# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-CSV-Track.t'

#########################

use Test::More;	# 'no_plan';
BEGIN { plan tests => 91 };

use Text::CSV::Track;

use File::Temp qw{tempfile};	#generate temp filename
use File::Spec qw{tmpdir};		#get temp directory
use File::Slurp qw{read_file write_file};		#reading whole file
use English qw(-no_match_vars);
use Fcntl ':flock'; # import LOCK_* constants

use strict;
use warnings;

#constants
my $DEVELOPMENT = 0;
$DEVELOPMENT = 1 if $ENV{'IN_DEBUG_MODE'};
my $MULTI_LINE_SUPPORT = 0;
my $EMPTY_STRING = q{};
my $SINGLE_QUOTE = q{'};
my $DOUBLE_QUOTE = q{"};

ok(1,															'all required modules loaded'); # If we made it this far, we're ok.

#########################


### TEST WITHOUT FILE MANIPULATION

print "testing without file manipulation\n";

#creation of object
my $track_object = Text::CSV::Track->new();
ok(defined $track_object,								'object creation');
ok($track_object->isa('Text::CSV::Track'),		'right class');

#store one value
$track_object->value_of('test1', 123);
is($track_object->value_of('test1'), 123,			'one value storing');

#store ten more
foreach my $i (1..10) {
	$track_object->value_of("test value $i", 100 - $i);
}
is($track_object->ident_list, 11,					'has 11 elements');

#remove one
$track_object->value_of('test1', undef);
is(scalar grep (defined $track_object->value_of($_), $track_object->ident_list()), 10,
																'has 10 elements after removal');


### TESTS WITH NEW FILE
# and no full time locking

print "testing with new file\n";

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

#try to read nonexisting file
$track_object = Text::CSV::Track->new({ file_name => $file_name });
eval { $track_object->value_of('test1') };
isnt($OS_ERROR, $EMPTY_STRING,						'OS ERROR if file missing');
$track_object = undef;
$OS_ERROR = undef;

#try to read nonexisting file with ignoring on
$track_object = Text::CSV::Track->new({ file_name => $file_name, ignore_missing_file => 1 });
is($OS_ERROR, $EMPTY_STRING,							'no OS ERROR with ignore missing file on');
is($track_object->value_of('test1'), undef,		'undef in empty file');

#store 100 values
foreach my $i (1..100) {
	my $store_string = qq{store string's value number "$i" with "' - quotes and \\"\\' backslash quotes};
	$track_object->value_of("test value $i", $store_string);
}
is($track_object->ident_list, 100,					'has 100 elements with quotes and backslashes');

#save to file
eval { $track_object->store(); };
is($OS_ERROR, $EMPTY_STRING,							"no OS ERROR while saveing to '$file_name'");

#clean object
$track_object = undef;

### TEST WITH GENERATED FILE

print "test with generated file\n";

$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->ident_list, 100,					'has 100 elements after read');
my $ident = 'test value 23';
my $stored_string = qq{store string's value number "23" with "' - quotes and \\"\\' backslash quotes};

is($track_object->value_of($ident), $stored_string,
																'check one stored value');

#change a value
$stored_string = '"\\ ' x 10;
$track_object->value_of($ident, $stored_string);
my $ident2 = 'test value 2';
$track_object->value_of($ident2, undef);

#save to file
eval { $track_object->store(); };
is($OS_ERROR, $EMPTY_STRING,							"save with removal and single change");

#clean object
$track_object = undef;

#check
$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->ident_list, 99,					'has 99 elements after read');
is($track_object->value_of($ident), $stored_string,			"is '$ident' '$stored_string'?");

#not storing this element
$ident = 'test value 2 2222';
$stored_string = '2222';
$track_object->value_of($ident, $stored_string);

#clean object
$track_object = undef;

#store was not called. should normaly not be called by DESTROY
$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of($ident), undef,		'was store() skipped by DESTROY?');

#now with auto_store
$track_object = Text::CSV::Track->new({ file_name => $file_name, auto_store => 1 });
$track_object->value_of($ident, $stored_string);
$track_object = undef;

#store was not called. should be now called by DESTROY
$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of($ident), $stored_string,'was store() called with auto_store by DESTROY?');

