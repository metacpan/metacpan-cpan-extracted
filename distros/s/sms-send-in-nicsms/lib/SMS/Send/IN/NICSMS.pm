package SMS::Send::IN::NICSMS;

# ABSTRACT: SMS::Send driver to send messages via NIC's SMS Gateway ( https://smsgw.sms.gov.in )

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use URI::Escape;

use base 'SMS::Send::Driver';

our $VERSION = '1.00'; # VERSION
our $AUTHORITY = 'cpan:INDRADG'; # AUTHORITY

sub new {
    my ( $class, %args ) = @_;

    # check we have the necessary credentials parameters
    die "Username needs to be passed as 'username'" unless ( $args{_login}  );
    die "PIN / password needs to be passed as 'password'" unless ( $args{_password} );
    die "SenderID / DLT Header needs to be passsed as 'signature'" unless ( $args{_signature} );
    die "19-digit DLT Entity ID needs to be passed as 'dlt_entity_id'" unless ( $args{_dlt_entity_id} );

    # build the object
    my $self = bless {
        _endpoint  => 'https://smsgw.sms.gov.in/failsafe/HttpLink',
        _debug     => 0,
        %args
    }, $class;

    # get an LWP user agent ready
    # FIXME - bypassing SSL cert check due to NIC's cert chain borkage
    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->ssl_opts(
        SSL_verify_mode => 0, 
        verify_hostname => 0,
    );
    
    return $self;
}

sub _send_method {
    my ( $self, @args ) = @_;

    my @params;
    while (@args) {
        my $key = shift @args;
        my $val = shift @args;
        push( @params, join( '=', uri_escape($key), uri_escape($val) ) );
        print STDERR ">>>   Arg $key = $val\n" if ( $self->{_debug} );
    }
    my $url = join( '?', $self->{_endpoint}, join( '&', @params ) );
    print STDERR ">>>   GET $url\n" if ( $self->{_debug} );

    my $res = $self->{ua}->get($url);

    my $errorbroker = $self->_ERRORHANDLER ( $res );

    if ( $errorbroker ) {
        print STDERR "<<<   Message sent successfully\n";
        print STDERR "<<<   SMS gateway response : $res->{_content}\n" if ( $self->{_debug} );
        return 1;
    } else {
        print STDERR "<<<   Message send failed\n";
        print STDERR "<<<   SMS gateway response : $res->{_content}\n";
        return;
    }
}

sub send_sms {

    my ( $self, %args ) = @_;

    # FIXME : ugly hack to handle passing the DLT_TEMPLATE_ID for Koha ILS
    if  ( exists $self->{_iskohainstance} ) {
        if ( $self->{_iskohainstance} eq "yes" ) {
            # check if $args{text} is carrying the DLT_TEMPLATE_ID at the start of the message
            # else throw an error
            # As on date the IDs are 19 digit numbers

            die "19-digit DLT_TEMPLATE_ID not found at start of message!" unless ( $args{text} =~ /^\d{19}/ );

            $self->{_dlt_template_id} = substr( $args{text}, 0, 19);

            $args{text} =~ s!^\d{19}!!;
	} else {
            die "Incorrect value for the key 'iskohainstance' in IN/NICSMS.yaml. Check file!";
        }
    } else {
        $self->{_dlt_template_id} = $args{_dlt_template_id};
    }

    # check for message for 160 char limit
    my $text = $self->_MESSAGETEXT ( $args{text} );
    
    # check destination number for well-formedness under NNP 2003 schema
    my $to = $self->_TO ( $args{to} );

    $self->_send_method(
        username        => $self->{_login},
        pin             => $self->{_password},
        mnumber         => $args{to},
        message         => $args{text},
	signature       => $self->{_signature},
        dlt_entity_id   => $self->{_dlt_entity_id},
        dlt_template_id => $self->{_dlt_template_id},
    );
}

# -----------------------------------------------------
# internal sanitization routines
# -----------------------------------------------------

sub _MESSAGETEXT {
  my ( $self, $text ) = @_;
  use bytes;
  die "Message length over limit. Max length is 160 characters" unless ( length($text) <= 160 ); 
} # check for 160 char length of message text

