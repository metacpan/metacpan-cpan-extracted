#!/usr/bin/perl
# Example of Document SOAP.
# Same code as has_wsdl.t, but now without comments and in short notation.

# Thanks to Thomas Bayer, for providing this service
#    See http://www.thomas-bayer.com/names-service/

# Author: Mark Overmeer, 27 Nov 2007
# Using:  XML::Compile 0.60
#         XML::Compile::SOAP 0.63
# Copyright by the Author, under the terms of Perl itself.
# Feel invited to contribute your examples!

use warnings;
use strict;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;

# Other useful modules
use Data::Dumper;          # Data::Dumper is your friend.
$Data::Dumper::Indent = 1;

use List::Util   qw/first/;

my $format_list;
format =
   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
   $format_list
.

# Forward declarations
sub get_countries();
sub get_name_info();
sub get_names_in_country();

#### MAIN

use Term::ReadLine;
my $term = Term::ReadLine->new('namesservice');

#
# Get the WSDL and Schema definitions
#

my $wsdl = XML::Compile::WSDL11->new('namesservice.wsdl');
$wsdl->importDefinitions('namesservice.xsd');

#
# Pick one of these tests
#

my $answer = '';
while(lc $answer ne 'q')
{
    print <<__SELECTOR;

    Which call do you like to see:
      1) getCountries
      2) getNameInfo
      3) getNamesInCountry
      Q) quit demo

__SELECTOR

    $answer = $term->readline("Pick one of above [1/2/3/Q] ");
    chomp $answer;

       if($answer eq '1') { get_countries() }
    elsif($answer eq '2') { get_name_info() }
    elsif($answer eq '3') { get_names_in_country() }
    elsif(lc $answer ne 'q' && length $answer)
    {   print "Illegal choice\n";
    }
}

exit 0;

#
# Get Countries
#

sub get_countries()
{   
    my $getCountries = $wsdl->compileClient('getCountries');
    my $answer = $getCountries->();

    if(my $fault_raw = $answer->{Fault})
    {   my $fault_nice = $answer->{$fault_raw->{_NAME}};
        die "Cannot get list of countries: $fault_nice->{reason}\n";
    }

    my $countries = $answer->{parameters}{country};

    print "getCountries() lists ".scalar(@$countries)." countries:\n";
    foreach my $country (sort @$countries)
    {   print "   $country\n";
    }
}

#
# Get Name Info
#

sub get_name_info()
{
    my $name = $term->readline("Personal name for info: ");
    chomp $name;
    length $name or return;

    my $getNameInfo = $wsdl->compileClient('getNameInfo');
    my $answer      = $getNameInfo->(name => $name);

    die "Lookup for '$name' failed: $answer->{Fault}{faultstring}\n"
        if $answer->{Fault};

    my $nameinfo = $answer->{parameters}{nameinfo};
    print "The name '$nameinfo->{name}' is\n";
    print "    male: ", ($nameinfo->{male}   ? 'yes' : 'no'), "\n";
    print "  female: ", ($nameinfo->{female} ? 'yes' : 'no'), "\n";
    print "  gender: $nameinfo->{gender}\n";
    print "and used in countries:\n";

    $format_list = join ', ', @{$nameinfo->{countries}{country}};
    write;
}

#
# Get Names In Country
#

sub get_names_in_country()
{   my $getCountries      = $wsdl->compileClient('getCountries');
    my $getNamesInCountry = $wsdl->compileClient('getNamesInCountry');

    my $answer1 = $getCountries->();
    die "Cannot get countries: $answer1->{Fault}{faultstring}\n"
        if $answer1->{Fault};

    my $countries = $answer1->{parameters}{country};

    my $country;
    while(1)
    {   $country = $term->readline("Most common names in which country? ");
        chomp $country;
        $country eq '' or last;
        print "  please specify a country name.\n";
    }

    # find the name case-insensitive in the list of available countries
    my $name = first { /^\Q$country\E$/i } @$countries;

    unless($name)
    {   $name = 'other countries';
        print "Cannot find name '$country', defaulting to '$name'\n";
        print "Available countries are:\n";
        $format_list = join ', ', @$countries;
        write;
    }

    print "Most common names in $name:\n";
    my $answer2 = $getNamesInCountry->(country => $name);
    die "Cannot get names in country: $answer2->{Fault}{faultstring}\n"
        if $answer2->{Fault};

    my $names    = $answer2->{parameters}{name};
    $names
        or die "No data available for country `$name'\n";

    $format_list = join ', ', @$names;
    write;
}

