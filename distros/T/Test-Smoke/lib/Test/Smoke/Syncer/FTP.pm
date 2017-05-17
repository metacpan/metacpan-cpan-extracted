package Test::Smoke::Syncer::FTP;
use warnings;
use strict;

our $VERSION = '0.029';

use base 'Test::Smoke::Syncer::Base';

=head1 Test::Smoke::Syncer::FTP

This handles syncing by getting the source-tree from ActiveState's APC
repository. It uses the C<Test::Smoke::FTPClient> that implements a
mirror function.

=cut

use File::Spec::Functions;

=head2 Test::Smoke::Syncer::FTP->new( %args )

Known args for this class:

    * ftphost (public.activestate.com)
    * ftpusr  (anonymous)
    * ftppwd  (smokers@perl.org)
    * ftpsdir (/pub/apc/perl-????)
    * ftpcdir (/pub/apc/perl-????-diffs)
    * ftype (undef|binary|ascii)

    * ddir
    * v

=cut

=head2 $syncer->sync()

This does the actual syncing:

    * Check {ftpcdir} for the latest changenumber
    * Mirror

=cut

sub sync {
    my $self = shift;

    $self->pre_sync;
    require Test::Smoke::FTPClient;

    my $fc = Test::Smoke::FTPClient->new( $self->{ftphost}, {
        v       => $self->{v},
        passive => $self->{ftppassive},
        fuser   => $self->{ftpusr},
        fpwd    => $self->{ftppwd},
        ftype   => $self->{ftype},
    } );

    $fc->connect;

    $fc->mirror( @{ $self }{qw( ftpsdir ddir )}, 1 ) or return;

    $self->{client} = $fc;

    my $plevel = $self->create_dot_patch;
    $self->post_sync;
    return $plevel;
}

=head2 $syncer->create_dot_patch

This needs to go to the *-diffs directory on APC and find the patch
whith the highest number, that should be our current patchlevel.

=cut

sub create_dot_patch {
    my $self = shift;
    my $ftp = $self->{client}->{client};

    $ftp->cwd( $self->{ftpcdir} );
    my $plevel = (sort { $b <=> $a } map {
        s/\.gz$//; $_
    } grep /\d+\.gz/ => $ftp->ls)[0];

    my $dotpatch = catfile( $self->{ddir}, '.patch' );
    local *DOTPATH;
    if ( open DOTPATCH, "> $dotpatch" ) {
        print DOTPATCH $plevel;
        close DOTPATCH or do {
            require Carp;
            Carp::carp( "Error writing '$dotpatch': $!" );
        };
    } else {
        require Carp;
        Carp::carp( "Error creating '$dotpatch': $!" );
    }
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
