#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::exit = sub (;$) {
        die sprintf "exit(%s) called\n", (shift||'');
    };
    *CORE::GLOBAL::localtime = sub { CORE::localtime(@_) };
}

use Cwd 'abs_path', 'cwd';
use Data::Dumper;
use Test::Smoke::App::AppOption;
$Test::Smoke::LogMixin::USE_TIMESTAMP = 0;

{
    create_config(
        'smokeme_config',
        mybin2 => '/usr/bin/mybin2',
        v      => 1,
        ping   => 'pang',
        noway  => 'right',
    );
    local @ARGV = ('-v=2', '--test1', 'app2', '-c', 'smokeme');
    my $app = Test::Smoke::App::Test1->new(
        main_options => [
            Test::Smoke::App::AppOption->new(
                name => 'test1',
                option => '=s',
                allow => [qw/app1 app2 Module::App3/],
                helptext => 'Test types.',
            ),
            Test::Smoke::App::AppOption->new(
                name => 'ping',
                option => '=s',
                default => 'pong',
                allow => ['pong', 'pang'],
            ),
        ],
        special_options => {
            app1 => [
                Test::Smoke::App::AppOption->new(name => '1gogo'),
                Test::Smoke::App::AppOption->new(
                    name    => 'mybin2',
                    option  => '=s',
                    default => '/usr/local/bin/mybin2',
                ),
            ],
            app2 => [
                Test::Smoke::App::AppOption->new(
                    name    => '2gogo',
                    option  => '!',
                    default => 1,
                ),
                Test::Smoke::App::AppOption->new(
                    name    => 'mybin2',
                    option  => '=s',
                    default => '/usr/local/bin/mybin2',
                ),
            ],
        },
    );
    isa_ok($app, 'Test::Smoke::App::Base');
    isa_ok($app, 'Test::Smoke::App::Test1');

    is($app->option('verbose'), 2, "verbose level 2");
    is($app->option('test1'), 'app2', "self-type ok");
    is($app->option('2gogo'), 1, "default option for app2");
    is($app->option('configfile'), abs_path('smokeme_config'), "Configuration file");
    is(
        $app->option('mybin2'),
        '/usr/bin/mybin2',
        "cfgfile overrides default"
    );

    eval { $app->option('invalid') };
    like(
        $@,
        qr/Invalid option 'invalid'/,
        "We know about invalid options"
    );
    eval { $app->option('1gogo') };
    like(
        $@,
        qr/Option '1gogo' is not valid/,
        "We know about special invalid options"
    );

    is_deeply(
        {$app->options},
        {
            configfile  => abs_path('smokeme_config'),
            verbose     => 2,
            test1       => 'app2',
            mybin2      => '/usr/bin/mybin2',
            '2gogo'     => 1,
            ping        => 'pang',
        },
        "Getting relevant options"
    );

    # Test the logging
    no warnings 'redefine';
    local *CORE::GLOBAL::localtime = sub {
        return (2, 11, 14, 15, 3, 115, 3, 104, 1);
    };
    {
        open my $log, '>', \my $logfile;
        my $stdout = select $log;
        $app->run1("no newline %s", 'single value');
        select $stdout;
        is($logfile, <<'        EOL', "log_info() no newline");
no newline single value
        EOL
    }
    {
        open my $log, '>', \my $logfile;
        my $stdout = select $log;
        $app->run1("With newline %s\n\n", 'single value');
        select $stdout;
        is($logfile, <<'        EOL', "log_info() 2newline");
With newline single value
        EOL
    }
    {
        open my $log, '>', \my $logfile;
        my $stdout = select $log;
        $app->run2("no newline %s", 'single value');
        select $stdout;
        is($logfile, <<'        EOL', "log_debug() no newline");
no newline single value
        EOL
    }
    {
        open my $log, '>', \my $logfile;
        my $stdout = select $log;
        $app->run2("With newline %s\n", 'single value');
        select $stdout;
        is($logfile, <<'        EOL', "log_debug() newline");
With newline single value
        EOL
    }
    {
        $app->final_options->{verbose} = 0;
        is($app->option('verbose'), 0, "No verbosity");
        open my $log, '>', \my $logfile;
        my $stdout = select $log;
        $app->run1("no newline %s", 'single value');
        select $stdout;
        is($logfile, undef, "no log_info() without verbose");

        $app->final_options->{verbose} = 1;
        is($app->option('verbose'), 1, "verbose == 1");
        select $log;
        $app->run2("With newline %s", 'single value');
        select $stdout;
        is($logfile, undef, "no log_debug() without verbose 2+");
    }
    unlink 'smokeme_config';
}

