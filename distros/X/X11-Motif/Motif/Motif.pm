package X11::Motif;

# Copyright 1997, 1998 by Ken Fox

use DynaLoader;

use strict;
use vars qw($VERSION @ISA);

BEGIN {
    $VERSION = 1.1;
    @ISA = qw(DynaLoader);

    # A widget set is responsible for loading itself and the
    # X Toolkit.  This is due to problems with the Xt library
    # when linked independently from a widget set -- the
    # Toolkit's definition of symbols such as vendorShell seem
    # to be corrupt or incompatible with a widget set's.

    bootstrap X11::Motif;
    bootstrap X11::Toolkit;

    use X11::Toolkit qw(:private);
    use X11::MotifCons;

    # Define the standard Toolkit aliases -- this has to be
    # done here to ensure that all the Toolkit symbols have
    # been constructed.

    X11::Toolkit::use_standard_aliases();
}

sub beta_version { 2 };

sub import {
    my $module = shift;
    my %done;

    foreach my $sym (@_) {
	next if ($done{$sym});

	if ($sym eq ':X') {
	    export_pattern(\%X::, '^X');
	}
	elsif ($sym eq ':Xt') {
	    export_pattern(\%X::Toolkit::, '^Xt');
	    export_pattern(\%X::Toolkit::Context::, '^Xt');
	    export_pattern(\%X::Toolkit::Widget::, '^Xt');
	}
	elsif ($sym eq ':Xm') {
	    if (!$done{':widgets'}) {
		$done{':widgets'} = 1;
		export_pattern(\%X::Motif::, '^xm');
	    }
	    export_pattern(\%X::Motif::, '^Xm');
	}
	elsif ($sym eq ':widgets') {
	    export_pattern(\%X::Motif::, '^xm');
	}
	elsif ($sym eq ':private') {
	    export_symbol(\%X11::Lib::, 'export_pattern');
	    export_symbol(\%X11::Lib::, 'export_symbol');
	    export_symbol(\%X11::Lib::, 'alias_trimmed_pattern');
	}
	else {
	    export_symbol(\%X::Motif::, $sym);
	}

	$done{$sym} = 1;
    }
}

my $finished_standard_aliases = 0;

sub use_standard_aliases {
    if (!$finished_standard_aliases) {
	$finished_standard_aliases = 1;

	# this next line might not be something we want to do... there
	# are an awful lot of XmN resources and they might look better
	# if they weren't aliased.

	#alias_trimmed_pattern("X::Motif", \%X::Motif::, '^Xm');
    }
}

package X::Motif;

use Carp;

# ================================================================================
# Motif Widgets
#
# Register the Motif widgets under their full names, e.g.  XmLabel,
# XmPushButton, XmForm.  The arguments to register() form the aliases (i.e.
# short intuitive resource names) understood by the widget.  Any aliases
# defined on the widget's superclass will be inherited by the widget.  However,
# Motif has many widgets which use identical resources that aren't inherited.
# For these widgets, we just define a small list and re-use the list in the
# call to register().

$X::Toolkit::Widget::resource_hints{'BooleanDimension'} = 'u';
$X::Toolkit::Widget::resource_hints{'HorizontalDimension'} = 'u';
$X::Toolkit::Widget::resource_hints{'VerticalDimension'} = 'u';

{
    my @activate = ('command' => 'activateCallback');

    # ------------------------------------------------------------
    # Primitives

    xmArrowButtonWidgetClass()->register(@activate);

    xmLabelWidgetClass()->register('text' => ['labelString', 'labelType' => 'string'],
				   'icon' => ['labelPixmap', 'labelType' => 'pixmap'],
				   'font' => 'fontList');

	xmCascadeButtonWidgetClass()->register(@activate);

	xmDrawnButtonWidgetClass()->register(@activate);

	xmPushButtonWidgetClass()->register(@activate);

	xmToggleButtonWidgetClass()->register('command' => 'valueChangedCallback');

    xmListWidgetClass()->register();

    xmScrollBarWidgetClass()->register();

    xmSeparatorWidgetClass()->register();

    xmTextWidgetClass()->register('text' => 'value');

    xmTextFieldWidgetClass()->register('text' => 'value', @activate);

    # ------------------------------------------------------------
    # Managers

    xmBulletinBoardWidgetClass()->register();

	xmFormWidgetClass()->register();

	xmSelectionBoxWidgetClass()->register();

	    xmCommandWidgetClass()->register();

	    xmFileSelectionBoxWidgetClass()->register();

	xmMessageBoxWidgetClass()->register('message' => 'messageString',
					    'alignment' => 'messageAlignment');

    xmDrawingAreaWidgetClass()->register();

    xmFrameWidgetClass()->register();

    xmPanedWindowWidgetClass()->register();

    xmRowColumnWidgetClass()->register('label' => 'labelString');

    xmScaleWidgetClass()->register();

    xmScrolledWindowWidgetClass()->register();

	xmMainWindowWidgetClass()->register();

    # ------------------------------------------------------------
    # Shells

    overrideShellWidgetClass()->register();

    wmShellWidgetClass()->register('resizable' => 'allowShellResize');

	vendorShellWidgetClass()->register();

	    transientShellWidgetClass()->register();

		xmMenuShellWidgetClass()->register();

		xmDialogShellWidgetClass()->register();

	topLevelShellWidgetClass()->register();

	    applicationShellWidgetClass()->register();

    # ------------------------------------------------------------
    # Custom Motif Extensions

    xpFolderWidgetClass()->register();
    xpStackWidgetClass()->register();
    xpLinedAreaWidgetClass()->register();
}

