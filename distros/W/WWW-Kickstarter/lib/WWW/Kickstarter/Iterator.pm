
package WWW::Kickstarter::Iterator;

use strict;
use warnings;
no autovivification;


sub _done { () }


sub new {
   my ($class, $generator, $buf) = @_;
   my $self = bless({}, $class);
   $self->{generator} = $generator || \&_done;
   $self->{buf      } = $buf       || [];
   return $self;
}


sub get {
   my ($self, $n) = @_;
   $n ||= 1;

   my $buf = $self->{buf};
   while (@$buf < $n) {
      my @add = $self->{generator}->()
         or do {
            $self->{generator} = \&_done;
            last;
         };

      push @$buf, @add;
   }

   return splice(@$buf, 0, $n);
}


sub get_rest {
   my ($self) = @_;

   my $buf = $self->{buf};
   while (my @add = $self->{generator}->()) {
      push @$buf, @add;
   }

   $self->{generator} = \&_done;
   return splice(@$buf, 0, $#$buf);
}


sub get_chunk {
   my ($self, $min) = @_;
   $min ||= 1;

   my $buf = $self->{buf};
   while (@$buf < $min) {
      my @add = $self->{generator}->()
         or do {
            $self->{generator} = \&_done;
            last;
         };

      push @$buf, @add;
   }

   return splice(@$buf, 0, $#$buf);
}


1;


__END__

=head1 NAME

WWW::Kickstarter::Iterator - Simple lazy lists


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $iter = WWW::Kickstarter::Iterator->new(\&fetcher);

   while (my ($item) = $iter->get()) {
      ...
   }


=head1 DESCRIPTION

Provides a means of iterating over Kickstarter results without doing more web queries than necessary.


=head1 CONSTRUCTOR

=head2 new

   my $iter = WWW::Kickstarter::Iterator->new();
   my $iter = WWW::Kickstarter::Iterator->new(\&generator);
   my $iter = WWW::Kickstarter::Iterator->new(\&generator, \@pre_generated);

Creates a lazy list iterator.

C<$generator> is a reference to a subroutine which generates the next item of the list.
It may return more than one item if it is convenient for it to do so.
Returning an empty list signifies the end of the list.

C<$generator> may be undefined if the pre-generated items define the list in its entirety.


=head1 METHODS

=head2 get

   my $done = my ($item) = $iter->get();
   my $done = my @items = $iter->get($n);

Returns the next item in the list. If an argument is provided, returns that many items instead.
If fewer than the requested number of items are are available, all remaining items are returned.
If no more items are available, an empty list is returned.


=head2 get_rest

   my @items = $iter->get_rest();

Returns the remaining items of the list, if any.


=head2 get_chunk

   my $done = my @items = $iter->get_chunk();
   my $done = my @items = $iter->get_chunk($min);

This method is similar C<get>, except it will return extra items if it is cheap to do so
(i.e. if they have already been generated). This is useful if you have an iterator with
expensive an generator (such as every iterator returned by WWW::Kickstarter) and if you
don't care exactly how many items you get back.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
