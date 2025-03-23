package Tk::AppWindow;

=head1 NAME

Tk::AppWindow - An application framework based on Tk

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.22";

use base qw(Tk::Derived Tk::MainWindow);
Construct Tk::Widget 'AppWindow';

use File::Basename;
require Tk::AppWindow::BaseClasses::Callback;
require Tk::Balloon;
require Tk::DynaMouseWheelBind;
require Tk::FilePicker;
require Tk::QuickForm;
require Tk::YAMessage;
use Tk::PNG;


use Config;
my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ConfigFolder'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

An extendable application framework written in perl/Tk. The aim is maximum user configurability
and ease of application building.

To get started read L<Tk::AppWindow::OverView> and L<Tk::AppWindow::CookBook>.

This document is a reference manual.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-appname>

Set the name of your application.

If this option is not specified, the name of your application
will be set to the filename of your executable with the first
character in upper case.

=item Switch: B<-commands>

Defines commands to be used in your application. It takes a paired list of
command names and callbacks as parameter.

 my $app = $k::AppWindw->new(
    -commands => [
       do_something1 => ['method', $obj],
       do_something2 => sub { return 1 },
    ],
 );

Only available at create time.

=item Name  : B<errorColor>

=item Class : B<ErrorColor>

=item Switch: B<-errorcolor>

Default value '#FF0000' (red).

=item Switch: B<-extensions>

Specifies the list of extensions to be loaded.

 my $app = Tk::AppWindow->new(
    -extensions => [ 
       qw/Art ConfigFolder Daemons 
       Help Keyboard MDI MenuBar
       Panels Plugins SDI Selector
       Settings SideBars StatusBar
       ToolBar/
    ],
 );

The following order matters for the buildup of menus and bars.
Only available at create time.

=item Name  : B<linkColor>

=item Class : B<LinkColor>

=item Switch: B<-linkcolor>

Foreground color for links. Default value '#3030DF'.

=item Switch: B<-logcall>

Callback to log messages.

=item Switch: B<-logerrorcall>

Callback to log errors.

=item Switch: B<-logwarningcall>

Callback to log warnings.

=item Switch: B<-logo>

Specifies the image file to be used as logo for your application.
Default value is Tk::findINC('Tk/AppWindow/aw_logo.png').

=item Switch: B<-namespace>

Specifies an additional name space for extensions and plugins.
If you set it, for example, to 'Foo::Bar', then your extensions
may also live in 'Foo::Bar::Ext' and your plugins may live 
in 'Foo::Bar::Plugins'.

Only available at create time.

=item Switch: B<-savegeometry>

Default value 0. Saves the geometry on quit and loads it on start. Only works
if the extension B<ConfigFolder> is loaded.

=back

=head1 COMMANDS

=over 4

=item B<quit>

Calls the CmdQuit method. See there.

