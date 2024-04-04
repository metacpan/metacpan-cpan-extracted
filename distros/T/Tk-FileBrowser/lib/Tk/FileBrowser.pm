package Tk::FileBrowser;

=head1 NAME

Tk::FileBrowser - Multi column file system explorer

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = 0.02;

use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'FileBrowser';

use POSIX qw( strftime );
use Config;
use Cwd;
use File::Basename;
use Tk;
require Tk::ITree;
require Tk::FileBrowser::Header;
require Tk::ListEntry;

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

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-casedependantsort>

Default value 0;

If you change the value you have to call B<refresh> to see your changes.

=item Switch: B<-columns>

Specify a list of column names to display. Only available at create
time. Allowed values are 'Accessed', 'Created', 'Modified', 'Size' and any you
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
             my $s = $fb->getSize($data);
             return 'X' if $s > 2048;
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

=item Switch: B<-invokefile>

This callback is executed when a user double clicks a file.

=item Switch: B<-showhidden>

Default value 0;

If you change the value you have to call B<load> again to see your changes.

=item Switch: B<-sorton>

Can be any valid column name. Default value 'Name'.

If you change the value you have to call B<refresh> to see your changes.

=item Switch: B<-sortorder>

Can be 'ascending' or 'descending'. Default value 'ascending'.

If you change the value you have to call B<refresh> to see your changes.

=back

=head1 ADVERTISED SUBWIDGETS

=over 4

=item B<Entry>

Class Tk::ListEntry.

=item B<Tree>

Class Tk::ITree.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	my $columns = delete $args->{'-columns'};
	$columns = ['Size', 'Modified'] unless defined $columns;
	my $sorton = delete $args->{'-sorton'};
	$sorton = 'Name' unless defined $sorton;
	my $sortorder = delete $args->{'-sortorder'};
	$sortorder = 'ascending' unless defined $sortorder;
	my $columntypes = delete $args->{'-columntypes'};

	$self->SUPER::Populate($args);
	
	my %column_types = (
		Name => {
			display => sub { return $self->getNameString(@_) },
			test => sub { return $self->testName(@_) },
		},
		Size => {
			display => sub { return $self->getSizeString(@_) },
			test => sub { return $self->testSize(@_) },
		},
		Accessed => {
			display => sub { return $self->getDateString('atime', @_) },
			test => sub { return $self->testDate('atime', @_) },
		},
		Created => {
			display => sub { return $self->getDateString('ctime', @_) },
			test => sub { return $self->testDate('ctime', @_) },
		},
		Modified => {
			display => sub { return $self->getDateString('mtime', @_) },
			test => sub { return $self->testDate('mtime', @_) },
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
	my $statustxt = '';
	$self->{BASE} = undef;
	$self->{BASETXT} = \$basetxt;
	$self->{COLNAMES} = {};
	$self->{COLNUMS} = {};
	$self->{COLTYPES} = \%column_types;
	$self->{JOBSTACK} = [];
	$self->{POOL} = {};
	$self->{SORTON} = $sorton;
	$self->{SORTORDER} = $sortorder;
	$self->{STATUSTXT} = \$statustxt,

	my $entry = $self->ListEntry(
		-command => ['EditSelect', $self],
		-textvariable => \$basetxt,
	)->pack(-fill => 'x');
	$self->Advertise('Entry', $entry);

	my $tree = $self->CreateTreeWidget(@$columns);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-bginterval => ['PASSIVE', undef, undef, 10],
		-casedependantsort => ['PASSIVE', undef, undef, 0],
		-columns => ['PASSIVE', undef, undef, $columns],
		-dateformat => ['PASSIVE', undef, undef, "%Y-%m-%d %H:%M"],
		-directoriesfirst => ['PASSIVE', undef, undef, 1],
		-diriconcall => ['CALLBACK', undef, undef, ['DefaultDirIcon', $self]],
		-fileiconcall => ['CALLBACK', undef, undef, ['DefaultFileIcon', $self]],
		-invokefile => ['CALLBACK', undef, undef, sub {}],
		-showhidden => ['PASSIVE', undef, undef, 0],
		-sorton => ['METHOD', undef, undef, $sorton],
		-sortorder => ['METHOD', undef, undef, $sortorder],
		-showhidden => ['PASSIVE', undef, undef, 0],
		DEFAULT => [ $tree ],
	);
	$self->Delegates(
		DEFAULT => $tree
	);
	return $self;
}

