use Test2::V0 -no_srand => 1;
use Test2::Require::ProgramInPath ();

subtest 'skip' => sub {

    plan 2;

    local *File::Which::which = sub {
        is(\@_, ['foo']);
        return undef;
    };

    is(
        Test2::Require::ProgramInPath->skip('foo'),
        'This test only runs if foo is in the PATH',
    );

};

subtest 'no skip' => sub {

    plan 2;

    local *File::Which::which = sub {
        is(\@_, ['foo']);
        return '/bin/foo';
    };

    is(
        Test2::Require::ProgramInPath->skip('foo'),
        U(),
    );

};

done_testing;