=back

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $commands = delete $args->{'-commands'};
	$commands = [] unless defined $commands;

	my $extensions = delete $args->{'-extensions'};
	$extensions = [] unless defined $extensions;
	
	my $namespace = delete $args->{'-namespace'};
	
	my $preconfig = delete $args->{'-preconfig'};
	$preconfig = [] unless defined $preconfig;
	
	my $appname = delete $args->{'-appname'};
	$appname = ucfirst(basename($0, '.pl', '.PL')) unless defined $appname;
	$args->{'-title'} = $appname;
	
	$self->SUPER::Populate($args);
	
	$self->DynaMouseWheelBind(
		'Tk::Canvas',
		'Tk::HList',
		'Tk::ITree',
		'Tk::Pane',
		'Tk::Tree',
	);

	$self->{APPNAME} = $appname;
	$self->{ARGS} = $args;
	$self->{BALLOON} = $self->Balloon;
	$self->{CMNDTABLE} = {};
	$self->{CONFIGTABLE} = {};
	$self->{GEOBLOCK} = 0;
	$self->{GEOCALLS} = {};
	$self->{GEOEXCLUSIVE} = '';
	$self->{EXTENSIONS} = {};
	$self->{EXTLOADORDER} = [];
	$self->{LOGDISABLED} = 0;
	$self->{NAMESPACE} = $namespace;
	$self->{WORKSPACE} = $self;

	$self->cmdConfig(
		poptest => ['popTest', $self], #usefull for testing only
		quit => ['CmdQuit', $self],
		@$commands
	);
	$self->configInit(
		-appname => ['appName', $self, $appname],
	);
	
	$self->{POSTCONFIG} = [];
	$self->{PRECONFIG} = $preconfig;
	for (@$extensions) {
		$self->extLoad($_, $args);
	}

	my $setplug = $self->extGet('Settings');
	if (defined $setplug) {
		my @useroptions = $setplug->LoadSettings;
		my $tab = $self->{CONFIGTABLE};
		while (@useroptions) {
			my $option = shift @useroptions;
			my $value = shift @useroptions;
			if (exists $tab->{$option}) {
				$self->configPut($option, $value)
			} else {
				$args->{$option} = $value;
			}
		}
	}


	#create file picker widget
	my $picker = $self->FilePicker(
		-diriconcall => ['getDirIcon', $self],
		-fileiconcall => ['getFileIcon', $self],
		-linkiconcall => ['getLinkIcon', $self],
	);
	$self->Advertise('FilePicker', $picker);


	my $pre = $self->{PRECONFIG};
	my $logcall = sub {
		my $message = shift;
		print STDERR "$message\n";
	};
	$self->ConfigSpecs(
		-linkcolor => ['PASSIVE', 'linkColor', 'LinkColor', '#3030DF'],
		-logcall => ['CALLBACK', undef, undef, $logcall], 
		-logerrorcall => ['CALLBACK', undef, undef, $logcall], 
		-logwarningcall => ['CALLBACK', undef, undef, $logcall], 
		-logo => ['PASSIVE', undef, undef, Tk::findINC('Tk/AppWindow/aw_logo.png')],
		-savegeometry => ['PASSIVE', undef, undef, 0],
		@$pre,
		DEFAULT => ['SELF'],
	);
	
	$self->Delegates(
		pick => $picker,
		pickFileOpen => $picker,
		pickFileOpenMulti => $picker,
		pickFileSave => $picker,
		pickFolderSelect => $picker,
		DEFAULT => $self,
	);

	$self->protocol('WM_DELETE_WINDOW', ['CmdQuit', $self]);
	delete $self->{ARGS};
	$self->after(1, ['PostConfig', $self]);
}

=head1 METHODS

=over 4

=item B<abbreviate>I<($string, ?$size?, ?$firstsize?)>

Shortens $string to $size by leaving out a middle part. Then returns it.
$size is set to 30 unless you specify it. $firstsize is set to 25% of $size
unless you set it.

=cut

sub abbreviate {
	my ($self, $string, $size, $firstsize) = @_;
	$size = 30 unless defined $size;
	$firstsize = int($size / 4) unless defined $firstsize;
	my $length = length($string);
	if ($length > $size) {
		my $first = substr($string, 0, $firstsize) . ' ... ';
		my $lastsize = $size - $firstsize - 5;
		my $last = substr($string, $length - $lastsize, $lastsize);
		$string = $first . $last;
	}
	return $string;
}

=item B<addPostConfig>I<('Method', $obj, @options)>

Only to be called by extensions at create time.
Specifies a callback te be executed after main loop starts.

Callbacks are executed in the order they are added.

=cut

sub addPostConfig {
	my $self = shift;
	my $pc = $self->{POSTCONFIG};
	my $call = $self->CreateCallback(@_);
	push @$pc, $call
}

=item B<addPreConfig>I<(@configs)>

Only to be called by extensions at create time.
Specifies configs to the ConfigSpec method executed in Populate.

=cut

sub addPreConfig {
	my $self = shift;
	my $p = $self->{PRECONFIG};
	push @$p, @_
}

=item B<appName>I<($name)>

Sets and returns the application name.
Same as $app->configPut(-name => $name), or $app->configGet($name).

=cut

sub appName {
	my $self = shift;
	if (@_) { $self->{APPNAME} = shift }
	return $self->{APPNAME}
}

=item B<balloon>

Returns a reference to the Balloon widget.

=cut

sub balloon {
	return $_[0]->{BALLOON}
}

=item B<BalloonAttach>I<$widget, $text>

Attaches a balloon message to $widget.

=cut

sub BalloonAttach {
	my ($self, $widget, $text) = @_;
	$self->{BALLOON}->attach($widget, -balloonmsg => $text)
}