{
    my $app;
    my $helptxt;
    {
        no warnings 'redefine';
        local *CORE::GLOBAL::exit = sub (;$) {
            return shift
        };
        local *STDOUT;
        open STDOUT, '>', \$helptxt;

        local @ARGV = ('--help', '--test1', 'app');
        $app = Test::Smoke::App::Test1->new(
            main_options => [
                Test::Smoke::App::AppOption->new(
                    name => 'test1',
                    option => '=s',
                    allow => ['app'],
                    helptext => 'Test1 variation',
                ),
            ],
        );
        isa_ok($app, 'Test::Smoke::App::Test1');
    }
    like(
        $helptxt,
        qr/test1=s <app>\s+ - Test1 variation/,
        "Helptext after --help"
    );
}

{ # This is to test the non-existence of the configfile
    local @ARGV = ('-v=2', '--test1', 'app2', '-c', 'smokeme');
    my $app = Test::Smoke::App::Test1->new(
        main_options => [
            Test::Smoke::App::AppOption->new(
                name => 'test1',
                option => '=s',
                allow => ['app2']
            ),
        ],
    );
    isa_ok($app, 'Test::Smoke::App::Test1');
    is_deeply($app->from_configfile, {}, "No configfile");
}

{ # This is to test the existence of a bad configfile
    local $SIG{__WARN__} = sub { };
    local @ARGV = ('-v=2', '--test1', 'app2', '-c', 'smokeme');
    open my $fh, '>', 'smokeme.config';
    print $fh "mybin2 : /usr/bin/mybin2\n";
    close $fh;
    my $app = Test::Smoke::App::Test1->new(
        main_options => [
            Test::Smoke::App::AppOption->new(
                name => 'test1',
                option => '=s',
                allow => ['app2'],
            ),
        ],
    );
    isa_ok($app, 'Test::Smoke::App::Test1');
    like(
        $app->configfile_error,
        qr/syntax error|Unknown regexp modifier/,
        "configfile error"
    );
    unlink 'smokeme.config';
}

{ # This is to test the precise existence of the configfile
    create_config('smokeme_config', mybin2 => '/usr/bin/mybin2');
    local @ARGV = ('-c', 'smokeme_config');
    my $app = Test::Smoke::App::Test1->new();
    isa_ok($app, 'Test::Smoke::App::Test1');
    is_deeply(
        $app->from_configfile,
        {mybin2 => '/usr/bin/mybin2'},
        "Got configfile"
    ) or diag $app->configfile_error;
    unlink 'smokeme_config';
}

{
    my $exitval;
    no warnings 'redefine';
    local *CORE::GLOBAL::exit = sub { $exitval = shift };
    my $stdout;
    {
        local @ARGV = ('-v', 3);
        local *STDOUT;
        open STDOUT, '>', \$stdout;
        my $app = Test::Smoke::App::Test1->new();
    }
    is($exitval, 1, "Program exit value 1");
    is(
        $stdout,
        "Invalid value '3' for option 'verbose'\n",
        "Diagnostic output invalid option values"
    );
}

{ # --show_config
    my $exitval;
    no warnings 'redefine';
    local *CORE::GLOBAL::exit = sub { $exitval = shift };
    local @ARGV = ('--show-config', '-v', '1');
    my $stdout;
    {
        local *STDOUT;
        open STDOUT, '>', \$stdout;
        my $app = Test::Smoke::App::Test1->new();
    }
    is($stdout, <<'    EODUMP', "--show-config");
Show configuration requested:
  Option              | Value
----------------------+--------------------------------------------
  configfile          | smokecurrent
  verbose             | 1
    EODUMP
    is($exitval, 0, "ExitValue 0");
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();

sub create_config {
    my ($name, %options) = @_;

    my $dump = Data::Dumper->new([\%options], ['conf'])->Dump;
    open my $fh, '>', $name or die "Cannot create '$name': $!";
    print $fh $dump;
    close $fh or die "Error writing to '$name': $!";
    return 1;
}

package Test::Smoke::App::Test1;
use warnings;
use strict;

use base 'Test::Smoke::App::Base';

sub run1 {
    my $self = shift;
    $self->log_info(@_);
}

sub run2 {
    my $self = shift;
    $self->log_debug(@_);
}
1;
