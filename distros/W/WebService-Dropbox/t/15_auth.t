use strict;
use Test::More;
use WebService::Dropbox;

if (!$ENV{'DROPBOX_APP_KEY'} or !$ENV{'DROPBOX_APP_SECRET'} or !$ENV{'DROPBOX_REFRESH_TOKEN'}) {
    plan skip_all => 'missing App Key, App Secret, and/or Refresh Token';
}


my $dropbox = WebService::Dropbox->new({
    key       => $ENV{'DROPBOX_APP_KEY'},
    secret    => $ENV{'DROPBOX_APP_SECRET'},
    env_proxy => 1,
});

$dropbox->debug;
$dropbox->verbose;

### initial authorization to get a refresh token
#my $url = $dropbox->authorize({ token_access_type => 'offline' });
#print "Go To $url\n";
#print "Enter code : ";
#chomp( my $code = <STDIN> );
#my $result = $dropbox->token($code) or die $dropbox->error;
#printf("Refresh Token: %s\nAccess Token: %s\n", $result->{'refresh_token'}, $result->{'access_token'});
#$VAR1 = {
#          'account_id' => '...',
#          'uid' => '...',
#          'refresh_token' => '...',
#          'scope' => 'account_info.read files.content.read files.metadata.read sharing.read ...',
#          'expires_in' => 14399,
#          'token_type' => 'bearer',
#          'access_token' => '...',
#        };

## Test getting an access token when you only have the refresh token
my $result = $dropbox->refresh_access_token($ENV{'DROPBOX_REFRESH_TOKEN'}) or die $dropbox->error;
is $dropbox->res->code, 200;
is $result->{'token_type'}, 'bearer';
my $token = $result->{'access_token'};
like $token, qr/\S+/;

done_testing();
