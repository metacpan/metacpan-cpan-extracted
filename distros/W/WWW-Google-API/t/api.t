use Test::More qw(no_plan);

use YAML::Syck qw(LoadFile);;

BEGIN { 
  use_ok('WWW::Google::API');
}

my $gapi_file = $ENV{HOME}.'/.gapi';

my $file_conf;
$file_conf = LoadFile($gapi_file) if -e $gapi_file;

my $api_key  = $ENV{gapi_key}  || $file_conf->{key}  || '';
my $api_user = $ENV{gapi_user} || $file_conf->{user} || '';
my $api_pass = $ENV{gapi_pass} || $file_conf->{pass} || '';

my $api;

if ($api_key and $api_user and $api_pass) {

  eval { 
    $api = WWW::Google::API->new( 'gbase',
                                   ( { auth_type => 'ProgrammaticLogin',
                                       api_key   => $api_key,
                                       api_user  => $api_user,
                                       api_pass  => $api_pass  },
                                     { } ) );
  };
  if ($@) {
    my $error = $@;
    warn $error;
  }

  isa_ok($api, 'WWW::Google::API', 'API Client');

  isnt($api->token, '', 'Token is not empty');

} else {
  diag("API Key, User, and Pass not all defined.  Skipping network tests.");
}
