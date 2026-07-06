package Tk::FileBrowser;

=head1 NAME

Tk::FileBrowser - Advanced file system explorer

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION = '0.14';

use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'FileBrowser';

use POSIX qw( strftime );

use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';

use Cwd;
use File::Basename;
use File::Spec;
use File::Spec::Link;
use Tie::Watch;
use Tk;
require Tk::ListBrowser;
use Tk::FileBrowser::Item;
require Tk::Photo;
require Tk::PNG;
require Tk::LabFrame;
require Tk::ListEntry;
require Tk::YADialog;
require Tk::Balloon;
#require Tk::YAMessage;

my $iconfolder = Tk::findINC('Tk/FileBrowser/Icons');

my $osname = $Config{'osname'};

my %timedata = (
	Accessed => 'atime',
	Created => 'ctime',
	Modified => 'mtime',
);

my %viewoptions = (
	icon => {
		-arrange => 'row',
		-textside => 'bottom',
		-textlength => 50,
		-textanchor => '',
		-wraplength => 110,
	},
	compact => {
		-arrange => 'column',
		-textlength => 30,
		-textside => 'right',
		-textanchor => 'w',
		-wraplength => 0,
	},
	detailed => {
		-arrange => 'tree',
		-textlength => 0,
		-textside => 'right',
		-textanchor => 'w',
		-wraplength => 0,
	},
);

my $sample;

=head1 SYNOPSIS

 require Tk::FileBrowser;
 my $b = $window->FileBrowser(@options)->pack;
 $b->load($folder);

=head1 DESCRIPTION

A multicolumn file browser widget. Columns are configurable, sortable
and resizable.

if you left-click the header bar, you will get a popup menu to configure
case dependant sort, directories first and show hidden.

if you left-click the tree widget, you will get a popup menu to open the
current selected entry.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-casedependantsort>

Default value 0;

If you change the value you have to call B<refresh> to see your changes.

=item Switch: B<-columns>

Specify a list of column names to display. Only available at create
time. Allowed values are 'Accessed', 'Created', 'Link', 'Modified', 'Size' and any you
have defined through the B<-columntypes> option.

Default value ['Size', 'Modified'].

The 'Name' column is always present and always first.

=item Switch: B<-columntypes>

Specify a list of column types you ish to define. Here is an example we use in our test file. I adds the colun 'Big',
which marks every entry that is geater than 2048 with an 'X', and sorts on size.

 my $fb = $app->FileBrowser(
    -columns => [qw[Size Modified Big]],
    -columntypes => [
       Big => {
          display => sub {
             my ($data) = @_;
              return 'X' if $data->size > 2048;
             return '';
          },
          test => sub {
             my ($data1, $data2) = @_;
             return $fb->testSize($data1, $data2);
          },
       },
    ],
 )->pack(
    -expand => 1,
   -fill => 'both',
 );

=item Switch: B<-compactimage>

Icon used to represent the compact view mode on it's button.

=item Switch B<-createfolderbutton>

Default value 0. If set a button is displayed on top right allowing the user to create a new folder.

=item Switch: B<-detailsimage>

Icon used to represent the detailed view mode on it's button.

=item Switch B<-dateformat>

Defaultvalue: "%Y-%m-%d %H:%M". Specifies how time stamps should be represented.

=item Switch: B<-directoriesfirst>

Default value 1.

If you change the value you have to call B<refresh> to see your changes.

=item Switch: B<-diriconcall>

Callback for obtaining the dir icon. By default it is set
to a call that returns the default folder.xpm in the Perl/Tk
distribution.

=item Switch: B<-fileiconcall>

Callback for obtaining the file icon. By default it is set
to a call that returns the default file.xpm in the Perl/Tk
distribution.

=item Switch: B<-headermenu>

Specifies a list of menuitems for the context menu of the header. By default
it is set to a list with checkbuttons entries for -sortcase, -directoriesfirst and -showhidden.

=item Switch: B<-iconviewimage>

Icon used to represent the icon view mode on it's button.

=item Switch: B<-invokefile>

This callback is executed when a user double clicks a file.

=item Switch: B<-linkiconcall>

Callback for obtaining the link icon. By default it is set
to a call that returns an xpm inside this module.

=item Switch: B<-listmenu>

Specifies a list of menuitems for the context menu of the file list. By default
it returns a list with a an Open command.

=item Switch: B<-loadfilter>

Filter applied during load. Default value ''.

=item Switch: B<-loadfilterfolders>

Specifies if filters are applied to folders during load. Default value 0.

If you change the value you have to call B<reload> to see your changes.

=item Switch B<-msgimage>

Image displayed in message pop ups. By default set to the Tk info pixmap.

=item Switch B<-newfolderimage>

Image for the create folder button. By default set to the Tk info pixmap.

=item Switch B<-postloadcall>

Callback called after a call to B<load>

=item Switch: B<-reloadimage>

Image for the reload button.

=item Switch: B<-showfiles>

Default value 1;

If you change the value you have to call B<reload> to see your changes.

=item Switch: B<-showfolders>

Default value 1;

If you change the value you have to call B<reload> to see your changes.

=item Switch: B<-showhidden>

Default value 0;

If you change the value you have to call B<reload> to see your changes.

=item Switch: B<-sorton>

Can be any valid column name. Default value 'Name'.

If you change the value you have to call B<refresh> to see your changes.

=item Switch: B<-sortorder>

Can be 'ascending' or 'descending'. Default value 'ascending'.

If you change the value you have to call B<refresh> to see your changes.

=item Switch: B<-viewmode>

Default value 'detailed'. Can be 'compact', 'detailed' or 'icon'.
Sets the view mode for displaying list entries.

=item Switch: B<-warnimage>

Image displayed in warning dialogs. By default set to the 'warning' Pixmap of Tk.

=back

=head1 ADVERTISED SUBWIDGETS

=over 4

=item B<Entry>

Class Tk::ListEntry.

=item B<Tree>

Class Tk::ListBrowser.

=back

=head1 KEYBINDINGS

=over 4

=item B<CTRL+A>

Selects all entries in the root of the list.

=item B<CTRL+F>

Shows the filter bar.

=item B<CTRL+P>

Pops a properties window with details about the current selection. A selection must be present.

=item B<F5>