# As per National Numbering Plan 2003, Indian mobile phone numbers have to be in
# [9|8|7]XXXXXXXXX format. So we need to sanitize our input. The driver expects
# number string in 91XXXXXXXXXX format

sub _TO {
  my ( $self, $dest ) = @_;

  my $checkseries;
  my $countrycode;

  # strip out any NaN characters
  $dest =~ s/[^\d]//g;

  # strip leading zero as some have the habit of inputing numbers as 0XXXXXXXXXX
  $dest =~ s/^0+//g;

  # check destination number length and format for well-formedness and fix common issues.
  if ( length($dest) == 12 or length($dest) == 10 ) {
  	if ( length($dest) == 12 ) {
	    $countrycode = substr $dest, 0, 2;
	    die "Country code incorrect, needs to be 91 for India" unless ( $countrycode eq '91' ); 
        }
	if ( length($dest) == 10 ) {
	    $countrycode = "91";
	    $dest = $countrycode . $dest;	#bring it up to 91XXXXXXXXXX
	}

	# check for 9,8,7,6 series numbering under NNP 2003
        # see https://en.wikipedia.org/wiki/Mobile_telephone_numbering_in_India
        #
        $checkseries = substr $dest, 2, 1;
        die "Invalid phone number as per National Numbering Plan 2003" unless ( $checkseries =~ /[9|8|7|6]/ ); 
  } else {
        die "Invalid phone number format";
  }
  return $dest;
}

sub _ERRORHANDLER {
  my ( $self, $res ) = @_;

  # check for "~code=API000 " in the response string signifying a successful send

  if ( $res->content =~ /~code=API000 / ) {
      return 1;
  } else {
      return;
  }
}

1;

__END__

=pod

=head1 NAME

SMS::Send::IN::NICSMS - Regional context SMS::Send driver to send messages via NIC's SMS Gateway ( https://smsgw.sms.gov.in )

=head1 VERSION

version 1.00

=head1 SYNOPSIS

  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new(
    'IN::NICSMS',
    _login           => 'username',           
    _password        => 'pin',
    _signature       => 'senderid',
    _dlt_entity_id   => 'dlt_entity_id',
  );
  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is an example message',  # use actual DLT approved content template
      to   => '91XXXXXXXXX',                 # use actual 10 digit mobile number in place of 'XXXXXXXXXX'
      _dlt_template_id => 'dlt_template_id', # use the actual DLT template id for the text template above
  );
  if ($sent) {
  print "Message send OK\n";
  }
  else {
  print "Failed to send message\n";
  

=head1 DESCRIPTION

An Indian regional context driver for SMS::Send to send SMS text messages via 
NIC's SMS Gateway in India - L<https://smsgw.sms.gov.in> with 100% compliance
to Telecom Regulatory Authority of India's (TRAI) TCCCPR 2018 norms which are
accessible at L<https://trai.gov.in/sites/default/files/RegulationUcc19072018.pdf>

This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).

The driver uses the NIC's HTTPS API mechanism for SMS.  This is documented in
the "HTTPS/XML API Hand Book" for official customers/users from Govt of India,
State governments, Union territories administrations, districts and other 
Government bodies of the service.

=head1 METHODS

=head2 new

Constructor, takes argument pairs passed by SMS::Send, returns an
SMS::Send::IN::NICSMS object.  See usage synopsis for example, and see 
SMS::Send documentation for further info on using SMS::Send drivers.

Mandatory arguments include:-

=over 4

=item _login

The username allotted to the user institution by NIC for use of the SMS service

=item _password

The PIN aka password for the username mentioned above

=item _signature

This is the 6 character (alphabet only) SenderID aka Header in DLT terminology

=item _dlt_entity_id

A 19 digit unique id assigned to the user institution while registering as PE
(principal entity) on the DLT platform. 

=back

Additional arguments that may be passed include:-

=over 4

=item _endpoint

The HTTPS API endpoint. Defaults to C<https://smsgw.sms.gov.in/failsafe/HttpLink>

=item _debug

Whether debugging information is output or not.

=back


=head2 send_sms

Send the message - see SMS::Send for details. It requires three parameters to 
function with the NIC SMS gateway:

=over 4

=item "text"

The DLT approved service implicit content template. The driver restricts it to 160
characters which forms the message body.

