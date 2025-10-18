#!perl


#  Load
#
use Test::More qw(no_plan);
BEGIN { use_ok( 'HTML::TreeBuilder' ); }
use WebDyne::Request::Fake;
use FindBin qw($RealBin $Script);
use File::Temp qw(tempfile);
use Digest::MD5;
use File::Find qw(find);
use Data::Dumper;
use IO::File;
$Data::Dumper::Indent=1;


#  Load WebDyne
#
require_ok('WebDyne');


#  Get test files
#
my @test_fn;
my $wanted_sr=sub { push (@test_fn, $File::Find::name) if /\.psp$/ };
find($wanted_sr, $RealBin);
foreach my $test_fn (sort {$a cmp $b } @test_fn) {
    my ($temp_fh, $temp_fn)=tempfile();
    #diag("test file $test_fn, temp_fh $temp_fh, temp_fn $temp_fn");
    my $r=WebDyne::Request::Fake->new( filename=>$test_fn, select=>$temp_fh, noheader=>1 );
    #$r->notes('noheader', 1);
    ok($r, 'request created');



    #  run handler which sends output to file
    #
    ok(defined(WebDyne->handler($r)), 'webdyne handler');
    is($r->status, 200, 'webdyne handler status');
    $r->DESTROY();
    seek($temp_fh,0,0);


    #  Create TreeBuilder dump of rendered text
    #
    my ($tree_fh, $tree_fn)=tempfile();
    my $tree_or=HTML::TreeBuilder->new();
    while (my $html=<$temp_fh>) {
	#  Do this way to get rid of extraneous CR's older version of CGI insert.
	$html=~s/\n+$//;
	$html=~s/>\s+/>/g;
	#diag($html);
	$tree_or->parse($html);
    }
    $tree_or->eof();
    $temp_fh->close();
    ok($tree_or, 'HTML::TreeBuilder object');
    $tree_or->dump($tree_fh);
    $tree_or->delete();
    #diag("tree_fn $tree_fn");
    seek($tree_fh,0,0);


    #  Get MD5 of file we just rendered
    #
    my $md5_or=Digest::MD5->new();
    $md5_or->addfile($tree_fh);
    my $md5_tree=$md5_or->hexdigest();


    #  Now of reference dump in test directory
    #
    (my $dump_fn=$test_fn)=~s/\.psp$/\.dmp/;
    my $dump_fh=IO::File->new($dump_fn, O_RDONLY);
    ok($dump_fh, "loaded render dump file for $dump_fn");
    binmode($dump_fh);
    $md5_or->reset();
    $md5_or->addfile($dump_fh);
    my $md5_dump=$md5_or->hexdigest();
    #diag("tree $md5_tree, dump $md5_dump");
    if ($md5_tree eq $md5_dump) {
        pass("render $test_fn");
    }
    else {
    #ok($md5_tree eq $md5_dump, "render $test_fn") || do {
        seek($tree_fh,0,0);
        seek($dump_fh,0,0);
        my @diff;
        my $line;
        while (my $made=<$tree_fh>) {
            my $test=<$dump_fh>;
            $line++;
            if ($made ne $test) {
                #  Hacks for HTML::Tree 3.13 which renders tags differently
                #
                #   '13 [gen]:         <option value=2> @0.1.3.0.1
                # ',
                #   '13 [ref]:         <option value="2"> @0.1.3.0.1
                # ',
                #   '15 [gen]:       <input type="submit"> @0.1.3.1
                # ',
                #   '15 [ref]:       <input type="submit" /> @0.1.3.1
                $test=~s/\s?\/>/>/g;
                $test=~s/\"(\d+)\"/$1/g;
            }
            unless ($made eq $test) {
                push @diff, "$line [gen]: $made", "$line [ref]: $test";
            }
        }
        if (@diff) {
            diag('  diff: - ', Dumper(\@diff));
            fail("render $test_fn");
        }
        else {
            pass("render $test_fn");
        }
    };


    #  Clean up
    #
    $tree_fh->close();
    $dump_fh->close();
    unlink($temp_fn, $tree_fn);
}

