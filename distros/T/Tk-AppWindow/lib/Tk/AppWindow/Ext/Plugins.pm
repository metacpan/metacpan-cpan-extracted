package Tk::AppWindow::Ext::Plugins;

=head1 NAME

Tk::AppWindow::Ext::Plugins - load and unload plugins

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.02";
use Tk;
use Pod::Usage;
use File::Basename;
require Tk::YADialog;
require Tk::AppWindow::PluginsForm;
use Module::Load::Conditional('check_install', 'can_load');
$Module::Load::Conditional::VERBOSE = 1;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Plugins'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Gives your user the opportunity to tune the application to his wishes,
by loading and unloading plugins.

Plugins are kind of like extensions, they add functionality. However,
a plugin cannot define configvariables. It can issue commands though.

This extension will load the extension B<ConfigFolder> if it is not loaded already.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-availableplugs>

If you set this list, only the specified plugins can be loaded by the 
end user. If you do not set this option, there is no restriction to what
plugins are available to the end user, except for blocked plugins.

=item Switch: B<-blockedplugs>

List of plugins that are blocked from the end user.

=item Switch: B<-plugins>

List of plugins that will be loaded at startup, factory settings.

=back

=head1 COMMANDS

=over 4

=item B<plugsdialog>

Creates a dialog window in which the user can select and unselect plugins

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{PLUGINS} = {};
	$self->Require('ConfigFolder');
	$self->addPreConfig(
		-availableplugs => ['PASSIVE', undef, undef, undef],
		-blockedplugs => ['PASSIVE', undef, undef, []],
		-plugins => ['PASSIVE', undef, undef, []],
	);

	$self->addPostConfig('DoPostConfig', $self);

	$self->cmdConfig(
		plugsdialog => ['PopPlugsDialog', $self],
	);

	return $self;
}

=head1 METHODS

=over 4

=cut