=item B<CanQuit>

Returns 1. It is called when Tk::AppWindow tests all extensions if they can quit. You can 
overwrite it when you inherit Tk::AppWindow.

=cut

sub CanQuit {
	my $self = shift;
	return 1
}

sub CmdQuit {
	my $self = shift;
	my $quit = 1;
	my $exts = $self->{EXTENSIONS};
	for (keys %$exts) {
		$quit = 0 unless $exts->{$_}->CanQuit;
	}
	$quit = 0 unless $self->CanQuit;
	if ($quit) {
		#saving geometry
		if ($self->configGet('-savegeometry')) {
			my $cf = $self->extGet('ConfigFolder');
			if (defined $cf) {
				my $geometry = $self->geometry;
				$cf->saveList('geometry', "aw geometry", $geometry);
			}
		}
		#quitting extensions
		for (keys %$exts) {
			$exts->{$_}->Quit;
		}
		$self->destroy;
	} 
}

=item B<cmdConfig>I<(@commands)>

 $app->cmdConfig(
    command1 => ['SomeMethod', $obj, @options],
    command2 => [sub { do whatever }, @options],
 );

cmdConfig takes a paired list of commandnames and callback descriptions.
It registers them to the commands table. After that B<cmdExecute> can 
be called on them.

=cut

sub cmdConfig {
	my $self = shift;
	my $tbl = $self->{CMNDTABLE};
	while (@_) {
		my $key = shift;
		my $callback = shift;
		unless (exists $tbl->{$key}) {
			$tbl->{$key} = $self->CreateCallback(@$callback);
		} else {
			carp "Command $key already exists"
		}
	}
}

=item B<cmdExecute>('command_name', @options);

Looks for the callback assigned to command_name and executes it.
returns the result.

=cut

sub cmdExecute {
	my $self = shift;
	my $key = shift;
	my $cmd = $self->{CMNDTABLE}->{$key};
	if (defined $cmd) {
		return $cmd->execute(@_);
	} else {
		carp "Command $key is not defined"
	}
}

=item B<cmdExists>('command_name')

Checks if command_name can be used as a command. Returns a boolean.

=cut

sub cmdExists {
	my ($self, $key) = @_;
	unless (defined $key) { return 0 }
	return exists $self->{CMNDTABLE}->{$key};
}

sub CmdGet {
	my ($self, $cmd) = @_;
	return $self->{CMNDTABLE}->{$cmd}
}

sub CmdHook {
	my $self = shift;
	my $method = shift;
	my $cmd = shift;
	my $call = $self->CmdGet($cmd);
	if (defined $call) {
		$call->$method(@_);
		return
	}
	carp "Command '$cmd' does not exist"
}

=item B<cmdHookAfter>(I<'command_name'>, I<@callback>)

Adds a hook to after stack of the callback associated with 'command_name'.
See L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub cmdHookAfter {
	my $self = shift;
	return $self->CmdHook('hookAfter', @_);
}

=item B<cmdHookBefore>(I<'command_name'>, I<@callback>)

Adds a hook to before stack of the callback associated with 'command_name'.
See L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub cmdHookBefore {
	my $self = shift;
	return $self->CmdHook('hookBefore', @_);
}


=item B<cmdRemove>(I<'command_name'>)

Removes 'command_name' from the command stack.

=cut

sub cmdRemove {
	my ($self, $key) = @_;
	return unless defined $key;
	return delete $self->{CMNDTABLE}->{$key};
}

=item B<cmdUnhookAfter>(I<'command_name'>, I<@callback>)

unhooks a hook from after stack of the callback associated with 'command_name'.
See L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub cmdUnhookAfter {
	my $self = shift;
	return $self->CmdHook('unhookAfter', @_);
}

=item B<cmdUnhookBefore>(I<'command_name'>, I<@callback>)

unhooks a hook from before stack of the callback associated with 'command_name'.
see L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub cmdUnhookBefore {
	my $self = shift;
	return $self->CmdHook('unhookBefore', @_);
}

=item B<configGet>I<('-option')>

Equivalent to $app-cget. Except here you can also specify
the options added by B<configInit>

=cut

