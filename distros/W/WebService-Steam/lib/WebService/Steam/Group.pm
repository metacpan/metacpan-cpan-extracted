package WebService::Steam::Group;

use Moose;

use overload '""' => sub { $_[0]->name };

has    name => ( is => 'ro', isa => 'Str', init_arg => 'groupName' );
has summary => ( is => 'ro', isa => 'Str' );

sub path { "http://steamcommunity.com/@{[ $_[1] =~ /^\d+$/ ? 'gid' : 'groups' ]}/$_[1]/memberslistxml" }

__PACKAGE__->meta->make_immutable;

1;
 
=head1 NAME

WebService::Steam::User

=head1 ATTRIBUTES

=head2 name

A string of the name of the group.

=head2 summary

A string of the summary of the group.