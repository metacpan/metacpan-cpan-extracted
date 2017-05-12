use strict;
use lib qw(./t/lib ./lib);
use Man;
use Test::Expectation;
use Data::Dumper;
use Test::More;

my $man;

it_is_a 'Man';

before_each(sub {
    $man = Man->new();
});

after_each(sub {
    $man->die();
});

it_should "go to school", sub {
    Man->expects('school')->to_return('reading');

    is_deeply(
        $man->beChild(),
        'has learned reading',
        'child learns'
    );
};

it_should "get a job", sub {
    $man->expects('job')->with('qualifications')->to_return('money');
    $man->work();
};

it_should "not catch an STD", sub {
    $man->does_not_expect('std');
    $man->meetsWoman('nice');
};

it_should "catch STD when cheating on wife", sub {
    $man->expects('std')->to_return('itching and burning');

    is_deeply(
        $man->meetsWoman('hooker'),
        'itching and burning',
        'uh oh, this man is in trouble'
    );
};

it_should "get fired and hired", sub {
    $man->expects('hired');
    $man->expects('fired');

    $man->career();
};
