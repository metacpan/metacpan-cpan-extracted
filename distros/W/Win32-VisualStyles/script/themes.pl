#!perl -w
use strict;
use warnings;

use Win32::VisualStyles qw(:all);
use Win32::GUI qw(CW_USEDEFAULT);
use Win32();

my $styles = GetThemeAppProperties();

my $mw = Win32::GUI::Window->new(
	-title => 'Visual Styles',
	-left  => CW_USEDEFAULT,
	-size  => [325,160],
);

$mw->AddCheckbox(
	-pos => [10,10],
	-text => 'Non-client styles',
	-onClick => \&change_styles,
	-checked => ($styles & STAP_ALLOW_NONCLIENT),
)->UserData(STAP_ALLOW_NONCLIENT);

$mw->AddCheckbox(
	-pos => [10,30],
	-text => 'Control styles',
	-onClick => \&change_styles,
	-checked => ($styles & STAP_ALLOW_CONTROLS),
)->UserData(STAP_ALLOW_CONTROLS);

$mw->AddCheckbox(
	-pos => [10,50],
	-text => 'WebContent styles',
	-onClick => \&change_styles,
	-checked => ($styles & STAP_ALLOW_WEBCONTENT),
)->UserData(STAP_ALLOW_WEBCONTENT);

$mw->AddButton(
	-pos => [10,75],
	-text => 'Win32::MsgBox',
	-onClick => sub { Win32::MsgBox('Some Message');1; },
);

my $isAppThemed = $mw->AddCheckbox(
	-pos => [150,10],
	-text => 'IsAppThemed(Global)',
	-disabled => 1,
	-checked => IsAppThemed(),
);

my $isThemeActive = $mw->AddCheckbox(
	-pos => [150,30],
	-text => 'IsThemeActive(Compatibility)',
	-disabled => 1,
	-checked => IsThemeActive(),
);

my $controls_styled = $mw->AddCheckbox(
	-pos => [150,50],
	-text => 'Controls styled?',
	-disabled => 1,
	-checked => control_styles_active(),
);

$mw->Show();
Win32::GUI::Dialog();
$mw->Hide();
exit(0);

sub change_styles {
	my ($self) = @_;

	if($self->Checked()) {
		$styles |= $self->UserData();
	}
	else {
		$styles &= ~$self->UserData();
	}

	SetThemeAppProperties($styles);

	$isAppThemed->Checked(IsAppThemed());
	$isThemeActive->Checked(IsThemeActive());
	$controls_styled->Checked(control_styles_active());

	#printf("GetThemeAppProperties: %08b\n",GetThemeAppProperties());
	return 1;
}
