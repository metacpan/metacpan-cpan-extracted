package Text::KDL::XS::Value;

use strict;
use warnings;

use Carp ();

# A Value is a blessed hashref with these slots:
#   type            : 'null' | 'bool' | 'number' | 'string'
#   kind            : 'integer' | 'float' | 'string'   (only when type=number)
#   value           : underlying scalar (IV/NV/PV) or undef
#   type_annotation : string, optional KDL type tag like "u32"

sub new {
    my ($class, %args) = @_;
    Carp::croak("Text::KDL::XS::Value->new: 'type' is required")
        unless defined $args{type};

    return bless {
        type            => $args{type},
        kind            => $args{kind},
        value           => $args{value},
        type_annotation => $args{type_annotation},
    }, $class;
}

sub type            { $_[0]->{type}            }
sub kind            { $_[0]->{kind}            }
sub type_annotation { $_[0]->{type_annotation} }

sub is_null   { $_[0]->{type} eq 'null'   }
sub is_bool   { $_[0]->{type} eq 'bool'   }
sub is_number { $_[0]->{type} eq 'number' }
sub is_string { $_[0]->{type} eq 'string' }

# Raw underlying scalar (already typed in XS).
sub value { $_[0]->{value} }

# Returns a Perl number suitable for arithmetic when possible.
# Arbitrary-precision integers are still returned as strings; callers
# who need bigint semantics should pass C<as_string> to Math::BigInt.
sub as_number {
    my ($self) = @_;
    return undef if $self->{type} eq 'null';
    return $self->{type} eq 'bool' ? ($self->{value} ? 1 : 0) : $self->{value} + 0
        if $self->{type} ne 'number';
    return $self->{value} if defined $self->{kind} && $self->{kind} ne 'string';
    # string-encoded number - preserve as string-on-the-wire but coerce at use
    return $self->{value};
}

sub as_string {
    my ($self) = @_;
    return undef        if $self->{type} eq 'null';
    return $self->{value} ? 'true' : 'false' if $self->{type} eq 'bool';
    return defined $self->{value} ? "$self->{value}" : undef;
}

# Best-effort native Perl scalar:
#   null    -> undef
#   bool    -> 1/0
#   number  -> IV / NV / string (for arbitrary-precision)
#   string  -> PV
sub as_perl {
    my ($self) = @_;
    my $t = $self->{type};
    return undef           if $t eq 'null';
    return $self->{value} ? 1 : 0 if $t eq 'bool';
    return $self->{value};
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Value - A typed KDL scalar value

=head1 SYNOPSIS

  if    ($v->is_null)   { ... }
  elsif ($v->is_bool)   { ... if $v->as_perl }
  elsif ($v->is_number) {
      if ($v->kind eq 'string') {
          # arbitrary-precision; preserved verbatim
          use Math::BigInt;
          my $big = Math::BigInt->new($v->as_string);
      } else {
          my $n = $v->as_number;
      }
  }
  elsif ($v->is_string) { my $s = $v->as_string }

=head1 DESCRIPTION

Represents a single KDL value (argument or property value) with full
fidelity to ckdl's value model. KDL numbers may be integers, floats, or
arbitrary-precision values represented as strings; this class preserves
the distinction via L</kind>.

=head1 METHODS

=over 4

=item C<type>            - C<'null'>, C<'bool'>, C<'number'>, or C<'string'>

=item C<kind>            - only for numbers: C<'integer'>, C<'float'>, C<'string'>

=item C<value>           - the raw underlying scalar (as ckdl produced it).
For booleans this is C<1>/C<0>; for arbitrary-precision numbers it is the
verbatim string form. For most consumers, C<as_perl> is more convenient.

=item C<type_annotation> - KDL type tag (e.g. C<u32>) or C<undef>

=item C<is_null>, C<is_bool>, C<is_number>, C<is_string>

=item C<as_number> - numeric coercion (returns the original string for
arbitrary-precision integers; pass to L<Math::BigInt> if needed).

=item C<as_string> - string coercion (C<"true">/C<"false"> for booleans,
C<undef> for null).

=item C<as_perl>   - best-effort native Perl scalar:
C<undef> for null, C<1>/C<0> for bool, IV/NV/string for numbers,
PV for strings.

=back

=cut
