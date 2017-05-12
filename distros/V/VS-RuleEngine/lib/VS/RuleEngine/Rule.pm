package VS::RuleEngine::Rule;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my $self = shift;
    $self = ref $self || $self;
    croak "new() should not be called as a function" if !$self;
    croak "Class '$self' does not override new()";
}


sub evaluate {
    my $self = shift;
    $self = ref $self || $self;
    croak "evaluate() should not be called as a function" if !$self;
    croak "Class '$self' does not override evaluate()";
}

1;
__END__

=head1 NAME

VS::RuleEngine::Rule - Interface for rules.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new

Called when a new instance is requested.

=back

=head2 INSTANCE METHODS

=over 4

=item evaluate

Evaluates the rule. Must return either KV_MATCH if the rule matched or KV_NO_MATCH if it didn't.

For arguments passed to this method see L<VS::RuleEngine::Constants/Arguments>.

=back
 
=cut
