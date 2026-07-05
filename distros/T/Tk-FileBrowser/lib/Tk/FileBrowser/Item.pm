package Tk::FileBrowser::Item;

=head1 NAME

Tk::FileBrowser::Item - Item object for Tk::FileBrowser

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION = 0.12;

use Config;
my $mswin = $Config{'osname'} eq 'MSWIN32';

use base qw(Tk::ListBrowser::Entry);

use File::Spec;

#setting up support for File::MimeInfo;
eval 'use File::MimeInfo::Magic qw(mimetype);' unless $mswin;
eval 'use File::MimeInfo::Simple qw(mimetype);' if $mswin;

=head1 SYNOPSIS

 use Tk::FileBrowser::Item;
 my $item = new Tk::FileBrowsr::Item($file);

=head1 DESCRIPTION

Item object used in Tk::FileBrowser. You should never have to create one yourself.

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);

	if ($self->isDir) {
		$self->{LOADED} = 0;
		$self->{CHILDREN} = {};
		$self->opened(0);
	}
	$self->loadStat;

	if ($self->isLink) {
		my $lb = $self->listbrowser;
		my $fm = $lb->parent;
		my $lc = $fm->cget('-linkcolor');
		$self->foreground($lc);
	}

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

=item B<fullname>I<(?$fullname?)>

=cut

sub fullname {
	my $self = shift;
	$self->{FULLNAME} = shift if @_;
	return $self->{FULLNAME}
}

sub hasChildren {
	my $self = shift;
	return 0 unless $self->isDir;
	my @c = $self->children;
	my $ch = @c;
	return $ch;
}

sub image {
	my $self = shift;
	my $lb = $self->listbrowser;
	my $fm = $lb->parent;
	my $mode = $fm->cget('-viewmode');
	my $method = "image_$mode";
	return unless $self->can($method);
	my $img = $self->$method;
	unless (defined $img) {
		if ($self->isDir) {
			$img = $fm->Callback('-diriconcall', $self->fullname, $mode)
		} elsif ($self->isLink) {
			$img = $fm->Callback('-linkiconcall', $self->fullname, $mode)
		} else {
			$img = $fm->Callback('-fileiconcall', $self->fullname, $mode)
		}
		$self->$method($img)
	}
	return $img;
}

sub image_compact {
	my $self = shift;
	$self->{IMAGECOMPACT} = shift if @_;
	return $self->{IMAGECOMPACT}
}

sub image_icon {
	my $self = shift;
	$self->{IMAGEICON} = shift if @_;
	return $self->{IMAGEICON}
}

sub image_detailed {
	my $self = shift;
	$self->{IMAGEDETAILED} = shift if @_;
	return $self->{IMAGEDETAILED}
}

=item B<isDir>

Returns true if this object reprents a directory.

=cut

sub isDir {
	return -d $_[0]->fullname;
}

=item B<isFile>

Returns true if this object reprents a file.

=cut

sub isFile {
	return -f $_[0]->fullname;
}

=item B<isLink>

Returns true if this object reprents a symbolic link.

=cut

sub isLink {
	return -l $_[0]->fullname;
}

=item B<loaded>I<($flag)>

Sets or returns the loaded flag if this object represents a directory.

=cut

sub loaded {
	my ($self, $flag) = @_;
	if ($self->isDir) {
		$self->{LOADED} = $flag if defined $flag;
		return $self->{LOADED}
	}
	carp $self->fullname . " is not a directory"
}

=item B<loadStat>I<($item)>

Loads the details of I<$item>. I<$item> can be a file, folder or symlink.

=cut

sub loadStat {
	my $self = shift;
	my $item = $self->fullname;
	return unless defined $item;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
	if (-l $item) {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat($item);
	} else {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($item);
	}
	$self->{SIZE} = $size;
	$self->{ACCESSED} = $atime;
	$self->{MODIFIED} = $mtime;
	$self->{CREATED} = $ctime;
	$self->{TYPE} = mimetype($item);
}

=item B<modified>

Returns the modified time stamp.

=cut

sub modified {
	return $_[0]->{MODIFIED};
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

=item B<type>

Returns the mime type.

=cut

sub type {
	return $_[0]->{TYPE};
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








