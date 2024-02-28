package Tk::AppWindow::Ext::Settings;

=head1 NAME

Tk::AppWindow::Ext::Settings - allow your user to configure settings

=cut

use strict;
use warnings;
use Tk;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Extension );

require Tk::YADialog;
require Tk::QuickForm;


=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Settings'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Add a settings feature to your application and allow the end user to configure the application.

Creates a menu item in the main menu.

Loads settings file at startup.

=head1 CONFIG VARIABLES

=over 4

=item B<-settingsfile>

Name of the settings file. Default is I<settingsrc>.

=item B<-useroptions>

Name of the settings file. Default is I<settingsrc>. A typical setup might look
like this:

 -useroptions => [
    '*page' => 'Editing',
    '*section' => 'User interface',
    -contentforeground => ['color', 'Foreground'],
    -contentbackground => ['color', 'Background'],
    -contentfont => ['font', 'Font'],
    '*end',
    '*section' => 'Editor settings',
    -contenttabs => ['text', 'Tab size'],
    -contentwrap => ['radio', 'Wrap', [qw[none char word]]],
    '*end',
    '*page' => 'Icons',
    -icontheme => ['list', 'Icon theme', 'available_icon_themes'],
    -iconsize => ['list', 'Icon size', 'available_icon_sizes'],
    '*page' => 'Bars',
    '*section' => 'Menubar',
    -menuiconsize => ['list', 'Icon size', 'available_icon_sizes'],
    '*end',
    '*section' => 'Toolbar',
    -toolbarvisible => ['boolean', 'Visible at launch'],
    -tooliconsize => ['list', 'Icon size', 'available_icon_sizes'],
    -tooltextposition => ['radio', 'Text position', [qw[none left right top bottom]]],
    '*end',
    '*section' => 'Statusbar',
    -statusbarvisible => ['boolean', 'Visible at launch'],
    '*end',
 ],

It uses L<Tk::TabbedForm> in the popup. See there for details of this option.

=back

=head1 COMMANDS

=over 4

=item B<settings>

Launches the settings dialog.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my $args = $self->GetArgsRef;

	$self->Require( 'ConfigFolder');
	$self->{SETTINGSFILE} = undef;
	$self->{USEROPTIONS} = undef;

	
	$self->configInit(
		-settingsfile => ['SettingsFile', $self, 'settingsrc'],
		-useroptions => ['UserOptions', $self, []],
	);

	$self->cmdConfig(
		settings => ['CmdSettings', $self],
	);

	return $self;
}

=head1 METHODS

=over 4

=cut

sub CmdSettings {
	my $self = shift;
	my $m = $self->GetAppWindow->YADialog(
		-buttons => ['Close'],
		-title => 'Configure settings',
	);
	
	my $f;
	my $b = $m->Subwidget('buttonframe')->Button(
		-text => 'Apply',
		-command => sub {
			my %options = $f->get;
			my @opts = sort keys %options;
			my @save = ();
			for (@opts) {
				my $val = $options{$_};
				if ($val ne '') {
					$self->configPut($_, $val);
					push @save, $_;
				}
			}
			$self->ReConfigureAll;
			$self->SaveSettings(@save);
		}
	);

	my %qopts = ();
	my $fil = $self->getArt('text-x-plain');
	$qopts{'-fileimage'} = $fil if defined $fil;
	my $fol = $self->getArt('folder');
	$qopts{'-folderimage'} = $fol if defined $fol;
	my $fon = $self->getArt('gtk-select-font');
	$qopts{'-fontimage'} = $fon if defined $fon;

	$f = $m->QuickForm(%qopts,
		-acceptempty => 1,
# 		-listcall => ['cmdExecute', $self],
		-structure => $self->configGet('-useroptions'),
		-postvalidatecall => sub {
			my $flag = shift;
			if ($flag) {
				$b->configure('-state', 'normal')
			} else {
				$b->configure('-state', 'disabled')
			}
		},
	)->pack(-expand => 1, -fill => 'both');
	my $nb = $f->createForm;
	if (defined $nb) {
		my @pages = $self->GetSettingsPages;
		while (@pages) {
			my $title = shift @pages;
			my $opt = shift @pages;
			my $class = shift @$opt;
			my $page = $nb->add($title, -label => $title);
			$page->$class(@$opt)->pack(-fill => 'both', -expand => 1);
		}
	}
	$f->put($self->GetUserOptions);
	
	$m->ButtonPack($b);
	$m->Show(-popover => $self->GetAppWindow);
	$m->destroy;
}

sub GetUserOptions {
	my $self = shift;
	my $uo = $self->configGet('-useroptions');
	my @options = @$uo;
	my %usopt = ();
	while (@options) {
		my $key = shift @options;
		if (($key eq '*page') or ($key eq '*section')) {
			shift @options;
			next;
		}
		if ($key eq '*end') {
			next;
		}
		shift @options;
		$usopt{$key} = $self->configGet($key);
	}
	return %usopt
}

sub GetSettingsPages {
	my $self = shift;
	my @p = $self->extList;
	my @u = ();
	my @l = ();
	for (@p) { push @l, $self->extGet($_) }
	for (@l) {
		push @u, $_->SettingsPage;
	}
	return @u;
}

sub LoadSettings {
	my $self = shift;
	my $cff = $self->extGet('ConfigFolder');
	my $file = $self->configGet('-settingsfile');
	return () unless $cff->confExists($file);
	my $uo = $self->configGet('-useroptions');
	my %useroptions = ();
	my @temp = (@$uo);
	while (@temp) {
		my $key = shift @temp;
		if (($key eq '*page') or ($key eq '*section')) {
			shift @temp;
			next;
		}
		if ($key eq '*end') {
			next;
		}
		shift @temp;
		$useroptions{$key} = 1;
	}
	my %hash = $cff->loadHash($file, 'aw settings');
	my @output = ();
	for (keys %hash) {
		my $key = $_;
		if (exists $useroptions{$key}) {
			push @output, $key, $hash{$key}
		} else {
			warn "Ignoring invalid option: $key"
		}
	}
	return @output;
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath					label				cmd			icon					keyb
		[	'menu_normal',		'appname::Quit',		'~Settings',	'settings',	'configure',		'F9',	], 
		[	'menu_separator',	'appname::Quit',		'h2'], 
	)
}

sub ReConfigureAll {
	my $self = shift;
	my @list = $self->extList;
	my %hash = ();
	for (@list) {
		$hash{$_} = $self->extGet($_);
	}
	my $kb = delete $hash{'Keyboard'};
	$kb->ReConfigure if defined $kb;
	for (keys %hash) {
		$hash{$_}->ReConfigure;
	}
}

sub SaveSettings {
	my $self = shift;
	my %hash = ();
	my $file = $self->configGet('-settingsfile');
	for (@_) {
		my $option = $_;
		my $value = $self->configGet($_);
		$hash{$option} = $value;
	}
	my $cff = $self->extGet('ConfigFolder');
	$cff->saveHash($file, 'aw settings', %hash);
}

sub SettingsFile {
	my $self = shift;
	if (@_) { $self->{SETTINGSFILE} = shift }
	return $self->{SETTINGSFILE}
}

sub UserOptions {
	my $self = shift;
	if (@_) { $self->{USEROPTIONS} = shift }
	return $self->{USEROPTIONS}
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::AppWindow::BaseClasses::PanelExtension>

=back

=cut

1;



