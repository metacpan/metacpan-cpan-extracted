package VS::RuleEngine::Action;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my $self = shift;
    $self = ref $self || $self;
    croak "new() should not be called as a function" if !$self;
    croak "Class '$self' does not override new()";
}

sub perform {
    my $self = shift;
    $self = ref $self || $self;
    croak "perform() should not be called as a function" if !$self;
    croak "Class '$self' does not override perform()";
}

1;
__END__

=head1 NAME

VS::RuleEngine::Action - Interface for actions.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new 

Called when a new instance is requested.

=back

=head2 INSTANCE METHODS

=over 4

=item perform

Runs the action. 

For arguments passed to this method see L<VS::RuleEngine::Constants/Arguments>.

=back

=cut