sub configGet {
	my ($self, $option) = @_;
	croak "Option not defined" unless defined $option;
	if (exists $self->{CONFIGTABLE}->{$option}) {
		my $call = $self->{CONFIGTABLE}->{$option};
		return $call->execute;
	} else {
		return $self->cget($option);
	}
}

sub ConfigHook {
	my $self = shift;
	my $method = shift;
	my $config = shift;
	if (exists $self->{CONFIGTABLE}->{$config}) {
		my $call = $self->{CONFIGTABLE}->{$config};
		$call->$method(@_);
		return 1
	}
	carp "Config option '$config' was not defined through configInit";
	return 0
}

=item B<configHookAfter>(I<'-configvariable'>, I<@callback>)

Adds a hook to the after stack of the callback associated with a config
variable'. See L<Tk::AppWindow::BaseClasses::Callback>.
Only works on config variables created through B<configInit>

=cut

sub configHookAfter {
	my $self = shift;
	return $self->ConfigHook('hookAfter', @_);
}

=item B<configHookAfter>(I<'-configvariable'>, I<@callback>)

Adds a hook to teh before stack of the callback associated with a config
variable'. See L<Tk::AppWindow::BaseClasses::Callback>.
Only works on config variables created through B<configInit>

=cut

sub configHookBefore {
	my $self = shift;
	return $self->ConfigHook('hookBefore', @_);
}

=item B<configInit>I<(@options)>

 $app->configInit(
    -option1 => ['method', $obj, @options, $default],
    -option2 => [sub { do something }, @options, $default],
 );

Add options to the options table. Usually called at create time. But worth experimenting with.

Always specify I<$default>. The last thing you specify is always the default value. set it undef
if you want it to be ignored.

=cut

sub configInit {
	my $self = shift;
	my $args = $self->{ARGS};
	my $table = $self->{CONFIGTABLE};
	while (@_) {
		my $option = shift;
		my $i = shift;
		my ($call, $owner, @options) = @$i;
		my $default = pop @options;
		my $value;
		$value = delete $args->{$option} if defined $args;
		$value = $default unless defined $value;
		unless (exists $table->{$option}) {
			$table->{$option} = $self->CreateCallback($call, $owner, @options);
			$self->configPut($option, $value) if defined $value;
		} else {
			croak "Config option $option already defined\n";
		}
	}
}

=item B<configMode>

Returns 1 if MainLoop is not yet running.

=cut

sub configMode {
	return exists $_[0]->{ARGS};
}

=item B<configPut>I<(-option => $value)>

Equivalent to $app-configure. Except here you can also specify
the options added by B<configInit>

=cut

sub configPut {
	my ($self, $option, $value) = @_;
	croak "Option not defined" unless defined $option;
	if (exists $self->{CONFIGTABLE}->{$option}) {
		my $call = $self->{CONFIGTABLE}->{$option};
		$call->execute($value);
	} else {
		$self->configure($option, $value);
	}
}

=item B<configRemove>I<('-option')>

Removes '-option from the config hash. Usefull when unloading a plugin
that configures an option with configInit.

=cut

sub configRemove {
	my ($self, $option) = @_;
	delete $self->{CONFIGTABLE}->{$option};
}

=item B<configUnhookAfter>(I<'-configvariable'>, I<@callback>)

Removes a hook from the after stack of the callback associated with a config
variable'. See L<Tk::AppWindow::BaseClasses::Callback>.
Only works on config variables created through B<configInit>

=cut

sub configUnhookAfter {
	my $self = shift;
	return $self->CmdHook('unhookAfter', @_);
}

=item B<configUnhookBefore>(I<'-configvariable'>, I<@callback>)

Removes a hook from the after stack of the callback associated with a config
variable'. See L<Tk::AppWindow::BaseClasses::Callback>.
Only works on config variables created through B<configInit>

=cut

sub configUnhookBefore {
	my $self = shift;
	return $self->CmdHook('unhookBefore', @_);
}

=item B<CreateCallback>('MethodName', $owner, @options);

=item B<CreateCallback>(sub { do whatever }, @options);

Creates and returns a Tk::AppWindow::Baseclasses::Callback object. 
A convenience method that saves you some typing.

=cut

sub CreateCallback {
	my $self = shift;
	return Tk::AppWindow::BaseClasses::Callback->new(@_);
}

=item B<extExists>I<($name)>

Returns 1 if $name is loaded.

