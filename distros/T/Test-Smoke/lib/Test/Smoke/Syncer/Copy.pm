package Test::Smoke::Syncer::Copy;
use warnings;
use strict;
use Cwd;

our $VERSION = '0.029';

use base 'Test::Smoke::Syncer::Base';

=head1 Test::Smoke::Syncer::Copy

This handles syncing with the B<File::Copy> module from a local
directory. It uses the B<MANIFEST> file is the source directory
to determine which fiels to copy. The current source-tree removed
before the actual copying.

=cut

=head2 Test::Smoke::Syncer::Copy->new( %args )

This crates the new object. Keys for C<%args>:

  * ddir:    destination directory ( ./perl-current )
  * cdir:    directory to copy from ( undef )
  * v:       verbose

=cut

=head2 $syncer->sync( )

This uses B<Test::Smoke::SourceTree> to do the actual copying.  After
that it will clean up the source-tree (from F<MANIFEST>, but ignoring
F<MANIFEST.SKIP>!).

=cut

sub sync {
    my $self = shift;

    $self->{cdir} eq $self->{ddir} and do {
        require Carp;
        Carp::croak( "Sourcetree cannot be copied onto it self!" );
    };

    $self->pre_sync;
    require Test::Smoke::SourceTree;
    my $cwd = getcwd;
    if (! chdir $self->{cdir}) {
        require Carp;
        Carp::croak( "[copy] Cannot chdir($self->{cdir}): $!" );
    };
    $self->make_dot_patch if (! -e ".patch");

    if (! chdir $cwd) {
        require Carp;
        Carp::croak( "[copy] Cannot chdir($cwd): $!" );
    };

    my $tree = Test::Smoke::SourceTree->new($self->{cdir}, $self->verbose);
    $tree->copy_from_MANIFEST($self->{ddir});

    $tree = Test::Smoke::SourceTree->new( $self->{ddir} );
    $tree->clean_from_MANIFEST( 'MANIFEST.SKIP' );

    my $plevel = $self->check_dot_patch;

    $self->post_sync;
    return $plevel;
}

1;

=head1 COPYRIGHT

(c) 2002-2013, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
