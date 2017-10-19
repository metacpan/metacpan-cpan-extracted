package WebService::OverheidIO::KvK;
our $VERSION = '1.1';
# ABSTRACT: Query Overheid.IO/OpenKVK via their API
#
use Moose;
extends 'WebService::OverheidIO';

sub _build_type {
    return 'kvk';
}

sub _build_fieldnames {
    my $self = shift;
    return [qw(
        dossiernummer
        handelsnaam
        huisnummer
        huisnummertoevoeging
        plaats
        postcode
        straat
        vestigingsnummer
    )];

}

sub _build_queryfields {
    my $self = shift;
    return [qw(
        dossiernummer
        handelsnaam
        vestigingsnummer
        subdossier
    )];
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OverheidIO::KvK - Query Overheid.IO/OpenKVK via their API

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use WebService::OverheidIO::KvK;
    my $overheidio = WebService::OverheidIO::KvK->new(
        key => "your developer key",
    );

=head1 DESCRIPTION

Query the Overheid.io KvK endpoints. Also known as OpenKvK

=head1 SEE ALSO

L<WebService::OverheidIO>

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mintlab BV.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
