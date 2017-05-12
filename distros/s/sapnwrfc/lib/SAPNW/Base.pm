package SAPNW::Base;

=pod

    Copyright (c) 2006 - 2010 Piers Harding.
        All rights reserved.

=cut

  use strict;
  require 5.008;
  use Data::Dumper;

  use vars qw($VERSION $DEBUG $SAPNW_RFC_CONFIG);
  $VERSION = '0.37';

  use constant RFCIMPORT     => 1;
  use constant RFCEXPORT     => 2;
  use constant RFCCHANGING   => 3;
  use constant RFCTABLES     => 7;

  use constant RFCTYPE_CHAR  => 0;
  use constant RFCTYPE_DATE  => 1;
  use constant RFCTYPE_BCD   => 2;
  use constant RFCTYPE_TIME  => 3;
  use constant RFCTYPE_BYTE  => 4;
  use constant RFCTYPE_TABLE => 5;
  use constant RFCTYPE_NUM   => 6;
  use constant RFCTYPE_FLOAT => 7;
  use constant RFCTYPE_INT   => 8;
  use constant RFCTYPE_INT2  => 9;
  use constant RFCTYPE_INT1  => 10;
  use constant RFCTYPE_NULL  => 14;
  use constant RFCTYPE_STRUCTURE  => 17;
  use constant RFCTYPE_DECF16  => 23;
  use constant RFCTYPE_DECF34  => 24;
  use constant RFCTYPE_XMLDATA => 28;
  use constant RFCTYPE_STRING  => 29;
  use constant RFCTYPE_XSTRING => 30;
  use constant RFCTYPE_EXCEPTION => 98;

  use constant RFC_OK => 0;
  use constant RFC_COMMUNICATION_FAILURE => 1;
  use constant RFC_LOGON_FAILURE => 2;
  use constant RFC_ABAP_RUNTIME_FAILURE => 3;
  use constant RFC_ABAP_MESSAGE => 4;
  use constant RFC_ABAP_EXCEPTION => 5;
  use constant RFC_CLOSED => 6;
  use constant RFC_CANCELED => 7;
  use constant RFC_TIMEOUT => 8;
  use constant RFC_MEMORY_INSUFFICIENT => 9;
  use constant RFC_VERSION_MISMATCH => 10;
  use constant RFC_INVALID_PROTOCOL => 11;
  use constant RFC_SERIALIZATION_FAILURE => 12;
  use constant RFC_INVALID_HANDLE => 13;
  use constant RFC_RETRY => 14;
  use constant RFC_EXTERNAL_FAILURE => 15;
  use constant RFC_EXECUTED => 16;
  use constant RFC_NOT_FOUND => 17;
  use constant RFC_NOT_SUPPORTED => 18;
  use constant RFC_ILLEGAL_STATE => 19;
  use constant RFC_INVALID_PARAMETER => 20;
  use constant RFC_CODEPAGE_CONVERSION_FAILURE => 21;
  use constant RFC_CONVERSION_FAILURE => 22;
  use constant RFC_BUFFER_TOO_SMALL => 23;
  use constant RFC_TABLE_MOVE_BOF => 24;
  use constant RFC_TABLE_MOVE_EOF => 25;


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
     Dumper
    );

  sub import {
    my ( $caller ) = caller;
    no strict 'refs';
    foreach my $sub ( @export_ok ){
      *{"${caller}::${sub}"} = \&{$sub};
    }
  }

  sub debug {
      return unless $DEBUG;
        print STDERR scalar localtime() . " - ". caller(), ":> " , @_, "\n";
    }


1;
