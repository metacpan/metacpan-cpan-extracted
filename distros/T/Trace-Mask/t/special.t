use Test2::Bundle::Extended;
use Test2::Tools::Spec;
use Trace::Mask::Reference qw/trace trace_string/;
use Trace::Mask::Util qw/update_mask/;
use Data::Dumper;

my ($end, $begin, $unitcheck, $check, $init, $destroy, $import, $unimport);

BEGIN { update_mask('*', '*', \&trace_end, {stop => 1, hide => 1}) }
sub trace_end { do_trace() } my $do_trace_line = __LINE__;
sub do_trace { trace() }     my $trace_line    = __LINE__;

BEGIN        { $begin     = trace_end() };
CHECK        { $check     = trace_end() };
INIT         { $init      = trace_end() };
sub import   { $import    = trace_end() };
sub unimport { $unimport  = trace_end() };

my $f = __FILE__;
my $l = __LINE__ + 1;
my $uc = eval "#line $l \"$f\"\nUNITCHECK { \$unitcheck = trace_end() }; 1";

my $x = 0;
sub DESTROY {
    return if $x++;
    $destroy = trace_end()
}

my $file = __FILE__;
main->import;
main->unimport;

my $one = bless {}, 'main';
$one = undef;

my $any = sub { 1 };

like(
    $begin,
    [
        [[__PACKAGE__, __FILE__, $trace_line,    'Trace::Mask::Reference::trace'], [], {}],
        [[__PACKAGE__, __FILE__, $do_trace_line, 'main::do_trace'],                [], {}],
        [[__PACKAGE__, __FILE__, $any,           'main::BEGIN'],                   [], {lock => 'BEGIN'}],
        DNE(),
    ],
    "BEGIN trace"
);

like(
    $unitcheck,
    [
        [[__PACKAGE__, __FILE__, $trace_line,    'Trace::Mask::Reference::trace'], [], {}],
        [[__PACKAGE__, __FILE__, $do_trace_line, 'main::do_trace'],                [], {}],
        [[__PACKAGE__, __FILE__, $any,           'main::UNITCHECK'],               [], {lock => 'UNITCHECK'}],
        DNE(),
    ],
    "UNITCHECK trace"
) if $uc;

like(
    $check,
    [
        [[__PACKAGE__, __FILE__, $trace_line,    'Trace::Mask::Reference::trace'], [], {}],
        [[__PACKAGE__, __FILE__, $do_trace_line, 'main::do_trace'],                [], {}],
        [[__PACKAGE__, __FILE__, $any,           'main::CHECK'],                   [], {lock => 'CHECK'}],
        DNE(),
    ],
    "CHECK trace"
);

like(
    $init,
    [
        [[__PACKAGE__, __FILE__, $trace_line,    'Trace::Mask::Reference::trace'], [], {}],
        [[__PACKAGE__, __FILE__, $do_trace_line, 'main::do_trace'],                [], {}],
        [[__PACKAGE__, __FILE__, $any,           'main::INIT'],                    [], {lock => 'INIT'}],
        DNE(),
    ],
    "INIT trace"
);

like(
    $destroy,
    [
        [[__PACKAGE__, __FILE__, $trace_line,    'Trace::Mask::Reference::trace'], [], {}],
        [[__PACKAGE__, __FILE__, $do_trace_line, 'main::do_trace'],                [], {}],
        [[__PACKAGE__, __FILE__, $any,           'main::DESTROY'],                 [], {lock => 'DESTROY'}],
        DNE(),
    ],
    "DESTROY trace"
);

like(
    $import,
    [
        [[__PACKAGE__, __FILE__, $trace_line,    'Trace::Mask::Reference::trace'], [], {}],
        [[__PACKAGE__, __FILE__, $do_trace_line, 'main::do_trace'],                [], {}],
        [[__PACKAGE__, __FILE__, $any,           'main::import'],                  [], {lock => 'import'}],
        DNE(),
    ],
    "import trace"
);

like(
    $unimport,
    [
        [[__PACKAGE__, __FILE__, $trace_line,    'Trace::Mask::Reference::trace'], [], {}],
        [[__PACKAGE__, __FILE__, $do_trace_line, 'main::do_trace'],                [], {}],
        [[__PACKAGE__, __FILE__, $any,           'main::unimport'],                  [], {lock => 'unimport'}],
        DNE(),
    ],
    "unimport trace"
);

# We want this to run before any other end blocks, which means we add it last
END {
    local $?;
    $end = trace_end();

    like(
        $end,
        [
            [[__PACKAGE__, __FILE__, $trace_line,    'Trace::Mask::Reference::trace'], [], {}],
            [[__PACKAGE__, __FILE__, $do_trace_line, 'main::do_trace'],                [], {}],
            [[__PACKAGE__, __FILE__, $any,           'main::END'],                     [], {lock => 'END'}],
            DNE(),
        ],
        "END trace"
    );

    $? = 0;

    plan $uc ? 8 : 7;
}
