use strict;
local $^W = 1;

our $jobname;
require './t/defs.pm';

#Testcases for URL normalization done in module selurl.pm

use Combine::Config;
use Combine::selurl;
use Cwd;
Combine::Config::Init($jobname,getcwd . '/blib/conf');

my $enableprint= shift(@ARGV);

#%tests contains patterns before and after like: $tests{'before'}='after';
my %tests = (   
        'http://www.it.lth.se/courses/vlsi/..\..\users\lambert\RedBeard\Index.html' => 'http://www.it.lth.se/courses/%5C..%5Cusers%5Clambert%5CRedBeard%5CIndex.html',
#http://www.it.lth.se/users/lambert/RedBeard/Index.html ??
        'http://www.it.lth.se/courses/dsi/demo\PowerPoint\Laboratory 3 demonstration.htm' => 'http://www.it.lth.se/courses/dsi/demo%5CPowerPoint%5CLaboratory%203%20demonstration.htm',
        '/foo/bar/.' =>                    '/foo/bar/', 
        '/foo/bar/./' =>                   '/foo/bar/',
        '/foo/bar/..' =>                   '/foo/',
        '/foo/bar/../' =>                  '/foo/',
        '/foo/bar/../baz' =>               '/foo/baz',
        '/foo/bar/../..' =>                '/',
        '/foo/bar/../../' =>               '/',
        '/foo/bar/../../baz' =>            '/baz',
        '/foo/bar/../../../baz' =>         '/../baz',
        '/foo/bar/../../../../baz' =>      '/baz', #??
        '/./foo' =>                        '/foo',
        '/../foo' =>                       '/../foo',
        '/foo.' =>                         '/foo.',
        '/.foo' =>                         '/.foo',
        '/foo..' =>                        '/foo..',
        '/..foo' =>                        '/..foo',
        '/./../foo' =>                     '/../foo',
        '/./foo/.' =>                      '/foo/',
        '/foo/./bar' =>                    '/foo/bar',
        '/foo/../bar' =>                   '/bar',
        '/foo//' =>                        '/foo/',
        '/foo///bar//' =>                  '/foo/bar/',    
        'http://www.foo.com:80/foo' =>     'http://www.foo.com/foo',
        'http://%20www.foo.com/sp1' =>     'http://www.foo.com/sp1',
        'http://www.%20foo.com/sp2' =>     'http://www.foo.com/sp2',
        'http://www.foo.com/foo/../bar/' =>     'http://www.foo.com/bar/',
        'http://www.foo.com/../bar/' =>     'http://www.foo.com/../bar/',
        'http://www.foo.com:8000/foo' =>   'http://www.foo.com:8000/foo',
        'http://www.foo.com./foo/bar.html' => 'http://www.foo.com/foo/bar.html',
        'http://www.foo.com.:81/foo' =>    'http://www.foo.com:81/foo',
        'http://www.foo.com/%7ebar' =>     'http://www.foo.com/~bar',
        'http://www.foo.com/%7Ebar' =>     'http://www.foo.com/~bar',
        'ftp://user:pass@ftp.foo.net/foo/bar' => 'ftp://user:pass@ftp.foo.net/foo/bar',
        'http://USER:pass@www.Example.COM/foo/bar' => 'http://USER:pass@www.example.com/foo/bar',
        'http://www.example.com./' =>      'http://www.example.com/',
        'http://www.fo.bar'  =>            'http://www.fo.bar/',
        'http://WWW.foo.nz:80/'  =>        'http://www.foo.nz/'
   );
my $base='http://www.lth.se/';
my $tt;
my $netlocid;
my $urlid;
my $err = 0; #FALSE
my $i=0;
foreach my $t (keys(%tests)) { $i++; }
print "1..$i\n";
$i=0;
foreach my $t (keys(%tests)) {
    print "\nDoing $t\n" if $enableprint;
    $i++;
    my $lerr=0;
    my $u =  Combine::selurl->new_abs($t,$base);
    $u->normalise;
    if ( ($u->path ne $tests{$t}) &&  ($u->as_string ne $tests{$t}) ) {
	$tt = $u->as_string;
	print "WAS: $t\nSHO: $tests{$t}\nIS:  $tt\n" if $enableprint;
	$err = 1; #TRUE
	$lerr = 1; #TRUE
    } else {
#	($netlocid,$urlid) = $u->normaliseId;
#        my $uu = selurl->new_abs($tests{$t},$base);
#	my ($unetlocid,$uurlid) = $uu->normaliseId;
#	if ( ($netlocid != $unetlocid) || ($urlid != $uurlid) ) {
#	    print "IDerr: $t ($netlocid,$urlid), $tests{$t} ($unetlocid,$uurlid)\n";
#	    $err = 1; #TRUE
#	} else {
#	    print "IDOK: $t ($netlocid,$urlid), $tests{$t} ($unetlocid,$uurlid)\n" if $enableprint;
#	}
    }
    $tt = $u->as_string; print "Result with base: $tt\n" if $enableprint;
   
    if ( $t =~ /^http:/ ) {
	$u =  Combine::selurl->new($t);
	$u->normalise;
	if ( ($u->path ne $tests{$t}) &&  ($u->as_string ne $tests{$t}) ) {
	    $tt = $u->as_string;
	    print "WAS: $t\nSHO: $tests{$t}\nIS:  $tt\n" if $enableprint;
	    $err = 1; #TRUE
	    $lerr = 1; #TRUE
	} else {
#	    ($netlocid,$urlid) = $u->normaliseId;
#	    my $uu = URL->new($tests{$t},$base);
#	    my ($unetlocid,$uurlid) = $uu->normaliseId;
#	    if ( ($netlocid != $unetlocid) || ($urlid != $uurlid) ) {
#		print "IDerr: $t ($netlocid,$urlid), $tests{$t} ($unetlocid,$uurlid)\n";
#		$err = 1; #TRUE
#	    } else {
#		print "IDOK: $t ($netlocid,$urlid), $tests{$t} ($unetlocid,$uurlid)\n" if  $enableprint;
#	    }
	}
	$tt = $u->as_string; print "Result without base: $tt\n" if $enableprint;
    }
   if ( $lerr ) { print "not ok $i\n"; } else { print "ok $i\n"; }
}

#if ( $err ) {
#    print "Some error(s) occured\n";
#} else {
#    print "ALL tests OK\n";
#}
