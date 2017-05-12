package VS::RuleEngine::Input;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my $self = shift;
    $self = ref $self || $self;
    croak "new() should not be called as a function" if !$self;
    croak "Class '$self' does not override new()";
}

sub value {
    my $self = shift;
    $self = ref $self || $self;
    croak "value() should not be called as a function" if !$self;
    croak "Class '$self' does not override value()";
}

1;
__END__

=head1 NAME

VS::RuleEngine::Input - Interface for inputs.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new 

Called when a new instance is requested.

=back

=head2 INSTANCE METHODS

=over 4

=item value

Invoked when a input handler request a value from the instance.

For arguments passed to this method see L<VS::RuleEngine::Constants/Arguments>.

=back

=cut