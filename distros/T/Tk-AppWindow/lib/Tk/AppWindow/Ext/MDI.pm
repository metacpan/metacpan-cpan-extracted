package Tk::AppWindow::Ext::MDI;

=head1 NAME

Tk::AppWindow::Ext::MDI - multiple document interface

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.15";

use base qw( Tk::AppWindow::BaseClasses::Extension );

use File::Basename;
use File::Spec;
use File::stat;
use Time::localtime;
require Tk::LabFrame;
require Tk::YAMessage;
require Tk::YANoteBook;

use Config;
my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MDI'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Provides a multi document interface to your application.

When L<Tk::AppWindow::Ext::MenuBar> is loaded it creates menu 
entries for creating, opening, saving and closing files. It also
maintains a history of recently closed files.

When L<Tk::AppWindow::Ext::ToolBar> is loaded it creates toolbuttons
for creating, opening, saving and closing files.

It features deferred loading. If you open a document it will not load the document
until there is a need to access it. This comes in handy when you want
to open multiple documents at one time.

You should define a content handler based on the abstract
baseclass L<Tk::AppWindow::BaseClasses::ContentManager>. See also there.

This extension will also load the extensions B<ConfigFolder> and B<Daemons>.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-contentmanagerclass>

This one should always be specified and you should always define a 
content manager class inheriting L<Tk::AppWindow::BaseClasses::ContentManager>.
This base class is a valid Tk widget.

=item Switch: B<-contentmanageroptions>

The possible options to pass on to the contentmanager.
These will also become options to the main application.

=item Switch: B<-diskmonitorinterval>

Default value 100. This means every 100 cycles of the B<Daemons> extension. Specifies the interval for
monitoring the disk status of documents. 

=item Switch: B<-filetypes>

Default value is "All files|*"

=item Switch: B<-historymenupath>

Specifies the default location in the main menu of the history menu.
Default value is File::Open recent. See also L<Tk::AppWindow::Ext::MenuBar>.

=item Switch: B<-maxhistory>

Default value is 12.

=item Switch: B<-maxtablength>

Default value 16

Maximum size of the document tab in the document bar.

=item Switch: B<-modifiedmonitorinterval>

Default value 25. This means every 25 cycles of the B<Daemons> extension. Specifies the interval for
monitoring the modified status of documents. 

=item Switch: B<-readonly>

Default value 0. If set to 1 MDI will operate in read only mode.

=back

=head1 COMMANDS

The following commands are defined.

=over 4

=item B<deferred_open>

Takes a document name that is in deferred state as parameter and creates a new content handler for it.
Returns a boolean indicating the succesfull load of its content.

=item B<doc_close>

Takes a document name as parameter and closes it.
If no parameter is specified closes the current selected document.
Returns a boolean for succes or failure.

=item B<doc_new>

Takes a document name as parameter and creates a new document.
If no parameter is specified an Untitled document is created.
Returns a boolean for succes or failure.

=item B<doc_open>

Takes a filename as parameter and opens it in deferred state.
If no parameter is specified a file dialog is issued.
Returns a boolean for succes or failure.

=item B<doc_rename>

Takes two document names as parameters and renames the first one to
the second one in the interface.

=item B<doc_save>

Takes a document name as parameter and saves it if it is modified.
If no parameter is specified the current selected document is saved.
Returns a boolean for succes or failure.

=item B<doc_save_as>

Takes a document name as parameter and issues a file dialog to rename it.
If no parameter is specified the current selected document is initiated in the dialog.
Returns a boolean for succes or failure.

=item B<doc_save_all>

Saves all open and modified documents.
Returns a boolean for succes or failure.

=item B<doc_select>

Select an opened document.

=item B<pop_hist_menu>

Is called when the file menu is opened in the menubar. It populates the
'Open recent' menu with the current history.

=item B<set_title>