sub create_menu {
    my $parent = shift;
    my $type = shift;

    my $shell = X::Toolkit::CreatePopupShell("a_menu_shell", xmMenuShellWidgetClass, $parent,
					XmNwidth, 1,
					XmNheight, 1);

    my $rc = X::Toolkit::CreateWidget("a_menu", xmRowColumnWidgetClass, $shell,
				      XmNrowColumnType, XmMENU_PULLDOWN);

    my $button = give $parent xmCascadeButtonWidgetClass,
					XmNsubMenuId, $rc,
					@_;

    if ($parent->IsSubclass(xmRowColumnWidgetClass) &&
	(query $parent XmNrowColumnType) == XmMENU_BAR)
    {
	my $label = query $button -text;
	if (plain $label =~ /\bHELP\b/i) {
	    change $parent -menuHelpWidget => $button;
	}
    }

    $rc;
}

sub create_option_menu {
    my $parent = shift;
    my $type = shift;

    my $shell = X::Toolkit::CreatePopupShell("a_menu_shell", xmMenuShellWidgetClass, $parent,
					XmNwidth, 1,
					XmNheight, 1);

    my $rc = X::Toolkit::CreateWidget("a_menu", xmRowColumnWidgetClass, $shell,
				      XmNrowColumnType, XmMENU_PULLDOWN);

    my $opt = give $parent xmRowColumnWidgetClass,
					XmNrowColumnType, XmMENU_OPTION,
					XmNsubMenuId, $rc,
					@_;

    return ($opt, $rc);
}

sub create_popup_menu {
    my $parent = shift;
    my $type = shift;

    my $shell = X::Toolkit::CreatePopupShell("a_menu_shell", xmMenuShellWidgetClass, $parent,
					XmNwidth, 1,
					XmNheight, 1);

    my $rc = give $shell xmRowColumnWidgetClass,
					-rowColumnType => XmMENU_POPUP,
					-managed => X::False,
					@_;

    return $rc;
}

sub XmDIALOG_CHOICE () { 10 }

my %dialog_style_names =
    ( 'error' => X::Motif::XmDIALOG_ERROR,
      'info' => X::Motif::XmDIALOG_INFORMATION,
      'information' => X::Motif::XmDIALOG_INFORMATION,
      'message' => X::Motif::XmDIALOG_MESSAGE,
      'question' => X::Motif::XmDIALOG_QUESTION,
      'warning' => X::Motif::XmDIALOG_WARNING,
      'working' => X::Motif::XmDIALOG_WORKING,
      'busy' => X::Motif::XmDIALOG_WORKING,
      'choice' => X::Motif::XmDIALOG_CHOICE(),
      'option' => X::Motif::XmDIALOG_CHOICE() );

my @dialog_style_titles;
    $dialog_style_titles[X::Motif::XmDIALOG_ERROR] = 'Error!';
    $dialog_style_titles[X::Motif::XmDIALOG_INFORMATION] = 'Information';
    $dialog_style_titles[X::Motif::XmDIALOG_MESSAGE] = 'Message';
    $dialog_style_titles[X::Motif::XmDIALOG_QUESTION] = 'Confirm';
    $dialog_style_titles[X::Motif::XmDIALOG_WARNING] = 'Warning!';
    $dialog_style_titles[X::Motif::XmDIALOG_WORKING] = 'Working ...';
    $dialog_style_titles[X::Motif::XmDIALOG_CHOICE()] = 'Choose';

