package VCS::CMSynergy::Client;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

=head1 NAME

VCS::CMSynergy::Client - base class for Synergy methods that don't require a session

=head1 SYNOPSIS

  use VCS::CMSynergy::Client;

  $client = VCS::CMSynergy::Client->new(%attr);

  $ary_ref = $client->ps;
  $short_version = $client->version;
  @ary = $client->status;

  @ary = $client->databases;
  @ary = $client->hostname;

This synopsis only lists the major methods.

=cut

use 5.008_001;                                  # i.e. v5.8.1
use strict;
use warnings;

use Carp;
use Config;
use Cwd;
use File::Spec;
use IPC::Run3;
use Log::Log4perl qw(:easy);

use Exporter();
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( is_win32 _fullwin32path _pathsep $Error $Ccm_command _error );

use constant is_win32 => $^O eq 'MSWin32' || $^O eq 'cygwin';
use constant _pathsep => is_win32 ? "\\" : "/" ;

our ($Error, $Ccm_command, $Default);

# not a method
# emulates the old way to enable tracing by setting the environment
# variable CMSYNERGY_TRACE
sub _init_legacy_logging
{
    # NOTE: Log::Log4perl can only be initialized once (i.e. the second
    # call to Log::Log4perl::init() overwrites the setting from the first).
    # Hence, don't mess up an existing setting.
    return if Log::Log4perl->initialized;

    my $trace = $ENV{CMSYNERGY_TRACE};
    return unless defined $trace && length $trace;

    my %init;                           # default layout => "%d %m%n"
    if ($trace =~ /^\d+$/)              # CMSYNERGY_TRACE="digits"
    {
        $init{file} = "STDERR";
    }
    elsif ($trace =~ /^(\d+)=(.*)/)     # CMSYNERGY_TRACE="digits=filename"
    {
        $trace = $1;
        $init{file} = ">>$2";
    }
    else                                # CMSYNERGY_TRACE="filename"
    {
        $trace = 2;
        $init{file} = ">>$trace";
    }
    $init{level} = $trace >= 8 ? $TRACE :
                   $trace >= 5 ? $DEBUG :
                   $trace >= 1 ? $INFO :
                   $OFF;

    Log::Log4perl->easy_init(\%init);
}

our %opts =
(
    HandleError         => undef,
    PrintError          => undef,
    RaiseError          => undef,
    CCM_HOME            => undef,
);


sub new
{
    my ($class, %args) = @_;

    my $self =
    {
        HandleError     => undef,
        PrintError      => 1,
        RaiseError      => 0,
        CCM_HOME        => $ENV{CCM_HOME},
        env             => {},
        ccm_command     => undef,
        error           => undef,
        out             => undef,
        err             => undef,
    };  
    bless $self, $class;

    while (my ($arg, $value) = each %args)
    {
        croak(__PACKAGE__."::new: unrecognized argument: $arg")
            unless exists $opts{$arg};

        $self->{$arg} = $value;
    }

    return $self->set_error("CCM_HOME is not set (neither as parameter to new() nor in environment")
        unless defined $self->{CCM_HOME};
    $self->{env}->{CCM_HOME} = delete $self->{CCM_HOME};

    my $ccm_exe = File::Spec->catfile(
        $self->{env}->{CCM_HOME}, "bin", "ccm$Config{_exe}");
    if ($^O eq 'cygwin')
    {
        # Cygwin: avoid potential "MS-DOS style path detected" warning
        run3 [ qw( cygpath --unix --absolute ), $ccm_exe ], \undef, \$ccm_exe, \undef;
        $ccm_exe =~ s/\015?\012\z//g;                   # OS agnostic chomp
    }
    return $self->set_error("CCM_HOME = `$self->{env}->{CCM_HOME}' does not point to a valid Synergy installation")
        unless -x $ccm_exe || ($^O eq 'cygwin' && -e $ccm_exe);
        # NOTE: -x $ccm_exe fails on cygwin
    $self->{ccm_exe} = $ccm_exe;

    _init_legacy_logging();

    return $self;
}


sub _memoize_method
{
    my ($class, $method, $code) = @_;
    croak(__PACKAGE__.qq[::_memoize_method: "$code" must be a CODE ref])
        unless ref $code eq "CODE";
    my $slot = $method;

    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::${method}"} = sub
    {
        my $self = shift;
        $self->{$slot} = &$code($self, @_) unless exists $self->{$slot};
        return $self->{$slot};
    };
}


