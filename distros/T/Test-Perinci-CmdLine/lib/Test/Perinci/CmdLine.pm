package Test::Perinci::CmdLine;

our $DATE = '2017-01-12'; # DATE
our $VERSION = '1.47'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Devel::Confess;

use Perinci::CmdLine::Gen qw(gen_pericmd_script);
use Capture::Tiny qw(capture);
use File::Path qw(remove_tree);
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir tempfile);
use IPC::System::Options qw(run);

use Test::More 0.98;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = (
    'pericmd_ok', # old, back-compat
    'pericmd_run_suite_ok',
    'pericmd_run_ok',
    'pericmd_run_test_groups_ok',
    'pericmd_run_tests_ok',
);

our %SPEC;

my %common_args = (
    class => {
        summary => 'Which Perinci::CmdLine class are we testing',
        schema => ['str*', in=>[
            'Perinci::CmdLine::Lite',
            'Perinci::CmdLine::Classic',
            'Perinci::CmdLine::Inline',
        ]],
        req => 1,
    },
);

my %incl_excl_tags_args = (
    include_tags => {
        schema => ['array*', of=>'str*'],
    },
    exclude_tags => {
        schema => ['array*', of=>'str*'],
    },
);

my %run_args = (
    name => {
        summary => 'Test name',
        description => <<'_',

If not specified, a nice default will be picked (e.g. from `argv`).

_
        schema => 'str*',
    },
    gen_args => {
        summary => 'Arguments to be passed to '.
            '`Perinci::CmdLine::Gen::gen_pericmd_script()`',
        schema => 'hash*',
        req => 1,
        tags => ['category:input'],
    },
    inline_gen_args => {
        summary => 'Additional arguments to be passed to '.
            '`Perinci::CmdLine::Gen::gen_pericmd_script()`',
        description => <<'_',

Keys from this argument will be added to `gen_args` and will only be used when
`class` is `Perinci::CmdLine::Inline`.

_
        schema => 'hash*',
        tags => ['category:input', 'variant:inline'],
    },
    classic_gen_args => {
        summary => 'Additional arguments to be passed to '.
            '`Perinci::CmdLine::Gen::gen_pericmd_script()`',
        description => <<'_',

Keys from this argument will be added to `gen_args` and will only be used when
`class` is `Perinci::CmdLine::Classic`.

_
        schema => 'hash*',
        tags => ['category:input', 'variant:classic'],
    },
    lite_gen_args => {
        summary => 'Additional arguments to be passed to '.
            '`Perinci::CmdLine::Gen::gen_pericmd_script()`',
        description => <<'_',

Keys from this argument will be added to `gen_args` and will only be used when
`class` is `Perinci::CmdLine::Lite`.

_
        schema => 'hash*',
        tags => ['category:input', 'variant:lite'],
    },
    argv => {
        summary => 'Command-line arguments that will be passed to '.
            'generated CLI script',
        schema => 'array*',
        default => [],
        tags => ['category:input'],
    },
    stdin => {
        summary => "Supply stdin content to generated CLI script",
        schema => 'str*',
        tags => ['category:input'],
    },
    env => {
        summary => "Set environment variables for generated CLI script",
        schema => 'hash*',
        tags => ['category:input'],
    },
    comp_line0 => {
        summary => "Set COMP_LINE environment for generated CLI script",
        description => <<'_',

Can contain `^` (caret) character which will be stripped from the final
`COMP_LINE` and the position of the character will be used to determine
`COMP_POINT`.

_
        schema => 'str*',
        tags => ['category:input'],
    },
    inline_allow => {
        summary => "Modules to allow to be loaded when testing generated ".
            "Perinci::CmdLine::Inline script",
        description => <<'_',

By default, when running the generated Perinci::CmdLine::Inline script, this
perl option will be used (see <pm:lib::filter> for more details):

    -Mlib::filter=allow_noncore,0

This means the script will only be able to load core modules. But if the script
is allowed to load additional modules, you can set this `inline_allow` parameter
to, e.g. `["Foo::Bar","Baz"]` and the above perl option will become:

    -Mlib::filter=allow_noncore,0,allow,Foo::Bar;Baz

To skip using this option, set `inline_run_filter` to false.

_
        schema => ['array*', of=>'perl::modname*'],
        tags => ['category:input', 'variant:inline'],
    },
    inline_run_filter => {
        summary => "Whether to use -Mfilter when running generated ".
            "Perinci::CmdLine::Inline script",
        schema => ['bool*'],
        default => 1,
        description => <<'_',

By default, when running the generated Perinci::CmdLine::Inline script, this
perl option will be used (see <pm:lib::filter> for more details):

    -Mlib::filter=allow_noncore,0,...

This is to test that the script does not require non-core modules. To skip using
this option (e.g. when using `pack_deps` gen option set to false), set
this option to false.

_
        tags => ['category:input', 'variant:inline'],
    },

    gen_status => {
        summary => 'Expected generate result status',
        schema  => 'int*',
        default => 200,
        tags => ['category:assert'],
    },
    exit_code => {
        summary => "Expected script's exit code",
        schema => 'int*',
        default => 0,
        tags => ['category:assert'],
    },
    exit_code_like => {
        summary => "Expected script's exit code (as regex pattern)",
        schema => 're*',
        default => 0,
        tags => ['category:assert'],
    },
    stdout_like => {
        summary => "Test output of generated CLI script",
        schema => 're*',
        tags => ['category:assert'],
    },
    stdout_unlike => {
        summary => "Test output of generated CLI script",
        schema => 're*',
        tags => ['category:assert'],
    },
    stderr_like => {
        summary => "Test error output of generated CLI script",
        schema => 're*',
        tags => ['category:assert'],
    },
    stderr_unlike => {
        summary => "Test error output of generated CLI script",
        schema => 're*',
        tags => ['category:assert'],
    },
    comp_answer => {
        summary => "Test completion answer of generated CLI script",
        schema => ['array*', of=>'str*'],
        tags => ['category:assert'],
    },
    posttest => {
        summary => "Additional tests",
        description => <<'_',

For example you can do `is()` or `ok()` or other <pm:Test::More> tests.

_
        schema => 'code*',
        tags => ['category:assert'],
    },

    tags => {
        schema => 'array*',
        tags => ['hidden'],
    },
);

