package X11::Xbae;

# Copyright 1997, 1998 by Ken Fox

use DynaLoader;

use strict;
use vars qw($VERSION);

BEGIN {
    $VERSION = 1.0;

    use X11::Motif;
}

sub beta_version { 2 };

package X::bae;

# ================================================================================
# Xbae Widgets
#
# Register the Xbae widgets.  See Motif.pm for more info on registering
# widgets.

    xbaeMatrixWidgetClass()->register();
    xbaeCaptionWidgetClass()->register();

# ================================================================================
# Widget Aliases
#
# Register the widgets under their simple names, e.g.  matrix, caption.

    xbaeMatrixWidgetClass()->register_alias(-matrix);
    xbaeCaptionWidgetClass()->register_alias(-caption);

# ================================================================================
# Resource values (constants)
#
# These should be exported similarly as the Motif resource constants. FIXME

sub XmGRID_NONE () { 0 }
sub XmGRID_LINE () { 1 }
sub XmGRID_SHADOW_IN () { 2 }
sub XmGRID_SHADOW_OUT () { 3 }
sub XmGRID_ROW_SHADOW () { 4 }
sub XmGRID_COLUMN_SHADOW () { 5 }
sub XmDISPLAY_NONE () { 0 }
sub XmDISPLAY_AS_NEEDED () { 1 }
sub XmDISPLAY_STATIC () { 2 }

# ================================================================================
# Callback data structures

$X::Toolkit::Widget::call_data_registry{'XbaeMatrix,defaultActionCallback'} = \"X::bae::MatrixDefaultActionCallData";
$X::Toolkit::Widget::call_data_registry{'XbaeMatrix,enterCellCallback'} = \"X::bae::MatrixEnterCellCallData";
$X::Toolkit::Widget::call_data_registry{'XbaeMatrix,leaveCellCallback'} = \"X::bae::MatrixLeaveCellCallData";

package X::bae::AnyCallData;

package X::bae::RowColumnCallData;
    use vars qw(@ISA);
    @ISA = qw(X::bae::AnyCallData);

package X::bae::MatrixDefaultActionCallData;
    use vars qw(@ISA);
    @ISA = qw(X::bae::RowColumnCallData);

package X::bae::MatrixEnterCellCallData;
    use vars qw(@ISA);
    @ISA = qw(X::bae::RowColumnCallData);

package X::bae::MatrixLeaveCellCallData;
    use vars qw(@ISA);
    @ISA = qw(X::bae::RowColumnCallData);

1;
