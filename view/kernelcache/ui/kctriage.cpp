#include <QMessageBox>
#include <QPainter>
#include <cmath>
#include "globalarea.h"
#include "kctriage.h"
#include "ui/fontsettings.h"

using namespace BinaryNinja;
using namespace KernelCacheAPI;


KCTriageViewType::KCTriageViewType()
	: ViewType("KCTriage", "Kernel Cache Triage")
{}


int KCTriageViewType::getPriority(BinaryViewRef data, const QString& filename)
{
	if (data->GetTypeName() == KC_VIEW_NAME)
		return 100;
	return 0;
}


QWidget* KCTriageViewType::create(BinaryViewRef data, ViewFrame* viewFrame)
{
	if (data->GetTypeName() != KC_VIEW_NAME)
		return nullptr;
	return new KCTriageView(viewFrame, data);
}


void KCTriageViewType::Register()
{
	registerViewType(new KCTriageViewType());
}


KCTriageView::KCTriageView(QWidget* parent, BinaryViewRef data) : QWidget(parent), View(), m_data(data), m_cache(new KernelCache(data))
{
	setBinaryDataNavigable(true);
	setupView(this);

	UIContext::registerNotification(this);

	m_triageCollection = new DockableTabCollection();
	m_triageTabs = new SplitTabWidget(m_triageCollection);

	auto triageTabStyle = new GlobalAreaTabStyle();
	m_triageTabs->setTabStyle(triageTabStyle);

	QWidget* defaultWidget = initImageTable();
	initSymbolTable();

	m_layout = new QVBoxLayout(this);
	m_layout->addWidget(m_triageTabs);
	setLayout(m_layout);

	m_triageTabs->selectWidget(defaultWidget);
}


KCTriageView::~KCTriageView()
{
	UIContext::unregisterNotification(this);
}


QWidget* KCTriageView::initImageTable()
{
	m_imageTable = new FilterableTableView(this);

	m_imageModel = new QStandardItemModel(0, 2, m_imageTable);
	m_imageModel->setHorizontalHeaderLabels({"VM Address", "Name"});

	// Apply custom column styling
	m_imageTable->setItemDelegateForColumn(0, new AddressColorDelegate(m_imageTable));

	BackgroundThread::create(m_imageTable)->thenBackground([this](const QVariant var) {
		QVariantList rows;

		auto images = m_cache->GetImages();

		auto newHeaders = std::make_shared<std::vector<KernelCacheMachOHeader>>();
		newHeaders->reserve(images.size());

		for (const auto& img : images)
		{
			if (auto header = m_cache->GetMachOHeaderForImage(img.name); header)
			{
				newHeaders->push_back(*header);
				rows.push_back(QList<QVariant>{
					QString("0x%1").arg(header->textBase, 0, 16),
					QString::fromStdString(img.name)
				});
			}
		}

		std::unique_lock<std::mutex> lock(m_headersMutex);
		m_headers.swap(newHeaders);

		return QVariant(rows);
	})->thenMainThread([this](const QVariant var) {
		QVariantList rows = var.toList();

		if (m_imageModel->rowCount() > 0)
			m_imageModel->removeRows(0, m_imageModel->rowCount());

		for (const QVariant &rowVariant : rows) {
			QVariantList row = rowVariant.toList();

			QList<QStandardItem*> items;
			for (const QVariant &cellValue : row)
				items.append(new QStandardItem(cellValue.toString()));

			m_imageModel->appendRow(items);
			m_imageTable->resizeColumnsToContents();
		}
	})->start();

	auto loadImageButton = new QPushButton();
	connect(loadImageButton, &QPushButton::clicked, [this](bool) {
		// Collect only visible selected rows
		QModelIndexList selected;
		for (const auto& index : m_imageTable->selectionModel()->selectedRows()) {
			if (!m_imageTable->isRowHidden(index.row())) {
				selected.append(index);
			}
		}

		if (selected.empty())
			return;

		for (const auto& selection : selected) {
			auto name = m_imageModel->item(selection.row(), 1)->text().toStdString();
			WorkerPriorityEnqueue([this, name]() { m_cache->LoadImageWithInstallName(name); });
		}
	});
	loadImageButton->setText("Load Selected");

	auto loadImageFilterEdit = new FilterEdit(m_imageTable);
	connect(loadImageFilterEdit, &FilterEdit::textChanged, [this](const QString& filter) {
		m_imageTable->setFilter(filter.toStdString());
	});

	connect(m_imageTable, &FilterableTableView::activated, this, [=](const QModelIndex& index) {
		auto selected = m_imageModel->item(index.row(), 1);
		auto name = selected->text().toStdString();
		WorkerPriorityEnqueue([this, name]() { m_cache->LoadImageWithInstallName(name); });
	});

	auto loadImageLayout = new QVBoxLayout;
	loadImageLayout->addWidget(loadImageFilterEdit);
	loadImageLayout->addWidget(m_imageTable);

	auto loadImageFooterLayout = new QHBoxLayout;
	loadImageFooterLayout->addWidget(loadImageButton);
	loadImageFooterLayout->setAlignment(Qt::AlignLeft);
	loadImageLayout->addLayout(loadImageFooterLayout);

	auto loadImageWidget = new QWidget;
	loadImageWidget->setLayout(loadImageLayout);

	m_imageTable->setModel(m_imageModel);

	m_imageTable->setEditTriggers(QAbstractItemView::NoEditTriggers);

	m_imageTable->horizontalHeader()->setSectionResizeMode(0, QHeaderView::ResizeToContents);
	m_imageTable->horizontalHeader()->setSectionResizeMode(1, QHeaderView::Stretch);

	m_imageTable->setSelectionBehavior(QAbstractItemView::SelectRows);
	m_imageTable->setSelectionMode(QAbstractItemView::ExtendedSelection);

	m_imageTable->setSortingEnabled(true);

	m_imageTable->verticalHeader()->setVisible(false);

	m_triageTabs->addTab(loadImageWidget, "Images");
	m_triageTabs->setCanCloseTab(loadImageWidget, false);

	return loadImageWidget; // For use as the default widget
}


