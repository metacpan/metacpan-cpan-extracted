package Mojo::Util::Collection::Formatter;
use Mojo::Base -base;

our $VERSION = '0.0.13';

use Mojo::JSON qw(encode_json);

=head2 asOptions

Return an array ref containing [{ value => $value, label => $label }, ...]

=cut

sub asOptions {
    my ($self, $objects, $value, $label, $value_name, $label_name) = @_;

    $value_name ||= 'value';
    $label_name ||= 'label';
    
    my $options = [map {
        {
            $value_name => $_->get($value),
            $label_name => $_->get($label),
        }
    } @$objects ];

    return $options;
}

=head2 toArray

Convert objects to array ref

=cut

sub toArray {
    my ($self, $objects) = (shift, shift);

    return [map { $_->serialize(@_) } @$objects];
}

=head2 toCsv

Convert objects to CSV string

=cut

sub toCsv {
    my ($self, $objects, $header, $columns, $options) = @_;

    my @array = map { $_->toCsv($columns, $options) } @$objects;

    unshift(@array, $header) if ($header);

    return join("\n", @array);
}

=head2 toJson

Convert collection to JSON string

=cut

sub toJson {
    my $self = shift;

    return encode_json($self->toArray(@_));
}

1;
