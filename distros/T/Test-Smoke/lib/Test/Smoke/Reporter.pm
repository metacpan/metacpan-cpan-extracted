package Test::Smoke::Reporter;
use warnings;
use strict;

our $VERSION = '0.054';

require File::Path;
require Test::Smoke;
use Cwd;
use Encode qw( decode encode );
use File::Spec::Functions;
use Test::Smoke::Util::LoadAJSON;
use POSIX qw( strftime );
use System::Info;
use Test::Smoke::Util qw(
    grepccmsg grepnonfatal get_smoked_Config read_logfile
    time_in_hhmm get_local_patches
);
use Text::ParseWords;
use Test::Smoke::LogMixin;

use constant USERNOTE_ON_TOP => 'top';

my %CONFIG = (
    df_ddir         => curdir(),
    df_outfile      => 'mktest.out',
    df_rptfile      => 'mktest.rpt',
    df_jsnfile      => 'mktest.jsn',
    df_cfg          => undef,
    df_lfile        => undef,
    df_showcfg      => 0,

    df_locale       => undef,
    df_defaultenv   => undef,
    df_perlio_only  => undef,
    df_is56x        => undef,
    df_skip_tests   => undef,

    df_harnessonly  => undef,
    df_harness3opts => undef,

    df_v            => 0,
    df_hostname     => undef,
    df_from         => '',
    df_send_log     => 'on_fail',
    df_send_out     => 'never',
    df_user_note    => '',
    df_un_file      => undef,
    df_un_position  => 'bottom', # != USERNOTE_ON_TOP for bottom
);

=head1 NAME

Test::Smoke::Reporter - OO interface for handling the testresults (mktest.out)

=head1 SYNOPSIS

    use Test::Smoke;
    use Test::Smoke::Reporter;

    my $reporter = Test::Smoke::Reporter->new( %args );
    $reporter->write_to_file;
    $reporter->transport( $url );

=head1 DESCRIPTION

Handle the parsing of the F<mktest.out> file.

=head1 METHODS

=head2 Test::Smoke::Reporter->new( %args )

[ Constructor | Public ]

Initialise a new object.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto ? ref $proto : $proto;

    my %args_raw = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();

    my %args = map {
        ( my $key = $_ ) =~ s/^-?(.+)$/lc $1/e;
        ( $key => $args_raw{ $_ } );
    } keys %args_raw;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } keys %{ $class->config( 'all_defaults' ) };

    $fields{_conf_args} = { %args_raw };
    my $self = bless \%fields, $class;
    $self->read_parse(  );
}

=head2 $reporter->verbose()

Accessor to the C<v> attribute.

=cut

sub verbose {
    my $self = shift;

    $self->{v} = shift if @_;

    $self->{v};
}

=head2 Test::Smoke::Reporter->config( $key[, $value] )

[ Accessor | Public ]

C<config()> is an interface to the package lexical C<%CONFIG>,
which holds all the default values for the C<new()> arguments.

With the special key B<all_defaults> this returns a reference
to a hash holding all the default values.

=cut

sub config {
    my $dummy = shift;

    my $key = lc shift;

    if ( $key eq 'all_defaults' ) {
        my %default = map {
            my( $pass_key ) = $_ =~ /^df_(.+)/;
            ( $pass_key => $CONFIG{ $_ } );
        } grep /^df_/ => keys %CONFIG;
        return \%default;
    }

    return undef unless exists $CONFIG{ "df_$key" };

    $CONFIG{ "df_$key" } = shift if @_;

    return $CONFIG{ "df_$key" };
}

=head2 $self->read_parse( [$result_file] )

C<read_parse()> reads the smokeresults file and parses it.

=cut

sub read_parse {
    my $self = shift;

    my $result_file = @_ ? $_[0] : $self->{outfile}
        ? catfile( $self->{ddir}, $self->{outfile} )
        : "";
    $self->log_debug("[%s::read_parse] found '%s'", ref($self), $result_file);

    if ( $result_file ) {
        $self->_read( $result_file );
        $self->_parse;
    }
    return $self;
}

=head2 $self->_read( $nameorref )

C<_read()> is a private method that handles the reading.

=over 8

=item B<Reference to a SCALAR> smokeresults are in C<$$nameorref>

=item B<Reference to an ARRAY> smokeresults are in C<@$nameorref>

=item B<Reference to a GLOB> smokeresults are read from the filehandle

=item B<Other values> are taken as the filename for the smokeresults

=back

=cut

sub _read {
    my $self = shift;
    my( $nameorref ) = @_;
    $nameorref = '' unless defined $nameorref;

    my $vmsg = "";
    local *SMOKERSLT;
    if ( ref $nameorref eq 'SCALAR' ) {
        $self->{_outfile} = $$nameorref;
        $vmsg = "from internal content";
    } elsif ( ref $nameorref eq 'ARRAY' ) {
        $self->{_outfile} = join "", @$nameorref;
        $vmsg = "from internal content";
    } elsif ( ref $nameorref eq 'GLOB' ) {
        *SMOKERSLT = *$nameorref;
        $self->{_outfile} = do { local $/; <SMOKERSLT> };
        $vmsg = "from anonymous filehandle";
    } else {
        if ( $nameorref ) {
            $vmsg = "from $nameorref";
            $self->{_outfile} = read_logfile($nameorref, $self->{v});
            defined($self->{_outfile}) or do {
                require Carp;
                Carp::carp( "Cannot read smokeresults ($nameorref): $!" );
                $vmsg = "did fail";
            };
        } else { # Allow intentional default_buildcfg()
            $self->{_outfile} = undef;
            $vmsg = "did fail";
        }
    }
    $self->log_info("Reading smokeresult %s", $vmsg);
}