#clean object
$track_object = undef;

#delete before lazy init
$track_object = Text::CSV::Track->new({ file_name => $file_name });
$track_object->value_of($ident, undef);
$track_object->value_of($ident."don't know", "123"); #set some other so the count of records will be kept on 100
isnt($track_object->{_lazy_init}, 1,				'after set the lazy init should not be trigered');
$track_object->store();
$track_object = undef;

$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of($ident), undef,		'delete before lazy init');
$track_object = undef;


###
# MESS UP WITH FILE

print "test with messed up file\n";

my @lines = read_file($file_name);

#add one more line and reverse sort
$lines[10] = "xman1,muhaha\n";
@lines = reverse @lines;
write_file($file_name, @lines);

#check
$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of('xman1'), 'muhaha',
																'check manualy stored value');
#revert the change
$track_object->value_of('xman1', undef);
$track_object->store();
$track_object = undef;

print "2 lines entry\n";
#two line entry test
$track_object = Text::CSV::Track->new({ file_name => $file_name });

#add 2 line entry
$track_object->value_of("xman2","muhaha\nhaha\n");
$track_object->store();
$track_object = undef;

#check
$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of("xman2"), "muhaha|haha|",			'was double line entry added and changed?');
$track_object = undef;


#two line entry test2
$track_object = Text::CSV::Track->new({ file_name => $file_name, replace_new_lines_with => ', ' });

#add 2 line entry with different separator
$track_object->value_of("xman3","muhaha\nhaha\n");
$track_object->store();
$track_object = undef;

#check
$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of("xman3"), "muhaha, haha, ",			'was double line entry added and changed with different separator?');
$track_object = undef;


print "binary data\n";

#test binary data
$track_object = Text::CSV::Track->new({ file_name => $file_name });

#add binary data
my $binary_data = chr(196).chr(190).chr(197).chr(161).chr(196).chr(141).chr(197).chr(165).chr(197).chr(190).chr(195).chr(189).chr(195).chr(161).chr(195).chr(173).chr(195).chr(169);
$track_object->value_of("xman4", $binary_data);
$track_object->store();
$track_object = undef;

#check
$track_object = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of("xman4"), $binary_data,			'check binary data read');
$track_object = undef;

#save a copy for comparation
my @bckup_lines = sort @lines;

#add badly formated line
push(@lines, qq{"aman2\n});
push(@lines, qq{"xman3,"muhaha\n});
write_file($file_name, sort @lines);

#check if module die when badly formated line is in the file
$track_object = Text::CSV::Track->new({ file_name => $file_name });

eval {
	$track_object->ident_list;
};
isnt($EVAL_ERROR, defined,								'died with badly formated lines');


#check ignoring of badly formated lines
$track_object = Text::CSV::Track->new({ file_name => $file_name, ignore_badly_formated => 1 });

$track_object->ident_list;

is($track_object->ident_list, 100,					"was badly formated lines ignored with 'ignore_badly_formated => 1' ?");
$track_object->store();
$track_object = undef;

@lines = read_file($file_name);
@lines = sort @lines;
is_deeply(\@lines, \@bckup_lines,					'compare if now the values are the same as before adding two badly formated lines');


### TWO PROCESSES WRITTING AT ONCE
print "test with two processes writing at once\n";

#do change in first process
$track_object  = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of('atonce2'), undef,	'atonce2 undef in first process');
$track_object->value_of('atonce','432');

#do change in second process
my $track_object2 = Text::CSV::Track->new({ file_name => $file_name });
is($track_object2->value_of('atonce'), undef,		'atonce undef in second process');
$track_object2->value_of('atonce2','234');

#now do store for both of them
$track_object->store();
$track_object2->store();

$track_object  = undef;
$track_object2 = undef;

#now read the result and check
$track_object  = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of('atonce2'), 234,		'do we have atonce2?');
is($track_object->value_of('atonce'), undef,		'do we miss atonce overwritten by second process?');

