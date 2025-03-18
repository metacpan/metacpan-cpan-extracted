package Tk::FileBrowser;

=head1 NAME

Tk::FileBrowser - Multi column file system explorer

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.10';

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
require Tk::FileBrowser::Header;
use Tk::FileBrowser::Images;
use Tk::FileBrowser::Item;
require Tk::ITree;
require Tk::LabFrame;
require Tk::ListEntry;
require Tk::YADialog;
#require Tk::YAMessage;

my $file_icon = Tk->findINC('file.xpm');
my $dir_icon = Tk->findINC('folder.xpm');
my $osname = $Config{'osname'};
my $placeholder = '_place_holder_';

my %timedata = (
	Accessed => 'atime',
	Created => 'ctime',
	Modified => 'mtime',
);



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

=item Switch B<-createfolderbutton>

Default value 0. If set a button is displayed on top right allowing the user to create a new folder.

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

=item Switch: B<-filtercase>

Default value 0. Specifies if filtering is case dependant.

The value of this filter will change when you use the filter bar.

If you change the value you have to call B<refresh> to see your changes.

=item Switch: B<-headermenu>

Specifies a list of menuitems for the context menu of the header. By default
it is set to a list with checkbuttons entries for -sortcase, -directoriesfirst and -showhidden.

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

=item Switch: B<-refreshfilter>

Filter applied during refresh. Default value ''.
The value of this filter will change when you use the filter bar.

If you change the value you have to call B<refresh> to see your changes.

=item Switch: B<-refreshfilterfolders>

Specifies if filters are applied to folders during refresh. Default value 0.

If you change the value you have to call B<refresh> to see your changes.

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

=item Switch: B<-warnimage>

Image displayed in warning dialogs. By default set to the 'warning' Pixmap of Tk.

=back

=head1 ADVERTISED SUBWIDGETS

=over 4

=item B<Entry>

Class Tk::ListEntry.

=item B<Tree>

Class Tk::ITree.

=item B<FilterFrame>

Class Tk::Frame.

=item B<FilterEntry>