Reload.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	my $col = delete $args->{'-columns'};
	$col = ['Size', 'Modified'] unless defined $col;
	my @columns = @$col;
	my $columntypes = delete $args->{'-columntypes'};

	$self->SUPER::Populate($args);
	
	###################################################################
	#define column types
	my %column_types = (
		Name => {
			display => sub { return $self->nameString(@_) },
			test => sub { return $self->testName(@_) },
			width => 190,
		},
		Accessed => {
			data => sub { my $i = shift; return $i->accessed },
			display => sub { return $self->dateString('Accessed', @_) },
			test => sub { return $self->testDate('Accessed', @_) },
			options => [-sortfield => 'data', -sortnumerical => 1],
			width => 120,
		},
		Created => {
			data => sub { my $i = shift; return $i->created },
			display => sub { return $self->dateString('Created', @_) },
			test => sub { return $self->testDate('Created', @_) },
			options => [-sortfield => 'data', -sortnumerical => 1],
			width => 120,
		},
		Link => {
			data => sub { return '' },
			display => sub { return $self->linkString(@_) },
			test => sub { return $self->testLink(@_) },
			options => [-sortfield => 'text', -sortnumerical => 0],
			width => 190,
		},
		Modified => {
			data => sub { my $i = shift; return $i->modified },
			display => sub { return $self->dateString('Modified', @_) },
			test => sub { return $self->testDate('Modified', @_) },
			options => [-sortfield => 'data', -sortnumerical => 1],
			width => 120,
		},
		Size => {
			data => sub { my $i = shift; return $i->size },
			display => sub { return $self->sizeString(@_) },
			test => sub { return $self->testSize(@_) },
			options => [-sortfield => 'data', -sortnumerical => 1],
			width => 60,
		},
		Type => {
			data => sub { my $i = shift; return $i->type },
			display => sub { my $i = shift; return $i->type  },
			test => sub { return $self->testType(@_) },
			options => [-sortfield => 'text', -sortnumerical => 0],
			width => 180,
		},
	);
	if (defined $columntypes) {
		while (@$columntypes) {
			my $key = shift @$columntypes;
			my $data = shift @$columntypes;
			$column_types{$key} = $data;
		}
	}
	
	my $basetxt = '';
	my $sep = '/';
	$sep = '\\' if $osname eq 'MSWin32';
	$self->{BASE} = undef;
	$self->{COLTYPES} = \%column_types;
	$self->{JOBSTACK} = [];
	$self->{NOREFRESH} = 0;
	$self->{SEPARATOR} = $sep;

	my @padding = (-padx => 2, -pady => 2);
	my @pack = (-side => 'left', @padding);

	#setting up load bar
	my $bl = $self->Balloon;
	my $lframe = $self->Frame->pack(-fill => 'x');
	my ($rows, $columns, $details);
	$rows = $lframe->Button(
		-relief => 'flat',
		-text => 'R',
		-command => ['viewmode', $self, 'icon'],
	)->pack(@pack);
	$self->Advertise('icon', $rows);
	$bl->attach($rows, -balloonmsg => 'Icon view mode');
	$columns = $lframe->Button(
		-relief => 'flat',
		-text => 'C',
		-command => ['viewmode', $self, 'compact'],
	)->pack(@pack);
	$self->Advertise('compact', $columns);
	$bl->attach($columns, -balloonmsg => 'Compact view mode');
	$details = $lframe->Button(
		-relief => 'flat',
		-text => 'D',
		-command => ['viewmode', $self, 'detailed'],
	)->pack(@pack);
	$self->Advertise('detailed', $details);
	$bl->attach($details, -balloonmsg => 'Detailed view mode');

	my $entry = $lframe->ListEntry(
		-command => ['EditSelect', $self],
		-motionselect => 0,
		-textvariable => \$basetxt,
	)->pack(@pack, -expand => 1, -fill => 'x');
	$self->Advertise('Entry', $entry);

	my $reload = $lframe->Button(
		-text => 'Reload',
		-relief => 'flat',
		-command => ['reload', $self],
	)->pack(@pack);
	$bl->attach($reload, -balloonmsg => 'Reload');
	
	my $createfolderbutton = $lframe->Button(
		-text => 'New folder',
		-command => ['createFolder', $self],
	);
	$self->Advertise('CreateDirButton', $createfolderbutton);
	$bl->attach($createfolderbutton, -balloonmsg => 'New directory');


	###################################################################
	#setting up the listbrowser widget


	my $lbopt = $viewoptions{'tree'};
	my $lb = $self->ListBrowser(%$lbopt,
		-autorefresh => 1,
		-command => ['Invoke', $self],
		-entryclass => 'Tk::FileBrowser::Item',
		-filtercolumns => 1,
		-indicatorprecmd => ['IndicatorPressed', $self],
		-selectmode => 'multiple',
		-separator => $sep,
		-sortfield => '-fullname',
	)->pack(@padding,
		-expand => 1, 
		-fill => 'both',
	);
	$lb->forceWidth($column_types{'Name'}->{'width'});
	$lb->priorityMax(1);

	$self->Advertise('LB' => $lb);
	my $c = $lb->Subwidget('Canvas');
	$c->Tk::bind('<Control-a>', [$self, 'selectAll']);
	$c->Tk::bind('<Control-p>', [$self, 'propertiesPop']);
	$c->Tk::bind('<F5>', [$self, 'reload']);
	$c->Tk::bind('<ButtonRelease-3>' => [$self, 'lmPost', Ev('X'), Ev('Y')]);

	###################################################################
	#setting up columns and headers
	$lb->headerCreate('',
		-text => => 'Name',
		-contextcall => ['hmPost', $self],
		-sortable => 1,
	);
	for (@columns) {
		my $item = $_;
		my $opt = $column_types{$item}->{'options'};
		my $col = $lb->columnCreate($item, @$opt);
		$col->forceWidth($column_types{$item}->{'width'});
		$lb->headerCreate($item,
			-text => => $item,
			-contextcall => ['hmPost', $self],
			-sortable => 1,
		);
	}
	$lb->sortMode('', 'ascending');
	$lb->headerPlace;
	
	###################################################################
	
	###################################################################
	#setting up header context menu
	my $hmcase;
	$self->Advertise('HMCase', \$hmcase);
	new Tie::Watch(
		-variable => \$hmcase,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			unless ($self->noRefresh) {
				$self->configure('-casedependantsort', $value);
				$self->after(1, ['refresh', $self]);;
			}
		},
	);
	my $hmfolders;
	$self->Advertise('HMFolders', \$hmfolders);
	new Tie::Watch(
		-variable => \$hmfolders,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			unless ($self->noRefresh) {
				$self->configure('-directoriesfirst', $value);
				$self->after(1, ['refresh', $self]);;
			}
		},
	);
	my $hmhidden;
	$self->Advertise('HMHidden', \$hmhidden);
	new Tie::Watch(
		-variable => \$hmhidden,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			unless ($self->noRefresh) {
				$self->configure('-showhidden', $value);
				$self->after(1, ['reload', $self]);;
			}
		},
	);
	my @headermenu = (
		[checkbutton => 'Sort case dependant', -variable => \$hmcase],
		[checkbutton => 'Directories first', -variable => \$hmfolders],
		[checkbutton => 'Show hidden', -variable => \$hmhidden],
		['separator' => ''],
		['command' => 'configure Columns', -command => ['configureColumns', $self]],
	);
	
	###################################################################
	#setting up the list context menu
	my (@listmenu) = (
		['command' => 'Open', -command => sub {
			my ($s) = $lb->infoSelection;
			$self->Invoke($s) if defined $s;
		}],
	);


	###################################################################
	#setting up ConfigSpecs

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-bginterval => ['PASSIVE', undef, undef, 5],
		-casedependantsort => [{-sortcase => $lb}, undef, undef, 0],
		-columns => ['PASSIVE', undef, undef, \@columns],
		-compactimage => [{-image => $columns}, undef, undef, $self->Pixmap(-file => "$iconfolder/view_multicolumn.xpm")],
		-createfolderbutton => ['METHOD', undef, undef, 0],
		-dateformat => ['PASSIVE', undef, undef, "%Y-%m-%d %H:%M"],
		-detailsimage => [{-image => $details}, undef, undef, $self->Pixmap(-file => "$iconfolder/view_detailed.xpm")],
		-directoriesfirst => ['PASSIVE', undef, undef, 1],
		-diriconcall => ['CALLBACK', undef, undef, ['DefaultDirIcon', $self]],
		-fileiconcall => ['CALLBACK', undef, undef, ['DefaultFileIcon', $self]],
		-headermenu => ['PASSIVE', undef, undef, \@headermenu],
		-iconviewimage => [{-image => $rows}, undef, undef, $self->Pixmap(-file => "$iconfolder/view_icon.xpm")],
		-invokefile => ['CALLBACK', undef, undef, ['openFile', $self]],
		-linkcolor => ['PASSIVE', undef, undef, '#1098D7'],
		-linkiconcall => ['CALLBACK', undef, undef, ['DefaultLinkIcon', $self]],
		-listmenu => ['PASSIVE', undef, undef, \@listmenu],
		-loadfilter => ['PASSIVE', undef, undef, ''],
		-loadfilterfolders => ['PASSIVE', undef, undef, 0],
		-msgimage => ['PASSIVE', undef, undef, $self->Getimage('info')],
		-newfolderimage => [{-image => $createfolderbutton}, undef, undef, $self->Pixmap(-file => "$iconfolder/folder_new.xpm")],
		-postloadcall => ['CALLBACK', undef, undef, sub {}],
		-reloadimage => [{-image => $reload}, undef, undef, $self->Pixmap(-file => "$iconfolder/reload.xpm")],
		-showfiles => ['PASSIVE', undef, undef, 1],
		-showfolders => ['PASSIVE', undef, undef, 1],
		-showhidden => ['PASSIVE', undef, undef, 0],
		-viewmode => ['METHOD', undef, undef, 'detailed'],
		-warnimage => ['PASSIVE', undef, undef, $self->Getimage('warning')],
		DEFAULT => [ $lb ],
	);
	$self->Delegates(
		collect => $self,
		folder => $self,
		GetFullName => $self,
		load => $self,
		reload => $self,
		DEFAULT => $lb,
	);
	$self->{'construct'} = 1;
	$self->after(1, sub { delete $self->{'construct'} });
}

