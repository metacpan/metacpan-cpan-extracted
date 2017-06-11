use strict;
use warnings;
use Test::More;
use WebService::Moodle::Simple;

note 'Testing without a Moodle server';

my $domain = 'moodle.example.com';
my $moodle = WebService::Moodle::Simple->new(
    domain   => $domain,
    username => 'apiuser',
    target   => 'local_wssetup',
    token    => '0123456789abcdef',
);

is(ref($moodle), 'WebService::Moodle::Simple');
is($moodle->dns_uri, "https://${domain}:443", 'uri derived from parameters');


done_testing();


