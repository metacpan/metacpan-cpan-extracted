#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

my @tests = (
    ['example1','ping','http://www.example.com/PING','trackback:ping/@rdf:resource'],
    ['example2','ping','http://www.example.com/PING','trackback:ping'],
    ['example1','pinged','http://www.example.com/PINGED','trackback:about/@rdf:resource'],
    ['example2','pinged','http://www.example.com/PINGED','trackback:about']
);

use Test::More tests => 5;

use XML::RAI 1.3;
use File::Spec;
use FileHandle;

use_ok('XML::RAI::TrackBack');

foreach my $test (@tests) {
    my($key, $meth, $val, $for) = @$test;
    my $file = File::Spec->catfile('x',"$key.xml");
    my $fh;
    open $fh, $file;
    my $rai = XML::RAI->parse_file($fh);
    my $i = $rai->items->[0];
    ok($i->$meth eq $val,"$meth on $file looking for $for");
}
