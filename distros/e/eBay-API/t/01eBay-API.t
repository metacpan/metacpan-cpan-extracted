#!/usr/bin/perl

################################################################################
# File: .................. 01eBay-API.t
# Location: .............. <user_defined_location>/eBay-API/t
# Original Author: ....... Milenko Milanovic
# Last Modified By: ...... Jeff Nokes
# Last Modified: ......... 07/13/2006 @ 12:10
#
# Description:
# Simple test installation script that will attempt to `use` or `require` +
# `import` each module provided in this package.  Simple test to see if Perl
# will compile them really.
#
# Notes:
# (1)  Before `make install' is performed this script should be runnable
#      with `make test'. After `make install' it should work as
#      `perl eBay-API.t'
#
################################################################################





# Required Includes
# ------------------------------------------------------------------------------
  use strict;
  use warnings;
  use Test::More tests => 10;      # 10 distinct tests.





# Simple tests, to use (or require + import) each module that is not
# auto-generated, so at least a compilation check will be done.  Test::More
# suggests running these in a BEGIN block.

BEGIN {

   # Test #1 - use eBay::API
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require Exporter;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [ $@ ]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API');

     }# end SKIP block


   # Test #2 - use eBay::Exception
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require Data::Dumper;
             require Exporter;
             require Error;
             require eBay::API::BaseApi;
             require Devel::StackTrace;
             require Exception::Class;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::Exception');

     }# end SKIP block


   # Test #3 - use eBay::BaseApi
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require Exporter;
             require Data::Dumper;
             require eBay::Exception;
             require Params::Validate;
             require XML::Tidy;
             require eBay::API::XML::Release;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API::BaseApi');

     }# end SKIP block


   # Test #4 - use eBay::API::XML::BaseCall
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require Exporter;
             require eBay::API::XML::BaseCallGen;
             require LWP::UserAgent;
             require HTTP::Request; 
             require HTTP::Headers; 
             require XML::Simple;
             require Data::Dumper;
             require Time::HiRes;
             require Compress::Zlib;
             require XML::Tidy;
             require eBay::API;
             require eBay::API::XML::DataType::XMLRequesterCredentialsType;
             require eBay::API::XML::DataType::ErrorType;
             require eBay::API::XML::DataType::Enum::SeverityCodeType;
             require eBay::API::XML::DataType::Enum::ErrorClassificationCodeType;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API::XML::BaseCall');

     }# end SKIP block


   # Test #5 - use eBay::API::XML::BaseCall
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require Exporter;
             require Data::Dumper;
             require Scalar::Util;
             require XML::Writer;
             require XML::Simple;
             require Encode;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API::XML::BaseDataType');

     }# end SKIP block


   # Test #6 - use eBay::API::XML::BaseXml
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require eBay::API::BaseApi;
             require Exporter;
             require Data::Dumper;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API::XML::BaseXml');

     }# end SKIP block



   # Test #7 - use eBay::API::XML::CallRetry
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require Exporter;
             require Data::Dumper;
             require HTTP::Status;
             require eBay::API::XML::BaseCall;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API::XML::CallRetry');

     }# end SKIP block


   # Test #8 - use eBay::API::XML::RequestDataType
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require Exporter;
             require eBay::API::XML::DataType::AbstractRequestType;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API::XML::RequestDataType');

     }# end SKIP block


   # Test #9 - use eBay::API::XML::ResponseDataType
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require Exporter;
             require eBay::API::XML::DataType::AbstractResponseType;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API::XML::ResponseDataType');

     }# end SKIP block


   # Test #10 - use eBay::API::XML::Session
     SKIP: {
        # Check for the existence of any dependencies on other modules/classes.
          eval {
             require LWP::Parallel;
             require Data::Dumper;
             require eBay::API::XML::BaseXml;
             require HTTP::Request;
          };

          # If there was an error given by the eval above, then the user must have
          # skipped the auto-generation phase, or there is some other module
          # dependency that is breaking things, thus we should skip this test.
            skip "Most likely dependency on another module not found:  [$@]\n\n", 1 if $@;

        # If we got this far, we must be OK to do the test.
          use_ok('eBay::API::XML::Session');

     }# end SKIP block

} # end BEGIN block




#########################

# Test::More defuault text below
#
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