sub create_dialog {
    my $parent = shift;
    my $type = shift;

    my @options = ();
    my $style = X::Motif::XmDIALOG_MESSAGE;
    my %show;
    my $choices;
    my $title;

    my($res_name, $value);
    my $num = scalar @_;
    my $i = 0;

    while ($i < $num) {
	$res_name = $_[$i++];
	$res_name =~ s|^-||;

	$value = $_[$i++];

	if ($res_name eq 'style' || $res_name eq 'type') {
	    $style = $value;
	}
	elsif ($res_name eq 'choices') {
	    $choices = $value;
	}
	elsif ($res_name eq 'title') {
	    $title = $value;
	}
	elsif ($res_name eq 'ok' || $res_name eq 'cancel' || $res_name eq 'help') {
	    if (ref $value eq 'ARRAY') {
		push @options, $res_name.'LabelString' => $value->[0],
			       $res_name.'Callback' => $value->[1];
	    }
	    else {
		push @options, $res_name.'Callback' => $value;
	    }
	    $show{$res_name} = 1;
	}
	else {
	    push @options, $res_name => $value;
	}
    }

    if (X::is_string($style)) {
	$style =~ s|^-||;
	if (defined $dialog_style_names{$style}) {
	    $style = $dialog_style_names{$style};
	}
    }

    if (!defined $title) {
	$title = $dialog_style_titles[$style];
    }

    my $shell = give $parent -DialogShell, -title => $title;
    my $dialog;

    if ($style eq X::Motif::XmDIALOG_CHOICE()) {
	$dialog = give $shell $type, -dialogType => X::Motif::XmDIALOG_MESSAGE,
				     -message => 'Not implemented';
    }
    else {
	$dialog = give $shell $type, -dialogType => $style, @options;
    }

    foreach ('OK', 'Cancel', 'Help') {
	if (!defined $show{lc $_}) {
	    my $child = X::Toolkit::search_from_parent($dialog, $_);
	    $child->UnmanageChild() if (defined $child);
	}
    }

    $dialog;
}

# ================================================================================
# Widget Subresources
#
# The subresources used by a widget aren't described in the class resource
# list, so they have to be added manually.  The implementation here requires
# the resource type to be pre-registered with the Toolkit.  Fortunately, every
# type encountered during normal resource registration is remembered so even
# custom Motif types should be available.  I haven't discovered a portable
# way to determine the size of a type used solely as a subresource -- but
# hopefully we'll never have to. '

xmTextWidgetClass()->register_subresource('PendingDelete', 'pendingDelete', 'Boolean');
xmTextWidgetClass()->register_subresource('SelectThreshold', 'selectThreshold', 'Int');

xmTextWidgetClass()->register_subresource('BlinkRate', 'blinkRate', 'Int');
xmTextWidgetClass()->register_subresource('Columns', 'columns', 'Short');
xmTextWidgetClass()->register_subresource('CursorPositionVisible', 'cursorPositionVisible', 'Boolean');
xmTextWidgetClass()->register_subresource('FontList', 'fontList', 'FontList');
xmTextWidgetClass()->register_subresource('ResizeHeight', 'resizeHeight', 'Boolean');
xmTextWidgetClass()->register_subresource('ResizeWidth', 'resizeWidth', 'Boolean');
xmTextWidgetClass()->register_subresource('Rows', 'rows', 'Short');
xmTextWidgetClass()->register_subresource('WordWrap', 'wordWrap', 'Boolean');

xmTextWidgetClass()->register_subresource('Scroll', 'scrollHorizontal', 'Boolean');
xmTextWidgetClass()->register_subresource('ScrollSide', 'scrollLeftSide', 'Boolean');
xmTextWidgetClass()->register_subresource('ScrollSide', 'scrollTopSide', 'Boolean');
xmTextWidgetClass()->register_subresource('Scroll', 'scrollVertical', 'Boolean');

