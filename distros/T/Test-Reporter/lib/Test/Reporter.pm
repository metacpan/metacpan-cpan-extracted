use 5.006;
use strict;
use warnings;
package Test::Reporter;

our $VERSION = '1.62';

use Cwd;
use Config;
use Carp;
use FileHandle;
use File::Temp;
use Sys::Hostname;
use Time::Local ();
use vars qw($AUTOLOAD $Tempfile $Report $DNS $Domain $Send);
use constant FAKE_NO_NET_DNS => 0;    # for debugging only
use constant FAKE_NO_NET_DOMAIN => 0; # for debugging only
use constant FAKE_NO_MAIL_SEND => 0;  # for debugging only

local $^W = 1;

sub new {
    my $type  = shift;
    my $class = ref($type) || $type;
    my $self  = {
        '_grade'             => undef,
        '_distribution'      => undef,
        # XXX distfile => undef would break old clients :-( -- dagolden, 2009-03-30
        '_distfile'          => '',
        '_report'            => undef,
        '_subject'           => undef,
        '_from'              => undef,
        '_comments'          => '',
        '_errstr'            => '',
        '_via'               => '',
        '_timeout'           => 120,
        '_debug'             => 0,
        '_dir'               => '',
        '_subject_lock'      => 0,
        '_report_lock'       => 0,
        '_perl_version'      => {
            '_archname' => $Config{archname},
            '_osvers'   => $Config{osvers},
        },
        '_transport'         => '',
        '_transport_args'    => [],
        # DEPRECATED ARGS
        '_address'           => 'cpan-testers@perl.org',
        '_mx'                => ['mx.develooper.com'],
        '_mail_send_args'    => '',
    };

    bless $self, $class;

    $self->{_perl_version}{_myconfig} = $self->_get_perl_V;
    $self->{_perl_version}{_version} = $self->_normalize_perl_version;

    $self->{_attr} = {
        map {$_ => 1} qw(
            _address _distribution _distfile _comments _errstr _via _timeout _debug _dir
        )
    };

    warn __PACKAGE__, ": new\n" if $self->debug();
    croak __PACKAGE__, ": new: even number of named arguments required"
        unless scalar @_ % 2 == 0;

    $self->_process_params(@_) if @_;
    $self->transport('Null') unless $self->transport();
    $self->_get_mx(@_) if $self->_have_net_dns();

    return $self;
}

sub debug {
    my $self = shift;
    return $self->{_debug};
}

sub _get_mx {
    my $self = shift;
    warn __PACKAGE__, ": _get_mx\n" if $self->debug();

    my %params = @_;

    return if exists $params{'mx'};

    my $dom = $params{'address'} || $self->address();
    my @mx;

    $dom =~ s/^.+\@//;

    for my $mx (sort {$a->preference() <=> $b->preference()} Net::DNS::mx($dom)) {
        push @mx, $mx->exchange();
    }

    if (not @mx) {
        warn __PACKAGE__,
            ": _get_mx: unable to find MX's for $dom, using defaults\n" if
                $self->debug();
        return;
    }

    $self->mx(\@mx);
}

sub _process_params {
    my $self = shift;
    warn __PACKAGE__, ": _process_params\n" if $self->debug();

    my %params   = @_;
    my @defaults = qw(
        mx address grade distribution distfile from comments via timeout debug dir perl_version transport_args transport );
    my %defaults = map {$_ => 1} @defaults;

    for my $param (keys %params) {
        croak __PACKAGE__, ": new: parameter '$param' is invalid." unless
            exists $defaults{$param};
    }

    # XXX need to process transport_args directly rather than through
    # the following -- store array ref directly
    for my $param (keys %params) {
        $self->$param($params{$param});
    }
}

sub subject {
    my $self = shift;
    warn __PACKAGE__, ": subject\n" if $self->debug();
    croak __PACKAGE__, ": subject: grade and distribution must first be set"
        if not defined $self->{_grade} or not defined $self->{_distribution};

    return $self->{_subject} if $self->{_subject_lock};

    my $subject = uc($self->{_grade}) . ' ' . $self->{_distribution} .
        " $self->{_perl_version}->{_archname} $self->{_perl_version}->{_osvers}";

    return $self->{_subject} = $subject;
}