Takes a document name as parameter and sets the main window title accordingly.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require( qw[ConfigFolder Daemons] );

	$self->{CMOPTIONS} = {};
	$self->{DEFERRED} = {};
	$self->{DOCS} = {};
	$self->{FORCECLOSE} = 0;
	$self->{HISTORY} = [];
	$self->{HISTORYDISABLED} = 0;
	$self->{INTERFACE} = undef;
	$self->{MONITOR} = {};
	$self->{SELECTDISABLED} = 0;
	$self->{SELECTED} = undef;

	my $args = $self->GetArgsRef;
	my $cmo = delete $args->{'-contentmanageroptions'};
	$cmo = [] unless defined $cmo;
	my @preconfig = ();
	for (@$cmo) {
		push @preconfig, $_ => ['PASSIVE', undef, undef, ''];
	}

	$self->addPreConfig(@preconfig,
		-contentmanagerclass => ['PASSIVE', undef, undef, 'Wx::Perl::FrameWorks::BaseClasses::ContentManager'],
		-contentmanageroptions => ['PASSIVE', undef, undef, $cmo],
		-diskmonitorinterval => ['PASSIVE', undef, undef, 100], #times 10 ms
		-maxhistory => ['PASSIVE', undef, undef, 12],
		-filetypes => ['PASSIVE', undef, undef, "All files|*"],
		-historymenupath => ['PASSIVE', undef, undef, 'File::Open recent'],
		-maxtablength => ['PASSIVE', undef, undef, 16],
		-modifiedmonitorinterval => ['PASSIVE', undef, undef, 25], #times 10 ms
		-readonly => ['PASSIVE', undef, undef, 0],
	);
	$self->cmdConfig(
		deferred_open => ['deferredOpen', $self],
		doc_close => ['CmdDocClose', $self],
		doc_new => ['CmdDocNew', $self],
		doc_open => ['CmdDocOpen', $self],
		doc_rename => ['docRename', $self],
		doc_save => ['CmdDocSave', $self],
		doc_save_as => ['CmdDocSaveAs', $self],
		$self->CommandDocSaveAll,
		doc_select => ['docSelect', $self],
		set_title => ['setTitle', $self],
		pop_hist_menu => ['CmdPopulateHistoryMenu', $self],
		pop_hist_tool => ['CmdPopulateHistoryTool', $self],
	);

	$self->addPostConfig('DoPostConfig', $self);
	$self->historyLoad;
	return $self;
}

=head1 METHODS

=over 4

=cut

sub CanQuit {
	my $self = shift;
	if ($self->docConfirmSaveAll) {
		$self->docForceClose(1);
		return 1
	}
	return 0
}

sub CmdDocClose {
	my ($self, $name) =  @_;
	$name = $self->docSelected unless defined $name;
	return 1 unless defined $name;
	my $close = 1;
	my $fc = $self->docForceClose;
	if ($self->docForceClose or $self->docConfirmSave($name)) {
		my $geosave = $self->geometry;
		$close = $self->docClose($name);
		$self->interfaceRemove($name) if $close;
		$self->geometry($geosave);
	}
	$self->log("Closed '$name'") if $close;
	$self->logWarning("Failed closing '$name'") unless $close;
	$close = $name if $close;
	return $close
}


sub CmdDocNew {
	my ($self, $name) = @_;
	$name = $self->docUntitled unless defined $name;
	$self->deferredAssign($name);
	$self->interfaceAdd($name);

	$self->cmdExecute('doc_select', $name);
	return $name;
}

sub CmdDocOpen {
	my ($self, $file) = @_;
	unless (defined($file)) {
		my @op = ();
		@op = (-popover => 'mainwindow') unless $mswin;
		my $sel = $self->docSelected;
		push @op, -initialdir => dirname($sel) if defined $sel;
		$file = $self->getOpenFile(@op);
	}
	if (defined $file) {
		$file = File::Spec->rel2abs($file);
		if ($self->docExists($file)) {
			$self->cmdExecute('doc_select', $file);
			return $file
		}
		if ($self->cmdExecute('doc_new', $file)) {
			$self->historyRemove($file);
			$self->cmdExecute('doc_select', $file);
			$self->log("Opened '$file'");
			return $file;
		}
	}
 	return ''
}

sub CmdDocSave {
	my ($self, $name) = @_;
	return 1 if $self->configGet('-readonly');
	$name = $self->docSelected unless defined $name;
	return 1 unless defined $name;
	return 1 unless $self->docModified($name);
	
	my $doc = $self->docGet($name);

	if (defined $doc) {
		unless ($name =~ /^Untitled/) {
			if ($doc->Save($name)) {
				$self->monitorUpdate($name);
				$self->log("Saved '$name'");
				my $nav = $self->navigator;
				$nav->EntrySaved($name) if defined $nav; 
				return $name
			} else {
				$self->logWarning("Failed saving '$name'");
				return 0
			}
			
		} else {
			return $self->CmdDocSaveAs($name);
		}
	}
	return 0
}

