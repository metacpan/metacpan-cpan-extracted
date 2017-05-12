###########################################################################
#
# Win32::CtrlGUI::Window - an OO interface for controlling Win32 GUI windows
#
###########################################################################
# Copyright 2000, 2001, 2004 Toby Ovod-Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
##########################################################################
package Win32::CtrlGUI::Window;

use strict;

use Win32::Setupsup;

use vars qw(%atom_map $sendkey_activate $sendkey_intvl
						$win32api_hash $constant_hash);

our $VERSION = '0.32'; # VERSION from OurPkgVersion

use overload
	'""'  => \&text,
	'0+'  => \&handle,
	fallback => 1;

&init;

#ABSTRACT: OO interface for controlling Win32 GUI windows


sub _new {
	my $class = shift;

	my $self = {
		handle => $_[0]
	};
	bless $self, $class;
	return $self;
}


sub handle {
	my $self = shift;

	return $self->{handle};
}


sub text {
	my $self = shift;

	$self->exists or return undef;
	Win32::Setupsup::GetWindowText($self->handle, \my $retval) or return undef;
	return $retval;
}


sub exists {
	my $self = shift;

	Win32::Setupsup::WaitForWindowClose($self->handle, 1);
	my $error = Win32::Setupsup::GetLastError();
	$error == 536870926 and return 1;
	$error == 0 and return 0;
	die "Win32::Setupsup::GetLastError returned unknown error code in Win32::CtrlGUI::Window::exists.\n";
}


sub send_keys {
	my $self = shift;
	my($keys, $intvl) = @_;

	foreach my $i (&_convert_send_keys($keys)) {
		if (ref $i eq 'SCALAR') {
			Win32::Sleep($$i*1000);
		} else {
			$self->_send_keys($i, $intvl);
		}
	}
}


sub enum_child_windows {
	my $self = shift;

	$self->exists or return undef;
	Win32::Setupsup::EnumChildWindows($self->handle, \my @children) or return undef;
	return (map {(ref $self)->_new($_)} @children);
}


sub has_child {
	my $self = shift;
	my($criteria) = @_;

	$self->exists or return undef;
	Win32::Setupsup::EnumChildWindows($self->handle, \my @children) or return undef;

	foreach my $i (@children) {
		Win32::Setupsup::GetWindowText($i, \my $temp);
		if (ref $criteria eq 'CODE') {
			$_ = Win32::CtrlGUI::Window->_new($i);
			&$criteria and return 1;
		} elsif (ref $criteria eq 'Regexp') {
			$temp =~ /$criteria/ and return 1;
		} else {
			lc($temp) eq lc($criteria) and return 1;
		}
	}
	return 0;
}


sub set_focus {
	my $self = shift;

	$self->exists or die 'Win32::CtrlGUI::Window::set_focus called on non-existent window handle '.$self->handle.".\n";
	Win32::Setupsup::SetFocus($self->handle);
}


sub get_properties {
	my $self = shift;
	my(@properties) = @_;

	$self->exists or return undef;
	Win32::Setupsup::GetWindowProperties($self->handle, \@properties, \my %properties) or return undef;
	return (map {$properties{$_}} @properties);
}


sub get_property {
	my $self = shift;
	my($property) = @_;

	return ($self->get_properties($property))[0];
}


sub set_properties {
	my $self = shift;
	my(%properties) = @_;

	$self->exists or die 'Win32::CtrlGUI::Window::set_properties called on non-existent window handle '.$self->handle.".\n";
	return Win32::Setupsup::SetWindowProperties($self->handle, \%properties);
}


sub send_message {
	my $self = shift;

	$self->_message('send', @_);
}


sub post_message {
	my $self = shift;

	$self->_message('post', @_);
}