Class Tk::Entry.

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
	my $sorton = delete $args->{'-sorton'};
	$sorton = 'Name' unless defined $sorton;
	my $sortorder = delete $args->{'-sortorder'};
	$sortorder = 'ascending' unless defined $sortorder;
	my $columntypes = delete $args->{'-columntypes'};

	$self->SUPER::Populate($args);
	
	###################################################################
	#define column types
	my %column_types = (
		Name => {
			display => sub { return $self->nameString(@_) },
			test => sub { return $self->testName(@_) },
		},
		Size => {
			display => sub { return $self->sizeString(@_) },
			test => sub { return $self->testSize(@_) },
		},
		Accessed => {
			display => sub { return $self->dateString('Accessed', @_) },
			test => sub { return $self->testDate('Accessed', @_) },
		},
		Created => {
			display => sub { return $self->dateString('Created', @_) },
			test => sub { return $self->testDate('Created', @_) },
		},
		Link => {
			display => sub { return $self->linkString(@_) },
			test => sub { return $self->testLink(@_) },
		},
		Modified => {
			display => sub { return $self->dateString('Modified', @_) },
			test => sub { return $self->testDate('Modified', @_) },
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
	$self->{BASETXT} = \$basetxt;
	$self->{COLNAMES} = {};
	$self->{COLNUMS} = {};
	$self->{COLTYPES} = \%column_types;
	$self->{JOBSTACK} = [];
	$self->{POOL} = {};
	$self->{NOREFRESH} = 0;
	$self->{SEPARATOR} = $sep;
	$self->{SORTON} = $sorton;
	$self->{SORTORDER} = $sortorder;

	my @padding = (-padx => 2, -pady => 2);
	my @pack = (-side => 'left', @padding);

	#setting up load bar
	my $lframe = $self->Frame->pack(-fill => 'x');

	my $entry = $lframe->ListEntry(
		-command => ['EditSelect', $self],
		-motionselect => 0,
		-textvariable => \$basetxt,
	)->pack(@pack, -expand => 1, -fill => 'x');
	$self->Advertise('Entry', $entry);

	my $reload = $lframe->Button(
		-text => 'Reload',
		-command => ['reload', $self],
	)->pack(@pack);
	
	my $createfolderbutton = $lframe->Button(
		-text => 'New folder',
		-command => ['createFolder', $self],
	);
	$self->Advertise('CreateDirButton', $createfolderbutton);


	###################################################################
	#setting up the tree widget

	unshift @columns, 'Name';
	my $col_names = {};
	my $col_nums = {};
	my $num_col = @columns;

	my $tree = $self->Scrolled('ITree', 
		-columns => $num_col,
		-command => ['Invoke', $self],
		-header => 1,
		-indicatorcmd => ['IndicatorPressed', $self],
		-leftrightcall => ['LeftRight', $self],
		-separator => $sep,
		-scrollbars => 'osoe',
	)->pack(@padding,
		-expand => 1, 
		-fill => 'both',
	);

	$self->Advertise('Tree' => $tree);
	$tree->bind('<Control-a>', [$self, 'selectAll']);
	$tree->bind('<Control-f>', [$self, 'filterFlip']);
	$tree->bind('<Control-p>', [$self, 'propertiesPop']);
	$tree->bind('<F5>', [$self, 'reload']);
	$tree->bind('<Button-3>' => [$self, 'lmPost', Ev('X'), Ev('Y')]);

	###################################################################
	#setting up tree headers
	my $column = 0;
	for (@columns) {
		my $n = $column;
		my $item = $_;
		my @so = ();
		my $sort = $self->sorton;
		@so = (-sortorder => $self->sortorder) if $item eq $sort;
		$col_names->{$item} = $n;
		$col_nums->{$n} = $item;
		my $header = $tree->Header(@so,
			-contextcall => ['hmPost', $self],
			-column => $column,
			-sortcall => ['SortMode', $self],
			-text => $_
		);
		$tree->headerCreate($column, -headerbackground => $self->cget(-background), -itemtype => 'window', -widget => $header);
		$column ++;
	}
	$self->{COLNAMES} = $col_names;
	$self->{COLNUMS} = $col_nums;
	
	###################################################################
	#setting up the filter
	my $fframe = $self->Frame;
	$self->Advertise('FilterFrame', $fframe);

	$fframe->Label(-text => 'Filter')->pack(@pack);

	my $filter = '';
	$self->Advertise('Filter', \$filter);
	new Tie::Watch(
		-variable => \$filter,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			$self->filterActivate;
		},
	);

	my $fentry = $fframe->Entry(
		-textvariable => \$filter,
	)->pack(@pack, -expand => 1, -fill => 'x');
	$self->Advertise('FilterEntry', $fentry);
	$fentry->bind('<Control-f>', [$self, 'filterFlip']);

	my $case = 0;
	$self->Advertise('Case', \$case);
	new Tie::Watch(
		-variable => \$case,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			unless ($self->noRefresh) {
				$self->configure('-filtercase', $value);
				$self->refresh ;
			}
		},
	);
	$fframe->Checkbutton(
		-onvalue => 1,
		-offvalue => 0,
		-variable => \$case,
		-text => 'Case',
	)->pack(@pack);

	my $folders = 0;
	$self->Advertise('Folders', \$folders);
	new Tie::Watch(
		-variable => \$folders,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			unless ($self->noRefresh) {
				$self->configure('-refreshfilterfolders', $value);
				$self->refresh ;
			}
		},
	);
	$fframe->Checkbutton(
		-onvalue => 1,
		-offvalue => 0,
		-text => 'Folders',
		-variable => \$folders,
	)->pack(@pack);
	
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
	);
	
	###################################################################
	#setting up the list context menu
	my (@listmenu) = (
		['command' => 'Open', -command => sub {
			my ($s) = $tree->infoSelection;
			$self->Invoke($s) if defined $s;
		}],
	);


	###################################################################
	#setting up ConfigSpecs

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-bginterval => ['PASSIVE', undef, undef, 10],
		-casedependantsort => ['PASSIVE', undef, undef, 0],
		-columns => ['PASSIVE', undef, undef, \@columns],
		-createfolderbutton => ['METHOD', undef, undef, 0],
		-dateformat => ['PASSIVE', undef, undef, "%Y-%m-%d %H:%M"],
		-directoriesfirst => ['PASSIVE', undef, undef, 1],
		-diriconcall => ['CALLBACK', undef, undef, ['DefaultDirIcon', $self]],
