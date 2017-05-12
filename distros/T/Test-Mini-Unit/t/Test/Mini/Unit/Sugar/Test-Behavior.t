use Test::Mini::Unit;

{
    package ImportTest;
    use Test::Mini::Unit::Sugar::Test;
    
    test everything { return 42 }
    test self       { return $self }
}

case t::Test::Mini::Unit::Sugar::Test::Behavior {
    test keyword_creates_new_method {
        assert_can(ImportTest => 'test_everything');
        assert_equal(ImportTest->test_everything(), 42);
    }

    test methods_automatically_assign_self_variable {
        assert_equal(ImportTest::test_self('FIRST') => 'FIRST');
    }
}
