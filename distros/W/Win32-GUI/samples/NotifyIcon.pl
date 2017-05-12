#!perl w

# Notify Icon Tester
# A Win32::GUI program to show off the capabilities of
# the Windows Taskbar notification icons.
# Really written to prove the functionality added to
# Win32::GUI, but also an interesting demo.

# (c) 2005 Robert May

# See the Help Menu in the program or embedded POD
# for further information

# TODO:
# Add tooltip to icon filename when it is truncated

use strict;
use warnings;

use Win32();
use Win32::GUI 1.03_02, qw(MB_OK MB_ICONHAND ES_WANTRETURN WS_CLIPCHILDREN WS_EX_TOPMOST);
use Win32::GUI::BitmapInline();

sub CW_USEDEFAULT()   {0x80000000};
sub WM_NOTIFYICON()   {32768 + 2};   # WM_APP + 2

my $VERSION = "1.01";

my %event_lookup = (
	512 => "MouseEvent(WM_MOUSEMOVE)",          # WM_MOUSEMOVE
	513 => "Click()",                           # WM_LBUTTONDOWN
	514 => "MouseEvent(WM_LBUTTONUP)",          # WM_LBUTTONUP
	515 => "DblClick()",                        # WM_LBUTTONDBLCLICK
	516 => "RightClick()",                      # WM_RBUTTONDOWN
	517 => "MouseEvent(WM_RBUTTONUP)",          # WM_RBUTTONUP
	518 => "RightDblClick()",                   # WM_RBUTTONDBLCLICK
	519 => "MiddleClick()",                     # WM_MBUTTONDOWN
	520 => "MouseEvent(WM_MBUTTONUP)",          # WM_MBUTTONUP
	521 => "MiddleDlbClick()",                  # WM_MBUTTONDBLCLICK

	1024 => "MouseEvent(NIN_SELECT)",           # NIN_SELECT v5+
	1025 => "MouseEvent(NIN_KEYSELECT)",        # NIN_KEYSELECT v5+
	1026 => "MouseEvent(NIN_BALLOONSHOW)",      # NIN_BALLOONSHOW v6+
	1027 => "MouseEvent(NIN_BALLOONHIDE)",      # NIN_BALLOONSHOW v6+
	1028 => "MouseEvent(NIN_BALLOONTIMEOUT)",   # NIN_BALLOONTIMEOUT v6+
	1029 => "MouseEvent(NIN_BALLOONUSERCLICK)", # NINBALLOONUSERCLICK v6+
);
	
my %cfg = (
	defaulticon => get_defaulticon(),
	iconfile    => undef,
	icon        => undef,
	ni          => undef,
	'v5'        => ($Win32::GUI::NotifyIcon::SHELLDLL_VERSION >= 5),
	events      => [],
	max_events  => 100,
);
$cfg{icon} = $cfg{defaulticon};

######################################################################
# Main menu
######################################################################
my $menu = Win32::GUI::Menu->new(
	"&File"             => "File",
	">&Change Icon ..." => { -name => "File_Chan",  -onClick => \&change_icon },
	"> -"               => 0,
	"> E&xit"           => { -name => "File_Exit",  -onClick => sub{-1} },
	"&Help"             => "Help",
	"> &Help"           => { -name => "Help_Help",  -onClick => \&OnHelp  },
	"> &About"          => { -name => "Help_About", -onClick => \&OnAbout },
);

######################################################################
# Main window
######################################################################
my $mw = Win32::GUI::Window->new(
	-title       => "Notify Icon Tester",
	-left        => CW_USEDEFAULT,
	-size        => [100,100],
	-resizable   => 0,
	-maximizebox => 0,
	-menu        => $menu,
	-dialogui    => 1,
);
$mw->Hook(WM_NOTIFYICON, \&record_event);

######################################################################
# Layout
######################################################################

# Primarily a 2 column layout:
my $col1_width = 235;
my $col2_width = 255;

my $padding = 10;
my $margin = 10;

my $col1_left       = 0;
my $col1_gb_left    = $col1_left + $padding;
my $col1_ctrl_left  = $col1_gb_left + $padding;
my $col1_gb_right   = $col1_left + $col1_width - ($padding/2);  # collapse padding between columns
my $col1_ctrl_right = $col1_gb_right - $padding;