=head2 $self->_parse( )

Interpret the contents of the outfile and prepare them for processing,
so report can be made.

=cut

sub _parse {
    my $self = shift;

    $self->{_rpt}    = \my %rpt;
    $self->{_cache}  = {};
    $self->{_mani}   = [];
    $self->{configs} = \my @new;
    return $self unless defined $self->{_outfile};

    my ($cfgarg, $debug, $tstenv, $start, $statarg, $fcnt);
    $rpt{count} = 0;
    # reverse and use pop() instead of using unshift()
    my @lines           = reverse split m/\n+/, $self->{_outfile};
    my $previous        = "";
    my $previous_failed = "";

    while (defined (local $_ = pop @lines)) {
        m/^\s*$/ and next;
        m/^-+$/  and next;
        s/\s*$//;

        if (my ($status, $time) = /(Started|Stopped) smoke at (\d+)/) {
            if ($status eq "Started") {
                $start = $time;
                $rpt{started} ||= $time;
            }
            elsif (defined $start) {
                my $elapsed = $time - $start;
                $rpt{secs} += $elapsed;
                @new and $new[-1]{duration} = $elapsed;
            }
            next;
        }

        if (my ($patch) = m/^   \s*
                                Smoking\ patch\s*
                                ((?:[0-9a-f]+\s+\S+)|(?:\d+\S*))
                                /x )
        {
            my ($pl, $descr) = split ' ', $patch;
            $rpt{patchlevel} = $patch;
            $rpt{patch}      = $pl || $patch;
            $rpt{patchdescr} = $descr || $pl;
            next;
        }
        if (/^Smoking branch (\S+)/) {
            $rpt{smokebranch} = $1;
        }

        if (/^MANIFEST /) {
            push @{$self->{_mani}}, $_;
            next;
        }

        if (s/^\s*Configuration:\s*//) {

            # You might need to do something here with
            # the previous Configuration: $cfgarg
            $rpt{statcfg}{$statarg} = $fcnt if defined $statarg;
            $fcnt = 0;

            $rpt{count}++;
            s/-Dusedevel(\s+|$)//;
            s/\s*-des//;
            $statarg = $_;
            $debug = s/-D(DEBUGGING|usevmsdebug)\s*// ? "D" : "N";
            $debug eq 'D' and $rpt{dbughow} = "-D$1";
            s/\s+$//;

            $cfgarg = $_ || "";

            push(
                @new,
                {
                    arguments => $_,
                    debugging => $debug,
                    started   => __posixdate($start),
                    results   => [],
                }
            );
            push @{$rpt{cfglist}}, $_ unless $rpt{config}->{$cfgarg}++;
            $tstenv          = "";
            $previous_failed = "";
            next;
        }

        if (my ($cinfo) = /^Compiler info: (.+)$/) {
            $rpt{$cfgarg}->{cinfo} = $cinfo;
            $rpt{cinfo} ||= $cinfo;
            @{$new[-1]}{qw( cc ccversion )} = split m/ version / => $cinfo, 2;
            next;
        }

        if (m/(?:PERLIO|TSTENV)\s*=\s*([-\w:.]+)/
              # skip this if it's from a build failure, since the
              # Unable to build... pushed an M
              && (!@{$new[-1]{results}}
                  || $new[-1]{results}[0]{summary} ne "M")) {
            $tstenv          = $1;
            $previous_failed = "";
            $rpt{$cfgarg}->{summary}{$debug}{$tstenv} ||= "?";
            my ($io_env, $locale) = split m/:/ => $tstenv,
                2;
            push(
                @{$new[-1]{results}},
                {
                    io_env        => $io_env,
                    locale        => $locale,
                    summary       => "?",
                    statistics    => undef,
                    stat_tests    => undef,
                    stat_cpu_time => undef,
                    failures      => [],
                }
            );

            # Deal with harness output
            s/^(?:PERLIO|TSTENV)\s*=\s+[-\w:.]+(?: :crlf)?\s*//;
        }

        if (m/\b(Files=[0-9]+,\s*Tests=([0-9]+),.*?=\s*([0-9.]+)\s*CPU)/) {
            $new[-1]{results}[-1]{statistics}    = $1;
            $new[-1]{results}[-1]{stat_tests}    = $2;
            $new[-1]{results}[-1]{stat_cpu_time} = $3;
        }
        elsif (
            m/\b(u=([0-9.]+)\s+
                    s=([0-9.]+)\s+
                    cu=([0-9.]+)\s+
                    cs=([0-9.]+)\s+
                    scripts=[0-9]+\s+
                    tests=([0-9]+))/xi
            )
        {
            $new[-1]{results}[-1]{statistics}    = $1;
            $new[-1]{results}[-1]{stat_tests}    = $6;
            $new[-1]{results}[-1]{stat_cpu_time} = $2 + $3 + $4 + $5;
        }

        if (m/^\s*All tests successful/) {
            $rpt{$cfgarg}->{summary}{$debug}{$tstenv} = "O";
            $new[-1]{results}[-1]{summary} = "O";
            next;
        }

        if (m/Inconsistent test ?results/) {
            ref $rpt{$cfgarg}->{$debug}{$tstenv}{failed}
                or $rpt{$cfgarg}->{$debug}{$tstenv}{failed} = [];

            if (not $rpt{$cfgarg}->{summary}{$debug}{$tstenv}
                or $rpt{$cfgarg}->{summary}{$debug}{$tstenv} ne "F")
            {
                $rpt{$cfgarg}->{summary}{$debug}{$tstenv} = "X";
                $new[-1]{results}[-1]{summary} = "X";
            }
            push @{$rpt{$cfgarg}->{$debug}{$tstenv}{failed}}, $_;
            while (m/^ \s* (\S+?) \s* \.+(?:\s+\.+)* \s* (\w.*?) \s*$/xgm) {
                my ($_test, $_info) = ($1, $2);

                push(
                    @{$new[-1]{results}[-1]{failures}},
                    $_info =~ m/^ \w+ $/x
                        ? {
                            test   => $_test,
                            status => $_info,
                            extra  => []
                            }
                        : # TEST output from minitest
                    $_info =~ m/^ (\w+) \s+at\ test\s+ (\d+) \s* $/x
                 || $_info =~ m/^ (\w+)--(\S.*\S) \s* $/x
                        ? {
                            test   => $_test,
                            status => $1,
                            extra  => [ $2 ]
                            }
                        : {
                            test   => "?",
                            status => "?",
                            extra  => []
                            }
                );
            }
        }

        if (/^Finished smoking [\dA-Fa-f]+/) {
            $rpt{statcfg}{$statarg} = $fcnt;
            $rpt{finished} = "Finished";
            next;
        }

        if (my ($status, $mini) =
            m/^ \s* Unable\ to
                \ (?=([cbmt]))(?:build|configure|make|test)
                \ (anything\ but\ mini)?perl/x
                )
        {
            $mini and $status = uc $status;   # M for no perl but miniperl
                                              # $tstenv is only set *after* this
            $tstenv ||= $mini ? "minitest" : "stdio";
            $rpt{$cfgarg}->{summary}{$debug}{$tstenv} = $status;
            push(
                @{$new[-1]{results}},
                {
                    io_env        => $tstenv,
                    locale        => undef,
                    summary       => $status,
                    statistics    => undef,
                    stat_tests    => undef,
                    stat_cpu_time => undef,
                    failures      => [],
                }
            );
            $fcnt++;
            next;
        }

        if (m/FAILED/ || m/DIED/ || m/dubious$/ || m/\?\?\?\?\?\?$/) {
            ref $rpt{$cfgarg}->{$debug}{$tstenv}{failed}
                or $rpt{$cfgarg}->{$debug}{$tstenv}{failed} = [];

            if ($previous_failed ne $_) {
                if (not $rpt{$cfgarg}->{summary}{$debug}{$tstenv}
                    or $rpt{$cfgarg}->{summary}{$debug}{$tstenv} !~ m/[XM]/)
                {
                    $rpt{$cfgarg}->{summary}{$debug}{$tstenv} = "F";
                    $new[-1]{results}[-1]{summary} = "F";
                }
                push @{$rpt{$cfgarg}->{$debug}{$tstenv}{failed}}, $_;
                push(
                    @{$new[-1]{results}[-1]{failures}},
                    m{^ \s*                     # leading space
                       ((?:\S+[/\\])?           # Optional leading path to
                           \S(?:[^.]+|\.t)+)    #  test file name
                       [. ]+                    # ....... ......
                       (\w.*?)                  # result
                       \s* $}x
                        ? {
                            test   => $1,
                            status => $2,
                            extra  => []
                            }
                        : {
                            test   => "?",
                            status => "?",
                            extra  => []
                        }
                );

                $fcnt++;
            }
            $previous_failed = $_;

            $previous = "failed";
            next;
        }

        if (m/PASSED/) {
            ref $rpt{$cfgarg}->{$debug}{$tstenv}{passed}
                or $rpt{$cfgarg}->{$debug}{$tstenv}{passed} = [];

            push @{$rpt{$cfgarg}->{$debug}{$tstenv}{passed}}, $_;
            push(
                @{$new[-1]{results}[-1]{failures}},
                m/^ \s* (\S+?) \.+(?:\s+\.+)* (\w+) \s* $/x
                    ? {
                        test   => $1,
                        status => $2,
                        extra  => []
                        }
                    : {
                        test   => "?",
                        status => "?",
                        extra  => []
                    }
            );
            $previous = "passed";
            next;
        }

        my @captures = ();
        if (@captures = $_ =~ m/
            (?:^|,)\s+
            (\d+(?:-\d+)?)
            /gx) {
            if (ref $rpt{$cfgarg}->{$debug}{$tstenv}{$previous}) {
                push @{$rpt{$cfgarg}->{$debug}{$tstenv}{$previous}}, $_;
                push @{$new[-1]{results}[-1]{failures}[-1]{extra}}, @captures;
            }
            next;
        }

        if (/^\s+(?:Bad plan)|(?:No plan found)|^\s+(?:Non-zero exit status)/) {
            if (ref $rpt{$cfgarg}->{$debug}{$tstenv}{failed}) {
                push @{$rpt{$cfgarg}->{$debug}{$tstenv}{failed}}, $_;
                s/^\s+//;
                push @{$new[-1]{results}[-1]{failures}[-1]{extra}}, $_;
            }
            next;
        }
        next;
    }

    $rpt{last_cfg} = $statarg;
    exists $rpt{statcfg}{$statarg} or $rpt{running} = $fcnt;
    $rpt{avg} = $rpt{count} ? $rpt{secs} / $rpt{count} : 0;
    $self->{_rpt} = \%rpt;
    $self->_post_process;
}