=cut

sub extExists {
	my ($self, $name) = @_;
	my $plgs = $self->{EXTENSIONS};
	return exists $plgs->{$name};
}

=item B<extGet>('Name')

Returns reference to extension object 'Name'.
Returns undef if 'Name' is not loaded.

=cut

sub extGet {
	my ($self, $name) = @_;
	my $plgs = $self->{EXTENSIONS};
	if (exists $plgs->{$name}) {
		return $plgs->{$name}
	}
	return undef
}

=item B<extList>

Returns a list of all loaded extensions

=cut

sub extList {
	my $self = shift;
	my $pl = $self->{EXTLOADORDER};
	return @$pl;
}

=item B<extLoad>('Name');

Loads and initializes an extension.
Terminates application if it fails.

Called at create time.

=cut

sub extLoad {
	my ($self, $name) = @_;
	my $exts = $self->{EXTENSIONS};
	my $ext = undef;
	unless (exists $exts->{$name}) { #unless already loaded
		my @paths = ('Tk::AppWindow::Ext');
		my $namespace = $self->NameSpace;
		if (defined $namespace) {
			$namespace = $namespace . '::Ext';
			push @paths, $namespace;
		}
		my $error = '';
		for (@paths) {
			my $p = $_;
			
			my $modname = $p . "::$name";
			eval "use $modname;";
			$error = $@;
			unless ($error) {
				my $ext = $modname->new($self);
				$exts->{$name} = $ext;
				my $o = $self->{EXTLOADORDER};
				push @$o, $name;
				return
			}
		}
		die "unable to load extension $name\n$error";
	}
}

=item B<fileSeparator>

Returns the correct file separator for your operating system.
'\' for windows and '/' for all the others.

=cut

sub fileSeparator {
	my $self = shift;
	return '\\' if $mswin;
	return '/'
}

=item B<fontFams>

Replaces the method I<fontFamilies>, which crashes when used under windows.
This one queries the registry for font families on Windows, and calls
I<fontFamilies> on other operating systems.

=cut

sub fontFams {
	my $self = shift;
	if ($mswin) {
		my @fams;
		my $raw = `reg query "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" /s`;
		my @lines = split /\n/, $raw;
		for (@lines) {
			my $lin = $_;
			chomp $lin;
			next if $lin eq '';
			next if $lin =~ /^HKEY/;
			$lin =~ s/^\s+//; #remove leading spaces
			$lin =~ s/^([^\(]+).*/$1/; #remove all as of TrueType;
			$lin =~ s/\s+$//; #remove trailing spaces
			next if $lin =~ /bold/i; #ignore bold
			next if $lin =~ /italic/i; #ignore italic
			next if $lin =~ /\.FON$/; #only truetype fonts
			$lin =~ s/\s\d+.+$//; #adjust for some older fonts
			push @fams, $lin;
		}
		return @fams
	} else {
		return $self->fontFamilies;
	}
}

sub GetArgsRef { return $_[0]->{ARGS} }

=item B<getArt>I<($icon, $size)>

Checks if extension B<Art> is loaded and returns requested image if so.
If $size is not specified, default size is used.

=cut

sub getArt {
	my ($self, $icon, $size) = @_;
	my $art = $self->extGet('Art');
	if (defined $art) {
		return $art->getIcon($icon, $size);
	}
	return undef
}

sub getDirIcon {
	my ($self, $name) = @_;
	my $icon = $self->getArt('folder');
	return $icon if defined $icon;
	return $self->Subwidget('FilePicker')->Subwidget('Browser')->DefaultDirIcon;
}

sub getFileIcon {
	my ($self, $name) = @_;
	my $art = $self->extGet('Art');
	my $icon = $art->getFileIcon($name) if defined $art;
	return $icon if defined $icon;
	return $self->Subwidget('FilePicker')->Subwidget('Browser')->DefaultFileIcon;
}

sub getLinkIcon {
	my ($self, $name) = @_;
	my $icon = $self->getArt('emblem-symbolic-link');
	return $icon if defined $icon;
	return $self->Subwidget('FilePicker')->Subwidget('Browser')->DefaultLinkIcon;
}

=item B<log>I<($message)>

Log $message

=cut

sub log {
	my ($self, $message) = @_;
	return if $self->logDisabled;
	$self->Callback('-logcall', $message);
}

=item B<logDisabled>I<(?$flag?)>

Disable/enable logging of messages.

=cut

sub logDisabled {
	my $self = shift;
	$self->{LOGDISABLED} = shift if @_;
	return $self->{LOGDISABLED}
}

=item B<logError>I<($message)>

Log $message as an error

=cut

sub logError {
	my ($self, $message) = @_;
	return if $self->logDisabled;
	$self->Callback('-logerrorcall', $message);
}

=item B<logWarning>I<($message)>

Log $message as a warning

=cut

sub logWarning {
	my ($self, $message) = @_;
	return if $self->logDisabled;
	$self->Callback('-logwarningcall', $message);
}

=item B<MenuItems>

Returns a list of two items used by the B<MenuBar> extension. The first defines the application menu.
The second is the menu option Quit in this menu. Overwrite this method to make it return
a different list. See also L<Tk::AppWindow::Ext::MenuBar>

=cut

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd			icon							keyb			config variable
		[	'menu', 				undef,			"~appname", 		], 
		[	'menu_normal',		'appname::',		"~Quit",					'quit',		'application-exit',		'CTRL+Q',	], 
	)
}