my $col2_left       = $col1_width;
my $col2_gb_left    = $col2_left + ($padding/2);
my $col2_ctrl_left  = $col2_gb_left + $padding;
my $col2_gb_right   = $col2_left + $col2_width - $padding;
my $col2_ctrl_right = $col2_gb_right - $padding;

my $row1_gb_top = 0;  # no padding at top

######################################################################
# Version Information group
######################################################################
$mw->AddGroupbox(
	-name  => "VGB",
	-title => "Version Information",
	-left  => $col1_gb_left,
	-top   => $row1_gb_top,
	-width => $col1_gb_right - $col1_gb_left,
);

$mw->AddLabel(
	-text  => "Win32::GUI\t\t$Win32::GUI::VERSION",
	-left  => $col1_ctrl_left,
	-top   => $row1_gb_top + (2 * $padding),
	-width => $mw->VGB->Width() - (2 * $padding),
);

$mw->AddLabel(
	-text  => "shell32.dll\t\t" . Win32::GUI::GetDllVersion("shell32"),
	-left  => $col1_ctrl_left,
	-top   => $row1_gb_top + (4 * $padding),
	-width => $mw->VGB->Width() - (2 * $padding),
);

$mw->AddLabel(
	-name  => "VL3",
	-text  => "Notify Icon Tester\t$VERSION",
	-left  => $col1_ctrl_left,
	-top   => $row1_gb_top + (6 * $padding),
	-width => $mw->VGB->Width() - (2 * $padding),
);

my $row1_gb_bottom = $mw->VL3->Top() + $mw->VL3->Height() + $padding;
$mw->VGB->Height($row1_gb_bottom - $row1_gb_top);

my$row2_gb_top = $row1_gb_bottom + $padding;
######################################################################
# Icon selection group
######################################################################
$mw->AddGroupbox(
	-name  => "IGB",
	-title => "Tray &Icon",
	-left  => $col1_gb_left,
	-top   => $row2_gb_top,
	-width => $col1_gb_right - $col1_gb_left,
	-group => 1,
);

$mw->AddCheckbox(
	-name    => "ICB",
	-text    => "Use Default Icon",
	-left    => $col1_ctrl_left,
	-top     => $row2_gb_top + 20,
	-onClick => \&toggle_icon,
	-tabstop => 1,
);

$mw->AddLabel(
	-name     => "IL",
	-text     => "Placeholder",
	-truncate => "path",  # only Win NT and higher - see update_ui()
	-left     => $col1_ctrl_left,
	-top      => $mw->ICB->Top() + $mw->ICB->Height() + 4,
	-width    => $col1_ctrl_right - $col1_ctrl_left,
);

$mw->AddButton(
	-name    => "IB",
	-text    => "Change Icon ...",
	-top     => $row2_gb_top + 20,
	-onClick => \&change_icon,
	-tabstop => 1,
);
$mw->IB->Left($col1_ctrl_right - $mw->IB->Width());

my $row2_gb_bottom = $mw->IL->Top() + $mw->IL->Height() + $margin;
$mw->IGB->Height($row2_gb_bottom - $row2_gb_top);

######################################################################
# Events groupbox
######################################################################
$mw->AddGroupbox(
	-title  => "&Events",
	-left   => $col2_gb_left,
	-top    => $row1_gb_top,
	-width  => $col2_gb_right - $col2_gb_left,
	-height => $row2_gb_bottom - $row1_gb_top,
	-group  => 1,
);

$mw->AddRadioButton(
	-name    => "ERB1",
	-text    => "Win95",
	-checked => 1,
	-left    => $col2_ctrl_left,
	-top     => $row1_gb_top + 20,
	-onClick => sub { $cfg{ni}->SetBehaviour(0) if $cfg{ni}; 1;},
	-tabstop => 1,
	-group   => 1,
);

$mw->AddRadioButton(
	-name    => "ERB2",
	-text    => "Win2k",
	-left    => $col2_ctrl_left + $mw->ERB1->Width() + 4,
	-top     => $row1_gb_top + 20,
	-onClick => sub { $cfg{ni}->SetBehaviour(1) if $cfg{ni}; 1;},
);

$mw->AddTextfield(
	-name       => "ETF",
	-multiline  => 1,
	-vscroll    => 1,
	-readonly   => 1,
	-background => 0xFFFFFF,
	-left       => $col2_ctrl_left,
	-top        => $mw->ERB1->Top() + $mw->ERB1->Height() + 4,
	-width      => $col2_ctrl_right - $col2_ctrl_left,
	-height     => $row2_gb_bottom - $margin - ($mw->ERB1->Top() + $mw->ERB1->Height() + 4),
	-tabstop    => 1,
	-group      => 1,
);