sub start
{
    my ($this, %args) = @_;
    $this = __PACKAGE__->_default unless ref $this;

    return VCS::CMSynergy->_start($this, %args);
}


sub _default    { $Default ||= shift->new(); }


sub ccm                                         # class/instance method
{
    my $this = shift;
    $this = __PACKAGE__->_default unless ref $this;

    my ($rc, $out, $err) = $this->_ccm(@_);

    # Note: "defined wantarray" checks if we're called in non-void context
    return wantarray ? ($rc, $out, $err) : $rc == 0
        if defined wantarray;

    $this->set_error($err || $out) unless $rc == 0;
}


my $ccm_prompt = qr/^ccm> /m;           # NOTE the trailing blank

sub _ccm
{
    my $this = shift;
    my $opts = @_ && ref $_[-1] eq "HASH" ? pop : {};

    $Error = $this->{error} = undef;
    $Ccm_command = $this->{ccm_command} = join(" ", @_);


    my ($rc, $out, $err);
    my %default_opts = 
    (
        in      => \undef,
        out     => \$out,
        err     => \$err,
    );
    if ($this->{utf8})
    {
        $default_opts{$_} = ":utf8" foreach qw( binmode_stdin binmode_stdout binmode_stderr );
    }

    # let settings in %$opts override those in %default_opts
    my %run_opts = (%default_opts, %$opts);
    my ($run_in, $run_out, $run_err) = delete @run_opts{qw(in out err)};

    my $t0 = [ Time::HiRes::gettimeofday() ];

    # NOTE: Trace the command _before_ executing it to help
    # diagnose "hung" scripts (e.g. a ccm command waiting for
    # user confirmation)
    TRACE "<- ccm($this->{ccm_command})";

    CCM:
    {
        if ($this->{coprocess})
        {
            USE_COPROCESS:
            {
                # don't use copress when using fancy run3() arguments
                last USE_COPROCESS if %$opts;

                # arguments cannot contain newlines in "interactive" ccm sessions
                last USE_COPROCESS if grep { /\n/ } @_;

                my ($dev, $ino) = stat(".") or last USE_COPROCESS;
                if ($this->{co_cwd_dev} != $dev || $this->{co_cwd_ino} != $ino)
                {
                    # working directory has changed since coprocess was spawned:
                    # shut down coprocess and start a new one
                    # NOTE: don't call _ccm here (infinite recursion)
                    $this->_kill_coprocess;
                    unless ($this->_spawn_coprocess)
                    {
                        carp(__PACKAGE__ . " _ccm: can't re-establish coprocess (because cwd changed): $this->{error}\n" .
                             "-- ignoring UseCoprocess from now on");
                        last USE_COPROCESS;
                    }
                    TRACE sprintf("spawned new coprocess because cwd changed (pid=%d)",
                                  $this->{coprocess}->pid);
                }

                # NOTE: "interactive" command arguments that contain blanks must
                # be quoted with double quotes; AFAICT there is no way
                # to quote embedded quotes!
                $this->{coprocess}->print(
                    join(" ", map { qq["$_"] } @_), "\n");

                $this->{coprocess}->expect(undef, -re => $ccm_prompt)
                    or return _error("expect error: ".$this->{coprocess}->error);

                # on Windows, treat output as if read in "text" mode
                $$run_out = $this->{coprocess}->before;

                $this->{coprocess}->print("set error\n");
                $this->{coprocess}->expect(undef, -re => $ccm_prompt)
                    or return _error("expect error: ".$this->{coprocess}->error);
                my $set = $this->{coprocess}->before;
                ($rc) = $set =~ /^(\d+)/
                    or return _error("unrecognized result from `set error': $set");
                ($rc, $$run_err) = ($rc << 8, "");         # fake $?
                last CCM;
            }
        }

        # simple ccm sub process
        $rc = $this->run([ $this->ccm_exe, @_ ], 
                         $run_in, $run_out, $run_err, \%run_opts);
    }

    unless (exists $opts->{out})
    {
        $$run_out =~ s/\015\012/\012/g if is_win32;     # as if read in :crlf mode
        $$run_out =~ s/\n\z//;                          # chomp
    }
    unless (exists $opts->{err})
    {
        $$run_err =~ s/\015\012/\012/g if is_win32;     # as if read in :crlf mode
        $$run_err =~ s/\n\z//;                          # chomp
    }

    if (Log::Log4perl->initialized)
    {
        # Note: Calling "easy" functions like TRACE() is always OK, even if
        # Log::Log4perl has never been initialized or has already been
        # cleaned up (e.g. during VCS::CMSynergy::DESTROY called in
        # Perl's global cleanup). But get_logger() will fail in these
        # circumstances.
        my $elapsed = sprintf("%.2f", Time::HiRes::tv_interval($t0));
        if (get_logger()->is_trace)
        {
            TRACE "-> rc = $rc [$elapsed sec]";
            TRACE "-> out = \"$$run_out\"\n" unless exists $opts->{out};
            TRACE "-> err = \"$$run_err\"\n" unless exists $opts->{err};
        }
        else
        {
            my $success = $rc == 0 ? "ok" : "failed";
            DEBUG "ccm($this->{ccm_command}) = $success [$elapsed sec]\n";
        }
    }

    $this->{out} = $$run_out unless exists $opts->{out};
    $this->{err} = $$run_err unless exists $opts->{err};

    return ($rc, 
            exists $opts->{out} ? undef : $$run_out, 
            exists $opts->{err} ? undef : $$run_err);
}

