use MooseX::Declare;

role t::RoleTest {
    use Test::Sweet;

    test from_role {
        pass 'tests can come from roles';
    }
}

class t::Basic with t::RoleTest {
    use Test::Sweet;

    test does_it_work {
        pass 'it works';
        return (1,2,3) if wantarray;
        return 42;
    }

    test method_call {
        my $result = $self->does_it_work;
        is $result, 42, 'got return value';

        my @result = $self->does_it_work;
        is_deeply \@result, [1,2,3], 'wantarray is preserved correctly';
    }

    test calling_a_test_from_a_role { $self->from_role }

    # from_role test (from t::RoleTest) runs here

}

