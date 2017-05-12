#!/usr/local/bin/perl

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Spec;
use WWW::Live::Auth;

my $cgi = CGI->new();

unless ( $cgi->param() ) {
  _error("Access to this script is intended for receiving consent from Windows Live; it does not provide content of its own");
}

eval {

  my $application_id;
  my $secret_key;

  my @path = File::Spec->splitpath($0);
  pop @path;
  my $filename = File::Spec->catfile( @path, 'example.key' );
  open(KEYFILE, '<', $filename) || _error("Unable to open $filename");
  while (defined (my $line = <KEYFILE>)) {
    chomp $line;
    if ($line =~ /^application_id = (\S+)/) {
      $application_id = $1;
    } elsif ($line =~ /^secret_key = (\S+)/) {
      $secret_key = $1;
    }
  }
  close KEYFILE;

  $application_id || _error("Application ID not found in $filename");
  $secret_key || _error("Secret key not found in $filename");

  $application_id eq 'REPLACE_ME' && _error("Application ID has not been set in $filename");
  $secret_key eq 'REPLACE_ME' && _error("Secret Key has not been set in $filename");

  my $auth = WWW::Live::Auth->new(
    'application_id' => $application_id,
    'secret_key'     => $secret_key
  );
  my ( $consent_token, $app_context ) = $auth->receive_consent( $cgi );

  my $uri = URI->new( $cgi->url );
  $uri->path( $app_context );
  
  my $cookie = $cgi->cookie( -name    => 'consent_token',
                             -value   => $consent_token->as_string,
                             -expires => '+1y' );
  
  print $cgi->header( -status   => 302,
                      -location => $uri->as_string,
                      -cookie   => $cookie );
};
if ($@) {
  _error($@);
}
  
sub _error {
  my $err = shift;
  print $cgi->header, $cgi->start_html;
  print '<p>Error: '.$err.'</p>';
  print $cgi->end_html;
  exit 1;
}
__END__

=head1 NAME

WWW::Live::Auth example script - Handles delegated authentication

=head1 SYNOPSIS

This script is only useful in combination with another application. See the
WWW::Live::Contacts package.

=head1 VERSION

1.0.0

=head1 AUTHOR

Andrew M. Jenkinson <jenkinson@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 Andrew M. Jenkinson.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 SEE ALSO

L<WWW::Live::Contacts>

=cut