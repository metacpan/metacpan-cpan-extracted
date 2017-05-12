use strict;
use warnings;
use utf8;

package Ukigumo::Client::VC::SVN;
use Mouse;
use Cwd;

with 'Ukigumo::Client::Role::VC';

has log_limit => ( is => 'ro', isa => 'Int', default => 50 );

sub default_branch { 'trunk' }

sub get_revision {
    my $self = shift;
    $self->{revision} ||= $self->_revision() || 'Unknown';
}

sub update {
    my ($self, $c) = @_;

    $c->logger->infof("workdir is ".Cwd::getcwd());
    unless (-d ".svn") {
        $c->tee("svn co @{[ $self->repository ]} ./") == 0 or die "Cannot checkout repository";
    }
    $c->tee("svn up") == 0 or die "svn fail";
    $c->tee("svn cleanup") == 0 or die "svn fail";
    $c->tee("svn status") == 0 or die "svn fail";
    $c->tee("svn info") == 0 or die "svn fail";
    delete $self->{revision};
}

sub get_log {
    my ($self, $rev1, $rev2) = @_;
    $rev1 = 1      if $rev1 eq 'Unknown';
    $rev2 = 'HEAD' if $rev2 eq 'Unknown';
    return if $rev1 eq $rev2; # no change
    `svn log --limit @{[ $self->log_limit ]} -r $rev1:$rev2`;
}

sub _trim {
    my @stuff = @_;
    $_ =~ s/^\s+|\s+$// for @stuff;
    return @stuff;
}

sub _revision {
    return +{ map { _trim(split ':', $_, 2) } split "\n", `svn info` }->{Revision};
}

1;
__END__

=head1 NAME

Ukigumo::Client::VC::SVN - svn.

=head1 DESCRIPTION

This is a svn wrapper for Ukigumo.

=head1 ATTRIBUTES

=over 4

=item repository

This is a repository URL.

=item branch

This is a name of branch. It's B<trunk> by default.

=back
