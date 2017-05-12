#! /usr/bin/perl -s
use strict;
use warnings;

#############################################

# Example of an extended exception class with an additional method
package myExceptionClass;

use eBay::Exception;

use base qw(eBay::Exception);

# declare special exception method
sub foo {
  print "I am in foo.\n";
}


############# begin main

package main;

use strict;
use Test::More qw (no_plan);
use Data::Dumper;

# expose try-catch syntax to application; and enable exceptions
use eBay::Exception qw(:try);
eBay::Exception::enableExceptions(); # enable ebay exceptions


# loop once with ebay exceptions enabled; and once with them disabled
for (my $i = 0; $i < 2; $i++) { 
  my $caught = 0;

  # trap standard eBay exception
  try {
    mythrow();
  } catch Error with {
    $caught = 1;
    my $error = shift;
#    print $error . "\n";
#    print $error->{package} . "\n";
#    print $error->{trace} . "\n";
#    print "##########\n" . Dumper($error) . "\n";
  } finally {
    #optional cleanup code;
  };  # Don't forget the semicolon, this is not a block, but a statement!

  if ($i == 0) {
    is($caught, 1, "Caught simple exception.");
  } else {
    is($caught, 0, "Ebay exception with die disabled.");
  }

  $caught = 0;

  # trap extended exception and call its method
  try {
    myNewThrow();
  } catch Error with {
    $caught = 1;
    my $error = shift;
    #print Dumper($error) . "\n";
    $error->foo();
  } finally {
    #optional cleanup code;
  };  # Don't forget the semicolon, this is not a block, but a statement!

  if ($i == 0) {
    is($caught, 1, "Caught extended exception.");
  } else {
    is($caught, 0, "Ebay exception with die disabled.");
  }
  eBay::Exception::disableExceptions(); # disable ebay exceptions
}

# test exceptions in a session  

use eBay::API::XML::Session;
eBay::Exception::enableExceptions();

my $caught = 0;
try {
  my $apisession = eBay::API::XML::Session->new('yo');
} catch Error with {
  $caught = 1;
};

is($caught, 1, 'Bad hash arg to Session::new().');

eBay::Exception::disableExceptions();

my $apisession = eBay::API::XML::Session->new('yo');

ok(! defined $apisession,
   "Test bad Session::new() with exceptions disabled (should not die).");

exit 0;

############### end main

sub mythrow {
  eBay::API::XmlParseException->ebay_throw(error => 'Test throwing xml parse exception.',
	schema => 'GetCategoriesResponse', package => 'mythrow' );
}

sub myNewThrow {
  ebay_throw myExceptionClass(message => 'Testing extended exception.',
			      error => "This is a foo error.", package => 'myNewThrow') ;
}


