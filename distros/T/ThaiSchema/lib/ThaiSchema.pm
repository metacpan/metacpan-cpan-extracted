package ThaiSchema;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.10';
use parent qw/Exporter/;

our $STRICT = 0;
our $ALLOW_EXTRA = 0;
our @_ERRORS;
our $_NAME = '';

our @EXPORT = qw/
    match_schema
    type_int type_str type_number type_hash type_array type_maybe type_bool type_null
/;

use JSON;
use B;
use Data::Dumper;

use Scalar::Util qw/blessed/;

sub match_schema {
    local @_ERRORS;
    local $_NAME = '';
    my $ok = _match_schema(@_);
    return wantarray ? ($ok, \@_ERRORS) : $ok;
}

sub _match_schema {
    my ($value, $schema) = @_;
    if (ref $schema eq 'HASH') {
        $schema = ThaiSchema::Hash->new(schema => $schema);
    }
    if (blessed $schema && $schema->can('match')) {
        if ($schema->match($value)) {
            return 1;
        } else {
            if ($schema->error) {
                push @_ERRORS, $_NAME .' '. $schema->error();
            }
            return 0;
        }
    } else {
        die "Unsupported schema: " . ref $schema;
    }
}

sub type_str() {
    ThaiSchema::Str->new();
}

sub type_int() {
    ThaiSchema::Int->new();
}

sub type_maybe($) {
    ThaiSchema::Maybe->new(schema => shift);
}

sub type_number() {
    ThaiSchema::Number->new();
}

sub type_hash($) {
    ThaiSchema::Hash->new(schema => shift);
}

sub type_array(;$) {
    ThaiSchema::Array->new(schema => shift);
}

sub type_bool() {
    ThaiSchema::Bool->new()
}

sub type_null() {
    ThaiSchema::Null->new()
}

package ThaiSchema::Extra;
# dummy object for extra key.
use parent qw/ThaiSchema::Base/;

sub is_array   { 1 }
sub is_hash    { 1 }
sub is_bool    { 1 }
sub is_number  { 1 }
sub is_integer { 1 }
sub is_null    { 1 }
sub is_string  { 1 }

sub schema { ThaiSchema::Extra->new() }

package ThaiSchema::Hash;

use parent qw/ThaiSchema::Base/;

sub schema {
    my ($self) = @_;
    return $self->{schema};
}

sub match {
    my ($self, $value) = @_;
    return 0 unless ref $value eq 'HASH';

    my $schema = $self->{schema};

    my $fail = 0;
    my %rest_keys = map { $_ => 1 } keys %$value;
    for my $key (keys %$schema) {
        local $_NAME = $_NAME ? "$_NAME.$key" : $key;
        if (not ThaiSchema::_match_schema($value->{$key}, $schema->{$key})) {
            $fail++;
        }
        delete $rest_keys{$key};
    }
    if (%rest_keys && !$ThaiSchema::ALLOW_EXTRA) {
        push @_ERRORS, 'have extra keys';
        return 0;
    }
    return !$fail;
}

sub error {
    return ();
}

sub is_hash { 1 }

package ThaiSchema::Array;
use parent qw/ThaiSchema::Base/;

sub is_array { 1 }

sub schema { shift->{schema} }

sub match {
    my ($self, $value) = @_;
    return 0 unless ref $value eq 'ARRAY';
    my $schema = $self->{schema};
    if (defined $schema) {
        for (my $i=0; $i<@{$value}; $i++) {
            local $_NAME = $_NAME . "[$i]";
            my $elem = $value->[$i];
            return 0 unless ThaiSchema::_match_schema($elem, $schema);
        }
    }
    return 1;
}

sub error {
    return ();
}

package ThaiSchema::Maybe;
use parent qw/ThaiSchema::Base/;

sub match {
    my ($self, $value) = @_;
    return 1 unless defined $value;
    return $self->{schema}->match($value);
}
sub error { "is not maybe " . $_[0]->{schema}->name }

sub name {
    return 'Maybe[' . $_[0]->{schema}->name .']';
}

