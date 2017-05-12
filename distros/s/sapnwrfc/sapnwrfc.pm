package sapnwrfc;
use strict;
use 5.008;
=pod

    Copyright (c) 2006 - 2010 Piers Harding.
    All rights reserved.

=cut

use vars qw($VERSION $AUTOLOAD $DEBUG);
$VERSION = '0.37';

use SAPNW::Base;
$SAPNW::Base::DEBUG = 0;

if ($^O eq 'solaris') {
    $ENV{'RSCP_CATCH_INIT'} = '0';
}

use SAPNW::Rfc;
use SAPNW::Connection;
use SAPNW::RFC::FunctionDescriptor;
use SAPNW::RFC::FunctionCall;
use SAPNW::RFC::Parameter;

use base qw(SAPNW::Rfc);


=head1 NAME

sapnwrfc - SAP Netweaver RFC support for Perl

=head1 SYNOPSIS

  SAPNW::Rfc->load_config;
  my $conn = SAPNW::Rfc->rfc_connect;

  my $rd = $conn->function_lookup("RPY_PROGRAM_READ");
  my $rc = $rd->create_function_call;
  $rc->PROGRAM_NAME("SAPLGRFC");
  eval {
      $rc->invoke;
  };
  if ($@) {
    die "RFC Error: $@\n";
  }
  print "Program name: ".$rc->PROG_INF->{'PROGNAME'}."\n";
  my $cnt_lines_with_text = scalar grep(/LGRFCUXX/, map { $_->{LINE} } @{$rc->SOURCE_EXTENDED});
  $conn->disconnect;


=head1 DESCRIPTION

sapnwrfc is an RFC based connector to SAP specifically designed for use with the next generation RFC SDK supplied by SAP for NW2004+ .

The next generation RFCSDK from SAP provides a number of interesting new features. The two most important are:

=over 4

=item * UNICODE support

=item * deep/nested structures

=back

Comprehensive examples can be found in the L<sapnwrfc-cookbook>.

Help on building sapnwrfc can be found in the README - L<http://search.cpan.org/dist/sapnwrfc/README>.

The UNICODE support is built fundamentally into the core of the new SDK, and as a result this is reflected in sapnwrfc. sapnwrfc takes UTF-8 as its only input character set, and handles the translation of this to UTF-16 as required by the RFCSDK.

Deep and complex structures are now supported fully. Please see the 08deep_z.t example in the tests (t/*) for an idea as to how it works.

sapnwrfc is a departure to the way the original SAP::Rfc (http://search.cpan.org/search?module=SAP::Rfc) works. It aims to simplify the exchange of native Perl data types between the user application and the connector. This means that the following general rules should be observered, when passing values to and from RFC interface parameters and tables:

=over 4

=item * Parameters with structures expect a reference to a hash containing the key/value pairs corresponding to the fields within eg: { 'FLD1' => 'val 1', 'FLD2' => 'val 2', ...}.

=item * Tables expect a reference to an Array of Hash references - as for structured parameters above, these hashes contain key/value pairs eg: [{ 'FLD1' => 'val 1', 'FLD2' => 'val2' ..}, { 'FLD1' => 'val 1', 'FLD2' => 'val2' ..}, ... ] .

=item * CHAR, DATE, TIME, STRING, XSTRING, and BYTE type parameters expect String values.

=item * BCD, and FLOAT expect a string representing the number.

=item * all INT types must be Perl ints.

=back

When building a call for client-side RFC, you should always be inspecting the requirements of the RFC call by using transaction SE37 first.  You should also be in the the habit of testing out your RFC calls first using SE37 too.  YOu would be amazed how much this simple approach will save you (and me) time.


There are a lot of examples of passing data in and out of the connector in the test suite - please refer to these to gain a better understanding of how to make it work.

=head1 Connection Parameters

Connection parameters can be either passed into SAPNW::Rfc->rfc_connect() as a hash of permited values, or more conveniently they can be stored in a YAML based config file.  Refer to the the file "sap.yml" that comes with this distribution for an example like this:

  ashost: ubuntu.local.net
  sysnr: "01"
  client: "001"
  user: developer
  passwd: developer
  lang: EN
  trace: 2
  debug: 1

Note: if you supply your config via the YAML based file, you can override any or all of those parameters at the time a call is made to SAPNW::Rfc->rfc_connect().


=head1 WIN32 Support

When I receive prebuilt PPDs from Olivier (and anyone else who wants to), I make these available at http://www.piersharding.com/download/win32/ .


=head1 AUTHOR

Piers Harding, piers@cpan.org.

Many thanks to:

=over 4

=item * Craig Cmehil - for making the connnections

=item * Ulrich Schmidt - for tireless help in development

=item * Olivier Boudry - the build and test meister

=back


=head1 SEE ALSO

L<sapnwrfc-cookbook>, perl(1), ABAP(101).

=cut


  # Export useful tools
  my @export_ok = qw(
	 debug
   RFCIMPORT
   RFCEXPORT
   RFCCHANGING
   RFCTABLES
   RFCTYPE_CHAR
   RFCTYPE_DATE
   RFCTYPE_BCD
   RFCTYPE_TIME
   RFCTYPE_BYTE
   RFCTYPE_TABLE
   RFCTYPE_NUM
   RFCTYPE_FLOAT
   RFCTYPE_INT
   RFCTYPE_INT2
   RFCTYPE_INT1
   RFCTYPE_NULL
   RFCTYPE_STRUCTURE
   RFCTYPE_DECF16
   RFCTYPE_DECF34
   RFCTYPE_XMLDATA
   RFCTYPE_STRING
   RFCTYPE_XSTRING
   RFCTYPE_EXCEPTION
   RFC_OK
   RFC_COMMUNICATION_FAILURE
   RFC_LOGON_FAILURE
   RFC_ABAP_RUNTIME_FAILURE
   RFC_ABAP_MESSAGE
   RFC_ABAP_EXCEPTION
   RFC_CLOSED
   RFC_CANCELED
   RFC_TIMEOUT
   RFC_MEMORY_INSUFFICIENT
   RFC_VERSION_MISMATCH
   RFC_INVALID_PROTOCOL
   RFC_SERIALIZATION_FAILURE
   RFC_INVALID_HANDLE
   RFC_RETRY
   RFC_EXTERNAL_FAILURE
   RFC_EXECUTED
   RFC_NOT_FOUND
   RFC_NOT_SUPPORTED
   RFC_ILLEGAL_STATE
   RFC_INVALID_PARAMETER
   RFC_CODEPAGE_CONVERSION_FAILURE
   RFC_CONVERSION_FAILURE
   RFC_BUFFER_TOO_SMALL
   RFC_TABLE_MOVE_BOF
   RFC_TABLE_MOVE_EOF
	);

  sub import {
    my ( $caller ) = caller;
    no strict 'refs';
    foreach my $sub ( @export_ok ){
      *{"${caller}::${sub}"} = \&{$sub};
    }
  }


1;