=head2 $self->_post_process( )

C<_post_process()> sets up the report for easy printing. It needs to
sort the buildenvironments, statusletters and test failures.

=cut

sub _post_process {
    my $self = shift;

    unless (defined $self->{is56x}) {
        $self->{is56x} = 0;
        # Overly defensive, as .out files might be analyzed outside of the
        # original smoke environment
        if ($self->{ddir} && -d $self->{ddir}) {
            my %cfg = get_smoked_Config($self->{ddir}, "version");
            if ($cfg{version} =~ m/^\s* ([0-9]+) \. ([0-9]+) \. ([0-9]+) \s*$/x) {
                my $p_version = sprintf "%d.%03d%03d", $1, $2, $3;
                $self->{is56x} = $p_version < 5.007;
            }
        }
    }
    $self->{defaultenv} ||= $self->{is56x};

    my (%bldenv, %cfgargs);
    my $rpt = $self->{_rpt};
    foreach my $config (@{$rpt->{cfglist}}) {

        foreach my $buildenv (keys %{$rpt->{$config}{summary}{N}}) {
            $bldenv{$buildenv}++;
        }
        foreach my $buildenv (keys %{$rpt->{$config}{summary}{D}}) {
            $bldenv{$buildenv}++;
        }
        foreach my $ca (grep defined $_ => quotewords('\s+', 1, $config)) {
            $cfgargs{$ca}++;
        }
    }
    my %common_args =
        map { ($_ => 1) }
        grep $cfgargs{$_} == @{$rpt->{cfglist}}
        && !/^-[DU]use/ => keys %cfgargs;

    $rpt->{_common_args} = \%common_args;
    $rpt->{common_args} = join " ", sort keys %common_args;
    $rpt->{common_args} ||= 'none';

    $self->{_tstenv} = [reverse sort keys %bldenv];
    my %count = (
        O => 0,
        F => 0,
        X => 0,
        M => 0,
        m => 0,
        c => 0,
        o => 0,
        t => 0
    );
    my (%failures, %order);
    my $ord = 1;
    my (%todo_passed, %order2);
    my $ord2 = 1;
    my $debugging = $rpt->{dbughow} || '-DDEBUGGING';

    foreach my $config (@{$rpt->{cfglist}}) {
        foreach my $dbinfo (qw( N D )) {
            my $cfg = $config;
            ($cfg = $cfg ? "$debugging $cfg" : $debugging)
                if $dbinfo eq "D";
            $self->log_info("Processing [%s]", $cfg);
            my $status = $self->{_rpt}{$config}{summary}{$dbinfo};
            foreach my $tstenv (reverse sort keys %bldenv) {
                next if $tstenv eq 'minitest' && !exists $status->{$tstenv};

                (my $showenv = $tstenv) =~ s/^locale://;
                if ($tstenv =~ /^locale:/) {
                    $self->{_locale_keys}{$showenv}++
                        or push @{$self->{_locale}}, $showenv;
                }
                $showenv = 'default'
                    if $self->{defaultenv} && $showenv eq 'stdio';

                $status->{$tstenv} ||= '-';

                my $status2 = $self->{_rpt}{$config}{$dbinfo};
                if (exists $status2->{$tstenv}{failed}) {
                    my $failed = join "\n", @{$status2->{$tstenv}{failed}};
                    if (   exists $failures{$failed}
                        && @{$failures{$failed}}
                        && $failures{$failed}->[-1]{cfg} eq $cfg)
                    {
                        push @{$failures{$failed}->[-1]{env}}, $showenv;
                    }
                    else {
                        push @{$failures{$failed}},
                            {
                            cfg => $cfg,
                            env => [$showenv]
                            };
                        $order{$failed} ||= $ord++;
                    }
                }
                if (exists $status2->{$tstenv}{passed}) {
                    my $passed = join "\n", @{$status2->{$tstenv}{passed}};
                    if (   exists $todo_passed{$passed}
                        && @{$todo_passed{$passed}}
                        && $todo_passed{$passed}->[-1]{cfg} eq $cfg)
                    {
                        push @{$todo_passed{$passed}->[-1]{env}}, $showenv;
                    }
                    else {
                        push(
                            @{$todo_passed{$passed}},
                            {
                                cfg => $cfg,
                                env => [$showenv]
                            }
                        );
                        $order2{$passed} ||= $ord2++;
                    }

                }

                $self->log_debug("\t[%s]: %s", $showenv, $status->{$tstenv});
                if ($tstenv eq 'minitest') {
                    $status->{stdio} = "M";
                    delete $status->{minitest};
                }
            }
            unless ($self->{defaultenv}) {
                exists $status->{perlio} or $status->{perlio} = '-';
                my @locales = split ' ', ($self->{locale} || '');
                for my $locale (@locales) {
                    exists $status->{"locale:$locale"}
                        or $status->{"locale:$locale"} = '-';
                }
            }

            $count{$_}++
                for map { m/[cmMtFXO]/ ? $_ : m/-/ ? 'O' : 'o' }
                map $status->{$_} => keys %$status;
        }
    }
    defined $self->{_locale} or $self->{_locale} = [];

    my @failures = map {
        {
            tests => $_,
            cfgs  => [
                map {
                    my $cfg_clean = __rm_common_args($_->{cfg}, \%common_args);
                    my $env = join "/", @{$_->{env}};
                    "[$env] $cfg_clean";
                } @{$failures{$_}}
            ],
        }
    } sort { $order{$a} <=> $order{$b} } keys %failures;
    $self->{_failures} = \@failures;

    my @todo_passed = map {
        {
            tests => $_,
            cfgs  => [
                map {
                    my $cfg_clean = __rm_common_args($_->{cfg}, \%common_args);
                    my $env = join "/", @{$_->{env}};
                    "[$env] $cfg_clean";
                } @{$todo_passed{$_}}
            ],
        }
    } sort { $order2{$a} <=> $order2{$b} } keys %todo_passed;
    $self->{_todo_passed} = \@todo_passed;

    $self->{_counters} = \%count;

    # Need to rebuild the test-environments as minitest changes into stdio
    my %bldenv2;
    foreach my $config (@{$rpt->{cfglist}}) {
        foreach my $buildenv (keys %{$rpt->{$config}{summary}{N}}) {
            $bldenv2{$buildenv}++;
        }
        foreach my $buildenv (keys %{$rpt->{$config}{summary}{D}}) {
            $bldenv2{$buildenv}++;
        }
    }
    $self->{_tstenvraw} = $self->{_tstenv};
    $self->{_tstenv}    = [reverse sort keys %bldenv2];
}

