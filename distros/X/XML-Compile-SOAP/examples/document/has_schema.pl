#!/usr/bin/perl
# Example of Document style SOAP, but without WSDL file
# Thanks to Thomas Bayer, for providing this service
#    See http://www.thomas-bayer.com/names-service/

# Author: Mark Overmeer, 26 Nov 2007
# Using:  XML::Compile 0.60
#         XML::Compile::SOAP 0.64
# Copyright by the Author, under the terms of Perl itself.
# Feel invited to contribute your examples!

# Of course, all Perl programs start like this!
use warnings;
use strict;

use XML::Compile::SOAP11::Client;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Util   qw/pack_type/;

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
sub get_countries($);
sub get_name_info();
sub get_names_in_country();

#### MAIN

use Term::ReadLine;
my $term = Term::ReadLine->new('namesservice');

#
# Get the Client and Schema definitions
#

my $client = XML::Compile::SOAP11::Client->new;
$client->schemas->importDefinitions('namesservice.xsd');

my $myns    = 'http://namesservice.thomas_bayer.com/';
my $address = 'http://www.thomas-bayer.com:80/names-service/soap';

#
# Pick one of these tests
#

my $answer = '';
while(lc $answer ne 'q')
{
    print <<__SELECTOR;

    Which call do you like to see:
      1) getCountries
      2) getCountries with trace output
      3) getNameInfo
      4) getNamesInCountry
      Q) quit demo

__SELECTOR

    $answer = $term->readline("Pick one of above [1/2/3/4/Q] ");
    chomp $answer;

       if($answer eq '1') { get_countries(0) }
    elsif($answer eq '2') { get_countries(1) }
    elsif($answer eq '3') { get_name_info()  }
    elsif($answer eq '4') { get_names_in_country() }
    elsif(lc $answer ne 'q' && length $answer)
    {   print "Illegal choice\n";
    }
}

exit 0;

#
# First example
# This one is explained in most detail
#

my $transporter;
sub get_transporter
{   return $transporter   # reuse the transporter
        if defined $transporter;

    # This is the place to add connection intelligence, like SSL
    $transporter
      = XML::Compile::Transport::SOAPHTTP->new(address => $address);
}

sub create_get_countries()
{   # construct the 'getCountries' call.  With a WSDL file, you do
    # not have to worry about these details, but when you haven't one,
    # ... well someone has to be explicit...

    # Here, you can specify SOAP version, transport METHOD, action URI,
    # and such, for the transport protocol part of SOAP.

    my $http = get_transporter->compileClient;

    # The message which is sent to the server
    # The 'parameters' is a constant you can pick yourself: you may need
    # it when calling the method.  Better use a descriptional name here.
    # Where this is document-style SOAP, the type is defined by a schema.
    # 'pack_type' will create a string "{$myns}getCountries".

    my $output = $client->compileMessage
     ( SENDER    =>
     , body => [ selection => pack_type($myns, 'getCountries') ]
     );

    # The returned message
    # Expected fault returns are automatically compiled in.  You may
    # add own fault and headerfault details.

    my $input = $client->compileMessage
     ( RECEIVER  =>
     , body => [ countries => pack_type($myns, 'getCountriesResponse') ]
     );

    # Connect everything together
    my $getCountries = $client->compileClient
     ( name      => 'getCountries'
     , encode    => $output
     , transport => $http
     , decode    => $input
     );

    $getCountries;    # return the code reference
}

