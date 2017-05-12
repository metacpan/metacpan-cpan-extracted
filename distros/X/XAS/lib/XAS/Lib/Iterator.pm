package XAS::Lib::Iterator;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'blessed dotid',
  constants => 'ARRAY HASH DELIMITER CODE',
  constant => {
    SELF  => 0,
    DATA  => 0,
    SIZE  => 1,
    INDEX => 2,
  },
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub new {
    my $class = shift;
    my $data  = shift || [];

    my $ref = ref($data);

    if ($ref eq HASH) {

        $data = [
            map {{ key => $_, value => $data->{$_} }} sort keys %$data
        ];

    } elsif (blessed($data) && $data->can('as_list')) {

        $data = $data->as_list();

    } elsif ($ref ne ARRAY) {

        $data = [sort(split(DELIMITER, $data))];

    }

    return bless [$data, scalar @$data, -1], $class;

}

sub index {

    if (defined($_[1])) {

        if (($_[1] > 0) && ($_[1] <= $_[SELF]->[SIZE])) {

            $_[SELF]->[INDEX] = $_[1] - 1;
            return 1;

        } else {

            return undef;

        }

    } else {

        return $_[SELF]->[INDEX];

    }

}

sub count {
    $_[SELF]->[SIZE];
}

sub first {
    $_[SELF]->[INDEX] = 0;
}

sub last {
    $_[SELF]->[INDEX] = $_[SELF]->[SIZE] - 1;
}

sub prev {
    $_[SELF]->[INDEX] < 1
      ? undef
      : $_[SELF]->[DATA]->[ --$_[SELF]->[INDEX] ];
}

sub next {
    $_[SELF]->[INDEX] >= $_[SELF]->[SIZE]
      ? undef
      : $_[SELF]->[DATA]->[ ++$_[SELF]->[INDEX] ];
}

sub find {

    my $left = 0;
    my $right = $_[SELF]->[SIZE] - 1;
    my $callback = $_[1] || undef;

    if (defined($callback) && (ref($callback) eq CODE)) {

        return _bsearch($_[SELF], $left, $right, $callback);

    } else {

        $_[SELF]->throw_msg(
            dotid($_[SELF]->class) . '.find',
            'invparams',
            'parameter 1 needs to be a code reference',
        );

    }

}

sub item {
    $_[SELF]->[INDEX] >= 0 && $_[SELF]->[INDEX] < $_[SELF]->[SIZE]
      ? $_[SELF]->[DATA]->[ $_[SELF]->[INDEX] ]
      : undef;
}

sub items {
    my $self = shift;

    if ($self->[INDEX] < 0) {

        $self->[INDEX] = $self->[SIZE]; 
        return $self->[DATA];

    } else {

        my $data  = $self->[DATA];
        my $slice = [
            @$data[ $self->[INDEX] .. $self->[SIZE] - 1 ]
        ];

        $self->[INDEX] = $self->[SIZE];
        return $slice;

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _bsearch {
    my $self    = shift;
    my $left    = shift;
    my $right   = shift;
    my $compare = shift;

    if ($right < $left) {

        return -1;

    }

    my $mid  = ($left + $right) >> 1;
    my $item = $self->[DATA]->[$mid];
    my $x    = $compare->($item);

    if ($x > 0) {

        return _bsearch($self, $mid + 1, $right, $compare);

    } elsif ($x < 0) {

        return _bsearch($self, $left, $mid - 1, $compare);

    } else {

        return $mid + 1;

    }

}

1;

__END__

=head1 NAME

XAS::Lib::Iterator - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Iterator;

 my @data = ['test1', 'test2', 'test3', 'test4'];
 
 my $iterator = XAS::Lib::Iterator->new(@data);

 while (my $item = $iterator->next) {

     printf("item: %s\n", $item);

 }

=head1 DESCRIPTION

This is a general purpose iterator for an array of items. Once the items are 
composed, you can then transverse over them and return items.

=head1 METHODS

=head2 new($items);

Initialize the object and process the supplied items.

=over 4

=item B<$items>

If the item is a blessed object with a as_list() method, then what is returned
from that call is used. 

If the item is a hash, it will be decomposed into an array of hashes
with the fields "key" and "value". Where "key" is the orignal key and "value" 
is the original value. The items will be sorted by the key.

And lastly, you can use a delimited string. The delimiter can be white space
or commas. This will be split into an array of sorted items.

Sorting is done by Perls builtin sort function.

=back

=head2 count

Return the number of items.

=head2 first

Set the index to the first item.

=head2 last

Set the index to the last item.

=head2 index($position)

Return or set the current position of the index.

=over 4

=item B<$position>

The optional position within the index. This is ones based.

=back

=head2 find($callback)

This method will find an item within the items. It will return the position
in the index or -1.

=over 4

=item B<$callback>

The comparison routine. It is passed an item for comparision. The routine
should return the following:

=over 4

=item *  1 if the item is greater then what is wanted.

=item * -1 if the item is lesser then what is wanted.

=item *  0 if they match.

=back

=back

=head2 next

Return the next item and increment the index.

=head2 prev

Return the previous item and decrements the index.

=head2 item

Return the item at the current index position.

=head2 items

Return a slice of the items from the current index position to the end.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
