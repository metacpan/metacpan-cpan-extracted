package eBay::Exception;

#########################################################################
#
# Module: ............... <user defined location>/eBay/API
# File: ................. Exception.pm
# Original Author: ...... Bob Bradley
#
#########################################################################

=pod

=head1 eBay::Exception

Ebay exception handling framework.

=head1 DESCRIPTION

This module provides a framework to users of the eBay::API packages to
throw, catch and handle severe runtime exceptions gracefully.

The eBay::API exceptions inherit the functionality of CPAN modules
Exceptions::Class and Error, including such informational fields as message,
error, time, package, etc.  See

  http://search.cpan.org/~drolsky/Exception-Class-1.23/lib/Exception/Class.pm

for a description of Exceptions::Class details.

As an end user you have the option of enabling exception handling or
not.  To enable exceptions you must include eBay::Exception B<and>
then enable exceptions by calling the Exception class method
ebay::Exception::enableExceptions();

Exceptions include the following:

=over 4

=item *

B<eBay::Exception>  Base class for all API exceptions.

=item *

B<eBay::API::XmlParseException> Exceptions encountered while parsing
XML content.  This class has an additional informational field:
I<schema>.

=item *

B<eBay::API::UsageException> Exceptions with using subroutines,
including the wrong number of parameters, the wrong types of
parameters, or inconsistent values in parameters.  This exception has
an additional informational field: I<argnumber>.

=back

Not all eBay applications errors may be reported as exceptions.  You
should always check the individual call responses for other
application level error information such as failure to list an item
for a user because that user does not have enough feedback to list an
item of that type.

=head1 SYNOPSIS

  use eBay::API::XML::Session;
  use eBay::Exception qw(:try);

  # Uncomment this line to enable the catch block below
  # eBay::Exception::enableExceptions();

  try {
    # Example of bad argument to Session constructor
    my $apisession = eBay::API::XML::Session->new('yo');
  } catch Error with {
    my $error = shift;
    print $error->{argnumber};  # specific to usage errors
    print $error->{package};    # package where error trapped
    print $error->{trace};      # stack trace
    print $error;               # exception type
    print "\n\nCATCHING THE EXCEPTON!\n";
  } finally {
    #optional cleanup code;
    print "\nIN FINALLY BLOCK.\n";
  };  # Don't forget the semicolon, this is not a block, but a statement!


=head1 EXTENDING EXCEPTION HANDLING

It is simple to extend the framework to use it in your own application
code.  You can define exception classes that inherit from any
pre-existing Extension::Class and then use and throw these classes in
your own application code.  If you extend from an eBay exception
class, then any exceptions you throw will also be logged to the eBay
logging facility if you throw the exception with the instance method
ebay_throw().  Whether the exception will actually be thrown, of course,
depends on whether you have enabled exceptions.  If you just throw()
the exception, it will always be thrown, and there will be no message
to the eBay API logging.

Example:

  package myException;

  use eBay::Exception;

  use base qw(eBay::Exception);

  sub foo {
    print "I AM IN FOO.\n";
  }

  1;

  package main;

  use eBay::Exception qw(:try);
  # Comment out following to disable the catch block
  eBay::Exception::enableExceptions();

  try {
    myNewThrow();
  } catch Error with {
    print "CATCHING myNewThrow().\n";
    my $error = shift;
    if ($error->isa('myException') ) {
      print "myException ERROR: " . $error->error . "\n";
      $error->foo();
    }
  } finally {
    #optional cleanup code;
    print "I AM CLEANING UP.\n";
  };

  sub myNewThrow {
    # log and (maybe) actually throw
    myException->ebay_throw( error => "This is a foo error." );
    # or just throw and always throw regardless
    # myException->throw( error => "This is a foo error." );
  }

  1;



=cut

# Required Includes
# ---------------------------------------------------------------------------
use strict;                   # Used to control variable hell
use warnings;
use Data::Dumper;
use Exporter;
use Error qw(:try);
use eBay::API::BaseApi;
use Devel::StackTrace;

my $enabled = 0;

# Declare our exception types
use Exception::Class ( 'eBay::Exception' =>
                         { isa => 'Exception::Class::Base',
			   fields => ['package', 'file', 'line'],
                           description => 'eBay API XML Parse exception.' },

                         'eBay::API::XmlParseException' =>
                         { isa => 'eBay::Exception',
			   fields => ['schema'],
                           description => 'eBay API XML Parse exception.' },

                         'eBay::API::UsageException' =>
                         { isa => 'eBay::Exception',
			   fields => ['argnumber'],
                           description => 'Incorrect subroutine call exception.' }

                         );

use base qw(Error Exception::Class);

# dynamically extend CPAN Exception::Class to CPAN Error

BEGIN {

  push @Exception::Class::Base::ISA, 'Error'
    unless Exception::Class::Base->isa('Error');

}

=pod

=head2 enableExceptions()

When called tells the exception framework to throw exceptions.  This has the
effect of activating any exception handling logic in catch portion of a try/catch
statement.

=cut

sub enableExceptions {
  $enabled = 1;
}

=pod

=head2 disableExceptions()

This reverses the effect of calling enableExceptions().  The default for the
exception handling framework is for it to be disabled.

=cut

sub disableExceptions {
  $enabled = 0;
}


=pod

=head2 ebay_throw()

Extract information from the exception being thrown, including a stack trace,
and log this information with the API logging framework.  If exceptions are
enabled, then call Exception::Class::throw() to throw the exception.  This will
cause the exception handling logic in the catch portion of the try/catch statement
to execute.

=cut

sub ebay_throw {
  my @args = @_;
  #print Dumper(@args);
  my ($package, $filename, $line) = caller;
  my $trace = Devel::StackTrace->new;
  my $msg .= (shift) . " at ".$package . " " . $filename . " " . $line  . "\n" . $trace->as_string;
  while (@_) {
    $msg .= "\t" . (shift) . ": ";
    $msg .= (shift) . "\n"
  }
  
  # log the error info
  no strict('subs');
  eBay::API::BaseApi::_log_it($msg, eBay::API::BaseApi::LOG_ERROR);
  use strict('subs');
  
  # check to see if exceptions are enabled
  if ($enabled) {
    my $exception = shift @args;
    $exception->throw(@args);
  }
}

  
# Return TRUE to perl
1;
