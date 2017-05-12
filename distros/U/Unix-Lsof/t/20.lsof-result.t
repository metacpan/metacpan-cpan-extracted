use Test::More;
use Cwd;

use Fatal qw(open close);
use IO::Socket::INET;
use strict;
use warnings;

my $hasnt_test_nowarnings;
my $hasnt_test_warn;

BEGIN {
    use Unix::Lsof;
    my $SKIP = Unix::Lsof::_find_binary();

    if (!$SKIP) {
        plan skip_all => q{lsof not found in $PATH, please install it (see ftp://lsof.itap.purdue.edu/pub/tools/unix/lsof)};
    } else {
        plan tests => 62;
    }

    use_ok( 'Unix::Lsof' );
    use_ok( 'Unix::Lsof::Result' );
    eval 'require Test::NoWarnings;';
    $hasnt_test_nowarnings = 1 if $@;
    eval 'use Test::Warn';
    $hasnt_test_warn = 1 if $@;
}

can_ok ('Unix::Lsof::Result',qw(get_pids get_filenames get_arrayof_rows get_arrayof_columns get_hashof_columns get_hashof_rows get_values has_errors errors));

my $lrs;
ok (defined ($lrs = lsof("/doesnaexist")), "returns ok on calling in scalar context");
isa_ok ($lrs,"Unix::Lsof::Result");
like ($lrs->errors(),qr/No such file or directory/,"Fails with missing file error message");
ok ($lrs->has_errors(),"Reports errors via the has_errors method");
ok (!$lrs,"object returns false");

my $dir = getcwd();

# Make sure we do not have an lsof installation that always returns errors,
# otherwise skip test for successful truth
ok ($lrs = lsof ("-w","$dir"), "returns true on current directory");

SKIP: {
    if ( $lrs->has_errors() ) {
        my $error = $lrs->errors();
        my $message = <<"MESSAGE_END";
Your lsof installation seems to return the following warning every time it is run, skipping
test for correct error handling, please check your system and the lsof manpage or report
this as a bug.
Message: $error
MESSAGE_END

    skip $message, 2;
    }
    ok ($lrs = lsof ("-w","README"), "returns true when file exists");
    ok (!$lrs->has_errors(),"Reports no errors when there aren't any");
}

$lrs = undef;
open (my $fh,"<","README");
open (my $sfh,"<","README");

ok ($lrs = lsof ("README"), "returns true if the file is open");
SKIP: {

    skip "Test::Warn not installed",5 if $hasnt_test_warn;
    warning_like { $lrs->get_values({ "protocol name" => "TCP" },"T"); } qr{tcp/tpi info is not in the list of fields returned by lsof},"Warns on non-existant field name";
    warnings_like { $lrs->get_values({ "file name" => [] }, "i") } [qr/Invalid filter specified for "file name"/,
                                                                    qr/Invalid filter specified for "file name"/],
                                                                        "Warns on invalid filter";
    ok($lrs = lsof ("README",{ suppress_errors => 1 }),"returns true with options block");
    ok($lrs->get_values({ "file name" => [] }, "i"), "suppressed invalid filter warning");
    like ($lrs->errors(),qr/Invalid filter specified for "file name"/,"Invalid filter warning in error message");
}

is (($lrs->get_pids)[0],$$,"Correct process number reported");

ok (defined ($lrs = lsof ("README","/doesnaexist")), "returns when called with an existing and non-existing file");
ok ($lrs, "returns true when it has any output");
is (($lrs->get_pids)[0],$$,"Correct process number reported");
ok ($lrs->has_errors(),"Reports that it has errors");

ok ($lrs = lsof ("-p",$$), "returns true when called on process");
    
close $fh;
close $sfh;

my @names;
ok (@names = $lrs->get_filenames,"Returned list of file names");

my $found = grep { $_ eq "$dir/README" } @names;
ok ( $found  ,"Correct file name in the list");

ok (my @f = $lrs->get_arrayof_rows("p","user id","command name","file name","inode number"),"Got fields");

like ($f[0]->[2],qr/\Aperl/,"Correct command name");

my ($index,$index2) = grep { $f[$_]->[3] eq "$dir/README" } 0..$#f;
ok ($index,"Got correct file name with get_arrayof_rows");

my $inode = (stat("$dir/README"))[1];
is ($inode, $f[$index]->[4], "Correct inode for file name");
is ($index2,undef,"No duplicate lines reported despite two file descriptors being open");

my $e = $lrs->get_arrayof_rows("p","user id","command name","file name","file descriptor","inode number");
@f = @$e;
($index,$index2) = grep { $f[$_]->[3] eq "$dir/README" } 0..$#f;

isnt ($index2,undef,"Second file handle shown when file descriptor output required");
is ($inode, $f[$index2]->[5], "Dual file handle is reported twice with same inode");

ok (@f = $lrs->get_arrayof_columns("p","file name","inode number"), "Got array of columns");
($index) = grep { $f[1][$_] eq "$dir/README" } 0..scalar(@{$f[1]})-1;

is ($inode, $f[2][$index], "correct inode in the same row as file name");

ok (my %h = $lrs->get_hashof_columns("p","n","inode_number"), "Got a hash of columns");

($index) = grep { $h{"n"}[$_] eq "$dir/README" } 0..scalar(@{$h{"n"}})-1;
is ($inode, $h{inode_number}[$index], "correct inode in the same row as file name");
is ($$, $h{"p"}[$index], "Correct pid reported in the same line");

for my $filter ( [ "number filter", {  i => $inode }],
                 [ "regex filter", { file_name => qr/R.ADME\z/ }],
                 [ "string filter", { n => "$dir/README" } ],
                 [ "anonymous sub filter", { n => sub { $_[0] =~ m/R.+?DME/ &&
                                                            $_[0] =~ m{/RE} } } ],
             ) {
    ok (@f = $lrs->get_arrayof_columns($filter->[1],"p","file name","inode number"),
        "Specified $filter->[0]");
    is_deeply (\@f,[[$$],["$dir/README"],[$inode]],"Correct array returned");
}

@f = $lrs->get_arrayof_columns({ n=> sub { $_[0] =~ m/R+?DME/ &&
                                            $_[0] !~ m/R+?DME/ } });
is ($#f,-1, "No elements returned with contradictory filter");

ok (my $h = $lrs->get_hashof_rows("i","p","n"),"Got a hash of rows");
is ($h->{$inode}[0]{"n"},"$dir/README","Returned correct file name");

ok (%h = $lrs->get_hashof_rows({ i => $inode }, "file name", "p"), "Filtered hash of rows");
is_deeply(\%h,{"$dir/README"=>[{"p" => $$ }]},"Only one value with correct ppid returned");

ok (@f = $lrs->get_values({ "file name" => "$dir/README" }, "i"),"Returned something on get_values");
is_deeply (\@f,[$inode],"Array with single correct inode returned");
my @g = $lrs->get_values({ "file name" => "$dir/README" }, "i", "p");
is_deeply (\@f, \@g,"get_values ignores surplus parameters");

ok (@f = $lrs->get_pids({ "i" => $inode }, "garbage"), "Returned ok with filter and garbage added");
is_deeply (\@f,[$$],"Array with single correct pid returned");
ok (my $n = $lrs->get_filenames({ i => $inode }), "Got filename with filter");
is_deeply ($n,["$dir/README"],"Array with single correct filename returned");

# test hash methods for fields that only exist in some rows
my $sock = IO::Socket::INET->new(Listen    => 5,
                                 LocalAddr => '127.0.0.1',
                                 LocalPort => 42424,
                                 Proto     => 'tcp');

$lrs = lsof("-p",$$,"-n");
my $prot = $lrs->get_hashof_rows( { "protocol name" => "TCP" }, "file type",  "protocol name", "n");
is_deeply ($prot,{ "IPv4" => [ { "protocol name" => "TCP", "n" => "127.0.0.1:42424" }] },
                               "Returned correct filter result for field that only exists in some rows");
my $tpi = $lrs->get_values({ "protocol name" => "TCP" },"T");
is ($tpi->[0]->{"connection state"},"LISTEN","tcp/tpi info reported correctly");

$lrs = lsof("-p",$$,"-n",{ tcp_tpi_parse => "part" });
$tpi = $lrs->get_values({ "protocol name" => "TCP" },"T");
is ($tpi->[0]->{"ST"},"LISTEN","tcp/tpi info correctly parsed into the short form");

$lrs = lsof("-p",$$,"-n",{ tcp_tpi_parse => "array" });
$tpi = $lrs->get_values({ "protocol name" => "TCP" },"T");
my ($l) = grep { $_ eq "ST=LISTEN" } @{$tpi->[0]};
is ($l,"ST=LISTEN","tcp/tpi info correctly parsed into the array");

$sock->close();

SKIP: {
    skip "Test::NoWarnings not installed", 1 if $hasnt_test_nowarnings;
    Test::NoWarnings->had_no_warnings();
}