sub CmdDocSaveAs {
	my ($self, $name) = @_;
	return 0 if $self->configGet('-readonly');
	$name = $self->docSelected unless defined $name;
	return 0 unless defined $name;

	my $doc = $self->docGet($name);
	if (defined $doc) {
		my @op = (-initialdir => dirname($name));
		push @op, -popover => 'mainwindow' unless $mswin;
		my $file = $self->getSaveFile(@op,);
		if (defined $file) {
			$file = File::Spec->rel2abs($file);
			if ($doc->Save($file)) {
				$self->log("Saved '$file'");
				$self->cmdExecute('doc_rename', $name, $file);
				return $file
			} else {
				$self->logWarning("Failed saving '$file'");
				return ''
			}
		}
	}
	return ''
}

sub CmdDocSaveAll {
	my $self = shift;
	my @list = $self->docList;
	my $succes = 1;
	for (@list) {
		$succes = '' unless $self->cmdExecute('doc_save', $_)
	}
	return $succes
}

sub CmdPopulateHistoryMenu {
	my $self = shift;
	my $mnu = $self->extGet('MenuBar');
	if (defined $mnu) {
		my $path = $self->configGet('-historymenupath');
		my ($menu, $index) = $mnu->FindMenuEntry($path);
		if (defined($menu)) {
			my $submenu = $menu->entrycget($index, '-menu');
			$submenu->delete(1, 'last');
			my $h = $self->{HISTORY};
			for (@$h) {
				my $f = $_;
				$submenu->add('command',
					-label => $f,
					-command => sub { $self->cmdExecute('doc_open', $f) }
				);
			}
			$submenu->add('separator');
			$submenu->add('command',
				-label => 'Clear list',
				-command => sub { @$h = () },
			);
		}
	}
}

sub CmdPopulateHistoryTool {
	my $self = shift;
	my $tb = $self->extGet('ToolBar');
	my $hist = $tb->GetItem('history');
	for ($hist->children) { $_->destroy }
	my $lf = $hist->LabFrame(
		-label => 'Recent files',
		-labelside => 'acrosstop',
	)->pack(-fill => 'both');
	my $f = $lf->Subwidget('frame');
	my $h = $self->{HISTORY};
	for (@$h) {
		my $file = $_;
		my $l = $f->Label(
			-anchor => 'w',
			-borderwidth => 1,
			-text => $file,
		)->pack(-fill => 'x');
		$l->bind('<Enter>', sub { $l->configure(-relief => 'raised') });
		$l->bind('<Leave>', sub { $l->configure(-relief => 'flat') });
		$l->bind('<Button-1>', sub { $l->configure(-relief => 'sunken') });
		$l->bind('<ButtonRelease-1>', sub {
			$l->configure(-relief => 'flat');
			$self->update;
			$tb->PopDown;
			$self->cmdExecute('doc_open', $file);
		});
	}
	$f->Frame(-borderwidth => 1, -relief => 'sunken', -height => 2)->pack(-fill => 'x', -pady => 2);
	my $l = $f->Label(
		-anchor => 'w',
		-borderwidth => 1,
		-text => 'Clear list',
	)->pack(-fill => 'x');
	$l->bind('<Enter>', sub { $l->configure(-relief => 'raised') });
	$l->bind('<Leave>', sub { $l->configure(-relief => 'flat') });
	$l->bind('<Button-1>', sub { $l->configure(-relief => 'sunken') });
	$l->bind('<ButtonRelease-1>', sub {
		$l->configure(-relief => 'flat');
		$self->update;
		$tb->PopDown;
		@$h = ();
	});
	my $width = 0;
	my $height = 0;
	for ($f->children) {
		my $w = $_->reqwidth;
		my $h = $_->reqheight;
		$width = $w if $w >$width;
		$height = $height + $h;
	}
	$hist->configure(-height => $height + 32, -width => $width + 12);
}

sub CommandDocSaveAll {
	my $self = shift;
	return doc_save_all => ['CmdDocSaveAll', $self],
}

=item B<ConfirmSaveDialog>I<($name)>

Pops a dialog with a warning that $name is unsaved.
Asks for your action. Does not check if $name is modified or not.
Returns the key you press, 'Yes', 'No', or cancel.
Does not do any saving or checking whether a file has been modified.

=cut

sub ConfirmSaveDialog {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $title = 'Warning, file modified';
	my $text = 	"Closing " . basename($name) .
		".\nDocument has been modified. Save it?";
	my $icon = 'dialog-warning';
	return $self->popDialog($title, $text, $icon, qw/Yes No Cancel/);
}

