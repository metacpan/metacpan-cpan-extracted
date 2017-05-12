use Test::More tests => 1;
use WebService::Livedoor::Auth;
use CGI;

my $auth = WebService::Livedoor::Auth->new({
    app_key => 'ac68fa32da1305dafe3421d012f0aaba',
    secret => 'ccd0ea2d35d7bafd',
});
my %query = (
    v => '1.0',
    userhash => 'KVAk6au7BSk4vmEPdYqqJer90fE',
);

my $q = CGI->new(\%query);
is($auth->calc_sig(\%query), $auth->calc_sig($q));
