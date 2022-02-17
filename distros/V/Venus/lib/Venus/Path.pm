package Venus::Path;

use 5.018;

use strict;
use warnings;

use Moo;

extends 'Venus::Kind::Utility';

with 'Venus::Role::Accessible';
with 'Venus::Role::Explainable';

use overload (
  '.' => sub{$_[0]->value . "$_[1]"},
  'eq' => sub{$_[0]->value eq "$_[1]"},
  'ne' => sub{$_[0]->value ne "$_[1]"},
  'qr' => sub{qr/@{[quotemeta($_[0]->value)]}/},
);

# METHODS

sub absolute {
  my ($self) = @_;

  require File::Spec;

  return $self->class->new(File::Spec->rel2abs($self->get));
}

sub basename {
  my ($self) = @_;

  require File::Basename;

  return File::Basename::basename($self->get);
}

sub child {
  my ($self, $path) = @_;

  require File::Spec;

  my @parts = File::Spec->splitdir($path);

  return $self->class->new(File::Spec->catfile($self->get, @parts));
}

sub chmod {
  my ($self, $mode) = @_;

  my $path = $self->get;

  CORE::chmod($mode, $path);

  return $self;
}

sub chown {
  my ($self, @args) = @_;

  my $path = $self->get;

  CORE::chown((map $_||-1, @args[0,1]), $path);

  return $self;
}

sub children {
  my ($self) = @_;

  require File::Spec;

  my @paths = map $self->glob($_), '.??*', '*';

  return wantarray ? (@paths) : \@paths;
}

sub default {
  require Cwd;

  return Cwd::getcwd();
}

sub directories {
  my ($self) = @_;

  my @paths = grep -d, $self->children;

  return wantarray ? (@paths) : \@paths;
}

sub exists {
  my ($self) = @_;

  return int!!-e $self->get;
}

sub explain {
  my ($self) = @_;

  return $self->get;
}

sub find {
  my ($self, $expr) = @_;

  $expr = '.*' if !$expr;

  $expr = qr/$expr/ if ref($expr) ne 'Regexp';

  my @paths;

  push @paths, grep {
    $_ =~ $expr
  } map {
    $_->is_directory ? $_->find($expr) : $_
  }
  $self->children;

  return wantarray ? (@paths) : \@paths;
}

sub files {
  my ($self) = @_;

  my @paths = grep -f, $self->children;

  return wantarray ? (@paths) : \@paths;
}

sub glob {
  my ($self, $expr) = @_;

  require File::Spec;

  $expr ||= '*';

  my @paths = map $self->class->new($_),
    CORE::glob +File::Spec->catfile($self->absolute, $expr);

  return wantarray ? (@paths) : \@paths;
}

sub is_absolute {
  my ($self) = @_;

  require File::Spec;

  return int!!(File::Spec->file_name_is_absolute($self->get));
}

sub is_directory {
  my ($self) = @_;

  my $path = $self->get;

  return int!!(-e $path && -d $path);
}

sub is_file {
  my ($self) = @_;

  my $path = $self->get;

  return int!!(-e $path && !-d $path);
}

sub is_relative {
  my ($self) = @_;

  return int!$self->is_absolute;
}

sub lineage {
  my ($self) = @_;

  require File::Spec;

  my @parts = File::Spec->splitdir($self->get);

  my @paths = ((
    reverse map $self->class->new(File::Spec->catfile(@parts[0..$_])), 1..$#parts
    ), $self->class->new($parts[0]));

  return wantarray ? (@paths) : \@paths;
}