# ================================================================================
# Widget Aliases
#
# Register the widgets under their simple names, e.g.  label, button, form --
# this should probably be done as an import statement.

    xmLabelWidgetClass()->register_alias(-label, 'alignment', XmALIGNMENT_BEGINNING);
    xmPushButtonWidgetClass()->register_alias(-button);
    xmToggleButtonWidgetClass()->register_alias(-toggle);

    xmSeparatorWidgetClass()->register_alias(-separator);
    xmSeparatorWidgetClass()->register_alias(-spacer, 'separatorType', XmNO_LINE);

    xmTextWidgetClass()->register_alias(-text);
    xmTextWidgetClass()->register_alias(-editor);
    xmTextFieldWidgetClass()->register_alias(-field);

    xmListWidgetClass()->register_alias(-list);

    xmFrameWidgetClass()->register_alias(-frame);
    xmPanedWindowWidgetClass()->register_alias(-pane);
    xmFormWidgetClass()->register_alias(-form);
    xmBulletinBoardWidgetClass()->register_alias(-bulletinboard);
    xmRowColumnWidgetClass()->register_alias(-rowcolumn);
    xmRowColumnWidgetClass()->register_alias(-menubar, XmNrowColumnType, XmMENU_BAR);
    xmRowColumnWidgetClass()->register_alias(-menu, \&create_menu);
    xmRowColumnWidgetClass()->register_alias(-optionmenu, \&create_option_menu);
    xmRowColumnWidgetClass()->register_alias(-popupmenu, \&create_popup_menu);
    xmScrolledWindowWidgetClass()->register_alias(-scrolledwindow);

    xmMessageBoxWidgetClass()->register_alias(-dialog, \&create_dialog);

    xmDrawingAreaWidgetClass()->register_alias(-drawingarea);
    xmDrawingAreaWidgetClass()->register_alias(-canvas);

    xmDialogShellWidgetClass()->register_alias(-dialogshell);
    xmMenuShellWidgetClass()->register_alias(-menushell);
    topLevelShellWidgetClass()->register_alias(-toplevel);
    transientShellWidgetClass()->register_alias(-transient);

# ================================================================================
# Motif convenience routines

sub generic_XmCreate {
    my $f = shift;
    my $type = shift;
    my $parent = shift;
    my $name = shift;

    my %resources = ();
    my %callbacks;

    X::Toolkit::Widget::build_strict_resource_table($type, $parent->Class()->name(),
						    \%resources, \%callbacks, @_);

    my $child = &$f($parent, $name, %resources);

    if (!defined $child) {
	carp "couldn't create $type widget $name";
    }

    $child;
}

sub XmCreateArrowButton {
    return generic_XmCreate(\&priv_XmCreateArrowButton, 'XmArrowButton', @_);
}

sub XmCreateBulletinBoard {
    return generic_XmCreate(\&priv_XmCreateBulletinBoard, 'XmBulletinBoard', @_);
}

sub XmCreateBulletinBoardDialog {
    return generic_XmCreate(\&priv_XmCreateBulletinBoardDialog, 'XmMessageBox', @_);
}

sub XmCreateCascadeButton {
    return generic_XmCreate(\&priv_XmCreateCascadeButton, 'XmCascadeButton', @_);
}

sub XmCreateCommand {
    return generic_XmCreate(\&priv_XmCreateCommand, 'XmCommand', @_);
}

sub XmCreateCommandDialog {
    return generic_XmCreate(\&priv_XmCreateCommandDialog, 'XmMessageBox', @_);
}

sub XmCreateDialogShell {
    return generic_XmCreate(\&priv_XmCreateDialogShell, 'XmDialogShell', @_);
}

sub XmCreateDrawingArea {
    return generic_XmCreate(\&priv_XmCreateDrawingArea, 'XmDrawingArea', @_);
}

sub XmCreateDrawnButton {
    return generic_XmCreate(\&priv_XmCreateDrawnButton, 'XmDrawnButton', @_);
}

sub XmCreateErrorDialog {
    return generic_XmCreate(\&priv_XmCreateErrorDialog, 'XmMessageBox', @_);
}

sub XmCreateFileSelectionBox {
    return generic_XmCreate(\&priv_XmCreateFileSelectionBox, 'XmFileSelectionBox', @_);
}

sub XmCreateFileSelectionDialog {
    return generic_XmCreate(\&priv_XmCreateFileSelectionDialog, 'XmMessageBox', @_);
}

sub XmCreateForm {
    return generic_XmCreate(\&priv_XmCreateForm, 'XmForm', @_);
}

sub XmCreateFormDialog {
    return generic_XmCreate(\&priv_XmCreateFormDialog, 'XmMessageBox', @_);
}

sub XmCreateFrame {
    return generic_XmCreate(\&priv_XmCreateFrame, 'XmFrame', @_);
}

sub XmCreateInformationDialog {
    return generic_XmCreate(\&priv_XmCreateInformationDialog, 'XmMessageBox', @_);
}

sub XmCreateLabel {
    return generic_XmCreate(\&priv_XmCreateLabel, 'XmLabel', @_);
}

sub XmCreateList {
    return generic_XmCreate(\&priv_XmCreateList, 'XmList', @_);
}

