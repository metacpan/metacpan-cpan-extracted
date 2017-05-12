use Test::Mini::Unit;

{
    package Dummy;

    use Test::Mini::Unit::Sugar::Shared;

    shared Tests { }
    shared ::Qualified { }
}

case t::Test::Mini::Unit::Sugar::Shared::Behavior {
    test keyword_creates_new_package {
        assert_can('Dummy::Tests' => 'import');
    }
    
    test keyword_creates_top_level_package_for_qualified_name {
        assert_can('Qualified' => 'import');
    }
    
    test created_packages_include_relevant_methods {
        assert_can('Dummy::Tests' => $_) for qw/ setup teardown test assert /;
        assert_can('Qualified'    => $_) for qw/ setup teardown test assert /;
    }
    
    test created_packages_ared_marked_as_loaded {
        assert_equal($INC{'Dummy/Tests.pm'}, __FILE__);
        assert_equal($INC{'Qualified.pm'},   __FILE__);
    }
}

1;
