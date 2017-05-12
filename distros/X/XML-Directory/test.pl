# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN {
    unshift @INC, 'examples';
}

use XML::Directory(qw(get_dir));
use XML::Directory::String;
use Cwd;

BEGIN { $| = 1; print "1..5\n"; }
END {print "There were problems!\n" unless $sum == 5;}
END {print "Passed\n" if $sum == 5;}

# 1
$r[0] = 1;
print "not ok 1\n" unless $r[0];
print "ok 1\n" if $r[0];

# 2
my @xml = get_dir('examples',1);
my $xml = join '', @xml;
chdir('..');
$r[1] = 1 if $xml =~ /dir2xml_string.pl/;
print "not ok 2\n" unless $r[1];
print "ok 2\n" if $r[1];

# 3
my $depth0 = 25;
my $dir = new XML::Directory::String('examples',1,$depth0);
my $depth = $dir->get_maxdepth;
$r[2] = 1 if $depth == $depth0 ;
print "not ok 3\n" unless $r[2];
print "ok 3\n" if $r[2];

#4
eval "require XML::SAX::Base";
if ($@) {
    $r[3] = 1;
    print "skipping 4\n";

} else {
    require XML::Directory::SAX;
    require MyHandler;
    require MyErrorHandler;
    my $h = MyHandler->new();
    my $e = MyErrorHandler->new();
    my $dir = XML::Directory::SAX->new(Handler => $h, details => 3);
    my $rc  = $dir->get_details;
    $r[3] = 1 if $rc == 3; 
    print "not ok 4\n" unless $r[3];
    print "ok 4\n" if $r[3];
}

#5
eval "require RDF::Notation3";
if ($@) {
    $r[4] = 1;
    print "skipping 5\n";

} else {
    require RDF::Notation3;
    my $dir = new XML::Directory::String('examples',2);
    $dir->enable_rdf('index.n3');
    $dir->parse;
    $res = $dir->get_string;
    $r[4] = 1 if $res =~ /dc:Title/; 
    print "not ok 5\n" unless $r[4];
    print "ok 5\n" if $r[4];
}

$sum = 0;
foreach (@r) {
    $sum += $_;
}
