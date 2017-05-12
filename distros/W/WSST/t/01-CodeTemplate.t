use strict;
use Test::More tests => 13;

BEGIN { use_ok("WSST::CodeTemplate"); }

can_ok("WSST::CodeTemplate", qw(get set expand new_template));

my $obj1 = WSST::CodeTemplate->new();
ok(ref $obj1, '$obj1->new()');
$obj1->set(test => 'TESTTEST');
is($obj1->get('test'), 'TESTTEST', '$obj1->set/get');
$obj1->set(test => 'TESTTESTTEST', test2 => 'TEST2');
is($obj1->get('test'), 'TESTTESTTEST', '$obj1->set/get');
is($obj1->get('test2'), 'TEST2', '$obj1->set/get');

my $tmpl = eval { $obj1->new_template('t/test_templates/test.tmpl'); };
ok(ref $tmpl, '$obj1->new_template()');
ok(!$@, '$obj1->new_template()');

my $obj2 = WSST::CodeTemplate->new(tmpl_dirs => ['t/test_templates'],
                                   vars => { test => 'TESTTEST' });
ok(ref $obj2, '$obj2->new(...)');
is_deeply($obj2->{tmpl_dirs}, ['t/test_templates'], '$obj2->{tmpl_dirs}');
is($obj2->get('test'), 'TESTTEST', '$obj2->get');

my $data = eval { $obj2->expand('test.tmpl'); };
is($data, "test: TESTTEST\n", '$obj2->expand');
ok(!$@, '$obj2->expand');

1;