sub Add {
	my ($self, $data) = @_;

	my $item = $data->name;
	my $full = $data->fullname;
	$data->configure(-itemtype => 'imagetext');

	my $lb = $self->Subwidget('LB');

	my $index = $self->Position($data);
	$self->insert($data, $index);
	my $columns = $self->cget('-columns');
	for (@$columns) {
		my $col_name = $_;
		my $textcall = $self->{COLTYPES}->{$col_name}->{'display'};
		my $datacall = $self->{COLTYPES}->{$col_name}->{'data'};
		$self->itemCreate($data->name, $col_name,
			-data => &$datacall($data),
			-text => &$textcall($data),
		);
	}
}

sub bgAddJob {
	my ($self, $data) = @_;
	my $stack = $self->{JOBSTACK};
	push @$stack, [$data]
}

sub bgCurJob {
	my $self = shift;
	my $stack = $self->{JOBSTACK};
	return unless @$stack;
	my $job = $stack->[0];
	my ($data, $handle) = @$job;
	unless (defined $handle) {
		my $fn = $data->fullname;
		$handle = $self->GetDirHandle($data->fullname);
		if (defined $handle) {
			push @$job, $handle
		} else { #directory cannot be opened
			shift @$stack;
			return $self->bgCurJob;
		}
	}
	return $data, $handle;
}

