package Test::Smoke::Syncer::FTP;
use warnings;
use strict;

our $VERSION = '0.029';

use base 'Test::Smoke::Syncer::Base';
use Cwd;

=head1 Test::Smoke::Syncer::FTP

This handles syncing by getting the source-tree from a FTP server.
It uses the C<Test::Smoke::FTPClient> that implements a mirror function.

=cut

use File::Spec::Functions;

=head2 Test::Smoke::Syncer::FTP->new( %args )

Known args for this class:

    * ftphost (ftp.example.com)
    * ftpusr  (anonymous)
    * ftppwd (?)
    * ftpsdir (/)
    * ftype (undef|binary|ascii)

    * ddir
    * v

=cut

=head2 $syncer->sync()

This does the actual syncing:

    * Mirror

=cut

sub sync {
    my $self = shift;

    $self->pre_sync;
    require Test::Smoke::FTPClient;

    my $fc = Test::Smoke::FTPClient->new( $self->{ftphost}, $self->{ftpport}, {
        v       => $self->{v},
        passive => $self->{ftppassive},
        fuser   => $self->{ftpusr},
        fpwd    => $self->{ftppwd},
        ftype   => $self->{ftype},
    } );

    $fc->connect;

    $fc->mirror( @{ $self }{qw( ftpsdir ddir )}, 1 ) or return;

    $self->{client} = $fc;
    $self->{v} = $fc->{v};

    my $cwd = cwd();
    chdir $self->{ddir} or croak("Cannot chdir($self->{ddir}): $!");

    $self->make_dot_patch();

    my $plevel = $self->check_dot_patch;

    chdir $cwd or croak("Cannot chdir($cwd): $!");

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
