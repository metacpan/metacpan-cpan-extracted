package WWW::Scramble::Entry;
use Moose;
use URI;
use WWW::Scramble::Handler;
use HTML::Element;

=head1 NAME

WWW::Scramble::Entry 

=head1 SYNOPSIS

Quick summary of what the module does.

=cut

has title => (is => 'rw', isa => 'HTML::Element');
has content => (is => 'rw', isa => 'HTML::Element');
has _rawdata => ( is => 'rw', isa => 'Str' );
has _handler => (
    is => 'ro', isa => 'WWW::Scramble::Handler', required => 1
);
has URI => (
    is => 'rw', isa => 'URI',
    default => sub { URI->new() }
);

=head2 BUILD

=cut 

sub BUILD {
    my $self = shift;
    $self->_handler->parse($self->_rawdata);
    $self->title ($self->_handler->get_title);
    $self->content ($self->_handler->get_content);
}

sub get_field {
    my ($self) = shift;
    return $self->_handler->get_field(@_);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