sub NameSpace {
	return $_[0]->{NAMESPACE}
}

=item B<openURL>I<($file_or_web)>

Opens I<$file_or_web> in the default application of your desktop.

Please provide 'https://' or whatever protocol in front if it is on the web.

=cut

sub openURL {
	my ($self, $url) = @_;
#	print "is web $url\n" if $url =~ /^[A-Za-z]+:\/\//;
	if ($mswin) {
		if ($url =~ /^[A-Za-z]+:\/\//) { #is a web document
			system("explorer \"$url\"");
		} else {
			system("\"$url\"");
		}
	} else {
		system("xdg-open \"$url\"");
	}
}

=item B<pause>I<($time)>

Pauses the app for $time miliseconds in a non blocking way.

=cut

sub pause {
	my ($self, $time) = @_;
	my $var = 0;
	$self->after($time, sub { $time = 1 });
	$self->waitVariable(\$time);
}


=item B<popDialog>I<($title, $message, $icon, @buttons)>

Pops up a dialogbox with @buttons.
The first button is the default button.
Returns the name of the button pressed.
If you press the Escape key it wil return '*Cancel*'.

=cut

sub popDialog {
	my ($self, $title, $text, $icon, @buttons) = @_;
	$icon = 'dialog-question' unless defined $icon;
	my @padding = (-padx => 10, -pady => 10);
	my $q = $self->YADialog(
		-title => $title,
		-buttons => \@buttons,
		-defaultbutton => $buttons[0],
	);
	my $img = $self->getArt($icon, 48); 
	$q->Label(-image => $img)->pack(-side => 'left', @padding) if defined $img;
	$q->Label(
		-anchor => 'w',
		-text => $text,
	)->pack(-side => 'left', -fill => 'x', @padding);
	my $answer = $q->Show(-popover => $self);
	$q->destroy;
	return $answer
}

=item B<popEntry>I<($title, $message, $value, $icon)>

Pops up a dialog box with an Entry widget.
returns the entered value if the ok button is pressed.
Otherwise returns undef..

=cut

sub popEntry {
	my ($self, $title, $text, $value, $icon) = @_;
	$icon = 'dialog-information' unless defined $icon;
	my @padding = (-padx => 10, -pady => 10);
	my $q = $self->YADialog(
		-title => $title,
		-buttons => [qw(Ok Cancel)],
	);
	$q->Label(-image => $self->getArt($icon, 48))->pack(-side => 'left', @padding);
	my $f = $q->Frame->pack(-side => 'left', @padding);
	$f->Label(
		-anchor => 'w',
		-text => $text,
	)->pack(-fill => 'x', -padx => 2, -pady => 2);
	my $e = $f->Entry->pack(-fill => 'x', -padx => 2, -pady => 2);
	$e->insert('end', $value) if defined $value;
	$e->focus;
	$e->bind('<Return>', sub { 
		$q->{PRESSED} = 'Ok' 
	});
	
	my $result;
	my $answer = $q->Show(-popover => $self);
	$result = $e->get if $answer eq 'Ok';

	$q->destroy;
	return $result
}

