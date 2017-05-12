#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

my @tests = (
    ['example2','title','FEED TITLE','title'],
    ['example3','title','FEED TITLE','dc:title'],
    ['example4','title','FEED TITLE','title'],
    ['example5','title','FEED TITLE','title'],
    ['example6','title','FEED TITLE','dc:title'],
    ['example17','link','http://www.example.com/FEED/ALTERNATE/LINK/','link'],
    ['example18','link','http://www.example.com/FEED/ALTERNATE/LINK/','dc:relation/@rdf:resource'],
    ['example21','link','http://www.example.com/FEED/ALTERNATE/LINK/','link'],
    ['example22','link','http://www.example.com/FEED/ALTERNATE/LINK/','link'],
    ['example23','link','http://www.example.com/FEED/ALTERNATE/LINK/','dc:relation/@rdf:resource'],
    ['example40','description','FEED SUMMARY','description'],
    ['example41','description','FEED SUMMARY','dc:description'],
    ['example42','description','FEED SUMMARY','description'],
    ['example43','description','FEED SUMMARY','description'],
    ['example44','description','FEED SUMMARY','dc:description'],
    ['example86','description','FEED SUMMARY','dcterms:alternative'],
    ['example75','format','FEED FORMAT','dc:format'],
    ['example75','contributor','FEED CONTRIBUTOR 2','dc:contributor'],
    ['example75','coverage','FEED COVERAGE','dc:coverage'],
    ['example75','creator','AUTHOR','dc:creator'],
    ['example75','creator','AUTHOR','author'],
    ['example89','identifier','http://www.example.com/IDENTIFIER','dc:identifier/@rdf:resource'],
    ['example90','identifier','http://www.example.com/IDENTIFIER','dc:identifier'],
    ['example17','identifier','http://www.example.com/FEED/ALTERNATE/LINK/','link'],
    ['example88','generator','http://www.example.com/FEED/GENERATOR','admin:generatorAgent/@rdf:resource'],
    ['example88a','generator','http://www.example.com/FEED/GENERATOR','admin:generatorAgent'],
    ['example87','generator','FEED GENERATOR','generator'],
    ['example86','issued_strict','2001-01-01T05:00:00+0000','dcterms:issued'],
    ['example86','issued','2001-01-01T05:00:00+0000','dcterms:issued'],
    ['example75','issued','2001-01-01T05:00:00+0000','dc:date'],
    ['example87','issued','2000-01-01T12:00:00+0000','lastBuildDate'],
    ['example091','issued','2000-01-01T12:00:00+0000','rss091:lastBuildDate'],
    ['example84','language','en-us','@xml:lang'], 
    ['example75','language','en-us','dc:language'], 
    ['example17','language','en-us','language'],
    ['example091','language','en-us','rss091:language'],
    ['example88','maintainer','mailto:foo@example.com','admin:errorReportsTo/@rdf:resource'],
    ['example88a','maintainer','mailto:foo@example.com','admin:errorReportsTo'],
    ['example87','maintainer','WEBMASTER','webMaster'],
    ['example86','modified_strict','2001-01-01T05:00:00+0000','dcterms:modified'],
    ['example86','modified','2001-01-01T05:00:00+0000','dcterms:modified'],
    ['example75','modified','2001-01-01T05:00:00+0000','dc:date'],
    ['example87','modified','2000-01-01T12:00:00+0000','lastBuildDate'],
    ['example091','modified','2000-01-01T12:00:00+0000','rss091:lastBuildDate'],
    ['example75','publisher','FEED PUBLISHER','dc:publisher'],
    ['example78','publisher','EDITOR','managingEditor'],
    ['example091','publisher','EDITOR','rss091:managingEditor'],
    ['example89','relation','http://www.example.com/FEED/RELATION','dc:relation/@rdf:resource'],
    ['example90','relation','http://www.example.com/FEED/RELATION','dc:relation'],
    ['example75','rights','FEED RIGHTS','dc:rights'],
    ['example78','rights','FEED RIGHTS','/channel/copyright'],
    ['example82','rights','FEED RIGHTS','/channel/creativeCommons:license'],
    ['example091','rights','FEED RIGHTS','/channel/rss091:copyright'],
    ['example75','source','FEED SOURCE','dc:source'],
    ['example87','source','FEED SOURCE','source'],
    ['example2','source','FEED TITLE','title'],
    ['example75','subject','FEED SUBJECT','dc:subject'],
    ['example87','subject','FEED SUBJECT','category'],
    ['example75','type','FEED TYPE','dc:type'],
    ['example86','valid','2001-01-01T05:00:00+0000','dcterms:valid'], 
    ['example87','valid','2000-01-01T12:00:00+0000','expirationDate']
);

use Test::More tests => 61;

use XML::RAI;
use File::Spec; # !!!!
use FileHandle;

foreach my $test (@tests) {
    my($key, $meth, $val, $for) = @$test;
    next unless $key && $key ne '' && $val && $val ne '';
    my $file = File::Spec->catfile('x',"$key.xml");
    my $fh;
    open $fh, $file;
    my $rai = XML::RAI->parse_file($fh);
    my $channel = $rai->channel;
#warn $channel->$meth if $for eq 'expirationDate';
    ok($channel->$meth && $channel->$meth eq $val,"$meth on $file looking for $for");
}