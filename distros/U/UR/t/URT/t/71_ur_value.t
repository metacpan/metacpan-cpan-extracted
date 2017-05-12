use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Scalar::Util qw(refaddr);
use Test::More tests => 89;
require File::Temp;

my $s1 = UR::Value::Text->get('hi there');
ok($s1, 'Got an object for string "hi there"');
is($s1->id, 'hi there', 'It has the right id');

my $s2 = UR::Value::Text->get('hi there');
ok($s2, 'Got another object for the same string');
is($s1,$s2, 'They are the same object');

my $s3 = UR::Value::Text->get('something else');
ok($s3, 'Got an object for a different string');
isnt($s1,$s3, 'They are different objects');

my $s4 = UR::Value::Text->get('0');
ok(defined($s4), 'Got an object for the string "0"'); # Note that $s4 stringifies to "0" which is boolean false
is($s4->id, '0', 'The ID is correct');
is($s4, '0', 'It stringifies correctly');

my $text = UR::Value::Text->get('metagenomic composition 16s is awesome');
ok($text, 'Got an object for string "metagenomic composition 16s is awesome"');
is($text->id, 'metagenomic composition 16s is awesome', 'Id is correct');

my $capitalized = $text->capitalize;
isa_ok($capitalized, 'UR::Value::Text');
is($capitalized->id, 'Metagenomic Composition 16s Is Awesome', 'Capitalized for is "Metagenomic Composition 16s Is Awesome"');

my $camel = $text->to_camel;
isa_ok($camel, 'UR::Value::Text');
is($camel->id, 'MetagenomicComposition16sIsAwesome', 'Text To camel case for is "MetagenomicComposition16sIsAwesome"');

my $lemac = $camel->to_lemac;
isa_ok($lemac, 'UR::Value::Text');
is($lemac->id, 'metagenomic composition 16s is awesome', 'Camel case to text for is "MetagenomicComposition16sIsAwesome"');
is($lemac, $text, 'Got the same UR::Value::Text object back for camel case to text');

$text->dump_warning_messages(0);
$text->queue_warning_messages(1);
ok(!$text->to_hash, 'Failed to convert text object "' . $text->id . '"to a hash when does not start with a dash (-)');
my $text_for_text_to_hash = '-aa foo -b1b -1 bar --c22 baz baz -ddd -11 -eee -f -g22g text -1111 --h_h 44 --i-i -5 -j-----j -5 -6 hello     -k    -l_l-l g  a   p   -m';
like(($text->warning_messages)[0],
    qr(Can not convert text object with id "metagenomic composition 16s is awesome" to hash),
    'Got expected error message from failed conversion');


my $text_to_hash = UR::Value::Text->get($text_for_text_to_hash);
ok($text_to_hash, 'Got object for param text');
my $hash = $text_to_hash->to_hash;
ok($hash, 'Got hash for text');
is_deeply($hash->id, { aa => 'foo', b1b => '-1 bar', c22 => 'baz baz', ddd => -11, eee => '', f => '', g22g => 'text -1111', h_h => 44, 'i-i' => -5, 'j-----j' => '-5 -6 hello', k => '', 'l_l-l' => 'g  a   p', m => '', }, 'Text to hash id is correct'); 
is($hash->__display_name__, "aa => 'foo',b1b => '-1 bar',c22 => 'baz baz',ddd => '-11',eee => '',f => '',g22g => 'text -1111',h_h => '44',i-i => '-5',j-----j => '-5 -6 hello',k => '',l_l-l => 'g  a   p',m => ''", 'Hash display name');
my $hash_to_text = $hash->to_text;
ok($hash_to_text, 'Got hash to text');
is($hash_to_text, '-aa foo -b1b -1 bar -c22 baz baz -ddd -11 -eee -f -g22g text -1111 -h_h 44 -i-i -5 -j-----j -5 -6 hello -k -l_l-l g  a   p -m', 'Hash to text is correct');

my $s1_refaddr = Scalar::Util::refaddr($s1);
ok($s1->unload(), 'Unload the original string object');

