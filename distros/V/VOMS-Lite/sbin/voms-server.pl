#!/usr/bin/perl


#use IO::Socket::SSL qw(debug4);
use IO::Socket::SSL;
use HTTP::Daemon::SSL;
use HTTP::Status;
use HTTP::Response;
use Sys::Hostname;
use VOMS::Lite qw(Issue);
use VOMS::Lite::PEMHelper qw(decodeCert encodeAC);


my @chain;

my $home=$ENV{'HOME'};
my $capath=(defined $ENV{X509_CERT_PATH})?$ENV{X509_CERT_PATH}:"/etc/grid-security/certificates";
my $host=hostname;
my $cert=(defined $ENV{X509_USER_CERT})?$ENV{X509_USER_CERT}:"/etc/grid-security/hostcert.pem";
my $key=(defined $ENV{X509_USER_KEY})?$ENV{X509_USER_KEY}:"/etc/grid-security/hostkey.pem";

my $d = new HTTP::Daemon::SSL( LocalAddr => $host, 
                               LocalPort => 8443, 
                               SSL_ca_path => $capath,
                               SSL_cert_file => $cert,
                               SSL_key_file => $key,
                               SSL_verify_mode => 0x07,
                               SSL_verify_callback => \&verify
#                              ,SSL_check_crl => 1    # use me if version openssl used to compile Net::SSLeay > 0.9.7b
                             ) || die;

print "(blocking) Server Listening at ", $d->url, "\n";
$|=1;     # flush after each write

