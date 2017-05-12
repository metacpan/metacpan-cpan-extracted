#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

my @tests = (
    ['example10','title','ENTRY TITLE','title'],
    ['example11','title','ENTRY TITLE','dc:title'],
    ['example12','title','ENTRY TITLE','title'],
    ['example13','title','ENTRY TITLE','title'],
    ['example14','title','ENTRY TITLE','dc:title'],
    ['example28','link','http://www.example.com/ENTRY/ALTERNATE/LINK/','link'],
    ['example29','link','http://www.example.com/ENTRY/ALTERNATE/LINK/','@rdf:about'],
    ['example32','link','http://www.example.com/ENTRY/ALTERNATE/LINK/','link'],
    ['example33','link','http://www.example.com/ENTRY/ALTERNATE/LINK/','guid'],
    ['example34','link','http://www.example.com/ENTRY/ALTERNATE/LINK/','guid[@isPermaLink="true"]'],
    ['example35','link','http://www.example.com/ENTRY/ALTERNATE/LINK/','link'],
    ['example52','abstract','PLAINTEXT ENTRY SUMMARY','description'],
    ['example53','abstract','PLAINTEXT ENTRY SUMMARY','dc:description'],
    ['example54','abstract','PLAINTEXT ENTRY SUMMARY','dcterms:abstract'],
    ['example55','abstract','PLAINTEXT ENTRY SUMMARY','description'],
    ['example56','abstract','PLAINTEXT ENTRY SUMMARY','description[@type="text/plain"]'],
    ['example57','abstract','PLAINTEXT ENTRY SUMMARY','description'],
    ['example58','abstract','PLAINTEXT ENTRY SUMMARY','dc:description'],
    ['example59','abstract','PLAINTEXT ENTRY SUMMARY','dcterms:abstract'],
    ['example62','content','ENTRY CONTENT WITH <b>EMBEDDED MARKUP</b>','content:encoded'],
    ['example63','content','ENTRY CONTENT WITH <b>INLINE MARKUP</b>','xhtml:body'],
    ['example64','content','ENTRY CONTENT WITH <b>INLINE MARKUP</b>','xhtml:div'],
    ['example65','content','ENTRY CONTENT WITH <b>EMBEDDED MARKUP</b>','content:encoded'],
    ['example67','content','ENTRY CONTENT WITH <b>EMBEDDED MARKUP</b>','description[@type="text/html"]'],
    ['example68','content','ENTRY CONTENT WITH <b>EMBEDDED MARKUP</b>','description'],
    ['example72','content','ENTRY CONTENT WITH <b>EMBEDDED MARKUP</b>','dc:description'],
    ['example73','content','ENTRY CONTENT WITH <b>EMBEDDED MARKUP</b>','rss091:description'],
    ['example62','content_strict','ENTRY CONTENT WITH <b>EMBEDDED MARKUP</b>','content:encoded'],
    ['example63','content_strict','ENTRY CONTENT WITH <b>INLINE MARKUP</b>','xhtml:body'],
    ['example64','content_strict','ENTRY CONTENT WITH <b>INLINE MARKUP</b>','xhtml:div'],
    ['example65','content_strict','ENTRY CONTENT WITH <b>EMBEDDED MARKUP</b>','content:encoded'],
    ['example76','format','text/html','dc:format'],
    ['example76','contributor','ENTRY CONTRIBUTOR 2','dc:contributor'],
    ['example76','coverage','ENTRY COVERAGE','dc:coverage'],
    ['example74','created_strict','2001-01-01T05:00:00+0000','dcterms:created'],
    ['example74','created','2001-01-01T05:00:00+0000','dcterms:created'],
    ['example76','created','2001-01-01T05:00:00+0000','dc:date'],
    ['example77','created','2000-01-01T12:00:00+0000','pubDate'], 
    ['example091','created','2000-01-01T12:00:00+0000','rss091:pubDate'],
    ['example76','creator','ENTRY CREATOR','dc:creator'],
    ['example77','creator','ENTRY CREATOR','author'],
    ['example80','identifier','http://www.example.com/IDENTIFIER','dc:identifier/@rdf:resource'],
    ['example81','identifier','http://www.example.com/IDENTIFIER','dc:identifier'],
    ['example33','identifier','http://www.example.com/ENTRY/ALTERNATE/LINK/','guid'],
    ['example35','identifier','http://www.example.com/ENTRY/ALTERNATE/LINK/','link'],
    ['example74','issued_strict','2001-01-01T05:00:00+0000','dcterms:issued'],
    ['example74','issued','2001-01-01T05:00:00+0000','dcterms:issued'],
    ['example76','issued','2001-01-01T05:00:00+0000','dc:date'],
    ['example77','issued','2000-01-01T12:00:00+0000','pubDate'],
    ['example091','issued','2000-01-01T12:00:00+0000','rss091:pubDate'],
    ['example85','language','en-us','@xml:lang'], 
    ['example76','language','en-us','dc:language'], 
    ['example84','language','en-us','/@xml:lang'], 
    ['example75','language','en-us','/channel/dc:language'], 
    ['example17','language','en-us','/channel/language'],
    ['example091','language','en-us','/channel/rss091:language'],
    ['example74','modified_strict','2001-01-01T05:00:00+0000','dcterms:modified'],
    ['example74','modified','2001-01-01T05:00:00+0000','dcterms:modified'],
    ['example76','modified','2001-01-01T05:00:00+0000','dc:date'],
    ['example77','modified','2000-01-01T12:00:00+0000','pubDate'],
    ['example091','modified','2000-01-01T12:00:00+0000','rss091:pubDate'],
    ['example76','publisher','ENTRY PUBLISHER','dc:publisher'],
    ['example75','publisher','FEED PUBLISHER','/channel/dc:publisher'],
    ['example78','publisher','EDITOR','/channel/managingEditor'],
    ['example091','publisher','EDITOR','/channel/rss091:managingEditor'],
    ['example80','relation','http://www.example.com/ENTRY/RELATION','dc:relation/@rdf:resource'],
    ['example81','relation','http://www.example.com/ENTRY/RELATION','dc:relation'],
    ['example76','rights','ENTRY RIGHTS','dc:rights'],
    ['example78','rights','FEED RIGHTS','/channel/copyright'],
    ['example82','rights','FEED RIGHTS','/channel/creativeCommons:license'],
    ['example091','rights','FEED RIGHTS','/channel/rss091:copyright'],
    ['example76','source','ENTRY SOURCE','dc:source'],
    ['example79','source','ENTRY SOURCE','source'],
    ['example76','subject','ENTRY SUBJECT','dc:subject'],
    ['example79','subject','ENTRY SUBJECT','category'],
    ['example76','type','ENTRY TYPE','dc:type'],
    ['example83','valid','2000-01-01T12:00:00+0000','dcterms:valid'], 
    ['example79','valid','2000-01-01T12:00:00+0000','expirationDate']
);

use Test::More tests => 78;

use XML::RAI;
use File::Spec; # !!!!
use FileHandle;

foreach my $test (@tests) {
    my($key, $meth, $val, $for) = @$test;
    my $file = File::Spec->catfile('x',"$key.xml");
    my $fh;
    open $fh, $file;
    my $rai = XML::RAI->parse_file($fh);
    my $item = $rai->items->[0]; # all our example files have one item.
    ok($item->$meth && $item->$meth eq $val,"$meth on $file looking for $for");
}