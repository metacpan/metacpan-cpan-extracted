package lib::gitroot;

our $VERSION = '0.004'; # VERSION

use Modern::Perl;
use Carp;
use File::Spec;
use lib ();

our $_GIT_ROOT = undef;

sub GIT_ROOT { $_GIT_ROOT };

our %_default_values = ( lib => 'lib' );

# :set_root
# :lib (implies :set_root, same as lib => 'lib')
# lib => library path
# use_base_dir => 'somedir_or_filename'
sub import
{
    my ($class, %args) = map { /^:(.*)$/ ? ($1 => $_default_values{$1} || 1) : $_ } @_;
    $args{set_root} = 1 if defined $args{lib};

    my ($module, $filename) = caller;
    $filename = $args{use_base_dir} if defined $args{use_base_dir};

    if ($args{set_root}) {

        if (defined $_GIT_ROOT) {
            die "Git Root already set" unless $args{once};
        } else {
            $filename //= $args{path};
            $_GIT_ROOT = _find_git_dir_for_filename($filename);
            lib->import($_GIT_ROOT.'/'.$args{lib}) if defined $args{lib} and defined $_GIT_ROOT;
        }
    }


    no strict 'refs';
    no warnings 'redefine';
    *{"$module\::GIT_ROOT"} = \&GIT_ROOT;
}


# finds .git root
# $filename - file or directory name to start searching for .git. default to caller.
sub find_git_dir {
    my ($filename, %args) = @_;
    (undef, $filename) = caller unless defined $filename;
    $filename = _readlink($filename) if delete $args{resolve_symlink} && _is_link($filename);
    confess "Unknown option(s) for find_git_dir: ".((keys %args)[0]) if %args;
    _find_git_dir_for_filename($filename);
}

# finds .git root
# $filename - file or directory name to start searching for .git
sub _find_git_dir_for_filename {
    my ($filename) = @_;
    _find_git_dir_for_path_and_isdir( File::Spec->rel2abs($filename), _is_dir($filename) );
}

# finds .git root
# $abspath - file or directory name to start searching for .git. must be absolute
# $is_dir - should be TRUE if $abspath represent directory
sub _find_git_dir_for_path_and_isdir
{
    my ($abspath, $is_dir) = @_;
    my @dirs = File::Spec->splitdir ( $abspath );
    pop @dirs unless $is_dir;
    while (@dirs) {
        my $gitdir = File::Spec->catdir(@dirs, '.git');
        if (_is_dir($gitdir)) {
            return File::Spec->catdir(@dirs);
        }
        pop @dirs;
    }
    return;
}

# like -d, made as function for testing purpose
sub _is_dir { -d shift(); };
sub _is_link { -l shift(); };
sub _readlink { readlink shift(); };


1;

__END__

=pod

=encoding utf-8

=head1 NAME

lib::gitroot - locate .git root at compile time and use as lib path

=head1 SYNOPSIS

    use lib::gitroot qw/:set_root/;

Finds git root and export GIT_ROOT function to current package. Will die if called several times from different places.

    use lib::gitroot qw/:lib/;

Finds git root, export GIT_ROOT function to current package and adds GIT_ROOT/lib to @INC. Will die if called several times from different places.

    use lib::gitroot qw/:set_root :once/;

Same as :set_root, but will not die if called from different places (instead will use first found GIT_ROOT)

    use lib::gitroot qw/:lib :once/;

Similar to :set_root :once

    use lib::gitroot lib => 'mylib';

Use GIT_ROOT/mylib instead

    use lib::gitroot;

Exports GIT_ROOT hoping that it's set previously or will be set in the future

    use lib::gitroot ':lib', use_base_dir => "/some/path";

Use some path, instead of caller filename, for searching for git

    use lib::gitroot ();
    say lib::gitroot::find_git_dir(undef, resolve_symlink => 1); # caller filename, resolve symlink
    say lib::gitroot::find_git_dir(); # caller filename
    say lib::gitroot::find_git_dir($filename, resolve_symlink => 1); # some filename $filename, resolve symlink

If $filename is a symlink, resolves it (i.e. only top level), finds .git root. Does not alter @INC or GIT_ROOT or anything else


=head1 AUTHOR

Victor Efimov <lt>efimov@reg.ruE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by REG.RU LLC

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
