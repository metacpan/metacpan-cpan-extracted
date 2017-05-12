package VS::RuleEngine::Input::Perl;

use strict;
use warnings;

use Carp qw(croak);

use base qw(VS::RuleEngine::Cv VS::RuleEngine::Input);

sub value {
    my $self = shift;
    return $self->($self, @_);
}

1;
__END__

=head1 NAME

VS::RuleEngine::Input::Perl - Use a code reference as an input

=cut

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( CODE )

Creates a new instance. The argument I<CODE> must be a reference to a subroutine - either 
anoynmous or named.

=back

=head2 INSTANCE METHODS

=over 4

=item value

Forwards the call to the wrapped subroutine.

=back

=cut