sub XmCreateMainWindow {
    return generic_XmCreate(\&priv_XmCreateMainWindow, 'XmMainWindow', @_);
}

sub XmCreateMenuBar {
    return generic_XmCreate(\&priv_XmCreateMenuBar, 'XmMenuBar', @_);
}

sub XmCreateMenuShell {
    return generic_XmCreate(\&priv_XmCreateMenuShell, 'XmMenuShell', @_);
}

sub XmCreateMessageBox {
    return generic_XmCreate(\&priv_XmCreateMessageBox, 'XmMessageBox', @_);
}

sub XmCreateMessageDialog {
    return generic_XmCreate(\&priv_XmCreateMessageDialog, 'XmMessageBox', @_);
}

sub XmCreateOptionMenu {
    return generic_XmCreate(\&priv_XmCreateOptionMenu, 'XmOptionMenu', @_);
}

sub XmCreatePanedWindow {
    return generic_XmCreate(\&priv_XmCreatePanedWindow, 'XmPanedWindow', @_);
}

sub XmCreatePopupMenu {
    return generic_XmCreate(\&priv_XmCreatePopupMenu, 'XmPopupMenu', @_);
}

sub XmCreatePromptDialog {
    return generic_XmCreate(\&priv_XmCreatePromptDialog, 'XmMessageBox', @_);
}

sub XmCreatePulldownMenu {
    return generic_XmCreate(\&priv_XmCreatePulldownMenu, 'XmPulldownMenu', @_);
}

sub XmCreatePushButton {
    return generic_XmCreate(\&priv_XmCreatePushButton, 'XmPushButton', @_);
}

sub XmCreateQuestionDialog {
    return generic_XmCreate(\&priv_XmCreateQuestionDialog, 'XmMessageBox', @_);
}

sub XmCreateRadioBox {
    return generic_XmCreate(\&priv_XmCreateRadioBox, 'XmRadioBox', @_);
}

sub XmCreateRowColumn {
    return generic_XmCreate(\&priv_XmCreateRowColumn, 'XmRowColumn', @_);
}

sub XmCreateScale {
    return generic_XmCreate(\&priv_XmCreateScale, 'XmScale', @_);
}

sub XmCreateScrollBar {
    return generic_XmCreate(\&priv_XmCreateScrollBar, 'XmScrollBar', @_);
}

sub XmCreateScrolledList {
    return generic_XmCreate(\&priv_XmCreateScrolledList, 'XmList', @_);
}

sub XmCreateScrolledText {
    return generic_XmCreate(\&priv_XmCreateScrolledText, 'XmText', @_);
}

sub XmCreateScrolledWindow {
    return generic_XmCreate(\&priv_XmCreateScrolledWindow, 'XmScrolledWindow', @_);
}

sub XmCreateSelectionBox {
    return generic_XmCreate(\&priv_XmCreateSelectionBox, 'XmSelectionBox', @_);
}

sub XmCreateSelectionDialog {
    return generic_XmCreate(\&priv_XmCreateSelectionDialog, 'XmMessageBox', @_);
}

sub XmCreateSeparator {
    return generic_XmCreate(\&priv_XmCreateSeparator, 'XmSeparator', @_);
}

sub XmCreateSimpleCheckBox {
    return generic_XmCreate(\&priv_XmCreateSimpleCheckBox, 'XmSimpleCheckBox', @_);
}

sub XmCreateSimpleMenuBar {
    return generic_XmCreate(\&priv_XmCreateSimpleMenuBar, 'XmSimpleMenuBar', @_);
}

sub XmCreateSimpleOptionMenu {
    return generic_XmCreate(\&priv_XmCreateSimpleOptionMenu, 'XmSimpleOptionMenu', @_);
}

sub XmCreateSimplePopupMenu {
    return generic_XmCreate(\&priv_XmCreateSimplePopupMenu, 'XmSimplePopupMenu', @_);
}

sub XmCreateSimplePulldownMenu {
    return generic_XmCreate(\&priv_XmCreateSimplePulldownMenu, 'XmSimplePulldownMenu', @_);
}

sub XmCreateSimpleRadioBox {
    return generic_XmCreate(\&priv_XmCreateSimpleRadioBox, 'XmSimpleRadioBox', @_);
}

sub XmCreateTemplateDialog {
    return generic_XmCreate(\&priv_XmCreateTemplateDialog, 'XmMessageBox', @_);
}

sub XmCreateText {
    return generic_XmCreate(\&priv_XmCreateText, 'XmText', @_);
}

