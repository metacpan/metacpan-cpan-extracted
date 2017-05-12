use strict;
use warnings;

use XML::RSS;

use Test::More;

if (eval "require Test::Differences") {
    Test::Differences->import;
    plan tests => 3;
}
else {
    plan skip_all => 'Test::Differences required';
}

my $simple_xml = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
>

<channel>
<title></title>
<link></link>
<description></description>
<itunes:category text="Technology"/>

</channel>
</rss>
EOF

my $sub_xml = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
>

<channel>
<title></title>
<link></link>
<description></description>
<itunes:category text="Technology">
<itunes:category text="Computers"/>
</itunes:category>

</channel>
</rss>
EOF

my $complex_xml = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
>

<channel>
<title></title>
<link></link>
<description></description>
<itunes:category text="Society &#x26; Culture">
<itunes:category text="History"/>
</itunes:category>
<itunes:category text="Technology">
<itunes:category text="Gadgets"/>
<itunes:category text="Computers"/>
<itunes:category text="News"/>
</itunes:category>

</channel>
</rss>
EOF

my $simple_rss  = XML::RSS->new(version => '2.0');
my $sub_rss     = XML::RSS->new(version => '2.0');
my $complex_rss = XML::RSS->new(version => '2.0');

foreach my $rss ($simple_rss, $sub_rss, $complex_rss) {
    $rss->add_module(
        prefix => 'itunes',
        uri    => 'http://www.itunes.com/dtds/podcast-1.0.dtd'
    );
}

$simple_rss->channel(itunes => {category => {text => 'Technology'}});

$sub_rss->channel(
    itunes => {
        category => {
            text     => 'Technology',
            category => {text => 'Computers'}
        }
    }
);

$complex_rss->channel(
    itunes => {
        category => [
            {   text     => 'Society & Culture',
                category => {text => 'History'}
            },
            {   text     => 'Technology',
                category => [{text => 'Gadgets'}, {text => 'Computers'}, {text => 'News'}]
            }
        ]
    }
);


# TEST
eq_or_diff($simple_rss->as_string . "\n", $simple_xml, 'Single category');

# TEST
eq_or_diff($sub_rss->as_string . "\n", $sub_xml, 'Subcategory');

# TEST
eq_or_diff($complex_rss->as_string . "\n", $complex_xml, 'Multiple categories with subcategoris');

