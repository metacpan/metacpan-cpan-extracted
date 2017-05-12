use MooseX::Declare;

class t::Subclass extends t::Basic {
    use Test::Sweet;

    test test_from_subclass {
        pass 'tests in subclasses run';
    }

    # still runs as the second test; since it appears as the second
    # test in the parent
    test method_call {
        pass 'using my own method_call test';
    }

}
