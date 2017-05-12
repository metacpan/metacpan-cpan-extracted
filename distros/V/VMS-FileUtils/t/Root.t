#! perl
#
#   test using rooted dir to go deeper in directories
#
use VMS::FileUtils::Root;

if ($^O =~ /vms/i) {

    print "1..23\n";

#
#   we make sure we aren't using a known logical
#
    $j = 0;
    while (1) {
	$j++;
	$dev = 'TEST_'.$$.'_'.$j;
	last if !defined($ENV{$dev});
    }
    
    $j = 0;
    while (1) {
	$j++;
	$troot = 'TESTX_'.$$.'_'.$j;
    last if !defined($ENV{$troot});
    }
    $iss = `define/job $troot $dev:[dir1.dir2.dir3.]`;
    if ($iss) {
	die "0 not ok\nError defining rooted logical for testing: $?\n";
    }
} else {
    print "1..1\n";
}


END {
    `deassign/job $troot` if $^O =~ /vms/i;
}

sub report ($$;$) {
    my $f = shift;
    my $e = shift;
    my $msg = shift;

    if ($f !~ /$e/i) {
        print "# $msg\n" if $msg;
        print "# EXPECTED: /$e/\n";
        print "# GOT:      '$f'\n";
        print "not ";
    }
    print "ok ",$NTEST++,"\n";
}



if ($^O !~ /vms/i) {
    print "ok 1\n";
    exit 0;
}



$NTEST = 1;
$cwd = '';

$z = new VMS::FileUtils::Root "$dev:[dir1.dir2.dir3]";
$f = $z->rooted("$dev:[dir1.dir2.dir3]");
$e = '\A\/ROOT[\w]+\/000000\Z';
report($f,$e,"Dir at top of VMS abs rooted tree");

$f = $z->unrooted($f);
$e = '\A\/'.$dev.'\/dir1\/dir2\/dir3\Z';
report($f,$e,"unroot Dir at top of VMS abs rooted tree");


$f = $z->rooted("$dev:[dir1.dir2.dir3]test.file");
$e = '\A\/ROOT[\w]+\/000000\/test\.file\Z';
report($f,$e,"File at top of VMS abs rooted tree");

$f = $z->unrooted($f);
$e = '\A\/'.$dev.'\/dir1\/dir2\/dir3\/test\.file\Z';
report($f,$e,"unroot file at top of VMS abs rooted tree");


$f = $z->rooted("$dev:[dir1.dir2.dir3.dir4]");
$e = '\A\/ROOT[\w]+\/dir4\Z';
report($f,$e,"Dir lower in VMS abs rooted tree");

$f = $z->unrooted($f);
$e = '\A\/'.$dev.'\/dir1\/dir2\/dir3\/dir4\Z';
report($f,$e,"unroot Dir lower in VMS abs rooted tree");

$f = $z->rooted("$dev:[dir1.dir2.dir3.dir4]test.file");
$e = '\A\/ROOT[\w]+\/dir4\/test\.file\Z';
report($f,$e,"File lower in VMS abs rooted tree");

$f = $z->unrooted($f);
$e = '\A\/'.$dev.'\/dir1\/dir2\/dir3\/dir4\/test\.file\Z';
report($f,$e,"unroot File lower in VMS abs rooted tree");

$f = $z->rooted("$troot:[000000]test.file");
$e = '\A\/ROOT[\w]+\/000000\/test\.file\Z';
report($f,$e,"Rooted expansion in VMS abs rooted tree");

$f = $z->rooted("/$troot/000000/test.file");
$e = '\A\/ROOT[\w]+\/000000\/test\.file\Z';
report($f,$e,"Rooted expansion in Unix abs rooted tree");

$f = $z->rooted("$troot:[dir7]test.file");
$e = '\A\/ROOT[\w]+\/dir7\/test\.file\Z';
report($f,$e,"Rooted expansion in VMS abs rooted tree");

$f = $z->rooted("/$troot/dir78/test.file");
$e = '\A\/ROOT[\w]+\/dir78\/test\.file\Z';
report($f,$e,"Rooted expansion in Unix abs rooted tree");

$z = new VMS::FileUtils::Root "/$dev/dir1/dir2/dir3";
$f = $z->rooted("/$dev/dir1/dir2/dir3");
$e = '\A\/ROOT[\w]+\/000000\Z';
report($f,$e,"Dir at top of Unix abs rooted tree");

$f = $z->unrooted($f);
$e = '\A\/'.$dev.'\/dir1\/dir2\/dir3\Z';
report($f,$e,"unroot Dir at top of Unix abs rooted tree");

$z = new VMS::FileUtils::Root "";
$f = $z->rooted("test.file");
if (open(F,">$f")) {
    ($sdev1,$sino1) = stat F;
    print F "hi\n";
    close F;
    ($sdev2,$sino2) = stat 'test.file';
    if ($sdev1 != $sdev2 || $sino1 != $sino2) {
        report($f,"equiv to []test.file","but it isn't");
    } else {
        report($f,$f,"local/rooted equiv");
        $cwd = $z->unrooted($f);
        $cwd =~ s#/test\.file\Z##;
        $cwd =~ s#\$#\\\$#g;
    }
    unlink $f;
} else {
    report("unable to open $f for writing","able to write $f","but couldn't");
}


$z = new VMS::FileUtils::Root "[.dir1]";
$f = $z->rooted("[.dir1.dir2.dir3]test.file");
$e = '\A\/ROOT[\w]+\/dir2\/dir3\/test.file\Z';
report($f,$e,"File in VMS rel rooted tree");

$f = $z->unrooted($f);
$e = '\A'.$cwd.'\/dir1\/dir2\/dir3\/test\.file\Z';
report($f,$e,"unroot File at top of Unix abs rooted tree");

$z = new VMS::FileUtils::Root "dir1";
$f = $z->rooted("[.dir1.dir2.dir3]test.file");
$e = '\A\/ROOT[\w]+\/dir2\/dir3\/test.file\Z';
report($f,$e,"File in Unix rel rooted tree");

$f = $z->unrooted($f);
$e = '\A'.$cwd.'\/dir1\/dir2\/dir3\/test\.file\Z';
report($f,$e,"unroot File in Unix rel rooted tree");

$z = new VMS::FileUtils::Root "";
$f = $z->rooted("test.file");
$e = '\A\/ROOT[\w]+\/000000\/test.file\Z';
report($f,$e,"File in CWD rel rooted tree");

$f = $z->rooted("foo/bar/blem/../zip/./blem/test.file");
$e = '\A\/ROOT[\w]+\/foo\/bar\/zip\/blem\/test.file\Z';
report($f,$e,"File with unixish path in rooted tree");

$z = new VMS::FileUtils::Root "/$dev/dir1/dir2/dir3/dir4/dir5/dir6/dir7/dir8/dir9";
$f = $z->rooted("/$dev/dir1/dir2/dir3/dir4/dir5/dir6/dir7/dir8/dir9/dir10/dir11/foo.bar");
$e = '\A\/ROOT[\w]+\/dir8\/dir9\/dir10\/dir11\/foo.bar';
report($f,$e,"Test rooted depth limit of 8");

$f = $z->unrooted($f);
$e = '\A\/'.$dev.'\/dir1\/dir2\/dir3\/dir4\/dir5\/dir6\/dir7\/dir8\/dir9\/dir10\/dir11\/foo\.bar\Z';
report($f,$e,"unroot File deep in rooted tree");