sub AvailablePlugins {
	my $self = shift;

	my $ap = $self->configGet('-availableplugs');
	return sort @$ap if defined $ap;
	my $bp = $self->configGet('-blockedplugs');
	my %blocked = ();
	for ($bp) { $blocked{$_} = 1 }

	my @namespaces = ( 'Tk::AppWindow' );
	my $additional = $self->NameSpace;
	push @namespaces, $additional if defined $additional;


	my %plugins = ();
	for (@namespaces) {
		my $space = $_;
		$space =~ s/\:\:/\//;
		for (@INC) {
			my $dir = "$_/$space/Plugins";
			if ((-e $dir) and (-d $dir)) {
				my @pm = <$dir/*.pm>;
				for (@pm) {
					my $plugin =  basename($_, '.pm');
					$plugins{$plugin} = 1 unless exists $blocked{$plugin};
				}
			}
		}
	}
	return sort keys %plugins
}

sub CanQuit {
	my $self = shift;
	my @plugs = $self->plugList;
	my $close = 1;
	for (@plugs) {
		$close = 0 unless $self->plugGet($_)->CanQuit
	}
	return $close
}

sub ConfigureBars {
	my ($self, $plug) = @_;
	my $menu = $self->extGet('MenuBar');
	if (defined $menu) {
		my @items = $plug->MenuItems;
		$menu->ReConfigure unless @items eq 0;
	}
	my $tool = $self->extGet('ToolBar');
	if (defined $tool) {
		my @items = $plug->ToolItems;
		$tool->ReConfigure unless @items eq 0;
	}
}

sub DoPostConfig {
	my $self = shift;
	my $file = $self->configGet('-configfolder') . '/plugins';
	if (-e $file) {
		if (open OFILE, "<", $file) {
			while (<OFILE>) {
				my $plug = $_;
				chomp($plug);
				$self->plugLoad($plug);
			}
			close OFILE;
		}
	} else {
		my $plugins = $self->configGet('-plugins');
		for (@$plugins) {
			$self->plugLoad($_);
		}
	}
}

sub MenuItems {
	my $self = shift;
	my @items = ();
	my @l = $self->plugList;
	for (@l) {
		push @items, $self->plugGet($_)->MenuItems
	}
	unless ($self->extExists('Settings')) {
		push @items, (
			[	'menu_normal',		'appname::Quit',		'~Plugins',	'plugsdialog',	'configure',		'F10',	], 
			[	'menu_separator',	'appname::Quit',		'h2'], 
		)
	}
	return @items;
}

sub plugDescription {
	my ($self, $plug) = @_;
	my @path = ("Tk/AppWindow/Plugins/");
	my $ns = $self->NameSpace;
	if (defined $ns) {
		$ns =~ s/\:\:/\//g;
		push @path, "$ns/Plugins";
	}
	my $file;
	for (@path) {
		my $p = $_;
		$file = Tk::findINC("$p/$plug.pm");
		last if defined $file;
	}
	open my $fi, "<", $file or die $!;
	open my $fh, '>', \my $str or die $!;
	pod2usage(
		-exitval => 'NOEXIT',
		-verbose => 99,
		-input => $fi,
		-output => $fh,
		-sections => ['DESCRIPTION'],
	);
	close $fh;
	close $fi;
	$str =~ s/^Description:\n//;
	$str =~ s/\n+$//;
	return $str;
}

=item B<plugExists(I<$name>)>

returns the requested plugin object.

=cut

sub plugExists {
	my ($self, $plug) = @_;
	return exists $self->{PLUGINS}->{$plug}
}

=item B<plugGet>(I<$name>)

returns the requested plugin object.

=cut

sub plugGet {
	my ($self, $plug) = @_;
	return $self->{PLUGINS}->{$plug}
}

=item B<plugList>

returns a sorted list of loaded plugins.

=cut

sub plugList {
	my $plugs = $_[0]->{PLUGINS};
	return sort keys %$plugs
}

=item B<plugLoad>(I<$name>)

Loads the plugin; returns 1 if succesfull;

=cut

sub plugLoad {
	my ($self, $plug) = @_;
	return if $self->plugExists($plug);
	my @paths = ('Tk::AppWindow::Plugins');
	my $namespace = $self->NameSpace;
	if (defined $namespace) {
		$namespace = $namespace . '::Plugins';
		push @paths, $namespace;
	}
	for (@paths) {
		my $p = $_;
		my $obj;
		
		my $modname = $p . "::$plug";
		my $app = $self->GetAppWindow;
		my $inst = check_install(module => $modname);
		if (defined $inst) {
			if (can_load(modules => {$modname => $inst->{'version'}})){
				$obj = $modname->new($app);
			}
		}
		if (defined($obj)) {
			$self->{PLUGINS}->{$plug} = $obj;
			$self->ConfigureBars($obj);
			return 1
		}
	}
	warn "unable to load plugin $plug\n";
	return 0
}

=item B<plugUnload>(I<$name>)

Unloads the plugin; returns 1 if succesfull;

=cut

sub plugUnload {
	my ($self, $plug) = @_;
	return unless $self->plugExists($plug);
	my $obj = $self->plugGet($plug);
	if ($obj->Unload) {
		delete $self->{PLUGINS}->{$plug};
		$self->ConfigureBars($obj);
		return 1
	}
	return 0;
}

sub plugUse {
	my ($self, $plug) = @_;
	my $modname = "Tk::AppWindow::Plugins::$plug";
	eval "use $modname;";
}

sub PopPlugsDialog {
	my $self = shift;
	my $dialog = $self->YADialog(
		-title => 'Configure plugins',
		-buttons => ['Close'],
	);
	$dialog->PluginsForm(
		-pluginsext => $self,
	)->pack(-expand => 1, -fill => 'both');
	$dialog->Show(-popover => $self->GetAppWindow);
	$dialog->destroy;
}

=item B<Reconfigure>

Calls Reconfigure on all loaded plugins 1 if all succesfull;

=cut

sub Reconfigure {
	my $self = shift;
	my @plugs = $self->PluginList;
	my $succes = 1;
	for (@plugs) {
		$succes = 0 unless $self->GetPlugin($_)->Reconfigure
	}
	return $succes
}

sub SettingsPage {
	my $self = shift;
	return (
		'Plugins' => ['PluginsForm', -pluginsext => $self ]
	)
}

sub ToolItems {
	my $self = shift;
	my @items = ();
	my @l = $self->plugList;
	for (@l) {
		push @items, $self->plugGet($_)->ToolItems
	}
	return @items;
}

sub Quit {
	my $self = shift;
	my @plugs = $self->plugList;
	my $file = $self->configGet('-configfolder') . '/plugins';
	if (open OFILE, ">", $file) {
		for (@plugs) { print OFILE "$_\n" }
		close OFILE;
	}
	for (@plugs) {
		$self->plugGet($_)->Quit
	}
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. Probably plenty. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::AppWindow::BaseClasses::Plugin>

=back

=cut

1;





