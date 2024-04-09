package Tk::FileBrowser::Item;

=head1 NAME

Tk::FileBrowser::Item - Item object for Tk::FileBrowser

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION = 0.03;

use Config;
my $mswin = $Config{'osname'} eq 'MSWIN32';

use File::Spec;

=head1 SYNOPSIS

 use Tk::FileBrowser::Item;
 my $item = new Tk::FileBrowsr::Item($file);

=head1 DESCRIPTION

Item object used in Tk::FileBrowser. You should never have to create one yourself.

=head1 METHODS

=over 4

=cut

sub new {
	my ($class, $item) = @_;
	die "You need to specify a file, folder or link name" unless defined $item;
	$item = File::Spec->rel2abs($item);
	my $self = {
		NAME => $item
	};
	if (-d $item) {
		$self->{LOADED} = 0;
		$self->{CHILDREN} = {};
		$self->{ISOPEN} = 0;
	}
	bless $self, $class;
	$self->loadStat($item);
	return $self
}

=item B<accessed>

Returns the accessed time stamp.

=cut

sub accessed {
	return $_[0]->{ACCESSED};
}

=item B<child>I<($name, $itemobject)>

Throws a warning if this object does not represent a directory.
Sets or returns the item object of I<$name>.

=cut

sub child {
	my ($self, $name, $obj) = @_;
	die "You must supply a name option" unless defined $name;
	if ($self->isDir) {
		$self->{CHILDREN}->{$name} = $obj if defined $obj;
		return $self->{CHILDREN}->{$name}
	}
	carp $self->name . " is not a directory"
}

=item B<children>

Returns a list of children if this object represents a folder.
Otherwise returns undef.

=cut

sub children {
	my $self = shift;
	if ($self->isDir) {
		my $c = $self->{CHILDREN};
		return keys %$c
	}
	carp $self->name . " is not a directory"
}

=item B<created>

Returns the created time stamp.

=cut

sub created {
	return $_[0]->{CREATED};
}

=item B<isDir>

Returns true if this object reprents a directory.

=cut

sub isDir {
	return -d $_[0]->name;
}

=item B<isFile>

Returns true if this object reprents a file.

=cut

sub isFile {
	return -f $_[0]->name;
}

=item B<isLink>

Returns true if this object reprents a symbolic link.

=cut

sub isLink {
	return -l $_[0]->name;
}

=item B<isOpen>I<($flag)>

Returns undef if this object does not represent a directory.
Sets or returns the open flag.

=cut

sub isOpen {
	my ($self, $flag) = @_;
	if ($self->isDir) {
		$self->{ISOPEN} = $flag if defined $flag;
		return $self->{ISOPEN}
	}
	carp $self->name . " is not a directory"
}

=item B<loaded>I<($flag)>

Returns undef if this object does not reprent a directory.
Sets or returns the loaded flag.

=cut

sub loaded {
	my ($self, $flag) = @_;
	if ($self->isDir) {
		$self->{LOADED} = $flag if defined $flag;
		return $self->{LOADED}
	}
	carp $self->name . " is not a directory"
}

=item B<loadStat>I<($item)>

Loads the details of I<$item>. I<$item> can be a file, folder or symlink.

=cut

sub loadStat {
	my ($self, $item) = @_;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
	if (-l $item) {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat($item);
	} else {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($item);
	}
	$self->{NAME} = $item;
	$self->{SIZE} = $size;
	$self->{ACCESSED} = $atime;
	$self->{MODIFIED} = $mtime;
	$self->{CREATED} = $ctime;
}

=item B<modified>

Returns the modified time stamp.

=cut

sub modified {
	return $_[0]->{MODIFIED};
}

=item B<name>

Returns the file nameof the disk item loaded.

=cut

sub name {
	return $_[0]->{NAME}
}

=item B<size>

Returns size the disk item loaded.
if it is a directory it will return the number of children.
Otherwise it will return item size if the size is known.

=cut

sub size {
	my $self = shift;
	my $size = $self->{SIZE};
	if ($self->isDir) {
		my @c = $self->children;
		$size = @c;
	}
	return $size
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=cut

1;