isa_ok($s1, 'UR::DeletedRef');
isa_ok($s2, 'UR::DeletedRef');

$s1 = UR::Value::Text->get('hi there');
ok($s1, 're-get the original string object');
is($s1->id, 'hi there', 'It has the right id');
isnt(Scalar::Util::refaddr($s1), $s1_refaddr, 'It is not the original object reference');

UR::Object::Type->define(
    class_name => 'Test::Value',
    is => 'UR::Value',
    id_by => [
        string => { is => 'Text' }
    ]
);

eval { Test::Value->get() };
like($@, qr/Can't load an infinite set of Test::Value/,
     'Getting infinite set of Test::Values threw an exception');

my $x1 = Test::Value->get('xyz');
ok($x1,"get('xyz') returned on first call");

my $x2 = Test::Value->get('xyz');
ok($x2,"get('xyz') returned on second call");
is($x1, $x2, 'They were the same object');

my $a1 = Test::Value->get(string => 'abc');
ok($a1,"get(string => 'abc') returned on first call");

my $a2 = Test::Value->get(string => 'abc');
ok($a2,"get(string => 'abc') returned on second call");
is($a1, $a2, 'They were the same object');

my $n1 = Test::Value->get('123');
ok($n1, "get('123') returned on first call");
my $n2 = Test::Value->get(string => '123');
ok($n2,"get(string => '123') returned on second call");
is($n1, $n2, 'They were the same object');


my @o = Test::Value->get(['xyz','abc','123','456']);
is(scalar(@o), 4, 'Got 4 Test::Values in a single get()');
is_deeply([ map { $_->id} @o],
          ['123','456','abc','xyz'],
          'Values were returned in ID order');
my %o = map { $_->id => $_ } @o;

is($o{'123'}, $n1, "Object with id '123' is the same as the one from earlier");
is($o{'abc'}, $a1, "Object with id 'abc' is the same as the one from earlier");
is($o{'xyz'}, $x1, "Object with id 'xyz' is the same as the one from earlier");
is($o{'456'}->string, '456', 'The 4th value in the last get() constructed the correct object');

 

UR::Object::Type->define(
    class_name => 'Test::Value2',
    is => 'UR::Value',
    id_by => [
        string1 => { is => 'Text' },
        string2 => { is => 'Text' },
    ],
    has => [
        other_prop => { is => 'Text' },
    ],
);

eval { Test::Value2->get(string1 => 'abc') };
like($@, qr/Can't load an infinite set of Test::Value2/, 
     'Getting infinite set of Test::Value2s threw an exception');

$a1 = Test::Value2->get(string1 => 'qwe', string2 => undef);
ok($a1, "get(string1 => 'qwe', string2 => undef) worked");
$a2 = Test::Value2->get(id => 'qwe');
ok($a2, "get(id => 'qwe') worked");
is($a1, $a2, 'They were the same object');

$a1 = Test::Value2->get(string1 => 'abc', string2 => 'def');
ok($a1, 'get() with both ID properties worked');

my $sep = Test::Value2->__meta__->_resolve_composite_id_separator;
$a2 = Test::Value2->get('abc' . $sep . 'def');
ok($a2, 'get() with the composite ID property worked');
is($a1, $a2, 'They are the same object');
is($a1->other_prop, undef, 'The non-id property is undefined');

$x1 = Test::Value2->get(string1 => 'xyz', string2 => 'xyz', other_prop => 'hi there');
ok($x1, 'get() including a non-id property worked');
is($x1->other_prop, 'hi there', 'The non-id property has the right value');

local $SIG{'__WARN__'} = sub {};   # Suppress warnings about is_unique during boolexpr construction
@o = Test::Value2->get(['xyz'.$sep.'xyz', 'abc'.$sep.'abc']);
is(scalar(@o), 2, 'get() with 2 composite IDs worked');

