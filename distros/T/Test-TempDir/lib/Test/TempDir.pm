use strict;
use warnings;
package Test::TempDir; # git description: v0.09-5-gd190d22
# ABSTRACT: (DEPRECATED) Temporary files support for testing

our $VERSION = '0.10';

use File::Temp ();

use Test::TempDir::Factory;

use Sub::Exporter -setup => {
    exports => [qw(temp_root tempdir tempfile scratch)],
    groups => {
        default => [qw(temp_root tempdir tempfile)],
    },
};

our ( $factory, $dir );

sub _factory   { $factory ||= Test::TempDir::Factory->new }
sub _dir       { $dir     ||= _factory->create }

END { undef $dir; undef $factory };

sub temp_root () { _dir->dir }

sub _temp_args { DIR => temp_root()->stringify, CLEANUP => 0 }
sub _template_args {
    if ( @_ % 2 == 0 ) {
        return ( _temp_args, @_ );
    } else {
        return ( $_[0], _temp_args, @_[1 .. $#_] );
    }
}

sub tempdir { File::Temp::tempdir( _template_args(@_) ) }

sub tempfile { File::Temp::tempfile( _template_args(@_) ) }

sub scratch {
    require Directory::Scratch;
    Directory::Scratch->new( _temp_args, @_ );
}


__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::TempDir - (DEPRECATED) Temporary files support for testing

=head1 VERSION

version 0.10

=head1 DEPRECATION NOTICE

There have been numerous issues found with this module, particularly with its
use of locks (unreliable, may result in your entire C<$TMPDIR> being deleted)
and MSWin32 compatibility. As well, it uses Moose, which is nowadays considered
to be heavier than necessary.

L<Test::TempDir::Tiny> was written as a replacement. Please use it instead!

=head1 SYNOPSIS

    use Test::TempDir;

    my $test_tempdir = temp_root();

    my ( $fh, $file ) = tempfile();

    my $directory_scratch_obj = scratch();

=head1 DESCRIPTION

Test::TempDir provides temporary directory creation with testing in mind.

The differences between using this and using L<File::Temp> are:

=over 4

=item *

=for stopwords creatable

If C<t/tmp> is available (writable, creatable, etc) it's preferred over
C<$ENV{TMPDIR}> etc. Otherwise a temporary directory will be used.

This is C<temp_root>

=item *

Lock files are used on C<t/tmp>, to prevent race conditions when running under a
parallel test harness.

=item *

The C<temp_root> is cleaned at the end of a test run, but not if tests failed.

=item *

C<temp_root> is emptied at the beginning of a test run unconditionally.

=item *

The default policy is not to clean the individual C<tempfiles> and C<tempdirs>
within C<temp_root>, in order to aid in debugging of failed tests.

=back

=head1 EXPORTS

=head2 C<temp_root>

The root of the temporary stuff.

=head2 C<tempfile>

=head2 C<tempdir>

Wrappers for the L<File::Temp> functions of the same name.

=for stopwords overridable

The default options are changed to use C<temp_root> for C<DIR> and disable
C<CLEANUP>, but these are overridable.

=head2 C<scratch>

Loads L<Directory::Scratch> and instantiates a new one, with the same default
options as C<tempfile> and C<tempdir>.

=head1 SEE ALSO

=over 4

=item *

L<File::Temp>,

=item *

L<Directory::Scratch>

=item *

L<Path::Class>

=back

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Florian Ragwitz

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=cut
