#!perl

# TODO see if I can replace this with Path::Class, Path::Extended,
# or Badger::Filesystem::Path.
package Test::OnlySome::PathCapsule;
use 5.012;
use strict;
use warnings;
use Carp qw(croak);
use File::Spec;
use Cwd qw(cwd);

use constant { true => !!1, false => !!0 };

our $VERSION = '0.001000';

# Docs {{{2

=head1 NAME

Test::OnlySome::PathCapsule - yet another object-oriented path representation

=head1 INSTALLATION

See L<Test::OnlySome>, with which this module is distributed.

=head1 SYNOPSIS

    use Test::OnlySome::PathCapsule;
    my $path = Test::OnlySome::PathCapsule->new('some/path')
    my $cwd = Test::OnlySome::PathCapsule->new()

    $path->up()         # move to the parent dir, if any
    $path->down('foo')  # move to dir 'foo'

Test::OnlySome::PathCapsule doesn't care whether the path actually exists on disk.

=head1 CREATING AND MODIFYING

=cut

# }}}2

# new() # {{{1

=head2 new

Create a new instance.

    my $path = Test::OnlySome::PathCapsule->new([$pathname_string[, $is_dir = 0]])

If C<$pathname_string> is given, the instance points at that path.  Otherwise,
the instance points at cwd.  If C<$is_dir>, C<$pathname_string> points at a
directory; otherwise, it points at a file.

=cut

sub new {
    my $class = shift;
    my $filename = shift;
    my $is_dir = shift // false;
    my $cwd = cwd;

    unless(defined $filename) {
        $filename = $cwd;
        $is_dir = true;
    }

    $filename = File::Spec->rel2abs($filename, $cwd)
        unless File::Spec->file_name_is_absolute($filename);

    my ($vol, $dir, $file) = File::Spec->splitpath($filename, $is_dir);
    $dir = File::Spec->catdir($dir);
        # Trim trailing slash, if any

    my @dirs = File::Spec->splitdir($dir);

    # Note: hash keys all have a leading underscore to avoid name confusion
    # with functions on the instance.
    return bless {
        _vol => $vol,           # The path itself, always stored absolute.
        _dirs => [@dirs],
        _file => $file,

        _is_dir => $is_dir,     # The path's context
        _relative_to => $cwd,   # never changes
    }, $class;
} # }}}1
# clone() # {{{1

=head2 clone

Return a clone of this instance.  Useful if you want to start from one
path and move to others.  Usage is C<$instance->clone()>.

=cut

sub clone {
    my $self = shift or croak "Need an instance";
    my $new_instance = {
        _vol => $self->{_vol},
        _dirs => [@{ $self->{_dirs} }],     # One-level-deep copy
        _file => $self->{_file},

        _is_dir => $self->{_is_dir},
        _relative_to => $self->{_relative_to},
    };

    return bless($new_instance, ref $self);
} # }}}1

=head2 up

Move up one directory, if that is possible.  Returns the instance, so you can
chain calls.  Usage:

    $path->up([$keep_filename=0])

If C<$keep_filename> is truthy, keep the filename.  Otherwise, clear it out,
since moving into a different directory probably invalidates the name.

Returns the instance.

=cut

sub up {
    my $self = shift or croak "Need an instance";
    my $keep_filename = shift // false;
    pop @{ $self->{_dirs} };
    unless($keep_filename) {
        $self->{_file} = '';
        $self->{_is_dir} = true;
    }
    return $self;
} #up

=head2 down

Move up one directory, if that is possible.  Returns the instance, so you can
chain calls.  Usage:

    $path->down($whither[, $keep_filename=0])

If C<$keep_filename> is truthy, keep the filename.  Otherwise, clear it out,
since moving into a different directory probably invalidates the name.

Returns the instance.

=cut

sub down {
    my $self = shift or croak "Need an instance";
    my $dir = shift or croak "Need a directory to move down to";
    my $keep_filename = shift // false;

    push @{ $self->{_dirs} }, $dir;
    unless($keep_filename) {
        $self->{_file} = '';
        $self->{_is_dir} = true;
    }
    return $self;
} #down

=head2 file

Get or set the filename.  Usage:

    $self->file([$new_filename])

If no argument is given, returns the current filename, or C<undef> if the
path is a directory.  If an argument is given, marks the instance as not
representing a dir, and returns the instance.

=cut

sub file {
    my $self = shift or croak "Need an instance";

    if(@_) {    # Setter
        $self->{_file} = '' . shift;
        $self->{_is_dir} = false;
        return $self;
    } else {    # Getter
        return $self->{_file};
    }
} #file

=head1 ACCESSING

=head2 is_dir

Returns true if the instance represents a directory as opposed to a file.

=cut

sub is_dir {
    my $self = shift or croak "Need an instance";
    return !!$self->{_is_dir};
} #is_dir()

=head2 abs

Returns the absolute path to the file.  Usage: C<$self->abs>.

=cut

sub abs {
    my $self = shift or croak "Need an instance";
    return File::Spec->catpath($self->{_vol},
        File::Spec->catdir(@{ $self->{_dirs} }),
        $self->{_file});
} #abs()

=head2 rel

Returns the relative path to the file from the current working directory.
Usage: C<$self->rel>.

=cut

sub rel {
    my $self = shift or croak "Need an instance";
    return File::Spec->abs2rel($self->abs, cwd);
} #rel()

=head2 rel_orig

Returns the relative path to the file from the current working directory
at the time the instance was created.  Usage: C<$self->rel_orig>.

=cut

sub rel_orig {
    my $self = shift or croak "Need an instance";
    return File::Spec->abs2rel($self->abs, $self->{_relative_to});
} #rel_orig()

1;
# vi: set fdm=marker fo-=ro:
