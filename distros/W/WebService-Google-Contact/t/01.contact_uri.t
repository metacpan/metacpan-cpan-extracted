use Test::More tests => 1;
use WebService::Google::Contact;

my $google = WebService::Google::Contact->new;
my $next = $google->uri_to_login('http://example.com/?next=1');
my $is_uri = 'https://www.google.com/accounts/AuthSubRequest?scope=http%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds&session=1&next=http%3A%2F%2Fexample.com%2F%3Fnext%3D1&secure=0';

is($next, $is_uri, 'valid_login_uri');