my$row3gb_top = $row2_gb_bottom + $padding;
######################################################################
# Simple Tooltip groupbox
######################################################################
$mw->AddGroupbox(
	-name  => "TGB",
	-title => "&Tooltip",
	-left  => $col1_gb_left,
	-top   => $row3gb_top,
	-width => $col2_gb_right - $col1_gb_left,
	-group => 1,
);

$mw->AddTextfield(
	-name     => "TTF",
	-text     => "Simple Tooltip Text",
	-prompt   => [ "Text", 30 ],
	-left     => $col1_ctrl_left,
	-top      => $row3gb_top + 20,
	-height   => 20,
	-width    => $col2_ctrl_right - $col1_ctrl_left - 30,
	-onChange => sub { $cfg{ni}->Change(-tip => $_[0]->Text()) if $cfg{ni}; 0;},
	-tabstop  => 1,
);
$mw->TTF->LimitText($cfg{v5} ? 127 : 63);

my $row3_gb_bottom = $mw->TTF->Top() + $mw->TTF->Height() + $margin;
$mw->TGB->Height($row3_gb_bottom - $row3gb_top);

my $row4_gb_top = $row3_gb_bottom + $padding;
######################################################################
# Balloon Tooltip groupbox
######################################################################
$mw->AddGroupbox(
	-name  => "BGB",
	-title => "&Balloon Tooltip",
	-left  => $col1_gb_left,
	-top   => $row4_gb_top,
	-width => $col2_gb_right - $col1_gb_left,
	-group => 1,
);

$mw->AddTextfield(
	-name     => "BTF1",
	-text     => "Balloon Title",
	-prompt   => [ "Title", 30 ],
	-left     => $col1_ctrl_left,
	-top      => $row4_gb_top + 20,
	-width    => $col1_gb_right - $col1_ctrl_left + 70, 
	-height   => 20,
	-onChange => sub { change_balloon("title" => $_[0]->Text()); },
	-tabstop  => 1,
);
$mw->BTF1->LimitText(63);

$mw->AddTextfield(
	-name      => "BTF2",
	-text      => "Balloon tip text.",
	-prompt    => [ "Body", 30 ],
	-multiline => 1,
	-vscroll   => 1,
	-pushstyle => ES_WANTRETURN,
	-left      => $col1_ctrl_left,
	-top       => $mw->BTF1->Top() + $mw->BTF1->Height() + 4,
	-height    => 100,
	-width     => $col1_gb_right - $col1_ctrl_left + 70, 
	-onChange  => sub { change_balloon("tip" => $_[0]->Text()); },
	-tabstop   => 1,
);
$mw->BTF2->LimitText(254);

my $row4_gb_bottom = $mw->BTF2->Top() + $mw->BTF2->Height() + $margin;
$mw->BGB->Height($row4_gb_bottom - $row4_gb_top);

$mw->AddTextfield(
	-name     => "BTF3",
	-text     => "10000",
	-prompt   => [ "Timeout", -45 ],
	-number   => 1,
	-left     => $col2_ctrl_right - 65,
	-top      => $row4_gb_top + 20,
	-height   => 20,
	-width    => 45,
	-onChange => sub { change_balloon("timeout" => $_[0]->Text()); },
	-tabstop  => 1,
);
$mw->BTF3->LimitText(5);

$mw->AddLabel(
	-name => "BL1",
	-text => "ms",
	-left => $mw->BTF3->Left() + $mw->BTF3->Width() + 4,
	-top  => $mw->BTF3->Top(),
);

$mw->AddLabel(
	-name => "BL2",
	-text => "Icon",
	-left => $mw->BTF3_Prompt->Left(),
	-top  => $mw->BTF3->Top() + $mw->BTF3->Height() + 7,
);

$mw->AddCombobox(
	-name         => "BCB",
	-dropdownlist => 1,
	-left         => $col2_ctrl_right - 65,
	-top          => $mw->BTF3->Top() + $mw->BTF3->Height() + 4,
	-height       => 80,
	-width        => 65,
	-onChange     => sub { change_balloon("icon" => $_[0]->Text()); },
	-tabstop      => 1,
);
$mw->BCB->Add('none', 'info', 'warning', 'error');
$mw->BCB->SetCurSel(0);

