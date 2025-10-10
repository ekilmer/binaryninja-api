#pragma once

#include <QtWidgets/QLineEdit>
#include "uitypes.h"

class BINARYNINJAUIAPI PasswordEdit: public QLineEdit
{
	Q_OBJECT

public:
	PasswordEdit(QWidget* parent = nullptr);

private slots:
	void showContextMenu(const QPoint& pos);
};
