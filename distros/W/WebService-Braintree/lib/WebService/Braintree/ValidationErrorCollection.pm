package WebService::Braintree::ValidationErrorCollection;
$WebService::Braintree::ValidationErrorCollection::VERSION = '1.1';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ValidationError

=head1 PURPOSE

This class represents a collection of validation errors.

=cut

use Moose;
use WebService::Braintree::ValidationError;

=head1 CLASS METHODS

This class is B<NOT> an interface, so it does B<NOT> have any class methods.

=cut

=head1 OBJECT METHODS

=cut

sub BUILD {
    my ($self, $args) = @_;

    $self->{_errors} = [ map { WebService::Braintree::ValidationError->new($_) } @{$args->{errors}} ];
    $self->{_nested} = {};

    while (my ($key, $value) = each %$args) {
        next if $key eq 'errors';
        $self->{_nested}->{$key} = __PACKAGE__->new($value);
    }
}

=head2 deep_errors()

This returns a list of the errors for the underlying validation failures.

=cut

has 'deep_errors' => (is => 'ro', lazy => 1, builder => '_deep_errors');
sub _deep_errors {
    my $self = shift;
    my @nested = map { @{$_->deep_errors} } values %{$self->{_nested}};
    return [ @{$self->{_errors}}, @nested ];
}

=head2 for()

This takes a target and returns a ValidationErrorCollection for that value (if
it exists).

=cut

sub for {
    my ($self, $target) = @_;
    return $self->{_nested}->{$target};
}

=head2 on()

This takes an attribute and returns an arrayref of the L<ValidationErrors|WebService::Braintree::ValidationError/> for that attribute. If there aren't any, then
this will return an empty arrayref.

=cut

sub on {
    my ($self, $attribute) = @_;
    return [ grep { $_->attribute eq $attribute } @{$self->{_errors}} ]
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document what the attributes actually mean.

=back

=cut