sub get_countries($)
{   my $show_trace = shift;

    # first compile a handler which you can call as often as you want.

    my $getCountries = create_get_countries;

    #
    ## From here on, just like the WSDL version
    #

    #
    # Call the produced method to list the supported countries
    #

    my ($answer, $trace)
    #   = $getCountries->(Body => {selection => {}});
    #   = $getCountries->(selection => {});
        = $getCountries->();    # is code-ref, so still needs ->()

    # In above examples, the first explicitly addresses the 'selection'
    # part in the Body.  There is also a Header.
    # The second version can be used when all header and body parts have
    # difference names.  The last version can be used if there is only one
    # body part defined.

    # If you do not need the trace, simply say:
    # my $answer = $getCountries->();

    if($show_trace)
    {   $trace->printTimings;
        $trace->printRequest;
        $trace->printResponse;
    }

    # And now?  What do I get back?  I love Data::Dumper.
    # warn Dumper $answer;

    #
    # Handling faults
    #

    if(my $fault_raw = $answer->{Fault})
    {   my $fault_nice = $answer->{$fault_raw->{_NAME}};

        # fault_raw points to the fault structure, which contains fields
        # faultcode, faultstring, and unprocessed "detail" information.
        # fault_nice points to the same information, but translated to
        # something what is equivalent in SOAP1.1 and SOAP1.2.

        die "Cannot get list of countries: $fault_nice->{reason}\n";

        # Have a look at Log::Report for cleaner (translatable) die:
        #   error __x"Cannot get list of countries: {reason}",
        #      reason => $fault_nice->{reason};
    }

    #
    # Collecting the country names
    #

    # The contents returned is a getCountriesResponse element of type
    # complexType getCountriesResponse, both defined in the xsd file.
    # The only data field is named 'country', and has a maxCount > 1 so
    # will be translated by XML::Compile into an ARRAY.
    # The received message is validated, so we do not need to check the
    # structure ourselves again.

    my $countries = $answer->{countries}{country};

    print "getCountries() lists ".scalar(@$countries)." countries:\n";
    foreach my $country (sort @$countries)
    {   print "   $country\n";
    }
}

#
# Second example
#

sub create_get_name_info()
{   my $http = get_transporter->compileClient;

    my $output = $client->compileMessage(SENDER   =>
     , body => [ whose => pack_type($myns, 'getNameInfo') ] );

    my $input  = $client->compileMessage(RECEIVER =>
     , body => [ info  => pack_type($myns, 'getNameInfoResponse') ] );

    $client->compileClient(name => 'getNameInfo'
     , encode => $output, transport => $http, decode => $input);
}

sub get_name_info()
{
    my $getNameInfo = create_get_name_info;

    #
    ## From here on, just like the WSDL version
    #

    # ask the user for a name
    my $name = $term->readline("Personal name for info: ");
    chomp $name;
    length $name or return;

    my ($answer, $trace2) = $getNameInfo->(name => $name);
    #print Dumper $answer, $trace2;

    die "Lookup for '$name' failed: $answer->{Fault}{faultstring}\n"
        if $answer->{Fault};

    my $nameinfo = $answer->{info}{nameinfo};
    print "The name '$nameinfo->{name}' is\n";
    print "    male: ", ($nameinfo->{male}   ? 'yes' : 'no'), "\n";
    print "  female: ", ($nameinfo->{female} ? 'yes' : 'no'), "\n";
    print "  gender: $nameinfo->{gender}\n";
    print "and used in countries:\n";

    $format_list = join ', ', @{$nameinfo->{countries}{country}};
    write;
}

#
# Third example
#

sub create_get_names_in_country()
{   my $http = get_transporter->compileClient;

    my $output = $client->compileMessage(SENDER   =>
     , body => [ which => pack_type($myns, 'getNamesInCountry') ] );

    my $input  = $client->compileMessage(RECEIVER =>
     , body => [ info  => pack_type($myns, 'getNamesInCountryResponse') ] );

    $client->compileClient(name => 'getNameInfo'
     , encode => $output, transport => $http, decode => $input);
}

sub get_names_in_country()
{   # usually in the top of your script: reusable
    my $getCountries      = create_get_countries;
    my $getNamesInCountry = create_get_names_in_country;

    #
    ## From here on the same as the WSDL version
    #

    my $answer1 = $getCountries->();
    die "Cannot get countries: $answer1->{Fault}{faultstring}\n"
        if $answer1->{Fault};

    my $countries = $answer1->{countries}{country};

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

    my $names    = $answer2->{info}{name};
    $names
        or die "No data available for country `$name'\n";

    $format_list = join ', ', @$names;
    write;
}