#		-errorimage => ['PASSIVE', undef, undef, $self->Getimage('error')],
		-fileiconcall => ['CALLBACK', undef, undef, ['DefaultFileIcon', $self]],
		-filtercase => ['PASSIVE', undef, undef, 0],
		-headermenu => ['PASSIVE', undef, undef, \@headermenu],
		-invokefile => ['CALLBACK', undef, undef, ['openFile', $self]],
		-linkiconcall => ['CALLBACK', undef, undef, ['DefaultLinkIcon', $self]],
		-listmenu => ['PASSIVE', undef, undef, \@listmenu],
		-loadfilter => ['PASSIVE', undef, undef, ''],
		-loadfilterfolders => ['PASSIVE', undef, undef, 0],
		-msgimage => ['PASSIVE', undef, undef, $self->Getimage('info')],
		-newfolderimage => [{-image => $createfolderbutton}, undef, undef, $self->Pixmap(-data => $newfolder_pixmap)],
		-postloadcall => ['CALLBACK', undef, undef, sub {}],
#		-questionimage => ['PASSIVE', undef, undef, $self->Getimage('question')],
		-refreshfilter => ['PASSIVE', undef, undef, ''],
		-refreshfilterfolders => ['PASSIVE', undef, undef, 0],
		-reloadimage => [{-image => $reload}, undef, undef, $self->Pixmap(-data => $reload_pixmap)],
		-separator => ['METHOD'],
		-showfiles => ['PASSIVE', undef, undef, 1],
		-showfolders => ['PASSIVE', undef, undef, 1],
		-showhidden => ['PASSIVE', undef, undef, 0],
		-sorton => ['METHOD', undef, undef, $sorton],
		-sortorder => ['METHOD', undef, undef, $sortorder],
		-warnimage => ['PASSIVE', undef, undef, $self->Getimage('warning')],
		DEFAULT => [ $tree ],
	);
	$self->Delegates(
		collect => $self,
		filterHide => $self,
		filterShow => $self,
		folder => $self,
		GetFullName => $self,
		load => $self,
		refresh => $self,
		reload => $self,
		selectAll => $self,
		DEFAULT => $tree,
	);
}

sub Add {
	my ($self, $path, $name, $data) = @_;

	my $item = $name;
	my $sep = $self->cget('-separator');
	$item = "$path$sep$name" unless $path eq '';
	my @op = (-itemtype => 'imagetext',);
	if ($data->isDir) {
		push @op, -image => $self->GetDirIcon($item);
	} elsif ($data->isLink) {
		push @op, -image => $self->GetLinkIcon($item);
	} else {
		push @op, -image => $self->GetFileIcon($item);
	}
	my @entrypos = $self->Position($item, $data);
	$self->add($item, -data => $data, @entrypos);
	my $c = $self->cget('-columns');
	my @columns = ('Name', @$c);
	for (@columns) {
		my $col_name = $_;
		my $col_num = $self->{COLNAMES}->{$col_name};
		if ($col_name eq 'Name') {
			$self->itemCreate($item, $col_num, @op,
				-text => $name,
			);
		} else {
			my $call = $self->{COLTYPES}->{$col_name}->{'display'};
			$self->itemCreate($item, $col_num,
				-text => &$call($data),
			);
			
		}
	}
	$self->autosetmode;
	return $item
}

sub bgAddJob {
	my ($self, $path, $data) = @_;
	my $stack = $self->{JOBSTACK};
	push @$stack, [$path, $data]
}

sub bgCurJob {
	my $self = shift;
	my $stack = $self->{JOBSTACK};
	return unless @$stack;
	my $job = $stack->[0];
	my ($path, $data, $handle) = @$job;
	unless (defined $handle) {
		$handle = $self->GetDirHandle($path);
		if (defined $handle) {
			push @$job, $handle
		} else { #directory cannot be opened
			shift @$stack;
			return $self->bgCurJob;
		}
	}
	return $path, $data, $handle;
}

