package VisualDreams::Yubikey::online;

our $VERSION = '0.06';

use warnings;
use strict;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use LWP::Simple;
use MIME::Base64;
use URI::Escape;

=head1 NAME
          
VisualDreams::Yubikey::online - Yubikey online authentication

=head1 DESCRIPTION
                         
This module will authenticate with the online Yubico API authentication server and return its results
in a HASH. This module is to be implemented in the VisualDreams engine.
                         
=head1 VERSION

Version 0.06

=head1 SYNOPSIS
        
  use VisualDreams::Yubikey::online;

  my $yubify = VisualDreams::Yubikey::online->new("ID","Base64 encoded API key");

  my $yubirecord = $yubify->verifyOnline($otp);

  my $url = $yubify->createUrl($otp);
  my $signedurl = $yubify->createSignedUrl($otp);
  my $signUrl = $yubify->signUrl($url);

=head1 FUNCTIONS

=head2 new

Input : API-ID and API-KEY

Initializes the module to standard API-ID, API-KEY and API-URL.
WARNING: Signed messages will automagically work with a valid Base-64 API key!

=cut 

sub new {
  my $class = shift;
  my $apiId = shift || die("Need atleast an Yubikey API ID");
  my $apiKey = shift || "";
  my $apiUrl = shift || 'http://api.yubico.com/wsapi/verify?';
  my $self = { apiId    => $apiId,
               apiKey   => $apiKey,
               apiUrl   => $apiUrl,
             };

  bless $self, $class;
  return $self;
}

=head2 signUrl

Signs the URL with API-ID, API-KEY and incoming url

Input : url
Output : signed base-64 encoded hmac

=cut 

sub signUrl($) {
  my $self = shift;
  my $message = shift;
  my $apiKeyDecoded = MIME::Base64::decode($self->{apiKey});
  my $hmac = hmac_sha1($message, $apiKeyDecoded);
  my $signature = uri_escape(MIME::Base64::encode($hmac),"\x2b");
  return($signature);
}

=head2 createUrl

Create standard URL with API-ID and OTP

Input : otp
Output : piece of url containing id and otp

=cut 


sub createUrl {
  my $self = shift;
  my $otp = shift;
  my $message = "id=$self->{apiId}&otp=$otp";
  return($message);
}

=head2 createSignedUrl

Create Signed URL with API-ID, API-KEY and OTP

Input : otp
Output : piece of url containing id, otp and base-64 hmac signature

=cut 

sub createSignedUrl {
  my $self = shift;
  my $otp = shift;
  my $message = $self->createUrl($otp);
  my $apiSignature = $self->signUrl($message);     
     $message .= "&h=$apiSignature";
  return($message);
}

sub returnYubiField {
  my $self = shift;
  my $content = shift;
  my $identifier = shift;
  chomp($content);
  if ($content =~ m/$identifier=(.*)/i) {
    my $return = $1;
    return($return);
  } 
}

=head2 verifyOnline

Verify the OTP with the Yubico server

Input : otp
Output : record with hmac, status and timestamp

=cut 


sub verifyOnline {
  my $self = shift;
  my $otp = shift;
  my $signed;
  my $url = $self->{apiUrl};
  my $yubirecord;
  my $errorstatus;

  if ($self->{apiKey}) {
    $url .= $self->createSignedUrl($otp);
  } else {
    $url .= $self->createUrl($otp);
  }    

  my $content = get($url);

  # offer support for more responses later on!

  if ($content) {
    my %yubiResponses =  ("hmac",   "h", 
                          "time",   "t",
                          "status", "status");

  
    while (my ($humanIdentifier, $yubIdentifier) = each(%yubiResponses)) {
         $yubirecord->{$humanIdentifier} = $self->returnYubiField($content,$yubIdentifier);
    }

  } else {
    $yubirecord->{status} = "Could not retrieve status from Yubico";
  }

  return($yubirecord);
}



1;
__END__
          
=head1 REQUIRES

Perl 5, L<Digest::HMAC_SHA1>, L<LWP::Simple>, L<MIME::Base64>, L<URI::Escape>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VisualDreams::Yubikey::online

=head2 EXPORT
                         
None by default.

=head1 AUTHOR
                         
Gunther Voet, Freaking Wildchild: E<lt>oss@xsrv.netE<gt> and E<lt>gunther.voet@gmail.comE<gt>

=head1 VisualDreams

Specifically created for the VisualDreams engine. More to come soon!

=head1 COPYRIGHT & LICENSE

Copyright 2008 Gunther Voet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