sub run
{
    my $this = shift;
    $this = __PACKAGE__->_default unless ref $this;

    # augment %ENV
    my $env = $this->{env};
    local @ENV{keys %$env} = values %$env if defined $env;

    # don't screw up global $? (e.g. when being called
    # in VCS::CMSynergy::DESTROY at program termination)
    local $?;                   
    run3(@_);
    return $?;
}

sub _spawn_coprocess
{
    my $self = shift;

    unless (eval "use Expect 1.15; 1")
    {
        $Error = $self->{error} = $@;
        return;
    }

    # augment %ENV
    my $env = $self->{env};
    local @ENV{keys %$env} = values %$env if defined $env;

    my $exp = Expect->new
        or $Error = $self->{error} = "Expect->new failed", return;
    ($exp->log_stdout(0) && $exp->slave->set_raw && $exp->set_raw)
        or $Error = $self->{error} = $exp->exp_error, return;
    $exp->spawn($self->ccm_exe)
        or $Error = $self->{error} = $exp->exp_error, return;

    # look for initial "ccm> " prompt
    $exp->expect(undef, -re => $ccm_prompt)
        or $Error = $self->{error} = $exp->exp_error, return;

    $self->{coprocess} = $exp;

    # remember coprocess' working directory
    # (so that we can detect whether the current working directory
    # of the main process has diverged)
    @$self{qw/co_cwd_dev co_cwd_ino/} = stat(".");

    return 1;
}

sub _kill_coprocess
{
    my $self = shift;
    $self->{coprocess}->print("exit\n");
    # FIXME: kill it just for paranoia (must save pid before line above!)
    $self->{coprocess} = undef;
}

# helper: create a fake triple ($rc, $out, $err) as returned from _cmd()
sub _error      { return (255 << 8, "", $_[0]) }

# helper (only meaningful on Cygwin):
# convert a potentially unixish path into its Windows equivalent (typically
# because we want to pass it to a native Windows program like ccm.exe)
sub _fullwin32path
{
    my ($path) = @_;
    my $out;
    run3 [ qw( cygpath --windows --absolute ), $path ], \undef, \$out, \undef;
    $out =~ s/\015?\012\z//g;                   # OS agnostic chomp
    return $out;
}


sub error
{
    my $this = shift;
    return ref $this ? $this->{error} : $Error;
}

sub ccm_command
{
    my $this = shift;
    return ref $this ? $this->{ccm_command} : $Ccm_command;
}

sub ccm_home                                    # class/instance method
{
    my $this = shift;
    $this = __PACKAGE__->_default unless ref $this;
    return $this->{env}->{CCM_HOME};
}

sub ccm_exe                                     # class/instance method
{
    my $this = shift;
    $this = __PACKAGE__->_default unless ref $this;
    return $this->{ccm_exe};
}

sub out                                         # class/instance method
{
    my $this = shift;
    $this = __PACKAGE__->_default unless ref $this;
    return wantarray ? split(/\n/, $this->{out}) : $this->{out};
}

sub err                                         # class/instance method
{
    my $this = shift;
    $this = __PACKAGE__->_default unless ref $this;
    return $this->{err};
}