{ 
    local $SIG{'__WARN__'} = sub {};   # Suppress warnings about is_unique during boolexpr construction
    eval { Test::Value2->get(id => ['xyz'.$sep.'xyz', 'abc'.$sep.'abc'], other_prop => 'somethign else') };
    like($@, qr/Cannot load class Test::Value2 via UR::DataSource::Default when 'id' is a listref and non-id properties appear in the rule/,
     'Getting with multiple IDs and including non-id properites threw an exception');
}

do {
    do {
        my $pathname = 'foo';
        my $path = UR::Value::FilesystemPath->get($pathname);
        isa_ok($path, 'UR::Value::FilesystemPath', 'path');
        is($path, $pathname, 'comparing path object to string works');
    };

    do {
        my $pathname = 'foo';
        my $path = UR::Value::FilesystemPath->get($pathname);
        $path .= 'a';
        $pathname .= 'a';
        isa_ok($path, 'UR::Value::FilesystemPath', 'after concatenation path still');
        is($path, $pathname, 'string concatenation works');
    };

    do {
        my $pathname = 'foo';
        my $path = UR::Value::FilesystemPath->get($pathname);
        like($path, qr/foo/, 'matching works');
    };
};

do { # file test "operators"
    my $temp_file = File::Temp->new();
    ok(-f $temp_file, 'created temp_file');

    my $temp_dir  = File::Temp->newdir();
    ok(-d $temp_dir, 'created temp_dir');

    my $temp_filename      = $temp_file->filename;
    my $temp_dirname       = $temp_dir->dirname;
    my $symlink_filename_a = $temp_dirname . '/symlink_a';

    symlink($temp_filename, $symlink_filename_a);
    ok(-l $symlink_filename_a, 'created symlink');

    do { # file
        my $path = UR::Value::FilePath->get($temp_filename);
        isa_ok($path, 'UR::Value::FilesystemPath', 'file path');

        is($path->exists, 1, 'file path exists');
        is($path->is_dir, '', 'file path is not a dir');
        is($path->is_file, 1, 'file path is a file');
        is($path->is_symlink, '', 'file path is not a symlink');

        is($path->size, 0, 'file path size is zero');
        system("echo hello > $path");
        isnt($path->size, 0, "file path size isn't zero");
        is($path->line_count, 1, 'file path has one line');
    };

    do { # dir
        my $path = UR::Value::FilesystemPath->get($temp_dirname);
        isa_ok($path, 'UR::Value::FilesystemPath', 'dir path');

        is($path->exists, 1, 'dir path exists');
        is($path->is_dir, 1, 'dir path is a dir');
        is($path->is_file, '', 'dir path is not a file');
        is($path->is_symlink, '', 'dir path is not a symlink');
    };

    do { # symlink
        my $path = UR::Value::FilesystemPath->get($symlink_filename_a);
        isa_ok($path, 'UR::Value::FilesystemPath', 'symlink path');

        is($path->exists, 1, ' symlink path exists');
        is($path->is_dir, '', ' symlink path is not a dir');
        is($path->is_file, 1, ' symlink path is a file');
        is($path->is_symlink, 1, ' symlink path is a symlink');

        my $symlink_filename_b = "$temp_dirname/symlink_b";
        symlink($path, $symlink_filename_b);
        ok(-l $symlink_filename_b, 'created symlink_b (from an object)');
    };
};


do {
    class TestIterator {
        has => [
            things => {
                is => 'Integer',
                is_many => 1,
            },
        ],
    };

    my $o = TestIterator->create(things => [5, 6, 7, 8]);
    my $i = $o->thing_iterator();

    while (my $v = $i->next()) { }

    is_deeply($o->thing_arrayref, [5, 6, 7, 8],
        'items not remove by Value::Iterator');
};

subtest q(regression test for UR::Value::Text->get('')) => sub {
    plan tests => 4;

    my $s1 = UR::Value::Text->get('');
    isa_ok($s1, 'UR::Value::Text', 'got an');
    is($s1->id, '', 'it has the correct id');

    my $s2 = UR::Value::Text->get('');
    isa_ok($s2, 'UR::Value::Text', 'got another');
    is(refaddr($s1), refaddr($s2), 'they are the same object');
};