sub is_null { 1 }

for my $method (qw/is_array is_bool is_hash is_number is_integer is_string/) {
    no strict 'refs';
    *{__PACKAGE__ . "::$method"} = sub { $_[0]->{schema}->$method() };
}
sub schema {
    my ($self) = @_;
    return $self->{schema};
}

package ThaiSchema::Str;
use parent qw/ThaiSchema::Base/;

sub match {
    my ($self, $value) = @_;
    return 0 unless defined $value;
    if ($ThaiSchema::STRICT) {
        my $b_obj = B::svref_2object(\$value);
        my $flags = $b_obj->FLAGS;
        return 0 if $flags & ( B::SVp_IOK | B::SVp_NOK ) and !( $flags & B::SVp_POK ); # SvTYPE is IV or NV?
        return 1;
    } else {
        return not ref $value;
    }
}
sub error { "is not str" }
sub is_string { 1 }

package ThaiSchema::Int;
use parent qw/ThaiSchema::Base/;
sub match {
    my ($self, $value) = @_;
    return 0 unless defined $value;
    if ($ThaiSchema::STRICT) {
        my $b_obj = B::svref_2object(\$value);
        my $flags = $b_obj->FLAGS;
        return 1 if $flags & ( B::SVp_IOK | B::SVp_NOK ) and int($value) == $value and !( $flags & B::SVp_POK ); # SvTYPE is IV or NV?
        return 0;
    } else {
        return $value =~ /\A(?:[1-9][0-9]*|0)\z/;
    }
}
sub error { "is not int" }
sub is_number { 1 }
sub is_integer { 1 }

package ThaiSchema::Number;
use parent qw/ThaiSchema::Base/;
use Scalar::Util ();
sub is_number { 1 }
sub match {
    my ($self, $value) = @_;
    return 0 unless defined $value;
    if ($ThaiSchema::STRICT) {
        my $b_obj = B::svref_2object(\$value);
        my $flags = $b_obj->FLAGS;
        return 1 if $flags & ( B::SVp_IOK | B::SVp_NOK ) and !( $flags & B::SVp_POK ); # SvTYPE is IV or NV?
        return 0;
    } else {
        return Scalar::Util::looks_like_number($value);
    }
}
sub error { 'is not number' }

package ThaiSchema::Bool;
use parent qw/ThaiSchema::Base/;
sub is_bool { 1 }
use JSON;
sub match {
    my ($self, $value) = @_;
    return 0 unless defined $value;
    return 1 if JSON::is_bool($value);
    return 1 if ref($value) eq 'SCALAR' && ($$value eq 1 || $$value eq 0);
    return 0;
}
sub error { 'is not bool' }

package ThaiSchema::Null;
use parent qw/ThaiSchema::Base/;
sub is_null { 1 }
sub match {
    die "Not implemented.";
}
sub error { 'is not null' }

1;
__END__

=encoding utf8

=head1 NAME

ThaiSchema - Lightweight schema validator

=head1 SYNOPSIS

    use ThaiSchema;

    match_schema({x => 3}, {x => type_int});

=head1 DESCRIPTION

ThaiSchema is a lightweight schema validator.

=head1 FUNCTIONS

=over 4

=item C<< type_int() >>

Is it a int value?

=item C<< type_str() >>

Is it a str value?

=item C<< type_maybe($child) >>

Is it maybe a $child value?

=item C<< type_hash(\%schema) >>

    type_hash(
        {
            x => type_str,
            y => type_int,
        }
    );

Is it a hash contains valid keys?

=item C<< type_array() >>

    type_array(
        type_hash({
            x => type_str,
            y => type_int,
        })
    );

=item C<< type_bool() >>

Is it a boolean value?

This function allows only JSON::true, JSON::false, C<\1>, and C<\0>.

=back

=head1 OPTIONS

=over 4

=item $STRICT

You can check a type more strictly.

This option is useful for checking JSON types.

=item $ALLOW_EXTRA

You can allow extra key in hashref.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
