#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(timethese);

use String::Similarity             ();
use Text::Brew                     ();
use Text::Fuzzy                    ();
use Text::Compare                  ();
use Text::Dice                     ();
use Text::Levenshtein              ();
use Text::Levenshtein::XS          ();
use Text::LevenshteinXS            ();
use Text::Levenshtein::Damerau::PP ();
use Text::Levenshtein::Damerau::XS ();
use Text::WagnerFischer            ();

my @strings;

my %algos = (
    Brew => sub {
        Text::Brew::distance(@strings, { -output => 'distance' });
    },
    Compare => sub {
        my $tc = Text::Compare->new;
        $tc->similarity(@strings);
    },
    Damerau => sub { Text::Levenshtein::Damerau::PP::pp_edistance(@strings) },
    Damerau_XS =>
        sub { Text::Levenshtein::Damerau::XS::xs_edistance(@strings) },
    Dice           => sub { Text::Dice::coefficient(@strings) },
    Fuzzy          => sub { Text::Fuzzy::distance_edits(@strings) },
    Levenshtein    => sub { Text::Levenshtein::distance(@strings) },
    Levenshtein_XS => sub { Text::Levenshtein::XS::distance(@strings) },
    LevenshteinXS  => sub { Text::LevenshteinXS::distance(@strings) },
    Similarity     => sub { String::Similarity::similarity(@strings) },
    WagnerFischer  => sub { Text::WagnerFischer::distance(@strings) },
);

my @tests = (
    ['2 short strings',  'france', 'republic of france'],
    ['utf-8 strings',  "\x{00DF}france", "republic of france\x{00DF}"],
    [
        '1 long, 1 short string',
        'Structural Assessment: The Role of Large and Full-Scale Testing'x100,
        'Web Aplications',
    ],
    [
        '1 short, 1 long string',
        'Web Aplications',
        'Structural Assessment: The Role of Large and Full-Scale Testing'x100,
    ],
);

for my $test (@tests) {
    printf "%s\n", $test->[0];
    @strings = @$test[1..2];
    Benchmark::cmpthese -2, \ %algos;
    print "\n";
}

__END__

