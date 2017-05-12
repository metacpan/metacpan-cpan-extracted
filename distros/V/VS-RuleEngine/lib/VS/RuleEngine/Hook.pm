package VS::RuleEngine::Hook;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my $self = shift;
    $self = ref $self || $self;
    croak "new() should not be called as a function" if !$self;
    croak "Class '$self' does not override new()";
}

sub invoke {
    my $self = shift;
    $self = ref $self || $self;
    croak "invoke() should not be called as a function" if !$self;
    croak "Class '$self' does not override invoke()";
}

1;
__END__

=head1 NAME

VS::RuleEngine::Hook - Interface for hooks.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new 

Called when a new instance is requested.

=back

=head2 INSTANCE METHODS

=over 4

=item invoke

Runs the hook. Must return KV_ABORT (to abort processing) or KV_CONTINUE. 

For arguments passed to this method see L<VS::RuleEngine::Constants/Arguments>.

=cut