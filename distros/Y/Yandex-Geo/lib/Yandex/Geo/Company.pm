# ABSTRACT: Convenient representation of company from Yandex Maps

package Yandex::Geo::Company;
$Yandex::Geo::Company::VERSION = '0.02';


use Object::Tiny qw{ name phones links url vk address postalCode };
use JSON::XS;


sub from_geo_json {
    my $feature_collection = shift;

    my @res;

    for my $f ( @{ $feature_collection->features } ) {

        my $company_meta = $f->properties->{CompanyMetaData};

        my $h = {};

        for (qw/id name shortName url address postalCode/) {
            $h->{$_} = $company_meta->{$_};
        }

        push @{ $h->{phones} }, $_->{formatted}
          for ( @{ $company_meta->{Phones} } );
        push @{ $h->{links} }, $_->{href} for ( @{ $company_meta->{Links} } );
        my $vk_link =
          ( grep { $_->{aref} eq '#vkontakte' } @{ $company_meta->{Links} } )
          [0];
        $h->{vk} = $vk_link->{href} if defined $vk_link;

        my $company_obj = __PACKAGE__->new(%$h);

        push @result, $company_obj;

    }

    return \@result;

}


sub from_json {
    my $json_str = shift;

    my $res      = decode_json $json_str;
    my $features = @{ $res->{features} };

    my @result;

    for my $f (@$features) {

        my $company_meta = $f->{properties}{CompanyMetaData};
        my $h            = {};

        for (qw/id name shortName url address postalCode/) {
            $h->{$_} = $company_meta->{$_};
        }

        push @{ $h->{phones} }, $_->{formatted}
          for ( @{ $company_meta->{Phones} } );
        push @{ $h->{links} }, $_->{href} for ( @{ $company_meta->{Links} } );
        my $vk_link =
          ( grep { $_->{aref} eq '#vkontakte' } @{ $company_meta->{Links} } )
          [0];
        $h->{vk} = $vk_link->{href} if defined $vk_link;

        my $company_obj = __PACKAGE__->new(%$h);

        push @result, $company_obj;
    }

    return \@result;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Yandex::Geo::Company - Convenient representation of company from Yandex Maps

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Class that is more convenient realization of company

It has following properties:

    id          # yandex maps id
    name        # name of company, type = string
    shortName   # short name of company, type = string
    url         # website of company, type = string
    phones      # company numbers, type = arrayref
    links       # links to pages on social networks, type = arrayref
    vk          # link to vk, type = arrayref
    address     # location, type = str
    postalCode  # postal code, type = str (6 digits)

Also, this class implements two methods: from_json and from_geo_json

E.g. if you make a query

    my $yndx_geo = Yandex::Geosearch->new( apikey => 'f33a4523-6c94-48df-9b41-5c5c6f250e98');
    my $res = $yndx_geo->get(text => 'макетные мастерские', only_city => 'ROV');

    Yandex::Geo::Company::from_json( $res->to_json )
    
    and
    
    Yandex::Geo::Company::from_geo_json( $res )
    
    do the same.

=head2 from_geo_json

Accept Geo::JSON::FeatureCollection and return array of Yandex::Geo::Company

    Yandex::Geo::Company::from_geo_json($json);

=head2 from_json

Parse regular json to arrayref of Yandex::Geo::Company objects

=head1 NAME

Yandex::Geo::Company

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