=head2 __posixdate($time)

Returns C<strftime("%F %T %z")>.

=cut

sub __posixdate {

    # Note that the format "%F %T %z" returns:
    #  Linux:  2012-04-02 10:57:58 +0200
    #  HP-UX:  April 08:53:32 METDST
    # ENOTPORTABLE!  %F is C99 only!
    my $stamp = shift || time;
    return $^O eq 'MSWin32'
        ? POSIX::strftime("%Y-%m-%d %H:%M:%S Z", gmtime $stamp)
        : POSIX::strftime("%Y-%m-%d %H:%M:%S %z", localtime $stamp);
}

=head2 __rm_common_args( $cfg, \%common )

Removes the the arguments stored as keys in C<%common> from C<$cfg>.

=cut

sub __rm_common_args {
    my( $cfg, $common ) = @_;

    require Test::Smoke::BuildCFG;
    my $bcfg = Test::Smoke::BuildCFG::new_configuration( $cfg );

    return $bcfg->rm_arg( keys %$common );
}

=head2 $reporter->get_logfile()

Return the contents of C<< $self->{lfile} >> either by reading the file or
returning the cached version.

=cut

sub get_logfile {
    my $self = shift;
    return $self->{log_file} if $self->{log_file};

    return $self->{log_file} = read_logfile($self->{lfile}, $self->{v});
}

