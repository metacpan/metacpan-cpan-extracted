package WWW::Noss::Forker;
use 5.016;
use strict;
use warnings;
our $VERSION = '2.05';

use File::Path qw(remove_tree);
use File::Temp qw(tempfile tempdir);
use Storable;

sub new {

    my ($class, $procs) = @_;

    if ($procs < 0) {
        die '$procs must be >=0';
    } elsif ($procs == 0) {
        $procs = 1;
    }

    return bless {
        Limit  => $procs,
        Finish => undef,
        Tmp    => tempdir(CLEANUP => 0),
        Procs  => {},
        Num    => 0,
        Child  => 0,
    }, $class;

}

sub run_on_finish {

    my ($self, $sub) = @_;

    if (ref $sub ne 'CODE') {
        die '$sub is not a subroutine reference';
    }

    $self->{ Finish } = $sub;

}

sub wait_next {

    my ($self) = @_;

    my $w = wait;
    if ($w == -1) {
        return -1;
    }

    if (defined $self->{ Finish }) {
        $self->{ Finish }->(
            $w, $?,
            -s $self->{ Procs }{ $w } ? retrieve($self->{ Procs }{ $w }) : undef
        );
    }

    $self->{ Num }--;
    delete $self->{ Procs }{ $w };

    return $w;

}

sub start {

    my ($self) = @_;

    while ($self->{ Num } >= $self->{ Limit }) {
        $self->wait_next;
    }

    my $tmp = do {
        my ($h, $p) = tempfile(UNLINK => 0, DIR => $self->{ Tmp });
        close $h;
        $p
    };

    my $pid = fork;
    if (not defined $pid) {
        die "error forking: $!\n";
    } elsif ($pid) {
        $self->{ Procs }{ $pid } = $tmp;
    } else {
        $self->{ Procs }{ $$ } = $tmp;
        $self->{ Child } = 1;
    }

    $self->{ Num }++;

    return $pid;

}

sub finish {

    my ($self, $code, $data) = @_;
    $code //= 0;

    if (!$self->{ Child }) {
        die "cannot call finish on non-child process";
    }

    if (defined $data) {
        store($data, $self->{ Procs }{ $$ });
    }
    exit $code;

}

sub wait_all_children {

    my ($self) = @_;

    my $waited = 0;

    while ($self->{ Num } > 0) {
        my $w = $self->wait_next;
        if ($w != -1) {
            $waited++;
        }
    }

    return $waited;

}

DESTROY {

    my ($self) = @_;

    if ($self->{ Child }) {
        return;
    }

    while (1) {
        my $w = eval { $self->wait_next } // 0;
        last if $w == -1;
    }

    eval { remove_tree($self->{ Tmp }, { safe => 1 }) };

}

1;

=head1 NAME

WWW::Noss::Forker - noss fork manager

=head1 SYNOPSIS

  use WWW::Noss::Forker;

  my $f = WWW::Noss::Forker->new(10);

  FORKLOOP: for my $dl (@downloads) {
      $f->start and next FORKLOOP;
      download($dl);
      $f->finish;
  }

  $f->wait_all_children;

=head1 DESCRIPTION

B<WWW::Noss::Forker> is a module for managing multiple simultaneous forks
easily. It is designed to be a lightweight counterpart to
L<Parallel::ForkManager>. This is a private module, please consult the L<noss>
manual for user documentation.

=head1 METHODS

=over 4

=item $forker = WWW::Noss::Forker->new($forks)

Create a B<WWW::Noss::Forker> object. C<$forks> is the maximum number of
forks to perform.

=item $forker->run_on_finish($subref)

Run C<$subref> upon the exit of a fork. C<$subref> will be given the
following arguments when called:

  0   $pid   PID of terminating process
  1   $exit  Exit status of terminating process
  2   $data  Data passed to $forker->finish(), undef if not present

=item $kid = $forker->wait_next()

Waits for next child to finish running and returns its PID.

=item $pid = $forker->start()

Starts executing next fork. If the maximum number of forks has been reached,
C<$forker> will wait until another fork has been completed.

Returns the PID of the forked process to the parent, and C<0> to the fork.

=item $forker->finish([ $code, [ $data ] ])

Finish and exit the current fork. C<$code> is the code to exit the fork with,
defaults to C<0>. C<$data> is a reference to data to pass to the subroutine
set in C<run_on_finish()>.

=item $waited = $forker->wait_all_children()

Waits for all children to complete. Returns the number of children completed.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung@posteo.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<Parallel::ForkManager>, L<noss>

=cut