$mw->AddCheckbox(
	-name    => "BCBB",
	-text    => "Show while editing",
	-left    => $mw->BTF3_Prompt->Left(),
	-top     => $mw->BCB->Top() + $mw->BCB->Height() + 4,
	-tabstop => 1,
);

$mw->AddButton(
	-name    => "BB1",
	-text    => "Show Balloon",
	-left    => $col2_ctrl_right - 81,
	-top     => $row4_gb_bottom - $margin - 4 - (2 * 21),
	-width   => 81,
	-height  => 21,
	-onClick => sub { $cfg{ni}->ShowBalloon(0),$cfg{ni}->ShowBalloon(1) if $cfg{ni}; 1;},
	-tabstop => 1,
	-group   => 1,
);

$mw->AddButton(
	-name    => "BB2",
	-text    => "Hide Balloon",
	-left    => $col2_ctrl_right - 81,
	-top     => $row4_gb_bottom - $margin - (1 * 21),
	-width   => 81,
	-height  => 21,
	-onClick => sub { $cfg{ni}->ShowBalloon(0) if $cfg{ni}; 1;},
	-tabstop => 1,
);

######################################################################
# Show/Remove Notify Icon Button
######################################################################
$mw->AddButton(
	-name    => "SB",
	-top     => $row4_gb_bottom + $padding,
	-size    => [110,21],
	-onClick => \&toggle_ni_state,
	-tabstop => 1,
	-group   => 1,
);
$mw->SB->Left($col2_gb_right - $mw->SB->Width());

my $ncw = $mw->Width() - $mw->ScaleWidth();
my $nch = $mw->Height() - $mw->ScaleHeight();
$mw->Resize($ncw + $col1_width + $col2_width, $nch + $mw->SB->Top() + $mw->SB->Height() + $padding);

update_ui();
$mw->Show();
Win32::GUI::Dialog();
$mw->Hide();
undef $mw;
exit(0);

sub toggle_icon
{
	if($cfg{icon} == $cfg{defaulticon}) {
		my $icon;
		$icon = Win32::GUI::Icon->new($cfg{iconfile}) if ($cfg{iconfile});

		if($icon) {
			$cfg{icon} = $icon;
		}
		else {
			$cfg{iconfile} = undef;
		}
	}
	else {
		$cfg{icon} = $cfg{defaulticon};
	}

	$cfg{ni}->Change(-icon => $cfg{icon}) if $cfg{ni};

	update_ui();
	return;
}

sub change_icon
{
	my $win = shift;

	my $file = Win32::GUI::GetOpenFileName (
		-owner        => $win,
		-filter       =>
			[ 'Icon files (*.ico)', '*.ico',
			  'All Files',          '*'   ],
		-title         => 'Select a new icon',
		-defaultfilter => 0,
		-filemustexist => 1,
		-pathmustexist => 1,
	); 

	my $icon;
	$icon = Win32::GUI::Icon->new($file) if ($file);

	if($icon) {
		$cfg{icon} = $icon;
		$cfg{iconfile} = $file;
	}
	else {
		$win->MessageBox(
			"$file does not appear to be valid icon format",
			"Notify Icon Tester error",
			MB_OK|MB_ICONHAND,
		) if $file;
	}

	$cfg{ni}->Change(-icon => $cfg{icon}) if $cfg{ni};

	update_ui();
	return;
}

sub toggle_ni_state
{
	my $win = $_[0]->GetParent();

	if($cfg{ni}) {
		$cfg{ni}->Remove();
		undef $cfg{ni};
	}
	else {
		$cfg{ni} = $win->AddNotifyIcon(
			-icon            => $cfg{icon},
			-tip             => $win->TTF->Text(),
			-balloon         => 0,
			-balloon_tip     => $win->BTF2->Text(),
			-balloon_title   => $win->BTF1->Text(),
			-balloon_timeout => $win->BTF3->Text(),
			-balloon_icon    => $win->BCB->Text(),
		);
	}

	update_ui();
	return;
}

sub change_balloon
{
	my $item = shift;
	my $value = shift;
	if($cfg{ni}) {
		$cfg{ni}->Change("-balloon_$item" => $value);
		if($mw->BCBB->Checked()) {
			$cfg{ni}->ShowBalloon(0);
			$cfg{ni}->ShowBalloon(1);
		}
	}

   	update_ui();
	return 0;
}

