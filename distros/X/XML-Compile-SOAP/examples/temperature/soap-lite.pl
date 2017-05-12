#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use SOAP::Lite; # +trace => 'all';

my $soap = SOAP::Lite
    ->uri('http://www.webserviceX.NET/')
    ->on_action(sub { "http://www.webserviceX.NET/$_[1]" } )
    ->proxy("http://www.webservicex.net/ConvertTemperature.asmx?WSDL");

my $method = SOAP::Data->name('ConvertTemp')
   ->attr({xmlns => 'http://www.webserviceX.NET'});

my @params = (
  SOAP::Data->new(name => 'Temperature', value => '12.0',type =>'s:double'),
  SOAP::Data->new(name => 'FromUnit', value => 'degreeCelsius', type => 's:string'),
  SOAP::Data->new(name =>'ToUnit', value => 'degreeFahrenheit', type => 's:string')
  );

my $som = $soap->ConvertTemp(@params);

if(my $match = $som->match('/Envelope/Body/ConvertTempResponse/')) {
   my $result = $som->valueof('//ConvertTempResponse/ConvertTempResult');
   print "Temperature is $result\n";
} else {
   print "match not OK: $match\n";
}