sub bgCycle {
	my $self = shift;
	my $stack = $self->{JOBSTACK};
	my ($path, $data, $handle) = $self->bgCurJob;
	unless (defined $path) {
		$self->bgStop;
		return;
	}
	my $sep = $self->cget('-separator');
	my $fpath = $path; my $fdata = $data;
	for (1 .. 10) {
		my $item = readdir($handle);
		if (defined $item) {
			next if $item eq '.';
			next if $item eq '..';
			next if (($item =~ /^\..+/) and (not $self->cget('-showhidden')));

			my $folder = $self->GetFullName($path);
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
			my $fullpath = $item;
			$fullpath = "$path$sep$item" unless $path eq '';

			my $cdat = new Tk::FileBrowser::Item( $fullname );
			$data->child($item, $cdat);
			if ($path eq '') {
				$self->Add($path, $item, $cdat);
				$self->bgAddJob($fullpath, $cdat) if $cdat->isDir;
			}
		} else {
			closedir $handle;
			$data->loaded(1);

			my $col = $self->ColNum('Size');
			if ((defined $col) and ($path ne '')) {
				my $size = $data->size;
				if (defined $size) {
					my $text = $self->sizeString($data);
					$self->itemConfigure($path, $col, -text => $text);
					$self->PHAdd($path) unless $self->PHExists($path);
				}
			}
			my @pos = $self->Position($path, $data);
			if ((@pos) and ($path ne '') and ($self->{SORTON} eq 'Size')) {
				my $parent = $self->infoParent($path);
				$parent = '' unless defined $parent;
				$self->deleteEntry($path);
				$self->Add($parent, basename($path), $data);
				my @c = $data->children;
				$self->PHAdd($path) if @c;
			}
			unless (($path eq '') or ($data->{'open'})) {
				$self->close($path);
			}
			
			my $parent;
			$parent = $self->infoParent($path) if $path ne '';
			if (defined $parent) {
				my $pdat = $self->infoData($parent);
				if ($pdat->isOpen) {
					$self->open($parent);
				}
			}

			while ((@$stack) and $data->loaded) {
				shift @$stack;
				($path, $data, $handle) = $self->bgCurJob;
			}

			unless (defined $path) {
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
		closedir $first->[2] if defined $first->[2];
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
	$self->infoData($entry)->{'open'} = 0;
}

sub branchOpen {
	my ($self, $entry) = @_;
	my $data = $self->infoData($entry);
	$self->open($entry);
	my $sep = $self->cget('-separator');
	my @children = $self->infoChildren($entry);
	if ($self->PHExists($entry) and (@children eq 1)) {
		$self->PHDelete($entry);
		my $data = $self->infoData($entry);
		my @children = $data->children;
		for (sort @children) {
			my $child = basename($_);
			my $childobj = $data->child($_);
			$self->Add($entry, $child, $childobj);
			my $childpath = "$entry$sep$_";
			if ($childobj->isDir) {
				$self->bgAddJob($childpath, $childobj);
				$self->bgStartConditional;
			}
		}
	}
	$data->isOpen(1);
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

sub ColName {
	my ($self, $num) = @_;
	return $self->{COLNUMS}->{$num}
}

sub ColNum {
	my ($self, $name) = @_;
	return $self->{COLNAMES}->{$name}
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

sub DefaultDirIcon {
	return $_[0]->Pixmap(-file => $dir_icon)
}

sub DefaultFileIcon {
	return $_[0]->Pixmap(-file => $file_icon)
}

sub DefaultLinkIcon {
	return $_[0]->Pixmap(-data => $link_pixmap)
}

sub EditSelect {
	my $self = shift;
	my $e = $self->Subwidget('Entry');
	$e->Subwidget('List')->popDown;
	my $folder = $e->get;
	print "folder $folder\n";
	my $home = $ENV{HOME};
	$folder =~ s/^~/$home/;
	$self->load($folder) if (-e $folder) and (-d $folder);
}

sub filter {
	my ($self, $filter, $value) = @_;
	return 1 if $filter eq '';
	$filter = quotemeta($filter);
	return 1 if $value eq '';
	my $case = $self->cget('-filtercase');
	if ($case) {
		return $value =~ /$filter/;
	} else {
		return $value =~ /$filter/i;
	}
}

sub filterActivate {
	my $self = shift;
	my $filter_id = $self->{'filter_id'};
	if (defined $filter_id) {
		$self->afterCancel($filter_id);
	}
	$filter_id = $self->after(500, ['filterRefresh', $self]);
	$self->{'filter_id'} = $filter_id;
}

=item B<filterFlip>

Hides the filter bar if it is shown. Shows it if it is hidden.

=cut

sub filterFlip {
	my $self = shift;
	my $f = $self->Subwidget('FilterFrame');
	if ($f->ismapped) {
		$f->packForget;
		$self->Subwidget('FilterEntry')->delete(0, 'end');
		$self->Subwidget('Tree')->focus;
	} else {
		$self->noRefresh(1);
		my $case = $self->Subwidget('Case');
		$$case = $self->cget('-filtercase');
		my $folders = $self->Subwidget('Folders');
		$$folders = $self->cget('-refreshfilterfolders');
		$self->noRefresh(0);
		$self->Subwidget('FilterFrame')->pack(-fill => 'x');
		$self->Subwidget('FilterEntry')->focus;
	}
}

sub filterRefresh {
	my $self = shift;
	my $filter = $self->Subwidget('FilterEntry')->get;
	$self->configure('-refreshfilter', $filter);
	delete $self->{'filter_id'};
	$self->refresh;
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
	my $folder = $self->GetFullName($path);
	my $dh;
	unless (opendir($dh, $folder)) {
		warn "cannot open folder $folder";
		return
	}
	return $dh
}

sub GetDirIcon {
	my ($self, $name) = @_;
	return $self->Callback('-diriconcall', $self->GetFullName($name));
}

sub GetFileIcon {
	my ($self, $name) = @_;
	return $self->Callback('-fileiconcall', $self->GetFullName($name));
}

sub GetFullName {
	my ($self, $item) = @_;
	if (ref $item eq 'Tk::FileBrowser::Item') {
		return $item->name;
	} else {
		my $base = $self->{BASE};
		return $base if $item eq '';
		my $sep =  $self->cget('-separator');
		return $sep . $item if $base eq $sep;
		return $self->{BASE} . $self->cget('-separator') . $item
	}
}

sub GetLinkIcon {
	my ($self, $name) = @_;
	return $self->Callback('-linkiconcall', $self->GetFullName($name));
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
	my ($self, $name) = @_;
	return $self->infoChildren('') if $name eq $self->{BASE};
	return $self->infoChildren($self->GetParent($name));
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
		$menu->post($x, $y);
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
	if ($action eq '<Activate>') {
		my $mode = $self->getmode($entry);
		if ($mode eq 'open') {
			$self->branchOpen($entry)
		} else {
			$self->branchClose($entry)
		}
	}
}

sub Invoke {
	my ($self, $entry) = @_;
	my $data = $self->infoData($entry);
	my $name = $data->name;
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
		$menu->post($x - 2, $y - 2);
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
#	my $basetxt = $self->{BASETXT};
#	$$basetxt = $folder;
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
	#start loading
	my $data = new Tk::FileBrowser::Item( $folder );
	$self->bgReset;
	$self->deleteAll;
	$self->{POOL} = $data;
	$self->bgAddJob('', $data);
	$self->bgStart;

	###################################################################
	#transfer focus to tree widget
	$self->Subwidget('Tree')->focus if $focus;
	$self->Callback('-postloadcall');
}

sub noRefresh {
	my ($self, $flag) = @_;
	$self->{NOREFRESH} = $flag if defined $flag;
	return $self->{NOREFRESH};
}

sub NumberOfColumns {
	my $self = shift;
	my $names = $self->{COLNAMES};
	my @size = keys %$names;
	my $num = @size;
	return $num
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
	my $key = $self->{SORTON};
	my $call = $self->{COLTYPES}->{$key}->{'test'};
	return &$call($item, $peer);
}

sub PHAdd {
	my ($self, $item) = @_;
	my $sep = $self->cget('-separator');
	$self->add("$item$sep$placeholder");
	$self->autosetmode;
}

sub PHDelete {
	my ($self, $item) = @_;
	my $sep = $self->cget('-separator');
	my $ph = "$item$sep$placeholder";
	$self->deleteEntry($ph);
}

sub PHExists {
	my ($self, $item) = @_;
	my $sep = $self->cget('-separator');
	my $ph = "$item$sep$placeholder";
	return $self->infoExists($ph)
}

sub Position {
	my ($self, $item, $itemdata) = @_;
	my $name = basename($item);
	my @peers = $self->GetPeers($item);
	return () unless @peers;
	my $directoriesfirst = $self->cget('-directoriesfirst');
	my @op = ();
	if ($itemdata->isDir and $self->cget('-directoriesfirst')) {
		for (@peers) {
			my $peer = $_;
			my $pdat = $self->infoData($peer);
			if (not $pdat->isDir) { #we arrived at the end of the directory section
				push @op, -before => $peer;
				last;
			} elsif ($self->OrderTest($itemdata, $pdat)) {
				push @op, -before => $peer;
				last;
			}
		}
	} else {
		for (@peers) {
			my $peer = $_;
			my $pdat = $self->infoData($peer);
			if (($pdat->isDir) and $self->cget('-directoriesfirst')) {
			#we are still in directory section, ignoring
			} elsif ($self->OrderTest($itemdata, $pdat)) {
				push @op, -before => $peer;
				last;
			}
		}
	}
	return @op;
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
#		print "drive $drive\n";
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
#			print "$tdrive, $free, $size\n";
		}
	} else {
		my $dfstring = `df $folder`;
		$dfstring =~ s/^[^\n]+\n//; #remove first line from df result
		($diskdev, $dummy, $diskused, $diskfree, $diskpused, $diskmount) = split(' ', $dfstring);
		$diskused = $self->size2String($diskused);
		$diskfree = $self->size2String($diskfree);
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

=item B<refresh>

Deletes all entries in the list and rebuilds it.

=cut

sub refresh {
	my $self = shift;
	my $bg = exists $self->{'bg_id'};
	$self->bgStop if $bg;
	$self->deleteAll;
	$self->update;
	my $root = $self->{POOL};
	my @children = $root->children;
	for (sort @children) {
		$self->refreshRecursive('', $_, $root->child($_));
	}
	$self->bgStart if $bg;
}

sub refreshRecursive {
	my ($self, $path, $name, $data) = @_;
	if ($data->isDir) {
		if ($self->cget('-refreshfilterfolders')) {
			return unless $self->filter($self->cget('-refreshfilter'), $name);
		}
	} else {
		return unless $self->filter($self->cget('-refreshfilter'), $name);
	}
	my $item = $self->Add($path, $name, $data);
	my $idat = $self->infoData($item);
	if ($idat->isDir) {
		my $open = $data->isOpen;
		my @c = $data->children;
		if ($open) {
			for (@c) {
				$self->refreshRecursive($item, basename($_), $data->child($_));
			}
		} elsif (@c) {
			$self->PHAdd($item)
		}
		unless ($open) {
			$self->close($item)
		}
	}
	$self->update;
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

sub SortMode {
	my ($self, $column, $order) = @_;
	$self->{SORTON} = $column;
	$self->{SORTORDER} = $order;
	my $col = $self->NumberOfColumns - 1;
	for (0 .. $col) {
		my $num = $_;
		my $name = $self->ColName($_);
		my $widget = $self->headerCget($num, '-widget');
		if ($name eq $column) {
			$widget->configure('-sortorder', $order);
		} else {
			$widget->configure('-sortorder', 'none');
		}
	}
	my $base = $self->{BASE};
	$self->refresh;
}

sub sorton {
	my ($self, $item) = @_;
	$self->{SORTON} = $item if defined $item;
	return $self->{SORTON}
}

sub sortorder {
	my ($self, $item) = @_;
	$self->{SORTORDER} = $item if defined $item;
	return $self->{SORTORDER}
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
	my $name = $data->name;
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

sub selectAll {
	my $self = shift;
	my $tree = $self->Subwidget('Tree');
	$tree->selectionClear;
	my @children = $tree->infoChildren('');
#	my $first = shift @children;
#	my $last = pop @children;
	for (@children) {
		$tree->selectionSet($_);
	}
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
	my $sort = $self->sortorder;
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
	my $sort = $self->sortorder;
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
	my $sort = $self->sortorder;
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
	my $sort = $self->sortorder;
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

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=item Allow columns to be configured on the fly.

=back

=head1 BUGS AND CAVEATS

Loading and sorting large folders takes ages.

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::ITree>

=item L<Tk::Tree>

=back

=cut

1;