=item B<ContentSpace>I<($name)>

Returns the page frame widget in the notebook belonging to $name.

=cut

sub ContentSpace {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return $self->Interface->getPage($name);
}

=item B<CreateContentHandler>I($name);

Initiates a new content handler for $name.

=cut

sub CreateContentHandler {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $page = $self->ContentSpace($name);
	my $cmclass = $self->configGet('-contentmanagerclass');
	my $h = $page->$cmclass(-extension => $self)->pack(-expand => 1, -fill => 'both');
	$self->{DOCS}->{$name} = $h;
	return $h;
}

=item B<CreateInterface>

Creates a Tk::YANoteBook multiple document interface.

=cut

sub CreateInterface {
	my $self = shift;
	$self->{INTERFACE} = $self->WorkSpace->YANoteBook(
		-selecttabcall => ['cmdExecute', $self, 'doc_select'],
		-closetabcall => ['cmdExecute', $self, 'doc_close'],
	)->pack(-expand => 1, -fill => 'both');
}

=item B<deferredAssign>I<($name, ?$options?)>

This method is called when you open a document.
It adds document $name to the interface and stores $options
in the deferred hash. $options is a reference to a hash. It's keys can
be any option accepted by your content manager.

=cut

sub deferredAssign {
	my ($self, $name, $options) = @_;
	croak 'Name not defined' unless defined $name;
	$options = {} unless defined $options;
	$self->{DEFERRED}->{$name} = $options;
}

=item B<deferredExists>I<($name)>

Returns true if deferred entry $name exists.

=cut

sub deferredExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return exists $self->{DEFERRED}->{$name}
}

=item B<deferredList>

Returns a list of deferred documents.

=cut

sub deferredList {
	my $self = shift;
	my $d = $self->{DEFERRED};
	return keys %$d
}

=item B<deferredOpen>I<($name)>

This method is called when you access the document for the first time.
It creates the content manager with the deferred options and loads the file.

=cut

sub deferredOpen {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $doc = $self->CreateContentHandler($name);
	my $flag = 1;
	$flag = '' unless (-e $name) and ($doc->Load($name));
	my $options = $self->deferredOptions($name);
	$self->after(20, sub {
		for (keys %$options) {
			$doc->configure($_, $options->{$_})
		}
		$self->monitorAdd($name);
	});
	$self->deferredRemove($name);
	if ($flag) {
		$self->log("Loaded $name");
	} else {
		$self->logWarning("Failed loading $name");
	}
	$flag = $name if $flag;
	return $flag
}

=item B<deferredOptions>I<($name, ?$options?)>

Sets and returns a reference to the hash containing the
options for $name.

=cut

sub deferredOptions {
	my ($self, $name, $options) = @_;
	croak 'Name not defined' unless defined $name;
	my $def = $self->{DEFERRED};
	$def->{$name} = $options if defined $options;
	return $def->{$name} 
}

=item B<deferredRemove>I<($name)>

Removes $name from the deferred hash.

=cut

sub deferredRemove {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	delete $self->{DEFERRED}->{$name}
}

=item B<docClose>I<($name)>

Removes $name from the interface and destroys the content manager.
Also adds $name to the history list.

=cut

sub docClose {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	if ($self->deferredExists($name)) {
		$self->historyAdd($name);
		$self->deferredRemove($name);
		return $name
	}
	my $doc = $self->docGet($name);
	if ($doc->Close) {
		#Add to history
		$self->historyAdd($name);

		#delete from document hash
		delete $self->{DOCS}->{$name};
		$self->monitorRemove($name);

		if ((defined $self->docSelected) and ($self->docSelected eq $name)) { 
			$self->docSelected(undef);
		}
		$doc->destroy;
		return $name
	}
	return 0
}

=item B<docConfirmSave>I<($name)>

Checks if $name is modified and asks confirmation
for save. Saves the document if you press 'Yes'.
Returns 1 unless you cancel the dialog, then it returns 0.
 
=cut

sub docConfirmSave {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	if ($self->docModified($name)) {
		#confirm save dialog comes here
		my $answer = $self->ConfirmSaveDialog($name);
		if ($answer eq 'Yes') {
			return 0 unless $self->cmdExecute('doc_save', $name);
		} elsif ($answer eq 'No') {
			return 1
		} else {
			return 0
		}
	} else {
		return 1
	}
}

=item B<docConfirmSaveAll>

Calls docConfirmSave for all loaded documents.
returns 0 if a 'Cancel' is detected.