# NOTE: we can't memoize "version", as the memoizing wrapper
# assumes an object (not a class) as invocant
sub version                                     # class/instance method
{
    my $this = shift;
    $this = __PACKAGE__->_default unless ref $this;

    my $version = $this->_version;
    return @$version{qw(cmsynergy schema informix patches)} if wantarray;
    return $version->{short};
}

__PACKAGE__->_memoize_method(_version => sub
{
    my $self = shift;

    # "version" is not a recognized "interactive" command
    local $self->{coprocess} = undef;

    my ($rc, $out, $err) = $self->_ccm(qw/version -all/);
    return $self->set_error($err || $out) unless $rc == 0;

    my %version;
    my $cmsynergy_rx = qr{(?:CM Synergy|SYNERGY/CM|Telelogic Synergy|IBM Rational Synergy)};
    ($version{cmsynergy}) = $out =~ /^$cmsynergy_rx Version\s+(\S*)$/imo
        or return $self->set_error("can't recognize version from `$out'");
    ($version{short}) = $version{cmsynergy} =~ /^(\d+\.\d+)/;

    ($version{schema}) = $out =~ /^$cmsynergy_rx Schema Version\s+(.*)$/imo;
    ($version{informix}) = $out =~ /^Informix.* Version\s+(.*)$/imo;
    $version{patches} = [ split(/\n/, $1) ]
        if $out =~ /^$cmsynergy_rx Patch Version\s+(.*?)(?:\Z|^$cmsynergy_rx|^Informix)/imso;
    return \%version;
});


sub ps  
{
    my ($this, @filter) = @_;
    $this = __PACKAGE__->_default unless ref $this;

    # "ps" is not a recognized "interactive" command
    local $this->{coprocess} = undef;

    my ($rc, $out, $err) = $this->_ccm(qw/ps/, @filter);
    return $this->set_error($err || $out) unless $rc == 0;

    # split at "rfc address..." header lines;
    # discard first item (the line "All Rfc processes..." or
    # "Processes with...")
    # NOTE: We do it this way (and not by splitting into lines
    # first, then recognizing "rfc address..." lines as
    # record headers) to work around a Synergy glitch:
    # if the single line in $CCM_HOME/etc/.router.adr ends with
    # a newline, then the record for the router process
    # will look like:
    #   rfc address (macarthur:5418:127.0.1.1:192.168.57.10
    #   )
    #         process (router)
    #         user (ccm_root)
    # i.e. the address contains an embedded newline. This
    # breaks line-based parsing.
    my @rfcs = split(/^rfc address \((.*?)\)/sm, $out);
    shift @rfcs;        

    my @ps;
    while (@rfcs)
    {
        my ($rfc_address, $rest) = splice @rfcs, 0, 2;
        chomp ($rfc_address, $rest);

        my %fields = $rest =~ /^\t(\S+) \((.*?)\)/gm;

        # the ps entry for the objreg process contains lines of the form
        #   db:/var/lib/telelogic/ccm65/tutorial_pre64sp1/db ()
        # transform the (database) paths into a list
        # as the value of key "db"
        my @dbs;
        foreach my $key (keys %fields)
        {
            if ($key =~ /^db:(.*)$/)
            {
                push @dbs, $1;
                delete $fields{$key};
            }
        }

        $fields{rfc_address} = $rfc_address;
        $fields{db} = \@dbs if @dbs;

        push @ps, \%fields;
    }

    return \@ps;
}


sub status      
{
    my $this = shift;
    $this = __PACKAGE__->_default unless ref $this;

    my ($rc, $out, $err) = $this->_ccm(qw/status/);
    return $this->set_error($err || $out) unless $rc == 0;

    my (@sessions, $session, $user);
    foreach (split(/\n/, $out))
    {
        if (/sessions for user (\S+):/i)
        {
            $user = $1;
            next;
        }
        if (my ($interface, $rfc_address) = /^(.*?) interface \@ (\S+)/i)
        {
            # start of a session description;
            # convert interface to process name used by `ccm ps'
            $session =
            {
                process         => $interface =~ /graphical/i ?
                                     "gui_interface" : "cmd_interface",
                rfc_address     => $rfc_address,
                user            => $user,
            };
            push @sessions, $session;
            next;
        }
        if (/^database: (.*)/i && $session)
        {
            # sanitize database path (all other Synergy information commands
            # show it with trailing "/db", so we standardize on that)
            # NOTE: careful here, because the database might reside on Windows
            ($session->{database} = $1)                 
                =~ s{^(.)(.*?)(\1db)?$}{$1$2$1db};
            next;
        }
    }
    return \@sessions;
}