sub update_ui
{
	$mw->ICB->Checked($cfg{defaulticon} == $cfg{icon});
	$mw->ICB->Enable(defined $cfg{iconfile} || ($cfg{defaulticon} != $cfg{icon}));
	{
		my $text = "Icon file: " . ($cfg{iconfile} ? $cfg{iconfile} : " -  Not Set  -");
		if(Win32::GetOSVersion() < 2) { # implement -truncate => 'path' for Win9X/ME
			my $font = $mw->IL->GetFont();
			my $width  = $mw->IL->Width();
			if(($mw->IL->GetTextExtentPoint32($text,$font))[0] > $width) {
				my($trunc, $keep);
				if($text =~ m/^(.*)(\\[^\\]*)$/) {
					$trunc = $1;
					$keep  = $2;
				}
				else {
					$trunc = '';
					$keep  = $text;
				}
				while(($mw->IL->GetTextExtentPoint32($trunc."...".$keep,$font))[0] > $width) {
					$trunc = substr($trunc,0,-1), next if length $trunc;
					$keep  = substr($keep,1),     next if length $keep;
					last;  # ensure we exit this loop
				}
				$text=$trunc."...".$keep;
			}
		}
		$mw->IL->Text($text);
	}
	$mw->IL->Enable($cfg{defaulticon} != $cfg{icon});

	$mw->ERB1->Enable($cfg{v5});
	$mw->ERB2->Enable($cfg{v5});

	$mw->BGB->Enable ($cfg{v5});
	$mw->BTF1_Prompt->Enable($cfg{v5});
	$mw->BTF1->Enable($cfg{v5});
	$mw->BTF2_Prompt->Enable($cfg{v5});
	$mw->BTF2->Enable($cfg{v5});
	$mw->BTF3_Prompt->Enable($cfg{v5});
	$mw->BTF3->Enable($cfg{v5});
	$mw->BL1->Enable ($cfg{v5});
	$mw->BCB->Enable ($cfg{v5} && (length $mw->BTF1->Text() > 0));
	$mw->BL2->Enable ($cfg{v5} && (length $mw->BTF1->Text() > 0));
	$mw->BCBB->Enable($cfg{v5});
	$mw->BB1->Enable ($cfg{v5} && defined($cfg{ni}) && (length $mw->BTF2->Text() > 0));
	$mw->BB2->Enable ($cfg{v5} && defined($cfg{ni}));

	$mw->SB->Text(($cfg{ni} ? "Remove" : "Show") . " Notify Icon");

	return;
}

sub record_event
{
	my ($win, $id, $lParam, $type, $msgcode) = @_;
	return unless $msgcode == WM_NOTIFYICON;
	return unless $type == 0;

	# Event numbers are in lParam

	# decode event
	my $event;
	$event = $event_lookup{$lParam} if exists $event_lookup{$lParam};
	$event = "$lParam (unknown)" unless $event;

	push @{$cfg{events}}, $event;

	while (@{$cfg{events}} > $cfg{max_events}) {
		shift @{$cfg{events}}
	}

	$win->ETF->SetSel(0,-1);
	$win->ETF->ReplaceSel(join("\r\n", @{$cfg{events}}));

	return;
}

