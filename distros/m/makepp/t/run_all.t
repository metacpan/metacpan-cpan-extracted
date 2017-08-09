#!/usr/bin/env perl

package Mpp;

use Socket;
use Sys::Hostname;

chdir 't';			# failure ignored, when called from here

my %c;				# CC=gehtnich CXX=gehtnich ./run_all.t
@c{qw(
c_compilation.test
log_graph.test
makeppreplay.test
md5.test
rule_include.test
additional_tests/2003_10_11_idash.test
additional_tests/2003_11_25_wild.test
additional_tests/2004_02_19_repository_change.test
additional_tests/2004_03_12_condscan.test
additional_tests/2004_03_24_scanner_c_lib.test
additional_tests/2004_11_02_repository_rmstale.test
additional_tests/2004_12_06_scancache.test
additional_tests/2004_12_17_idl.test
additional_tests/2005_03_31_scanfail.test
additional_tests/2005_07_12_build_cache_cp.test
additional_tests/2006_12_07_scan_order.test
additional_tests/2009_12_27_skip_word_unix.test
)} = ();

BEGIN {
  if( $^O =~ /^MSWin/ ) {
    require Win32API::File;
    Win32API::File::SetErrorMode( &Win32API::File::SEM_FAILCRITICALERRORS | &Win32API::File::SEM_NOOPENFILEERRORBOX );
  }
}

use Config;

(my $cmd = $0) =~ s!.*/!!;
my $makepp = @ARGV && $ARGV[0] =~/\bm(?:ake)?pp$/ && shift;
if( @ARGV && $ARGV[0] eq '-?' ) { print <<EOF; exit }
$cmd\[ options][ -- run_tests options][ tests]
    -T  run_tests.pl -dvs rather than default -ts
    -b  Add all build_cache tests to list.
    -c  Select only those which use the C compiler.
    -C  Select none of those which use the C compiler.
    -R  Add all repository tests to list.
    -S  None of the stress_tests.

    If no tests are given, runs all in and below the current directory.
EOF
$cmd =~ s!all\.t!tests.pl!;
my( $T, $b, $c, $C, $R, $S, @opts );
while( @ARGV ) {
  last unless $ARGV[0] =~ /^-(.*)/;
  shift;
  if( $1 eq '-' ) {
    @opts = shift;
  } elsif( @opts ) {
    push @opts, "-$1";
  } else {
    eval "\$$1 = 1";
  }
}

push @ARGV, <*build_cache*.test */*build_cache*.test> if $b;
push @ARGV, <*repository*.test */*repository*.test> if $R;

