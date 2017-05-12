package CondTestMore;

BEGIN
{
    eval {
        require Test::More;
    };
    if ($@)
    {
        warn "You don't have Test::More. Terminating";
        print "1..0\n";
        exit 0;
    }
    Test::More->import();
    @ISA = qw(Test::More);
    *EXPORT = \@Test::More::EXPORT;
}

1;