while (my $c = $d->accept) {
  while (my $r = $c->get_request) {

# Find out requested type
    my $type = MimeType( $r->header("Accept") );

# Send response (get attribute if request is all OK
    if ( $type eq "" ) { $c->send_error(RC_UNSUPPORTED_MEDIA_TYPE) }
    elsif ($r->method eq 'GET' && $r->url->path =~ /^(\/[a-zA-Z0-9_.-]+(?:\/(?:[\040-\176]|\%[0-9a-fA-F]{2})*)*)$/ ) { # Accept sensible characters
      my $ReqAttrib=$1;
      $ReqAttrib=~ s/%(..)/pack('c',hex($1))/ge;

      print "Incoming request for:$ReqAttrib\n";

      my @encodedCerts = decodeCert(@chain,"CERTIFICATE");

      #do AC stuff here;
      my $ref = VOMS::Lite::Issue(\@encodedCerts,$ReqAttrib);
      my %hash=%$ref;

      my $AC=$hash{AC};
      my @Warnings=@{ $hash{Warnings} };
      my @Errors=@{ $hash{Errors} };
      my @Targets=@{ $hash{Targets} };
      my @Attribs=@{ $hash{Attribs} };

      my $ret;
      if ( @Errors ) { # Send error if error
        if    ( $Errors[0] eq "VOMS::Lite: No VO specified" )                                { $ret=RC_BAD_REQUEST; }
        elsif ( $Errors[0] eq "VOMS::Lite: No Gridmapfile for VO" )                          { $ret=RC_NOT_FOUND; }
        elsif ( $Errors[0] =~ /^VOMS::Lite: Unable to open\/create serial file/ )            { $ret=RC_INSUFFICIENT_STORAGE; }
        elsif ( $Errors[0] eq "VOMS::Lite::AC: Holder certificate not supplied" )            { $ret=RC_UNAUTHORIZED; }
        elsif ( $Errors[0] eq "VOMS::Lite::AC: VOMS AC Serial not supplied" )                { $ret=RC_INSUFFICIENT_STORAGE; }
        elsif ( $Errors[0] eq "VOMS::Lite::AC: VOMS Attributes not supplied" )               { $ret=RC_FORBIDDEN; }
        elsif ( $Errors[0] eq "VOMS::Lite::AC: Unable to parse holder certificate." )        { $ret=RC_UNAUTHORIZED; }
        elsif ( $Errors[0] eq "VOMS::Lite::AC: Unable to get holder certificate's issuer" )  { $ret=RC_UNAUTHORIZED; }
        elsif ( $Errors[0] eq "VOMS::Lite::AC: Unable to get holder certificate's serial" )  { $ret=RC_UNAUTHORIZED; }
        elsif ( $Errors[0] eq "VOMS::Lite::AC: Unable to get holder certificate's subject" ) { $ret=RC_UNAUTHORIZED; }
        else  { $ret=RC_INTERNAL_SERVER_ERROR; }
      }
      else { $ret=RC_OK; }
      my $res = HTTP::Response->new( $ret );
      if ( $type eq "text/html" ) {
        my $errors   = ($#Errors)   ? "" : "<h3>Errors</h3><ul><li>".  (join "<li>", @Errors).  "</ul>\n";
        my $warnings = ($#Warnings) ? "" : "<h3>Warnings</h3><ul><li>".(join "<li>", @Warnings)."</ul>\n";
        my $targets  = ($#Targets)  ? "" : "<h3>Targets</h3><ul><li>". (join "<li>", @Targets) ."</ul>\n";
        my $attribs  = ($#Attribs)  ? "" : "<h3>Attributes</h3><ul><li>". (join "<li>", @Attribs) ."</ul>\n";
        my $ac       = ($AC eq "")  ? "" : "<h3>VOMS Attribute</h3>\n<pre>\n".encodeAC($AC)."</pre>\n";
        $res->header( 'Content_Type' => "text/html" );
        $res->content( "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n".
                       "<html><head>\n<title>VOMS Response</title>\n</head><body>\n".
                       "$attribs$errors$warnings$targets$ac".
                       "</body></html>" );
        $c->send_response($res);
      } else {
        my $errors   = ($#Errors)   ? "" : "\nErrors:\n".  (join "\n\t", @Errors).  "\n";
        my $warnings = ($#Warnings) ? "" : "\nWarnings:\n".(join "\n\t", @Warnings)."\n";
        my $targets  = ($#Targets)  ? "" : "\nTargets:\n". (join "\n\t", @Targets) ."\n";
        my $attribs  = ($#Attribs)  ? "" : "\nAttributes:\n". (join "\n\t", @Attribs) ."\n";
        my $ac       = ($AC eq "")  ? "" : "\n".encodeAC($AC);
        $res->header( 'Content_Type' => "text/plain" );
        $res->content( "$attribs$errors$warnings$targets$ac" );
        $c->send_response($res);
      }
    } 
    elsif ( $r->method eq 'GET' ) { $c->send_error(RC_BAD_REQUEST) }
    elsif ( $r->method ne 'GET' ) { $c->send_error(RC_NOT_IMPLEMENTED) }
    else { $c->send_error(RC_FORBIDDEN) }
  }
  $c->close;
  undef($c);
}

#Seems like the only way to get Net::SSLeay to get access to the certificate chain (find_issuer not implemented)
sub verify {
  my ($OpenSSLSays,$CertStackPtr,$DN,$OpenSSLError)=@_;
  unshift @chain,Net::SSLeay::PEM_get_string_X509(Net::SSLeay::X509_STORE_CTX_get_current_cert($CertStackPtr));
  return $OpenSSLSays;
}

sub MimeType {
  my $typestr=shift;
  $typestr     =~ s/\s//g; 
  my @types   = split ',', $typestr;
  my ($html,$plain,$text,$any,$type)=(0,0,0,0,"none");
  foreach (@types) {
    my @parameters = split ';',$_;
    my $type       = shift @parameters;
    my $q=1;
    foreach (@parameters) { if ( /^q=([0-9](?:.[0-9]+))$/ ) { $q=$1; last; } }
    if    ( $type eq "text/html"  && $q > $html )  { $html=$q; }
    elsif ( $type eq "text/plain" && $q > $plain ) { $plain=$q; }
    elsif ( $type eq "text/*"     && $q > $text )  { $text=$q; }
    elsif ( $type eq "*/*"        && $q > $any  )  { $any=$q; }
  }

  if ( $html >= $plain && $html != 0 ) { return "text/html"; }
  elsif ( $plain != 0 ) { return "text/plain"; }
  elsif ( $text != 0 ) { return "text/html"; }
  elsif ( $any != 0 ) { return "text/html"; }
  else { return ""; }
}

__END__

=head1 NAME

  voms-server.pl

=head1 SYNOPSIS

  A simple VOMS https server using the VOMS::Lite library. 


=head1 DESCRIPTION

  This server porvides a minimal, non-forking example of a VOMS server interface for obtaining VOMS attribute certificates.

  It loosely follows the principles of REST where the client simply uses a  GET method to request Attributes they want:
  GET https://voms.server.fqdn:port/VO/Subgroup/.../Role=role/Capability=capability

 This example server doesn't fork 
 It relies upon a pecularity of the Net::SSLeay verify callback implementation 
   i.e. if Net::SSLeay has verified the incoming credentials to its satisfaction
   then the callback can be used to construct the certificate chain if not then it doesn't
 Therefore it cannot be made to handle GSI proxy certificates without patching NetSSLeay.

=head1 SEE ALSO

VOMS::Lite

If you want a well behaved server consider using Apache with mod_ssl and mod_perl.
If you want proxy certificates to be able to acces a service like this consider using 
Apache with mod_gridsite and mod_perl

This script was originally designed for SHEBANGS, a JISC funded project at The University of Manchester.
http://www.mc.manchester.ac.uk/projects/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