#same as above but now we have atonce and atonce2
#we test if in case we do only set-s we will inherite changes from other processes

#do change in first process
$track_object  = Text::CSV::Track->new({ file_name => $file_name });
$track_object->value_of('atonce', '2nd 432');

#do change in second process
$track_object2 = Text::CSV::Track->new({ file_name => $file_name });
$track_object2->value_of('atonce2', '2nd 234');

#now do store for both of them
$track_object2->store();
$track_object->store();

$track_object  = undef;
$track_object2 = undef;

#now read the result and check
$track_object  = Text::CSV::Track->new({ file_name => $file_name });
is($track_object->value_of('atonce'), '2nd 432',	'does atonce has the right value?');
is($track_object->value_of('atonce2'), '2nd 234',	'does atonce2 has the right value?');



### TEST LOCKING
print "test file locking\n";

#open with full time locking
$track_object = Text::CSV::Track->new({ file_name => $file_name, full_time_lock => 1 });
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



### TEST multi column tracking
print "test with multi column files\n";

#store one value
$track_object = Text::CSV::Track->new({ file_name => $file_name, ignore_missing_file => 1 });
$track_object->value_of('multi test1', 123, 321);
$track_object->value_of('multi test2', 222, 111);
is($track_object->value_of('multi test1'), 2,			'multi column storing in scalar context number of records');

my @got = $track_object->value_of('multi test1');
my @expected = (123, 321);
is_deeply(\@got, \@expected,							'multi column storing');

is($track_object->csv_line_of('multi test2'), '"multi test2",222,111' , 'test csv_line_of()');

$track_object->store();
$track_object = undef;

print "hash tests\n";
#hash_of() tests
$track_object = Text::CSV::Track->new({
	file_name    => $file_name
	, hash_names => [ qw{ col coool fi ga ro } ]
});
my %hash = %{$track_object->hash_of('multi test2')};
is($hash{'coool'}, 111,									'get the second column by name');
%hash = %{$track_object->hash_of('multi test1')};
is($hash{'col'}, 123,									'get the first column from different row by name');
$track_object->hash_of('multi test3', { coool => 321, ga => 654 } );
$track_object->store;

$track_object = undef;

print "hash set tests\n";
#hash_of() set tests
$track_object = Text::CSV::Track->new({
	file_name    => $file_name
	, hash_names => [ qw{ col coool fi ga ro } ]
});

%hash = %{$track_object->hash_of('multi test3')};
is($hash{'ga'}, 654,										'check first column');
is($hash{'coool'}, 321,									'check the second column');
$track_object->hash_of('multi test3', { coool => 333, ro => 555 } );

%hash = %{$track_object->hash_of('multi test3')};
is($hash{'ga'}, 654,										'check first column (after single column hash set)');
is($hash{'coool'}, 333,									'check the second column (after single column hash set)');
is($hash{'ro'}, 555,										'check the second column (after single column hash set)');

eval {
	$track_object->hash_of('multi test3', { cooolxx => 333, ro => 555 } );
};
ok($EVAL_ERROR,											'setting unknown column should error - '.$EVAL_ERROR);
$EVAL_ERROR = undef;

$track_object = undef;

###
# TEST different separator
print "test different separators\n";

write_file($file_name,
	"{1|23{|{jeden; &{ dva tri'{\n",
	"{32|1{|tri dva, jeden\"\n",
	"unquoted|last one\n",
);

