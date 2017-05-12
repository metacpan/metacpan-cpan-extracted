package Tie::Scalar::RingBuffer;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);
our $VERSION = '0.04';

sub _castbool ($) { $_[0] ? 1 : 0 }

sub TIESCALAR {
    my $class = shift;
    my $list = shift;
    my $opts = shift || +{};

    croak "Tie::Scalar::RingBuffer expects a listref" unless @_ == 0 && ref($list) eq 'ARRAY';
    croak "Tie::Scalar::RingBuffer expects a hashref of options" unless ref($opts) eq 'HASH';

    # validate options
    for (keys %$opts){
        /^(?:start_offset|increment|random)$/ or croak "Unrecognized option '$_'";
    }

    if (exists($opts->{'increment'}) && exists($opts->{'random'})){
        croak "options 'increment' and 'random' are mutually exclusive"
    }

    # set defaults
    my $self =  bless +{ _list    => $list,
                         _ix      => 0,
                         _last_ix => 0,
                         _random  => 0,
                         _debug   => 0,
                         _incr    => 1}, $class;

    # apply options
    if (exists $opts->{'random'}){
        $self->{_random} = _castbool ($opts->{'random'});
        $self->start_offset(int rand @{$self->{_list}});
    }
    $self->start_offset ($opts->{'start_offset'}) if exists $opts->{'start_offset'};
    $self->increment ($opts->{'increment'}) if exists $opts->{'increment'};

    $self
}

sub FETCH
{
    my $self = shift;
    print ("FETCH(ix=",$self->{_ix},")\n") if $self->{_debug};
    my ($list,$ix) = ($self->{_list}, $self->{_ix});
    $self->{_ix} = $self->{_random} ?  (rand @$list)
                                    : ($ix + $self->{_incr}) % @$list;
    $self->{_last_ix} = $ix;
    $list->[$ix];
}

sub redo ()
{
    my $self = shift;
    croak "redo expects an object" unless UNIVERSAL::isa($self, __PACKAGE__);
    $self->{_list}->[$self->{_last_ix}]
}

sub STORE
{
    my $self = shift;
    print("STORE(_last_ix=",$self->{_last_ix},")\n") if $self->{_debug};
    $self->{_list}->[$self->{_last_ix}] = shift;
}

sub UNTIE { }
sub DESTROY { }

sub start_offset {
    my $self = shift;
    croak "start_offset() expects an object" unless UNIVERSAL::isa($self,__PACKAGE__);

    if (@_){
        my $start_offset = shift;
        croak "start_offset() expects a numeric offset" unless defined($start_offset) && $start_offset =~ /^[+-]?\d+$/;
        $self->{_ix} = ($start_offset % scalar @{$self->{_list}});
    }
    $self->{_ix};
}

sub increment {
    my $self = shift;
    croak "increment() expects an object" unless UNIVERSAL::isa($self,__PACKAGE__);
    if(@_){
        my $incr = shift;
        croak "increment() expects an integer" unless defined($incr) && $incr =~ /^[+-]?\d+$/;
        $self->{_incr} = $incr;
    }
    $self->{_incr};
}


1;
__END__

=head1 NAME

Tie::Scalar::RingBuffer - Treat a scalar as a ring buffer iterator.

=head1 SYNOPSIS

  use Tie::Scalar::RingBuffer;

  tie $in_order,    'Tie::Scalar::RingBuffer', \@data;
  tie $every_other, 'Tie::Scalar::RingBuffer', \@data, { increment => 2 };
  tie $backwards,   'Tie::Scalar::RingBuffer', \@data, { start_offset => $#data, increment => -1 };
  tie $random,      'Tie::Scalar::RingBuffer', \@data, { random => 1 };


  # Alternate CSS row shading for HTML table rows:
  @css_shades  =  qw(normal_row shaded_row);
  tie $row_shade, 'Tie::Scalar::RingBuffer', \@css_shades;

  foreach (@html_rows) {
      print qq( <tr class="$row_shade"> );
      print qq( <td> $_ </td> ) foreach (@$_);
      print qq( </tr> );
  }

=head1 ABSTRACT

This module ties a $scalar to a @list so that every time you access the
$scalar, you are really accessing the next element in the list. The list is
treated as a ring buffer, so there is no 'end' to the iteration.

=head1 DESCRIPTION

A ring buffer is a queue in which the tail and head are logically connected so
that there is effectively no end to the queue. This modules treats a listref as
a ring buffer, and creates an iterator for that ring buffer. The iteration is
completely hidden; there is no need to call next() method, nor is there an at_end()
method. Every time you access the iterator, you get the I<next> value from
the list. The iterator wraps around at the end of the list (or at the
beginning if you are iterating backwards), and will iterate
forever.

=head1 METHODS

=over

=item tie SCALAR, Tie::Scalar::RingBuffer, LISTREF [, OPTIONS]

Ties I<SCALAR> to I<LISTREF>. Each time I<SCALAR> is accessed, it produces the next
element in I<LISTREF>. You can control how the I<next> element is found by specifying
L</OPTIONS>. Currently, there is no need to call L<untie()>.

Example:

    my @dilemma = qw(she loves me. she loves me not.);
    tie $answer, 'Tie::Scalar::RingBuffer', \@dilemma;
    while (1){
        print "$answer "
    }

which prints, "she loves me. she loves me not. she loves " ... and so on.

The OPTIONS hashref, if present, may contain the following key-value pairs:

=over

=item C<< start_offset => NUM >>

Specifies the the starting point in the list. I<start_offset> is only used when you
tie the list, and is not used afterwards.

default: C<< 0 >>.

=item C<< increment => NUM >>

At each access, I<NUM> is added to the current index to produce the new index.
To iterate backwards, specify C<< increment => -1 >>. If I<increment> is C<0>, you
get the same element every time.

default: C<< 1 >>.

=item C<< random => BOOLEAN >>

If I<BOOLEAN> is true, then you get a random element from the list every time.

default: C<< 0 >>.

=back

=item redo

The redo method produces the same result as the previous FETCH did. If $scalar
is tied, then,

    $x = $scalar;
    $y = tied($scalar)->redo();

leaves $x == $y.

=back

=head1 ASSIGNING VALUES

Assignment (STORE) is performed on the same index that was used for previous
FETCH.  The following is a pathetic attempt to escape one's destiny:

    my @dilemma = qw(she loves me. she loves me not.);
    tie $answer, 'Tie::Scalar::RingBuffer', \@dilemma;
    for (0..$#dilemma){
        $answer = 'so.' if $answer =~ m/not/;
        print tied($answer)->redo(), " ";
    }

The above code has the same effect as:

    $dilemma[6] = 'so.';

=head1 SEE ALSO

See Tie::Array::Iterable for a more complex, C++-style iterator.

=head1 AUTHOR

John Millaway E<lt>millaway@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by John Millaway

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