=head2 $reporter->get_outfile()

Return the contents of C<< $self->{outfile} >> either by reading the file or
returning the cached version.

=cut

sub get_outfile {
    my $self = shift;
    return $self->{_outfile} if $self->{_outfile};

    my $fq_outfile = catfile($self->{ddir}, $self->{outfile});
    return $self->{_outfile} = read_logfile($fq_outfile, $self->{v});
}

=head2 $reporter->write_to_file( [$name] )

Write the C<< $self->report >> to file. If name is omitted it will
use C<< catfile( $self->{ddir}, $self->{rptfile} ) >>.

=cut

sub write_to_file {
    my $self = shift;
    return unless defined $self->{_outfile};
    my( $name ) = shift || ( catfile $self->{ddir}, $self->{rptfile} );

    $self->log_info("Writing report to '%s'", $name);
    local *RPT;
    open RPT, "> $name" or do {
        require Carp;
        Carp::carp( "Error creating '$name': $!" );
        return;
    };
    print RPT $self->report;
    close RPT or do {
        require Carp;
        Carp::carp( "Error writing to '$name': $!" );
        return;
    };
    $self->log_info("'%s' written OK", $name);
    return 1;
}

=head2 $reporter->smokedb_data()

Transport the report to the gateway. The transported data will also be stored
locally in the file mktest.jsn

=cut

sub smokedb_data {
    my $self = shift;
    $self->log_info("Gathering CoreSmokeDB information...");

    my %rpt  = map { $_ => $self->{$_} } keys %$self;
    $rpt{manifest_msgs}   = delete $rpt{_mani};
    $rpt{applied_patches} = [$self->registered_patches];
    $rpt{sysinfo}         = do {
        my %Conf = get_smoked_Config($self->{ddir} => qw( version lfile ));
        my $si = System::Info->new;
        my ($osname, $osversion) = split m/ - / => $si->os, 2;
        (my $ncpu      = $si->ncpu          || "?") =~ s/^\s*(\d+)\s*/$1/;
        (my $user_note = $self->{user_note} || "")  =~ s/(\S)[\s\r\n]*\z/$1\n/;
        {
            architecture     => lc $si->cpu_type,
            config_count     => $self->{_rpt}{count},
            cpu_count        => $ncpu,
            cpu_description  => $si->cpu,
            duration         => $self->{_rpt}{secs},
            git_describe     => $self->{_rpt}{patchdescr},
            git_id           => $self->{_rpt}{patch},
            smoke_branch     => $self->{_rpt}{smokebranch},
            hostname         => $self->{hostname} || $si->host,
            lang             => $ENV{LANG},
            lc_all           => $ENV{LC_ALL},
            osname           => $osname,
            osversion        => $osversion,
            perl_id          => $Conf{version},
            reporter         => $self->{from},
            reporter_version => $VERSION,
            smoke_date       => __posixdate($self->{_rpt}{started}),
            smoke_revision   => $Test::Smoke::VERSION,
            smoker_version   => $Test::Smoke::Smoker::VERSION,
            smoke_version    => $Test::Smoke::VERSION,
            test_jobs        => $ENV{TEST_JOBS},
            username         => $ENV{LOGNAME} || getlogin || getpwuid($<) || "?",
            user_note        => $user_note,
            smoke_perl       => ($^V ? sprintf("%vd", $^V) : $]),
        };
    };
    $rpt{compiler_msgs} = [$self->ccmessages];
    $rpt{nonfatal_msgs} = [$self->nonfatalmessages];
    $rpt{skipped_tests} = [$self->user_skipped_tests];
    $rpt{harness_only}  = delete $rpt{harnessonly};
    $rpt{summary}       = $self->summary;

    $rpt{log_file} = undef;
    my $rpt_fail = $rpt{summary} eq "PASS" ? 0 : 1;
    if (my $send_log = $self->{send_log}) {
        if (   ($send_log eq "always")
            or ($send_log eq "on_fail" && $rpt_fail))
        {
            $rpt{log_file} = $self->get_logfile();
        }
    }
    $rpt{out_file} = undef;
    if (my $send_out = $self->{send_out}) {
        if (   ($send_out eq "always")
            or ($send_out eq "on_fail" && $rpt_fail))
        {
            $rpt{out_file} = $self->get_outfile();
        }
    }
    delete $rpt{$_} for qw/from send_log send_out user_note/, grep m/^_/ => keys %rpt;

    my $json = JSON->new->utf8(1)->pretty(1)->encode(\%rpt);

    # write the json to file:
    my $jsn_file = catfile($self->{ddir}, $self->{jsnfile});
    if (open my $jsn, ">", $jsn_file) {
        binmode($jsn);
        print {$jsn} $json;
        close $jsn;
        $self->log_info("Write to '%s': ok", $jsn_file);
    }
    else {
        $self->log_warn("Error creating '%s': %s", $jsn_file, $!);
    }

    return $self->{_json} = $json;
}

