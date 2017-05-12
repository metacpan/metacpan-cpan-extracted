package VS::RuleEngine::Output;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my $self = shift;
    $self = ref $self || $self;
    croak "new() should not be called as a function" if !$self;
    croak "Class '$self' does not override new()";
}

sub pre_process {
    my $self = shift;
    $self = ref $self || $self;
    croak "pre_process() should not be called as a function" if !$self;
    croak "Class '$self' does not override pre_process()";
}

sub process {
    my $self = shift;
    $self = ref $self || $self;
    croak "process() should not be called as a function" if !$self;
    croak "Class '$self' does not override process()";
}

sub post_process {
    my $self = shift;
    $self = ref $self || $self;
    croak "post_process() should not be called as a function" if !$self;
    croak "Class '$self' does not override post_process()";
}

1;
__END__

=head1 NAME

VS::RuleEngine::Output - Interface for outputs.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new

Called when a new instance is requested.

=back

=head2 INSTANCE METHODS

=over 4

=item pre_process

Currently not used.

For arguments passed to this method see L<VS::RuleEngine::Constants/Arguments>.

=item process

Called after each iteration in the runloop.

For arguments passed to this method see L<VS::RuleEngine::Constants/Arguments>.

=item post_process

Currently not used.

For arguments passed to this method see L<VS::RuleEngine::Constants/Arguments>.

=back

=cut