@ARGV = @ARGV ?
  map { /\.test$/ ? $_ : "$_.test" } @ARGV :
  <*.test */*.test>;
@ARGV = grep exists $c{$_}, @ARGV if $c;
@ARGV = grep !exists $c{$_}, @ARGV if $C;
@ARGV = grep !/stress_tests/, @ARGV if $S;

my $cpantst = 1 if $ENV{AUTOMATED_TESTING};
push @opts, $T ? '-dvs' : '-ts' if $T || $cpantst || $ENV{HARNESS_ACTIVE};
unshift @ARGV, @opts;
print "$cmd @ARGV\n" if $ENV{DEBUG};

$ENV{MAKEPP_LN_CP} = 1
  if $cpantst && !exists $ENV{MAKEPP_LN_CP} && $^O =~ /^MS(?:ys|Win)/i;

system $^X, $cmd, @ARGV;	# run the tests
my $exit = $?;
exit 0 unless $exit || $cpantst;
my $reason =
  $? == -1 ? "failed: $!: system $^X, $cmd, @ARGV\n" :
  $? & 127 ? "died with signal $?: system $^X, $cmd, @ARGV\n" :
  $? ? "exited with value " . ($? >> 8) . ": system $^X, $cmd, @ARGV\n" :
  '';


# CPAN tester: try to send details about what succeeded or material to analyze what went wrong
# Failure of manual run: ask kindly to have this mailed
close STDERR;
my $proxy_prefix = '';
my $connectee =
  my $server = 'makepp.sourceforge.net';
my $port = 80;
# try to handle auto conf by either of two modules as available
sub auto {
  eval q
  {
    use HTTP::ProxyAutoConfig;
    $ENV{http_auto_proxy} ||= $_[0];
    my $pac = new HTTP::ProxyAutoConfig;
    ($pac = $pac->FindProxy( "http://$server" )) =~ s/^PROXY // or return 1;
    $pac;
  }
  ||
  eval q
  {
    use HTTP::ProxyPAC;
    my $pac = HTTP::ProxyPAC->new( $_[0] );
    $pac->find_proxy( "http://$server" )->proxy->as_string;
  };
}
# common code for both Windows modules
sub win {
  if( $_[0] =~ /1$/ ) {		# enable
    if( $_[1] && $_[1] !~ /(?:\A|;)$server(?:\Z|;)/ ) {
      $_[2];
    } else {
      1;
    }
  } elsif( $_[3] ) {
    auto $_[3];
  }
}

sub mail {
  my( $s, $e ) = @_;
  my $a = 'occitan@esperanto.org';
  open VERSION, "$^X ../makeppinfo --version|";
  my $v = <VERSION>;
  $v =~ /makeppinfo (?:(?:cvs-)?version|snapshot|release-candidate) ([^:\n]+)(.*)/s;
  $s .= " V$1";
  my $_s = "-s'$s' ";
  my $msg = "$s V$1$2\n$reason\n$v\n\n\@INC: @INC\n\n";
  $SIG{PIPE} = sub {	# open didn't manage to start mail, or it aborted, use own forwarder
    if( !$ENV{NO_PROXY} || $ENV{NO_PROXY} !~ /(?:\A|,)$server(?:\Z|,)/ ) {
      my $proxy = $ENV{http_proxy} || $ENV{HTTP_proxy} || $ENV{ALL_PROXY};
      unless( $proxy ) {
	if( $ENV{http_auto_proxy} ) {
	  $proxy = auto $ENV{http_auto_proxy};
	} elsif( $^O eq 'MSWin32' ) {
	  $proxy =		# try to find settings by either of two modules as available
	    eval q
	    {
	      use Win32::TieRegistry(Delimiter=>'/', TiedHash=>\my %reg);
	      my $iekey = $reg{'CUser/Software/Microsoft/Windows/CurrentVersion/Internet Settings/'} or return;
	      win @$iekey{qw(/ProxyEnable /ProxyOverride /ProxyServer /AutoConfigURL)};
	    }
	    ||
	    eval q
	    {
	      use Win32::Registry;
	      my $iekey;
	      $::HKEY_CURRENT_USER->Open( 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings', $iekey ) or return;
	      win map { my( $t, $v ); $iekey->QueryValueEx( $_, $t, $v ); $v }
		qw(ProxyEnable ProxyOverride ProxyServer AutoConfigURL);
	    }
	}
      }
      if( $proxy =~ /\A(?:http:\/\/)?(.*?)(?::(\d+))\Z/ ) {
	$proxy_prefix = "http://$server";
	$connectee = $1;
	$port = $2 || 80;
      }
    }

    my $fqhn = eval { gethostbyaddr gethostbyname( hostname ), AF_INET or hostname } || 'none';
    $fqhn .= ".$server" if $fqhn !~ /\./; # make it at least syntactically fq
    my $f = ($ENV{LOGNAME} || $ENV{USER} || 'nobody') . '@' . $fqhn;
    $s =~ tr/ /+/;		# URL safe, no other special sign in this case

    socket MAIL, PF_INET, SOCK_STREAM, getprotobyname 'tcp' or exit $e;
    connect MAIL, sockaddr_in $port, inet_aton $connectee or exit $e;
    print MAIL <<EOM;
POST $proxy_prefix/cpantester.php?f=$f&s=$s HTTP/1.0
Host: $server
Content-Type: text/plain
Content-Length: 999999

$msg
EOM
    # don't know Content-Length yet, but server needs it, too big is ok
  };
  if( open MAIL, "| exec 2>/dev/null; mailx $_s$a || nail $_s$a || mail $_s$a || /usr/lib/sendmail $a || mail $a" ) {
    print MAIL $msg;
  } else {
    $SIG{PIPE}();
  }

  my %acc;
  for( sort keys %Config ) {
    next unless defined $Config{$_};
    my $value = $Config{$_} eq $_ ? '~' : $Config{$_};
    push @{$acc{$value}},
      @{$acc{$value}} ? (/^${$acc{$value}}[-1](.+)/ ? "~$1" : $_) : $_
    }
  print MAIL "@{$acc{$_}} => $_\n" for sort keys %acc;
}

# CPAN testers don't send success or error details
my $v = sprintf $Config{ptrsize} == 4 ? 'V%vd' : 'V%vd-%dbits', $^V, $Config{ptrsize} * 8;
my $perltype =
  $Config{cf_email} =~ /(Active)(?:Perl|State)/ ? $1 :
  $Config{ldflags} =~ /(vanilla|strawberry|chocolate)/i ? ucfirst lc $1 :
  '';
$v .= "-$perltype" if $perltype;
(my $arch = $Config{myarchname}) =~ tr/ ;&|\\'"()[]*\//-/d; # clear out shell meta chars

if( $cpantst ) {
  unless( $reason || <$v/*.{failed,tdir}> ) {
    mail "SUCCESS-$arch $v", 0;
    exit 0;
  }
  mail "FAIL-$arch $v", 1;
  open SPAR, "$^X spar -d - $v|";
  undef $/;
  print MAIL "\nbegin 755 $arch-$v.spar\n" . pack( 'u*', <SPAR> ) . "\nend\n";
} else {
  system "$^X spar -d - $v >$arch-$v.spar";
  print "I'm sorry, something is not working right in your environment.
Please check above and in the .log files if there were any hints about what
you might do. Also on http://makepp.sourceforge.net/2.1/ in the side menu look
at Compatibility and Incompatibilities!  If all that doesn't help to pass,
please mail the file $arch-$v.spar to occitan\@esperanto.org
Thank you for helping!\n"
}

if( $exit > 0xff ) {
  exit $exit >> 8;
} elsif( $exit ) {
  kill $exit & 0x7f, $$;
}
exit 0;