=head2 $reporter->report( )

Return a string with the full report

=cut

sub report {
    my $self = shift;
    return unless defined $self->{_outfile};
    $self->_get_usernote();

    my $report = $self->preamble;

    $report .= "Summary: ".$self->summary."\n\n";
    $report .= $self->letter_legend . "\n";
    $report .= $self->smoke_matrix . $self->bldenv_legend;

    $report .= $self->registered_patches;

    $report .= $self->harness3_options;

    $report .= $self->user_skipped_tests;

    $report .= "\nFailures: (common-args) $self->{_rpt}{common_args}\n"
            .  $self->failures if $self->has_test_failures;
    $report .= "\n" . $self->mani_fail           if $self->has_mani_failures;

    $report .= "\nPassed Todo tests: (common-args) $self->{_rpt}{common_args}\n"
            .  $self->todo_passed if $self->has_todo_passed;

    $report .= $self->ccmessages;

    $report .= $self->nonfatalmessages;

    if ( $self->{showcfg} && $self->{cfg} && $self->has_test_failures ) {
        require Test::Smoke::BuildCFG;
        my $bcfg = Test::Smoke::BuildCFG->new( $self->{cfg} );
        $report .= "\nBuild configurations:\n" . $bcfg->as_string ."=\n";
    }

    $report .= $self->signature;
    return $report;
}

=head2 $reporter->_get_usernote()

Return $self->{user_note} if exists.

Check if C<< $self->{un_file} >> exists, and read contents into C<<
$self->{user_note} >>.

=cut

sub _get_usernote {
    my $self = shift;

    if (!$self->{user_note} && $self->{un_file}) {
        if (open my $unf, '<', $self->{un_file}) {
            $self->{user_note} = join('', <$unf>);
        }
        else {
            $self->log_warn("Cannot read '%s': %s", $self->{un_file}, $!);
        }
    }
    elsif (!defined $self->{user_note}) {
        $self->{user_note} = '';
    }
    $self->{user_note} =~ s/(?<=\S)\s*\z/\n/;
}

=head2 $reporter->ccinfo( )

Return the string containing the C-compiler info.

=cut

sub ccinfo {
    my $self = shift;
    my $cinfo = $self->{_rpt}{cinfo};
    unless ( $cinfo ) { # Old .out file?
        my %Config = get_smoked_Config( $self->{ddir} => qw(
            cc ccversion gccversion
        ));
        $cinfo = "? ";
        my $ccvers = $Config{gccversion} || $Config{ccversion} || '';
        $cinfo .= ( $Config{cc} || 'unknown cc' ) . " version $ccvers";
        $self->{_ccinfo} = ($Config{cc} || 'cc') . " version $ccvers";
    }
    return $cinfo;
}

=head2 $reporter->registered_patches()

Return a section with the locally applied patches (from patchlevel.h).

=cut

sub registered_patches {
    my $self = shift;

    my @lpatches = get_local_patches($self->{ddir}, $self->{v});
    @lpatches && $lpatches[0] eq "uncommitted-changes" and shift @lpatches;
    wantarray and return @lpatches;

    @lpatches or return "";

    my $list = join "\n", map "    $_" => @lpatches;
    return "\nLocally applied patches:\n$list\n";
}

=head2 $reporter->harness3_options

Show indication of the options used for C<HARNESS_OPTIONS>.

=cut

sub harness3_options {
    my $self = shift;

    $self->{harnessonly} or return "";

    my $msg = "\nTestsuite was run only with 'harness'";
    $self->{harness3opts} or return $msg . "\n";

    return  $msg . " and HARNESS_OPTIONS=$self->{harness3opts}\n";
}

=head2 $reporter->user_skipped_tests( )

Show indication for the fact that the user requested to skip some tests.

=cut

sub user_skipped_tests {
    my $self = shift;

    my @skipped;
    if ($self->{skip_tests} && -f $self->{skip_tests} and open my $fh,
        "<", $self->{skip_tests})
    {
        while (my $raw = <$fh>) {
            next, if $raw =~ m/^# One test name on a line/;
            chomp($raw);
            push @skipped,  "    $raw";
        }
        close $fh;
    }
    wantarray and return @skipped;

    my $skipped = join "\n", @skipped or return "";

    return "\nTests skipped on user request:\n$skipped";
}

=head2 $reporter->ccmessages( )