void KCTriageView::initSymbolTable()
{
	m_symbolTable = new SymbolTableView(this, m_cache);

	auto symbolFilterEdit = new FilterEdit(m_symbolTable);
	connect(symbolFilterEdit, &FilterEdit::textChanged, [this](const QString& filter) {
		m_symbolTable->setFilter(filter.toStdString());
	});

	auto symbolLayout = new QVBoxLayout;
	symbolLayout->addWidget(symbolFilterEdit);
	symbolLayout->addWidget(m_symbolTable);

	auto symbolWidget = new QWidget;
	symbolWidget->setLayout(symbolLayout);

	std::function<void(uint64_t)> navigateToAddress = [=](uint64_t addr) {
		ExecuteOnMainThread([addr, this](){
			if (Settings::Instance()->Get<bool>("ui.view.graph.preferred"))
				m_data->Navigate("Graph:KCView", addr);
			else
				m_data->Navigate("Linear:KCView", addr);
		});
	};

	connect(m_symbolTable, &SymbolTableView::activated, this, [=](const QModelIndex& index)
	{
		auto symbol = m_symbolTable->getSymbolAtRow(index.row());
		WorkerPriorityEnqueue([this, symbol, navigateToAddress]() {
			if (m_data->IsValidOffset(symbol.address))
				navigateToAddress(symbol.address);
			else
			{
				m_cache->LoadImageWithInstallName(symbol.image);
				navigateToAddress(symbol.address);
			}
		});
	});

	m_triageTabs->addTab(symbolWidget, "Symbols");
	m_triageTabs->setCanCloseTab(symbolWidget, false);
}


QFont KCTriageView::getFont()
{
	return getMonospaceFont(this);
}


BinaryViewRef KCTriageView::getData()
{
	return m_data;
}


bool KCTriageView::navigate(uint64_t offset)
{
	// TODO: We have to set this to true otherwise view restore does not pickup this view.
	return true;
}


uint64_t KCTriageView::getCurrentOffset()
{
	return 0;
}
