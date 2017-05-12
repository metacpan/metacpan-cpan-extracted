package List::History;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;


use Carp;
use Class::Accessor;

use base 'Class::Accessor';
{ # accessor/alias setup
  __PACKAGE__->follow_best_practice;
  my @r;
  my @rw = qw(
    current_pos
    );
  __PACKAGE__->mk_accessors(@rw);
  # real method name goes at the end;
  my @alias_table = (
    map({[$_, 'get_' . $_]} @rw, @r),
    [qw(list             get_list)],
    [qw(current          get_current)],
    [qw(f       fore     foreward)],
    [qw(b       back     backward)],
    );

  foreach my $row (@alias_table) {
    my $real = $row->[-1];
    foreach my $alias (@$row[0..($#$row-1)]) {
      no strict 'refs';
      *{$alias} = \&{$real};
    }
  }
} # end accessor/alias setup
########################################################################

########################################################################
# We make a special moment class for each history instance.  This allows
# the history constructor to specify what accessor methods moments have.
my $mk_moment_class;
{
  my $constructor = sub {
    my $package = shift;
    my $class = ref($package) || $package;
    (@_ % 2) and
      croak('Odd number of elements in argument hash');

    my $self = {@_};

    bless($self, $class);
    return($self);
  }; # end subroutine $constructor assignment
  $mk_moment_class = sub {
    my ($class, $moment_spec) = @_;
    use Class::Accessor;
    {
      no strict 'refs';
      *{"${class}::new"} = $constructor;
      @{"${class}::ISA"} = ('Class::Accessor');
    }
    $class->follow_best_practice;
    $class->mk_accessors(keys(%$moment_spec));
    # TODO use moment_spec as an object type map
    foreach my $attr (keys(%$moment_spec)) {
      no strict 'refs';
      *{"${class}::$attr"} = \&{"${class}::get_$attr"};
    }
  };
}
########################################################################

=head1 NAME

List::History - a previous/current/next list of objects

=head1 ABOUT

This is a history list much like what is implemented in most major browsers.

The position pointer could be in one of several states:

    prev   current    next
  -------  -------  --------
     0        0        0       just started
     1        0        0       clicked a new link
     0        1        1       clicked once and went back
     1        1        0       went back (or forward to end)
     1        1        1       went back twice or more

In other words, there is not a current moment unless you C<remember()>
it.  The state is saved I<just before> the user leaves the current page.

=head1 SYNOPSIS

=cut

=head2 new

  my %details = (
    foo => 1, # gives moment foo(), get_foo(), and set_foo()
    bar => 1, # etc.
  );
  my $hist = List::History->new(moment_spec => {%details});

The C<moment_spec> argument defines the attributes for the moment class,
which allows you to use accessors on the stored hashref.  Each moment
class is particular to a given history object.  This is generated for
you by the constructor.  The values in the hash are currently ignored,
but will eventually become some sort of typemap.

=cut

sub new {
  my $package = shift;
  (@_ % 2) and
    croak('Odd number of elements in argument hash');
  my %args = @_;

  my $class = ref($package) || $package;
  my $self = {
    current_pos => -1,
    list        => [],
    };
  $self->{'_moment_class'} = "$self-moment";
  # create the moment class
  $mk_moment_class->($self->{_moment_class}, $args{moment_spec} || {});

  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head1 Moment-Making Methods

=head2 add

Add a moment to the history.  C<$hist-E<gt>has_current> will always be false
after this method is called.

  $hist->add(%moment_data);

=cut

sub add {
  my $self = shift;
  my $moment = $self->moment(@_);

  $self->clear_future;
  my $list = $self->_list;
  push(@$list, $moment);
  # set our pos past the end of the list
  $self->set_current_pos(scalar(@$list));
  return($moment);
} # end subroutine add definition
########################################################################

=head2 remember

Creates a moment and either replaces the current moment or else makes
this one current.  (You'll need to call this before going back.)

  $hist->remember(%moment_data);

=cut

sub remember {
  my $self = shift;
  my $moment = $self->moment(@_);

  my $list = $self->_list;
  if($self->has_current) {
    $list->[$self->current_pos] = $moment;
  }
  else { # could be first or later
    push(@$list, $moment);
    # last item is now current
    $self->set_current_pos($#$list);
  }
  return($moment);
} # end subroutine remember definition
########################################################################

=head1 Boolean Methods

These return true if the history has a moment in the given slot.

=head2 has_current

  my $bool = $hist->has_current;

=cut

sub has_current {
  my $self = shift;

  scalar(@{$self->_list}) or return();
  my $p = $self->current_pos;
  return(($p >= 0) and ($p < scalar(@{$self->_list})));
} # end subroutine has_current definition
########################################################################

=head2 has_next

  my $bool = $hist->has_next;

=cut

sub has_next {
  my $self = shift;

  $self->has_current or return();
  my $p = $self->current_pos;
  return(($p + 1) < scalar(@{$self->_list}));
} # end subroutine has_next definition
########################################################################

=head2 has_prev

  my $bool = $hist->has_prev;

=cut

sub has_prev {
  my $self = shift;

  my $p = $self->current_pos;
  return($p > 0);
} # end subroutine has_prev definition
########################################################################

=head1 Manipulation Methods

=head2 foreward

  my $moment = $hist->foreward;

=cut

sub foreward {
  my $self = shift;

  $self->has_next or croak("has no next item");
  $self->_inc_pos(+1);
  return($self->current);
} # end subroutine foreward definition
########################################################################

=head2 backward

  my $moment = $hist->backward;

=cut

sub backward {
  my $self = shift;

  $self->has_prev or croak("has no prev item");
  $self->_inc_pos(-1);
  return($self->current);
} # end subroutine backward definition
########################################################################

=head2 get_list

  my @list = $hist->get_list;

=cut

sub get_list {
  my $self = shift;
  return(@{$self->_list});
} # end subroutine get_list definition
########################################################################

=head2 get_current

  my $moment = $hist->get_current;

=cut

sub get_current {
  my $self = shift;

  $self->has_current or croak("has no current item");
  return($self->_list->[$self->current_pos]);
} # end subroutine get_current definition
########################################################################

=head2 get_moment

  my $moment = $hist->get_moment($index);

=cut

sub get_moment {
  my $self = shift;
  my ($index) = @_;

  my $list = $self->_list;
  (@$list > $index) or croak("moment $index does not exist");
  return($list->[$index]);
} # end subroutine get_moment definition
########################################################################

=head2 clear_future

This is called automatically by C<add()>.  Clears the current and future item.

  $hist->clear_future;

=cut

sub clear_future {
  my $self = shift;

  $self->has_current or return;
  my $p = $self->current_pos;
  my $list = $self->_list;
  splice(@$list, $p);
  return;
} # end subroutine clear_future definition
########################################################################

=head1 Convenience

=head2 moment

This will typically not be needed since add() and remember() call it for
you.

  my $moment = $self->moment(%moment_data);

=cut

sub moment {
  my $self = shift;
  return($self->{_moment_class}->new(@_));
} # end subroutine moment definition
########################################################################

=head1 Private

=head2 _list

  my $list = $hist->_list;

=cut

sub _list {
  my $self = shift;
  return($self->{list});
} # end subroutine _list definition
########################################################################


=head2 _inc_pos

  $self->_inc_pos($number);

=cut

sub _inc_pos {
  my $self = shift;
  my ($n) = @_;

  (abs($n) == 1) or croak("bad");
  $self->set_current_pos($self->current_pos + $n);
} # end subroutine _inc_pos definition
########################################################################


=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

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