sub get_defaulticon
{
	return newIcon Win32::GUI::BitmapInline( q(
AAABAAIAICAQAAAAAADoAgAAJgAAACAgAAAAAAAAqAgAAA4DAAAoAAAAIAAAAEAAAAABAAQAAAAA
AIACAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAMDAwACAgIAA
AAD/AAD/AAAA//8A/wAAAP8A/wD//wAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIgAd3AAiIAAAAAAAAAAAAgHgIcACAiAAAAAAAAAAAAI
CIiAAAAIAAAAAAAAAAAAAAiIAAAAAAAAAAAAAAAAAIgHiAAAAAAAAAAAAAAAAACIB3cACAAAAAAA
AAAAAAAACIB3gAAAAAgAAAAAAAAAAAAIgIiAAAAAAAAAAAAAAAAAAAAAiAiAgAAAAAAAAAAAAAAA
AAeIiAAAAAAAAAAAAAAIgIAAiAiAAAAAAAAAAAAAAIdwAACAAAAAAAAAAAAAgAAABwAAAAAAAAAA
AAAAAAAICHcAAAAAAAAAAAAAAAAACAB3cHAACIgAAAAAAAAIAAiId3gIAAgHAAAAAAAAAAiAB3d4
AIAABwAAAAAAAId3d3eIiAAAAAgAAAAAh3eHd3dwAAiAAACAAAAACAh3d3d3AAAHeAAAAAAAAAAA
iAh3dwCIAAgIeAAAAAAACIiHAHAAh3gAgHAAAAAAAAgACIAACAeIgICAAAAAAAAAAAAAAACIcAiA
AAAAAAAAAAAAAAAAAAAIiAAAAAAAAAAAAAAAAIAACIAAAAAAAAAAAAAAAAAIgIAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/////////////////wAAf/8AAH//AAB//wAAf/8A
AH//AAB//wAAP/8AAD//AAA//4AAH/+AAB//wAAf/8AAH//gAB//4AAP/4AAD/gAAA/4AAAP8AAA
H+AAAD/wAAA/+AAAP/iAAH//+AD///4A////Af///4f///////////8oAAAAIAAAAEAAAAABAAgA
AAAAAIAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAMDAwADA
3MAA8MqmANTw/wCx4v8AjtT/AGvG/wBIuP8AJar/AACq/wAAktwAAHq5AABilgAASnMAADJQANTj
/wCxx/8Ajqv/AGuP/wBIc/8AJVf/AABV/wAASdwAAD25AAAxlgAAJXMAABlQANTU/wCxsf8Ajo7/
AGtr/wBISP8AJSX/AAAA/gAAANwAAAC5AAAAlgAAAHMAAABQAOPU/wDHsf8Aq47/AI9r/wBzSP8A
VyX/AFUA/wBJANwAPQC5ADEAlgAlAHMAGQBQAPDU/wDisf8A1I7/AMZr/wC4SP8AqiX/AKoA/wCS
ANwAegC5AGIAlgBKAHMAMgBQAP/U/wD/sf8A/47/AP9r/wD/SP8A/yX/AP4A/gDcANwAuQC5AJYA
lgBzAHMAUABQAP/U8AD/seIA/47UAP9rxgD/SLgA/yWqAP8AqgDcAJIAuQB6AJYAYgBzAEoAUAAy
AP/U4wD/sccA/46rAP9rjwD/SHMA/yVXAP8AVQDcAEkAuQA9AJYAMQBzACUAUAAZAP/U1AD/sbEA
/46OAP9rawD/SEgA/yUlAP4AAADcAAAAuQAAAJYAAABzAAAAUAAAAP/j1AD/x7EA/6uOAP+PawD/
c0gA/1clAP9VAADcSQAAuT0AAJYxAABzJQAAUBkAAP/w1AD/4rEA/9SOAP/GawD/uEgA/6olAP+q
AADckgAAuXoAAJZiAABzSgAAUDIAAP//1AD//7EA//+OAP//awD//0gA//8lAP7+AADc3AAAubkA
AJaWAABzcwAAUFAAAPD/1ADi/7EA1P+OAMb/awC4/0gAqv8lAKr/AACS3AAAerkAAGKWAABKcwAA
MlAAAOP/1ADH/7EAq/+OAI//awBz/0gAV/8lAFX/AABJ3AAAPbkAADGWAAAlcwAAGVAAANT/1ACx
/7EAjv+OAGv/awBI/0gAJf8lAAD+AAAA3AAAALkAAACWAAAAcwAAAFAAANT/4wCx/8cAjv+rAGv/
jwBI/3MAJf9XAAD/VQAA3EkAALk9AACWMQAAcyUAAFAZANT/8ACx/+IAjv/UAGv/xgBI/7gAJf+q
AAD/qgAA3JIAALl6AACWYgAAc0oAAFAyANT//wCx//8Ajv//AGv//wBI//8AJf//AAD+/gAA3NwA
ALm5AACWlgAAc3MAAFBQAPLy8gDm5uYA2traAM7OzgDCwsIAtra2AKqqqgCenp4AkpKSAIaGhgB6
enoAbm5uAGJiYgBWVlYASkpKAD4+PgAyMjIAJiYmABoaGgAODg4A8Pv/AKSgoACAgIAAAAD/AAD/
AAAA//8A/wAAAP8A/wD//wAA////AOnp6enp6enp6enp6enp6enp6enp6enp6enp6enp6enr5+T/
//////8AAAAA6+sAAAcHBwAAAOvr6///////5Ovn5P///////wAAAOsAB+sA6wcAAADrAOvr////
///k6+fk////////AAAA6wDr6+vrAAAAAAAA6wD//////+Tr5+T///////8AAAAAAOvr6wAAAAAA
AAAAAP//////5Ovn5P///////wAA6+sAB+vrAAAAAAAAAAAA///////k6+fk////////AADr6wAH
BwcAAADrAAAAAAD//////+Tr5+T///////8AAADr6wAHB+sAAAAAAAAAAOv/////5Ovn5P//////
/wAAAAAA6+sA6+vrAAAAAAAAAP/////k6+fk////////AAAAAAAAAAAAAOvrAOvrAOsA/////+Tr
5+T/////////AAAAAAAAAAAAAAfr6+vrAAAA////5Ovn5P////////8AAAAA6+sA6wAAAOvrAOvr
AAD////k6+fk//////////8AAAAA6wcHAAAAAADrAAAAAP///+Tr5+T//////////+sAAAAAAAAH
AAAAAAAAAAAA////5Ovn5P///////////wAA6wDrBwcAAAAAAAAAAAD////k6+fk////////////
AADrAAAHBwcABwAAAADr6+v//+Tr5+T/////////6wAAAOvr6wcHB+sA6wAAAOsAB///5Ovn5P//
/wAAAAAAAOvrAAAHBwcH6wAA6wAAAAAH///k6+fk////AAAA6wcHBwcHBwfr6+vrAAAAAAAAAOv/
/+Tr5+T//+sHBwfrBwcHBwcHAAAAAOvrAAAAAADr////5Ovn5P/rAOsHBwcHBwcHBwAAAAAABwfr
AAAAAP/////k6+fk//8AAOvrAOsHBwcHAADr6wAAAOsA6wfr/////+Tr5+T////r6+vrBwAABwAA
AOsHB+sAAOsABwD/////5Ovn5P///+sAAP/r6wAAAADrAAfr6+sA6wDr///////k6+fk////////
//////8AAADr6wcAAOvrAP///////+Tr5+T/////////////////AAAAAAAA6+vr////////5Ovn
5P//////////////////6wAAAADr6//////////k6+fn5+fn5+fn5+fn5+fn5+fn6+sA6+fn5+fn
5+fn5wfr5wcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHB+vnZxFnZ2dnZ2dnZ2dnZ2dnZ2dn
Z2dnZ2dn6+vr6+tn6+dnDmdnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2cH6gfqB2fr5+vr6+vr6+vr6+vr
6+vr6+vr6+vr6+vr6+vr6+vr6+sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==
) );
}

