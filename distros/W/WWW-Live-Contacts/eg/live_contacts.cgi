#!/usr/local/bin/perl

use strict;
use warnings;

use CGI;
use File::Spec;
use URI;
use WWW::Live::Auth::ConsentToken;
use WWW::Live::Auth;
use WWW::Live::Contacts;

my $cgi = CGI->new();

eval {

  my $script_url = URI->new( $cgi->url );
  my $script_context = $script_url->path();
  my $return_url = $script_url;
  $return_url =~ s/live_contacts\.cgi$/live_auth\.cgi/;

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

  my $ct = $cgi->cookie( 'consent_token' );
  if ( $ct ) {
    $ct = WWW::Live::Auth::ConsentToken->new(
      'consent_token' => $ct,
      'secret_key'    => $secret_key,
    );
    
    if ( $ct->expires < time() ) {
      my $auth = WWW::Live::Auth->new(
        'application_id' => $application_id,
        'secret_key'     => $secret_key,
      );
      $ct = $auth->refresh_consent( 'consent_token' => $ct );
    }
  }
  
  if ( $ct ) {
    my $ua = WWW::Live::Contacts->new( 'consent_token' => $ct );
    my @contacts = $ua->get_contacts()->entries();
    print $cgi->header, $cgi->start_html('List Contacts');
    print "<h1>List of Contacts</h1>";
    
    for my $c ( @contacts ) {
      my $id = $c->id;
      print "<h2>Contact $id</h2>\n";
      print "<table>\n";
      if ( $c->full_name ) {
        printf "<tr><th align=\"left\">%s</th><td>%s</td></tr>\n", 'Name', $c->full_name;
      }
      for ( $c->emails ) {
        printf "<tr><th align=\"left\">%s</th><td>%s</td></tr>\n", $_->type.' email', $_->address;
      }
      for ( $c->addresses ) {
        printf "<tr><th align=\"left\">%s</th><td>%s</td></tr>\n", $_->type.' address', $_->full('<br/>');
      }
      print "</table>\n";
    }
    
    
    print $cgi->end_html();
  }
  
  else {
    my $auth = WWW::Live::Auth->new(
      'application_id' => $application_id,
      'secret_key'     => $secret_key,
    );
    my $url = $auth->consent_url(
      'offers'      => 'Contacts.View',
      'privacy_url' => 'http://mysite.com/privacy_policy.html',
      'return_url'  => $return_url,
      'context'     => $script_context,
    );
    print $cgi->redirect( -status => 302, -uri => $url );
  }
};
if ($@) {
  _error($@);
}
  
sub _error {
  my $err = shift;
  print $cgi->header, $cgi->start_html('List Contacts');
  print '<p>Error: '.$err.'</p>';
  print $cgi->end_html;
  exit 1;
}
__END__

=head1 NAME

WWW::Live::Contacts example script - A sample application

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

=cut