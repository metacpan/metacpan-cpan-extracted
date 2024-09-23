# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-CSV-Track-Max.t'

#########################

use Test::More; # 'no_plan';
BEGIN { plan tests => 12 };

use Text::CSV::Track::Max;
use File::Temp qw{tempfile};	#generate temp filename
use File::Spec::Functions qw{tmpdir};		#get temp directory
use English qw(-no_match_vars);
use Fcntl ':flock'; # import LOCK_* constants

use strict;
use warnings;

#constants
my $DEVELOPMENT = 0;
my $EMPTY_STRING = q{};

ok(1,															'all required modules loaded'); # If we made it this far, we're ok.

#########################


### TEST WITHOUT FILE MANIPULATION

#creation of object
my $track_object = Text::CSV::Track::Max->new();
ok(defined $track_object,								'object creation');
ok($track_object->isa('Text::CSV::Track::Max'),	'right class');

#store one value
$track_object->value_of('test1', 123);
is($track_object->value_of('test1'), 123,			'one value storing');

#store ten more
foreach my $i (1..10) {
	$track_object->value_of("test$i", 100 - $i);
}
is($track_object->ident_list, 10,					'has 10 elements');

#remove one
$track_object->value_of('test1', undef);
is(scalar grep (defined $track_object->value_of($_), $track_object->ident_list()), 9,
																'has 9 elements after removal');

#try to set smaller value
$track_object->value_of('test3', 2);
isnt($track_object->value_of('test3'), 2,			'we should have old value in "test3"');


### TESTS FILE

#generate temp file name
my $tmp_template = 'text-csv-track-XXXXXX';
my ($fh, $file_name) = tempfile($tmp_template);

#remove temp file if exists
close($fh);
unlink($file_name) or die 'unable to remove "'.$file_name.'"';

#in development it's better to have steady filename other wise it should be random
if ($DEVELOPMENT) {
	print "skip random temp filename it's development time\n";
	$file_name = $tmp_template;
	unlink($file_name);
}

#cleanup after tempfile()
$OS_ERROR = undef;


### TWO PROCESSES WRITTING AT ONCE

#do change in first process
$track_object  = Text::CSV::Track::Max->new({ file_name => $file_name, ignore_missing_file => 1 });
$track_object->value_of('atonce','432');

#do change in second process
my $track_object2 = Text::CSV::Track::Max->new({ file_name => $file_name, ignore_missing_file => 1 });
$track_object2->value_of('atonce','234');

#now do store for both of them
$track_object->store();
$track_object2->store();

#clean up
$track_object  = undef;
$track_object2 = undef;

#now read the result and check
$track_object  = Text::CSV::Track::Max->new({ file_name => $file_name });
is($track_object->value_of('atonce'), 432,	'do we have greater value stored before?');

#try do change to smaller number
$track_object  = Text::CSV::Track::Max->new({ file_name => $file_name, ignore_missing_file => 1 });
$track_object->value_of('atonce','-100');
$track_object->store();
$track_object  = undef;

#check
$track_object  = Text::CSV::Track::Max->new({ file_name => $file_name });
is($track_object->value_of('atonce'), 432,	'do we still have it?');


### TEST LOCKING

#open with full time locking
$track_object = Text::CSV::Track::Max->new({ file_name => $file_name, full_time_lock => 1 });
open($fh, "<", $file_name) or die "can't open file '$file_name' - $OS_ERROR";
$track_object->value_of('x', 1);
#check lazy init. it should succeed
isnt(flock($fh, LOCK_SH | LOCK_NB), 0,				'try shared lock while lazy init should not be activated, should succeed');
#release the lock
flock($fh, LOCK_UN) or die "flock ulock failed - $OS_ERROR";

#active lazy initialization
$track_object->value_of('x');
#try non blocking shared flock. it should fail
is(flock($fh, LOCK_SH | LOCK_NB), 0,				"try shared lock while in full time lock mode, should fail - $OS_ERROR");
$track_object = undef;

#try non blocking shared flock after object is destroied. now it should succeed
isnt(flock($fh, LOCK_SH | LOCK_NB), 0,				'try shared lock after track object is destroyed, should succeed');

close($fh);


### CLEANUP

#remove temporary file
unlink($file_name) if not $DEVELOPMENT;