=item B<popForm>I<(%options)>

This method uses L<Tk::QuickForm> to pop up a form for the user to fill out.
Returns a hash with all defined keys if the user clicks the Ok button,
Returns an empty hash if the user clicks cancel.
It can take the following options:

=over 4

=item B<-acceptempty>

Boolean. By default false. If set, empty fields will not evaluate as error.

=item B<-initialvalues>

A reference to a hash with default values to be loaded.

=item B<-oktext>

By default 'Ok'. You can change it to any text you like.

=item B<-structure>

Same option as in L<Tk::QuickForm>. See there.

=item B<-title>

The window title.

=back

=cut

sub popForm {
	my ($self, %args) = @_;

	my $structure = delete $args{'-structure'};
	croak "Option -structure not set" unless defined $structure;

	my $initial = delete $args{'-initialvalues'};

	my $oktext = delete $args{'-oktext'};
	$oktext = 'Ok' unless defined $oktext;

	my $acceptempty = delete $args{'-acceptempty'};
	$acceptempty = 0 unless defined $acceptempty;

	my $q = $self->YADialog(%args,
		-buttons => ['Cancel'],
	);
	my $b = $q->Subwidget('buttonframe')->Button(
		-text => $oktext,
		-command => sub {
			$q->Pressed('Ok')
		}
	);
	$q->ButtonPack($b);

	#getting icons for Tk::QuickForm
	my %qopts = ();
	my @images = (
		['-fileimage', 'text-x-plain', 16],
		['-folderimage', 'folder', 16],
		['-fontimage', 'gtk-select-font', 16],
		['-msgimage', 'dialog-question', 32],
		['-newfolderimage', 'folder-new', 16],
		['-reloadimage', 'appointment-recurring', 16],
		['-warnimage', 'dialog-warning', 32],
	);
	for (@images) {
		my ($opt, $icon, $size) = @$_;
		my $img = $self->getArt($icon, $size);
		$qopts{$opt} = $img if defined $img;
	}

	my $form = $q->QuickForm(%qopts,
		-acceptempty => $acceptempty,
		-diriconcall => ['getDirIcon', $self],
		-fileiconcall => ['getFileIcon', $self],
		-linkiconcall => ['getLinkIcon', $self],
		-structure => $structure,
		-postvalidatecall => sub {
			my $flag = shift;
			if ($flag) {
				$b->configure('-state', 'normal')
			} else {
				$b->configure('-state', 'disabled')
			}
		},
	)->pack(-expand => 1, -fill => 'both', -padx => 2, -pady => 2);
	$form->createForm;
	$form->put(%$initial) if defined $initial;

	my %result = ();
	my $answer = $q->Show(-popover => $self);
	%result = $form->get if $answer eq 'Ok';

	$q->destroy;
	return %result
}

=item B<popMessage>I<($message, $icon, ?$size?)>

Pops up a message box with a close button.

=cut

sub popMessage {
	my ($self, $text, $icon, $size) = @_;
	$icon = 'dialog-information' unless defined $icon;
	$size = 48 unless defined $size;
	my $m = $self->YAMessage(
		-title => 'Message',
		-text => $text,
		-image => $self->getArt($icon, $size),
	);
	$m->Show(-popover => $self);
	$m->destroy;
}

sub popTest {
	my $self = shift;
	$self->popMessage('You did something');
}

sub PostConfig {
	my $self = shift;
	delete $self->{ARGS};

	#set logo
	my $lgf = $self->cget('-logo');
	if ((defined $lgf) and (-e $lgf)) {
		my $logo = $self->Photo(-file => $lgf, -format => 'PNG');
		$self->iconimage($logo);
	}
	#set geometry
	if ($self->configGet('-savegeometry')) {
		my $cf = $self->extGet('ConfigFolder');
		if (defined $cf) {
			my ($g) = $cf->loadList('geometry', 'aw geometry');
			$self->geometry($g) if defined $g;
		}
	}
	my $pc = $self->{POSTCONFIG};
	for (@$pc) { $_->execute }

	#create filepicker images
	my @images = (
		['-msgimage', 'dialog-information', 32],
		['-newfolderimage', 'folder-new', 16],
		['-reloadimage', 'appointment-recurring', 16],
		['-warnimage', 'dialog-warning', 32],
	);
	my $picker = $self->Subwidget('FilePicker');
	for (@images) {
		my ($opt, $icon, $size) = @$_;
		my $img = $self->getArt($icon, $size);
		$picker->configure($opt, $img) if defined $img;
	}

}

