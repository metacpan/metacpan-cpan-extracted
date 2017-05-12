package MultiTask::Minion;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use Class::Accessor::Classy;
rw 'on_quit';
rs 'done' => \(my $set_done);
no  Class::Accessor::Classy;

=head1 NAME

MultiTask::Minion - a worker

=head1 SYNOPSIS

=cut


=head2 new

  my $worker = MultiTask::Minion->new();

=cut

sub new {
  my $class = shift;
  my $self = {};

  my $new_class = "$self";
  {
    $new_class =~ s/HASH\(([^\)]*)\)/${class}::$1/ or
      croak("cannot transform $self into a package");
    my $isa = do { no strict 'refs'; \@{"${new_class}::ISA"}; };
    push(@$isa, $class); # You're one of us now...
  }

  bless($self, $new_class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 make

Creates a new minion class, defining work() and other methods inline.

  my $worker = MultiTask::Minion->make(sub {
    return(work => sub {...})
  });

=cut

sub make {
  my $package = shift;
  my ($subref) = @_;
  ((ref($subref) || '') eq 'CODE') or croak("not a code reference");

  my $self = $package->new;
  my %atts = $subref->($self);
  foreach my $att ($self->_standard_attributes) {
    if($atts{$att}) {
      $self->_make_method($att, delete($atts{$att}));
    }
  }
  keys(%atts) and
    croak("unsupported attributes ", join(", ", keys(%atts)));
  return($self);
} # end subroutine make definition
########################################################################

=head2 _standard_attributes

  $self->_standard_attributes;

=cut

sub _standard_attributes {
  my $self = shift;
  return(qw(
    start
    work
    finish
    quit
  ));
} # end subroutine _standard_attributes definition
########################################################################

=head2 _make_method

  $self->_make_method($name, $subref);

=cut

sub _make_method {
  my $self = shift;
  my ($name, $subref) = @_;
  ($name =~ m/^[a-z_][\w]*$/i) or croak("'$name' not a valid name");

  my $class = ref($self);
  ($class =~ m/::0x/) or croak("'$class' is invalid");

  if(my $super_sub = $class->can($name)) {
    no strict 'refs';
    *{$class . '::SUPER_' . $name} = $super_sub;
  }

  no strict 'refs';
  defined(&{$class . '::' . $name}) and croak("cannot overwrite $name");
  *{$class . '::' . $name} = $subref;
} # end subroutine _make_method definition
########################################################################

=head1 Control

=head2 quit

  $minion->quit;

=cut

sub quit {
  my $self = shift;

  if(my $on_quit = $self->on_quit) {
    $on_quit->($self);
  }
  my $class = ref($self);
  if($class =~ m/::0x/) { # delete our methods
    foreach my $att ($self->_standard_attributes) {
      no strict 'refs';
      if(defined(&{$class . '::' . $att})) {
        delete(${$class . '::'}{$att});
      }
    }
  }
  $self->$set_done(1);
} # end subroutine quit definition
########################################################################

=head2 DESTROY

  $minion->DESTROY;

=cut

sub DESTROY {
  my $self = shift;
  #warn "destroy $self\n";
  delete($self->{$_}) for(keys(%$self));
  if(1) { # cleanup namespace
    my $package = ref($self);
    $package =~ m/^(.*::)([^:]+)$/ or die;
    my $parent = $1;
    my $inner = $2 . '::';
    # don't kill-off permanent packages!
    # TODO use something that's not pattern-based?
    ($inner =~ m/^0x/) or return; # warn "not destroying $package";
    my $pack;
    {
      no strict 'refs';
      $parent = \%{"$parent"};
      #$innerp = \%{"$inner"};
      $pack   = \%{"${package}::"};
    }
    #warn join(",", keys(%$parent));
    #warn join(",", keys(%$pack));
    #warn join(",", keys(%{$parent->{$inner}}));
    delete($parent->{$inner});
    #warn join(",", keys(%$parent));
  }
  return;
} # end subroutine DESTROY definition
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
