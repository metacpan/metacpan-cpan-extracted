package WebService::OverheidIO::BAG;
our $VERSION = '1.1';
# ABSTRACT: Query Overheid.IO/BAG via their API

use Moose;
extends 'WebService::OverheidIO';

sub _build_type {
    return 'bag';
}

sub _build_fieldnames {
    my $self = shift;

    return [qw(
        openbareruimtenaam
        huisnummer
        huisnummertoevoeging
        huisletter
        postcode
        woonplaatsnaam
        gemeentenaam
        provincienaam
        locatie
    )];
}

sub _build_queryfields {
    my $self = shift;
    # Be aware that we return an empty array (ref) due to bugs on the OverheidIO side.
    # If used you will get a 500 server error.
    return [];
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OverheidIO::BAG - Query Overheid.IO/BAG via their API

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use WebService::OverheidIO::BAG;
    my $overheidio = WebService::OverheidIO::BAG->new(
        key => "your developer key",
    );

=head1 DESCRIPTION

Query the Overheid.io BAG endpoints. BAG stands for Basis Administratie
Gebouwen.

=head1 SEE ALSO

L<WebService::OverheidIO>

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mintlab BV.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