sub bgCycle {
	my $self = shift;
	my $stack = $self->{JOBSTACK};
	my ($data, $handle) = $self->bgCurJob;
	unless (defined $data) {
		$self->bgStop;
		return;
	}
	my $sep = $self->cget('-separator');
	for (1 .. 1) {
		my $item = readdir($handle);
		if (defined $item) {
			next if $item eq '.';
			next if $item eq '..';
			next if (($item =~ /^\..+/) and (not $self->cget('-showhidden')));

			my $dname = $data->name;
			my $folder = $data->fullname;
			my $fullname;
			my $root = $self->GetRootFolder;
			if ($folder eq $root) {
				$fullname = "$root$item";
			} else {
				$fullname = "$folder$sep$item";
			}
			next if ((-d $fullname) and (not $self->cget('-showfolders')));
			next if ((-f $fullname) and (not $self->cget('-showfiles')));

			if (-d $fullname) {
				if ($self->cget('-loadfilterfolders')) {
					next unless $self->filter($self->cget('-loadfilter'), $item);
				}
			} else {
				next unless $self->filter($self->cget('-loadfilter'), $item);
			}
			my $name = $item;
			my $priority = 0;
			$priority = 1 if (-d $fullname) and $self->cget('-directoriesfirst');
			$name = "$dname$sep$item" if $dname ne '';
			my @op;
			my $cdat = new Tk::FileBrowser::Item(@op,
				-listbrowser => $self->Subwidget('LB'),
				-fullname => $fullname,
				-name => $name,
				-priority => $priority,
				-text => $item,
			);
			$data->child($name, $cdat);
			if ($dname eq '') {
				$self->Add($cdat);
				$self->bgAddJob($cdat) if $cdat->isDir;
			}
		} else {
			closedir $handle;
			$data->loaded(1);

			my $name = $data->name;
			my $size = $data->size;
			if ((defined $size) and ($name ne '')) {
				my $text = $self->sizeString($data);
				$self->itemConfigure($name, 'Size', -data => $size, -text => $text);
				$self->refreshSingle($name) if $data->ismapped;
			}
			if (($name ne '') and ($self->cget('-sorton') eq 'Size')) {
				$self->delete($name);
				$self->Add($data);
				my @c = $data->children;
				$self->refreshPurge($self->index($name));
			}
			unless (($name eq '') or ($data->{'open'})) {
				$self->close($name);
			}
			
			my $parent;
			$parent = $self->infoParent($name) if $name ne '';
			if (defined $parent) {
				my $pdat = $self->get($parent);
				if ($pdat->opened) {
					$self->open($parent);
				}
			}

			while ((@$stack) and $data->loaded) {
				shift @$stack;
				($data, $handle) = $self->bgCurJob;
			}

			unless (defined $data) {
				$self->bgStop;
				last;
			}
		}
	}
	$self->bgStart if exists $self->{'bg_id'};
}

sub bgReset {
	my $self = shift;
	my $stack = $self->{JOBSTACK};
	if (@$stack) {
		my $first = $stack->[0];
		closedir $first->[1] if defined $first->[1];
		while (@$stack) { shift @$stack }
	}
	$self->bgStop
}

sub bgStart {
	my $self = shift;
	my $interval = $self->cget('-bginterval');
	my $id = $self->after($interval, ['bgCycle', $self]);
	$self->{'bg_id'} = $id;
}

sub bgStartConditional {
	my $self = shift;
	return if exists $self->{'bg_id'};
	$self->bgStart
}

sub bgStop {
	my $self = shift;
	my $id = $self->{'bg_id'};
	$self->afterCancel($id) if defined $id;
	delete $self->{'bg_id'};
}

sub branchClose {
	my ($self, $entry) = @_;
	$self->close($entry);
	$self->get($entry)->opened(0);
}

sub branchOpen {
	my ($self, $entry) = @_;
	my $data = $self->get($entry);
	my $sep = $self->cget('-separator');
	my @children = $self->infoChildren($entry);
	if (@children eq 0) {
		my @children = $data->children;
		for (@children) {
			my $child = $_;
			my $childobj = $data->child($_);
			$self->Add($childobj);
			if ($childobj->isDir) {
				$self->bgAddJob($childobj);
				$self->bgStartConditional;
			}
		}
	}
	$data->opened(1);
}

=item B<collect>

Returns a list of all selected files and folders.

=cut

sub collect {
	my $self = shift;
	my @sel = $self->infoSelection;
	my @ret = ();
	for (@sel) { push @ret, $self->GetFullName($_) }
	return @ret
}

sub configureColumns {
	my $self = shift;
	my $t = $self->{COLTYPES};
	my @types = sort keys %$t;
	my $changed = 0;
	my $d = $self->YADialog(
		-title => 'Columns',
	);
	my $f = $d->LabFrame(
		-label => 'Show column',
		-labelside => 'acrosstop',
	)->pack(-expand => 1, -fill => 'both');
	for (@types) {
		my $type = $_;
		next if $type eq 'Name';
		my $state;
		my $b = $f->Checkbutton(
			-command => sub {
				$self->clear;
				if ($state) {
					return if $self->columnExists($type);
					$changed = 1;
					my $opt = $t->{$type}->{'options'};
					my $col = $self->columnCreate($type, @$opt);
					$col->forceWidth($t->{$type}->{'width'});
					$self->headerCreate($type,
						-text => => $type,
						-contextcall => ['hmPost', $self],
						-sortable => 1,
					);
					my $textcall = $self->{COLTYPES}->{$type}->{'display'};
					my $datacall = $self->{COLTYPES}->{$type}->{'data'};
					my @pool = $self->getAll;
					for (@pool) {
						$self->itemCreate($_->name, $type,
							-data => &$datacall($_),
							-text => &$textcall($_),
						);
					}
				} else {
					return unless $self->columnExists($type);
					$changed = 1;
					my $col = $self->columnGet($type);
					$self->headerRemove($type);
					$self->columnRemove($type);
				}
				$self->headerPlace;
				$self->configure(-columns => [$self->columnList]);
				$self->refreshPurge;
			},
			-text => $_,
			-variable => \$state,
		)->pack(-anchor => 'w', -padx => 20, -pady => 2);
		$b->select if $self->columnExists($_);
	}
	$d->show(-popover => $self);
	$d->destroy;
#	$self->reload if $changed;
}

sub createFolder {
	my $self = shift;
	my @padding = (-padx => 10, -pady => 10);
	my $q = $self->YADialog(
		-title => 'New folder',
		-buttons => [qw(Ok Cancel)],
	);
	$q->Label(-image => $self->cget('-msgimage'))->pack(-side => 'left', @padding);
	my $f = $q->Frame->pack(-side => 'left', @padding);
	$f->Label(
		-anchor => 'w',
		-text => 'Folder name:',
	)->pack(-fill => 'x', -padx => 2, -pady => 2);
	my $e = $f->Entry->pack(-fill => 'x', -padx => 2, -pady => 2);
	$e->focus;
	$e->bind('<Return>', sub { 
		$q->Pressed('Ok');
	});
	my $result;
	my $answer = $q->Show(-popover => $self);
	$result = $e->get if $answer eq 'Ok';
	$q->destroy;
	if (defined $result) {
		my $folder = $self->GetFullName($result);
		if (mkdir $folder) {
			$self->reload
		} else {
			my $e = $self->YAMessage(
				-title => 'Error',
				-text => "Creating Folder '$result' failed.",
				-image => $self->cget('-warnimage'),
			);
			$e->show(-popover => $self->toplevel);
			$e->destroy;
		}
	}
}

