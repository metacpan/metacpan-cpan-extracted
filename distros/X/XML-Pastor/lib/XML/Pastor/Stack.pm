use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);


#===============================================
package XML::Pastor::Stack;


our $VERSION = '0.01';

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;

    my $self = [];
    if(@_) {
        push(@{ $self }, @_);
    }

    return bless($self, $class);
}

sub peek {
    my $self = shift();

    return $self->get(0);
}

sub clear {
    my $self = shift();

    $#{ $self } = -1;
}

sub get {
    my $self = shift();
    my $index = shift();

    return $self->[$index];
}

sub count {
    my $self = shift();

    return $#{ $self } + 1;
}

sub empty {
    my $self = shift();

    if($self->count() == 0) {
        return 1;
    }

    return 0;
}

sub pop {
    my $self = shift();

    return shift(@{ $self });
}

sub push {
    my $self = shift();

    unshift(@{ $self }, shift());
}

1;

__END__

=head1 NAME

XML::Pastor::Stack - A Stack!

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 SYNOPSIS

  use XML::Pastor::Stack;
  my $stack = new XML::Pastor::Stack();

=head1 DESCRIPTION

Quite simple, really.  Just a stack implemented via an array.
 
This module is a blunt copy of the L<Data::Stack> module. I had originally intended to use that module
but it turns out that it -superflously- requires perl 5.8.6 to build and I only had perl 5.8.4 on my system
with no means to upgrade. So that's why I had to copy all the code in L<Data::Stack> into this otherwise needless module.

=head1 METHODS

=over 4

=item new( [ @ITEMS ] )

Creates a new XML::Pastor::Stack.  If passed an array, those items are added to the stack.

=item peek()

Returns the item at the top of the stack but does not remove it.

=item get($INDEX)

Returns the item at position $INDEX in the stack but does not remove it.  0 based.

=item count()

Returns the number of items in the stack.

=item empty()

Returns a true value if the stack is empty.  Returns a false value if not.

=item clear()

Completely clear the stack.

=item pop()

Removes the item at the top of the stack and returns it.

=item push($item)

Adds the item to the top of the stack.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

There are various Stack packages out there but none of them seemed simple enough. Here we are!

=head1 AUTHOR

Ayhan Ulusoy <dev(at)ulusoy(dot)name>

The author of the original module L<Data::Stack> is: Cory Watson, E<lt>cpan@onemogin.comE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2006-2007 by Ayhan Ulusoy. (A shame, as the code is copied from Data::Stack by Cory Watson)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