sub open {
  my ($self, @args) = @_;

  my $path = $self->get;

  require IO::File;

  my $handle = IO::File->new;

  $handle->open($path, @args) or do {
    my $throw;
    my $error = "Can't open $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  return $handle;
}

sub mkcall {
  my ($self, $args) = @_;

  my $path = $self->get;

  my $result;

  (defined($result = ($args ? qx($path $args) : qx($path)))) or do {
    my $throw;
    my $error = "Can't mkcall $path: " . ($! ? "$!" : "exit code ($?)");
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  chomp $result;

  return wantarray ? ($result, $?) : $result;
}

sub mkdir {
  my ($self, $mode) = @_;

  my $path = $self->get;

  ($mode ? CORE::mkdir($path, $mode) : CORE::mkdir($path)) or do {
    my $throw;
    my $error = "Can't mkdir $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  return $self;
}

sub mkdirs {
  my ($self, $mode) = @_;

  my @paths;

  for my $path (
    grep !!$_, reverse($self->parents), ($self->is_file ? () : $self)
  )
  {
    if ($path->exists) {
      next;
    }
    else {
      push @paths, $path->mkdir($mode);
    }
  }

  return wantarray ? (@paths) : \@paths;
}

sub mkfile {
  my ($self) = @_;

  my $path = $self->get;

  return $self if $self->exists;

  $self->open('>');

  CORE::utime(undef, undef, $path) or do {
    my $throw;
    my $error = "Can't mkfile $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  return $self;
}

sub name {
  my ($self) = @_;

  return $self->absolute->get;
}

sub parent {
  my ($self) = @_;

  require File::Spec;

  my @parts = File::Spec->splitdir($self->get);

  my $path = File::Spec->catfile(@parts[0..$#parts-1]);

  return defined $path ? $self->class->new($path) : undef;
}

sub parents {
  my ($self) = @_;

  my @paths = $self->lineage;

  @paths = @paths[1..$#paths] if @paths;

  return wantarray ? (@paths) : \@paths;
}

sub parts {
  my ($self) = @_;

  require File::Spec;

  return [File::Spec->splitdir($self->get)];
}

sub read {
  my ($self, $binmode) = @_;

  my $path = $self->get;

  CORE::open(my $handle, '<', $path) or do {
    my $throw;
    my $error = "Can't read $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  CORE::binmode($handle, $binmode) or do {
    my $throw;
    my $error = "Can't binmode $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(binmode => $binmode);
    $throw->stash(path => $path);
    $throw->error;
  }
  if defined($binmode);

  my $result = my $content = '';

  while ($result = $handle->sysread(my $buffer, 131072, 0)) {
    $content .= $buffer;
  }

  if (not(defined($result))) {
    my $throw;
    my $error = "Can't read from file $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  }

  if ($^O =~ /win32/i) {
    $content =~ s/\015\012/\012/g;
  }

  return $content;
}

sub relative {
  my ($self, $path) = @_;

  require File::Spec;

  $path ||= $self->default;

  return $self->class->new(File::Spec->abs2rel($self->get, $path));
}

sub rmdir {
  my ($self) = @_;

  my $path = $self->get;

  CORE::rmdir($path) or do {
    my $throw;
    my $error = "Can't rmdir $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  return $self;
}

sub rmdirs {
  my ($self) = @_;

  my @paths;

  for my $path ($self->children) {
    if ($path->is_file) {
      push @paths, $path->unlink;
    }
    else {
      push @paths, $path->rmdirs;
    }
  }

  push @paths, $self->rmdir;

  return wantarray ? (@paths) : \@paths;
}

sub rmfiles {
  my ($self) = @_;

  my @paths;

  for my $path ($self->children) {
    if ($path->is_file) {
      push @paths, $path->unlink;
    }
    else {
      push @paths, $path->rmfiles;
    }
  }

  return wantarray ? (@paths) : \@paths;
}

sub sibling {
  my ($self, $path) = @_;

  require File::Basename;
  require File::Spec;

  return $self->class->new(File::Spec->catfile(
    File::Basename::dirname($self->get), $path));
}

sub siblings {
  my ($self) = @_;

  my @paths = map $self->parent->glob($_), '.??*', '*';

  my %seen = ($self->absolute, 1);

  @paths = grep !$seen{$_}++, @paths;

  return wantarray ? (@paths) : \@paths;
}

sub test {
  my ($self, $spec) = @_;

  return eval(
    join(' ', map("-$_", grep(/^[a-zA-Z]$/, split(//, $spec || 'e'))), '$self')
  );
}

sub unlink {
  my ($self) = @_;

  my $path = $self->get;

  CORE::unlink($path) or do {
    my $throw;
    my $error = "Can't unlink $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  return $self;
}

sub write {
  my ($self, $data, $binmode) = @_;

  my $path = $self->get;

  CORE::open(my $handle, '>', $path) or do {
    my $throw;
    my $error = "Can't write $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  CORE::binmode($handle, $binmode) or do {
    my $throw;
    my $error = "Can't binmode $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(binmode => $binmode);
    $throw->stash(path => $path);
    $throw->error;
  }
  if defined($binmode);

  (($handle->syswrite($data) // -1) == length($data)) or do {
    my $throw;
    my $error = "Can't write to file $path: $!";
    $throw = $self->throw;
    $throw->message($error);
    $throw->stash(path => $path);
    $throw->error;
  };

  return $self;
}

1;



=head1 NAME

Venus::Path - Path Class

=cut

=head1 ABSTRACT

Path Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/planets');

  # my $planets = $path->files;
  # my $mercury = $path->child('mercury');
  # my $content = $mercury->read;

=cut

=head1 DESCRIPTION

This package provides methods for working with file system paths.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Accessible>

L<Venus::Role::Explainable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 absolute

  absolute() (Path)

The absolute method returns a path object where the value (path) is absolute.

I<Since C<0.01>>

=over 4

=item absolute example 1

  # given: synopsis;

  $path = $path->absolute;

  # bless({ value => "/path/to/t/data/planets" }, "Venus::Path")

=back

=cut

=head2 basename

  basename() (Str)

The basename method returns the path base name.

I<Since C<0.01>>

=over 4

=item basename example 1

  # given: synopsis;

  my $basename = $path->basename;

  # planets

=back

=cut

=head2 child

  child(Str $path) (Path)

The child method returns a path object representing the child path provided.

I<Since C<0.01>>

=over 4

=item child example 1

  # given: synopsis;

  $path = $path->child('earth');

  # bless({ value => "t/data/planets/earth" }, "Venus::Path")

=back

=cut

=head2 children

  children() (ArrayRef[Path])

The children method returns the files and directories under the path. This
method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item children example 1

  # given: synopsis;

  my $children = $path->children;

  # [
  #   bless({ value => "t/data/planets/ceres" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/earth" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/eris" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/haumea" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/jupiter" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/makemake" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mars" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mercury" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/neptune" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/pluto" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/saturn" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/uranus" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/venus" }, "Venus::Path"),
  # ]

=back

=cut

=head2 chmod

  chmod(Str $mode) (Path)

The chmod method changes the file permissions of the file or directory.

I<Since C<0.01>>

=over 4

=item chmod example 1

  # given: synopsis;

  $path = $path->chmod(0755);

  # bless({ value => "t/data/planets" }, "Venus::Path")

=back

=cut

=head2 chown

  chown(Str @args) (Path)

The chown method changes the group and/or owner or the file or directory.

I<Since C<0.01>>

=over 4

=item chown example 1

  # given: synopsis;

  $path = $path->chown(-1, -1);

  # bless({ value => "t/data/planets" }, "Venus::Path")

=back

=cut

=head2 default

  default() (Str)

The default method returns the default value, i.e. C<$ENV{PWD}>.

I<Since C<0.01>>

=over 4

=item default example 1

  # given: synopsis;

  my $default = $path->default;

  # $ENV{PWD}

=back

=cut

=head2 directories

  directories() (ArrayRef[Path])

The directories method returns a list of children under the path which are
directories. This method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item directories example 1

  # given: synopsis;

  my $directories = $path->directories;

  # []

=back

=cut

=head2 exists

  exists() (Bool)

The exists method returns truthy or falsy if the path exists.

I<Since C<0.01>>

=over 4

=item exists example 1

  # given: synopsis;

  my $exists = $path->exists;

  # 1

=back

=over 4

=item exists example 2

  # given: synopsis;

  my $exists = $path->child('random')->exists;

  # 0

=back

=cut

=head2 explain

  explain() (Str)

The explain method returns the path string and is used in stringification
operations.

I<Since C<0.01>>

=over 4

=item explain example 1

  # given: synopsis;

  my $explain = $path->explain;

  # t/data/planets

=back

=cut

=head2 files

  files() (ArrayRef[Path])

The files method returns a list of children under the path which are files.
This method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item files example 1

  # given: synopsis;

  my $files = $path->files;

  # [
  #   bless({ value => "t/data/planets/ceres" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/earth" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/eris" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/haumea" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/jupiter" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/makemake" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mars" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mercury" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/neptune" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/pluto" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/saturn" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/uranus" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/venus" }, "Venus::Path"),
  # ]

=back

=cut

=head2 find

  find(Str | Regexp $expr) (ArrayRef[Path])

The find method does a recursive depth-first search and returns a list of paths
found, matching the expression provided, which defaults to C<*>. This method
can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item find example 1

  # given: synopsis;

  my $find = $path->find;

  # [
  #   bless({ value => "t/data/planets/ceres" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/earth" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/eris" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/haumea" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/jupiter" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/makemake" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mars" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mercury" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/neptune" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/pluto" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/saturn" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/uranus" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/venus" }, "Venus::Path"),
  # ]

=back

=over 4

=item find example 2

  # given: synopsis;

  my $find = $path->find('[:\/\\\.]+m.*$');

  # [
  #   bless({ value => "t/data/planets/makemake" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mars" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mercury" }, "Venus::Path"),
  # ]

=back

=over 4

=item find example 3

  # given: synopsis;

  my $find = $path->find('earth');

  # [
  #   bless({ value => "t/data/planets/earth" }, "Venus::Path"),
  # ]

=back

=cut

=head2 glob

  glob(Str | Regexp $expr) (ArrayRef[Path])

The glob method returns the files and directories under the path matching the
expression provided, which defaults to C<*>. This method can return a list of
values in list-context.

I<Since C<0.01>>

=over 4

=item glob example 1

  # given: synopsis;

  my $glob = $path->glob;

  # [
  #   bless({ value => "t/data/planets/ceres" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/earth" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/eris" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/haumea" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/jupiter" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/makemake" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mars" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/mercury" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/neptune" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/pluto" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/saturn" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/uranus" }, "Venus::Path"),
  #   bless({ value => "t/data/planets/venus" }, "Venus::Path"),
  # ]

=back

=cut

=head2 is_absolute

  is_absolute() (Bool)

The is_absolute method returns truthy or falsy is the path is absolute.

I<Since C<0.01>>

=over 4

=item is_absolute example 1

  # given: synopsis;

  my $is_absolute = $path->is_absolute;

  # 0

=back

=cut

=head2 is_directory

  is_directory() (Bool)

The is_directory method returns truthy or falsy is the path is a directory.

I<Since C<0.01>>

=over 4

=item is_directory example 1

  # given: synopsis;

  my $is_directory = $path->is_directory;

  # 1

=back

=cut

=head2 is_file

  is_file() (Bool)

The is_file method returns truthy or falsy is the path is a file.

I<Since C<0.01>>

=over 4

=item is_file example 1

  # given: synopsis;

  my $is_file = $path->is_file;

  # 0

=back

=cut

=head2 is_relative

  is_relative() (Bool)

The is_relative method returns truthy or falsy is the path is relative.

I<Since C<0.01>>

=over 4

=item is_relative example 1

  # given: synopsis;

  my $is_relative = $path->is_relative;

  # 1

=back

=cut

=head2 lineage

  lineage() (ArrayRef[Path])

The lineage method returns the list of parent paths up to the root path. This
method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item lineage example 1

  # given: synopsis;

  my $lineage = $path->lineage;

  # [
  #   bless({ value => "t/data/planets" }, "Venus::Path"),
  #   bless({ value => "t/data" }, "Venus::Path"),
  #   bless({ value => "t" }, "Venus::Path"),
  # ]

=back

=cut

=head2 mkcall

  mkcall(Any @data) (Any)

The mkcall method returns the result of executing the path as an executable. In
list context returns the call output and exit code.

I<Since C<0.01>>

=over 4

=item mkcall example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new($^X);

  my $output = $path->mkcall('--help');

  # Usage: perl ...

=back

=over 4

=item mkcall example 2

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/sun');

  my ($call_output, $exit_code) = $path->mkcall('--heat-death');

  # ("", 256)

=back

=cut

=head2 mkdir

  mkdir(Maybe[Str] $mode) (Path)

The mkdir method makes the path as a directory.

I<Since C<0.01>>

=over 4

=item mkdir example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/systems');

  $path = $path->mkdir;

  # bless({ value => "t/data/systems" }, "Venus::Path")

=back

=cut

=head2 mkdirs

  mkdirs(Maybe[Str] $mode) (ArrayRef[Path])

The mkdirs method creates parent directories and returns the list of created
directories. This method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item mkdirs example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/systems');

  my $mkdirs = $path->mkdirs;

  # [
  #   bless({ value => "t/data/systems" }, "Venus::Path")
  # ]

=back

=over 4

=item mkdirs example 2

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/systems/solar');

  my $mkdirs = $path->mkdirs;

  # [
  #   bless({ value => "t/data/systems" }, "Venus::Path"),
  #   bless({ value => "t/data/systems/solar" }, "Venus::Path"),
  # ]

=back

=cut

=head2 mkfile

  mkfile() (Path)

The mkfile method makes the path as an empty file.

I<Since C<0.01>>

=over 4

=item mkfile example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/moon');

  $path = $path->mkfile;

  # bless({ value => "t/data/moon" }, "Venus::Path")

=back

=cut

=head2 name

  name() (Str)

The name method returns the path as an absolute path.

I<Since C<0.01>>

=over 4

=item name example 1

  # given: synopsis;

  my $name = $path->name;

  # /path/to/t/data/planets

=back

=cut

=head2 open

  open(Any @data) (FileHandle)

The open method creates and returns an open filehandle.

I<Since C<0.01>>

=over 4

=item open example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/planets/earth');

  my $fh = $path->open;

  # bless(..., "IO::File");

=back

=over 4

=item open example 2

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/planets/earth');

  my $fh = $path->open('<');

  # bless(..., "IO::File");

=back

=over 4

=item open example 3

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/planets/earth');

  my $fh = $path->open('>');

  # bless(..., "IO::File");

=back

=cut

=head2 parent

  parent() (Path)

The parent method returns a path object representing the parent directory.

I<Since C<0.01>>

=over 4

=item parent example 1

  # given: synopsis;

  my $parent = $path->parent;

  # bless({ value => "t/data" }, "Venus::Path")

=back

=cut

=head2 parents

  parents() (ArrayRef[Path])

The parents method returns is a list of parent directories. This method can
return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item parents example 1

  # given: synopsis;

  my $parents = $path->parents;

  # [
  #   bless({ value => "t/data" }, "Venus::Path"),
  #   bless({ value => "t" }, "Venus::Path"),
  # ]

=back

=cut

=head2 parts

  parts() (ArrayRef[Str])

The parts method returns an arrayref of path parts.

I<Since C<0.01>>

=over 4

=item parts example 1

  # given: synopsis;

  my $parts = $path->parts;

  # ["t", "data", "planets"]

=back

=cut

=head2 read

  read(Str $binmode) (Str)

The read method reads the file and returns its contents.

I<Since C<0.01>>

=over 4

=item read example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/planets/mars');

  my $content = $path->read;

=back

=cut

=head2 relative

  relative(Str $root) (Path)

The relative method returns a path object representing a relative path
(relative to the path provided).

I<Since C<0.01>>

=over 4

=item relative example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('/path/to/t/data/planets/mars');

  my $relative = $path->relative('/path');

  # bless({ value => "to/t/data/planets/mars" }, "Venus::Path")

=back

=over 4

=item relative example 2

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('/path/to/t/data/planets/mars');

  my $relative = $path->relative('/path/to/t');

  # bless({ value => "data/planets/mars" }, "Venus::Path")

=back

=cut

=head2 rmdir

  rmdir() (Path)

The rmdir method removes the directory and returns a path object representing
the deleted directory.

I<Since C<0.01>>

=over 4

=item rmdir example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/stars');

  my $rmdir = $path->mkdir->rmdir;

  # bless({ value => "t/data/stars" }, "Venus::Path")

=back

=cut

=head2 rmdirs

  rmdirs() (ArrayRef[Path])

The rmdirs method removes that path and its child files and directories and
returns all paths removed. This method can return a list of values in
list-context.

I<Since C<0.01>>

=over 4

=item rmdirs example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/stars');

  $path->child('dwarfs')->mkdirs;

  my $rmdirs = $path->rmdirs;

  # [
  #   bless({ value => "t/data/stars/dwarfs" }, "Venus::Path"),
  #   bless({ value => "t/data/stars" }, "Venus::Path"),
  # ]

=back

=cut

=head2 rmfiles

  rmfiles() (ArrayRef[Path])

The rmfiles method recursively removes files under the path and returns the
paths removed. This method does not remove the directories found. This method
can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item rmfiles example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/stars')->mkdir;

  $path->child('sirius')->mkfile;
  $path->child('canopus')->mkfile;
  $path->child('arcturus')->mkfile;
  $path->child('vega')->mkfile;
  $path->child('capella')->mkfile;

  my $rmfiles = $path->rmfiles;

  # [
  #   bless({ value => "t/data/stars/arcturus" }, "Venus::Path"),
  #   bless({ value => "t/data/stars/canopus" }, "Venus::Path"),
  #   bless({ value => "t/data/stars/capella" }, "Venus::Path"),
  #   bless({ value => "t/data/stars/sirius" }, "Venus::Path"),
  #   bless({ value => "t/data/stars/vega" }, "Venus::Path"),
  # ]

=back

=cut

=head2 sibling

  sibling(Str $path) (Path)

The sibling method returns a path object representing the sibling path provided.

I<Since C<0.01>>

=over 4

=item sibling example 1

  # given: synopsis;

  my $sibling = $path->sibling('galaxies');

  # bless({ value => "t/data/galaxies" }, "Venus::Path")

=back

=cut

=head2 siblings

  siblings() (ArrayRef[Path])

The siblings method returns all sibling files and directories for the current
path. This method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item siblings example 1

  # given: synopsis;

  my $siblings = $path->siblings;

  # [
  #   bless({ value => "t/data/moon" }, "Venus::Path"),
  #   bless({ value => "t/data/sun" }, "Venus::Path"),
  # ]

=back

=cut

=head2 test

  test(Str $expr) (Bool)

The test method evaluates the current path against the stackable file test
operators provided.

I<Since C<0.01>>

=over 4

=item test example 1

  # given: synopsis;

  my $test = $path->test;

  # -e $path

  # 1

=back

=over 4

=item test example 2

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/sun');

  my $test = $path->test('efs');

  # -e -f -s $path

  # 1

=back

=cut

=head2 unlink

  unlink() (Path)

The unlink method removes the file and returns a path object representing the
removed file.

I<Since C<0.01>>

=over 4

=item unlink example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/asteroid')->mkfile;

  my $unlink = $path->unlink;

  # bless({ value => "t/data/asteroid" }, "Venus::Path")

=back

=cut

=head2 write

  write(Str $data, Str $binmode) (Path)

The write method write the data provided to the file.

I<Since C<0.01>>

=over 4

=item write example 1

  package main;

  use Venus::Path;

  my $path = Venus::Path->new('t/data/asteroid');

  my $write = $path->write('asteroid');

=back

=cut

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<(.)>

This package overloads the C<.> operator.

B<example 1>

  # given: synopsis;

  my $result = $path . '/earth';

  # "t/data/planets/earth"

=back

=over 4

=item operation: C<(eq)>

This package overloads the C<eq> operator.

B<example 1>

  # given: synopsis;

  my $result = $path eq 't/data/planets';

  # 1

=back

=over 4

=item operation: C<(ne)>

This package overloads the C<ne> operator.

B<example 1>

  # given: synopsis;

  my $result = $path ne 't/data/planets/';

  # 1

=back

=over 4

=item operation: C<(qr)>

This package overloads the C<qr> operator.

B<example 1>

  # given: synopsis;

  my $result = 't/data/planets' =~ $path;

  # 1

=back

=head1 AUTHORS

Cpanery, C<cpanery@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2021, Cpanery

Read the L<"license"|https://github.com/cpanery/venus/blob/master/LICENSE> file.

=cut