=cut

sub docConfirmSaveAll {
	my $self = shift;
	my $close = 1;
	my @docs = $self->docList;
	for (@docs) {
		my $name = $_;
		$close = $self->docConfirmSave($name);
		last if $close eq 0;
	}
	return $close;
}

=item B<docExists>I<($name)>

Returns true if $name exists in either loaded or deferred state.

=cut

sub docExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return 1 if exists $self->{DOCS}->{$name};
	return 1 if $self->deferredExists($name);
	return 0
}

=item B<docForceClose>I<(?$flag?)>

If $flag is set ConfirmSave dialogs will be skipped,
documents will be closed ruthlessly. Use with care
and always reset it back to 0 when you're done.

=cut

sub docForceClose {
	my $self = shift;
	$self->{FORCECLOSE} = shift if @_;
	return $self->{FORCECLOSE}
}


=item B<docFullList>

Returns a list of all documents, loaded and deferred.

=cut

sub docFullList {
	my $self = shift;
	return $self->docList, $self->deferredList;
}

=item B<docGet>I<($name)>

Returns the content manager object for $name.

=cut

sub docGet {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	$self->cmdExecute('deferred_open', $name) if $self->deferredExists($name);
	return $self->{DOCS}->{$name}
}

=item B<docList>

Returns a list of all loaded documents.

=cut

sub docList {
	my $self = shift;
	my $dochash = $self->{DOCS};
	return keys %$dochash;
}

=item B<docListDisplayed>

Returns a list of documents currently visible in the tabs bar.

=cut

sub docListDisplayed {
	my $self = shift;
	my $interface = $self->extGet('CoditMDI')->Interface;
	my $disp = $interface->{DISPLAYED};
	return @$disp
}

=item B<docListUnDisplayed>

Returns a list of documents currently not visible in the tabs bar.

=cut

sub docListUnDisplayed {
	my $self = shift;
	my $interface = $self->extGet('CoditMDI')->Interface;
	my $undisp = $interface->{UNDISPLAYED};
	return @$undisp
}

=item B<docModified>I<($name)>

Returns true if $name is modified.

=cut

sub docModified {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return 0 if $self->deferredExists($name);
	return $self->docGet($name)->IsModified;
}

=item B<docRename>I<($old, $new)>

Renames a loaded document.

=cut

sub docRename {
	my ($self, $old, $new) = @_;
	croak 'Old not defined' unless defined $old;
	croak 'New not defined' unless defined $new;

	unless ($old eq $new) {
		my $doc = delete $self->{DOCS}->{$old};
		$self->{DOCS}->{$new} = $doc;

		$self->interfaceRename($old, $new);
		$self->monitorRemove($old);
		$self->monitorAdd($new);

		if ($self->docSelected eq $old) {
			$self->cmdExecute('doc_select', $new)
		}
	}
}

=item B<docSelect>I<($name)>

Selects $name.

=cut

sub docSelect {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return if $self->selectDisabled;
	$self->cmdExecute('deferred_open', $name) if $self->deferredExists($name);
	$self->docSelected($name);
	$self->interfaceSelect($name);
	$self->docGet($name)->doSelect;
	$self->cmdExecute('set_title', $name);
}

=item B<docSelected>

Returns the name of the currently selected document.
Returns undef if no document is selected.

=cut

sub docSelected {
	my $self = shift;
	$self->{SELECTED} = shift if @_;
	return $self->{SELECTED}
}

=item B<docTitle>I<($name)>

Strips the path from $name for the title bar.

=cut

sub docTitle {
	my ($self, $name) = @_;
	return basename($name, '');
}

=item B<docUntitled>>

Returns 'Untitled' plus a digit '(d)'.
It checks how many untitled documents exists
and adjusts the number.

=cut

sub docUntitled {
	my $self = shift;
	my $name = 'Untitled';
	if ($self->docExists($name)) {
		my $num = 2;
		while ($self->docExists("$name ($num)")) { $num ++ }
		$name = "$name ($num)";
	}
	return $name
}

sub DoPostConfig {
	my $self = shift;
	$self->CreateInterface;
}

=item B<historyAdd>I<($name)>

=cut

sub historyAdd {
	my ($self, $filename) = @_;
	croak 'Name not defined' unless defined $filename;
	return if $self->historyDisabled;
	if (defined($filename) and (-e $filename)) {
		my $hist = $self->{HISTORY};
		unshift @$hist, $filename;

		#Keep history size at or below maximum
		my $siz = @$hist;
		pop @$hist if ($siz > $self->configGet('-maxhistory'));
	}
}

