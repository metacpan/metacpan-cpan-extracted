use Test::Mini::Unit;

case t::Test::Mini::Unit::Sugar::TestCase::Variables {
    setup    { assert_instance_of($self => __PACKAGE__); }
    test it  { assert_instance_of($self => __PACKAGE__); }
    teardown { assert_instance_of($self => __PACKAGE__); }
}