sub Add {
	my ($self, $path, $name, $data) = @_;

	my $item = $name;
	my $sep = $self->cget('-separator');
	$item = "$path$sep$name" unless $path eq '';
	my @op = (-itemtype => 'imagetext',);
	if ($self->IsDir($item)) {
		push @op, -image => $self->GetDirIcon($item);
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
				$fullname = "$folder$sep$item";`																																	`																																																																																																																	
			}
			my $fullpath = $item;
			$fullpath = "$path$sep$item" unless $path eq '';

			my $cdat = $self->getStat($fullname);
			$data->{'children'}->{$item} = $cdat;
			if ($path eq '') {
				$self->Add($path, $item, $cdat);
				$self->bgAddJob($fullpath, $cdat) if $self->IsDir($fullpath);
			}
		} else {
			closedir $handle;
			$data->{'loaded'} = 1;

			my $col = $self->ColNum('Size');
			if ((defined $col) and ($path ne '')) {
				my $size = $self->getSize($data);
				my $text = $self->getSizeString($data);
				$self->itemConfigure($path, $col, -text => $text);
				$self->PHAdd($path) unless $self->PHExists($path) or ($size eq 0);
			}
			my @pos = $self->Position($path, $data);
			if ((@pos) and ($path ne '') and ($self->{SORTON} eq 'Size')) {
				my $parent = $self->infoParent($path);
				$parent = '' unless defined $parent;
				$self->deleteEntry($path);
				$self->Add($parent, basename($path), $data);
				my $c = $data->{'children'};
				$self->PHAdd($path) if %$c;
			}
			unless (($path eq '') or ($data->{'open'})) {
				$self->close($path);
			}
			
			my $parent;
			$parent = $self->infoParent($path) if $path ne '';
			if (defined $parent) {
				my $pdat = $self->infoData($parent);
				if ($pdat->{'open'}) {
					$self->open($parent);
				}
			}

			while ((@$stack) and $data->{'loaded'}) {
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
#	return if exists $self->{'bg_id'};
	my $data = $self->infoData($entry);
	unless ($data->{'open'}) {
		$self->open($entry);
		my $sep = $self->cget('-separator');
		my @children = $self->infoChildren($entry);
		if ($self->PHExists($entry) and (@children eq 1)) {
			$self->PHDelete($entry);
			my $data = $self->infoData($entry);
			my $children = $data->{'children'};
			for (sort keys %$children) {
				$self->Add($entry, $_, $children->{$_});
				my $child = "$entry$sep$_";
				my $data = $children->{$_};
				if (exists $data->{'children'}) {
					$self->bgAddJob($child, $data);
					$self->bgStartConditional;
				}
			}
		}
		$data->{'open'} = 1;
	} 
}

sub ColName {
	my ($self, $num) = @_;
	return $self->{COLNUMS}->{$num}
}

sub ColNum {
	my ($self, $name) = @_;
	return $self->{COLNAMES}->{$name}
}

sub CreateTreeWidget {
	my ($self, @columns) = @_;
	unshift @columns, 'Name';
	my $col_names = {};
	my $col_nums = {};
	my $num_col = @columns;
	my $sep = '/';
	$sep = '\\' if $osname eq 'MSWin32';

	my $tree = $self->Scrolled('ITree', 
		-columns => $num_col,
		-command => ['Invoke', $self],
		-header => 1,
		-indicatorcmd => ['IndicatorPressed', $self],
		-leftrightcall => ['LeftRight', $self],
		-separator => $sep,
		-scrollbars => 'osoe',
	)->pack(
		-after => $self->Subwidget('Entry'),
		-padx => 2, 
		-pady => 2,
		-expand => 1, 
		-fill => 'both',
	);

	$self->Advertise(Tree => $tree);
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
			-column => $column,
			-sortcall => ['SortMode', $self],
			-text => $_
		);
		$tree->headerCreate($column, -itemtype => 'window', -widget => $header);
		$column ++;
	}
	$self->{COLNAMES} = $col_names;
	$self->{COLNUMS} = $col_nums;
	return $tree
}

