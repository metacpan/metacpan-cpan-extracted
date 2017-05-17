package Test::Smoke::Syncer::Rsync;
use warnings;
use strict;

our $VERSION = '0.029';

use base 'Test::Smoke::Syncer::Base';

=head1 Test::Smoke::Syncer::Rsync

This handles syncing with the B<rsync> program.
It should only be visible from the "parent-package" so no direct
user-calls on this.

=cut

use Cwd;
use Test::Smoke::LogMixin;
use Test::Smoke::Util::Execute;
use Text::ParseWords;

=head2 Test::Smoke::Syncer::Rsync->new( %args )

This crates the new object. Keys for C<%args>:

  * ddir:   destination directory ( ./perl-current )
  * source: the rsync source ( ftp.linux.activestate.com::perl-current )
  * opts:   the options for rsync ( -az --delete )
  * rsync:  the full path to the rsync program ( rsync )
  * v:      verbose

=head2 $rsync->pre_sync()

Create the destination directory is it doesn't exist.

=cut

sub pre_sync {
    my $self = shift;
    if (! -d $self->{ddir}) {
        require File::Path;
        open my $fh, '>', \my $output;
        my $stdout = select $fh;
        File::Path::mkpath($self->{ddir}, $self->verbose);
        select $stdout;
        $self->log_info($output);
    }
    $self->SUPER::pre_sync;
}

=head2 $object->sync( )

Do the actual sync using a call to the B<rsync> program.

B<rsync> can also be used as a smart version of copy. If you
use a local directory to rsync from, make sure the destination path
ends with a I<path separator>! (This does not seem to work for source
paths mounted via NFS.)

=cut

sub sync {
    my $self = shift;
    $self->pre_sync;

    my $rsync = Test::Smoke::Util::Execute->new(
        command => $self->{rsync},
        verbose => $self->verbose,
    );
    my $cwd = cwd();
    if (! chdir $self->{ddir}) {
        require Carp;
        Carp::croak( "[rsync] Cannot chdir($self->{ddir}): $!" );
    };
    my $rsyncout = $rsync->run(
        shellwords($self->{opts}),
        ($self->verbose ? "-v" : ""),
        $self->{source},
        File::Spec->curdir,
        ($self->verbose ? "" : ">" . File::Spec->devnull)
    );
    $self->log_debug($rsyncout);

    if (my $err = $rsync->exitcode ) {
        require Carp;
        Carp::carp( "Problem during rsync ($err)" );
    }

    if ($self->is_git_dir()) {
        $self->make_dot_patch();
    }

    chdir $cwd;

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
