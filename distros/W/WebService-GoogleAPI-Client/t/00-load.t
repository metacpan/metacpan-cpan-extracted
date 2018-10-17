#!perl -T

=head2 USAGE

To run manually in the local directory assuming gapi.json present in source root and in xt/author/calendar directory
  C<prove -I../lib 00-load.t -w -o -v>

NB: is also run as part of dzil test

=cut

use 5.006;
use strict;
use warnings;
use Test::More;

use Cwd;
my $dir = getcwd;

# plan tests => 1; ## or at end  done_test();
my $DEBUG = 0;

#BEGIN {

use_ok( 'WebService::GoogleAPI::Client' ) || print "Bail out!\n";

my $default_file = $ENV{ 'GOOGLE_TOKENSFILE' } || "$dir/../../gapi.json";    ## assumes running in a sub of the build dir by dzil
my $user         = $ENV{ 'GMAIL_FOR_TESTING' } || '';                        ## will be populated by first available if set to '' and default_file exists


subtest 'Test with User Configuration' => sub {
  plan( skip_all => 'No user configuration - set $ENV{GOOGLE_TOKENSFILE} or create gapi.json in dzil source root directory' ) unless -e $default_file;

  ok( 1 == 1, 'Configured WebService::GoogleAPI::Client User' );
  my $gapi = WebService::GoogleAPI::Client->new( debug => $DEBUG );

  $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } ) || croak( $! );
  my $aref_token_emails = $gapi->auth_storage->storage->get_token_emails_from_storage;
  $user = $aref_token_emails->[0] unless $user;                              ## default to the first user if none defined yet

  #note("ENV CONFIG SETS $ENV{'GMAIL_FOR_TESTING'} WITHIN $ENV{'GOOGLE_TOKENSFILE'} ");

  if ( -e $default_file && $user )
  {
    note( "Running tests with user '$user' using '$default_file' credentials" );
    $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } );
    $gapi->user( $user );

    #p($gapi);

  }
};    ## END 'Test with User Configuration' SUBTEST


#note("Testing WebService::GoogleAPI::Client $WebService::GoogleAPI::Client::VERSION, Perl $], $^X");

done_testing();