# FIXME does not work on Windows
# (in fact, it only works on the host where Synergy's Informix engine is running)
sub databases   
{
    my ($this, $servername) = @_;
    $this = __PACKAGE__->_default unless ref $this;

    my @server_status =
        (File::Spec->catfile($this->ccm_home, qw/bin ccmsrv/), qw/status/);
    push @server_status, -s => $servername if defined $servername;

    my ($out, $err);
    my $rc = $this->run(\@server_status, \undef, \$out, \$err);
    chomp ($out, $err);
    return $this->set_error($err || $out) unless $rc == 0;

    # strip leading/trailing stuff
    my ($list) = $out =~ /^===.*?$(.*?)^There is a total/ms;
    return $this->set_error(qq[unrecognized output from "@server_status": $out])
        unless defined $list;
    return grep { !/dbpath not available/ }
           map  { (split(' ', $_, 3))[2]  }
           split(/\n/, $list);
}

# FIXME does not work on windows
sub hostname
{
    my ($this, @filter) = @_;
    $this = __PACKAGE__->_default unless ref $this;

    our %Hostname;                              # cache by CCM_HOME
    my $ccm_home = $this->ccm_home;
    unless (exists $Hostname{$ccm_home})
    {
        my ($out, $err);
        my $rc = $this->run([ File::Spec->catfile($ccm_home, qw/bin util ccm_hostname/) ], \undef, \$out, \$err);
        chomp($out, $err);
        # ignore bogus exit code (seems to be length of output in bytes, arghh)
        $Hostname{$ccm_home} = $out;
    }

    return $Hostname{$ccm_home};
}


sub set_error
{
    my ($this, $error, $method, $rv, @rv) = @_;

    $Error = $this->{error} = $error;

    # try the HandleError routine if one was provided;
    # consider the error handled if it returns true
    my $handler = $this->{HandleError};
    return wantarray ? @rv : $rv if $handler and &$handler($error, $this, $rv, @rv);

    # unless $method was explicitly specified, use our caller
    # except skip private methods of VCS::CMsynergy... packages
    unless (defined $method)
    {
        $method = (caller(0))[3];
        for (my $n = 1;; $n++)
        {
            my $next = (caller($n))[3];
            last unless defined $next;
            $method = $next;
            last unless $method =~ /^VCS::CMSynergy.*::_\w*$/;
        }
    }

    my $msg = "$method: $error";
    croak($msg) if $this->{RaiseError}; 
    carp($msg)  if $this->{PrintError};
    return wantarray ? @rv : $rv;
}

1;

__END__

=head1 DESCRIPTION

In most cases there is no need to know about C<VCS::CMSynergy::Client>,
the base class of L<VCS::CMSynergy>.
If you have an established session, you can
invoke all methods on the session object. If you want to use a method
without a session (e.g. L</ps>), invoke it as a class method:

  $ps = VCS::CMSynergy->ps;

You need to use C<VCS::CMSynergy::Client> explicitly if

=over 4

=item *

you want to use a method without a session I<and>

=item *

you have several installations of Synergy, i.e. several C<$CCM_HOME>s, I<and>

=item *

you want to switch between different C<$CCM_HOME>s in the same
invocation of your program.

=back

A typical example is an administrative program that iterates over all
your Synergy databases in all your installations:

  foreach my $ccm_home (qw(/usr/local/ccm51 /usr/local/ccm62 /usr/local/ccm63))
  {
      print "installation in $ccm_home ...\n";
      my $client = VCS::CMSynergy::Client->new(CCM_HOME => $ccm_home);

      foreach my $db ($client->databases)
      {
          ...
      }
  }

All methods below (except C<new>) can be invoked on either:

=over 4

=item *

a C<VCS::CMSynergy::Client> object

=item *

a C<VCS::CMSynergy> object

=item *

the C<VCS::CMSynergy::Client> class

=item *

the C<VCS::CMSynergy> class

=back

