package Test::Expectation::Negative;

    use base 'Test::Expectation::Base';

    sub isMet {
        return !shift->{-met};
    }

1;