#check
$track_object = Text::CSV::Track->new({
	file_name => $file_name
	, sep_char => q{|}
	, escape_char => q{&}
	, quote_char => q/{/
});
is($track_object->ident_list, 3,						'we should have three records');
is($track_object->value_of('1|23'), "jeden; { dva tri'",
																'check 1/3 line read');
is($track_object->value_of('32|1'), 'tri dva, jeden"',
																'check 2/3 line read');
is($track_object->value_of('unquoted'), 'last one',
																'check 3/3 line read');


### TEST skipping of header lines
print "test file with header lines\n";

my @file_lines = (
	"heade line 1\n",
	"heade line 2 $SINGLE_QUOTE, $DOUBLE_QUOTE\n",
	"heade line 3, 333\n",
	"123,\"jeden dva try\"\n",
	"321,\"tri dva jeden\"\n",
	"unquoted,\"last one\"\n",
);

write_file($file_name, @file_lines);

#check
$track_object = Text::CSV::Track->new({
	file_name    => $file_name,
	header_lines => 3,
});
is(scalar @{$track_object->header_lines}, 3,		'we should have three header lines');
is($track_object->ident_list, 3,						'we should have three records');
is($track_object->value_of('123'), "jeden dva try",
																'check first line read');
#save back the file
$track_object->store();
$track_object = undef;

my @file_lines_after = read_file($file_name);
is_deeply(\@file_lines_after,\@file_lines,		'is the file same after store()?');

#check trunc mode
$track_object = Text::CSV::Track->new({
	file_name    => $file_name,
	header_lines => 3,
	trunc        => 1,
});
$track_object->value_of('123','jeden dva try 123');
is($track_object->ident_list, 1,						'we should one records');
$track_object->store();

@file_lines_after = read_file($file_name);
is(@file_lines_after , 4,								'we should have 3+1 lines in file');

#test header lines and empty file
unlink($file_name);
my @header_lines = (
	"header line 1",
	"header line 2",
	"header line 3",
);
$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => \@header_lines,
	ignore_missing_file => 1,
});
$track_object->value_of('123','try 123');
$track_object->store();
@file_lines_after = read_file($file_name);
is(@file_lines_after , 4,								'we should have 3+1 empty lines + one value in new file created');

$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => 3,
	ignore_missing_file => 1,
});
is($track_object->value_of('123') , 'try 123',	'check the one stored value');

my $file_content = read_file($file_name);
my $file_content_expected = 'header line 1
header line 2
header line 3
123,"try 123"
';
is($file_content, $file_content_expected,			'check file with forced header lines');

print "changing header lines\n";
@header_lines = (
	"header line 1",
	"header line 2",
	"header line 33",
);
$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => \@header_lines,
	ignore_missing_file => 1,
});
$track_object->value_of('321','try 321');
$track_object->store();
$file_content = read_file($file_name);
$file_content_expected = 'header line 1
header line 2
header line 33
123,"try 123"
321,"try 321"
';
is($file_content, $file_content_expected,			'check file with changed forced header lines');

$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => 3,
});
is_deeply($track_object->header_lines,\@header_lines,		"check fetching header lines");
is($track_object->value_of('123') , 'try 123',	'check one stored value');

#empty file + numeric header lines
unlink($file_name);
$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => 1,
	ignore_missing_file => 1,
});
$track_object->value_of('321','try 321');
$track_object->store();
my @file_lines2 = read_file($file_name);
is(@file_lines2, 2,									'check numeric header lines definition on empty file');


#footer
print "test file with footer lines\n";

my @footer_lines = (
	"footer line 1",
	"footer line 2 $SINGLE_QUOTE, $DOUBLE_QUOTE",
	"footer line 3, 333",
);

@file_lines = (
	"heade line 1\n",
	"heade line 2 $SINGLE_QUOTE, $DOUBLE_QUOTE\n",
	"heade line 3, 333\n",
	"123,\"jeden dva try\"\n",
	"321,\"tri dva jeden\"\n",
	"unquoted,\"last one\"\n",
	map { $_."\n" } @footer_lines,
);

write_file($file_name, @file_lines);

