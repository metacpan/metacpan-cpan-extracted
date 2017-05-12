use Test::Builder::Tester tests=>3;
use Test::XML::Simple;

my $with_attr = <<EOS;
<results total="1">this is a result</results>
EOS

test_out('ok 1 - nonempty works');
xml_is($with_attr, '//results/@total', "1", "nonempty works");
test_test('nonempty');

my $two_tag = <<EOS;
<results total="0"></results>
EOS

test_out('ok 1 - two-tag works');
xml_is($two_tag, '//results/@total', "0", "two-tag works");
test_test('two-tag');

my $collapsed = <<EOS;
<results total="0"/>
EOS

test_out('ok 1 - collapsed works');
xml_is($collapsed, '//results/@total', "0", "collapsed works");
test_test('collapsed');
