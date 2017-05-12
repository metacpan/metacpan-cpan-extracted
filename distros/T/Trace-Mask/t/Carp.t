use Test2::Require::Module Carp => '1.03';
use Test2::Bundle::Extended -target => 'Trace::Mask::Carp';
use Test2::Tools::Spec -rand => 0;
use Trace::Mask::Test qw{
    test_tracer NA
    test_stack_full_combo
};

use Trace::Mask::Util qw/mask_frame/;

use Trace::Mask::Carp qw{
    confess longmess cluck mask parse_carp_line mask_trace
};

imported_ok qw{
    confess longmess cluck mask parse_carp_line mask_trace
};

diag("Carp Version: " . Carp->VERSION . "\n");

tests carp_replacements => sub {
    local $ENV{'NO_TRACE_MASK'};

    test_tracer(
        name    => 'longmess',
        type    => 'return',
        trace   => \&longmess,
        convert => sub {
            my $trace = shift;
            my @stack;

            for my $line (split /[\n\r]+/, $trace) {
                my $info = parse_carp_line($line);
                my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                push @stack => [$call, $args];
            }

            return \@stack;
        },
    );

    test_tracer(
        name    => 'confess',
        type    => 'exception',
        trace   => \&confess,
        convert => sub {
            my $trace = shift;
            my @stack;

            for my $line (split /[\n\r]+/, $trace) {
                my $info = parse_carp_line($line);
                my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                push @stack => [$call, $args];
            }

            return \@stack;
        },
    );

    test_tracer(
        name    => 'cluck',
        type    => 'warning',
        trace   => \&cluck,
        convert => sub {
            my $trace = shift;
            my @stack;

            for my $line (split /[\n\r]+/, $trace) {
                my $info = parse_carp_line($line);
                my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                push @stack => [$call, $args];
            }

            return \@stack;
        },
    );
};

describe import => sub {
    my $real_confess  = \&Carp::confess;
    my $real_longmess = \&Carp::longmess;
    my $real_cluck    = \&Carp::cluck;

    around_each 'local' => sub {
        # Make sure these handlers get restored
        local $SIG{__WARN__} = $SIG{__WARN__};
        local $SIG{__DIE__}  = $SIG{__DIE__};

        # Make sure carp is restored
        no warnings 'redefine';
        local *Carp::confess  = $real_confess;
        local *Carp::longmess = $real_longmess;
        local *Carp::cluck    = $real_cluck;

        $_[0]->();
    };

    tests global => sub {
        local $SIG{__WARN__};
        local $SIG{__DIE__};

        ok(!$SIG{__WARN__}, "unset __WARN__ handler");
        ok(!$SIG{__DIE__},  "unset __DIE__ handler");

        $CLASS->import('-global');

        ok($SIG{__WARN__}, "set __WARN__ handler");
        ok($SIG{__DIE__},  "set __DIE__ handler");
    };

    tests wrap => sub {
        $CLASS->import('-wrap');
        ref_is(Carp->can('confess'),  $CLASS->can('confess'),  "overrode Carp::confess");
        ref_is(Carp->can('longmess'), $CLASS->can('longmess'), "overrode Carp::longmess");
        ref_is(Carp->can('cluck'),    $CLASS->can('cluck'),    "overrode Carp::cluck");
    };

    tests bad_imports => sub {
        like(
            dies { $CLASS->import('xxx') },
            qr/'xxx' is not exported by $CLASS/,
            "Bad import"
        );

        like(
            dies { $CLASS->import('-xxx', '-yyy') },
            qr/bad flag\(s\): -xxx, -yyy/,
            "Bad flags"
        );
    };
};

tests global_handlers => sub {
    local $SIG{__DIE__};
    local $SIG{__WARN__};
    local $ENV{'NO_TRACE_MASK'};

    $CLASS->import('-global');

    test_tracer(
        name    => 'confess',
        type    => 'exception',
        trace   => \&Carp::confess,
        convert => sub {
            my $trace = shift;
            my @stack;

            for my $line (split /[\n\r]+/, $trace) {
                my $info = parse_carp_line($line);
                my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                push @stack => [$call, $args];
            }

            return \@stack;
        },
    );

    test_tracer(
        name    => 'cluck',
        type    => 'sigwarn',
        trace   => \&Carp::cluck,
        convert => sub {
            my $trace = shift;
            my @stack;

            for my $line (split /[\n\r]+/, $trace) {
                my $info = parse_carp_line($line);
                my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                push @stack => [$call, $args];
            }

            return \@stack;
        },
    );

};