sub createfolderbutton {
	my $self = shift;
	my $b = $self->Subwidget('CreateDirButton');
	if (@_) {
		my $pack = shift;
		if ($pack) {
			$b->pack(-side => 'left', -padx => 2, -pady => 2) #unless $b->ismapped
		} else {
			$b->packForget #if $b->ismapped
		}
	}
	return $b->ismapped
}

sub DefaultIcon {
	my ($self, $file) = @_;
	return $self->Photo(
		-file => "$iconfolder/$file.png",
		-format => 'png',
	)
}

sub DefaultDirIcon {
	my ($self, $file, $mode) = @_;
	$mode = 'detailed' unless defined $mode;
	my $f = "folder-$mode" . 'view';
	return $self->DefaultIcon($f)
}

sub DefaultFileIcon {
	my ($self, $file, $mode) = @_;
	$mode = 'detailed' unless defined $mode;
	my $f = "file-$mode" . 'view';
	return $self->DefaultIcon($f)
}

sub DefaultLinkIcon {
	my ($self, $file, $mode) = @_;
	$mode = 'detailed' unless defined $mode;
	my $f = "link-$mode" . 'view';
	return $self->DefaultIcon($f)
}

sub EditSelect {
	my $self = shift;
	my $e = $self->Subwidget('Entry');
	$e->Subwidget('List')->popDown;
	my $folder = $e->get;
	my $home = $ENV{HOME};
	$folder =~ s/^~/$home/;
	$self->load($folder) if (-e $folder) and (-d $folder);
}

=item B<folder>

Returns the name of the folder loaded. Returns undef if
nothing is loaded.

=cut

sub folder {
	return $_[0]->{BASE}
}

sub GetDirHandle {
	my ($self, $path) = @_;
	my $dh;
	unless (opendir($dh, $path)) {
		croak "cannot open folder $path";
		return
	}
	return $dh
}

sub GetFullName {
	my ($self, $item) = @_;
	if (ref $item eq 'Tk::FileBrowser::Item') {
		return $item->fullname;
	} else {
		my $base = $self->{BASE};
		return $base if $item eq '';
		my $sep =  $self->cget('-separator');
		return $sep . $item if $base eq $sep;
		return $self->{BASE} . $sep . $item
	}
}

sub GetParent {
	my ($self, $name) = @_;
	my $dir = dirname($name);
	if ($dir eq '.') {
		$dir = '' ;
	}
	return $dir
}

sub GetRootFolder {
	my $self = shift;
	my $root = '/';
	$root = substr($self->{BASE}, 0, 3) if $mswin;
	return $root
}

sub GetPeers {
	my ($self, $item) = @_;
	my $name = $item->fullname;
	return $self->infoRoot if $name eq $self->{BASE};
	return $self->infoChildren($self->GetParent($item->name));
}

sub hmPost {
	my $self = shift;
	$self->noRefresh(1);
	my $hmcase = $self->Subwidget('HMCase');
	$$hmcase = $self->cget('-casedependantsort');
	my $hmfolders = $self->Subwidget('HMFolders');
	$$hmfolders = $self->cget('-directoriesfirst');
	my $hmhidden = $self->Subwidget('HMHidden');
	$$hmhidden = $self->cget('-showhidden');
	$self->noRefresh(0);
	my ($x, $y) = $self->pointerxy;
	my $items = $self->cget('-headermenu');
	if (@$items) {
		my $menu = $self->Menu(
			-menuitems => $items,
			-tearoff => 0,
		);
		$menu->bind('<Leave>', [$self, 'hmUnpost']);
		$self->{'h_menu'} = $menu;
		$menu->post($x - 4, $y - 4);
	}
}

sub hmUnpost {
	my $self = shift;
	my $menu = $self->{'h_menu'};
	if (defined $menu) {
		delete $self->{'h_menu'};
		$menu->unpost;
		$menu->destroy;
	}
}

sub IndicatorPressed {
	my ($self, $entry, $action) = @_;
	if ($action eq 'open') {
		$self->branchOpen($entry)
	} else {
		$self->branchClose($entry)
	}
}

sub Invoke {
	my ($self, $entry) = @_;
	my $data = $self->get($entry);
	my $name = $data->fullname;
	if ($data->isDir) {
		$self->load($name)
	} else {
		$self->Callback('-invokefile', $name)
	}
}

sub LeftRight {
	my ($self, $dir, $entry) = @_;
	if ($dir eq 'left') { 
		$self->branchClose($entry);
	} else {
		$self->branchOpen($entry);
	}
}

sub lmPost {
	my $self = shift;
	my ($x, $y) = $self->pointerxy;
	my $items = $self->cget('-listmenu');
	if (@$items) {
		my $menu = $self->Menu(
			-menuitems => $items,
			-tearoff => 0,
		);
		$menu->bind('<Leave>', [$self, 'lmUnpost']);
		$self->{'l_menu'} = $menu;
		$menu->post($x - 4, $y - 4);
	}
}

sub lmUnpost {
	my $self = shift;
	my $menu = $self->{'l_menu'};
	if (defined $menu) {
		delete $self->{'l_menu'};
		$menu->unpost;
		$menu->destroy;
	}
}

=item B<load>I<($folder)>

loads $folder into memory and refreshes the display
if succesfull.

=cut

