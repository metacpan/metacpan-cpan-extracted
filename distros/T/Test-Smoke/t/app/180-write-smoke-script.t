#! perl -w
use strict;
use warnings;

use Test::More;
use Test::NoWarnings ();

use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;

use Test::Smoke::LogMixin;
use Test::Smoke::App::ConfigSmoke::WriteSmokeScript;

# Disable timestamps so we can match exact output.
$Test::Smoke::LogMixin::USE_TIMESTAMP = 0;

{ # write_smoke_script: VMS branch is now routed through log_warn
    local $^O = 'VMS';
    my $obj = FakeConfigSmoke->new();

    open my $cap, '>', \my $out;
    my $stdout = select $cap; $|++;
    $obj->write_smoke_script('cron', '22:25');
    select $stdout;

    like(
        $out,
        qr/VMS not \(fully\) supported yet\./,
        'VMS branch emits a warning via log_warn'
    );
    is(
        $obj->{_smoke_script}, 'smokecurrent.com',
        'VMS sets the .com smoke_script extension'
    );
}

{ # write_as_shell: happy path uses log_info for header and "Created" line
    my $tmp = tempdir(CLEANUP => 1);
    my $jcl = File::Spec->catfile($tmp, 'smokecurrent.sh');
    my $obj = FakeConfigSmoke->new(_smoke_script_value => $jcl);

    open my $cap, '>', \my $out;
    my $stdout = select $cap; $|++;
    $obj->write_as_shell('cron', '22:25');
    select $stdout;

    like($out, qr/-- Write shell script --/,    'header logged via log_info');
    like($out, qr/>> Created '\Q$jcl\E'/,       '"Created" line logged via log_info');
    ok(-f $jcl,                                 'shell script file was written');
}

{ # write_as_shell: log_info is silenced when verbose == 0
    my $tmp = tempdir(CLEANUP => 1);
    my $jcl = File::Spec->catfile($tmp, 'smokecurrent.sh');
    my $obj = FakeConfigSmoke->new(
        _smoke_script_value => $jcl,
        _verbose            => 0,
    );

    my $out = '';
    open my $cap, '>', \$out;
    my $stdout = select $cap; $|++;
    $obj->write_as_shell('cron', '22:25');
    select $stdout;

    is($out, '', 'no info output at verbose=0 (only log_info calls in happy path)');
    ok(-f $jcl, 'script still written when info logging is silenced');
}

{ # write_as_shell: file-create failure goes through log_warn (always shown)
    my $bad = File::Spec->catfile(
        'no_such_dir_for_write_smoke_script_test', 'x.sh'
    );
    my $obj = FakeConfigSmoke->new(
        _smoke_script_value => $bad,
        _verbose            => 0,
    );

    open my $cap, '>', \my $out;
    my $stdout = select $cap; $|++;
    eval { $obj->write_as_shell('cron', '22:25') };
    my $err = $@;
    select $stdout;

    like(
        $out,
        qr/Problem: cannot create\(\Q$bad\E\)/,
        'create-failure routed through log_warn'
    );
    like(
        $err,
        qr/Please, fix yourself\./,
        'die still fires after log_warn'
    );
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();

# ------------------------------------------------------------------
# Minimal host that mixes in WriteSmokeScript and supplies just the
# attributes/methods used by write_smoke_script / write_as_shell.
# ------------------------------------------------------------------
package FakeConfigSmoke;
use base 'Test::Smoke::ObjectBase';
use Test::Smoke::LogMixin;
use Test::Smoke::App::ConfigSmoke::WriteSmokeScript;

sub VERSION { '0.000' }

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        _verbose            => 1,
        _prefix             => 'smokecurrent',
        _configfile         => 'smokecurrent_config',
        _dollar_0           => 'configsmoke.pl',
        _smoke_script_value => 'smokecurrent.sh',
        _current_values     => {
            umask    => '022',
            lfile    => 'smokecurrent.log',
            renice   => '',
            killtime => '',
        },
        %args,
    }, $class;
    return $self;
}

# smoke_script is read by both write_smoke_script and write_as_shell.
sub smoke_script { $_[0]->{_smoke_script_value} }

# Stub the Scheduler mixin methods called by write_as_shell / write_as_cmd.
sub schedule_entry_crontab  { qq[25 22 * * * '$_[1]'] }
sub schedule_entry_ms_at    { qq[$_[1] 22:25 placeholder] }
sub query_entry_ms_schtasks { 'schtasks placeholder' }

1;