Use a port of Jarkko's F<grepccerr> script to report the compiler messages.

=cut

sub ccmessages {
    my $self = shift;

    my $ccinfo = $self->{_rpt}{cinfo} || $self->{_ccinfo} || "cc";
    $ccinfo =~ s/^(.+)\s+version\s+.+/$1/;

    $^O =~ /^(?:linux|.*bsd.*|darwin)/ and $ccinfo = 'gcc';
    my $cc = $ccinfo =~ /(gcc|bcc32)/ ? $1 : $^O;

    if (!$self->{_ccmessages_}) {

        $self->log_info("Looking for cc messages: '%s'", $cc);
        $self->{_ccmessages_} = grepccmsg(
            $cc,
            $self->get_outfile(),
            $self->{v}
        ) || [];
    }
    $self->log_debug("Finished grepping for %s", $cc);

    return @{$self->{_ccmessages_}} if wantarray;
    return "" if !$self->{_ccmessages_};

    local $" = "\n";
    return <<"    EOERRORS";

Compiler messages($cc):
@{$self->{_ccmessages_}}
    EOERRORS
}

=head2 $reporter->nonfatalmessages( )

Find failures worth reporting that won't cause tests to fail

=cut

sub nonfatalmessages {
    my $self = shift;

    my $ccinfo = $self->{_rpt}{cinfo} || $self->{_ccinfo} || "cc";
    $ccinfo =~ s/^(.+)\s+version\s+.+/$1/;

    $^O =~ /^(?:linux|.*bsd.*|darwin)/ and $ccinfo = 'gcc';
    my $cc = $ccinfo =~ /(gcc|bcc32)/ ? $1 : $^O;

    if (!$self->{_nonfatal_}) {

        $self->log_info("Looking for non-fatal messages: '%s'", $cc);
        $self->{_nonfatal_} = grepnonfatal(
            $cc,
            $self->get_outfile(),
            $self->{v}
        ) || [];
    }

    return @{$self->{_nonfatal_}} if wantarray;
    return "" if !$self->{_nonfatal_};

    local $" = "\n";
    return <<"    EOERRORS";

Non-Fatal messages($cc):
@{$self->{_nonfatal_}}
    EOERRORS
}

=head2 $reporter->preamble( )

Returns the header of the report.

=cut

sub preamble {
    my $self = shift;

    my %Config = get_smoked_Config( $self->{ddir} => qw(
        version libc gnulibc_version
    ));
    my $si = System::Info->new;
    my $archname  = lc $si->cpu_type;

    (my $ncpu = $si->ncpu || "") =~ s/^(\d+)\s*/$1 cpu/;
    $archname .= "/$ncpu";

    my $cpu = $si->cpu;

    my $this_host = $self->{hostname} || $si->host;
    my $time_msg  = time_in_hhmm( $self->{_rpt}{secs} );
    my $savg_msg  = time_in_hhmm( $self->{_rpt}{avg}  );

    my $cinfo = $self->ccinfo;

    my $os = $si->os;

    my $branch = '';
    if ($self->{_rpt}{smokebranch}) {
        $branch = " branch $self->{_rpt}{smokebranch}";
    }

    my $preamble = <<__EOH__;
Automated smoke report for$branch $Config{version} patch $self->{_rpt}{patchlevel}
$this_host: $cpu ($archname)
    on        $os
    using     $cinfo
    smoketime $time_msg (average $savg_msg)

__EOH__

    if ($self->{un_position} eq USERNOTE_ON_TOP) {
        (my $user_note = $self->{user_note}) =~ s/(?<=\S)\s*\z/\n/;
        $preamble = "$user_note\n$preamble";
    }

    return $preamble;
}

=head2 $reporter->smoke_matrix( )

C<smoke_matrix()> returns a string with the result-letters and their
configs.

=cut

sub smoke_matrix {
    my $self = shift;
    my $rpt  = $self->{_rpt};

    # Maximum of 6 letters => 11 positions
    my $rptl = length $rpt->{patchdescr};
    my $pad = $rptl >= 11 ? "" : " " x int( (11 - $rptl)/2 );
    my $patch = $pad . $rpt->{patchdescr};
    my $report = sprintf "%-11s  Configuration (common) %s\n",
                         $patch, $rpt->{common_args};
    $report .= ("-" x 11) . " " . ("-" x 57) . "\n";

    foreach my $config ( @{ $rpt->{cfglist} } ) {
        my $letters = "";
        foreach my $dbinfo (qw( N D )) {
            foreach my $tstenv ( @{ $self->{_tstenv} } ) {
                $letters .= "$rpt->{$config}{summary}{$dbinfo}{$tstenv} ";
            }
        }
        my $cfg = join " ", grep ! exists $rpt->{_common_args}{ $_ }
            => quotewords( '\s+', 1, $config );
        $report .= sprintf "%-12s%s\n", $letters, $cfg;
    }

    return $report;
}

=head2 $reporter->summary( )

Return the B<PASS> or B<FAIL(x)> string.

=cut

sub summary {
    my $self         = shift;
    my $count        = $self->{_counters};
    my @rpt_sum_stat = grep $count->{$_} > 0 => qw( X F M m c t );
    my $rpt_summary  = "";
    if (@rpt_sum_stat) {
        $rpt_summary = "FAIL(" . join("", @rpt_sum_stat) . ")";
    }
    else {
        $rpt_summary = $count->{o} == 0 ? "PASS" : "PASS-so-far";
    }

    return $rpt_summary;
}

=head2 $reporter->has_test_failures( )