#check
$track_object = Text::CSV::Track->new({
	file_name    => $file_name,
	header_lines => 3,
	footer_lines => 3,
});
is(scalar @{$track_object->header_lines}, 3,		'we should have three header lines');
is(scalar @{$track_object->footer_lines}, 3,		'we should have three footer lines');
is($track_object->ident_list, 3,					'we should have three records');
is($track_object->value_of('123'), "jeden dva try",
													'check first line read');

is_deeply(\@{$track_object->footer_lines}, \@footer_lines,
													'check read footer lines');

@footer_lines = (
	"footer line 111",
	"footer line 222",
	"footer line 333",
);

$track_object->footer_lines(\@footer_lines);
$track_object->store;
undef $track_object;

$track_object = Text::CSV::Track->new({
	file_name    => $file_name,
	header_lines => 3,
	footer_lines => 3,
});
is_deeply(\@{$track_object->footer_lines}, \@footer_lines,
													'check changed footer lines');
undef $track_object;

#footer with trunc option
$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => 3,
	footer_lines        => 3,
	trunc               => 1,
});
$track_object->store();
undef $track_object;

@file_lines2 = read_file($file_name);
is(6, scalar @file_lines2,							'we should have the same file with only header and footer lines');

$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => 3,
	footer_lines        => 3,
	trunc               => 1,
});
is_deeply(\@{$track_object->footer_lines}, \@footer_lines,
													'check footer lines');

#empty file with footer
unlink($file_name);
$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => 3,
	footer_lines        => 3,
	ignore_missing_file => 1,
});
$track_object->store;

@file_lines2 = read_file($file_name);
is(6, scalar @file_lines2,									'we should have empty file with 6 empty header and footer lines');

$track_object->value_of('test', '123');
$track_object->footer_lines(\@footer_lines);
$track_object->store;
undef $track_object;

@file_lines2 = read_file($file_name);
is(7, scalar @file_lines2,									'we should have the same file with footer filled and 1 value');

$track_object = Text::CSV::Track->new({
	file_name           => $file_name,
	header_lines        => 3,
	footer_lines        => 3,
});
is($track_object->value_of('test'), '123',					'check that value');

#removing of footer
$track_object->footer_lines([]);
$track_object->store;
undef $track_object;

@file_lines2 = read_file($file_name);
is(4, scalar @file_lines2,									'we should have the same file without footer');

#restore file
@file_lines = (
	"heade line 1\n",
	"heade line 2 $SINGLE_QUOTE, $DOUBLE_QUOTE\n",
	"heade line 3, 333\n",
	"123,\"jeden dva try\"\n",
	"321,\"tri dva jeden\"\n",
	"unquoted,\"last one\"\n",
);
write_file($file_name, @file_lines);

###TEST always_quote
print "test always quote\n";
#check
$track_object = Text::CSV::Track->new({
	file_name    => $file_name,
	header_lines => 3,
	always_quote => 1,
});
$track_object->store();
$track_object = undef;

#do always_quote "by hand"
@file_lines = (
	"heade line 1\n",
	"heade line 2 $SINGLE_QUOTE, $DOUBLE_QUOTE\n",
	"heade line 3, 333\n",
	'"123","jeden dva try"'."\n",
	'"321","tri dva jeden"'."\n",
	'"unquoted","last one"'."\n",
);

@file_lines_after = read_file($file_name);
is_deeply(\@file_lines_after,\@file_lines,		"is the file ok after 'always quote' store()?");


###
# single column files
print "test single column files tracking\n";

@file_lines = (
	"line1\n",
	"line2\n",
	"line3\n",
	"123\n",
	"321\n",
	"unquoted\n",
);
write_file($file_name, @file_lines);

$track_object = Text::CSV::Track->new({
	file_name     => $file_name,
	single_column => 1,
});
is($track_object->ident_list, 6,						'we should have six records');
ok($track_object->value_of(123),						'check one records');
is($track_object->value_of(1234), undef,			'check record not there');

$track_object->value_of(123, undef);				#remove one
$track_object->value_of(1234, 1);					#add one

$track_object->store();
$track_object = undef;