The former two always use the setting of C<CCM_HOME> given at their creation,
while the latter two actually operate on a "default" instance of  C<VCS::CMSynergy::Client>.
This instance is created the first time
any C<VCS::CMSynergy::Client> or C<VCS::CMSynergy> class method is invoked
in the course of your program. Its C<CCM_HOME> uses
the value of C<$ENV{CCM_HOME}> that was in effect at the time
the default instance was created.

=head1 METHODS

=head2 new

  my $client = VCS::CMSynergy::Client->new( CCM_HOME => "/usr/local/ccm62" );

Creates a new Synergy client.

If it fails (e.g. CCM_HOME doesn't seem to contain a valid
Synergy installation), it returns C<undef>.

C<new> is called with an attribute hash. The following attributes
are currently supported:

=over 4

=item C<CCM_HOME> (string)

Value of the C<CCM_HOME> environment variable to use for this client.

It defaults from the environment variable of the same name,
i.e. C<$ENV{CCM_HOME}>.

=item C<PrintError> (boolean)

This attribute can be used to force errors to generate warnings (using
L<carp|Carp/carp>) in addition to returning error codes in the normal way.
When set to true, any method which results in an error occurring will cause
the corresponding C<< $ccm->error >> to be printed to stderr.

It defaults to "on".

=item C<RaiseError> (boolean)

This attribute can be used to force errors to raise exceptions
(using L<croak|Carp/croak>) rather than simply return error codes
in the normal way.
When set to true, any method which results in an error will cause
effectively a C<die> with the actual C<< $ccm->error >>
as the message.

It defaults to "off".

=item C<HandleError> (code ref)

This attribute can be used to provide your own
alternative behavior in case of errors. If set to a
reference to a subroutine then that subroutine is called
when an error is detected (at the same point that
L</RaiseError> and L</PrintError> are handled).

See the L<< VCS::CMSynergy/C<HandleError> (code ref) >> for details.

=back

=head2 ccm_home

  print "CCM_HOME=", $client->ccm_home;

Returns the setting of CCM_HOME as used by the client.

=head2 error

  $last_error = $client->error;

Returns the last error that occurred in this client.

=head2 ccm_command

  $last_cmsynergy_command = $client->ccm_command;

Returns the last Synergy command invoked on behalf of the
C<VCS::CMSynergy::Client>.

=head2 out

Returns the raw standard output of the last Synergy command invoked
on behalf of the C<VCS::CMSynergy::Client>.
In scalar context the output is returned as a possibly multi-line string.
In list context it is returned as an array of pre-chomped lines.

=head2 err

Returns the raw standard error of the last Synergy command invoked
on behalf of the C<VCS::CMSynergy::Client>.
The return value is a possibly multi-line string regardless of calling context.

=head2 ps

  $ary_ref = $client->ps;
  $ary_ref = $client->ps(user => "jdoe", process => "gui_interface", ...);

Executes B<ccm ps> and returns a reference to an array of references,
one per Synergy process. Each reference points to a hash
containing pairs of field names (e.g. C<host>, C<database>, C<pid>) and values
for that particular process as listed by B<ccm ps>.

The available keys vary with the type of the process
(e.g. C<engine>, C<gui_interface>). The process type is listed
under key C<process>.  The key C<rfc_address> is always present.
The object registrar (i.e. the unique process with key C<process>
equal to "objreg") has a special key C<db>.
Its value is a reference to an array of database names
that the registrar as encountered during its lifetime.

In the second form of invocation, you can pass pairs of field name
and field value and C<ps> will only return processes whose fields
match I<all> the corresponding values.

Here's an example of the value returned by C<ps>
as formatted by L<Data::Dumper>:

  $ps = [
      {
        'process' => 'router',
        'host' => 'tiv01',
        'rfc_address' => 'tiv01:5415:160.50.76.15',
        'user' => 'ccm_root',
        'host_addr' => '',
        'pid' => '9428'
      },
      {
        'process' => 'gui_interface',
        'database' => '/ccmdb/tbd/slc/db',
        'engine_address' => 'tiv01:60682:160.50.76.15',
        'host' => 'lapis',
        'user' => 'q076273',
        'msg_handler_1' => 'uissys:message_handler',
        'display' => '',
        'callback' => 'vistartup:cb_init',
        'rfc_address' => 'lapis:1934:160.50.136.36',
        'pid' => '224',
        'host_addr' => ''
      },
      {
        'process' => 'engine',
        'database' => '/ccmdb/tbd/nasa_ix/db',
        'host' => 'nasaora',
        'user' => 'qx06322',
        'callback' => 'engine_startup:cb_init',
        'rfc_address' => 'nasaora:1559:160.48.78.33',
        'pid' => '24490',
        'host_addr' => '',
        'ui_address' => 'nasaora:1556:160.48.78.33'
      },
      {
        'process' => 'objreg',
        'db' => [
                  '/ccmdb/tbd/slc/db',
                  '/ccmdb/tbd/eai/db',
                  ...
                ],
        'max_conns' => '256',
        'objreg_machine_addr' => '160.50.76.15',
        'host' => 'tiv01',
        'user' => 'ccm_root',
        'callback' => 'objreg:cb_init',
        'policy' => 'one_per_db',
        'noblock' => 'true',
        'rfc_address' => 'tiv01:60352:160.50.76.15',
        'objreg_machine' => 'tiv01',
        'host_addr' => '',
        'pid' => '9896',
        'objreg_machine_hostname' => 'tiv01'
      },
      ...
  ];