=head1 BENCHMARKS

    2 short strings
                        Rate Compare   Brew WagnerFischer Levenshtein  Fuzzy Damerau  Dice Damerau_XS Levenshtein_XS LevenshteinXS Similarity
    Compare           1039/s      --   -52%          -70%        -78%   -79%    -83%  -99%       -99%          -100%         -100%      -100%
    Brew              2143/s    106%     --          -39%        -54%   -56%    -64%  -98%       -99%           -99%         -100%      -100%
    WagnerFischer     3502/s    237%    63%            --        -25%   -28%    -42%  -96%       -98%           -98%         -100%      -100%
    Levenshtein       4664/s    349%   118%           33%          --    -4%    -23%  -95%       -97%           -98%         -100%      -100%
    Fuzzy             4872/s    369%   127%           39%          4%     --    -19%  -95%       -97%           -98%         -100%      -100%
    Damerau           6024/s    480%   181%           72%         29%    24%      --  -93%       -96%           -97%         -100%      -100%
    Dice             90649/s   8622%  4129%         2489%       1844%  1761%   1405%    --       -44%           -61%          -94%       -96%
    Damerau_XS      160490/s  15342%  7388%         4483%       3341%  3194%   2564%   77%         --           -30%          -89%       -92%
    Levenshtein_XS  230400/s  22068% 10649%         6479%       4840%  4629%   3725%  154%        44%             --          -84%       -89%
    LevenshteinXS  1451196/s 139527% 67605%        41341%      31014% 29689%  23992% 1501%       804%           530%            --       -29%
    Similarity     2047995/s 196948% 95448%        58384%      43810% 41940%  33899% 2159%      1176%           789%           41%         --

    utf-8 strings
                        Rate Compare   Brew WagnerFischer Levenshtein  Fuzzy Damerau  Dice Damerau_XS Levenshtein_XS Similarity LevenshteinXS
    Compare            881/s      --   -44%          -69%        -77%   -78%    -82%  -99%       -99%          -100%      -100%         -100%
    Brew              1570/s     78%     --          -45%        -60%   -61%    -69%  -98%       -99%           -99%      -100%         -100%
    WagnerFischer     2847/s    223%    81%            --        -27%   -29%    -43%  -97%       -98%           -99%      -100%         -100%
    Levenshtein       3877/s    340%   147%           36%          --    -3%    -22%  -95%       -97%           -98%      -100%         -100%
    Fuzzy             4013/s    355%   156%           41%          4%     --    -20%  -95%       -97%           -98%      -100%         -100%
    Damerau           4986/s    466%   218%           75%         29%    24%      --  -94%       -97%           -98%       -99%         -100%
    Dice             81757/s   9177%  5107%         2772%       2009%  1937%   1540%    --       -45%           -64%       -91%          -94%
    Damerau_XS      148882/s  16794%  9382%         5130%       3740%  3610%   2886%   82%         --           -34%       -83%          -88%
    Levenshtein_XS  225989/s  25543% 14293%         7839%       5729%  5531%   4432%  176%        52%             --       -74%          -82%
    Similarity      866110/s  98179% 55063%        30325%      22241% 21481%  17270%  959%       482%           283%         --          -32%
    LevenshteinXS  1281531/s 145317% 81522%        44919%      32957% 31832%  25602% 1467%       761%           467%        48%            --

    1 long, 1 short string
                    Rate    Brew   Fuzzy WagnerFischer Levenshtein Damerau Compare Damerau_XS  Dice Levenshtein_XS LevenshteinXS Similarity
    Brew           2.30/s      --    -19%          -42%        -56%    -69%    -96%       -99% -100%          -100%         -100%      -100%
    Fuzzy          2.84/s     23%      --          -29%        -46%    -61%    -95%       -99% -100%          -100%         -100%      -100%
    WagnerFischer  4.00/s     74%     41%            --        -24%    -45%    -94%       -99% -100%          -100%         -100%      -100%
    Levenshtein    5.26/s    128%     85%           32%          --    -28%    -92%       -98%  -99%          -100%         -100%      -100%
    Damerau        7.32/s    218%    157%           83%         39%      --    -88%       -97%  -99%           -99%         -100%      -100%
    Compare        62.0/s   2591%   2080%         1450%       1078%    747%      --       -77%  -93%           -95%          -98%       -99%
    Damerau_XS      275/s  11854%   9587%         6786%       5133%   3664%    344%         --  -69%           -76%          -91%       -95%
    Dice            876/s  37933%  30718%        21808%      16550%  11876%   1313%       218%    --           -23%          -70%       -84%
    Levenshtein_XS 1144/s  49545%  40127%        28498%      21634%  15533%   1745%       315%   31%             --          -61%       -80%
    LevenshteinXS  2911/s 126220% 102256%        72665%      55201%  39678%   4595%       957%  232%           154%            --       -48%
    Similarity     5581/s 242105% 196157%       139419%     105935%  76171%   8901%      1926%  537%           388%           92%         --

    1 short, 1 long string
                    Rate    Brew  Fuzzy WagnerFischer Levenshtein Damerau Compare Damerau_XS Similarity  Dice Levenshtein_XS LevenshteinXS
    Brew           2.22/s      --   -19%          -46%        -58%    -72%    -96%       -99%      -100% -100%          -100%         -100%
    Fuzzy          2.73/s     23%     --          -33%        -49%    -65%    -96%       -99%       -99% -100%          -100%         -100%
    WagnerFischer  4.09/s     84%    50%            --        -23%    -48%    -93%       -99%       -99% -100%          -100%         -100%
    Levenshtein    5.34/s    140%    96%           31%          --    -32%    -91%       -98%       -99%  -99%           -99%         -100%
    Damerau        7.80/s    251%   186%           91%         46%      --    -87%       -98%       -99%  -99%           -99%         -100%
    Compare        62.4/s   2707%  2187%         1425%       1068%    699%      --       -81%       -88%  -93%           -94%          -97%
    Damerau_XS      331/s  14790% 12032%         7988%       6097%   4139%    430%         --       -38%  -62%           -67%          -86%
    Similarity      533/s  23864% 19426%        12918%       9873%   6723%    754%        61%         --  -38%           -48%          -77%
    Dice            860/s  38596% 31430%        20920%      16004%  10918%   1279%       160%        61%    --           -16%          -62%
    Levenshtein_XS 1018/s  45714% 37230%        24787%      18966%  12944%   1532%       208%        91%   18%             --          -55%
    LevenshteinXS  2286/s 102757% 83710%        55773%      42705%  29186%   3564%       591%       329%  166%           125%            --

=cut
