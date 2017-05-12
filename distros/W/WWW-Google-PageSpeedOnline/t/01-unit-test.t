#!perl

use strict; use warnings;
use WWW::Google::PageSpeedOnline;
use Test::More tests => 8;

my ($api_key, $page, $title);
$api_key = 'Your_API_Key';

eval {
    $page = WWW::Google::PageSpeedOnline->new();
};
like($@, qr/Missing required arguments: api_key/);

eval {
    $page = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process(url => 'http://localhost');
};
like($@, qr/ERROR: Parameters have to be hash ref/);

eval {
    $page = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({ strategy => 'desktop' });
};
like($@, qr/ERROR: Missing mandatory param: url/);

eval {
    $page = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({url => 'http:localhost' });
};
like($@, qr/ERROR: Invalid data type 'url'/);

eval {
    $page = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({url      => 'http://code.google.com/speed/page-speed/',
                    strategy => 'deesktop'});
};
like($@, qr/ERROR: Invalid data type 'strategy' found/);

eval {
    $page = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({url      => 'http://code.google.com/speed/page-speed/',
                    strategy => 'desktop',
                    rule     => 'XYZ'});
};
like($@, qr/ERROR: 'Rules' should be passed in as arrayref/);

eval {
    $page = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({url      => 'http://code.google.com/speed/page-speed/',
                    strategy => 'desktop',
                    rule     => ['XYZ']});
};
like($@, qr/ERROR: Invalid 'rule' found \[XYZ\]/);

eval {
    $page = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({url      => 'http://code.google.com/speed/page-speed/',
                    strategy => 'desktop',
                    rule     => ['AvoidCssImport'],
                    temp     => 1});
};
like($@, qr/ERROR: Received invalid param: temp/);