sub report {
    my $self = shift;
    warn __PACKAGE__, ": report\n" if $self->debug();

    return $self->{_report} if $self->{_report_lock};

    my $report;
    $report .= "This distribution has been tested as part of the CPAN Testers\n";
    $report .= "project, supporting the Perl programming language.  See\n";
    $report .= "http://wiki.cpantesters.org/ for more information or email\n";
    $report .= "questions to cpan-testers-discuss\@perl.org\n\n";

    if (not $self->{_comments}) {
        $report .= "\n\n--\n\n";
    }
    else {
        $report .= "\n--\n" . $self->{_comments} . "\n--\n\n";
    }

    $report .= $self->{_perl_version}->{_myconfig};

    chomp $report;
    chomp $report;

    return $self->{_report} = $report;
}

sub grade {
    my ($self, $grade) = @_;
    warn __PACKAGE__, ": grade\n" if $self->debug();

    my %grades    = (
        'pass'    => "all tests passed",
        'fail'    => "one or more tests failed",
        'na'      => "distribution will not work on this platform",
        'unknown' => "distribution did not include tests",
    );

    return $self->{_grade} if scalar @_ == 1;

    croak __PACKAGE__, ":grade: '$grade' is invalid, choose from: " .
        join ' ', keys %grades unless $grades{$grade};

    return $self->{_grade} = $grade;
}

sub transport {
  my $self = shift;
    warn __PACKAGE__, ": transport\n" if $self->debug();

    return $self->{_transport} unless scalar @_;

    my $transport = shift;

    my $transport_class = "Test::Reporter::Transport::$transport";
    unless ( eval "require $transport_class; 1" ) { ## no critic
        croak __PACKAGE__ . ": could not load '$transport_class'\n$@\n";
    }

    my @args = @_;

    # XXX keep this for legacy support
    if ( @args && $transport eq 'Mail::Send' && ref $args[0] eq 'ARRAY' ) {
        # treat as old form of Mail::Send arguments and convert to list
        $self->transport_args(@{$args[0]});
    }
    elsif ( @args ) {
        $self->transport_args(@args);
    }

    return $self->{_transport} = $transport;
}

sub edit_comments {
    my($self, %args) = @_;
    warn __PACKAGE__, ": edit_comments\n" if $self->debug();

    my %tempfile_args = (
        UNLINK => 1,
        SUFFIX => '.txt',
        EXLOCK => 0,
    );

    if (exists $args{'suffix'} && defined $args{'suffix'} && length $args{'suffix'}) {
        $tempfile_args{SUFFIX} = $args{'suffix'};
        # prefix the extension with a period, if the user didn't.
        $tempfile_args{SUFFIX} =~ s/^(?!\.)(?=.)/./;
    }

    ($Tempfile, $Report) = File::Temp::tempfile(%tempfile_args);

    print $Tempfile $self->{_comments};

    $self->_start_editor();

    my $comments;
    {
        local $/;
        open my $fh, "<", $Report or die __PACKAGE__, ": Can't open comment file '$Report': $!";
        $comments = <$fh>;
        close $fh or die __PACKAGE__, ": Can't close comment file '$Report': $!";
    }

    chomp $comments;

    $self->{_comments} = $comments;

    return;
}

sub send {
    my ($self) = @_;
    warn __PACKAGE__, ": send\n" if $self->debug();

    $self->from();
    $self->report();
    $self->subject();

    return unless $self->_verify();

    if ($self->_is_a_perl_release($self->distribution())) {
        $self->errstr(__PACKAGE__ . ": use perlbug for reporting test " .
            "results against perl itself");
        return;
    }

    my $transport_type  = $self->transport() || 'Null';
    my $transport_class = "Test::Reporter::Transport::$transport_type";
    my $transport = $transport_class->new( $self->transport_args() );

    unless ( eval { $transport->send( $self ) } ) {
        $self->errstr(__PACKAGE__ . ": error from '$transport_class:'\n$@\n");
        return;
    }

    return 1;
}

