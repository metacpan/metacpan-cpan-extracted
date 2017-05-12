#!perl

use warnings;
use strict;

use Test::More tests => 5;

use WWW::FastPass;
use URI;

my $script = eval { 
    WWW::FastPass::script('key', 'secret', 'test@example.com',
                          'testname', 'testuid') 
};
ok((not $@), 'Called script successfully');
ok($script, 'Got a result from the script function');

like($script, qr/^<script/, 'Result begins with script tag');
like($script, qr/<\/script>$/, 'Result ends with closing script tag');
like($script, 
     qr/add_js\("fastpass", "http:\/\/getsatisfaction.com\/fastpass\?/, 
     'Result appears to contain the fastpass URL');

1;