Returns true if C<< @{ $reporter->{_failures} >>.

=cut

sub has_test_failures { exists $_[0]->{_failures} && @{ $_[0]->{_failures} } }

=head2 $reporter->failures( )

report the failures (grouped by configurations).

=cut

sub failures {
    my $self = shift;

    return join "\n", map {
         join "\n", @{ $_->{cfgs} }, $_->{tests}, ""
    } @{ $self->{_failures} };
}

=head2 $reporter->has_todo_passed( )

Returns true if C<< @{ $reporter->{_todo_pasesd} >>.

=cut

sub has_todo_passed { exists $_[0]->{_todo_passed} && @{ $_[0]->{_todo_passed} } }

=head2 $reporter->todo_passed( )

report the todo that passed (grouped by configurations).

=cut

sub todo_passed {
    my $self = shift;

    return join "\n", map {
         join "\n", @{ $_->{cfgs} }, $_->{tests}, ""
    } @{ $self->{_todo_passed} };
}

=head2 $reporter->has_mani_failures( )

Returns true if C<< @{ $reporter->{_mani} >>.

=cut

sub has_mani_failures { exists $_[0]->{_mani} && @{ $_[0]->{_mani} } }

=head2 $reporter->mani_fail( )

report the MANIFEST failures.

=cut

sub mani_fail {
    my $self = shift;

    return join "\n", @{ $self->{_mani} }, "";
}

=head2 $reporter->bldenv_legend( )

Returns a string with the legend for build-environments

=cut

sub bldenv_legend {
    my $self = shift;
    $self->{defaultenv} = ( @{ $self->{_tstenv} } == 1 )
        unless defined $self->{defaultenv};
    my $debugging = $self->{_rpt}{dbughow} || '-DDEBUGGING';

    if ( $self->{_locale} && @{ $self->{_locale} } ) {
        my @locale = ( @{ $self->{_locale} }, @{ $self->{_locale} } );
        my $lcnt = @locale;
        my $half = int(( 4 +  $lcnt ) / 2 );
        my $cnt = 2 * $half;

        my $line = '';
        for my $i ( 0 .. $cnt-1 ) {
            $line .= '| ' x ( $cnt - 1 - $i );
            $line .= '+';
            $line .= '-' x (2 * $i);
            $line .= '- ';

            if ( ($i % $half) < ($lcnt / 2) ) {
                my $locale = shift @locale;     # XXX: perhaps pop()
                $line .= "LC_ALL = $locale"
            } else {
                if ( $self->{perlio_only} ) {
                    $line .= "PERLIO = perlio"
                }
                else {
                    $line .= ( (($i - @{$self->{_locale}}) % $half) % 2 == 0 )
                        ? "PERLIO = perlio"
                        : "PERLIO = stdio ";
                }
            }
            $i < $half and $line .= " $debugging";
            $line .= "\n";
        }
        return $line;
    }

    my $locale = ''; # XXX
    my %l;
@l{qw( EOS EOaL EOpL EOaE EOpE )} = (<<"EOS", <<"EOaL", <<"EOpL", <<"EOaE", <<"EOpE");
| +--------- $debugging
+----------- no debugging

EOS
| | | | | +- LC_ALL = $locale $debugging
| | | | +--- PERLIO = perlio $debugging
| | | +----- PERLIO = stdio  $debugging
| | +------- LC_ALL = $locale
| +--------- PERLIO = perlio
+----------- PERLIO = stdio

EOaL
| | | +----- LC_ALL = $locale $debugging
| | +------- PERLIO = perlio $debugging
| +--------- LC_ALL = $locale
+----------- PERLIO = perlio

EOpL
| | | +----- PERLIO = perlio $debugging
| | +------- PERLIO = stdio  $debugging
| +--------- PERLIO = perlio
+----------- PERLIO = stdio

EOaE
| +--------- PERLIO = perlio $debugging
+----------- PERLIO = perlio

EOpE
    return  $self->{perlio_only}
        ? $locale ? $l{EOaL} : $self->{defaultenv} ? $l{EOS} : $l{EOaE}
        : $locale ? $l{EOpL} : $self->{defaultenv} ? $l{EOS} : $l{EOpE};
}

=head2 $reporter->letter_legend( )

Returns a string with the legend for the letters in the matrix.

=cut

sub letter_legend {
    require Test::Smoke::Smoker;
    return <<__EOL__
O = OK  F = Failure(s), extended report at the bottom
X = Failure(s) under TEST but not under harness
? = still running or test results not (yet) available
Build failures during:       - = unknown or N/A
c = Configure, m = make, M = make (after miniperl), t = make test-prep
__EOL__
}

=head2 $reporter->signature()

Returns the signature for the e-mail message (starting with dash dash space
newline) and some version numbers.

=cut

sub signature {
    my $self = shift;
    my $this_pver = $^V ? sprintf "%vd", $^V : $];
    my $build_info = "$Test::Smoke::VERSION";

    my $signature = <<"    __EOS__";
-- 
Report by Test::Smoke v$build_info running on perl $this_pver
(Reporter v$VERSION / Smoker v$Test::Smoke::Smoker::VERSION)
    __EOS__

    if ($self->{un_position} ne USERNOTE_ON_TOP) {
        (my $user_note = $self->{user_note}) =~ s/(?<=\S)\s*\z/\n/;
        $signature = "\n$user_note\n$signature";
    }

    return $signature;
}

1;

=head1 SEE ALSO

L<Test::Smoke::Smoker>

=head1 COPYRIGHT

(c) 2002-2012, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>
  * H.Merijn Brand <hmbrand@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * http://www.perl.com/perl/misc/Artistic.html

=item * http://www.gnu.org/copyleft/gpl.html

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