sub load {
	my ($self, $folder, $focus) = @_;

	###################################################################
	#validate options
	$focus = 1 unless defined $focus;
	$folder = getcwd unless defined $folder;
	return if $folder eq '';
	my $home = $ENV{HOME};
	$folder =~ s/^~/$home/;
	unless (-e $folder) {
		warn "'$folder' does not exist";
		return
	}
	unless (-d $folder) {
		warn "'$folder' is not a directory";
		return
	}
	$folder = File::Spec->rel2abs($folder);

	###################################################################
	#configure the list entry
	my $e = $self->Subwidget('Entry');
	$e->delete(0, 'end');
	$e->insert('end', $folder);

	my @folders = ();
	my $pfolder = $folder;
	$self->{BASE} = $folder;
	my $root = $self->GetRootFolder;
	while ($pfolder ne $root) {
		$pfolder = dirname($pfolder);
		my $item = $pfolder;
		push @folders, $item;
	}
	my $entry = $self->Subwidget('Entry');
	$entry->configure(-values => \@folders);

	###################################################################
	my $listbrowser = $self->Subwidget('LB');
	#start loading
	my $data = new Tk::FileBrowser::Item(
		-fullname => $folder,
		-listbrowser => $listbrowser,
		-name => ''
	);
	$self->bgReset;
	$self->deleteAll;
	$listbrowser->refreshPos(0);
	$self->bgAddJob($data);
	$self->bgStart;

	###################################################################
	#transfer focus to ListBrowser widget
	$listbrowser->CanvasFocus if $focus;
	$self->Callback('-postloadcall');
}

sub noRefresh {
	my ($self, $flag) = @_;
	$self->{NOREFRESH} = $flag if defined $flag;
	return $self->{NOREFRESH};
}

=item B<openFile>I<($file)>

Opens I<$file> in the default application of your desktop.

=cut

sub openFile {
	my ($self, $url) = @_;
	if ($mswin) {
		system("\"$url\"");
	} else {
		system("xdg-open \"$url\"");
	}
}

sub OrderTest {
	my ($self, $item, $peer) = @_;
	my $key = $self->cget('-sorton');
	$key = 'Name' if $key eq '';
	my $call = $self->{COLTYPES}->{$key}->{'test'};
	return &$call($item, $peer);
}

sub Position {
	my ($self, $item) = @_;
	my $name = $item->name;
	my $parent = $self->decodeParent($name);

	#collect peers
	my @list;
	if (defined $parent) {
		@list = $self->getChildren($parent)
	} else {
		@list = $self->getRoot;
	}
	unless (@list) {
		return 0 unless defined $parent;
		return $self->index($parent) + 1
	}

	my $pos;

	#define search section
	my $first = 0;
	my $last = @list;
	($first, $last) = $self->prioritySection($item->priority, \@list) if ($self->cget('-directoriesfirst'));
	$pos = $first if $first eq $last;

	#search peers
	while (not defined $pos) {
		my $middle = int(($last - $first)/2) + $first;
		my $mid = $list[$middle];
		if ($self->OrderTest($item, $mid)) { #middle is before or on the required position
			$last = $middle
		} else { #middle is past the required position
			$first = $middle
		}
		if ($last - $first <= 1) {
			if ($self->OrderTest($item, $list[$first])) {
				$pos = $first;
			} else { 
				$pos = $last;
			}
			last;
		}
	}
	$pos = $pos + $self->index($parent) + 1 if defined $parent;
	return $pos;
}

sub prioritySection {
	my ($self, $priority, $list) = @_;

	return (0, 0) unless @$list;

	my $size = @$list;
	my $lp = $list->[$size - 1]->priority;
	return ($size, $size) if $lp > $priority; #section not there but starts at the end

	my $p = $list->[0]->priority;
	return (0, 0) if $p < $priority; # section not there but starts at the beginning

	my $start;
	$start = 0 if $p eq $priority;
	

	unless (defined $start) {
		my $first = 0;
		my $last = @$list - 1;
		while (not defined $start) {
			if ($last - $first <= 1) {
				$start = $last if $list->[$last]->priority == $priority;
				$start = $first if $list->[$first]->priority == $priority;
				last;
			}
			my $middle = int(($last - $first)/2) + $first;
			#$middle is inside or past requested section
			if ($list->[$middle]->priority <= $priority) {
				$last = $middle
			#$middle is before requested section
			} elsif  ($list->[$middle]->priority > $priority) {
				$first = $middle
			}
		}
	}

	my $last = $size - 1;
#	return ($start, $last);
	return ($start, $size) if $priority eq 0;
	return ($start, $size) if $priority eq $list->[$last]->priority;
	
	my $first = $start;

	my $end;
	while (not defined $end) {
		if ($last - $first <= 1) {
			$end = $first if $list->[$first]->priority == $priority;
			$end = $last if $list->[$last]->priority == $priority;
			last;
		}
		my $middle = int(($last - $first)/2) + $first;
		#middle is past requested section
		if ($list->[$middle]->priority < $priority) {
			$last = $middle
		#middle is inside requested section
		} elsif ($list->[$middle]->priority == $priority) {
			$first = $middle
		}
	}
	$end ++;

	return ($start, $end);
}

sub propertiesCollect {
	my ($self, $folder) = @_;
	my $totaldirs = 0;
	my $totalfiles = 0;
	my $totallinks = 0;
	my $totalsize = 0;
	if (opendir(my $dh, $folder)) {
		while (my $entry = readdir($dh)) {
			next if $entry eq '.';
			next if $entry eq '..';
			my $full = $folder . $self->cget('-separator') . $entry;
			if (-d $full) {
				$totaldirs ++;
				my ($d, $f, $l, $size) = $self->propertiesCollect($full);
				$totaldirs = $totaldirs + $d;
				$totalfiles = $totalfiles + $f;
				$totallinks = $totallinks + $l;
				$totalsize = $totalsize + $size;
				$self->update;
			} elsif (-f $full) {
				$totalfiles ++;
				$totalsize = $totalsize + -s $full;
			} elsif (-l $full) {
				$totallinks ++;
#				$totalsize = $totalsize + -s $full;
			}
		}
	}
	return ($totaldirs, $totalfiles, $totallinks, $totalsize)
}