=item "to"

Destination mobile phone number in India. Numbered as per NNP 2003 i.e. 91XXYYYZZZZZ.

=item "_dlt_entity_id"

A 19-digit unique ID assigned to the B<text> content template above by DLT operator.

=back


=head1 MISCELLANEOUS

NIC's implementation of DLT compliance requires a DLT approved content template
along with its specific DLT Template ID to be passed to the HTTPS API call. 
While it is simple to implement that functionality in the Send Driver module, as
of 2022-10-08 it is not possible to dieectly pass this DLT_TEMPLATE_ID to the 
driver from Koha ILS for which this driver is primarily written. To accomodate
Koha's current limitation in this regard, a workaround is to embed the approved
19-digit DLT_TEMPLATE_ID at the beginning of each SMS message template in Koha.


=head2 Recipient phone number checks

Additional checks have been placed into the code for ensuring compliance with 
Indian National Numbering Plan 2003 (and its subsequent amendments). This measure 
is expected to prevent user generated errors due to improperly formatted or 
invalid mobile numbers, as noted below:

=over 4

=item Example 1 : "819XXXXYYYYY" 

81 is an invalid country code. As an India specific driver, the country code must be 91.

=item Example 2 : "9XXXXYYYYY"

=item Example 3 : "8XXXXYYYYY"

=item Example 4 : "7XXXXYYYYY"

=item Example 5 : "6XXXXYYYYY"

As per National Numbering Plan 2003, cell phone numbers (GSM, CDMA, 4G, LTE) have to 
start with 9XXXX / 8XXXX / 7XXXX / 6XXXX series (access code + operator identifier). 
A phone number that does not fit this template will be rejected by the driver.

=item Example 6 : "12345678"

=item Example 7 : "12345678901234"

A phone number that is less than 10-digits long or over 12-digits long (including 
country code prefix) will be rejected as invalid input as per NNP 2003. 

=item Example 8 : "+91 9XXXX YYYYY"

=item Example 9 : "+91-9XXXX-YYYYY"

=item Example 10 : "+919XXXXYYYYY"

=item Example 11 : "09XXXXYYYYY"

Phone numbers formatted as above, when input to the driver will be handled 
as "919XXXXYYYYY" by the driver.

=back


=head2 Error Codes

The following error code are returned by the NIC HTTPS API:

=over 4

=item  -2 : Invalid credentials.

=item -19 : Unauthorised access.

=item 000 : SMS Platform Accepted

=back

In the driver we only check if the error code is B<000> in the response sent back
by the SMS Gateway.


=head1 INSTALLATION

See L<https://perldoc.perl.org/perlmodinstall> for information and options 
on installing Perl modules.


=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=SMS-Send-IN-NICSMS>.

=head1 AVAILABILITY

The project homepage is L<https://metacpan.org/release/SMS-Send-IN-NICSMS>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/SMS::Send::IN::NICSMS/>.

Alternatively, you can also visit the GitHub repository for this driver at
L<https://github.com/l2c2technologies/sms-send-in-nicsms>


=head1 ACKNOWLEDGEMENT

State Central Library, Thiruvananthapuram, Kerala who approached regarding the 
possibility of development of a DLT compliant SMS Send driver in Perl for NIC's
SMS Gateway service and provided the necessary inputs to develop and test the 
driver. Thanks also to National Informatics Centre, MeitY, Govt of India for 
the developer documentation of their API for SMS service. Developer colleagues
from the Koha Community and various CPAN contributors who's prior work on 
SMS::Send regional drivers acted as sources of inspiration for the code.


=head1 AUTHOR

Indranil Das Gupta E<lt>indradg@l2c2.co.inE<gt> (on behalf of L2C2 Technologies).


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 L2C2 Technologies

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language system itself, or at your option, any 
later version of Perl 5 you may have available.

This software comes with no warranty of any kind, including but not limited to 
the implied warranty of merchantability.

Your use of this software may result in charges against / use of available 
credits on your NIC SMS Service account. Please use this software carefully 
keeping a close eye on your usage and/or billing, The author takes no 
responsibility for any such charges accrued.

Document published by L2C2 Technologies [ https://www.l2c2.co.in ]

=cut