sub _normalize_perl_version {
  my $self = shift;
  my $perl_version = sprintf("v%vd",$^V);
  my $perl_V = $self->perl_version->{_myconfig};
  my ($rc) = $perl_V =~ /Locally applied patches:\n\s+(RC\d+)/m;
  $perl_version .= " $rc" if $rc;
  return $perl_version;
}

sub write {
    my $self = shift;
    warn __PACKAGE__, ": write\n" if $self->debug();

    my $from = $self->from();
    my $report = $self->report();
    my $subject = $self->subject();
    my $distribution = $self->distribution();
    my $grade = $self->grade();
    my $dir = $self->dir() || cwd;
    my $distfile = $self->{_distfile} || '';
    my $perl_version = $self->perl_version->{_version};

    return unless $self->_verify();

    $distribution =~ s/[^A-Za-z0-9\.\-]+//g;

    my($fh, $file); unless ($fh = $_[0]) {
        $file = "$grade.$distribution.$self->{_perl_version}->{_archname}.$self->{_perl_version}->{_osvers}.${\(time)}.$$.rpt";

        if ($^O eq 'VMS') {
            $file = "$grade.$distribution.$self->{_perl_version}->{_archname}";
            my $ext = "$self->{_perl_version}->{_osvers}.${\(time)}.$$.rpt";
            # only 1 period in filename
            # we also only have 39.39 for filename
            $file =~ s/\./_/g;
            $ext  =~ s/\./_/g;
            $file = $file . '.' . $ext;
        }

        $file = File::Spec->catfile($dir, $file);

        warn $file if $self->debug();
        $fh = FileHandle->new();
        open $fh, ">", $file or die __PACKAGE__, ": Can't open report file '$file': $!";
    }
    print $fh "From: $from\n";
    if ($distfile ne '') {
      print $fh "X-Test-Reporter-Distfile: $distfile\n";
    }
    print $fh "X-Test-Reporter-Perl: $perl_version\n";
    print $fh "Subject: $subject\n";
    print $fh "Report: $report";
    unless ($_[0]) {
        close $fh or die __PACKAGE__, ": Can't close report file '$file': $!";
        warn $file if $self->debug();
        return $file;
    } else {
        return $fh;
    }
}

sub read {
    my ($self, $file) = @_;
    warn __PACKAGE__, ": read\n" if $self->debug();

    # unlock these; if not locked later, we have a parse error
    $self->{_report_lock} = $self->{_subject_lock} = 0;

    my $buffer;

    {
        local $/;
        open my $fh, "<", $file or die __PACKAGE__, ": Can't open report file '$file': $!";
        $buffer = <$fh>;
        close $fh or die __PACKAGE__, ": Can't close report file '$file': $!";
    }

    # convert line endings
    my $CR   = "\015";
    my $LF   = "\012";
    $buffer =~ s{$CR$LF}{$LF}g;
    $buffer =~ s{$CR}{$LF}g;

    # parse out headers
    foreach my $line (split(/\n/, $buffer)) {
      if ($line =~ /^(.+):\s(.+)$/) {
        my ($header, $content) = ($1, $2);
        if ($header eq "From") {
          $self->{_from} = $content;
        } elsif ($header eq "Subject") {
          $self->{_subject} = $content;
          my ($grade, $distribution, $archname) = (split /\s/, $content)[0..2];
          $self->{_grade} = lc $grade;
          $self->{_distribution} = $distribution;
          $self->{_perl_version}{_archname} = $archname;
          $self->{_subject_lock} = 1;
        } elsif ($header eq "X-Test-Reporter-Distfile") {
          $self->{_distfile} = $content;
        } elsif ($header eq "X-Test-Reporter-Perl") {
          $self->{_perl_version}{_version} = $content;
        } elsif ($header eq "Report") {
          last;
        }
      }
    }

    # parse out body
    if ( $self->{_from} && $self->{_subject} ) {
      ($self->{_report}) = ($buffer =~ /^.+?Report:\s(.+)$/s);
      my ($perlv) = $self->{_report} =~ /(^Summary of my perl5.*)\z/ms;
      $self->{_perl_version}{_myconfig} = $perlv if $perlv;
      $self->{_report_lock} = 1;
    }

    # check that the full report was parsed
    if ( ! $self->{_report_lock} ) {
        die __PACKAGE__, ": Failed to parse report file '$file'\n";
    }

    return $self;
}