sub get_help_text
{
	my $parser;

	eval "require Pod::Simple::RTF";
	if($@) {
		eval "require Pod::Simple::Text";
		if($@) {
			return "Pod::Simple required to get help.";
		}
		else {
			$parser = Pod::Simple::Text->new();
		}
	}
	else {
		$parser = Pod::Simple::RTF->new();
	}

	my $string;
	$parser->output_string(\$string);
	$parser->parse_file($0);

	return $string;
}

sub OnAbout
{
	my $win = shift;
	$win->MessageBox(
		"Notify Icon Tester v$VERSION\r\n" .
		"(c) Robert May, 2006",
		"About Notify Icon Tester",
		MB_OK,
	);
}

sub OnHelp
{
	my $win;

	$win = Win32::GUI::Window->new(
		-title       => "Notify Icon Tester Help",
		-left        => CW_USEDEFAULT,
		-size        => [600, 500],
		-pushstyle   => WS_CLIPCHILDREN,
		-onResize    => sub { $_[0]->TEXT->Resize($_[0]->ScaleWidth(), $_[0]->ScaleHeight); 1; },
		-onTerminate => sub { undef $win; 1; },  # Closure prevents $win going out of scope
		                                         # at end of OnHelp().  Ref count to $win forced
							 # to zero on Terminate event.
		-dialogui    => 1,
	);

	# Hidden button that handles ESC char.
	# Might be better to use an accelerator table
	# but this is nice and quick
	$win->AddButton(
		-visible => 0,
		-cancel  => 1,
		-onClick => sub { undef $win; 1; },     # See comments above
	);

	$win->AddRichEdit(
		-name        => "TEXT",
		#-class       => "RichEdit20A",
		-readonly    => 1,
		-background  => 0xFFFFFF,
		-width       => $win->ScaleWidth(),
		-height      => $win->ScaleHeight(),
		-vscroll     => 1,
		-autohscroll => 0,
	);

	$win->TEXT->Text(get_help_text());
	$win->Show();

	return;
}
__END__