sub propertiesPop {
	my $self = shift;
	my @sel = $self->collect;
	return unless @sel;
	my @dirs = ();
	my @files = ();
	my @links = ();

	for (@sel) {
		push @dirs, $_ if -d $_;
		push @files, $_ if -f $_;
		push @links, $_ if -l $_;
	}
	my $ndirs = @dirs;
	my $nfiles = @files;
	my $nlinks = @links;

	my $totalsize = 0;
	my $totaldirs = $ndirs;
	my $totalfiles = $nfiles;
	my $totallinks = $nlinks;

	my $summary = 'Calculating';

	my ($diskdev, $dummy, $diskused, $diskfree, $diskpused, $diskmount);
	my $folder = $self->folder;
	if ($mswin) {
		my $drive = substr($folder, 0, 2);
		$diskdev = 'not supported';
		my $dfstring = `wmic logicaldisk get size, freespace, caption`;
		while ($dfstring =~ s/(^[^\n]+)\n//) {
			my ($tdrive, $free, $size) = split(' ', $1);
			next unless defined $tdrive;
			if (substr($tdrive, 0, 2) eq $drive) {
				my $used = $size - $free;
				$diskmount = $drive;
				$diskfree = $self->size2String($free);
				$diskused = $self->size2String($used);
				my $pused = int($used / $size) * 100;
				$diskpused = "$pused%";
			}
		}
	} else {
		my $dfstring = `df $folder`;
		$dfstring =~ s/^[^\n]+\n//; #remove first line from df result
		($diskdev, $dummy, $diskused, $diskfree, $diskpused, $diskmount) = split(' ', $dfstring);
		$diskused = $self->size2String($diskused*1024);
		$diskfree = $self->size2String($diskfree*1024);
	}

	my $srow = 0;
	my $labwidth = 36;
	my $namwidth = 12;

	for (@files, @links) {
		$totalsize = $totalsize + -s $_
	}
	my $stop = 0;

	#setup dialog box
	my $db = $self->YADialog(
		-title => 'Properties',
		-buttons => [],
	);
	my $button = $db->Subwidget('buttonframe')->Button(
		-command => sub {
			$stop = 1;
			$db->Pressed('Close');
		},
		-text => 'Close',
	);
	$db->ButtonPack($button);

	my $sf = $db->LabFrame(
		-label => 'Selected',
	)->pack(-expand => 1, -fill => 'both');
	for ([\$ndirs, 'Directories'], [\$nfiles, 'Files'], [\$nlinks, 'Links']) {
		my ($num, $lab) = @$_;
		if ($$num > 0) {
			$sf->Label(
				-width => $namwidth,
				-text => "$lab:",
				-anchor => 'e',
			)->grid(-row => $srow, -column => 0, -sticky => 'ew');
			$sf->Label(
				-width => $labwidth,
				-textvariable => $num,
				-anchor => 'w',
			)->grid(-row => $srow, -column => 1, -sticky => 'ew');
			$srow++
		};
	}

	my $df = $db->LabFrame(
		-label => 'Details',
	)->pack(-expand => 1, -fill => 'both');
	$srow = 0;
	for (
		[\$summary, 'Summary'],
		[\$totalsize, 'Total Size'],
	) {
		my ($num, $lab) = @$_;
		$df->Label(
			-width => $namwidth,
			-text => "$lab:",
			-anchor => 'e',
		)->grid(-row => $srow, -column => 0, -sticky => 'ew');
		$df->Label(
			-width => $labwidth,
			-textvariable => $num,
			-anchor => 'w',
		)->grid(-row => $srow, -column => 1, -sticky => 'ew');
		$srow++
	}

	my $dvf = $db->LabFrame(
		-label => 'Disk',
	)->pack(-expand => 1, -fill => 'both');
	$srow = 0;
	for (
		[\$diskfree, 'Free space'],
		[\$diskused, 'Used space'],
		[\$diskpused, 'Percentage'],
		[\$diskmount, 'Mount'],
		[\$diskdev, 'Device'],
	) {
		my ($num, $lab) = @$_;
		$dvf->Label(
			-width => $namwidth,
			-text => "$lab:",
			-anchor => 'e',
		)->grid(-row => $srow, -column => 0, -sticky => 'ew');
		$dvf->Label(
			-width => $labwidth,
			-textvariable => $num,
			-anchor => 'w',
		)->grid(-row => $srow, -column => 1, -sticky => 'ew');
		$srow++
	}



	$self->after(200, sub {
		for (@dirs){
			my ($d, $f, $l, $size) = $self->propertiesCollect($_);
			return if $stop;
			$totaldirs = $totaldirs + $d;
			$totalfiles = $totalfiles + $f;
			$totallinks = $totallinks + $l;
			$totalsize = $totalsize + $size;
			$summary = "Folders: $totaldirs, Files: $totalfiles, Links: $totallinks";
			$db->update;
		}
		$totalsize = $self->size2String($totalsize);
	});

	#pop dialog here
	$button->focus;
	$db->show(-popover=> $self);
	$db->destroy;
	
}

=item B<reload>

Reloads the current folder, if one is loaded.

=cut

sub reload {
	my $self = shift;
	my $folder = $self->folder;
	$self->load($folder) if defined $folder;
}

sub separator {
	my $self = shift;
	warn "ingoring attempt to configure separator" if @_;
	return $self->{SEPARATOR}
}

=back

=head1 COLUMN DEFINITIONS

The B<-columntypes> options allows you to define your own column types. The structure is like this:

 my $fb = $app->FileBrowser(
    -columns => [qw[Size Modified MyColumn]],
    -columntypes => [
       MyColumn => {
          display => sub { ... },
          test => sub { ... },
       },
    ],
 );

I<MyColumn> is followed by a reference to a hash with the keys I<display> and I<test>.
Both keys hold a reference to an anonymous sub.

The I<display> sub receives one argument, a B<Tk::FirleBrowser::Item> object. It should
return the string to be displayed in the column.

The I<test> sub receives two arguments, Both a B<Tk::FirleBrowser::Item> object. It should
test both objects against each other, taking B<-sortorder> into account. It should return
the boolean result of the test.

The methods below can help you writing your own column definitions. Whenever you see I<$data> here, 
it refers to a B<Tk::FirleBrowser::Item> object.

=over 4

=item B<dateString>I<($type, $data)>

Returns the formatted date string of one of the date items in I<$data>;
I<$type> can be 'Accessed', 'Created' or 'Modified'.

=cut

sub dateString {
	my ($self, $key, $data) = @_;
	$key = lc $key;
	my $raw = $data->$key;
	return '' unless defined $raw;
	return strftime($self->cget('-dateformat'), localtime($raw))
}

=item B<linkString>I<($data)>

