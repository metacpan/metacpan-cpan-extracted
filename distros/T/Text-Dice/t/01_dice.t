use strict;
use warnings;
use Test::More;
use Text::Dice;

ok defined &coefficient, 'coefficient() is exported';

# Examples from: http://www.catalysoft.com/articles/StrikeAMatch.html

subtest 'france' => sub {
    my @tests = (
        [ 'FRANCE',          'REPUBLIC OF FRANCE', 56 ],
        [ 'FRANCE',          'QUEBEC',             0 ],
        [ 'FRENCH REPUBLIC', 'REPUBLIC OF FRANCE', 72 ],
        [ 'FRENCH REPUBLIC', 'REPUBLIC OF CUBA',   61 ],
    );
    for my $test (@tests) {
        my ($str1, $str2, $xscore) = @$test;
        my $score = 100 * sprintf '%.2f', coefficient($str1, $str2);
        is $score, $xscore, "$str1 | $str2";
    }
};

subtest 'healed' => sub {
    my @tests = (
        [ Sealed => 80 ], [ Healthy => 55 ], [ Heard => 44 ],
        [ Herded => 40 ], [ Help    => 25 ], [ Sold  => 0 ],
    );
    for my $test (@tests) {
        my ($word, $xscore) = @$test;
        my $score = 100 * sprintf '%.2f', coefficient('Healed', $word);
        is $score, $xscore, "Healed | $word";
    }
};

subtest 'book title searchs' => sub {
    my %queries = (
        'Web Database Applications' => [ 82, 71, 70, 67, 51, 49, 12, 10 ],
        'PHP Web Applications'      => [ 68, 59, 58, 47, 67, 34, 7,  11 ],
        'Web Aplications'           => [ 59, 50, 49, 46, 56, 32, 7,  12 ],
    );

    my @titles = (
        'Web Database Applications with PHP & MySQL',
        'Creating Database Web Applications with PHP and ASP',
        'Building Database Applications on the Web Using PHP3',
        'Building Web Database Applications with Visual Studio 6',
        'Web Application Development With PHP',
        'WebRAD: Building Database Applications on the Web with Visual FoxPro and Web Connection',
        'Structural Assessment: The Role of Large and Full-Scale Testing',
        'How to Find a Scholarship Online',
    );

    while (my ($q, $scores) = each %queries) {
        my $i = 0;
        for my $t (@titles) {
            my $score = 100 * sprintf '%.2f', coefficient($q, $t);
            is $score, $scores->[$i++], "$q | $t";
        }
    }
};

subtest 'arrayref input' => sub {
    my ($str1, $str2, $xscore) = ('FRANCE', 'REPUBLIC OF FRANCE', 56);
    my ($aref1, $aref2);
    for my $w (split ' ', lc $str1) {
        push @$aref1, substr $w, $_, 2 for (0 .. length($w) - 2);
    }
    for my $w (split ' ', lc $str2) {
        push @$aref2, substr $w, $_, 2 for (0 .. length($w) - 2);
    }
    my $score = 100 * sprintf '%.2f', coefficient($aref1, $aref2);
    is $score, $xscore, "$str1 | $str2";
};

subtest 'bad input' => sub {
    my ($str1, $str2, $xscore) = ('FRANCE', 'REPUBLIC OF FRANCE', 56);
    my $aref = ['REPUBLIC', 'OF', 'FRANCE'];
    is coefficient($str1, $aref), undef, "string and arrayref";
};

done_testing;