sub XmCreateTextField {
    return generic_XmCreate(\&priv_XmCreateTextField, 'XmTextField', @_);
}

sub XmCreateToggleButton {
    return generic_XmCreate(\&priv_XmCreateToggleButton, 'XmToggleButton', @_);
}

sub XmCreateWarningDialog {
    return generic_XmCreate(\&priv_XmCreateWarningDialog, 'XmMessageBox', @_);
}

sub XmCreateWorkArea {
    return generic_XmCreate(\&priv_XmCreateWorkArea, 'XmWorkArea', @_);
}

sub XmCreateWorkingDialog {
    return generic_XmCreate(\&priv_XmCreateWorkingDialog, 'XmMessageBox', @_);
}

# ================================================================================
# Resource converters
#
# The input to a converter is always a string.  The output of a converter
# should be a value in the internal resource type, but it can also be a string
# that the toolkit or widget set knows how to convert.  If a true value is
# returned from the converter, then that stops the conversion chain.  If
# a false (or undefined) value is returned, then conversion will continue
# to the registered converter.  (Improperly coded converters can break the
# rule that the input is always a string!)

sub cvt_to_XmLabelType {
    my $value = shift;
    if    ($$value =~ /string/i) { $$value = XmSTRING }
    elsif ($$value =~ /pixmap/i) { $$value = XmPIXMAP }
}

sub cvt_to_HorizontalPosition {
    my $value = shift;
    my $widget = shift;
    if ($$value =~ /^\d+$/i) {
	$$value = int $$value;
    }
    elsif ($$value =~ /^(\d+\.?\d*)(\w*)$/i) {
	my $x = $1;
	my $u = $2;
	if    ($u eq 'mm')   { $x *= X::Toolkit::width_pixels_per_mm($widget) }
	if    ($u eq 'cm')   { $x *= X::Toolkit::width_pixels_per_mm($widget) * 10.0 }
	elsif ($u eq 'in')   { $x *= X::Toolkit::width_pixels_per_mm($widget) * 25.4 }
	$$value = $x;
    }
}

sub cvt_to_VerticalPosition {
    my $value = shift;
    my $widget = shift;
    if ($$value =~ /^\d+$/i) {
	$$value = int $$value;
    }
    elsif ($$value =~ /^(\d+\.?\d*)(\w*)$/i) {
	my $x = $1;
	my $u = $2;
	if    ($u eq 'mm')   { $x *= X::Toolkit::height_pixels_per_mm($widget) }
	if    ($u eq 'cm')   { $x *= X::Toolkit::height_pixels_per_mm($widget) * 10.0 }
	elsif ($u eq 'in')   { $x *= X::Toolkit::height_pixels_per_mm($widget) * 25.4 }
	$$value = $x;
    }
}

sub cvt_to_XmString {
    my $value = shift;

    $$value = new X::Motif::String($$value);
}

sub cvt_to_UserData {
    my $value = shift;

    $$value = new X::shared_perl_value($$value);
}

X::Toolkit::Widget::register_converter('LabelType', \&cvt_to_XmLabelType);
X::Toolkit::Widget::register_converter('HorizontalPosition', \&cvt_to_HorizontalPosition);
X::Toolkit::Widget::register_converter('VerticalPosition', \&cvt_to_VerticalPosition);
X::Toolkit::Widget::register_converter('XmString', \&cvt_to_XmString);

# It isn't very satisfying to register a class converter and then
# require the resource *type* to be converted.  Either class conversion
# should be monitored or the forcing/registration scheme should be
# re-thought.  FIXME

X::Toolkit::Widget::conversion_is_mandatory('Pointer');
X::Toolkit::Widget::register_class_converter('UserData', \&cvt_to_UserData);

# ================================================================================
# Manager Widget Hooks
#
# Special routines that handle constraint resources in the standard
# Tk-like toolkit api.