Returns the formatted size string to be displayed for I<$data>.

=cut

sub linkString {
	my ($self, $data) = @_;
	my $name = $data->fullname;
	return '' unless -l $name;
	return File::Spec::Link->resolve($name);
}

=item B<nameString>I<($data)>

Returns the name to be displayed for I<$data>.

=cut

sub nameString {
	my ($self, $data) = @_;
	return basename($data->name);
}

sub size2String {
	my ($self, $size) = @_;
	my @magnifiers = ('', 'K', 'M', 'G', 'T', 'P');
	my $count = 0;
	while ($size >= 1024) {
		$size = $size / 1024;
		$count ++;
	}
	my $mag = $magnifiers[$count];
	if ($count eq 0) {
		$size = int($size);
	} elsif ($size < 10) {
		$size = sprintf("%.2f", $size)
	} elsif ($size < 100) {
		$size = sprintf("%.1f", $size)
	} else {
		$size = int($size);
	}
	$size = $size . " $mag" . 'B';
	return $size
}

=item B<sizeString>I<($data)>

Returns the formatted size string to be displayed for I<$data>.

=cut

sub sizeString {
	my ($self, $data) = @_;
	my $size = $data->size;
	return '' unless defined $size;
	if ($data->isDir) {
		$size = "$size items" if $size ne 1;
		$size = "$size item" if $size eq 1;
	} else {
		$size = $self->size2String($size);
	}
	return $size
}


=item B<testDate>I<($type, $data1, $data2)>

I<$type> can be 'Accessed', 'Created' or 'Modified'.

Compares the date stamps in $data1 and $data2 and returns true if $data1 wins.

=cut

sub testDate {
	my ($self, $key, $data1, $data2) = @_;
	$key = lc($key);
	my $sort = $self->cget('-sortorder');
	my $idat = $data1->$key;
	my $pdat = $data2->$key;
	return 1 unless defined $idat;
	return 1 unless defined $pdat;
	if ($sort eq 'ascending') {
		return $idat <= $pdat
	} else {
		return $idat >= $pdat
	}
}

=item B<testLink>I<($data1, $data2)>

Checks if both $data1 and $data2 represent symbolic links and returns true if $data1 target wins.

=cut

sub testLink {
	my ($self, $data1, $data2) = @_;
	my $sort = $self->cget('-sortorder');
	my $itarget = $self->linkString($data1);
	my $ptarget = $self->linkString($data2);
	if ($sort eq 'ascending') {
		return 1 if $itarget eq '';
		return 0 if $ptarget eq '';
		return $itarget le $ptarget
	} else {
		return 0 if $itarget eq '';
		return 1 if $ptarget eq '';
		return $itarget ge $ptarget
	}
}

=item B<testName>I<($data1, $data2)>

Compares the names of $data1 and $data2 and returns true if $data1 wins.

=cut

sub testName {
	my ($self, $data1, $data2) = @_;
	my $sort = $self->cget('-sortorder');
	my $name = basename($data1->name);
	my $peer = basename($data2->name);
	unless ($self->cget('-casedependantsort')) {
		$name = lc($name);
		$peer = lc($peer);
	}
	if ($sort eq 'ascending') {
		return $name lt $peer
	} else {
		return $name gt $peer
	}
}

=item B<testSize>I<($data1, $data2)>

Compares the sizes of $data1 and $data2 and returns true if $data1 wins.

=cut

sub testSize {
	my ($self, $data1, $data2) = @_;
	my $sort = $self->cget('-sortorder');
	my $isize = $data1->size;
	my $psize = $data2->size;
	return 1 unless defined $isize;
	return 1 unless defined $psize;
	if ($sort eq 'ascending') {
		return $isize <= $psize
	} else {
		return $isize >= $psize
	}
}

=item B<testType>I<($data1, $data2)>

Compares the mime types of $data1 and $data2 and returns true if $data1 wins.

=cut

sub testType {
	my ($self, $data1, $data2) = @_;
	my $sort = $self->cget('-sortorder');
	my $itype = $data1->type;
	my $ptype = $data2->type;
	return 1 unless defined $itype;
	return 1 unless defined $ptype;
	if ($sort eq 'ascending') {
		return $itype ge $ptype
	} else {
		return $itype le $ptype
	}
}

sub viewCurrent {
	my $self = shift;
	$self->{VIEWCUR} = shift if @_;
	return $self->{VIEWCUR}
}

sub viewmode {
	my $self = shift;
	if (@_) {
		my $mode = shift;

		my $cur = $self->viewCurrent;
		return if (defined $cur) and ($cur eq $mode);
		
		if (exists $self->{'construct'}) {
			$self->after(3, sub { $self->viewmode($mode) });
			return
		}
	
		$self->viewCurrent($mode);
		my $lb = $self->Subwidget('LB');
	
		#setting up a sample item to set up display mode
		unless (defined $sample) {
			$sample = new Tk::FileBrowser::Item(
				-name => 'FileBrowser',
				-fullname => Tk::findINC('Tk/FileBrowser'),
				-listbrowser => $lb,
				-text => 'Xi XiXi Xi XiXiX iXi XiXi XiXi XiXi XiXi XiX iXi XiXiX iXi XiXiXiXiX iXi XiXi XiXi XiXi XiXi XiX iXi XiXiX iXi XiXi',
			);
		}
	
		#switch view mode;
		my $opt = $viewoptions{$mode};
		unless (defined $opt) {
			croak "invalid view mode $mode";
			return
		}
	
		for ('icon', 'compact', 'detailed') {
			if ($mode eq $_) {
				$self->Subwidget($_)->configure(-relief => 'sunken')
			} else {
				$self->Subwidget($_)->configure(-relief => 'flat')
			}
		}
	
		$lb->clear;
		for (keys %$opt) {
			$lb->configure($_, $opt->{$_})
		}
		$lb->cellSize($sample);
		my $h = $lb->handler;
		my $sy = $lb->cget('-margintop');
		$sy = $sy + $lb->cget('-headerheight') if $mode eq 'detailed';
		$h->startXY($lb->cget('-marginleft'), $sy);
		$lb->refreshPurge;
	}
	return $self->viewCurrent
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

Loading and sorting large folders takes ages.

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::ListBrowser>

=back

=cut

1;













