# If a .phanfarerc file exist, use it for authentication
# File format:
#   api_key xxx
#   private_key yyy
#   email_address my@email
#   password zzz
#

use Test::More;

eval 'use File::HomeDir; use Config::General; use WWW::Phanfare::API';
plan skip_all => "Required modules for album testing not available: $@" if $@;

my $rcfile = File::HomeDir->my_home . "/.phanfarerc";
#unless ( -r $rcfile ) { diag "Cannot read $rcfile"; done_testing; exit; }
plan skip_all => "Cannot read $rcfile" unless -r $rcfile;
my $conf = new_ok( Config::General => [ $rcfile ] );
unless ( $conf ) { diag "Cannot read $rcfile"; done_testing; exit; }

my %config = $conf->getall;
ok( $config{api_key} and $config{private_key} and $config{email_address} and $config{password} );
unless ( $config{api_key} and $config{private_key} and $config{email_address} and $config{password} ) {
  diag "Cannot test authentiction without api_key, private_key, email_address and password defined in .phanfarerc";
  done_testing;
  exit;
}

my $api = new_ok ( 'WWW::Phanfare::API' => [
  api_key     => $config{api_key},
  private_key => $config{private_key},
] );
unless ( $api ) { diag "Cannot create Phanfare agent"; done_testing; exit; }

my $user = $api->Authenticate(
  email_address => $config{email_address},
  password      => $config{password},
);
ok ( $user->{'stat'} eq 'ok',  "Could not authenticate" );
unless ( $user->{'stat'} eq 'ok' ) {
  diag "Cannot continue without authentication: $user->{code_value}";
  done_testing;
  exit;
}

ok ( defined $user->{session}{uid}, "uid not defined authentication response" );
my $myuid = $user->{session}{uid};
ok ( $myuid > 0, "Invalid uid: $myuid" );
unless ( $myuid > 0 ) {
  diag "Need target_uid for GetAlbumList";
  done_testing;
  exit;
}

my $album = $api->GetAlbumList( target_uid => $myuid );
ok( $album->{stat} eq 'ok', "GetAlbumList request failed" );
ok( ref $album->{albums}{album} eq 'ARRAY' , "Could not get list of albums" );

done_testing();