sub _verify {
    my $self = shift;
    warn __PACKAGE__, ": _verify\n" if $self->debug();

    my @undefined;

    for my $key (keys %{$self}) {
        push @undefined, $key unless defined $self->{$key};
    }

    $self->errstr(__PACKAGE__ . ": Missing values for: " .
        join ', ', map {$_ =~ /^_(.+)$/} @undefined) if
        scalar @undefined > 0;
    return $self->errstr() ? return 0 : return 1;
}

# Courtesy of Email::MessageID
sub message_id {
    my $self = shift;
    warn __PACKAGE__, ": message_id\n" if $self->debug();

    my $unique_value = 0;
    my @CHARS = ('A'..'F','a'..'f',0..9);
    my $length = 3;

    $length = rand(8) until $length > 3;

    my $pseudo_random = join '', (map $CHARS[rand $#CHARS], 0 .. $length), $unique_value++;
    my $user = join '.', time, $pseudo_random, $$;

    return '<' . $user . '@' . Sys::Hostname::hostname() . '>';
}

sub from {
    my $self = shift;
    warn __PACKAGE__, ": from\n" if $self->debug();

    if (@_) {
        $self->{_from} = shift;
        return $self->{_from};
    }
    else {
        return $self->{_from} if defined $self->{_from} and $self->{_from};
        $self->{_from} = $self->_mailaddress();
        return $self->{_from};
    }

}

sub mx {
    my $self = shift;
    warn __PACKAGE__, ": mx\n" if $self->debug();

    if (@_) {
        my $mx = shift;
        croak __PACKAGE__,
            ": mx: array reference required" if ref $mx ne 'ARRAY';
        $self->{_mx} = $mx;
    }

    return $self->{_mx};
}

# Deprecated, but kept for backwards compatibility
# Passes through to transport_args -- converting from array ref to list to
# store and converting from list to array ref to get
sub mail_send_args {
    my $self = shift;
    warn __PACKAGE__, ": mail_send_args\n" if $self->debug();
    croak __PACKAGE__, ": mail_send_args cannot be called unless Mail::Send is installed\n"
      unless $self->_have_mail_send();
    if (@_) {
        my $mail_send_args = shift;
        croak __PACKAGE__, ": mail_send_args: array reference required\n"
            if ref $mail_send_args ne 'ARRAY';
        $self->transport_args(@$mail_send_args);
    }
    return [ $self->transport_args() ];
}



sub transport_args {
    my $self = shift;
    warn __PACKAGE__, ": transport_args\n" if $self->debug();

    if (@_) {
        $self->{_transport_args} = ref $_[0] eq 'ARRAY' ? $_[0] : [ @_ ];
    }

    return @{ $self->{_transport_args} };
}

# quote for command-line perl
sub _get_sh_quote { ( ($^O eq "MSWin32") || ($^O eq 'VMS') ) ? '"' : "'" }


sub perl_version  {
    my $self = shift;
    warn __PACKAGE__, ": perl_version\n" if $self->debug();

    if( @_) {
        my $perl = shift;
        my $q = $self->_get_sh_quote;
        my $magick = int(rand(1000));                                 # just to check that we get a valid result back
        my $cmd  = "$perl -MConfig -e$q print qq{$magick\n\$Config{archname}\n\$Config{osvers}\n};$q";
        if($^O eq 'VMS'){
            my $sh = $Config{'sh'};
            $cmd  = "$sh $perl $q-MConfig$q -e$q print qq{$magick\\n\$Config{archname}\\n\$Config{osvers}\\n};$q";
        }
        my $conf = `$cmd`;
        chomp $conf;
        my %conf;
        ( @conf{ qw( magick _archname _osvers) } ) = split( /\n/, $conf, 3);
        croak __PACKAGE__, ": cannot get perl version info from $perl: $conf" if( $conf{magick} ne $magick);
        delete $conf{magick};
        $conf{_myconfig} = $self->_get_perl_V($perl);
        chomp $conf;
        $self->{_perl_version} = \%conf;
   }
   return $self->{_perl_version};
}

sub _get_perl_V {
    my $self = shift;
    my $perl = shift || qq{"$^X"};
    my $q = $self->_get_sh_quote;
    my $cmdv = "$perl -V";
    if($^O eq 'VMS'){
        my $sh = $Config{'sh'};
        $cmdv = "$sh $perl $q-V$q";
    }
    my $perl_V = `$cmdv`;
    chomp $perl_V;
    return $perl_V;
}

sub AUTOLOAD {
    my $self               = $_[0];
    my ($package, $method) = ($AUTOLOAD =~ /(.*)::(.*)/);

    return if $method =~ /^DESTROY$/;

    unless ($self->{_attr}->{"_$method"}) {
        croak __PACKAGE__, ": No such method: $method; aborting";
    }

    my $code = q{
        sub {
            my $self = shift;
            warn __PACKAGE__, ": METHOD\n" if $self->{_debug};
            $self->{_METHOD} = shift if @_;
            return $self->{_METHOD};
        }
    };

    $code =~ s/METHOD/$method/g;

    {
        no strict 'refs';
        *$AUTOLOAD = eval $code; ## no critic
    }

    goto &$AUTOLOAD;
}

sub _have_net_dns {
    my $self = shift;
    warn __PACKAGE__, ": _have_net_dns\n" if $self->debug();

    return $DNS if defined $DNS;
    return 0 if FAKE_NO_NET_DNS;

    $DNS = eval {require Net::DNS};
}

sub _have_net_domain {
    my $self = shift;
    warn __PACKAGE__, ": _have_net_domain\n" if $self->debug();

    return $Domain if defined $Domain;
    return 0 if FAKE_NO_NET_DOMAIN;

    $Domain = eval {require Net::Domain};
}

sub _have_mail_send {
    my $self = shift;
    warn __PACKAGE__, ": _have_mail_send\n" if $self->debug();

    return $Send if defined $Send;
    return 0 if FAKE_NO_MAIL_SEND;

    $Send = eval {require Mail::Send};
}

sub _start_editor {
    my $self = shift;
    warn __PACKAGE__, ": _start_editor\n" if $self->debug();

    my $editor = $ENV{VISUAL} || $ENV{EDITOR} || $ENV{EDIT}
        || ($^O eq 'VMS'     and "edit/tpu")
        || ($^O eq 'MSWin32' and "notepad")
        || 'vi';

    $editor = $self->_prompt('Editor', $editor);

    die __PACKAGE__, ": The editor `$editor' could not be run on '$Report': $!" if system "$editor $Report";
    die __PACKAGE__, ": Report has disappeared; terminated" unless -e $Report;
    die __PACKAGE__, ": Empty report; terminated" unless -s $Report > 2;
}

sub _prompt {
    my $self = shift;
    warn __PACKAGE__, ": _prompt\n" if $self->debug();

    my ($label, $default) = @_;

    printf "$label%s", (" [$default]: ");
    my $input = scalar <STDIN>;
    chomp $input;

    return (length $input) ? $input : $default;
}

# From Mail::Util 1.74 (c) 1995-2001 Graham Barr (c) 2002-2005 Mark Overmeer
{
  # cache the mail domain, so we don't try to resolve this *every* time
  # (thanks you kane)
  my $domain;

  sub _maildomain {
      my $self = shift;
      warn __PACKAGE__, ": _maildomain\n" if $self->debug();

      # use cached value if set
      return $domain if defined $domain;

      # prefer MAILDOMAIN if set
      if ( defined $ENV{MAILDOMAIN} ) {
        return $domain = $ENV{MAILDOMAIN};
      }

      local $_;

      my @sendmailcf = qw(
          /etc /etc/sendmail /etc/ucblib /etc/mail /usr/lib /var/adm/sendmail
      );

      my $config = (grep(-r, map("$_/sendmail.cf", @sendmailcf)))[0];

      if (defined $config && open(my $cf, "<", $config)) {
          my %var;
          while (<$cf>) {
              if (my ($v, $arg) = /^D([a-zA-Z])([\w.\$\-]+)/) {
                  $arg =~ s/\$([a-zA-Z])/exists $var{$1} ? $var{$1} : '$'.$1/eg;
                  $var{$v} = $arg;
              }
          }
          close($cf) || die $!;
          $domain = $var{j} if defined $var{j};
          $domain = $var{M} if defined $var{M};

          $domain = $1
              if ($domain && $domain =~ m/([A-Za-z0-9](?:[\.\-A-Za-z0-9]+))/);

          undef $domain if $^O eq 'darwin' && $domain =~ /\.local$/;

          return $domain if (defined $domain && $domain !~ /\$/);
      }

      if (open(my $cf, "<", "/usr/lib/smail/config")) {
          while (<$cf>) {
              if (/\A\s*hostnames?\s*=\s*(\S+)/) {
                  $domain = (split(/:/,$1))[0];
                  undef $domain if $^O eq 'darwin' && $domain =~ /\.local$/;
                  last if defined $domain and $domain;
              }
          }
          close($cf) || die $!;

          return $domain if defined $domain;
      }

      if (eval {require Net::SMTP}) {
          for my $host (qw(mailhost smtp localhost)) {

            # default timeout is 120, which is Very Very Long, so lower
            # it to 5 seconds. Total slowdown will not be more than
            # 15 seconds ( 5 x @hosts ) --kane
            my $smtp = eval {Net::SMTP->new($host, Timeout => 5)};

            if (defined $smtp) {
                $domain = $smtp->domain;
                $smtp->quit;
                undef $domain if $^O eq 'darwin' && $domain =~ /\.local$/;
                last if defined $domain and $domain;
            }
          }
      }

      unless (defined $domain) {
          if ($self->_have_net_domain()) {
              ###################################################################
              # The below statement might possibly exhibit intermittent blocking
              # behavior. Be advised!
              ###################################################################
              $domain = Net::Domain::domainname();
              undef $domain if $^O eq 'darwin' && $domain =~ /\.local$/;
          }
      }

      $domain = "localhost" unless defined $domain;

      return $domain;
  }
}

# From Mail::Util 1.74 (c) 1995-2001 Graham Barr (c) 2002-2005 Mark Overmeer
sub _mailaddress {
    my $self = shift;
    warn __PACKAGE__, ": _mailaddress\n" if $self->debug();

    my $mailaddress = $ENV{MAILADDRESS};
    $mailaddress ||= $ENV{USER}    ||
                     $ENV{LOGNAME} ||
                     eval {getpwuid($>)} ||
                     "postmaster";
    $mailaddress .= '@' . $self->_maildomain() unless $mailaddress =~ /\@/;
    $mailaddress =~ s/(^.*<|>.*$)//g;

    my $realname = $self->_realname();
    if ($realname) {
        $mailaddress = "$mailaddress ($realname)";
    }

    return $mailaddress;
}

sub _realname {
    my $self = shift;
    warn __PACKAGE__, ": _realname\n" if $self->debug();

    my $realname = '';

    $realname =
        eval {(split /,/, (getpwuid($>))[6])[0]} ||
        $ENV{QMAILNAME}                          ||
        $ENV{REALNAME}                           ||
        $ENV{USER};

    return $realname;
}

sub _is_a_perl_release {
    my $self = shift;
    warn __PACKAGE__, ": _is_a_perl_release\n" if $self->debug();

    my $perl = shift;

    return $perl =~ /^perl-?\d\.\d/;
}

1;

# ABSTRACT: sends test results to cpan-testers@perl.org

=pod

=encoding UTF-8

=head1 NAME

Test::Reporter - sends test results to cpan-testers@perl.org

=head1 VERSION

version 1.62

=head1 SYNOPSIS

  use Test::Reporter;

  my $reporter = Test::Reporter->new(
      transport => 'File',
      transport_args => [ '/tmp' ],
  );

  $reporter->grade('pass');
  $reporter->distribution('Mail-Freshmeat-1.20');
  $reporter->send() || die $reporter->errstr();

  # or

  my $reporter = Test::Reporter->new(
      transport => 'File',
      transport_args => [ '/tmp' ],
  );

  $reporter->grade('fail');
  $reporter->distribution('Mail-Freshmeat-1.20');
  $reporter->comments('output of a failed make test goes here...');
  $reporter->edit_comments(); # if you want to edit comments in an editor
  $reporter->send() || die $reporter->errstr();

  # or

  my $reporter = Test::Reporter->new(
      transport => 'File',
      transport_args => [ '/tmp' ],
      grade => 'fail',
      distribution => 'Mail-Freshmeat-1.20',
      from => 'whoever@wherever.net (Whoever Wherever)',
      comments => 'output of a failed make test goes here...',
      via => 'CPANPLUS X.Y.Z',
  );
  $reporter->send() || die $reporter->errstr();

=head1 DESCRIPTION

Test::Reporter reports the test results of any given distribution to the CPAN
Testers project. Test::Reporter has wide support for various perl5's and
platforms.

CPAN Testers no longer receives test reports by email, but reports still
resemble an email message. This module has numerous legacy "features"
left over from the days of email transport.

=head2 Transport mechanism

The choice of transport is set with the C<transport> argument.  CPAN Testers
should usually install L<Test::Reporter::Transport::Metabase> and use
'Metabase' as the C<transport>.  See that module for necessary transport
arguments.  Advanced testers may wish to test on a machine different from the
one used to send reports.  Consult the L<CPAN Testers
Wiki|http://wiki.cpantesters.org/> for examples using other transport classes.

The legacy email-based transports have been split out into a separate
L<Test::Reporter::Transport::Legacy> distribution and methods solely
related to email have been deprecated.

=head1 ATTRIBUTES

=head2 Required attributes

=over

=item * B<distribution>

Gets or sets the name of the distribution you're working on, for example
Foo-Bar-0.01. There are no restrictions on what can be put here.

=item * B<from>

Gets or sets the e-mail address of the individual submitting
the test report, i.e. "John Doe <jdoe@example.com>".

=item * B<grade>

Gets or sets the success or failure of the distributions's 'make test'
result. This must be one of:

  grade     meaning
  -----     -------
  pass      all tests passed
  fail      one or more tests failed
  na        distribution will not work on this platform
  unknown   tests did not exist or could not be run

=back

=head2 Transport attributes

=over

=item * B<transport>

Gets or sets the transport type. The transport type argument is
refers to a 'Test::Reporter::Transport' subclass.  The default is 'Null',
which uses the L<Test::Reporter::Transport::Null> class and does
nothing when C<send> is called.

You can add additional arguments after the transport
selection.  These will be passed to the constructor of the lower-level
transport. See C<transport_args>.

 $reporter->transport(
     'File', '/tmp'
 );

This is not designed to be an extensible platform upon which to build
transport plugins. That functionality is planned for the next-generation
release of Test::Reporter, which will reside in the CPAN::Testers namespace.

=item * B<transport_args>

Optional.  Gets or sets transport arguments that will used in the constructor
for the selected transport, as appropriate.

=back

=head2 Optional attributes

=over

=item * B<comments>

Gets or sets the comments on the test report. This is most
commonly used for distributions that did not pass a 'make test'.

=item * B<debug>

Gets or sets the value that will turn debugging on or off.
Debug messages are sent to STDERR. 1 for on, 0 for off. Debugging
generates very verbose output and is useful mainly for finding bugs
in Test::Reporter itself.

=item * B<dir>

Defaults to the current working directory. This method specifies
the directory that write() writes test report files to.

=item * B<timeout>

Gets or sets the timeout value for the submission of test
reports. Default is 120 seconds.

=item * B<via>

Gets or sets the value that will be appended to
X-Reported-Via, generally this is useful for distributions that use
Test::Reporter to report test results. This would be something
like "CPANPLUS 0.036".

=back

=head2 Deprecated attributes

CPAN Testers no longer uses email for submitting reports.  These attributes
are deprecated.

=over

=item * B<address>

=item * B<mail_send_args>

=item * B<mx>

=back

=head1 METHODS

=over

=item * B<new>

This constructor returns a Test::Reporter object.

=item * B<perl_version>

Returns a hashref containing _archname, _osvers, and _myconfig based upon the
perl that you are using. Alternatively, you may supply a different perl (path
to the binary) as an argument, in which case the supplied perl will be used as
the basis of the above data. Make sure you protect it from the shell in
case there are spaces in the path:

  $reporter->perl_version(qq{"$^X"});

=item * B<subject>

Returns the subject line of a report, i.e.
"PASS Mail-Freshmeat-1.20 Darwin 6.0". 'grade' and 'distribution' must
first be specified before calling this method.

=item * B<report>

Returns the actual content of a report, i.e.
"This distribution has been tested as part of the cpan-testers...".
'comments' must first be specified before calling this method, if you have
comments to make and expect them to be included in the report.

=item * B<send>

Sends the test report to cpan-testers@perl.org via the defined C<transport>
mechanism.  You must check errstr() on a send() in order to be guaranteed
delivery.

=item * B<edit_comments>

Allows one to interactively edit the comments within a text
editor. comments() doesn't have to be first specified, but it will work
properly if it was.  Accepts an optional hash of arguments:

=over

=item * B<suffix>

Optional. Allows one to specify the suffix ("extension") of the temp
file used by B<edit_comments>.  Defaults to '.txt'.

=back

=item * B<errstr>

Returns an error message describing why something failed. You must check
errstr() on a send() in order to be guaranteed delivery.

=item * B<write and read>

These methods are used in situations where you wish to save reports locally
rather than transmitting them to CPAN Testers immediately.  You use write() on
the machine that you are testing from, transfer the written test reports from
the testing machine to the sending machine, and use read() on the machine that
you actually want to submit the reports from. write() will write a file in an
internal format that contains 'From', 'Subject', and the content of the report.
The filename will be represented as:
grade.distribution.archname.osvers.seconds_since_epoch.pid.rpt. write() uses
the value of dir() if it was specified, else the cwd.

On the machine you are testing from:

  my $reporter = Test::Reporter->new
  (
    grade => 'pass',
    distribution => 'Test-Reporter-1.16',
  )->write();

On the machine you are submitting from:

  # wrap in an opendir if you've a lot to submit
  my $reporter;
  $reporter = Test::Reporter->new()->read(
    'pass.Test-Reporter-1.16.i686-linux.2.2.16.1046685296.14961.rpt'
  )->send() || die $reporter->errstr();

write() also accepts an optional filehandle argument:

  my $fh; open $fh, '>-';  # create a STDOUT filehandle object
  $reporter->write($fh);   # prints the report to STDOUT

=back

=head2 Deprecated methods

=over

=item * B<message_id>

=back

=head1 CAVEATS

If you experience a long delay sending reports with Test::Reporter, you may be
experiencing a wait as Test::Reporter attempts to determine your email
address.  Always use the C<from> parameter to set your email address
explicitly.

=head1 SEE ALSO

For more about CPAN Testers:

=over 4

=item *

L<CPAN Testers reports|http://www.cpantesters.org/>

=item *

L<CPAN Testers wiki|http://wiki.cpantesters.org/>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/cpan-testers/Test-Reporter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/cpan-testers/Test-Reporter>

  git clone https://github.com/cpan-testers/Test-Reporter.git

=head1 AUTHORS

=over 4

=item *

Adam J. Foxson <afoxson@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Kirrily "Skud" Robert <skud@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Richard Soderberg <rsod@cpan.org>

=item *

Kurt Starsinic <Kurt.Starsinic@isinet.com>

=back

=head1 CONTRIBUTORS

=for stopwords Andreas Koenig Ed J Tatsuhiko Miyagawa Vincent Pit

=over 4

=item *

Andreas Koenig <andk@cpan.org>

=item *

Ed J <mohawk2@users.noreply.github.com>

=item *

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=item *

Vincent Pit <perl@profvince.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Authors and Contributors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1;
