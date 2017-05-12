package Test::Smoke::Syncer::Forest;
use warnings;
use strict;

use base 'Test::Smoke::Syncer::Base';

=head1 Test::Smoke::Syncer::Forest

This handles syncing by setting up a master directory that is in sync
with either a snapshot or the repository. Then it creates a copy of
this master directory as a hardlink forest and the B<regenheaders.pl>
script is run (if found). Now the source-tree should be up to date
and ready to be copied as a hardlink forest again, to its final
destination.

Thanks to Nicholas Clark for donating this idea.

=cut

=head2 Test::Smoke::Syncer::Forest->new( %args )

Keys for C<%args>:

  * All keys from the other methods (depending on {fsync})
  * fsync: which master sync method is to be used
  * mdir:  master directory
  * fdir:  intermediate directory (first hardlink forest)

=cut

=head2 $syncer->sync( )

C<sync()> starts with a "traditional" sync according to {ftype} in {mdir}.
It then creates a copy of {mdir} in {fdir} with hardlinks an tries to run
the B<regen_headers.pl> script in {fdir}. This directory should now contain
an up to date (working) source-tree wich again using hardlinks is copied
to the destination directory {ddir}.


=cut

sub sync {
    my $self = shift;

    my %args = map { ( $_ => $self->{ $_ } ) } keys %$self;
    $args{ddir} = $self->{mdir};
    $self->{v} and print "Prepare to sync ($self->{fsync}|$args{ddir})\n";
    my $syncer = Test::Smoke::Syncer->new( $self->{fsync}, \%args );
    $syncer->sync;

    # Now copy the master
    $args{ddir} = $self->{fdir};
    $args{hdir} = $self->{mdir};
    $self->{v} and print "Prepare to sync (hardlink|$args{ddir})\n";
    $syncer = Test::Smoke::Syncer->new( hardlink => \%args );
    $syncer->sync;

    # now try to run the 'regen_headers.pl' script
    if ( -e File::Spec->catfile( $self->{fdir}, 'regen_headers.pl' ) ) {
        $self->{v} and print "Run 'regen_headers.pl' ($self->{fdir})\n";
        my $cwd = Cwd::cwd();
        chdir $self->{fdir} or do {
            require Carp;
            Carp::croak( "Cannot chdir($self->{fdir}) in forest: $!" );
        };
        system( "$^X regen_headers.pl" ) == 0 or do {
            require Carp;
            Carp::carp( "Error while running 'regen_headers.pl'" );
        };
        chdir $cwd or do {
            require Carp;
            Carp::croak( "Cannot chdir($cwd) back: $!" );
        };
    }

    $args{ddir} = $self->{ddir};
    $args{hdir} = $self->{fdir};
    $self->{v} and print "Prepare to sync (hardlink|$args{ddir})\n";
    $syncer = Test::Smoke::Syncer->new( hardlink => \%args );
    my $plevel = $syncer->sync;

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
