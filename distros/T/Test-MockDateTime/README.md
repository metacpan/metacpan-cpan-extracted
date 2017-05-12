Test-MockDateTime
=================

allows mocking DateTime->now in tests

    use Test::More;
    use Test::MockDateTime;
    use DateTime;
    
    on '2013-01-02 03:04:05' => sub {
        # inside this block all calls to DateTime::now 
        # will report a mocked date.
        
        my $now = DateTime->now;
        is $now->ymd, '2013-01-02', 'occured now';
    };
    
    done_testing;