sub DefaultDirIcon {
	return $_[0]->Pixmap(-file => $dir_icon)
}

sub DefaultFileIcon {
	return $_[0]->Pixmap(-file => $file_icon)
}

sub EditSelect {
	my $self = shift;
	my $e = $self->Subwidget('Entry');
	my $folder = $e->get;
	$e->Subwidget('List')->popDown;
	$self->load($folder) if (-e $folder) and (-d $folder);
}

=item B<getDateString>I<($type, $data)>

Returns the formatted date string of one of the date items in I<$data>;
I<$type> can be 'atime', 'ctime' or 'mtime'

=cut

sub getDateString {
	my ($self, $key, $data) = @_;
	my $raw = $data->{$key};
	return '' unless defined $raw;
	return strftime($self->cget('-dateformat'), localtime($raw))
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
	return $self->Callback('-diriconcall', $name);
}

sub GetFileIcon {
	my ($self, $name) = @_;
	return $self->Callback('-fileiconcall', $name);
}

sub GetFullName {
	my ($self, $name) = @_;
	my $base = $self->{BASE};
	return $base if $name eq '';
	my $sep =  $self->cget('-separator');
	return $sep . $name if $base eq $sep;
	return $self->{BASE} . $self->cget('-separator') . $name
}

sub GetParent {
	my ($self, $name) = @_;
	my $dir = dirname($name);
	if ($dir eq '.') {
		$dir = '' ;
	}
	return $dir
}

=item B<getNameString>I<($data)>

Returns the name to be displayed for I<$data>.

=cut

sub getNameString {
	my ($self, $data) = @_;
	return basename($data->{'name'});
}

sub GetRootFolder {
	my $self = shift;
	my $root = '/';
	$root = substr($self->{BASE}, 0, 3) if $osname eq 'MSWin32';
	return $root
}

sub GetPeers {
	my ($self, $name) = @_;
	return $self->infoChildren('') if $name eq $self->{BASE};
	return $self->infoChildren($self->GetParent($name));
}

=item B<getSize>I<($data)>

Returns the size of the item represented in I<$data>.
If I<$data> contains a folder, it returns the number of items. If not if
returns the size in bytes.

=cut

sub getSize {
	my ($self, $data) = @_;
	my $size;
	if (exists $data->{'children'}) {
		my $c = $data->{'children'};
		$size = keys %$c;
	} else {
		$size = $data->{'size'};
	}
	return 0 unless defined $size;
	return $size
}

=item B<getSizeString>I<($data)>

Returns the formatted size string to be displayed for I<$data>.

=cut

sub getSizeString {
	my ($self, $data) = @_;
	my $size = $self->getSize($data);
	if (exists $data->{'children'}) {
		$size = "$size items" if $size ne 1;
		$size = "$size item" if $size eq 1;
	} else {
		my @magnifiers = ('', 'K', 'M', 'G', 'T', 'P');
		my $count = 0;
		while ($size >= 1024) {
			$size = $size / 1024;
			$count ++;
		}
		my $mag = $magnifiers[$count];
		if ($count eq 0) {
			$size = int($size);
		} elsif ($size < 100) {
			$size = sprintf("%.1f", $size)
		} else {
			$size = int($size);
		}
		$size = $size . " $mag" . 'B';
	}
	return $size
}

=item B<getStat>I<($item)>

Returns a reference to an info hash for $item. I<$item> if the full name of an existing file or folder. 
This data structure is used throughout this package. 
Whenever you seee I<$data> in this document it refers to one of these.
If looks like this:

 $stat = {
    name => $item,
    size => $some_size,
    atime => $some_time_stamp_1,
    ctime => $some_time_stamp_2,
    mtime => $some_time_stamp_3,
 
    #the ones below only if $item is folder.
    children => {}, #default
    loaded => 0, #default
    open => 0, #default
 }

=cut

sub getStat {
	my ($self, $item) = @_;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($item);
	my %itemdata = (
		name => $item,
		size => $size,
		atime => $atime,
		mtime => $mtime,
		ctime => $ctime,
	);
	if (-d $item) {
		$itemdata{'loaded'} = 0;
		$itemdata{'children'} = {};
		$itemdata{'open'} = 0;
	}
	return \%itemdata;
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
	my $full = $self->GetFullName($entry);
	if ($self->IsDir($entry)) {
		$self->load($full)
	} else {
		$self->Callback('-invokefile', $full)
	}
}

