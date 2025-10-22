#pragma once

#include <QtWidgets/QLineEdit>
#include "uitypes.h"

class ClickableLabel;

class BINARYNINJAUIAPI PasswordEdit: public QLineEdit
{
	Q_OBJECT

	ClickableLabel* m_toggleLabel;
	void updateToggleIcon();

public:
	PasswordEdit(QWidget* parent = nullptr);

protected:
	void resizeEvent(QResizeEvent* event) override;

private slots:
	void showContextMenu(const QPoint& pos);
};