sub handle_custom_form_constraints {
    my($res_name, $value, $registry, $resources) = @_;

    if ($res_name eq 'top' || $res_name eq 'bottom' ||
	$res_name eq 'right' || $res_name eq 'left')
    {
	if (ref $value eq 'ARRAY') {
	    X::Toolkit::Widget::set_resource($res_name.'Offset' => $value->[1], $registry, $resources);
	    $value = $value->[0];
	}

	if (ref $value eq 'X::Toolkit::Widget') {
	    X::Toolkit::Widget::set_resource($res_name.'Attachment' => XmATTACH_WIDGET, $registry, $resources);
	    X::Toolkit::Widget::set_resource($res_name.'Widget' => $value, $registry, $resources);
	}
	elsif (X::is_integer($value) || $value =~ /^\d+$/) {
	    X::Toolkit::Widget::set_resource($res_name.'Attachment' => XmATTACH_POSITION, $registry, $resources);
	    X::Toolkit::Widget::set_resource($res_name.'Position' => int $value, $registry, $resources);
	}
	elsif ($value =~ /^-?form$/i) {
	    X::Toolkit::Widget::set_resource($res_name.'Attachment' => XmATTACH_FORM, $registry, $resources);
	}
	elsif ($value =~ /^-?none$/i) {
	    X::Toolkit::Widget::set_resource($res_name.'Attachment' => XmATTACH_NONE, $registry, $resources);
	}
	else {
	    carp "value $value not defined for resource $res_name";
	    return 0;
	}
    }
    elsif ($res_name =~ /^align[-_]?(\w+)/i)
    {
	$res_name = lc($1);

	if ($res_name eq 'top' || $res_name eq 'bottom' ||
	    $res_name eq 'right' || $res_name eq 'left')
	{
	    if (ref $value eq 'ARRAY') {
		X::Toolkit::Widget::set_resource($res_name.'Offset' => $value->[1], $registry, $resources);
		$value = $value->[0];
	    }

	    if (ref $value eq 'X::Toolkit::Widget') {
		X::Toolkit::Widget::set_resource($res_name.'Attachment' => XmATTACH_OPPOSITE_WIDGET, $registry, $resources);
		X::Toolkit::Widget::set_resource($res_name.'Widget' => $value, $registry, $resources);
	    }
	    elsif ($value =~ /^-?form$/i) {
		X::Toolkit::Widget::set_resource($res_name.'Attachment' => XmATTACH_OPPOSITE_FORM, $registry, $resources);
	    }
	    else {
		carp "value $value must be a widget or form edge for resource align_$res_name";
		return 0;
	    }
	}
	else {
	    carp "value $value must be a widget to align $res_name";
	    return 0;
	}
    }
    return 1;
}

$X::Toolkit::Widget::constraint_handlers{'XmForm'} = \&handle_custom_form_constraints;

# ================================================================================
# Callback data structures

# This is sort of kludgy right now.  There should probably be a generic way to
# specify the default callback data structure for a widget.  The concatenated
# key is used rather than nested hashes because it saves memory.  The performance
# hit is very minor because lookups are only performed when adding callbacks to
# widgets, not when calling them.

$X::Toolkit::Widget::call_data_registry{'XmPushButton,activateCallback'} = \"X::Motif::PushButtonCallData";

my $text_verify_call_data = "X::Motif::TextVerifyCallData";
$X::Toolkit::Widget::call_data_registry{'XmTextField,losingFocusCallback'} = \$text_verify_call_data;
$X::Toolkit::Widget::call_data_registry{'XmTextField,modifyVerifyCallback'} = \$text_verify_call_data;
$X::Toolkit::Widget::call_data_registry{'XmTextField,motionVerifyCallback'} = \$text_verify_call_data;

my $list_call_data = "X::Motif::ListCallData";
$X::Toolkit::Widget::call_data_registry{'XmList,singleSelectionCallback'} = \$list_call_data;
$X::Toolkit::Widget::call_data_registry{'XmList,multipleSelectionCallback'} = \$list_call_data;
$X::Toolkit::Widget::call_data_registry{'XmList,extendedSelectionCallback'} = \$list_call_data;
$X::Toolkit::Widget::call_data_registry{'XmList,browseSelectionCallback'} = \$list_call_data;
$X::Toolkit::Widget::call_data_registry{'XmList,defaultActionCallback'} = \$list_call_data;

package X::Motif::AnyCallData;

package X::Motif::ArrowButtonCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::DrawingAreaCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::DrawnButtonCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::PushButtonCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::RowColumnCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::ScrollBarCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::ToggleButtonCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::ListCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::SelectionBoxCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::CommandCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::FileSelectionCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::ScaleCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::TextVerifyCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

package X::Motif::TraverseObscuredCallData;
    use vars qw(@ISA);
    @ISA = qw(X::Motif::AnyCallData);

# ================================================================================
# Special Toolkit extensions

package X::Toolkit::Widget;

# The interfaces here are experimental.  I'm not sure if they are
# useful -- they certainly aren't finished!

my %adj = ( 'top' => 'left',
	    'bottom' => 'left',
	    'left' => 'top',
	    'right' => 'top' );

