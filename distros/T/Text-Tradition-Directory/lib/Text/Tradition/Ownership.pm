package Text::Tradition::Ownership;

use strict;
use warnings;
use Moose::Role;
use Text::Tradition::User;

requires 'throw';

=head1 NAME

Text::Tradition::Ownership - add-on role to enable Text::Tradition objects
to have users who own them.

=head1 METHODS

=head2 user

Accessor for the owner of the tradition.

=head2 public

Whether this tradition should be accessible (readonly) to anyone who is not
the owner.

=cut

has 'user' => (
    is => 'rw',
    isa => 'Text::Tradition::User',
    required => 0,
    predicate => 'has_user',
    clearer => 'clear_user',
    weak_ref => 1
    );

has 'public' => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => sub { 0; },
    );

    
1;

