package Test::Smoke::Syncer::Git;
use warnings;
use strict;

our $VERSION = '0.029';

use base 'Test::Smoke::Syncer::Base';

=head1 Test::Smoke::Syncer::Git

This handles syncing with git repositories.

=cut


use Cwd;
use File::Spec::Functions;
use Test::Smoke::LogMixin;
use Test::Smoke::Util::Execute;

=head2 Test::Smoke::Syncer::Git->new( %args )

Keys for C<%args>:

    * gitorigin
    * gitdir
    * gitbin
    * gitbranchfile
    * gitdfbranch

=cut

=head2 $syncer->sync()

Do the actual syncing.

There are 2 repositories, they both need to be updated:

The first (proxy) repository has the github.com/Perl repository as its
(origin) remote. The second repository is used to run the smoker from.

For the proxy-repository we do:

    git fetch --all
    git remote prune origin
    git reset --hard origin/$gitbranch

For the working-repository we do:

    git clean -dfx
    git fetch --all
    git reset --hard origin/$gitbranch

=cut

sub sync {
    my $self = shift;

    my $gitbin = Test::Smoke::Util::Execute->new(
        command => $self->{gitbin},
        verbose => $self->verbose,
    );
    use Carp;
    my $cwd = cwd();
    # Handle the proxy-clone
    if ( ! -d $self->{gitdir} || ! -d catdir($self->{gitdir}, '.git') ) {
        my $cloneout = $gitbin->run(
            clone => $self->{gitorigin},
            $self->{gitdir},
            ($^O eq 'MSWin32' ? ('--config', 'core.autocrlf=input') : ()),
            '2>&1'
        );
        if ( my $gitexit = $gitbin->exitcode ) {
            croak("Cannot make initial clone: $self->{gitbin} exit $gitexit");
        }
        $self->log_debug("[git clone from $self->{gitorigin}]: $cloneout");
    }

    my $gitbranch = $self->get_git_branch;
    chdir $self->{gitdir} or croak("Cannot chdir($self->{gitdir}): $!");
    $self->log_debug("chdir($self->{gitdir})");

    my $gitout = $gitbin->run(remote => 'update', '--prune', '2>&1');
    $self->log_debug("gitorigin(update --prune): $gitout");

    $gitout = $gitbin->run(checkout => $gitbranch, '2>&1');
    $self->log_debug("gitorigin(checkout): $gitout");

    $gitout = $gitbin->run(reset => '--hard', "origin/$gitbranch", '2>&1');
    $self->log_debug("gitorigin(reset --hard): $gitout");

    # Now handle the working-clone
    chdir $cwd or croak("Cannot chdir($cwd): $!");
    $self->log_debug("chdir($cwd)");
    # make the working-clone if it doesn't exist yet
    if ( ! -d $self->{ddir} || ! -d catdir($self->{ddir}, '.git') ) {
        # It needs to be empty ...
        my $cloneout = $gitbin->run(
            clone         => $self->{gitdir},
            $self->{ddir},
            ($^O eq 'MSWin32' ? ('--config', 'core.autocrlf=input') : ()),
            '2>&1'
        );
        if ( my $gitexit = $gitbin->exitcode ) {
            croak("Cannot make smoke clone: $self->{gitbin} exit $gitexit");
        }
        $self->log_debug("[git clone $self->{gitdir}]: $cloneout");
    }

    chdir $self->{ddir} or croak("Cannot chdir($self->{ddir}): $!");
    $self->log_debug("chdir($self->{ddir})");

    # reset the working-dir to HEAD of the last branch smoked
    $gitout = $gitbin->run(reset => '--hard', 'HEAD', '2>&1');
    $self->log_debug("working-dir(reset --hard): $gitout");

    # remove all untracked files and dirs
    $gitout = $gitbin->run(clean => '-dfx', '2>&1');
    $self->log_debug("working-dir(clean -dfx): $gitout");

    # update from origin
    $gitout = $gitbin->run(fetch => 'origin', '2>&1');
    $self->log_debug("working-dir(fetch origin): $gitout");

    # now checkout the branch we want smoked
    $gitout = $gitbin->run(checkout => $gitbranch, '2>&1');
    $self->log_debug("working-dir(checkout $gitbranch): $gitout");

    # Make sure HEAD is exactly what the branch is
    $gitout = $gitbin->run(reset => '--hard', "origin/$gitbranch", '2>&1');
    $self->log_debug("working-dir(reset --hard): $gitout");

    $self->make_dot_patch();

    chdir $cwd;

    return $self->check_dot_patch;
}

=head2 $git->get_git_branch()

Reads the first line of the file set in B<gitbranchfile> and returns its
value.

=cut

sub get_git_branch {
    my $self = shift;

    return $self->{gitdfbranch} if !$self->{gitbranchfile};
    return $self->{gitdfbranch} if ! -f $self->{gitbranchfile};

    if (open my $fh, '<', $self->{gitbranchfile}) {
        $self->log_debug("Reading branch to smoke from: '$self->{gitbranchfile}'");

        chomp( my $branch = <$fh> );
        close $fh;
        return $branch;
    }
    $self->log_warn("Error opening '$self->{gitbranchfile}': $!");
    return $self->{gitdfbranch};
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