tests wrap => sub {
    no warnings 'redefine';
    local *Carp::confess  = sub { die 'oops' };
    local *Carp::cluck    = sub { die 'oops' };
    local *Carp::longmess = sub { die 'oops' };
    local *confess;
    local *cluck;
    local *longmess;
    use warnings 'redefine';

    not_imported_ok qw/confess longmess cluck/;

    $CLASS->import('-wrap');
    ref_is(\&Carp::confess,  \&Trace::Mask::Carp::confess,  "got our confess");
    ref_is(\&Carp::cluck,    \&Trace::Mask::Carp::cluck,    "got our cluck");
    ref_is(\&Carp::longmess, \&Trace::Mask::Carp::longmess, "got our longmess");

    Carp->import(qw/confess longmess cluck/);
    imported_ok qw/confess longmess cluck/;

    ref_is(\&confess,  \&Trace::Mask::Carp::confess,  "got our confess");
    ref_is(\&cluck,    \&Trace::Mask::Carp::cluck,    "got our cluck");
    ref_is(\&longmess, \&Trace::Mask::Carp::longmess, "got our longmess");

    test_tracer(
        name    => 'longmess',
        type    => 'return',
        trace   => \&longmess,
        convert => sub {
            my $trace = shift;
            my @stack;

            for my $line (split /[\n\r]+/, $trace) {
                my $info = parse_carp_line($line);
                my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                push @stack => [$call, $args];
            }

            return \@stack;
        },
    );

    test_tracer(
        name    => 'confess',
        type    => 'exception',
        trace   => \&confess,
        convert => sub {
            my $trace = shift;
            my @stack;

            for my $line (split /[\n\r]+/, $trace) {
                my $info = parse_carp_line($line);
                my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                push @stack => [$call, $args];
            }

            return \@stack;
        },
    );

    test_tracer(
        name    => 'cluck',
        type    => 'warning',
        trace   => \&cluck,
        convert => sub {
            my $trace = shift;
            my @stack;

            for my $line (split /[\n\r]+/, $trace) {
                my $info = parse_carp_line($line);
                my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                push @stack => [$call, $args];
            }

            return \@stack;
        },
    );
};

tests mask => sub {
    mask {
        test_tracer(
            name    => 'confess',
            type    => 'exception',
            trace   => \&Carp::confess,
            convert => sub {
                my $trace = shift;
                my @stack;

                for my $line (split /[\n\r]+/, $trace) {
                    my $info = parse_carp_line($line);
                    my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                    my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                    push @stack => [$call, $args];
                }

                return \@stack;
            },
        );

        test_tracer(
            name    => 'cluck',
            type    => 'sigwarn',
            trace   => \&Carp::cluck,
            convert => sub {
                my $trace = shift;
                my @stack;

                for my $line (split /[\n\r]+/, $trace) {
                    my $info = parse_carp_line($line);
                    my $call = [NA, @{$info}{qw/file line/}, $info->{sub} || NA];
                    my $args = $info->{args} ? [map { m/^.*=\w+\(.*$/ ? "$_" : eval $_ } split /\s*,\s*/, $info->{args}] : [];
                    push @stack => [$call, $args];
                }

                return \@stack;
            },
        );
    };
};

tests parse_carp => sub {
    my $file = __FILE__;
    my $line = __LINE__ + 1;
    my $trace = sub { eval { sub { Carp::longmess('yyy') }->('xxx') } }->('aaa', 'bbb');
    my ($error, $eval, $anon) = split /[\n\r]+/, $trace;

    is(
        parse_carp_line($error),
        {indent => "", msg => 'yyy', file => $file, line => $line, orig => $error},
        "got fields form error line"
    );

    is(
        parse_carp_line($eval),
        {indent => "\t", sub => 'eval', file => $file, line => $line, orig => $eval},
        "got fields from eval"
    );

    like(
        parse_carp_line($anon),
        {indent => "\t", sub => 'main::__ANON__', args => qr/^("|')aaa("|')\s*,\s*('|")bbb("|')$/, file => $file, line => $line, orig => $anon},
        "got fields from regular sub call"
    );

    is(
        parse_carp_line("ffaas asdfasg gastrh sdfg at file asg 234"),
        undef,
        "Not a carp line"
    );
};


tests mask_trace => sub {
    my $file = __FILE__;
    my $line = __LINE__ + 1;
    my $trace = sub { eval { sub { Carp::longmess("fahfjas fdajas\ndfhajsdfh sajfdhja\nasdfs\n") }->('xxx') } }->('aaa', 'bbb');

    $trace = mask_trace($trace, 'longmess');

    my ($e1, $e2, $e3, $msg, $eval, $anon) = split /[\n\r]+/, $trace;

    is($e1, "fahfjas fdajas", "First error line");
    is($e2, "dfhajsdfh sajfdhja", "Second error line");
    is($e3, "asdfs", "Third error line");

    like($msg, qr/ at \Q$file\E line $line\.?/, "got initial message");
    is($eval, "\teval {...} called at $file line $line", "got eval");
    like($anon, qr/^\tmain::__ANON__\(('|")aaa('|"),\s*('|")bbb("|')\) called at $file line $line.?$/, "got anon");
};

done_testing;