=item B<historyDisabled>I<($name)>

=cut

sub historyDisabled {
	my $self = shift;
	$self->{HISTORYDISABLED} = shift if @_;
	return $self->{HISTORYDISABLED}
}
	

=item B<historyLoad>

Loads the history file in the config folder.

=cut

sub historyLoad {
	my $self = shift;
	my $folder = $self->configGet('-configfolder');
	if (-e "$folder/history") {
		if (open(OFILE, "<", "$folder/history")) {
			my @history = ();
			while (<OFILE>) {
				my $line = $_;
				chomp $line;
				push @history, $line;
			}
			close OFILE;
			$self->{HISTORY} = \@history;
		}
	}
}

=item B<historyRemove>I<($name)>

Removes $name from the history list. Called when a document is
opened.

=cut

sub historyRemove {
	my ($self, $file) = @_;
	croak 'Name not defined' unless defined $file;
	return if $self->historyDisabled;
	my $h = $self->{HISTORY};
	my ($index) = grep { $h->[$_] eq $file } (0 .. @$h-1);
	splice @$h, $index, 1 if defined $index;
}

=item B<historySave>

Saves the history list to the history file in the config folder.

=cut

sub historySave {
	my $self = shift;
	my $hist = $self->{HISTORY};
	if (@$hist) {
		my $folder = $self->configGet('-configfolder');
		if (open(OFILE, ">", "$folder/history")) {
			for (@$hist) {
				print OFILE "$_\n";
			}
			close OFILE
		} else {
			warn "Cannot save document history"
		}
	}
}

=item B<Interface>

Returns a reference to the multiple document interface.

=cut

sub Interface {
	return $_[0]->{INTERFACE}
}

=item B<interfaceAdd>I<($name)>

Adds $name to the multiple document interface and to the
Selector if the Selector extension is loaded.

=cut

sub interfaceAdd {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;

	#add to document notebook
	my $if = $self->Interface;
	if (defined $if) {
		my @op = ();
		my $cti = $self->getArt('tab-close', 16);
		push @op, -closeimage => $cti if defined $cti;
		my $page = $if->addPage($name, @op,
			-title => $self->docTitle($name),
			-closebutton => 1,
		);
	}

	#add to navigator
	my $navigator = $self->navigator;
	if (defined $navigator) {
		$navigator->Add($name) if defined $navigator;
#		$self->interfaceCollapse;
	}
}

=item B<interfaceCollapse>

Collapses all folder trees in the document tree except the path of the selected entry, if extension Selector is loaded.

=cut

sub interfaceCollapse {
	my $self = shift;
	my $t = $self->Subwidget('NAVTREE');
	$t->collapseAll if defined $t;
}

=item B<interfaceExpand>

Opens all folder trees in the document tree, if extension Selector is loaded.

=cut

sub interfaceExpand {
	my $self = shift;
	my $t = $self->Subwidget('NAVTREE');
	$t->expandAll if defined $t;
}

sub interfaceGet {
	my $self = shift;
	my $navigator = $self->navigator;
	return $navigator
}

=item B<interfaceRemove>I<($name, ?$flag?)>

Removes $name from the multiple document interface and from the
Selector if the Selector extension is loaded.

=cut

sub interfaceRemove {
	my ($self, $name, $flag) = @_;
	croak 'Name not defined' unless defined $name;
	$flag = 1 unless defined $flag;
	#remove from document notebook
	my $if = $self->Interface;
	$if->deletePage($name) if (defined $if) and $flag;

	#remove from navigator
	my $navigator = $self->interfaceGet;
	$navigator->Delete($name) if defined $navigator;
}

=item B<interfaceRename>I<($old, $new)>

Renames the $old entry in the multiple document interface and the navigator.

=cut

sub interfaceRename {
	my ($self, $old, $new) = @_;
	croak 'Old not defined' unless defined $old;
	croak 'New not defined' unless defined $new;

	#rename in document notebook
	my $if = $self->Interface;
	if (defined $if) {
		$if->renamePage($old, $new);
		my $tab = $if->getTab($new);
		$tab->configure(
			-name => $new,
			-title => $self->docTitle($new),
		);
	}

	#rename in navigator
	my $navigator = $self->interfaceGet;
	if (defined $navigator) {
		$navigator->Delete($old);
		$navigator->Add($new);
	}
}

