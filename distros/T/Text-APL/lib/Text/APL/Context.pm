package Text::APL::Context;

use strict;
use warnings;

use base 'Text::APL::Base';

use Digest::MD5 ();

sub _BUILD {
    my $self = shift;

    $self->{vars}    ||= {};
    $self->{helpers} ||= {};
}

sub id {
    my $self = shift;

    my $id = '';

    $id .= join ':', sort keys %{$self->{vars}};
    $id .= ',';
    $id .= join ':', sort keys %{$self->{helpers}};

    return Digest::MD5::md5_hex($id);
}

sub name    { $_[0]->{name} || '' }
sub vars    { $_[0]->{vars} }
sub helpers { $_[0]->{helpers} }

sub add_helper {
    my $self = shift;

    $self->add('helpers', @_);
}

sub add_var {
    my $self = shift;

    $self->add('vars', @_);
}

sub add {
    my $self = shift;
    my ($type, $key, $value) = @_;

    $self->{$type}->{$key} = $value;
}

1;
__END__

=pod

=head1 NAME

Text::APL::Context - value object

=head1 DESCRIPTION

Used internally for passing variables and helpers to the template.

=head1 METHODS

=head2 C<new>

    my $template = Text::APL::Context->new;

Create new L<Text::APL::Context> instance.

=head2 C<vars>

Returns variables.

=head2 C<helpers>

Returns helpers.

=cut