sub _message {
	my $self = shift;
	my $variant = shift @_;
	my $type = shift @_;
	my $msg = shift @_;

	exists $INC{'Win32::API'} or eval "use Win32::API";

	($variant eq 'send' || $variant eq 'post') or die "Win32::CtrlGUI::Window::_message passed illegal variant '$variant'\n";

	$self->exists or die 'Win32::CtrlGUI::Window::${variant}_message called on non-existent window handle '.$self->handle.".\n";

	$type = uc($type);
	$type =~ /^[NP]{2}$/ or die "Win32::CtrlGUI::Window::${variant}_message needs proper type information as first parameter.\n";

	if ($msg =~ /^[A-Z]/) {
		exists $constant_hash->{$msg} or die "Win32::CtrlGUI::Window::${variant}_message does not know about message '$msg'\n";
		$msg = $constant_hash->{$msg};
	}

	my $api_name = "${variant}_$type";
	unless (exists $win32api_hash->{$api_name}) {
		my $Variant = ucfirst($variant);
		$win32api_hash->{$api_name} = Win32::API->new("user32","${Variant}Message",[qw(N N), split(//, $type)],'N');
	}

	return $win32api_hash->{$api_name}->Call($self->handle(), $msg, $_[0], $_[1]);
}


sub get_text {
	my $self = shift;

	my $buflen = $self->send_message('NN', 'WM_GETTEXTLENGTH', 0, 0)+1;
	my $buffer = ' ' x $buflen;
	my $retval = $self->send_message('NP', 'WM_GETTEXT', $buflen, $buffer);
	$buffer = substr($buffer, 0, $retval);
	return $buffer;
}


sub lb_get_items {
	my $self = shift;

	my $count = $self->send_message('NN', 'LB_GETCOUNT', 0, 0);

	my(@retvals);

	foreach my $index (0..$count-1) {
		my $buflen = $self->send_message('NN', 'LB_GETTEXTLEN', $index, 0)+1;
		my $buffer = ' ' x $buflen;
		my $retval = $self->send_message('NP', 'LB_GETTEXT', $index, $buffer);
		$buffer = substr($buffer, 0, $retval);
		push(@retvals, $buffer);
	}

	return @retvals;
}


sub lb_get_selindexes {
	my $self = shift;

	my $multi = ($self->get_property('style') & 0x0808) ? 1 : 0;

	if ($multi) {
		my $count = $self->send_message('NN', 'LB_GETSELCOUNT', 0, 0) or return ();

		my $buflen = $count * 4;
		my $buffer = ' ' x $buflen;
		my $retval = $self->send_message('NP', 'LB_GETSELITEMS', $count, $buffer);

		return unpack("L$retval", $buffer);
	} else {
		my $retval = $self->send_message('NN', 'LB_GETCURSEL', 0, 0);
		$retval == -1 and return;
		return $retval;
	}
}


sub lb_set_selindexes {
	my $self = shift;
	my(@indexes) = @_;

	my $multi = ($self->get_property('style') & 0x0808) ? 1 : 0;

	(scalar(@indexes) > 1 && !$multi) and die "Win32::CtrlGUI::Window::lb_set_selindexes called with multiple indexes on a non-multi select list box.\n";

	if ($multi) {
		my(%old, %new);
		@old{$self->lb_get_selindexes()} = undef;
		@new{@indexes} = undef;

		my $count = $self->send_message('NN', 'LB_GETCOUNT', 0, 0);

		foreach my $index (0..$count-1) {
			if (exists($old{$index}) != exists($new{$index})) {
				$self->send_message('NN', 'LB_SETSEL', exists($new{$index}) ? 1 : 0 , $index) and return 0;
			}
		}
		return 1;
	} else {
		my $index = scalar(@indexes) ? $indexes[0] : -1;
		my $retval = $self->send_message('NN', 'LB_SETCURSEL', $index, 0);
		return $retval == $index ? 1 : 0;
	}
}


sub cb_get_items {
	my $self = shift;

	my $count = $self->send_message('NN', 'CB_GETCOUNT', 0, 0);

	my(@retvals);

	foreach my $index (0..$count-1) {
		my $buflen = $self->send_message('NN', 'CB_GETLBTEXTLEN', $index, 0)+1;
		my $buffer = ' ' x $buflen;
		my $retval = $self->send_message('NP', 'CB_GETLBTEXT', $index, $buffer);
		$buffer = substr($buffer, 0, $retval);
		push(@retvals, $buffer);
	}

	return @retvals;
}


sub cb_get_selindex {
	my $self = shift;

	my $retval = $self->send_message('NN', 'CB_GETCURSEL', 0, 0);
	$retval == -1 and return;
	return $retval;
}


sub cb_set_selindex {
	my $self = shift;
	my($index) = @_;

	$index eq '' and $index = -1;
	my $retval = $self->send_message('NN', 'CB_SETCURSEL', $index, 0);
	return $retval == $index ? 1 : 0;
}

sub _send_keys {
	my $self = shift;
	my($keys, $intvl) = @_;

	$self->exists or die 'Win32::CtrlGUI::Window::send_keys called on non-existent window handle '.$self->handle.".\n";
	Win32::Setupsup::SendKeys($self->handle, $keys, $sendkey_activate, defined $intvl ? $intvl : $sendkey_intvl);
}

sub _convert_send_keys {
	my($input) = @_;

	#Turn backslashes into doubled backslashes
	$input =~ s/\\/\\\\/g;

	#Match qualifier sequences
	while ($input =~ /^(.*?)(?<!\{)([+!^]+)(\{[{}]\}|\{[^}]*\}|\\\\|[^{])(.*)$/) {
		my($begin, $qualifiers, $atom, $end) = ($1, $2, $3, $4);
		$qualifiers =~ /(.)\1/ and die "SendKey conversion error: The qualifiers string \"$qualifiers\" contains a repeat.\n";
		my($startq, $endq);
		foreach my $q (reverse split(//, $qualifiers)) {
			$q = {'+' => 'SHIFT', '^' => 'CTRL', '!' => 'ALT'}->{$q};
			$atom = "\\$q\\$atom\\$q-\\";
		}
		$input = "$begin$atom$end";
	}

	#Match atoms and evaluate
	while ($input =~ /^(.*?)\{([^{}0-9][^{}]*)\}(.*)$/) {
		my($begin, $atom, $end) = ($1, $2, $3);
		$atom =~ /^(\S+)( \d+)?$/ or die "SendKey conversion error: The curly string \"$atom\" is illegal.\n";
		$atom = $1;
		my $repeat = int($2 ? $2 : 1);
		if (exists($atom_map{$atom})) {
			$input = $begin.($atom_map{$atom} x $repeat).$end;
		} elsif ($repeat > 1 and length($atom) == 1) {
			$input = $begin.($atom x $repeat).$end;
		} else {
			die "Unknown atom \"$atom\".\n";
		}
	}

	#Unmatched curly braces checking - first we get rid of {{}, {}}, and {4.5} type stuff
	(my $input_test = $input) =~ s/\{[{}]\}//g;
	$input_test =~ s/\{[0-9][0-9]*(\.[0-9]+)?\}//g;
	$input_test =~ /[{}]/ and die "SendKey conversion error: There are unmatched curly braces in \"$input\".\n";

	#Convert {{} to { and {}} to }
	$input =~ s/\{([{}])\}/$1/g;

	#Add +'s to modifier key down strokes
	$input =~ s/\\(ALT|CTRL|SHIFT)\\/\\$1+\\/g;

	#Deal with pause (i.e. {4.5}) commands
	my(@retval);
	while ($input =~ /(.*?)\{([0-9][0-9]*(\.[0-9]+)?)\}(.*)/) {
		my($begin, $sleep, $end) = ($1, $2, $4);
		push(@retval, $begin, \$sleep);
		$input = $end;
	}
	push(@retval, $input);

	return @retval;
}

sub init {
	&init_atom_map;
	&init_constant_hash;
	$sendkey_activate = 1;
	$sendkey_intvl = 0;
}

sub init_atom_map {
	%atom_map = ('!' => '!', '^' => '^', '+' => '+', 'ALT' => "\\ALT+\\\\ALT-\\", 'SPACE' => ' ', 'SP' => ' ');
	$atom_map{BACKSPACE} = "\\BACK\\";

	foreach my $i (qw(BACK BEG DEL DN END ESC HELP INS LEFT PGDN PGUP RET RIGHT TAB UP)) {
		$atom_map{$i} = "\\$i\\";
	}

	foreach my $i (1..12) {
		$atom_map{"F$i"} = "\\F$i\\";
	}

	foreach my $i (0..9, '*', '+', '-', '/') {
		$atom_map{"NUM$i"} = "\\NUM$i\\";
	}

	$atom_map{BACKSPACE} = "\\BACK\\";
	$atom_map{BS} =        "\\BACK\\";
	$atom_map{DELETE} =    "\\DEL\\";
	$atom_map{DOWN} =      "\\DN\\";
	$atom_map{ENTER} =     "\\RET\\";
	$atom_map{ESCAPE} =    "\\ESC\\";
	$atom_map{HOME} =      "\\BEG\\";
	$atom_map{INSERT} =    "\\INS\\";
}

sub init_constant_hash {
	$constant_hash = {
		'WM_NULL' =>                         0x0000,
		'WM_CREATE' =>                       0x0001,
		'WM_DESTROY' =>                      0x0002,
		'WM_MOVE' =>                         0x0003,
		'WM_SIZE' =>                         0x0005,
		'WM_ACTIVATE' =>                     0x0006,
		'WM_SETFOCUS' =>                     0x0007,
		'WM_KILLFOCUS' =>                    0x0008,
		'WM_ENABLE' =>                       0x000A,
		'WM_SETREDRAW' =>                    0x000B,
		'WM_SETTEXT' =>                      0x000C,
		'WM_GETTEXT' =>                      0x000D,
		'WM_GETTEXTLENGTH' =>                0x000E,
		'WM_PAINT' =>                        0x000F,
		'WM_CLOSE' =>                        0x0010,
		'WM_QUERYENDSESSION' =>              0x0011,
		'WM_QUIT' =>                         0x0012,
		'WM_QUERYOPEN' =>                    0x0013,
		'WM_ERASEBKGND' =>                   0x0014,
		'WM_SYSCOLORCHANGE' =>               0x0015,
		'WM_ENDSESSION' =>                   0x0016,
		'WM_SHOWWINDOW' =>                   0x0018,
		'WM_WININICHANGE' =>                 0x001A,
		'WM_SETTINGCHANGE' =>                0x001A,
		'WM_DEVMODECHANGE' =>                0x001B,
		'WM_ACTIVATEAPP' =>                  0x001C,
		'WM_FONTCHANGE' =>                   0x001D,
		'WM_TIMECHANGE' =>                   0x001E,
		'WM_CANCELMODE' =>                   0x001F,
		'WM_SETCURSOR' =>                    0x0020,
		'WM_MOUSEACTIVATE' =>                0x0021,
		'WM_CHILDACTIVATE' =>                0x0022,
		'WM_QUEUESYNC' =>                    0x0023,
		'WM_GETMINMAXINFO' =>                0x0024,
		'WM_PAINTICON' =>                    0x0026,
		'WM_ICONERASEBKGND' =>               0x0027,
		'WM_NEXTDLGCTL' =>                   0x0028,
		'WM_SPOOLERSTATUS' =>                0x002A,
		'WM_DRAWITEM' =>                     0x002B,
		'WM_MEASUREITEM' =>                  0x002C,
		'WM_DELETEITEM' =>                   0x002D,
		'WM_VKEYTOITEM' =>                   0x002E,
		'WM_CHARTOITEM' =>                   0x002F,
		'WM_SETFONT' =>                      0x0030,
		'WM_GETFONT' =>                      0x0031,
		'WM_SETHOTKEY' =>                    0x0032,
		'WM_GETHOTKEY' =>                    0x0033,
		'WM_QUERYDRAGICON' =>                0x0037,
		'WM_COMPAREITEM' =>                  0x0039,
		'WM_GETOBJECT' =>                    0x003D,
		'WM_COMPACTING' =>                   0x0041,
		'WM_WINDOWPOSCHANGING' =>            0x0046,
		'WM_WINDOWPOSCHANGED' =>             0x0047,
		'WM_POWER' =>                        0x0048,
		'WM_COPYDATA' =>                     0x004A,
		'WM_CANCELJOURNAL' =>                0x004B,
		'WM_NOTIFY' =>                       0x004E,
		'WM_INPUTLANGCHANGEREQUEST' =>       0x0050,
		'WM_INPUTLANGCHANGE' =>              0x0051,
		'WM_TCARD' =>                        0x0052,
		'WM_HELP' =>                         0x0053,
		'WM_USERCHANGED' =>                  0x0054,
		'WM_NOTIFYFORMAT' =>                 0x0055,
		'WM_CONTEXTMENU' =>                  0x007B,
		'WM_STYLECHANGING' =>                0x007C,
		'WM_STYLECHANGED' =>                 0x007D,
		'WM_DISPLAYCHANGE' =>                0x007E,
		'WM_GETICON' =>                      0x007F,
		'WM_SETICON' =>                      0x0080,
		'WM_NCCREATE' =>                     0x0081,
		'WM_NCDESTROY' =>                    0x0082,
		'WM_NCCALCSIZE' =>                   0x0083,
		'WM_NCHITTEST' =>                    0x0084,
		'WM_NCPAINT' =>                      0x0085,
		'WM_NCACTIVATE' =>                   0x0086,
		'WM_GETDLGCODE' =>                   0x0087,
		'WM_SYNCPAINT' =>                    0x0088,
		'WM_NCMOUSEMOVE' =>                  0x00A0,
		'WM_NCLBUTTONDOWN' =>                0x00A1,
		'WM_NCLBUTTONUP' =>                  0x00A2,
		'WM_NCLBUTTONDBLCLK' =>              0x00A3,
		'WM_NCRBUTTONDOWN' =>                0x00A4,
		'WM_NCRBUTTONUP' =>                  0x00A5,
		'WM_NCRBUTTONDBLCLK' =>              0x00A6,
		'WM_NCMBUTTONDOWN' =>                0x00A7,
		'WM_NCMBUTTONUP' =>                  0x00A8,
		'WM_NCMBUTTONDBLCLK' =>              0x00A9,
		'WM_KEYFIRST' =>                     0x0100,
		'WM_KEYDOWN' =>                      0x0100,
		'WM_KEYUP' =>                        0x0101,
		'WM_CHAR' =>                         0x0102,
		'WM_DEADCHAR' =>                     0x0103,
		'WM_SYSKEYDOWN' =>                   0x0104,
		'WM_SYSKEYUP' =>                     0x0105,
		'WM_SYSCHAR' =>                      0x0106,
		'WM_SYSDEADCHAR' =>                  0x0107,
		'WM_KEYLAST' =>                      0x0108,
		'WM_IME_STARTCOMPOSITION' =>         0x010D,
		'WM_IME_ENDCOMPOSITION' =>           0x010E,
		'WM_IME_COMPOSITION' =>              0x010F,
		'WM_IME_KEYLAST' =>                  0x010F,
		'WM_INITDIALOG' =>                   0x0110,
		'WM_COMMAND' =>                      0x0111,
		'WM_SYSCOMMAND' =>                   0x0112,
		'WM_TIMER' =>                        0x0113,
		'WM_HSCROLL' =>                      0x0114,
		'WM_VSCROLL' =>                      0x0115,
		'WM_INITMENU' =>                     0x0116,
		'WM_INITMENUPOPUP' =>                0x0117,
		'WM_MENUSELECT' =>                   0x011F,
		'WM_MENUCHAR' =>                     0x0120,
		'WM_ENTERIDLE' =>                    0x0121,
		'WM_MENURBUTTONUP' =>                0x0122,
		'WM_MENUDRAG' =>                     0x0123,
		'WM_MENUGETOBJECT' =>                0x0124,
		'WM_UNINITMENUPOPUP' =>              0x0125,
		'WM_MENUCOMMAND' =>                  0x0126,
		'WM_CTLCOLORMSGBOX' =>               0x0132,
		'WM_CTLCOLOREDIT' =>                 0x0133,
		'WM_CTLCOLORLISTBOX' =>              0x0134,
		'WM_CTLCOLORBTN' =>                  0x0135,
		'WM_CTLCOLORDLG' =>                  0x0136,
		'WM_CTLCOLORSCROLLBAR' =>            0x0137,
		'WM_CTLCOLORSTATIC' =>               0x0138,
		'WM_MOUSEFIRST' =>                   0x0200,
		'WM_MOUSEMOVE' =>                    0x0200,
		'WM_LBUTTONDOWN' =>                  0x0201,
		'WM_LBUTTONUP' =>                    0x0202,
		'WM_LBUTTONDBLCLK' =>                0x0203,
		'WM_RBUTTONDOWN' =>                  0x0204,
		'WM_RBUTTONUP' =>                    0x0205,
		'WM_RBUTTONDBLCLK' =>                0x0206,
		'WM_MBUTTONDOWN' =>                  0x0207,
		'WM_MBUTTONUP' =>                    0x0208,
		'WM_MBUTTONDBLCLK' =>                0x0209,
		'WM_MOUSEWHEEL' =>                   0x020A,
		'WM_MOUSELAST' =>                    0x020A,
		'WM_MOUSELAST' =>                    0x0209,
		'WM_PARENTNOTIFY' =>                 0x0210,
		'WM_ENTERMENULOOP' =>                0x0211,
		'WM_EXITMENULOOP' =>                 0x0212,
		'WM_NEXTMENU' =>                     0x0213,
		'WM_SIZING' =>                       0x0214,
		'WM_CAPTURECHANGED' =>               0x0215,
		'WM_MOVING' =>                       0x0216,
		'WM_POWERBROADCAST' =>               0x0218,
		'WM_DEVICECHANGE' =>                 0x0219,
		'WM_MDICREATE' =>                    0x0220,
		'WM_MDIDESTROY' =>                   0x0221,
		'WM_MDIACTIVATE' =>                  0x0222,
		'WM_MDIRESTORE' =>                   0x0223,
		'WM_MDINEXT' =>                      0x0224,
		'WM_MDIMAXIMIZE' =>                  0x0225,
		'WM_MDITILE' =>                      0x0226,
		'WM_MDICASCADE' =>                   0x0227,
		'WM_MDIICONARRANGE' =>               0x0228,
		'WM_MDIGETACTIVE' =>                 0x0229,
		'WM_MDISETMENU' =>                   0x0230,
		'WM_ENTERSIZEMOVE' =>                0x0231,
		'WM_EXITSIZEMOVE' =>                 0x0232,
		'WM_DROPFILES' =>                    0x0233,
		'WM_MDIREFRESHMENU' =>               0x0234,
		'WM_IME_SETCONTEXT' =>               0x0281,
		'WM_IME_NOTIFY' =>                   0x0282,
		'WM_IME_CONTROL' =>                  0x0283,
		'WM_IME_COMPOSITIONFULL' =>          0x0284,
		'WM_IME_SELECT' =>                   0x0285,
		'WM_IME_CHAR' =>                     0x0286,
		'WM_IME_REQUEST' =>                  0x0288,
		'WM_IME_KEYDOWN' =>                  0x0290,
		'WM_IME_KEYUP' =>                    0x0291,
		'WM_MOUSEHOVER' =>                   0x02A1,
		'WM_MOUSELEAVE' =>                   0x02A3,
		'WM_CUT' =>                          0x0300,
		'WM_COPY' =>                         0x0301,
		'WM_PASTE' =>                        0x0302,
		'WM_CLEAR' =>                        0x0303,
		'WM_UNDO' =>                         0x0304,
		'WM_RENDERFORMAT' =>                 0x0305,
		'WM_RENDERALLFORMATS' =>             0x0306,
		'WM_DESTROYCLIPBOARD' =>             0x0307,
		'WM_DRAWCLIPBOARD' =>                0x0308,
		'WM_PAINTCLIPBOARD' =>               0x0309,
		'WM_VSCROLLCLIPBOARD' =>             0x030A,
		'WM_SIZECLIPBOARD' =>                0x030B,
		'WM_ASKCBFORMATNAME' =>              0x030C,
		'WM_CHANGECBCHAIN' =>                0x030D,
		'WM_HSCROLLCLIPBOARD' =>             0x030E,
		'WM_QUERYNEWPALETTE' =>              0x030F,
		'WM_PALETTEISCHANGING' =>            0x0310,
		'WM_PALETTECHANGED' =>               0x0311,
		'WM_HOTKEY' =>                       0x0312,
		'WM_PRINT' =>                        0x0317,
		'WM_PRINTCLIENT' =>                  0x0318,
		'WM_HANDHELDFIRST' =>                0x0358,
		'WM_HANDHELDLAST' =>                 0x035F,
		'WM_AFXFIRST' =>                     0x0360,
		'WM_AFXLAST' =>                      0x037F,
		'WM_PENWINFIRST' =>                  0x0380,
		'WM_PENWINLAST' =>                   0x038F,

		'CB_GETEDITSEL' =>               0x0140,
		'CB_LIMITTEXT' =>                0x0141,
		'CB_SETEDITSEL' =>               0x0142,
		'CB_ADDSTRING' =>                0x0143,
		'CB_DELETESTRING' =>             0x0144,
		'CB_DIR' =>                      0x0145,
		'CB_GETCOUNT' =>                 0x0146,
		'CB_GETCURSEL' =>                0x0147,
		'CB_GETLBTEXT' =>                0x0148,
		'CB_GETLBTEXTLEN' =>             0x0149,
		'CB_INSERTSTRING' =>             0x014A,
		'CB_RESETCONTENT' =>             0x014B,
		'CB_FINDSTRING' =>               0x014C,
		'CB_SELECTSTRING' =>             0x014D,
		'CB_SETCURSEL' =>                0x014E,
		'CB_SHOWDROPDOWN' =>             0x014F,
		'CB_GETITEMDATA' =>              0x0150,
		'CB_SETITEMDATA' =>              0x0151,
		'CB_GETDROPPEDCONTROLRECT' =>    0x0152,
		'CB_SETITEMHEIGHT' =>            0x0153,
		'CB_GETITEMHEIGHT' =>            0x0154,
		'CB_SETEXTENDEDUI' =>            0x0155,
		'CB_GETEXTENDEDUI' =>            0x0156,
		'CB_GETDROPPEDSTATE' =>          0x0157,
		'CB_FINDSTRINGEXACT' =>          0x0158,
		'CB_SETLOCALE' =>                0x0159,
		'CB_GETLOCALE' =>                0x015A,

		'LB_ADDSTRING' =>            0x0180,
		'LB_INSERTSTRING' =>         0x0181,
		'LB_DELETESTRING' =>         0x0182,
		'LB_SELITEMRANGEEX' =>       0x0183,
		'LB_RESETCONTENT' =>         0x0184,
		'LB_SETSEL' =>               0x0185,
		'LB_SETCURSEL' =>            0x0186,
		'LB_GETSEL' =>               0x0187,
		'LB_GETCURSEL' =>            0x0188,
		'LB_GETTEXT' =>              0x0189,
		'LB_GETTEXTLEN' =>           0x018A,
		'LB_GETCOUNT' =>             0x018B,
		'LB_SELECTSTRING' =>         0x018C,
		'LB_DIR' =>                  0x018D,
		'LB_GETTOPINDEX' =>          0x018E,
		'LB_FINDSTRING' =>           0x018F,
		'LB_GETSELCOUNT' =>          0x0190,
		'LB_GETSELITEMS' =>          0x0191,
		'LB_SETTABSTOPS' =>          0x0192,
		'LB_GETHORIZONTALEXTENT' =>  0x0193,
		'LB_SETHORIZONTALEXTENT' =>  0x0194,
		'LB_SETCOLUMNWIDTH' =>       0x0195,
		'LB_ADDFILE' =>              0x0196,
		'LB_SETTOPINDEX' =>          0x0197,
		'LB_GETITEMRECT' =>          0x0198,
		'LB_GETITEMDATA' =>          0x0199,
		'LB_SETITEMDATA' =>          0x019A,
		'LB_SELITEMRANGE' =>         0x019B,
		'LB_SETANCHORINDEX' =>       0x019C,
		'LB_GETANCHORINDEX' =>       0x019D,
		'LB_SETCARETINDEX' =>        0x019E,
		'LB_GETCARETINDEX' =>        0x019F,
		'LB_SETITEMHEIGHT' =>        0x01A0,
		'LB_GETITEMHEIGHT' =>        0x01A1,
		'LB_FINDSTRINGEXACT' =>      0x01A2,
		'LB_SETLOCALE' =>            0x01A5,
		'LB_GETLOCALE' =>            0x01A6,
		'LB_SETCOUNT' =>             0x01A7,
		'LB_INITSTORAGE' =>          0x01A8,
		'LB_ITEMFROMPOINT' =>        0x01A9,
		'LB_MSGMAX' =>               0x01B0,
		'LB_MSGMAX' =>               0x01A8,
	};
}


1;

__END__

=head1 NAME

Win32::CtrlGUI::Window - OO interface for controlling Win32 GUI windows

=head1 VERSION

This document describes version 0.32 of
Win32::CtrlGUI::Window, released January 10, 2015
as part of Win32-CtrlGUI version 0.32.

=head1 SYNOPSIS

  use Win32::CtrlGUI

  my $window = Win32::CtrlGUI::wait_for_window(qr/Notepad/);
  $window->send_keys("!fx");

=head1 DESCRIPTION

C<Win32::CtrlGUI::Window> objects represent GUI windows, and are used to
interact with those windows.

=head1 METHODS

=head2 _new

This method is titled C<_new> because it would rarely get called by user-level
code.  It takes a passed window handle and returns a C<Win32::CtrlGUI::Window>
object.

=head2 handle

This method returns the window's handle.  Rarely used because the numification
operator for C<Win32::CtrlGUI::Window> is overloaded to call it.

=head2 text

This method returns the window's text.  Rarely used because the stringification
operator for C<Win32::CtrlGUI::Window> is overloaded to call it.  Thus, instead
of writing C<print $window-E<gt>text,"\n";>, one can simply write C<print
$window,"\n";>  If you want to print out the handle number, write C<print
$window-E<gt>handle,"\n"> or C<print int($window),"\n">.

If the window no longer exists, the method will return undef;

=head2 exists

Calls C<Win32::Setupsup::WaitForWindowClose> with a timeout of 1ms to determine
whether the window still exists or not.  Returns true if the
C<Win32::CtrlGUI::Window> object still refers to an existing window, returns
false if it does not.

=head2 send_keys

The C<send_keys> method sends keystrokes to the window.  The first parameter is
the text to send. The second parameter is optional and specifies the interval
between sending keystrokes, in milliseconds.

If the window no longer exists, this method will die with the error
"Win32::CtrlGUI::Window::send_keys called on non-existent window handle
I<handle>."

I found the C<SendKeys> syntax used by C<Win32::Setupsup> to be rather
unwieldy.  I missed the syntax used in WinBatch, so I implemented a conversion
routine.  At the same time, I extended the syntax a little.  I think you'll
like the result.

The meta-characters are:

=over 4

=item !

Holds the Alt key down for the next character

=item ^

Holds the Ctrl key down for the next character

=item +

Holds the Shift key down for the next character

=item { and }

Used to send special characters, sequences, or for sleeping

=back

The C<!>, C<^>, and C<+> characters can be combined.  For instance, to send a
Ctrl-Shift-F7, one uses the sequence C<^+{F7}>.

The special characters sendable using the curly braces are:

  Alt         {ALT}
  Backspace   {BACKSPACE} or {BS} or {BACK}
  Clear       {CLEAR}
  Delete      {DELETE} or {DEL}
  Down Arrow  {DOWN} or {DN}
  End         {END}
  Enter       {ENTER} or {RET}
  Escape      {ESCAPE} or {ESC}
  F1->F12     {F1}->{F12}
  Help        {HELP}
  Home        {HOME} or {BEG}
  Insert      {INSERT} or {INS}
  Left Arrow  {LEFT}
  NumKey 0->9 {NUM0}->{NUM9}
  NumKey /*-+ {NUM/} or {NUM*} or {NUM-} or {NUM+}
  Page Down   {PGDN}
  Page Up     {PGUP}
  Right Arrow {RIGHT}
  Space       {SPACE} or {SP}
  Tab         {TAB}
  Up Arrow    {UP}

  !           {!}
  ^           {^}
  +           {+}
  }           {}}
  {           {{}

If the character name is followed by a space and an integer, the key will be
repeated that many times.  For instance, to send 15 down arrows keystrokes, use
C<{DOWN 15}>.  To send 5 asterisks, use C<{* 5}>.  This doesn't work for
sending multiple number keys (unless you use NUM0 or some such).

Finally, if the contents of the {} block are a number - either integer or
floating point, a pause will be inserted at the point.  For instance,
C<$window-E<gt>send_keys("!n{2.5}C:\\Foo.txt{1}{ENTER}")> is equivalent to:

  $window->send_keys("!n");
  Win32::Sleep(2500);
  $window->send_keys("C:\\Foo.txt");
  Win32::Sleep(1000);
  $window->send_keys("{ENTER}");

Hope you like the work.

=head2 enum_child_windows

Returns a list of the window's child windows.  They are, of course,
C<Win32::CtrlGUI::Window> objects.

If the window no longer exists, the method will return undef;

=head2 has_child

Checks to see whether the window has a child window matching the passed
criteria.  Same criteria options as found in
C<Win32::CtrlGUI::wait_for_window>.  Returns 0 or 1.

If the window no longer exists, the method will return undef;

=head2 set_focus

Calls C<Win32::Setupsup::SetFocus> on the window.  See the
C<Win32::Setupsup::SetFocus> documentation for caveats concerning this method.

If the window no longer exists, this method will die with the error
"Win32::CtrlGUI::Window::set_focus called on non-existent window handle
I<handle>."

=head2 get_properties

Calls C<Win32::Setupsup::GetWindowProperties> on the window.  Passes the list
of requested properties and returns the list of returned values in the same
order.

If the window no longer exists, the method will return undef;

=head2 get_property

Scalar variant of the above.

=head2 set_properties

Calls C<Win32::Setupsup::SetWindowProperties> on the window.

If the window no longer exists, this method will die with the error
"Win32::CtrlGUI::Window::set_properties called on non-existent window handle
I<handle>."

=head2 send_message

This requires C<Win32::API>.  This makes the C<SendMessage> API call on the
window handle in question.  See the Win32 SDK for more information on what
messages can be sent to windows and what their effects are.

The passed parameters are:

=over 4

=item type

This should be a string consisting of two characters, both of which are either
C<N> or C<P>.  Pass C<N> if the parameter is of type C<DWORD> and C<P> if the
parameter is a string to which a pointer should be passed.

=item msg

This should be either the numerical value for the message or a string
specifying the constant (it will be looked up in a table of known constants,
such as C<WM_GETTEXT> and C<WM_RBUTTONDOWN>).

=item param1 and param2

These will be passed directly into the C<SendMessage> call as the two message
parameters.

=back

=head2 post_message

This is the C<PostMessage> version of C<send_message>.

=head2 get_text

This makes use of the C<send_message> method, and so it also requires
C<Win32::API>.  It uses the C<WM_GETTEXT> message to retrieve the text of a
window or control.  This has the advantage of retrieving the text of text
boxes.  Note that this method will block if called on hung windows.

=head2 lb_get_items

This makes use of the C<send_message> method, and so it also requires
C<Win32::API>.  It uses the C<LB_GETCOUNT>, C<LB_GETTEXTLEN>, and C<LB_GETTEXT>
messages to retrieve the text for the items in the list box.  Note that this
method will block if called on hung windows.

=head2 lb_get_selindexes

This makes use of the C<send_message> method, and so it also requires
C<Win32::API>.  It uses the C<LB_GETCURSEL>, C<LB_GETSELCOUNT>, and
C<LB_GETSELITEMS> messages to retrieve the indexes for the selected items in
the list box.  Note that this method will block if called on hung windows.

=head2 lb_set_selindexes

This makes use of the C<send_message> method, and so it also requires
C<Win32::API>.  It uses the C<LB_SETCURSEL>, C<LB_GETCOUNT>, and C<LB_SETSEL>
messages to specify the selected item(s) in the list box.

=head2 cb_get_items

This makes use of the C<send_message> method, and so it also requires
C<Win32::API>.  It uses the C<CB_GETCOUNT>, C<CB_GETLBTEXTLEN>, and
C<CB_GETLBTEXT> messages to retrieve the text for the items in the combo box.
Note that this method will block if called on hung windows.

=head2 cb_get_selindex

This makes use of the C<send_message> method, and so it also requires
C<Win32::API>.  It uses the C<CB_GETCURSEL> message to retrieve the index for
the selected item in the combo box.  Note that this method will block if called
on hung windows.

=head2 cb_set_selindex

This makes use of the C<send_message> method, and so it also requires
C<Win32::API>.  It uses the C<LB_SETCURSEL> message to specify the selected
item in the combo box.

=for Pod::Coverage
# FIXME: Should these be documented?
init
init_atom_map
init_constant_hash

=head1 GLOBALS

=head2 $Win32::CtrlGUI::Window::sendkey_activate

I couldn't think of any reason that anyone would B<not> want to activate the
window before sending it keys (especially given the way this OO front-end
works), but if you do find yourself in that situation, change this to 0.

=head2 $Win32::CtrlGUI::Window::sendkey_intvl

This global parameter specifies the I<default> interval between keystrokes when
executing a C<send_keys>.  The value is specified in milliseconds.  The
C<send_keys> method also takes an optional parameter that will override this
value.  The default value is 0.

=head1 CONFIGURATION AND ENVIRONMENT

Win32::CtrlGUI::Window requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Toby Ovod-Everett  S<C<< <toby AT ovod-everett.org> >>>

Win32::CtrlGUI is now maintained by
Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Win32-CtrlGUI AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-CtrlGUI >>.

You can follow or contribute to Win32-CtrlGUI's development at
L<< http://github.com/madsen/win32-ctrlgui >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Toby Ovod-Everett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