@file_lines = (
	"1234\n",
	"321\n",
	"line1\n",
	"line2\n",
	"line3\n",
	"unquoted\n",
);
@file_lines_after = read_file($file_name);
is_deeply(\@file_lines_after,\@file_lines,		"check single quote file after store");


print "failure of store should not corrupt final csv file\n";
#two line entry test
$track_object = Text::CSV::Track->new({ file_name => $file_name, binary => 0 });

$binary_data = chr(196).chr(190).chr(197).chr(161).chr(196).chr(141).chr(197).chr(165).chr(197).chr(190).chr(195).chr(189).chr(195).chr(161).chr(195).chr(173).chr(195).chr(169);
$track_object->value_of("111", $binary_data);
eval { $track_object->store(); };
isnt($EVAL_ERROR, $EMPTY_STRING,					'we should have croak when storing binary and "binary => 0"');
$track_object = undef;
$EVAL_ERROR = undef;

@file_lines_after = read_file($file_name);
is_deeply(\@file_lines, \@file_lines_after,			'check quote file after crashed store');


###
# different column as identificator
print "different column as identificator\n";
@file_lines = (
	"abc,5,qwe\n",
	"abc,4\n",
	"123,6,hgf rty\n",
	"321,7,!~;:\n",
);

write_file($file_name, @file_lines);
$track_object = Text::CSV::Track->new({
	file_name                   => $file_name,
	identificator_column_number => 1,
	hash_names                  => [ qw{ col coool } ],
});

is_deeply([ $track_object->value_of(4) ], [ 'abc' ] ,				'check record');
is_deeply([ $track_object->value_of(5) ], [ 'abc', 'qwe'] ,			'check record');
is_deeply([ $track_object->value_of(6) ], [ '123', 'hgf rty'],		'check record');
is_deeply([ $track_object->value_of(7) ], [ '321', '!~;:' ],		'check record');

%hash = %{$track_object->hash_of(6)};
is($hash{'col'}, 123,								'check record generated by hash_of');
is($hash{'coool'}, 'hgf rty',						'check record generated by hash_of');

$track_object->store();

@file_lines = (
	"abc,4\n",
	"abc,5,qwe\n",
	"123,6,\"hgf rty\"\n",
	"321,7,!~;:\n",
);

@file_lines_after = read_file($file_name);
is_deeply(\@file_lines, \@file_lines_after,			'check file after store of identificator in different column');


#check store as xml
print "check store as xml\n";
$track_object = Text::CSV::Track->new({
	file_name => $file_name,
	trunc     => 1,
});
$track_object->value_of('1', 'aaa');
$track_object->value_of('2', 'ddd');
$track_object->value_of('3', 'bbb');
$track_object->value_of('4', 'ccc');
$track_object->store_as_xml();

@file_lines = (
	"<Row>\n",
	"    <Cell><Data ss:Type=\"String\">1</Data></Cell>\n",
	"    <Cell><Data ss:Type=\"String\">aaa</Data></Cell>\n",
	"</Row>\n",
	"<Row>\n",
	"    <Cell><Data ss:Type=\"String\">2</Data></Cell>\n",
	"    <Cell><Data ss:Type=\"String\">ddd</Data></Cell>\n",
	"</Row>\n",
	"<Row>\n",
	"    <Cell><Data ss:Type=\"String\">3</Data></Cell>\n",
	"    <Cell><Data ss:Type=\"String\">bbb</Data></Cell>\n",
	"</Row>\n",
	"<Row>\n",
	"    <Cell><Data ss:Type=\"String\">4</Data></Cell>\n",
	"    <Cell><Data ss:Type=\"String\">ccc</Data></Cell>\n",
	"</Row>\n",
);

@file_lines_after = read_file($file_name);
is_deeply(\@file_lines_after, \@file_lines,			'check file after store as xml');


### CLEANUP

sub END {
	#remove temporary file
	unlink($file_name) if not $DEVELOPMENT;
}
