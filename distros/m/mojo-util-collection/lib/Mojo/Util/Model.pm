package Mojo::Util::Model;
use Mojo::Base -base;

our $VERSION = '0.0.13';

use Mojo::JSON qw(encode_json);

has 'exists' => sub {
    return shift->pk ? 1 : 0;
};

has 'id';

has 'keys_to_serialize' => sub {
    my $self = shift;

    my @keys = keys(%$self);

    push(@keys, 'exists', 'pk', 'primary_key');

    return \@keys;
};

has 'pk' => sub {
    my $self = shift;

    return $self->get($self->primary_key);
};

has 'primary_key' => 'id';

=head2 get

Returns the value of a field.

=cut

sub get {
    my ($self, $field, $default) = @_;

    my $value = undef;
    $default //= undef;

    my @pieces = split(/\./, $field);

    if (scalar(@pieces) > 1) {
        $field = shift @pieces;

        if ($self->can($field)) {
            if (ref($self->$field) eq 'HASH') {
                my $tmp = $self->$field;

                while (ref($tmp)  eq 'HASH') {
                    $field = shift @pieces;
                    $tmp = $tmp->{ $field };
                }

                return $tmp || $default;
            }

            return $self->$field->get(join('.', @pieces), $default);
        }

        return $default;
    }

    if ($self->can($field)) {
        $value = $self->$field;
    } else {
        $value = $self->{ $field } if (exists $self->{ $field });
    }

    return $value // $default;
}

=head2 serialize

Returns a hashref representation of the model.

=cut

sub serialize {
    my $self = shift;

    my @fields = @_;

    if (!scalar(@fields)) {
        @fields = @{ $self->keys_to_serialize };
    }

    my $result = {};

    $result->{ $_ } = $self->get($_) for (@fields);

    return $result;
}

=head2 toCsv

Returns a CSV representation of the model.

=cut

sub toCsv {
    my ($self, $columns, $options) = @_;

    my $default = defined($options->{ default }) ? $options->{ default } : 'n/a';
    my $quote_char = $options->{ quote_char } // '"';

    my @array;

    foreach my $column (@$columns) {
        push(@array, sprintf('%s%s%s', $quote_char, $self->get($column, $default), $quote_char));
    }

    return join(',', @array);
}

=head2 toJson

Returns a JSON representation of the model.

=cut

sub toJson {
    return encode_json(shift->serialize);
}

=head2 AUTOLOAD

Try to get a field from the model or die.

=cut

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $field = $AUTOLOAD =~ /::(\w+)$/ ? $1 : undef;

    $field =~ s/.*:://;
    return unless $field =~ /[^A-Z]/; # skip DESTROY and all-cap methods

    return $self->get($field) if (exists $self->{ $field });

    die "Undefined method $AUTOLOAD";
}

1;