sub IsDir {
	my ($self, $entry) = @_;
	my $full = $self->GetFullName($entry);
	return -d $full
}

sub IsFile {
	my ($self, $entry) = @_;
	my $full = $self->GetFullName($entry);
	return not -d $full
}

sub IsLoaded {
	my ($self, $entry, $flag) = @_;
	my $data = $self->infoData($entry);
	if (defined $flag) {
		$data->{'loaded'} = $flag
	}
	return $data->{'loaded'}
}

sub LeftRight {
	my ($self, $dir, $entry) = @_;
	if ($dir eq 'left') { 
		$self->branchClose($entry);
	} else {
		$self->branchOpen($entry);
	}
}

=item B<load>I<($folder)>

loads $folder into memory and refreshes the display
if succesfull.

=cut

sub load {
	my ($self, $folder) = @_;
	$folder = getcwd unless defined $folder;
	unless (-e $folder) {
		warn "'$folder' does not exist";
		return
	}
	unless (-d $folder) {
		warn "'$folder' is not a directory";
		return
	}
	my $basetxt = $self->{BASETXT};
	$$basetxt = $folder;
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
	my $data = $self->getStat($folder);
	$self->bgStop;
	$self->deleteAll;
	$self->{POOL} = $data;
	$self->{JOBSTACK} = [];
	$self->bgAddJob('', $data);
	$self->bgStart;
}

sub NumberOfColumns {
	my $self = shift;
	my $names = $self->{COLNAMES};
	my @size = keys %$names;
	my $num = @size;
	return $num
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
	if ($self->IsDir($item) and $self->cget('-directoriesfirst')) {
		for (@peers) {
			my $peer = $_;
			my $pdat = $self->infoData($peer);
			if ($self->IsFile($peer)) { #we arrived at the end of the directory section
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
			if ($self->IsDir($peer)) { 
				#we are still in directory section, ignoring
			} elsif ($self->OrderTest($itemdata, $pdat)) {
				push @op, -before => $peer;
				last;
			}
		}
	}
	return @op;
}

sub PostConfig {
	my $self = shift;
	my $col = $self->cget('-columns');
	$self->CreateTreeWidget(@$col)
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
	my $root = $self->{POOL}->{'children'};
	for (sort keys %$root) {
		$self->refreshRecursive('', $_, $root->{$_});
		my $open = $root->{$_}->{'open'};
		$self->close($_) if (defined $open) and $open;
	}
	$self->bgStart if $bg;
}

sub refreshRecursive {
	my ($self, $path, $name, $data) = @_;
	my $item = $self->Add($path, $name, $data);
	if ($self->IsDir($item) and ($data->{'loaded'})) {
		my $open = $data->{'open'};
		my $c = $data->{'children'};
		if ($open) {
			for (sort keys %$c) {
				$self->refreshRecursive($item, $_, $c->{$_});
			}
		} elsif (%$c) {
			$self->PHAdd($item)
		}
		$self->close($item) unless $open;
	}
	$self->update;
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

=item B<testDate>I<($type, $data1, $data2)>

$type can be 'atime', 'ctime' or 'mtime'.

Compares the date stamps in $data1 and $data2 and returns true if $data1 wins.

=cut

sub testDate {
	my ($self, $key, $data1, $data2) = @_;
	my $sort = $self->sortorder;
	my $idat = $data1->{$key};
	my $pdat = $data2->{$key};
	return 1 unless defined $idat;
	return 1 unless defined $pdat;
	if ($sort eq 'ascending') { 
		return $idat <= $pdat
	} else {
		return $idat >= $pdat
	}
}

=item B<testName>I<($data1, $data2)>

Compares the names of $data1 and $data2 and returns true if $data1 wins.

=cut

sub testName {
	my ($self, $data1, $data2) = @_;
	my $sort = $self->sortorder;
	my $name = basename($data1->{'name'});
	my $peer = basename($data2->{'name'});
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
	my $isize = $self->getSize($data1);
	my $psize = $self->getSize($data2);
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

=item Recognize links.

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





