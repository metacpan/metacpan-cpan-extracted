package MultiTask::Manager;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


=head1 NAME

MultiTask::Manager - work a group of minions until they are dead

=head1 SYNOPSIS

  my $man = MultiTask::Manager->new;
  $man->set_on_add(sub {...});
  ...
  $man->add($worker);

  if($man->has_work) {
    $man->work;
  }

=cut

use Class::Accessor::Classy;
with 'new';
rs has_work => \(my $set_has_work);
rw 'on_add';
no  Class::Accessor::Classy;

=head1 Constructor

=head2 new

  my $man = MultiTask::Manager->new(
    on_add => sub {
      my ($self, $minion) = @_;
    },
  );

=cut

sub new {
  my $package = shift;
  my $self = $package->SUPER::new(
    @_,
    block   => {},
    minions => [],
    queue   => 0,
    );
  return($self);
} # end subroutine new definition
########################################################################

=head1 Minion Management

=head2 add

  $minion = $man->add($minion);

=cut

sub add {
  my $self = shift;
  my ($minion) = @_;

  unless($minion->can('work')) {
    # TODO $minion->init ?
    confess("lazy minion");
  }
  $minion->set_on_quit(sub {
    $self->remove($minion);
  });
  my $minions = $self->{minions};
  push(@$minions, $minion);

  if(my $on_add = $self->on_add) {
    $on_add->($self, $minion);
  }
  $self->$set_has_work(scalar(@$minions));

  if($minion->can('start')) {
    $minion->start;
  }

  return($minion);
} # end subroutine add definition
########################################################################

=head2 remove

  $man->remove($minion);

=cut

sub remove {
  my $self = shift;
  my ($minion) = @_;

  # XXX we set an onquit, so is it valid to call this externally?

  # clean the minions and the queue
  my $minions = $self->{minions};
  for(my $i = 0; $i < @$minions; $i++) {
    if($minions->[$i] == $minion) {
      splice(@$minions, $i, 1);
      $self->{queue}-- if($i > $self->{queue});
      last;
    }
  }
  #warn "this leaves ", scalar(@$minions), ' minions';
  # delete in case the hash address gets reused
  delete($self->{block}{$minion});
  $minion->DESTROY;
  $self->$set_has_work(scalar(@$minions));
} # end subroutine remove definition
########################################################################

=head1 Getting Work Done

=head2 work

  $man->work;

=cut

sub work {
  my $self = shift;
  my $minions = $self->{minions};
  $self->{queue} = 0 if($self->{queue} >= @$minions);
  my $minion = $minions->[$self->{queue}];
  $self->{queue}++;
  # in Wx, a minion might double up on itself
  # TODO make this allow both all-blocking and single-blocking?
  $self->{block}{$minion} and return;
  $self->{block}{$minion} = 1;
  my @ret = $minion->work;
  # might have removed it while it was working
  $self->{block}{$minion} = 0 if(exists($self->{block}{$minion}));
  (@ret > 1) or return($ret[0]);
  return(@ret);
} # end subroutine work definition
########################################################################

=head2 quit_all

  $man->quit_all;

=cut

sub quit_all {
  my $self = shift;
  my $minions = $self->{minions};
  foreach my $minion (@$minions) {
    $minion->quit;
  }
  $self->{minions} = []; # just in case
} # end subroutine quit_all definition
########################################################################


=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