$SPEC{pericmd_run_test_groups_ok} = {
    v => 1.1,
    summary => 'Run groups of Perinci::CmdLine tests',
    args => {
        %common_args,
        %incl_excl_tags_args,
        tempdir => {
            schema => 'str*',
            description => <<'_',

If not specified, will create temporary directory with `File::Temp`'s
`tempdir()`.

_
        },
        cleanup_tempdir => {
            schema => 'bool',
        },
        groups => {
            schema => ['array*'],
            req => 1,
        },
    },
};
sub pericmd_run_test_groups_ok {
    my %args = @_;

    my $class   = $args{class};

    my $cleanup_tempdir = $args{cleanup_tempdir};
    my $tempdir = $args{tempdir} // do {
        $cleanup_tempdir //= 1;
        tempdir();
    };

    my $include_tags = $args{include_tags};
    my $exclude_tags = $args{exclude_tags};

    # create a pericmd script, run it, test the result
    my $test_cli = sub {
        use experimental 'smartmatch';
        no strict 'refs';
        no warnings 'redefine';

        my %test_args = @_;

        my $name = $test_args{name} // join(" ", @{$test_args{argv} // []});

        my ($exit_code, $stdout, $stderr);
        subtest $name => sub {
            my $tags = $test_args{tags} // [];

            if ($include_tags) {
                my $found;
                for (@$tags) {
                    if ($_ ~~ @$include_tags) {
                        $found++; last;
                    }
                }
                unless ($found) {
                    plan skip_all => 'Does not have any of the '.
                        'include_tag(s): ['. join(", ", @$include_tags) . ']';
                    return;
                }
            }
            if ($exclude_tags) {
                for (@$tags) {
                    if ($_ ~~ @$exclude_tags) {
                        plan skip_all => "Has one of the exclude_tag: $_";
                        return;
                    }
                }
            }

            my %gen_args;

            $gen_args{cmdline} = $class;

            if ($test_args{gen_args}) {
                $gen_args{$_} = $test_args{gen_args}{$_}
                    for keys %{$test_args{gen_args}};
            } else {
                die "Please specify 'gen_args'";
            }
            if ($class eq 'Perinci::CmdLine::Lite' &&
                    $test_args{lite_gen_args}) {
                $gen_args{$_} = $test_args{lite_gen_args}{$_}
                    for keys %{$test_args{lite_gen_args}};
            }
            if ($class eq 'Perinci::CmdLine::Classic' &&
                    $test_args{classic_gen_args}) {
                $gen_args{$_} = $test_args{classic_gen_args}{$_}
                    for keys %{$test_args{classic_gen_args}};
            }
            if ($class eq 'Perinci::CmdLine::Inline' &&
                    $test_args{inline_gen_args}) {
                $gen_args{$_} = $test_args{inline_gen_args}{$_}
                    for keys %{$test_args{inline_gen_args}};
            }

            $gen_args{read_config} //= 0;
            $gen_args{read_env} //= 0;

            my ($fh, $filename) = tempfile('cliXXXXXXXX', DIR=>$tempdir);
            $gen_args{output_file} = $filename;
            $gen_args{overwrite} = 1;
            my $gen_res = gen_pericmd_script(%gen_args);
            if (exists $test_args{gen_status}) {
                is($gen_res->[0], $test_args{gen_status}, "gen status")
                    or return;
                return if $test_args{gen_status} != 200;
            }
            die "Can't generate CLI script at $filename: ".
                "$gen_res->[0] - $gen_res->[1]" unless $gen_res->[0] == 200;
            note "Generated CLI script at $filename";
            note "gen_pericmd_script args: ", explain \%gen_args;
            note "argv: ", explain $test_args{argv};

            my $res;
            run(
                {shell=>0, die=>0, log=>1,
                 ((env=>$test_args{env}) x !!$test_args{env}),
                 ((stdin=>$test_args{stdin}) x !!defined($test_args{stdin})),
                 capture_stdout=>\$stdout, capture_stderr=>\$stderr, lang=>'C'},
                $^X,
                # pericmd-inline script must work with only core modules
                ($class eq 'Perinci::CmdLine::Inline' && ($test_args{inline_run_filter} // 1) ?
                     ("-Mlib::filter=allow_noncore,0".
                      ($test_args{inline_allow} ? ",allow,".
                       join(";",@{$test_args{inline_allow}}) : "")) : ()),
                $filename,
                @{ $test_args{argv} // []},
            );
            $stdout //= "";
            note "Script's stdout: <$stdout>";
            $stderr //= "";
            note "Script's stderr: <$stderr>";
            $exit_code = $? >> 8;

            my $exit_code_as_expected = do {
                if ($test_args{exit_code_like}) {
                    like($exit_code, $test_args{exit_code_like}, "exit_code (like)");
                } else {
                    is($exit_code, ($test_args{exit_code}//0), "exit_code");
                }
            };
            $exit_code_as_expected or do {
                diag "Script's stdout: <$stdout>";
                diag "Script's stderr: <$stderr>";
            };
            if ($test_args{stdout_like}) {
                if (ref($test_args{stdout_like}) eq 'ARRAY') {
                    for my $re (@{ $test_args{stdout_like} }) {
                        like($stdout, $re, "stdout_like");
                    }
                } else {
                    like($stdout, $test_args{stdout_like}, "stdout_like");
                }
            }
            if ($test_args{stdout_unlike}) {
                if (ref($test_args{stdout_unlike}) eq 'ARRAY') {
                    for my $re (@{ $test_args{stdout_unlike} }) {
                        unlike($stdout, $re, "stdout_unlike");
                    }
                } else {
                    unlike($stdout, $test_args{stdout_unlike}, "stdout_unlike");
                }
            }
            if ($test_args{stderr_like}) {
                if (ref($test_args{stderr_like}) eq 'ARRAY') {
                    for my $re (@{ $test_args{stderr_like} }) {
                        like($stderr, $re, "stderr_like");
                    }
                } else {
                    like($stderr, $test_args{stderr_like}, "stderr_like");
                }
            }
            if ($test_args{stderr_unlike}) {
                if (ref($test_args{stderr_unlike}) eq 'ARRAY') {
                    for my $re (@{ $test_args{stderr_unlike} }) {
                        unlike($stderr, $re, "stderr_unlike");
                    }
                } else {
                    unlike($stderr, $test_args{stderr_unlike}, "stderr_unlike");
                }
            }
            if ($test_args{posttest}) {
                $test_args{posttest}->($exit_code, $stdout, $stderr);
            }
        }; # subtest
        ($exit_code, $stdout, $stderr);
    }; # test_cli

    my $test_cli_completion = sub {
        my %test_args = @_;

        my $comp_line = delete($test_args{comp_line0});
        my $answer = delete($test_args{comp_answer});

        my $comp_point;
        if (($comp_point = index($comp_line, '^')) >= 0) {
            $comp_line =~ s/\^//;
        } else {
            $comp_point = length($comp_line);
        }

        $test_cli->(
            %test_args,
            tags => [@{$test_args{tags} // []}, 'completion'],
            env => {
                COMP_LINE  => $comp_line,
                COMP_POINT => $comp_point,
            },
            posttest => sub {
                my ($exit_code, $stdout, $stderr) = @_;
                my @answer = split /^/m, $stdout;
                for (@answer) {
                    chomp;
                    s/\\(.)/$1/g;
                }
                if ($answer) {
                    is_deeply(\@answer, $answer, 'answer')
                        or diag explain \@answer;
                }
            },
        );
    };

    for my $group (@{ $args{groups} }) {
        subtest $group->{name} => sub {
            if ($group->{before_all_tests}) {
                $group->{before_all_tests}->($group);
            }
            ok 1, "dummy"; # just to avoid no tests being run if all excluded by tags
            for my $test (@{ $group->{tests} // [] }) {
                if ($group->{before_each_test}) {
                    $group->{before_each_test}->($test);
                }
                my ($exit_code, $stdout, $stderr) = $test_cli->(%$test);
                if ($group->{after_each_test}) {
                    $group->{after_each_test}->($test, $exit_code, $stdout, $stderr);
                }
            }
            for my $test (@{ $group->{completion_tests} // [] }) {
                if ($group->{before_each_test}) {
                    $group->{before_each_test}->($test);
                }
                my ($exit_code, $stdout, $stderr) = $test_cli_completion->(%$test);
                if ($group->{after_each_test}) {
                    $group->{after_each_test}->($test, $exit_code, $stdout, $stderr);
                }
            }
            if ($group->{after_all_tests}) {
                $group->{after_all_tests}->($group);
            }
        } # group subtest
    } # for group

    if ($cleanup_tempdir) {
        if (!Test::More->builder->is_passing) {
            diag "there are failing tests, not deleting tempdir $tempdir";
        } elsif ($ENV{DEBUG}) {
            diag "DEBUG is true, not deleting tempdir $tempdir";
        } else {
            note "all tests successful, deleting tempdir $tempdir";
            remove_tree($tempdir);
        }
    }
}

$SPEC{pericmd_run_ok} = {
    v => 1.1,
    summary => 'Run a single test of a Perinci::CmdLine script',
    args => {
        %common_args,
        %run_args,
    },
};
sub pericmd_run_ok {
    my %args = @_;

    my %rtg_args;

    $rtg_args{class} = delete $args{class};

    {
        my $test = {};
        for my $k (keys %run_args) {
            $test->{$k} = delete $args{$k} if exists $args{$k};
        }
        my $group = {
            name => $test->{name} // 'single test group (pericmd_run_ok)',
        };
        if (defined $args{comp_answer}) {
            $group->{completion_tests} = [$test];
        } else {
            $group->{tests} = [$test];
        }
        $rtg_args{groups} = [$group];
    }

    pericmd_run_test_groups_ok(%rtg_args);
}

$SPEC{pericmd_run_tests_ok} = {
    v => 1.1,
    summary => 'Run a group of tests of a Perinci::CmdLine script',
    args => {
        %common_args,
        name => {
            schema => 'str*',
        },
        tests => {
            schema => ['array*', of=>'hash*'],
            req => 1,
        },
    },
};
sub pericmd_run_tests_ok {
    my %args = @_;

    my %rtg_args;

    $rtg_args{class} = delete $args{class};

    {
        my $group = {
            name => delete($args{name}) // 'single group (pericmd_run_tests_ok)',
        };
        if (grep {$_->{comp_answer}} @{ $args{tests} }) {
            $group->{completion_tests} = delete $args{tests};
        } else {
            $group->{tests} = delete $args{tests};
        }
        $rtg_args{groups} = [$group];
    }

    pericmd_run_test_groups_ok(%rtg_args);
}

$SPEC{pericmd_run_suite_ok} = {
    v => 1.1,
    summary => 'Common test suite for Perinci::CmdLine::{Lite,Classic,Inline}',
    args => {
        %common_args,
    },
};
sub pericmd_run_suite_ok {
    my %suite_args = @_;

    my $tempdir = tempdir();

    require Perinci::Examples::Tiny;

    my $include_tags = $suite_args{include_tags} // do {
        if (defined $ENV{TEST_PERICMD_INCLUDE_TAGS}) {
            [split /,/, $ENV{TEST_PERICMD_INCLUDE_TAGS}];
        } else {
            undef;
        }
    };
    my $exclude_tags = $suite_args{exclude_tags} // do {
        if (defined $ENV{TEST_PERICMD_EXCLUDE_TAGS}) {
            [split /,/, $ENV{TEST_PERICMD_EXCLUDE_TAGS}];
        } else {
            undef;
        }
    };

    # for embedded function+meta tests
    my $code_embed = q!
our %SPEC;
$SPEC{square} = {v=>1.1, args=>{num=>{schema=>'num*', req=>1, pos=>0}}};
sub square { my %args=@_; [200, "OK", $args{num}**2] }
!;

    pericmd_run_test_groups_ok(
        %suite_args,
        include_tags => $include_tags,
        exclude_tags => $exclude_tags,
        tempdir => $tempdir,
        cleanup_tempdir => 1,
        groups => [
            {
                name => 'help action',
                tests => [
                    {
                        gen_args    => {url => '/Perinci/Examples/Tiny/noop'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--help/],
                        exit_code   => 0,
                        stdout_like => qr/^Usage.+^([^\n]*)Options/ims,
                    },
                    {
                        name        => '+ is not accepted as option starter',
                        gen_args    => {url => '/Perinci/Examples/Tiny/noop'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/+h/],
                        exit_code   => 200,
                    },
                    {
                        name        => '+ is not accepted as option starter (2)',
                        gen_args    => {url => '/Perinci/Examples/Tiny/noop'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/+help/],
                        exit_code   => 200,
                    },
                    {
                        name        => 'extra args is okay',
                        gen_args    => {url => '/Perinci/Examples/Tiny/noop'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--help 1 2 3/],
                        exit_code   => 0,
                        stdout_like => qr/^Usage.+^([^\n]*)Options/ims,
                    },
                    {
                        tags        => [qw/subcommand/],
                        name        => 'help for cli with subcommands',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                sc1 => '/Perinci/Examples/Tiny/noop',
                            },
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--help/],
                        exit_code   => 0,
                        stdout_like => qr/^Subcommands.+\bsc1\b/ms,
                    },
                    {
                        tags          => [qw/subcommand/],
                        name          => 'help on a subcommand',
                        gen_args      => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                sc1 => '/Perinci/Examples/Tiny/noop',
                            },
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv          => [qw/sc1 --help/],
                        exit_code     => 0,
                        stdout_like   => qr/Do nothing.+^Usage/ms,
                        stdout_unlike => qr/^Subcommands.+\bsc1\b/ms,
                    },
                ],
            }, # help action

            {
                name => 'version action',
                tests => [
                    {
                        gen_args    => {url => '/Perinci/Examples/Tiny/noop'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--version/],
                        exit_code   => 0,
                        stdout_like => qr/\Q$Perinci::Examples::Tiny::VERSION\E/,
                    },
                ],
            }, # version action

            {
                name => 'subcommands action',
                tests => [

                    # XXX test that if specified, subcommand spec's summary is used
                    # instead of subcommand url's Riap summary.

                    {
                        tags        => ['subcommand'],
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'noop' => '/Perinci/Examples/Tiny/noop',
                                'odd_even' => '/Perinci/Examples/Tiny/odd_even',
                            },
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--subcommands/],
                        exit_code   => 0,
                        stdout_like => qr/noop.+odd_even/ms,
                    },
                    {
                        tags        => ['subcommand'],
                        name        => 'unknown subcommand = error',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'noop' => '/Perinci/Examples/Tiny/noop',
                                'odd_even' => '/Perinci/Examples/Tiny/odd_even',
                            },
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/foo/],
                        exit_code   => 200,
                    },
                    {
                        tags        => ['subcommand'],
                        name        => 'default_subcommand',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'noop' => '/Perinci/Examples/Tiny/noop',
                                'odd_even' => '/Perinci/Examples/Tiny/odd_even',
                            },
                            default_subcommand=>'noop',
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw//],
                        exit_code   => 0,
                        stdout_like => qr/^$/, # no-op
                    },
                    {
                        tags        => ['subcommand'],
                        name        => 'default_subcommand 2',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'noop' => '/Perinci/Examples/Tiny/noop',
                                'odd_even' => '/Perinci/Examples/Tiny/odd_even',
                            },
                            default_subcommand=>'odd_even',
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw//],
                        exit_code   => 100, # missing required argument: number
                    },

                ],
            }, # subcommands action

            {
                name => 'call action',
                tests => [
                    {
                        tags           => ['embedded-meta'],
                        name           => 'embedded function+meta works',
                        gen_args       => {
                            url => '/main/square',
                            code_before_instantiate_cmdline => $code_embed,
                        },
                        argv           => [qw/12/],
                        exit_code      => 0,
                        stdout_like    => qr/^144$/,
                    },
                    {
                        name           => 'extra args not allowed',
                        gen_args       => {url => '/Perinci/Examples/Tiny/noop'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv           => [qw/1/],
                        exit_code      => 200,
                    },
                    {
                        name           => 'missing required args -> error',
                        gen_args       => {url => '/Perinci/Examples/Tiny/odd_even'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv           => [qw//],
                        exit_code      => 100,
                    },
                    {
                        name           => 'common option: --format',
                        gen_args       => {url => '/Perinci/Examples/Tiny/Args/as_is'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny::Args']},
                        argv           => [qw/--arg abc --format json/],
                        exit_code      => 0,
                        stdout_like    => qr/^\[\s*"?200"?,\s*"OK",\s*"abc",\s*\{.*\}\s*\]/s,
                    },
                    {
                        name           => 'common option: --json',
                        gen_args       => {url => '/Perinci/Examples/Tiny/Args/as_is'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny::Args']},
                        argv           => [qw/--arg abc --json/],
                        exit_code      => 0,
                        stdout_like    => qr/^\[\s*"?200"?,\s*"OK",\s*"abc",\s*\{.*\}\s*\]/s,
                    },
                    {
                        name           => 'common option: --naked-res',
                        gen_args       => {url => '/Perinci/Examples/Tiny/Args/as_is'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny::Args']},
                        argv           => [qw/--arg abc --json --naked-res/],
                        exit_code      => 0,
                        stdout_like    => qr/^"abc"$/s,
                    },
                    {
                        name           => 'common option: --no-naked-res',
                        gen_args       => {url => '/Perinci/Examples/Tiny/Args/as_is'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny::Args']},
                        argv           => [qw/--arg abc --json --no-naked-res/],
                        exit_code      => 0,
                        stdout_like    => qr/^\[\s*"?200"?,\s*"OK",\s*"abc",\s*\{.*\}\s*\]/s,
                    },
                    {
                        tags           => ['subcommand'],
                        name           => 'common option: --cmd',
                        gen_args       => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'noop' => '/Perinci/Examples/Tiny/noop',
                                'odd_even' => '/Perinci/Examples/Tiny/odd_even',
                            },
                            default_subcommand=>'noop',
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv           => [qw/--cmd odd_even 5/],
                        exit_code      => 0,
                        stdout_like    => qr/^odd$/s,
                    },

                    {
                        name           => 'json argument',
                        gen_args       => {url => '/Perinci/Examples/Tiny/Args/as_is'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny::Args']},
                        argv           => ['--arg-json', '["a","b"]', '--json'],
                        exit_code      => 0,
                        stdout_like    => qr/^\[\s*"?200"?,\s*"OK",\s*\[\s*"a",\s*"b"\s*\],\s*\{.*\}\s*\]/s,
                    },

                    {
                        name           => 'can handle function which returns naked result',
                        gen_args       => {url => '/Perinci/Examples/Tiny/hello_naked'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv           => [],
                        exit_code      => 0,
                        stdout_like    => qr/Hello, world/,
                    },
                ],
            }, # call action

            {
                name => 'cmdline_src (error cases)',
                tests => [
                    {
                        tags       => ['cmdline_src'],
                        name       => 'unknown value',
                        gen_args   => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_unknown"},
                        inline_gen_args => {load_module=>["Perinci::Examples::CmdLineSrc"]},
                        argv       => [],
                        exit_code  => 231,
                    },
                    {
                        tags       => ['cmdline_src'],
                        name       => 'arg type not str/array',
                        gen_args   => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_invalid_arg_type"},
                        inline_gen_args => {load_module=>["Perinci::Examples::CmdLineSrc"]},
                        argv       => [],
                        exit_code  => 231,
                    },
                    {
                        tags       => ['cmdline_src', 'cmdline_src:stdin'],
                        name       => 'multiple stdin',
                        gen_args   => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_multi_stdin"},
                        inline_gen_args => {load_module=>["Perinci::Examples::CmdLineSrc"]},
                        argv       => [qw/a b/],
                        exit_code  => 200,
                    },
                ],
            }, # cmdline_src (error cases)

            {
                name => 'cmdline_src (file)',
                before_all_tests => sub {
                    write_text("$tempdir/infile1", "foo");
                    write_text("$tempdir/infile2", "bar\nbaz");
                },
                tests => [
                    {
                        tags        => ['cmdline_src', 'cmdline_src:file'],
                        name        => 'file 1',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_file"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--a1', "$tempdir/infile1"],
                        stdout_like => qr/a1=foo/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:file'],
                        name        => 'file 1 (special hint arguments passed)',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_file"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--json', '--a1', "$tempdir/infile1"],
                        stdout_like => [
                            qr/"-cmdline_src_a1"\s*:\s*"file"/sx,
                            qr/"-cmdline_srcfilenames_a1"\s*:\s*\[/sx,
                        ],
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:file'],
                        name        => 'file 2',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_file"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--a1', "$tempdir/infile1", '--a2', "$tempdir/infile2"],
                        stdout_like => qr/a1=foo\na2=\[bar\n,baz\]/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:file'],
                        name        => 'file 2 (special hint arguments passed)',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_file"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--json', '--a1', "$tempdir/infile1", '--a2', "$tempdir/infile2"],
                        stdout_like => [
                            qr/"-cmdline_src_a1"\s*:\s*"file"/sx,
                            qr/"-cmdline_src_a2"\s*:\s*"file"/sx,
                            qr/"-cmdline_srcfilenames_a1"\s*:\s*\[/sx,
                            qr/"-cmdline_srcfilenames_a2"\s*:\s*\[/sx,
                        ],
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:file'],
                        name        => 'file not found',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_file"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--a1', "$tempdir/infile1/x"],
                        exit_code   => 200,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:file'],
                        name        => 'file, missing required arg',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_file"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--a2', "$tempdir/infile2"],
                        exit_code   => 100,
                    },
                ],
            }, # cmdline_src (file)

            {
                name => 'cmdline_src (stdin)',
                tests => [
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin'],
                        name        => 'stdin str',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => [],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/a1=bar\nbaz/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin'],
                        name        => 'stdin str (special hint arguments passed)',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--json'],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/
                                             "-cmdline_src_a1"\s*:\s*"stdin"
                                         /sx,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin'],
                        name        => 'stdin array',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_array"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => [],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/a1=\[bar\n,baz\]/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin'],
                        name        => 'stdin + arg set to "-"',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => [qw/--a1 -/],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/a1=bar\nbaz/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin'],
                        name        => 'stdin + arg set to non "-"',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => [qw/--a1 x/],
                        stdin       => "bar\nbaz",
                        exit_code   => 100,
                    },
                ],
            }, # cmdline_src (stdin)

            {
                name => 'cmdline_src (stdin_line)',
                tests => [
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_line'],
                        name        => 'stdin_line + from stdin',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_line"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--a2', 'bar'],
                        stdin       => "foo\n",
                        stdout_like => qr/a1=foo\na2=bar/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_line'],
                        name        => 'stdin_line + from stdin (special hint arguments passed)',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_line"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--json', '--a2', 'bar'],
                        stdin       => "foo\n",
                        stdout_like => qr/"-cmdline_src_a1"\s*:\s*"stdin_line"/sx,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_line'],
                        name        => 'stdin_line + from cmdline',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_line"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--a2', 'bar', '--a1', 'qux'],
                        stdout_like => qr/a1=qux\na2=bar/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_line'],
                        name        => 'multi stdin_line',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_multi_stdin_line"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--a3', 'baz'],
                        stdin       => "foo\nbar\n",
                        stdout_like => qr/a1=foo\na2=bar\na3=baz/,
                    },
                ],
            }, # cmdline_src (stdin_line)

            {
                name => 'cmdline_src (stdin_or_file)',
                before_all_tests => sub {
                    write_text("$tempdir/infile1", "foo");
                    write_text("$tempdir/infile2", "bar\nbaz");
                },
                tests => [
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_file'],
                        name        => 'stdin_or_file file',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_file_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ["$tempdir/infile1"],
                        stdout_like => qr/a1=foo$/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_file'],
                        name        => 'stdin_or_file file (extra argument)',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_file_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ["$tempdir/infile1", "$tempdir/infile1"],
                        stdout_like => qr/a1=foo$/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_file'],
                        name        => 'stdin_or_file file (special hint arguments passed)',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_file_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--json', "$tempdir/infile1"],
                        stdout_like => [
                            qr/"-cmdline_src_a1"\s*:\s*"stdin_or_file"/sx,
                            qr/"-cmdline_srcfilenames_a1"\s*:\s*\[/sx,
                        ],
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_file'],
                        name        => 'stdin_or_files file not found',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_file_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ["$tempdir/infile1/x"],
                        exit_code   => 200,
                    },

                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_file'],
                        name        => 'stdin_or_file stdin str',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_file_str"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => [],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/a1=bar\nbaz$/,
                        # TODO test special hint arguments passed
                    },

                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_file'],
                        name        => 'stdin_or_file stdin str',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_file_array"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => [],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/a1=\[bar\n,baz\]/,
                        # TODO test special hint arguments passed
                    },
                ],
            }, # cmdline_src (stdin_or_file)

            {
                name => 'cmdline_src (stdin_or_files)',
                before_all_tests => sub {
                    write_text("$tempdir/infile1", "foo");
                    write_text("$tempdir/infile2", "bar\nbaz");
                },
                tests => [
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_files'],
                        name        => 'stdin_or_files file',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_files_array"},
                        inline_gen_args => {load_module=>["Perinci::Examples::CmdLineSrc"]},
                        argv        => ["$tempdir/infile1", "$tempdir/infile2"],
                        stdout_like => qr/a1=\[foo,bar\n,baz\]$/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_files'],
                        name        => 'stdin_or_files file (special hint arguments passed)',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_files_str"},
                        inline_gen_args => {load_module=>["Perinci::Examples::CmdLineSrc"]},
                        argv        => ['--json', "$tempdir/infile1"],
                        stdout_like => [
                            qr/"-cmdline_src_a1"\s*:\s*"stdin_or_files"/sx,
                            qr/"-cmdline_srcfilenames_a1"\s*:\s*\[/sx,
                        ],
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_files'],
                        name        => 'stdin_or_files file not found',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_files_str"},
                        inline_gen_args => {load_module=>["Perinci::Examples::CmdLineSrc"]},
                        argv        => ["$tempdir/infile1/x"],
                        exit_code   => 200,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_files'],
                        name        => 'stdin_or_files stdin str',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_files_str"},
                        inline_gen_args => {load_module=>["Perinci::Examples::CmdLineSrc"]},
                        argv        => [],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/a1=bar\nbaz$/,
                        # TODO test special hint arguments passed
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_files'],
                        name        => 'stdin_or_files stdin str',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_files_array"},
                        inline_gen_args => {load_module=>["Perinci::Examples::CmdLineSrc"]},
                        argv        => [],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/a1=\[bar\n,baz\]/,
                        # TODO test special hint arguments passed
                    },
                ],
            }, # cmdline_src (stdin_or_files)

            {
                name => 'cmdline_src (stdin_or_args)',
                before_all_tests => sub {
                },
                tests => [
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_args'],
                        name        => 'from arg',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_args_array"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => ['--a1', "x"],
                        stdout_like => qr/a1=\[x\]/,
                    },
                    {
                        tags        => ['cmdline_src', 'cmdline_src:stdin_or_args'],
                        name        => 'from stdin',
                        gen_args    => {url=>"/Perinci/Examples/CmdLineSrc/cmdline_src_stdin_or_args_array"},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineSrc']},
                        argv        => [],
                        stdin       => "bar\nbaz",
                        stdout_like => qr/a1=\[bar,baz\]/,
                    },
                ],
            }, # cmdline_src (stdin_or_args)

            {
                name => 'dry-run',
                tests => [
                    {
                        tags        => ['dry-run'],
                        name        => 'dry-run (via env, 0)',
                        gen_args    => {url=>'/Perinci/Examples/test_dry_run'},
                        #inline_gen_args => {...},
                        env         => {DRY_RUN=>0},
                        argv        => [],
                        stdout_like => qr/wet/,
                    },
                    {
                        tags        => ['dry-run'],
                        name        => 'dry-run (via env, 1)',
                        gen_args    => {url=>'/Perinci/Examples/test_dry_run'},
                        #inline_gen_args => {...},
                        env         => {DRY_RUN=>1},
                        argv        => [qw//],
                        stdout_like => qr/dry/,
                    },
                    {
                        tags        => ['dry-run'],
                        name        => 'dry-run (via cmdline opt)',
                        gen_args    => {url=>'/Perinci/Examples/test_dry_run'},
                        #inline_gen_args => {...},
                        argv        => [qw/--dry-run/],
                        stdout_like => qr/dry/,
                    },
                ],
            }, # dry-run

            {
                name => 'tx',
                tests => [
                    {
                        tags        => ['tx', 'dry-run'],
                        name        => 'dry_run (using tx) (w/o)',
                        gen_args    => {url=>'/Perinci/Examples/Tx/check_state'},
                        argv        => [],
                        stdout_like => qr/^$/,
                    },
                    {
                        tags        => ['tx', 'dry-run'],
                        name        => 'dry_run (using tx) (w/)',
                        gen_args    => {url=>'/Perinci/Examples/Tx/check_state'},
                        argv        => [qw/--dry-run/],
                        stdout_like => qr/check_state/,
                    },
                ],
            }, # tx

            {
                name => 'streaming',
                before_all_tests => sub {
                    write_text("$tempdir/infile-str", "one\ntwo three\nfour\n");
                    write_text("$tempdir/infile-hash-json", qq({}\n{"a":1}\n{"b":2,"c":3}\n{"d":4}\n));
                    write_text("$tempdir/infile-invalid-json", qq({}\n{\n));
                    write_text("$tempdir/infile-int", qq(1\n3\n5\n));
                    write_text("$tempdir/infile-invalid-int", qq(1\nx\n5\n));
                    write_text("$tempdir/infile-words", qq(word1\nword2\n));
                    write_text("$tempdir/infile-invalid-words", qq(word1\nword2\nnot a word\n));
                },
                tests => [
                    # streaming input
                    {
                        tags        => ['streaming', 'streaming-input'],
                        name        => "stream input, simple type, chomp on",
                        gen_args    => {url => '/Perinci/Examples/Stream/count_lines'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-str"],
                        stdout_like => qr/
                                             3
                                         /mx,
                    },
                    {
                        tags        => ['streaming', 'streaming-input'],
                        name        => "stream input, simple type, chomp off",
                        gen_args    => {url => '/Perinci/Examples/Stream/wc'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-str"],
                        stdout_like => qr/
                                             ^chars \s+ 19\n
                                             ^lines \s+ 3\n
                                             ^words \s+ 4\n
                                         /mx,
                    },
                    {
                        tags        => ['streaming', 'streaming-input'],
                        name        => "stream input, json stream",
                        gen_args    => {url => '/Perinci/Examples/Stream/wc_keys'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-hash-json"],
                        stdout_like => qr/^keys \s+ 4\n/mx,
                    },

                    {
                        tags        => ['streaming', 'streaming-input', 'validate-streaming-input'],
                        name        => 'stream input, simple type, word validation', # also test that each record is chomp-ed
                        gen_args    => {url => '/Perinci/Examples/Stream/count_words'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-words"],
                        stdout_like => qr/2/,
                    },
                    {
                        tags        => ['streaming', 'streaming-input', 'validate-streaming-input'],
                        name        => 'stream input, simple types, word validation, error',
                        gen_args    => {url => '/Perinci/Examples/Stream/count_words'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-invalid-words"],
                        exit_code_like => qr/[1-9]/,
                        stdout_like => qr/fails validation/,
                    },
                    {
                        tags        => ['streaming', 'streaming-input', 'validate-streaming-input'],
                        name        => 'stream input, simple types, word validation, error',
                        gen_args    => {url => '/Perinci/Examples/Stream/count_words'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-invalid-words"],
                        exit_code_like => qr/[1-9]/,
                        stdout_like => qr/fails validation/,
                    },
                    {
                        tags        => ['streaming', 'streaming-input', 'validate-streaming-input'],
                        name        => 'stream input, json stream, error',
                        gen_args    => {url => '/Perinci/Examples/Stream/wc_keys'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-invalid-json"],
                        exit_code => 200,
                    },

                    # streaming result
                    {
                        tags        => ['streaming', 'streaming-result', 'validate-streaming-result'],
                        name        => "stream result, simple types, word validation",
                        gen_args    => {url => '/Perinci/Examples/Stream/produce_words_err'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["-n", 9],
                    },
                    {
                        tags        => ['streaming', 'streaming-result', 'validate-streaming-result'],
                        name        => "stream result, simple types, word validation, error",
                        gen_args    => {url => '/Perinci/Examples/Stream/produce_words_err'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["-n", 10],
                        exit_code_like => qr/[1-9]/,
                        stderr_like => qr/fails validation/,
                    },
                    {
                        tags        => ['streaming', 'streaming-result'],
                        name        => "stream result, json stream",
                        gen_args    => {url => '/Perinci/Examples/Stream/produce_hashes'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => [qw/-n 3/],
                        stdout_like => qr/
                                             ^\Q{"num":1}\E\n
                                             ^\Q{"num":2}\E\n
                                             ^\Q{"num":3}\E\n
                                         /mx,
                    },

                    # streaming input+result
                    {
                        tags        => ['streaming', 'streaming-input', 'streaming-result'],
                        name        => "stream input+result, simple type, float validation",
                        gen_args    => {url => '/Perinci/Examples/Stream/square_nums'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-int"],
                        stdout_like => qr/
                                             ^"?1"?\n
                                             ^"?9"?\n
                                             ^"?25"?\n
                                         /mx,
                    },
                    {
                        tags        => ['streaming', 'streaming-input', 'streaming-result', 'validate-streaming-input'],
                        name        => "stream input+result, simple type, float validation, error",
                        gen_args    => {url => '/Perinci/Examples/Stream/square_nums'},
                        inline_gen_args => {load_module=>["Perinci::Examples::Stream"]},
                        argv        => ["$tempdir/infile-invalid-int"],
                        exit_code_like => qr/[1-9]/, # sometimes it's 9, sometimes it's 25; looks like the input line is being used somehow as exit code?
                        stderr_like => qr/fails validation/,
                    },
                ],
            }, # streaming

            {
                name => 'result metadata',
                tests => [
                    {
                        name        => 'cmdline.exit_code',
                        gen_args    => {url=>'/Perinci/Examples/CmdLineResMeta/exit_code'},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineResMeta']},
                        argv        => [qw//],
                        exit_code   => 7,
                    },
                    {
                        name        => 'cmdline.result',
                        gen_args    => {url=>'/Perinci/Examples/CmdLineResMeta/result'},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineResMeta']},
                        argv        => [qw//],
                        stdout_like => qr/false/,
                    },
                    {
                        name        => 'cmdline.default_format',
                        gen_args    => {url=>'/Perinci/Examples/CmdLineResMeta/default_format'},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineResMeta']},
                        argv        => [qw//],
                        stdout_like => qr/null/,
                    },
                    {
                        name        => 'cmdline.default_format (overriden by cmdline opt)',
                        gen_args    => {url=>'/Perinci/Examples/CmdLineResMeta/default_format'},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineResMeta']},
                        argv        => [qw/--format text/],
                        stdout_like => qr/\A\z/,
                    },
                    {
                        name        => 'cmdline.skip_format',
                        gen_args    => {url=>'/Perinci/Examples/CmdLineResMeta/skip_format'},
                        inline_gen_args => {load_module=>['Perinci::Examples::CmdLineResMeta']},
                        argv        => [qw//],
                        stdout_like => qr/ARRAY\(0x/,
                    },
                ],
            }, # result metadata

            {
                name => 'completion',
                completion_tests => [
                    {
                        name           => 'self-completion works',
                        gen_args       => {url => '/Perinci/Examples/Tiny/odd_even'},
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv           => [],
                        comp_line0     => 'cmd --nu^',
                        comp_answer    => ['--number'],
                    },
                    {
                        tags           => ['subcommand'],
                        name           => 'completion of subcommand name',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'sc1' => '/Perinci/Examples/Tiny/noop',
                                'sc2' => '/Perinci/Examples/Tiny/odd_even',
                            },
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv           => [],
                        comp_line0     => 'cmd sc^',
                        comp_answer    => ['sc1', 'sc2'],
                    },
                    {
                        tags           => ['subcommand'],
                        name           => 'completion of subcommand option',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'sc1' => '/Perinci/Examples/Tiny/noop',
                                'sc2' => '/Perinci/Examples/Tiny/odd_even',
                            },
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv           => [],
                        comp_line0     => 'cmd sc2 --nu^',
                        comp_answer    => ['--number'],
                    },
                ],
            }, # completion

            {
                name => 'env',
                tests => [
                    {
                        tags        => ['env'],
                        name        => 'env read',
                        env         => {
                            SUM_NUMS_OPT => '1 2',
                        },
                        gen_args    => {
                            read_env => 1,
                            script_name => 'sum-nums',
                            url => '/Perinci/Examples/Tiny/sum',
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/3/],
                        exit_code   => 0,
                        stdout_like => qr/^6$/s,
                    },
                    {
                        tags        => ['env'],
                        name        => 'default env name prefixed by _ if script name starts with number',
                        env         => {
                            _0SUM_NUMS_OPT => '1 2',
                        },
                        gen_args    => {
                            read_env => 1,
                            script_name => '0sum-nums',
                            url => '/Perinci/Examples/Tiny/sum',
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/3/],
                        exit_code   => 0,
                        stdout_like => qr/^6$/s,
                    },
                    {
                        tags        => ['env'],
                        name        => 'turned off via --no-env',
                        env         => {
                            SUM_NUMS_OPT => '1 2',
                        },
                        gen_args    => {
                            read_env => 1,
                            script_name => 'sum-nums',
                            url => '/Perinci/Examples/Tiny/sum',
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--no-env 3/],
                        exit_code   => 0,
                        stdout_like => qr/^3$/s,
                    },
                    {
                        tags        => ['env'],
                        name        => 'attr:env_name',
                        env         => {
                            SUM_NUMS_OPT => '1 2',
                            foo_opt => '7 8',
                        },
                        gen_args    => {
                            read_env => 1,
                            script_name => 'sum-nums',
                            env_name => 'foo_opt',
                            url => '/Perinci/Examples/Tiny/sum',
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/3/],
                        exit_code   => 0,
                        stdout_like => qr/^18$/s,
                    },
                ],
            }, # env

            {
                name => 'config file',
                before_all_tests => sub {
                    write_text("$tempdir/prog.conf", <<'_');
a=101
b=201
[subcommand=subcommand1]
a=102
c=201
[subcommand=subcommand2]
a=103
[profile=profile1]
a=111
d=201
[subcommand=subcommand1 profile=profile1]
a=121
_
                    write_text("$tempdir/prog2.conf", <<'_');
a=104
_
                    write_text("$tempdir/sum.conf", <<'_');
array=0
_
                    write_text("$tempdir/prog3.conf", <<'_');
format=json
naked_res=1
a.arg=101
_
                    write_text("$tempdir/prog4.conf", <<'_');
a=300
b=301
[prog]
a=302
b=303
[prog2]
a=304
b=305
[prog profile=profile1]
a=306
b=307
_
                },
                tests => [
                    {
                        tags        => ['config-file'],
                        name        => 'attr:config_dirs',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog',
                            read_config => 1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [],
                        stdout_like => qr/^a=101\nb=201\nc=\nd=\ne=$/,
                    },
                    {
                        tags        => ['config-file'],
                        name        => 'attr:config_filename',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog',
                            read_config => 1,
                            config_dirs => [$tempdir],
                            config_filename => 'prog2.conf',
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [],
                        stdout_like => qr/^a=104\nb=\nc=\nd=\ne=$/,
                    },
                    {
                        tags        => ['config-file'],
                        name        => 'attr:config_filename (hash record)',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog',
                            read_config => 1,
                            config_dirs => [$tempdir],
                            config_filename => [{filename=>'prog4.conf', section=>'prog'}, 'prog2.conf'],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [],
                        stdout_like => qr/^a=104\nb=303\nc=\nd=\ne=$/,
                    },
                    {
                        tags        => ['config-file'],
                        name        => 'attr:config_filename (hash record) + --config-profile',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog',
                            read_config => 1,
                            config_dirs => [$tempdir],
                            config_filename => [{filename=>'prog4.conf', section=>'prog'}, 'prog2.conf'],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--config-profile profile1/],
                        stdout_like => qr/^a=104\nb=307\nc=\nd=\ne=$/,
                    },
                    {
                        tags        => ['config-file'],
                        name        => 'common option: --no-config',
                        gen_args => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog',
                            read_config =>1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--no-config/],
                        stdout_like => qr/^a=\nb=\nc=\nd=\ne=$/,
                    },
                    {
                        tags        => ['config-file'],
                        name        => 'common option: --config-path',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog',
                            read_config =>1,
                            #config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => ['--config-path', "$tempdir/prog.conf"],
                        stdout_like => qr/^a=101\nb=201\nc=\nd=\ne=$/,
                    },
                    {
                        tags        => ['config-file'],
                        name        => 'common option: --config-profile',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog',
                            read_config =>1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--config-profile=profile1/],
                        stdout_like => qr/a=111\nb=201\nc=\nd=201\ne=$/,
                    },
                    {
                        tags        => ['config-file'],
                        name        => 'unknown config profile -> error',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog',
                            read_config =>1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--config-profile=foo/],
                        exit_code   => 112,
                    },
                    {
                        tags        => ['config-file'],
                        name => 'unknown config profile but does not read config -> ok',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'foo',
                            read_config =>1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--config-profile=bar/],
                        stdout_like => qr/^a=\nb=\nc=\nd=\ne=$/,
                    },
                    # disabled for now, because Perinci::CmdLine::Generate doesn't
                    # yet provide a way to pass the hook
                    #{
                    #    name => 'unknown config profile but set ignore_missing_config_profile_section -> ok',
                    #    hook_before_read_config_file => sub {
                    #        my ($self, $r) = @_;
                    #        $r->{ignore_missing_config_profile_section} = 1;
                    #    },
                    #    gen_args => {...},
                    #    inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                    #argv => [qw/--config-profile=bar/],
                    #stdout_like => qr/^a=101\nb=201\nc=\nd=\ne=$/,
                    #}
                    {
                        tags        => ['config-file', 'subcommand'],
                        name        => 'subcommand',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'subcommand1' => '/Perinci/Examples/Tiny/noop2',
                            },
                            script_name => 'prog',
                            read_config =>1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/subcommand1/],
                        stdout_like => qr/^a=102\nb=201\nc=201\nd=\ne=$/,
                    },

                    {
                        tags        => ['config-file', 'subcommand'],
                        name        => 'subcommand + --config-profile',
                        gen_args => {
                            url => '/Perinci/Examples/Tiny/',
                            subcommands => {
                                'subcommand1' => '/Perinci/Examples/Tiny/noop2',
                            },
                            script_name => 'prog',
                            read_config => 1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw/--config-profile=profile1 subcommand1/],
                        stdout_like => qr/^a=121\nb=201\nc=201\nd=201\ne=$/,
                    },
                    {
                        tags        => ['config-file'],
                        name        => 'array-ify if argument is array',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/sum',
                            script_name => 'sum',
                            read_config => 1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [qw//],
                        stdout_like => qr/^0$/,
                    },

                    # TODO array-ify common option

                    {
                        tags        => ['config-file', 'config-file-sets-common-options'],
                        name        => 'can also set common option',
                        gen_args    => {
                            url => '/Perinci/Examples/Tiny/noop2',
                            script_name => 'prog3',
                            read_config => 1,
                            config_dirs => [$tempdir],
                        },
                        inline_gen_args => {load_module=>['Perinci::Examples::Tiny']},
                        argv        => [],
                        stdout_like => qr/^"a=101\\nb=\\nc=\\nd=\\ne="/,
                    },
                ],
            }, # config file

            # TODO: test logging

        ] # groups
    );
}

# old, back-compat name
*pericmd_ok = \&pericmd_run_suite_ok;

1;
# ABSTRACT: Common test suite for Perinci::CmdLine::{Lite,Classic,Inline}

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Perinci::CmdLine - Common test suite for Perinci::CmdLine::{Lite,Classic,Inline}

=head1 VERSION

This document describes version 1.47 of Test::Perinci::CmdLine (from Perl distribution Test-Perinci-CmdLine), released on 2017-01-12.

=for Pod::Coverage ^(pericmd_ok)$

=head1 FUNCTIONS


=head2 pericmd_run_ok(%args) -> [status, msg, result, meta]

Run a single test of a Perinci::CmdLine script.

This function is exported by default.

Arguments ('*' denotes required arguments):

=over 4

=item * B<argv> => I<array> (default: [])

Command-line arguments that will be passed to generated CLI script.

=item * B<class>* => I<str>

Which Perinci::CmdLine class are we testing.

=item * B<classic_gen_args> => I<hash>

Additional arguments to be passed to `Perinci::CmdLine::Gen::gen_pericmd_script()`.

Keys from this argument will be added to C<gen_args> and will only be used when
C<class> is C<Perinci::CmdLine::Classic>.

=item * B<comp_answer> => I<array[str]>

Test completion answer of generated CLI script.

=item * B<comp_line0> => I<str>

Set COMP_LINE environment for generated CLI script.

Can contain C<^> (caret) character which will be stripped from the final
C<COMP_LINE> and the position of the character will be used to determine
C<COMP_POINT>.

=item * B<env> => I<hash>

Set environment variables for generated CLI script.

=item * B<exit_code> => I<int> (default: 0)

Expected script's exit code.

=item * B<exit_code_like> => I<re> (default: 0)

Expected script's exit code (as regex pattern).

=item * B<gen_args>* => I<hash>

Arguments to be passed to `Perinci::CmdLine::Gen::gen_pericmd_script()`.

=item * B<gen_status> => I<int> (default: 200)

Expected generate result status.

=item * B<inline_allow> => I<array[perl::modname]>

Modules to allow to be loaded when testing generated Perinci::CmdLine::Inline script.

By default, when running the generated Perinci::CmdLine::Inline script, this
perl option will be used (see L<lib::filter> for more details):

 -Mlib::filter=allow_noncore,0

This means the script will only be able to load core modules. But if the script
is allowed to load additional modules, you can set this C<inline_allow> parameter
to, e.g. C<["Foo::Bar","Baz"]> and the above perl option will become:

 -Mlib::filter=allow_noncore,0,allow,Foo::Bar;Baz

To skip using this option, set C<inline_run_filter> to false.

=item * B<inline_gen_args> => I<hash>

Additional arguments to be passed to `Perinci::CmdLine::Gen::gen_pericmd_script()`.

Keys from this argument will be added to C<gen_args> and will only be used when
C<class> is C<Perinci::CmdLine::Inline>.

=item * B<inline_run_filter> => I<bool> (default: 1)

Whether to use -Mfilter when running generated Perinci::CmdLine::Inline script.

By default, when running the generated Perinci::CmdLine::Inline script, this
perl option will be used (see L<lib::filter> for more details):

 -Mlib::filter=allow_noncore,0,...

This is to test that the script does not require non-core modules. To skip using
this option (e.g. when using C<pack_deps> gen option set to false), set
this option to false.

=item * B<lite_gen_args> => I<hash>

Additional arguments to be passed to `Perinci::CmdLine::Gen::gen_pericmd_script()`.

Keys from this argument will be added to C<gen_args> and will only be used when
C<class> is C<Perinci::CmdLine::Lite>.

=item * B<name> => I<str>

Test name.

If not specified, a nice default will be picked (e.g. from C<argv>).

=item * B<posttest> => I<code>

Additional tests.

For example you can do C<is()> or C<ok()> or other L<Test::More> tests.

=item * B<stderr_like> => I<re>

Test error output of generated CLI script.

=item * B<stderr_unlike> => I<re>

Test error output of generated CLI script.

=item * B<stdin> => I<str>

Supply stdin content to generated CLI script.

=item * B<stdout_like> => I<re>

Test output of generated CLI script.

=item * B<stdout_unlike> => I<re>

Test output of generated CLI script.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pericmd_run_suite_ok(%args) -> [status, msg, result, meta]

Common test suite for Perinci::CmdLine::{Lite,Classic,Inline}.

This function is exported by default.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class>* => I<str>

Which Perinci::CmdLine class are we testing.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pericmd_run_test_groups_ok(%args) -> [status, msg, result, meta]

Run groups of Perinci::CmdLine tests.

This function is exported by default.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class>* => I<str>

Which Perinci::CmdLine class are we testing.

=item * B<cleanup_tempdir> => I<bool>

=item * B<exclude_tags> => I<array[str]>

=item * B<groups>* => I<array>

=item * B<include_tags> => I<array[str]>

=item * B<tempdir> => I<str>

If not specified, will create temporary directory with C<File::Temp>'s
C<tempdir()>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pericmd_run_tests_ok(%args) -> [status, msg, result, meta]

Run a group of tests of a Perinci::CmdLine script.

This function is exported by default.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class>* => I<str>

Which Perinci::CmdLine class are we testing.

=item * B<name> => I<str>

=item * B<tests>* => I<array[hash]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 DEBUG => bool

If set to 1, then temporary files (e.g. generated scripts for testing) will not
be cleaned up, so you can inspect them.

=head2 TEST_PERICMD_EXCLUDE_TAGS => str

To set default for C<pericmd_ok()>'s C<exclude_tags> argument.

=head2 TEST_PERICMD_INCLUDE_TAGS => str

To set default for C<pericmd_ok()>'s C<include_tags> argument.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-Perinci-CmdLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-Perinci-CmdLine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Perinci-CmdLine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Supported Perinci::CmdLine backends: L<Perinci::CmdLine::Inline>,
L<Perinci::CmdLine::Lite>, L<Perinci::CmdLine::Classic>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