=item B<StatusAttach>I<$widget, $text>

Attaches a status message to $widget

=cut

sub StatusAttach {
	my ($self, $widget, $text) = @_;
	my $s = $self->extGet('StatusBar');
	$s->Attach($widget, $text) if defined $s;
}

=item B<StatusMessage>I<($text>)>

Sends a message to the status bar if it is loaded. See L<Tk::AppWindow::Ext::StatusBar>

=cut

sub StatusMessage {
	my $self = shift;
	my $sb = $self->extGet('StatusBar');
	$sb->Message(@_) if defined $sb;
}

=item B<progressAdd>I<($name, $label, $size, $variable)>

Adds a progress bar to the status bar.
Extension B<StatusBar> must be loaded for this to work.

=cut

sub progressAdd {
	my ($self, $name, $label, $size, $variable) = @_;
	my $sb = $self->extGet('StatusBar');
	$sb->AddProgressItem($name,
		-label => $label,
		-length => 150,
		-from => 0,
		-to => $size,
		-variable => $variable,
	) if defined $sb;
}

=item B<progressRemove>I<($name)>

Removes a progress bar from the status bar.
Extension B<StatusBar> must be loaded for this to work.

=cut

sub progressRemove {
	my ($self, $name) = @_;
	my $sb = $self->extGet('StatusBar');
	$sb->Delete($name) if defined $sb;
}

=item B<ToolItems>

Returns an empty list. It is called by the B<ToolBar> extension. Overwrite it
if you like.

=cut

sub ToolItems {
	my $self = shift;
	return (
	)
}

sub WorkSpace {
	my $self = shift;
	$self->{WORKSPACE} = $self->Subwidget(shift) if @_;
	return $self->{WORKSPACE}
}

=back

=head1 FILE DIALOGS

The B<pickWhatEver> methods launch filedialogs. They are meant as a replacement
of the classic B<getOpenFile> and B<getSaveFile> methods. The pick methods
can be called with a lot of the options for L<Tk::FilePicker> and L<Tk::FileBrowser>.
See also there. Additionaly, they can also be called with these options:

=over 4

=item B<-initialdir>

Directory to load on pop.

=item B<-initialfile>

Suggested file name.

=back

The pick methods always return their results in list context. So
even when you expect only one result you have to do:

 my ($file) = $fp->pickWhatEver(%options);

=over 4

=item B<pick>

The basic pick method.

=item B<pickFileOpen>

Calls B<pick> configured to select one file for opening. Equivalent to:

 my ($file) = $window->pick(
    -checkoverwrite => 0,
    -showfolders => 1,
    -showfiles => 1,
    -selectmode => 'single',
    -selectstring => 'Open',
    -title => 'Open file',
 );

=item B<pickFileOpenMulti>

Calls B<pick> configured to select multiple files for opening. Equivalent to:

 my @files = $window->pick(
    -checkoverwrite => 0,
    -showfolders => 1,
    -showfiles => 1,
    -selectmode => 'extended',
    -selectstring => 'Open',
    -title => 'Open file',
 );

=item B<pickFileSave>

Calls B<pick> configured to select one file for saving. Pops
a dialog for overwrite if the selected file exists. Equivalent to:

 my ($file) = $window->pick(
    -checkoverwrite => 1,
    -showfolders => 1,
    -showfiles => 1,
    -selectmode => 'single',
    -selectstring => 'Save',
    -title => 'Save file',
 );

=item B<pickFolderSelect>

Calls B<pick> configured to select one folder. Equivalent to:

 my ($folder) = $window->pick(
    -checkoverwrite => 0,
    -showfolders => 1,
    -showfiles => 0,
    -selectmode => 'single',
    -selectstring => 'Select',
    -title => 'Select folder',
 );

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 LICENSE

Same as Perl.

=head1 BUGS

If you find any, please contact the author.

=cut

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow::OverView>

=item L<Tk::AppWindow::CookBook>

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::AppWindow::Commands>

=item L<Tk::AppWindow::ConfigVariables>

=back

=cut

1;
__END__
















