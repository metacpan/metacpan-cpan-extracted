# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl cmt-libchm.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('cmt::libchm') };


my $fail = 0;
foreach my $constname (qw(
	CHM_COMPRESSED CHM_ENUMERATE_ALL CHM_ENUMERATE_DIRS CHM_ENUMERATE_FILES
	CHM_ENUMERATE_META CHM_ENUMERATE_NORMAL CHM_ENUMERATE_SPECIAL
	CHM_ENUMERATOR_CONTINUE CHM_ENUMERATOR_FAILURE CHM_ENUMERATOR_SUCCESS
	CHM_MAX_PATHLEN CHM_PARAM_MAX_BLOCKS_CACHED CHM_RESOLVE_FAILURE
	CHM_RESOLVE_SUCCESS CHM_UNCOMPRESSED)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined cmt::libchm macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

use Data::Dumper; 

diag '@ARGV = '.Dumper(\@ARGV);

my $chm_file = 't/test.chm'; 
my $h = chm_open($chm_file) or die "chm_open"; 
my $i = 0;
chm_enumerate($h, CHM_ENUMERATE_ALL, 
    sub {
        my ($hh, $ui) = @_;
        my $d = dumpUnitInfo($ui); 
        # diag sprintf("%4d %s", ++$i, Dumper($d)); 
        my ($path, $flags, $start, $len, $spc) = getUnitInfo($ui); 
        diag "path=$path, fl=$flags, st=$start, len=$len, spc=$spc";
        return CHM_ENUMERATOR_CONTINUE; 
    }, undef); 
chm_close($h); 
