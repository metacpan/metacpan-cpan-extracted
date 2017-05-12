use strict;
use Test::More (tests => 2);
use XML::RSS::LibXML;

for my $version (qw(1.0 2.0)) {
    my $rss = XML::RSS::LibXML->new(version => "2.0");
    $rss->add_module(prefix => "content",
        uri => "http://purl.org/rss/1.0/modules/content/"
    );
    $rss->add_item(
        link => 'poo',
        content => {
            'encoded' => 'blah'
        },
        'title' => 'foo'
    );

    like($rss->as_string, qr/<content:encoded>/);
}
    
1;
