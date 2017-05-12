#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

my @tests = (
    ['example71','url','http://www.example.com/IMAGE/LINK/','/channel/image[0]/@rdf:about'],
    ['example70','url','http://www.example.com/IMAGE/LINK/','/channel/image[0]/@rdf:resource'],
    ['example69','url','http://www.example.com/IMAGE/LINK/','/channel/image[0]/url'],
    ['example69','title','IMAGE TITLE','/channel/image[0]/title'],
    ['example69','description','IMAGE LINK DESCRIPTION','/channel/image[0]/description'],
    ['example091','description','IMAGE LINK DESCRIPTION','/channel/image[0]/rss091:description'],
    ['example69','link','http://www.example.com/IMAGE/LINKS/TO/','/channel/image[0]/link'],
    ['example69','height','42','/channel/image[0]/height'],
    ['example091','height','42','/channel/image[0]/rss091:height'],
    ['example69','width','42','/channel/image[0]/width'],
    ['example091','width','42','/channel/image[0]/rss091:width']
);

use Test::More tests => 11;

use XML::RAI;
use File::Spec; # !!!!
use FileHandle;

foreach my $test (@tests) {
    my($key, $meth, $val, $for) = @$test;
    my $file = File::Spec->catfile('x',"$key.xml");
    my $fh;
    open $fh, $file;
    my $rai = XML::RAI->parse_file($fh);
    my $img = $rai->image;
    ok($img->$meth eq $val,"$meth on $file looking for $for");
}