=head1 NAME

Notify Icon Tester

=head1 SYNOPSIS

C<perl NotifyIcon.pl>

=head1 OVERVIEW

This program has evolved from a simple utility designed to
allow for testing of the Win32::GUI::NotifyIcon functionality
into a program showing off some of the features available
from Win32::GUI.

=head1 VERSIONS

This program requires Win32::GUI v1.03_01 or higher, and should
run with any 32-bit version of windows (Win95/98/NT/ME/2K/XP).
The version of Win32::GUI is displayed in the 'Version Information'
panel.

Different versions of windows ship with different version of
shell32.dll.  Some versions of Internet Explorer may update
the system version of shell32.dll.
The version of shell32.dll installed on your system is displayed
in the 'Version Information' panel.  Balloon tooltips and some of the notification
events are only available with shell32.dll V5.0 and later.  Functions
that are not available will be disabled in the GUI.

=head1 USING

=head2 Showing and Removing the tray icon

Pressing the bottom-right button 'Show/Remove Notify Icon'
shows and removes a tray icon from the taskbar's system tray.

=head2 Selecting the icon

By default the Win32::GUI icon is displayed in the system tray.
It is possible to change this icon by selecting the 'Change Icon ...'
option from the 'File' menu, or by pressing the 'Change Icon ...' button.

The file selected must be a vaild windows icon (usually a *.ico file).
The microsoft documentation give the following limitations for the icon
colour depth:

=over 4

I<< To avoid icon distortion, be aware that notification area icons have
different levels of support under different versions of Microsoft
Windows. Windows 95, Windows 98, and Microsoft Windows NT 4.0 support
icons of up to 4 bits per pixel (BPP). Windows Millennium Edition
(Windows Me) and Windows 2000 support icons of a color depth up to
the current display mode. Windows XP supports icons of up to 32 BPP. >>

=back

=head2 Setting the Tooltip

Text entered in the Tooltip Text Textfield will be displayed
as a tooltip when the icon is displayed in the system tray
and the mouse hovers over the icon.  The text is limited to 63 characters
for shell32.dll before 5.0 and 127 characters for later
versions.

=head2 Balloon Tooltips

Balloon tooltips are available to systems with shell32.dll greater
than 5.0.  Balloon tooltips are larger tooltips, capable of showing
more information.  While the notify icon is displayed in the taskbar
a balloon tooltip can be shown and hidden using the 'Show Balloon'
and 'Hide Balloon' buttons.  The 'Show while editing' checkbox, if
checked, shows the balloon tooltip while you edit it's contents within
the 'Balloon Tooltip' panel.  You may adjust the following values
affecting the display of a Balloon Tooltip:

=over 4

=item Title

Sets the title of the balloon tooltip.  The title is displayed
in bold at the top of the tooltip.

=item Body

The main content of the balloon tooltip.  The ballon tooltip will
not be displayed if this field is empty.

=item Icon

Set the system icon that is displyed next to the balloon tooltip title.
One of: none (no icon), info, warn or error.  The icon is not displayed if
there is no title.

=item Timeout

The maximum time in milliseconds for which the tooltip will be displayed.
The tooltip may be displayed for a shorter time if another balloon tooltip
is displayed by either the same or any other system tray icon.

The system enforces minimum and maximum timeout values.
Timeout values that are too large are set to the maximum value
and values that are too small default to the minimum value. The system minimum
and maximum timeout values are set by the operating system and for all
current version sof windows are 10 seconds and 30
seconds, respectively.

=back

=head2 Events

The 'Events' panel shows events that are sent from the Notify Icon to the
owner window.  Typically these are mouse-related events, and can be triggered
by moving and clicking the mouse on the Notify Icon.

v5.0 supports 2 behaviours for messages sent when the notify icon has
keyboard focus and the <enter> and <space> key are pressed.  The
behavious can be changed by clicking the radio-buttons at the top
of the 'Events' panel.  See the microsoft documentation for
'Shell_NotifyIcon' for further details.

The text control at the bottom of the 'Events' panel shows the
events as they happen.

v6.0 of shell32.dll support various additional event messages
that occur as the balloon tooltip is displayed and hidden.

=head1 AUTHOR

Robert May - robertemay@users.sourceforge.net

=head1 COPYRIGHT AND LICENCE

This software is released under the same terms as Perl itself.

=cut

