package Test::VS::RuleEngine::Output;

use strict;
use warnings;

use Carp qw(croak);

use base qw(VS::RuleEngine::Output);

sub new {
    my ($pkg, %args) = @_;
    my $self = bless { %args }, $pkg;
    return $self;
}

1;
__END__

=head1 NAME

Test::VS::RuleEngine::Output - Test output class

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new

Creates a new instace.

=back

=cut