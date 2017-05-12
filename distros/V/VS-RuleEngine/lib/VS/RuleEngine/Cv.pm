package VS::RuleEngine::Cv;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my ($pkg, $cv) = @_;
    my $self = bless $cv, $pkg;
    return $self;
}

1;
__END__

=head1 NAME

VS::RuleEngine::Cv - Base class for objects implemented as a code reference

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( CODE )

Creates a new instance.

=back

=cut