my %opp = ( 'top' => 'bottom',
	    'bottom' => 'top',
	    'left' => 'right',
	    'right' => 'left' );

sub attach_edge_to {
    my($edge, $widget, $registry, $resources) = @_;

    if (defined $widget) {
	set_resource($edge.'Attachment', X::Motif::XmATTACH_WIDGET, $registry, $resources);
	set_resource($edge.'Widget', $widget, $registry, $resources);
    }
    else {
	set_resource($edge.'Attachment', X::Motif::XmATTACH_FORM, $registry, $resources);
    }
}

sub arrange ($;@) {
    my $self = shift;
    my $type_name = $self->XtClass()->name();

    if ($type_name ne "XmForm") {
	carp "you can only arrange the widgets in a form widget";
	return;
    }

    my $fill_x = 0;
    my $fill_y = 0;

    my($edge, $adj_edge, $opp_edge, $opp_adj_edge);
    my %border;
    my %child = ( );

    foreach my $w ($self->XtChildren()) {
	$child{$w->ID()} = 1;
    }

    my $registry = $constraint_resource_registry{$type_name};

    my %resources;

    my($res_name, $value);
    my $num = scalar @_;
    my $i = 0;

    while ($i < $num) {
	$res_name = $_[$i++];
	$res_name =~ s|^-||;

	$value = $_[$i++];

	if ($res_name eq "fill") {
	    $fill_x = ($value =~ /x/i);
	    $fill_y = ($value =~ /y/i);
	}
	elsif ($res_name eq 'top' || $res_name eq 'bottom' ||
	       $res_name eq 'right' || $res_name eq 'left')
	{
	    my @peers = ();

	    if (ref $value eq 'X::Toolkit::Widget') {
		push @peers, $value;
	    }
	    else {
		@peers = @{$value};
	    }

	    $edge = $res_name;
	    $adj_edge = $adj{$edge};
	    $opp_edge = $opp{$edge};
	    $opp_adj_edge = $opp{$adj_edge};

	    foreach $value (@peers) {
		if (!$self->equal($value->XtParent())) {
		    carp "can't pack a widget that isn't in the form";
		}
		elsif (exists $child{$value->ID()}) {

		    delete $child{$value->ID()};
		    %resources = ();

		    attach_edge_to($edge, $border{$edge}, $registry, \%resources);
		    attach_edge_to($adj_edge, $border{$adj_edge}, $registry, \%resources);

		    if ($edge eq 'top' || $edge eq 'bottom') {
			if ($fill_x) {
			    attach_edge_to($opp_adj_edge, $border{$opp_adj_edge}, $registry, \%resources);
			}
			else {
			    my %sep_resources = ();
			    my $sep = $self->give('Separator', -separatorType => 'no_line');
			    attach_edge_to($edge, $border{$edge}, $registry, \%sep_resources);
			    attach_edge_to($adj_edge, $value, $registry, \%sep_resources);
			    attach_edge_to($opp_adj_edge, $border{$opp_adj_edge}, $registry, \%sep_resources);
			    $sep->priv_XtSetValues(%sep_resources,
						   $opp_edge.'Attachment' => X::Toolkit::InArg::new('attach_opposite_widget', 'Attachment', 1, 0),
						   $opp_edge.'Widget' => $value);
			}
			if (!%child) {
			    if ($fill_y) {
				attach_edge_to($opp_edge, $border{$opp_edge}, $registry, \%resources);
			    }
			}
		    }
		    else {
			if ($fill_y) {
			    attach_edge_to($opp_adj_edge, $border{$opp_adj_edge}, $registry, \%resources);
			}
			else {
			    my %sep_resources = ();
			    my $sep = $self->give('Separator', -separatorType => 'no_line');
			    attach_edge_to($edge, $border{$edge}, $registry, \%sep_resources);
			    attach_edge_to($adj_edge, $value, $registry, \%sep_resources);
			    attach_edge_to($opp_adj_edge, $border{$opp_adj_edge}, $registry, \%sep_resources);
			    $sep->priv_XtSetValues(%sep_resources,
						   $opp_edge.'Attachment' => X::Toolkit::InArg::new('attach_opposite_widget', 'Attachment', 1, 0),
						   $opp_edge.'Widget' => $value);
			}
			if (!%child) {
			    if ($fill_x) {
				attach_edge_to($opp_edge, $border{$opp_edge}, $registry, \%resources);
			    }
			}
		    }

		    $value->priv_XtSetValues(%resources);

		    $border{$edge} = $value;
		}
	    }
	}
    }
}

X11::Motif::use_standard_aliases();

1;
