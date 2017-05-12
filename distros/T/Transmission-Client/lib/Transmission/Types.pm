# ex:ts=4:sw=4:sts=4:et
package Transmission::Types;
# See Transmission::Client for copyright statement.

=head1 NAME

Transmission::Types - Moose types for Transmission

=head1 DESCRIPTION

The types below is pretty much what you would expect them to be, execpt
for some (maybe weird?) default values - that is for coercion from "Any".

The type names correspond to types used in the Transmission RPC
specification.

=head1 TYPES

=head2 number

=head2 double

=head2 string

=head2 boolean

=head2 array

=cut

use MooseX::Types -declare => [qw/number double string boolean array/];
use MooseX::Types::Moose ':all';
use B;

# If Perl thinks a value is a string, JSON will encode it as such. But
# Transmission is picky about how parameters are encoded in the JSON
# request, so we make sure Perl knows how to store numeric types.
sub _coerce_num {
    local $_ = shift;
    return -1 unless defined $_ and /^[0-9]+(?:\.[0-9]+)?$/;
    return 0+$_;
}

sub _is_num {
    my $sv = shift;
    my $flags = B::svref_2object(\$sv)->FLAGS;

    # Make sure perl internally thinks of $sv as an integer
    # or numeric value. In earlier releases I also made sure that
    # it's not a string ($flags & B::SVp_POK), but POK and
    # (NOK|IOK) seem to be mutually exclusive.
    return $flags & (B::SVp_NOK | B::SVp_IOK);
}

subtype number, as Num, where { _is_num($_) and $_ == int $_};
coerce number, from Any, via { int _coerce_num($_) };

subtype double, as Num, where { _is_num($_) };
coerce double, from Any, via { _coerce_num($_) };

subtype string, as Str;
coerce string, from Any, via { defined $_ ? "$_" : "__UNDEF__" };

type boolean, where { defined $_ and $_ =~ /^(1|0)$/ };
coerce boolean, from Object, via { int $_ };

subtype array, as ArrayRef;
coerce array, from Any, via { [] };

=head1 LICENSE

=head1 NAME

See L<Transmission::Client>

=cut

1;
