use Test::More;
use Text::Unpack::Auto qw(guess_unpack auto_unpack);

# n=2 means gaps of 1 get bridged, gaps of 2+ are real separators
# (min_gap = n-1 = 1, so 0{1,1} matches)

subtest 'n=2: bridge single zeros' => sub {
    is Text::Unpack::Auto::close_gaps('101', 2), '111', 'single zero between ones gets bridged';
    is Text::Unpack::Auto::close_gaps('10101', 2), '11111', 'multiple single zeros all bridged';
    is Text::Unpack::Auto::close_gaps('100101', 2), '100111', 'gap of 2 preserved, gap of 1 bridged';
    is Text::Unpack::Auto::close_gaps('1001001', 2), '1001001', 'all gaps of 2, none bridged';
};

subtest 'n=3: bridge gaps up to 2' => sub {
    is Text::Unpack::Auto::close_gaps('101', 3),   '111',   'gap of 1 bridged';
    is Text::Unpack::Auto::close_gaps('1001', 3),  '1111',  'gap of 2 bridged';
    is Text::Unpack::Auto::close_gaps('10001', 3), '10001', 'gap of 3 preserved';
};

subtest 'edge cases' => sub {
    is Text::Unpack::Auto::close_gaps('1', 2),    '1',    'single column, no gaps';
    is Text::Unpack::Auto::close_gaps('0', 2),    '0',    'no data columns at all';
    is Text::Unpack::Auto::close_gaps('11', 2),   '11',   'adjacent ones, nothing to bridge';
    is Text::Unpack::Auto::close_gaps('101', 1),  '101',  'n=1 means min_gap=0, nothing ever bridged';
    is Text::Unpack::Auto::close_gaps('', 2),     '',     'empty string';
};

subtest 'no bridging across string boundaries' => sub {
    is Text::Unpack::Auto::close_gaps('01010', 2), '01110', 'leading/trailing zeros not affected';
    is Text::Unpack::Auto::close_gaps('0100', 2),  '0100',  'lone 1 with no right neighbour not bridged';
};

done_testing;
