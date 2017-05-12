package VANAMBURG::StackCard;
use Moose;
extends 'VANAMBURG::Card';

=head1 VANAMBURG::StackCard

An extension of VANAMBURG::Card that adds a stack_number field,
useful for stacks such as memorized decks.

=cut

=head2 stack_number

The location ( 1 through number of cards in packet or deck) where this
card is located in the stack when the stack is ordered.

=cut

has 'stack_number' => ( isa => 'Int', is => 'ro', required => 1 );


1;
