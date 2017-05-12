#!/ford/thishost/unix/div/ap/bin/perl -w

use blib;

use strict;
use X11::Motif qw(:Xt :Xm);

my $toplevel = X::Toolkit::initialize("Example");

my $form = XtCreateManagedWidget("form", xmFormWidgetClass, $toplevel);

my $hello = XtCreateManagedWidget("hello", xmLabelWidgetClass, $form,
				    XmNbackground, 'yellow',
				    XmNfontList, '-*-helvetica-bold-r-*-*-*-240-*-*-*-*-*-*',
				    XmNlabelString, 'Hello, world!',
				    XmNlabelType, XmSTRING);

my $quit = XtCreateManagedWidget("quit", xmPushButtonWidgetClass, $form,
				    XmNlabelString, 'quit',
				    XmNlabelType, XmSTRING);

my $unmanage = XtCreateManagedWidget("unmanage", xmPushButtonWidgetClass, $form,
                                    XmNlabelString, 'Unmanage Dialog Window',
                                    XmNlabelType, XmSTRING);

my $manage = XtCreateManagedWidget("manage", xmPushButtonWidgetClass, $form,
                                    XmNlabelString, 'Manage Dialog Window',
                                    XmNlabelType, XmSTRING);


my $dialog = XtCreateWidget("Dialog", xmDialogShellWidgetClass, $toplevel);

my $fileselectionbox = XtCreateManagedWidget("fileselectionbox", xmFileSelectionBoxWidgetClass,
					$dialog);

XtAddCallback($quit, XmNactivateCallback, sub { exit }, 0);
XtAddCallback($unmanage, XmNactivateCallback, sub {XtUnmanageChild($dialog)}, 0);
XtAddCallback($manage, XmNactivateCallback, sub {XtManageChild($dialog)}, 0);



XtSetValues($form,
		XmNfractionBase, 4);

XtSetValues($hello,
		XmNrightAttachment, XmATTACH_FORM,
		XmNleftAttachment, XmATTACH_FORM,
		XmNtopAttachment, XmATTACH_FORM,
		XmNbottomAttachment, XmATTACH_POSITION,
		XmNbottomPosition, 1);

XtSetValues($quit,
		XmNrightAttachment, XmATTACH_FORM,
		XmNleftAttachment, XmATTACH_FORM,
		XmNtopAttachment, XmATTACH_POSITION,
		XmNtopPosition, 1,
		XmNbottomAttachment, XmATTACH_POSITION,
		XmNbottomPosition, 2);

XtSetValues($unmanage,
                XmNrightAttachment, XmATTACH_FORM,
                XmNleftAttachment, XmATTACH_FORM,
                XmNtopAttachment, XmATTACH_POSITION,
                XmNtopPosition, 2,
                XmNbottomAttachment, XmATTACH_POSITION,
                XmNbottomPosition, 3);

XtSetValues($manage,
                XmNrightAttachment, XmATTACH_FORM,
                XmNleftAttachment, XmATTACH_FORM,
                XmNtopAttachment, XmATTACH_POSITION,
                XmNtopPosition, 3,
                XmNbottomAttachment, XmATTACH_POSITION,
                XmNbottomPosition, 4);


my($depth, $label, $y, $width) = XtGetValues($quit, XmNdepth, XmNlabelString, XmNy, XmNwidth);

print "quit button depth = $depth, label = '", $label->plain, "', y = $y, width = $width\n";

handle $toplevel;