=item B<interfaceSelect>I<($name)>

Is called when something else than the user selects a document.

=cut

sub interfaceSelect {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;

	#select on document notebook
	my $if = $self->Interface;
	$if->selectPage($name) if defined $if;

	#select on  navigator
	my $navigator = $self->interfaceGet;
	$navigator->SelectEntry($name) if defined $navigator;
}

=item B<interfaceShow>I<($name)>

Makes I<$name> visible in the Selector.

=cut

sub interfaceShow {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;

	my $t = $self->Subwidget('NAVTREE');
	$t->entryShow($name) if defined $t;
}

=item B<MenuItems>

Returns the menu items for MDI. Called by extension B<MenuBar>.

=cut

sub MenuSaveAll {
	my $self = shift;
	return [	'menu_normal', 'File::', "Save ~all", 'doc_save_all', 'document-save', 'CTRL+L'],
}

sub MenuItems {
	my $self = shift;
	my $readonly = $self->configGet('-readonly');

	my @items = (
#        type              menupath       label                cmd                  icon              keyb
 		[	'menu', 				undef,			"~File" 	], 
	);
	push @items,
		[	'menu_normal',		'File::',		"~New",					'doc_new',				'document-new',	'CTRL+N'			], 
		[	'menu_separator',	'File::', 		'f1'], 
	unless $readonly;
	push @items,
		[	'menu_normal',		'File::',		"~Open",					'doc_open',			'document-open',	'CTRL+O'			], 
 		[	'menu', 				'File::',		"Open ~recent", 		'pop_hist_menu', 	],
	;
	push @items,
		[	'menu_separator',	'File::', 		'f2' ], 
		[	'menu_normal',		'File::',		"~Save",					'doc_save',			'document-save',	'CTRL+S'			], 
		[	'menu_normal',		'File::',		"S~ave as",				'doc_save_as',		'document-save-as',],
		$self->MenuSaveAll,
	unless $readonly;
	push @items,
		[	'menu_separator',	'File::', 		'f3' ], 
		[	'menu_normal',		'File::',		"~Close",				'doc_close',			'document-close',	'CTRL+SHIFT+O'	], 
	;
	return @items
}

=item B<monitorAdd>I<($name)>

Adds $name to the hash of monitored documents.
It will check it's modified status. It willcollect its time stamp, 
if $name is an existing file.

=cut

sub monitorAdd {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;

	my $dem = $self->extGet('Daemons');
	my $di = $self->configGet('-diskmonitorinterval');
	my $mi = $self->configGet('-modifiedmonitorinterval');

	$dem->jobAdd("$name-disk", $di, 'monitorDisk', $self, $name);
	$dem->jobAdd("$name-modified", $mi, 'monitorModified', $self, $name);
	my $hash = $self->{MONITOR};
	my $modified = $self->docModified($name);
	my $stamp;
	$stamp = ctime(stat($name)->mtime) if -e $name;
	$hash->{$name} = {
		modified => $modified,
		timestamp => $stamp,
	}
}


=item B<monitorDisk>I<($name)>

Checks if $name is modified on disk after it was loaded.
Launches a dialog for reload or ignore if so.

=cut

sub monitorDisk {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
#	print "monitorDisk $name\n";
	return unless -e $name;
	my $stamp = $self->{MONITOR}->{$name}->{'timestamp'};
	my $docstamp = ctime(stat($name)->mtime);
	if ($stamp ne $docstamp) {
		my $title = 'Warning, file modified on disk';
		my $text = 	"$name\nHas been modified on disk.";
		my $icon = 'dialog-warning';
		my $answer = $self->popDialog($title, $text, $icon, qw/Reload Ignore/);
		if ($answer eq 'Reload') {
			$self->docGet($name)->Load($name);
		}
		$self->{MONITOR}->{$name}->{'timestamp'} = $docstamp;
	}
}

=item B<monitorList>I<($name)>

returns a list of monitored documents.

=cut

sub monitorList {
	my $self = shift;
	my $hash = $self->{MONITOR};
	return sort keys %$hash;
}

=item B<monitorModified>I<($name)>

Checks if the modified status of the document has changed
and updates the navigator.

=cut

sub monitorModified {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
#	print "monitorModified $name\n";
	my $mod = $self->{MONITOR}->{$name}->{'modified'};
	my $docmod = $self->docModified($name);
	my $nav = $self->navigator;
	if ($mod ne $docmod) {
		if ($docmod) {
			$nav->EntryModified($name) if defined $nav;
		} else {
			$nav->EntrySaved($name) if defined $nav;
		}
		$self->{MONITOR}->{$name}->{'modified'} = $docmod;
	}
}

