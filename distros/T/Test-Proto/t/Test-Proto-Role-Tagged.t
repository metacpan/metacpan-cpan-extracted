use Test::More;

use Test::Proto::Base;
use Test::Proto::TestCase;

foreach my $obj (Test::Proto::TestCase->new, Test::Proto::Base->new) {
	subtest ( (ref $obj) => sub{
		# tags attribute
		can_ok($obj, 'tags');
		is_deeply( $obj->tags, [], 'tags begins as []');
		is( $obj->has_tag('nope'), 0, 'Tags begins as []');

		# add_tag
		can_ok($obj, 'add_tag');
		isa_ok($obj->add_tag('yep'), ref $obj, 'add_tag returns the object');
		ok($obj->has_tag('yep'), 'add_tag does indeed add the tag');
		ok(!$obj->has_tag('nope'), 'add_tag does not add any other tag');
		ok(!$obj->has_tag('YEP'), 'add_tag is case sensitive');
		isa_ok($obj->add_tag('yep'), ref $obj, 'add_tag returns the object when you do it again with a tag already added');
		is_deeply($obj->tags, ['yep'], 're-adding a tag does not create a new one');

		# remove_tag
		$obj->add_tag('another');
		can_ok($obj, 'remove_tag');
		isa_ok($obj->remove_tag('another'), ref $obj, 'remove_tag returns the object');
		is_deeply($obj->tags, ['yep'], 'remove_tag does indeed remove the tag');
		isa_ok($obj->remove_tag('another'), ref $obj, 'remove_tag does not die when removing a tag which is no longer present');
		isa_ok($obj->remove_tag('yep')->remove_tag('another'), ref $obj, 'remove_tag does not die when no tags');
	});
}

use Test::Proto::TestRunner;

sub runner {Test::Proto::TestRunner->new};

my $result = Test::Proto::Base->new->eq('b')->validate('a', runner->skipped_tags(['skip_me']));

ok(!$result, 'With skipped_tags set, doesn\'t skip normally');

$result = Test::Proto::Base->new->eq('b')->add_tag('skip_me')->validate('a', runner->skipped_tags(['skip_me']));

ok($result, 'Skips failing test ok with skipped_tags');

$result = Test::Proto::Base->new->eq('b')->validate('a', runner->required_tags(['need_me']));

ok($result, 'Skips failing test ok with required_tags');

$result = Test::Proto::Base->new->eq('b')->add_tag('need_me')->validate('a', runner->required_tags(['need_me']));

ok(!$result, 'With required_tags, does not skip when requirement is met');

done_testing();