=head2 status

  $ary_ref = $client->status;

Executes B<ccm status> and returns a reference to an array of references,
one per Synergy session. Each reference points to a hash
containing pairs of field names (e.g. C<database>) and values
for that particular session.

The available keys are a subset of the keys returned by the
L</ps> method: C<rfc_address>, C<database>, C<user>, and C<process>.

Note: Unlike the output of the B<ccm status> command, the value
for C<database> has a trailing C<"/db">. This makes it consistent
with the session attribute C<database> and the return value of L</ps>.

Here's an example of the value returned by C<status>
as formatted by L<Data::Dumper>:

  $status = [
      {
        'process' => 'gui_interface',
        'database' => '/ccmdb/scm/support/db',
        'rfc_address' => 'tiv01:53020:160.50.76.15',
        'user' => 'rschupp'
      },
      {
        'process' => 'gui_interface',
        'database' => '/ccmdb/scm/support/db',
        'rfc_address' => 'wmuc111931:4661:160.50.136.201',
        'user' => 'rschupp'
      },
      {
        'process' => 'cmd_interface',
        'database' => '/ccmdb/test/tut51/db',
        'rfc_address' => 'tiv01:53341:160.50.76.15',
        'user' => 'rschupp'
      }
  ];

=head2 version

  $short_version = $client->version;
  ($full_version, $schema_version,
    $informix_version, @patches) = $client->version;

Returns version info about the Synergy installation.
In a scalar context C<version> returns the (short) Synergy version number,
e.g. "6.2". In an array context the following information is returned:

=over 4

=item *

the full Synergy version (e.g. "6.2.3041")

=item *

the database schema version (e.g. "6.2")

=item *

the Informix version (e.g. "9.21.UC3X6")

=item *

a possible empty array of applied Synergy patches

=back

=head2 ccm_exe

Returns the absolute pathname of the B<ccm> executable.

=head2 set_error

  $ccm->set_error($error);
  $ccm->set_error($error, $method);
  $ccm->set_error($error, $method, $rv, @rv);

Set the L</error> value for the session to C<$error>.
This will trigger the normal DBI error handling
mechanisms, such as L</RaiseError> and L</HandleError>, if
they are enabled.  This method is typically only used internally.

The C<$method> parameter provides an alternate method name
for the L</RaiseError>/L</PrintError> error string.
Normally the method name is deduced from C<caller(1)>.

The L</set_error> method normally returns C<undef>.  The C<$rv>and C<@rv>
parameters provides an alternate return value if L</set_error> was
called in scalar or in list context, resp.

=head2 run

  $client->run(\@cmd, $in, $out, $err);

Runs C<run3> from L<IPC::Run3> with the given arguments in an
environment (C<$ENV{CCM_HOME}>, C<$ENV{PATH> etc) set up for C<$client>.
Returns the exit status (i.e. C<$?>) from executing C<@cmd>.

=head2 databases

  @databases = $client->databases;
  @databases = $client->databases($servername);

Returns an array containing the names of all known Synergy databases.

Note: This method does not work on Windows.

=head2 hostname

  $hostname = $client->hostname.

The hostname as returned by B<ccm_hostname> (which might be different
from what L<POSIX/uname> returns).

=head1 SEE ALSO

L<VCS::CMSynergy>,
L<VCS::CMSynergy::Object>

=head1 AUTHORS

Roderich Schupp, argumentum GmbH <schupp@argumentum.de>

=cut

