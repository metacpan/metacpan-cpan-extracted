#!/usr/bin/perl -w
use strict;

###############################################################################
# Run the following tests before this test:
#
# 00_clear.t - remove ./test
# 01_basic.t - create fresh ./test
###############################################################################

use Test::More;
use File::Spec::Functions qw(updir);
use IO::File;

our @stores;

#----------------------------------------------------------------------------

BEGIN {
	require 'backends.pl';

	@stores = test_stores();
	plan tests => 1 + @stores * 10;

	#01
	use_ok('VCS::Lite::Shell', qw(:all));
}	

VCS::Lite::Repository->user('test'); # For tests on non-Unix platforms

for (@stores) {

    #+01
    require_ok "VCS::Lite::Store::$_";

    chdir 'test';
    chdir $_;

    add('hworld.pl');

    #+02
    ok((-e 'hworld.pl'),"hworld.pl created");

    my $rep = VCS::Lite::Repository->new('.');
    my @cont = $rep->contents;

    #+03
    ok(scalar(grep {$_->path =~ /hworld.pl$/} @cont),
    	"hworld.pl in the repository");

    my $hworld = <<EOF;
#!/usr/bin/perl

use strict;
use warnings;

print "Hello World\\n";

EOF

	if(my $TEST = IO::File->new('hworld.pl','w+')) {
        print $TEST $hworld;
        $TEST->close;
    }

    check_in('hworld.pl',"Initial version\n");

    my $hw = VCS::Lite::Element->new('hworld.pl');

    #+04
    is($hw->latest,1,"Check in worked, latest gen 1");

    $hworld =~ s/Hello World/Bonjour Le Monde/;
	if(my $TEST = IO::File->new('hworld.pl','w+')) {
        print $TEST $hworld;
        $TEST->close;
    }

    my $diff = diff( file1 => 'hworld.pl');

    my ($line1,$line2,@body) = split /\n/,$diff;

    #+05
    like($line1,qr/\-\-\-.*hworld.pl\@\@1/,"First file output from diff");

    #+06
    is($line2,'+++ hworld.pl ',"Second file output from diff");

    my $body = join("\n",@body) . "\n";

my $expected = <<END;
\@\@ -6,1 +6,1 \@\@
-print "Hello World\\n";
+print "Bonjour Le Monde\\n";
END

    #+07
    is($body,$expected,"print line changed");
    
    check_in('hworld.pl',"Change text to French\n");

    $hw = VCS::Lite::Element->new('hworld.pl');

    #+08
    is($hw->latest,2,"Check in worked, latest gen 2");

    #+09
    is( diff( file1 => 'hworld.pl'),'',
    	"Now no different from checked in version");

    #+10
    is( diff( file1 => 'hworld.pl', gen1 => 1), $diff,
        "Generation 1 diffs the same as before");

    chdir updir;
    chdir updir;
}
