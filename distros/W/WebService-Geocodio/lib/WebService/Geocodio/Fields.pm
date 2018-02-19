use strict;
use warnings;

{
    package WebService::Geocodio::Fields::CongressionalDistrict;
$WebService::Geocodio::Fields::CongressionalDistrict::VERSION = '0.05';
use Moo;
    use strictures 2;;

    has [qw(name district_number congress_number proportion congress_years current_legislators)] => (
        is => 'ro',
    );

}

################## State Legislative Districts

{
    package WebService::Geocodio::Fields::StateLegislativeDistrict::House;
$WebService::Geocodio::Fields::StateLegislativeDistrict::House::VERSION = '0.05';
use Moo;
    use strictures 2;;

    has [qw(name district_number)] => (
        is => 'ro',
    );
}

{
    package WebService::Geocodio::Fields::StateLegislativeDistrict::Senate;
$WebService::Geocodio::Fields::StateLegislativeDistrict::Senate::VERSION = '0.05';
use Moo;
    use strictures 2;;

    has [qw(name district_number)] => (
        is => 'ro',
    );
}

{

    package WebService::Geocodio::Fields::StateLegislativeDistrict;
$WebService::Geocodio::Fields::StateLegislativeDistrict::VERSION = '0.05';
use WebService::Geocodio::Fields::StateLegislativeDistrict::House;
    use WebService::Geocodio::Fields::StateLegislativeDistrict::Senate;

    use Moo;
    use strictures 2;;
    use Carp qw(confess);

    has [qw(house senate)] => (
        is => 'ro',
        predicate => 1,
    );

    sub BUILDARGS {
        my ($class, $hr) = @_;

        confess "$class only accepts hashrefs in its constructor" unless ( ref($hr) eq 'HASH' );

        my $out;

        $out->{house} = WebService::Geocodio::Fields::StateLegislativeDistrict::House->new(
            $hr->{house}) if exists $hr->{house};
        $out->{senate} = WebService::Geocodio::Fields::StateLegislativeDistrict::Senate->new(
            $hr->{senate}) if exists $hr->{senate};

        return $out;
    }

}

############### School districts

{
    package WebService::Geocodio::Fields::SchoolDistrict::Unified;
$WebService::Geocodio::Fields::SchoolDistrict::Unified::VERSION = '0.05';
use Moo;
    use strictures 2;;

    has [qw(name lea_code grade_low grade_high)] => (
        is => 'ro',
    );
}

{
    package WebService::Geocodio::Fields::SchoolDistrict::Elementary;
$WebService::Geocodio::Fields::SchoolDistrict::Elementary::VERSION = '0.05';
use Moo;
    use strictures 2;;

    has [qw(name lea_code grade_low grade_high)] => (
        is => 'ro',
    );
}

{
    package WebService::Geocodio::Fields::SchoolDistrict::Secondary;
$WebService::Geocodio::Fields::SchoolDistrict::Secondary::VERSION = '0.05';
use Moo;
    use strictures 2;;

    has [qw(name lea_code grade_low grade_high)] => (
        is => 'ro',
    );
}

{

    package WebService::Geocodio::Fields::SchoolDistrict;
$WebService::Geocodio::Fields::SchoolDistrict::VERSION = '0.05';
use WebService::Geocodio::Fields::SchoolDistrict::Unified;
    use WebService::Geocodio::Fields::SchoolDistrict::Elementary;
    use WebService::Geocodio::Fields::SchoolDistrict::Secondary;

    use Moo;
    use strictures 2;;
    use Carp qw(confess);

    has [qw(unified elementary secondary)] => (
        is => 'ro',
        predicate => 1,
    );

    sub BUILDARGS {
        my ($class, $hr) = @_;

        confess "$class only accepts hashrefs in its constructor" unless ( ref($hr) eq 'HASH' );

        my $out;

        $out->{unified} = WebService::Geocodio::Fields::SchoolDistrict::Unified->new(
            $hr->{unified}) if exists $hr->{unified};
        $out->{elementary} = WebService::Geocodio::Fields::SchoolDistrict::Elementary->new(
            $hr->{elementary}) if exists $hr->{elementary};
        $out->{secondary} = WebService::Geocodio::Fields::SchoolDistrict::Secondary->new(
            $hr->{secondary}) if exists $hr->{secondary};

        return $out;
    }
}

############################ Timezone

{
    package WebService::Geocodio::Fields::Timezone;
$WebService::Geocodio::Fields::Timezone::VERSION = '0.05';
use Moo;
    use strictures 2;

    has [qw(name utc_offset observes_dst)] => (
        is => 'ro',
    );
}

############################ Census

{
    package WebService::Geocodio::Fields::Census;
$WebService::Geocodio::Fields::Census::VERSION = '0.05';
use Moo;
    use strictures 2;

    has [qw(state_fips county_fips place_fips tract_code
        block_group block_code census_year)] => (
        is => 'ro',
    );

}

package WebService::Geocodio::Fields;
$WebService::Geocodio::Fields::VERSION = '0.05';
# ABSTRACT: Modules to represent various fields Geocod.io supports

use WebService::Geocodio::Fields::CongressionalDistrict;
use WebService::Geocodio::Fields::StateLegislativeDistrict;
use WebService::Geocodio::Fields::SchoolDistrict;
use WebService::Geocodio::Fields::Timezone;
use WebService::Geocodio::Fields::Census;

use Moo;
use strictures 2;
use Carp qw(confess);

has [qw(cd stateleg school timezone census)] => (
    is => 'rw',
    predicate => 1,
);

sub BUILDARGS {
    my ( $class, $hr ) = @_;

    confess "$class only accepts hashrefs in its constructor" unless ( ref($hr) eq 'HASH' );

    my $out;

    $out->{cd} = [ map { WebService::Geocodio::Fields::CongressionalDistrict->new($_) }
        @{ $hr->{congressional_districts} } ] if exists $hr->{congressional_districts};
    $out->{stateleg} = WebService::Geocodio::Fields::StateLegislativeDistrict->new(
        $hr->{state_legislative_districts}) if exists $hr->{state_legislative_districts};
    $out->{school} = WebService::Geocodio::Fields::SchoolDistrict->new(
        $hr->{school_districts}) if exists $hr->{school_districts};
    $out->{timezone} = WebService::Geocodio::Fields::Timezone->new($hr->{timezone})
        if exists $hr->{timezone};
    $out->{census} = WebService::Geocodio::Fields::Census->new($hr->{census})
        if exists $hr->{census};

    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Geocodio::Fields::CongressionalDistrict - Modules to represent various fields Geocod.io supports

=head1 VERSION

version 0.05

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
