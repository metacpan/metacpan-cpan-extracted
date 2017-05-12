#!/usr/bin/perl
# Example of Document style SOAP, but without WSDL file
# Same as has_schema.pl, but now as short and without explanation

# Thanks to Thomas Bayer, for providing this service
#    See http://www.thomas-bayer.com/names-service/

# Author: Mark Overmeer, 27 Nov 2007
# Using:  XML::Compile 0.60
#         XML::Compile::SOAP 0.64
# Copyright by the Author, under the terms of Perl itself.
# Feel invited to contribute your examples!

use warnings;
use strict;

use XML::Compile::SOAP11::Client;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Util   qw/pack_type/;

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
my $term   = Term::ReadLine->new('namesservice');

my $client = XML::Compile::SOAP11::Client->new;
$client->schemas->importDefinitions('namesservice.xsd');

my $myns   = 'http://namesservice.thomas_bayer.com/';

my $http   = XML::Compile::Transport::SOAPHTTP
  ->new(address => 'http://www.thomas-bayer.com:80/names-service/soap')
  ->compileClient; 

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

sub create_call($)
{   my $name = shift;

    my $output = $client->compileMessage
     ( SENDER    =>
     , body => [ ask => pack_type($myns, $name) ]
     );

    my $input = $client->compileMessage
     ( RECEIVER  =>
     , body => [ got => pack_type($myns, $name.'Response') ]
     );

    $client->compileClient
     ( name      => $name
     , encode    => $output
     , transport => $http
     , decode    => $input
     );
}

#
# Get Countries
#

sub get_countries()
{   
    my $getCountries = create_call 'getCountries';

    my ($answer, $trace) = $getCountries->();
    $answer
        or die "No answer received\n";
    #use Data::Dumper;
    #warn Dumper $trace;

    if(my $fault_raw = $answer->{Fault})
    {   my $fault_nice = $answer->{$fault_raw->{_NAME}};
        die "Cannot get list of countries: $fault_nice->{reason}\n";
    }

    my $countries = $answer->{got}{country};

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
    my $getNameInfo = create_call 'getNameInfo';

    my $name = $term->readline("Personal name for info: ");
    chomp $name;
    length $name or return;

    my $answer = $getNameInfo->(name => $name);
    die "Lookup for '$name' failed: $answer->{Fault}{faultstring}\n"
        if $answer->{Fault};

    my $nameinfo = $answer->{got}{nameinfo};
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
{   # usually in the top of your script: reusable
    my $getCountries      = create_call 'getCountries';
    my $getNamesInCountry = create_call 'getNamesInCountry';

    my $answer1 = $getCountries->();
    die "Cannot get countries: $answer1->{Fault}{faultstring}\n"
        if $answer1->{Fault};

    my $countries = $answer1->{got}{country};

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

    my $names    = $answer2->{got}{name};
    $names
        or die "No data available for country `$name'\n";

    $format_list = join ', ', @$names;
    write;
}

