package UUID::Generator::PurePerl::Compat;

use strict;
use warnings;

our $VERSION = '0.80';

use Exporter;
*import = \&Exporter::import;

our @EXPORT = qw( NameSpace_DNS NameSpace_URL NameSpace_OID NameSpace_X500 );

use Carp;
use UUID::Generator::PurePerl;
use UUID::Object;

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    return $self;
}

sub generator {
    my $self = shift;

    if (! defined $self->{generator}) {
        $self->{generator} = UUID::Generator::PurePerl->new();
    }

    return $self->{generator};
}

sub _generate_v1 {
    my ($self, $type) = @_;

    return $self->generator->generate_v1()->$type();
}

sub create_bin {
    my $self = shift;
    return $self->_generate_v1('as_binary_np', @_);
}
*create = *create_bin;

sub create_str {
    my $self = shift;
    return uc $self->_generate_v1('as_string', @_);
}

sub create_hex {
    my $self = shift;
    return '0x' . uc $self->_generate_v1('as_hex', @_);
}

sub create_b64 {
    my $self = shift;
    return $self->_generate_v1('as_base64_np', @_);
}

sub _generate_v3 {
    my ($self, $type, $ns, $name) = @_;

    $ns = UUID::Object->create_from_binary_np($ns);

    return $self->generator->generate_v3($ns, $name)->$type();
}

sub create_from_name_bin {
    my $self = shift;
    return uc $self->_generate_v3('as_binary_np', @_);
}
*create_from_name = *create_from_name_bin;

sub create_from_name_str {
    my $self = shift;
    return uc $self->_generate_v3('as_string', @_);
}

sub create_from_name_hex {
    my $self = shift;
    return '0x' . uc $self->_generate_v3('as_hex', @_);
}

sub create_from_name_b64 {
    my $self = shift;
    return $self->_generate_v3('as_base64_np', @_);
}


sub to_string {
    my $self = shift;
    return uc UUID::Object->create_from_binary_np(@_)->as_string;
}

sub to_hexstring {
    my $self = shift;
    return '0x' . uc UUID::Object->create_from_binary_np(@_)->as_hex;
}

sub to_b64string {
    my $self = shift;
    return UUID::Object->create_from_binary_np(@_)->as_base64_np;
}

sub from_string {
    my $self = shift;
    return UUID::Object->create_from_string(@_)->as_binary_np;
}

sub from_hexstring {
    my $self = shift;
    my $arg  = shift;

    $arg =~ s{ \A 0x }{}ixmso;

    return UUID::Object->create_from_hex($arg)->as_binary_np;
}

sub from_b64string {
    my $self = shift;
    return UUID::Object->create_from_base64_np(@_)->as_binary_np;
}


sub compare {
    my ($self, $a, $b) = @_;

    $a = UUID::Object->create_from_binary_np($a);
    $b = UUID::Object->create_from_binary_np($b);

    return $a cmp $b;
}


sub NameSpace_DNS {
    return UUID::Object::uuid_ns_dns()->as_binary_np;
}

sub NameSpace_URL {
    return UUID::Object::uuid_ns_url()->as_binary_np;
}

sub NameSpace_OID {
    return UUID::Object::uuid_ns_oid()->as_binary_np;
}

sub NameSpace_X500 {
    return UUID::Object::uuid_ns_x500()->as_binary_np;
}

1;
__END__

=head1 NAME

UUID::Generator::PurePerl::Compat - Compatible interface to Data::UUID

=head1 DESCRIPTION

This module is going to be marked as *DEPRECATED*.

Do not use this module in your applications / modules.

=head1 AUTHOR

ITO Nobuaki E<lt>banb@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
