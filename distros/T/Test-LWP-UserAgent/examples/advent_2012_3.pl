use strict;
use warnings;
use feature 'say';

use Test::LWP::UserAgent;
use HTTP::Message::PSGI;
use HTTP::Request::Common;
use Plack::Util;

my $useragent = Test::LWP::UserAgent->new;
my $app = Plack::Util::load_psgi('examples/myapp.psgi');
$useragent->register_psgi('mytestdomain.com', $app);
my $response = $useragent->request(GET 'http://mytestdomain.com/foo/bar');

say $response->content;

