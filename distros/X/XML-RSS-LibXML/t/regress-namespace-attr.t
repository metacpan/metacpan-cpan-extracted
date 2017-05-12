use strict;
use Test::More tests => 3;
use XML::RSS::LibXML;

my $rss = XML::RSS::LibXML->new;
eval {
    $rss->parse(<<EORSS);
<rss xmlns:media="http://search.yahoo.com/mrss" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:creativeCommons="http://backend.userland.com/creativeCommonsRssModule" xmlns:feedburner="http://rssnamespace.org/feedburner/ext/1.0" version="2.0">
<channel>
   <admin:generatorAgent xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://www.typepad.com/" />
</channel>
</rss>
EORSS
};
ok(!$@, "parse check. $@");

is($rss->{channel}{admin}{generatorAgent}{_content}, '');
is($rss->{channel}{admin}{generatorAgent}{admin}, 'http://webns.net/mvcb/');