=item B<monitorRemove>I<($name)>

Removes $name from the hash of monitored documents.

=cut

sub monitorRemove {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $dem = $self->extGet('Daemons');
	$dem->jobRemove("$name-disk");
	$dem->jobRemove("$name-modified");
	delete $self->{MONITOR}->{$name};
}

=item B<monitorUpdate>I<($name)>

Assigns a fresh time stamp to $name. Called when a document is saved.

=cut

sub monitorUpdate {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	$self->{MONITOR}->{$name}->{'timestamp'} = ctime(stat($name)->mtime);
}

sub navigator {
	my $self = shift;
	my $nav = $self->extGet('Selector');
	$nav = $self->extGet('Navigator') unless defined $nav;
	return $nav
}

sub ReConfigure {
	my $self = shift;
	my @docs = $self->docList;
	for (@docs) {
		$self->docGet($_)->ConfigureCM;
	}
}

sub Quit {
	my $self = shift;
	my @docs = $self->docList;
# 	$self->docForceClose(1);
	for (@docs) {
		$self->CmdDocClose($_);
	}
	$self->historySave;
}

=item B<selectDisabled>I<?$flag?)>

Sets and returns the selectdisabled flag. If this flag is set,
no document can be selected. Use with care.

=cut

sub selectDisabled {
	my $self = shift;
	$self->{SELECTDISABLED} = shift if @_;
	return $self->{SELECTDISABLED}
}

sub setTitle {
	my ($self, $name) = @_;
	my $appname = $self->configGet('-appname');
	$self->configPut(-title => "$name - $appname") if defined $name;
	$self->configPut(-title => $appname) unless defined $name;
}


=item B<silentMode>I<($flag)>

Takes a boolean as parameter. When silentMode is on the document bar will not update,
document history and select are disabled. This will speed up things when you open
multiple documents at once.

=cut

sub silentMode {
	my ($self, $flag) = @_;
	unless (defined $flag) {
		croak "You must specify a boolean flag";
		return
	}
	my $if = $self->Interface;
	if ($flag) {
		$self->{'autoupdate'} = $if->autoupdate;
		$if->autoupdate(0);

		$self->{'historydisabled'} = $self->historyDisabled;
		$self->historyDisabled(1);

		$self->{'selectdisabled'} = $self->selectDisabled;
		$self->selectDisabled(1);

	} else {
		my $a = $self->{'autoupdate'};
		$if->autoupdate($a) if defined $a;
		delete $self->{'autoupdate'};

		my $h = $self->{'historydisabled'};
		$self->historyDisabled($h) if defined $h;
		delete $self->{'historydisabled'};

		my $d = $self->{'selectdisabled'};
		$self->selectDisabled($d) if defined $d;
		delete $self->{'selectdisabled'};
	}
}

sub ToolSaveAll {
	my $self = shift;
	return [	'tool_button',		'Save all',		'doc_save_all',		'document-save',	'Save all open documents'], 
}

=item B<ToolItems>

Returns the tool items for MDI. Called by extension B<ToolBar>.

=cut

sub ToolItems {
	my $self = shift;
	my $readonly = $self->configGet('-readonly');
	my @items = ();

	push @items,
		#	 type					label			cmd					icon					help		
		[	'tool_button',		'New',		'doc_new',			'document-new',	'Create a new document'],
	unless $readonly;

	push @items,
		[	'tool_list',    'history', 'pop_hist_tool' ],
		[	'tool_button',		'Open',		'doc_open',		'document-open',	'Open a document'],
		[	'tool_list_end' ],
		
	;

	push @items,
		
		[	'tool_list' ],
		[	'tool_button',		'Save',		'doc_save',		'document-save',	'Save current document'], 
		[	'tool_button',		'Save as ',		'doc_save_as',		'document-save-as',	'Rename and save current document'],
		$self->ToolSaveAll,
		[	'tool_list_end' ],
	unless $readonly;

	push @items,
		[	'tool_button',		'Close',		'doc_close',		'document-close',	'Close current document'], 
	; 
	return @items
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

=item L<Tk::AppWindow::BaseClasses::ContentManager>

=item L<Tk::AppWindow::Ext::ConfigFolder>

=item L<Tk::AppWindow::Ext::Selector>

=back

=cut

1;