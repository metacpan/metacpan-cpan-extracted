package VPIT::TestHelpers;

use strict;
use warnings;

use Config ();

=head1 NAME

VPIT::TestHelpers

=head1 SYNTAX

    use VPIT::TestHelpers (
     feature1 => \@feature1_args,
     feature2 => \@feature2_args,
    );

=cut

sub export_to_pkg {
 my ($subs, $pkg) = @_;

 while (my ($name, $code) = each %$subs) {
  no strict 'refs';
  *{$pkg.'::'.$name} = $code;
 }

 return 1;
}

sub sanitize_prefix {
 my $prefix = shift;

 if (defined $prefix) {
  if (length $prefix and $prefix !~ /_$/) {
   $prefix .= '_';
  }
 } else {
  $prefix = '';
 }

 return $prefix;
}

my %default_exports = (
 load_or_skip     => \&load_or_skip,
 load_or_skip_all => \&load_or_skip_all,
 skip_all         => \&skip_all,
);

my %features = (
 threads  => \&init_threads,
 usleep   => \&init_usleep,
 run_perl => \&init_run_perl,
 capture  => \&init_capture,
);

sub import {
 shift;
 my @opts = @_;

 my %exports = %default_exports;

 for (my $i = 0; $i <= $#opts; ++$i) {
  my $feature = $opts[$i];
  next unless defined $feature;

  my $args;
  if ($i < $#opts and defined $opts[$i+1] and ref $opts[$i+1] eq 'ARRAY') {
   ++$i;
   $args = $opts[$i];
  } else {
   $args = [ ];
  }

  my $handler = $features{$feature};
  die "Unknown feature '$feature'" unless defined $handler;

  my %syms = $handler->(@$args);

  $exports{$_} = $syms{$_} for sort keys %syms;
 }

 export_to_pkg \%exports => scalar caller;
}

my $test_sub = sub {
 my $sub = shift;

 my $stash;
 if ($INC{'Test/Leaner.pm'}) {
  $stash = \%Test::Leaner::;
 } else {
  require Test::More;
  $stash = \%Test::More::;
 }

 my $glob = $stash->{$sub};
 return ref \$glob eq 'GLOB' ? *$glob{CODE}
      : ref  $glob eq 'CODE' ?  $glob
      :                          undef;
};

sub skip { $test_sub->('skip')->(@_) }

sub skip_all { $test_sub->('plan')->(skip_all => $_[0]) }

sub diag {
 my $diag = $test_sub->('diag');
 $diag->($_) for @_;
}

our $TODO;
local $TODO;

sub load {
 my ($pkg, $ver, $imports) = @_;

 my $spec = $ver && $ver !~ /^[0._]*$/ ? "$pkg $ver" : $pkg;
 my $err;

 local $@;
 if (eval "use $spec (); 1") {
  $ver = do { no strict 'refs'; ${"${pkg}::VERSION"} };
  $ver = 'undef' unless defined $ver;

  if ($imports) {
   my @imports = @$imports;
   my $caller  = (caller 1)[0];
   local $@;
   my $res = eval <<"IMPORTER";
package
        $caller;
BEGIN { \$pkg->import(\@imports) }
1;
IMPORTER
   $err = "Could not import '@imports' from $pkg $ver: $@" unless $res;
  }
 } else {
  (my $file = "$pkg.pm") =~ s{::}{/}g;
  delete $INC{$file};
  $err = "Could not load $spec";
 }

 if ($err) {
  return wantarray ? (0, $err) : 0;
 } else {
  diag "Using $pkg $ver";
  return 1;
 }
}

sub load_or_skip {
 my ($pkg, $ver, $imports, $tests) = @_;

 die 'You must specify how many tests to skip' unless defined $tests;

 my ($loaded, $err) = load($pkg, $ver, $imports);
 skip $err => $tests unless $loaded;

 return $loaded;
}

sub load_or_skip_all {
 my ($pkg, $ver, $imports) = @_;

 my ($loaded, $err) = load($pkg, $ver, $imports);
 skip_all $err unless $loaded;

 return $loaded;
}

=head1 FEATURES

=head2 C<run_perl>

=over 4

=item *

Import :

    use VPIT::TestHelpers run_perl => [ $p ]

where :

=over 8

=item -

C<$p> is prefixed to the constants exported by this feature (defaults to C<''>).

=back

=item *

Dependencies :

=over 8

=item -

L<File::Spec>

=back

=item *

Exports :

=over 8

=item -

C<run_perl $code>

=item -

C<run_perl_file $file>

=item -

C<RUN_PERL_FAILED> (possibly prefixed by C<$p>)

=back

=back

=cut

sub fresh_perl_env (&) {
 my $handler = shift;

 my ($SystemRoot, $PATH) = @ENV{qw<SystemRoot PATH>};
 my $ld_name  = $Config::Config{ldlibpthname};
 my $ldlibpth = $ENV{$ld_name};

 local %ENV;
 $ENV{$ld_name}   = $ldlibpth   if                      defined $ldlibpth;
 $ENV{SystemRoot} = $SystemRoot if $^O eq 'MSWin32' and defined $SystemRoot;
 $ENV{PATH}       = $PATH       if $^O eq 'cygwin'  and defined $PATH;

 my $perl = $^X;
 unless (-e $perl and -x $perl) {
  $perl = $Config::Config{perlpath};
  unless (-e $perl and -x $perl) {
   return undef;
  }
 }

 return $handler->($perl, '-T', map("-I$_", @INC));
}

sub init_run_perl {
 my $p = sanitize_prefix(shift);

 # This is only required for run_perl_file(), so it is not needed for the
 # threads feature which only calls run_perl() - don't forget to update its
 # requirements if this ever changes.
 require File::Spec;

 return (
  run_perl              => \&run_perl,
  run_perl_file         => \&run_perl_file,
  "${p}RUN_PERL_FAILED" => sub () { 'Could not execute perl subprocess' },
 );
}

sub run_perl {
 my $code = shift;

 if ($code =~ /"/) {
  die 'Double quotes in evaluated code are not portable';
 }

 fresh_perl_env {
  my ($perl, @perl_args) = @_;
  system { $perl } $perl, @perl_args, '-e', $code;
 };
}

sub run_perl_file {
 my $file = shift;

 $file = File::Spec->rel2abs($file);
 unless (-e $file and -r _) {
  die 'Could not run perl file';
 }

 fresh_perl_env {
  my ($perl, @perl_args) = @_;
  system { $perl } $perl, @perl_args, $file;
 };
}

=head2 C<capture>

=over 4

=item *

Import :

    use VPIT::TestHelpers capture => [ $p ];

where :

=over 8

=item -

C<$p> is prefixed to the constants exported by this feature (defaults to C<''>).

=back

=item *

Dependencies :

=over 8

=item -

Neither VMS nor OS/2

=item -

L<IO::Handle>

=item -

L<IO::Select>

=item -

L<IPC::Open3>

=item -

On MSWin32 : L<Socket>

=back

=item *

Exports :

=over 8

=item -

C<capture @command>

=item -

C<CAPTURE_FAILED $details> (possibly prefixed by C<$p>)

=item -

C<capture_perl $code>

=item -

C<CAPTURE_PERL_FAILED $details> (possibly prefixed by C<$p>)

=back

=back

=cut

sub init_capture {
 my $p = sanitize_prefix(shift);

 skip_all 'Cannot capture output on VMS'  if $^O eq 'VMS';
 skip_all 'Cannot capture output on OS/2' if $^O eq 'os2';

 load_or_skip_all 'IO::Handle', '0', [ ];
 load_or_skip_all 'IO::Select', '0', [ ];
 load_or_skip_all 'IPC::Open3', '0', [ ];
 if ($^O eq 'MSWin32') {
  load_or_skip_all 'Socket', '0', [ ];
 }

 return (
  capture                   => \&capture,
  "${p}CAPTURE_FAILED"      => \&capture_failed_msg,
  capture_perl              => \&capture_perl,
  "${p}CAPTURE_PERL_FAILED" => \&capture_perl_failed_msg,
 );
}

# Inspired from IPC::Cmd

sub capture {
 my @cmd = @_;

 my $want = wantarray;

 my $fail = sub {
  my $err     = $!;
  my $ext_err = $^O eq 'MSWin32' ? $^E : undef;

  my $syscall = shift;
  my $args    = join ', ', @_;

  my $msg = "$syscall($args) failed: ";

  if (defined $err) {
   no warnings 'numeric';
   my ($err_code, $err_str) = (int $err, "$err");
   $msg .= "$err_str ($err_code)";
  }

  if (defined $ext_err) {
   no warnings 'numeric';
   my ($ext_err_code, $ext_err_str) = (int $ext_err, "$ext_err");
   $msg .= ", $ext_err_str ($ext_err_code)";
  }

  die "$msg\n";
 };

 my ($status, $content_out, $content_err);

 local $@;
 my $ok = eval {
  my ($pid, $out, $err);

  if ($^O eq 'MSWin32') {
   my $pipe = sub {
    socketpair $_[0], $_[1],
               &Socket::AF_UNIX, &Socket::SOCK_STREAM, &Socket::PF_UNSPEC
                      or $fail->(qw<socketpair reader writer>);
    shutdown $_[0], 1 or $fail->(qw<shutdown reader>);
    shutdown $_[1], 0 or $fail->(qw<shutdown writer>);
    return 1;
   };
   local (*IN_R,  *IN_W);
   local (*OUT_R, *OUT_W);
   local (*ERR_R, *ERR_W);
   $pipe->(*IN_R,  *IN_W);
   $pipe->(*OUT_R, *OUT_W);
   $pipe->(*ERR_R, *ERR_W);

   $pid = IPC::Open3::open3('>&IN_R', '<&OUT_W', '<&ERR_W', @cmd);

   close *IN_W or $fail->(qw<close input>);
   $out = *OUT_R;
   $err = *ERR_R;
  } else {
   my $in = IO::Handle->new;
   $out   = IO::Handle->new;
   $out->autoflush(1);
   $err   = IO::Handle->new;
   $err->autoflush(1);

   $pid = IPC::Open3::open3($in, $out, $err, @cmd);

   close $in;
  }

  # Forward signals to the child (except SIGKILL)
  my %sig_handlers;
  foreach my $s (keys %SIG) {
   $sig_handlers{$s} = sub {
    kill "$s" => $pid;
    $SIG{$s} = $sig_handlers{$s};
   };
  }
  local $SIG{$_} = $sig_handlers{$_} for keys %SIG;

  unless ($want) {
   close $out or $fail->(qw<close output>);
   close $err or $fail->(qw<close error>);
   waitpid $pid, 0;
   $status = $?;
   return 1;
  }

  my $sel = IO::Select->new();
  $sel->add($out, $err);

  my $fd_out = fileno $out;
  my $fd_err = fileno $err;

  my %contents;
  $contents{$fd_out} = '';
  $contents{$fd_err} = '';

  while (my @ready = $sel->can_read) {
   for my $fh (@ready) {
    my $buf;
    my $bytes_read = sysread $fh, $buf, 4096;
    if (not defined $bytes_read) {
     $fail->('sysread', 'fd(' . fileno($fh) . ')');
    } elsif ($bytes_read) {
     $contents{fileno($fh)} .= $buf;
    } else {
     $sel->remove($fh);
     close $fh or $fail->('close', 'fd(' . fileno($fh) . ')');
     last unless $sel->count;
    }
   }
  }

  waitpid $pid, 0;
  $status = $?;

  if ($^O eq 'MSWin32') {
   # Manual CRLF translation that couldn't be done with sysread.
   s/\x0D\x0A/\n/g for values %contents;
  }

  $content_out = $contents{$fd_out};
  $content_err = $contents{$fd_err};

  1;
 };

 if ("$]" < 5.014 and $ok and ($status >> 8) == 255 and defined $content_err
                  and $content_err =~ /^open3/) {
  # Before perl commit 8960aa87 (between 5.12 and 5.14), exceptions in open3
  # could be reported to STDERR instead of being propagated, so work around
  # this.
  $ok = 0;
  $@  = $content_err;
 }

 if ($ok) {
  return ($status, $content_out, $content_err);
 } else {
  my $err = $@;
  chomp $err;
  return (undef, $err);
 }
}

sub capture_failed_msg {
 my $details = shift;

 my $msg = 'Could not capture command output';
 $msg   .= " ($details)" if defined $details;

 return $msg;
}

sub capture_perl {
 my $code = shift;

 if ($code =~ /"/) {
  die 'Double quotes in evaluated code are not portable';
 }

 fresh_perl_env {
  my @perl = @_;
  capture @perl, '-e', $code;
 };
}

sub capture_perl_failed_msg {
 my $details = shift;

 my $msg = 'Could not capture perl output';
 $msg   .= " ($details)" if defined $details;

 return $msg;
}

=head2 C<threads>

=over 4

=item *

Import :

    use VPIT::TestHelpers threads => [
     $pkg, $threadsafe_var, $force_var
    ];

where :

=over 8

=item -

C<$pkg> is the target package name that will be exercised by this test ;

=item -

C<$threadsafe_var> is the name of an optional variable in C<$pkg> that evaluates to true if and only if the module claims to be thread safe (not checked if either C<$threadsafe_var> or C<$pkg> is C<undef>) ;

=item -

C<$force_var> is the name of the environment variable that can be used to force the thread tests (defaults to C<PERL_FORCE_TEST_THREADS>).

=back

=item *

Dependencies :

=over 8

=item -

C<perl> 5.13.4

=item -

L<POSIX>

=item -

L<threads> 1.67

=item -

L<threads::shared> 1.14

=back

=item *

Exports :

=over 8

=item -

C<spawn $coderef>

=back

=item *

Notes :

=over 8

=item -

C<< exit => 'threads_only' >> is passed to C<< threads->import >>.

=back

=back

=cut

sub init_threads {
 my ($pkg, $threadsafe_var, $force_var) = @_;

 skip_all 'This perl wasn\'t built to support threads'
                                            unless $Config::Config{useithreads};

 if (defined $pkg and defined $threadsafe_var) {
  my $threadsafe;
  # run_perl() doesn't actually require anything
  my $stat = run_perl("require POSIX; require $pkg; exit($threadsafe_var ? POSIX::EXIT_SUCCESS() : POSIX::EXIT_FAILURE())");
  if (defined $stat) {
   require POSIX;
   my $res  = $stat >> 8;
   if ($res == POSIX::EXIT_SUCCESS()) {
    $threadsafe = 1;
   } elsif ($res == POSIX::EXIT_FAILURE()) {
    $threadsafe = !1;
   }
  }
  if (not defined $threadsafe) {
   skip_all "Could not detect if $pkg is thread safe or not";
  } elsif (not $threadsafe) {
   skip_all "This $pkg is not thread safe";
  }
 }

 $force_var = 'PERL_FORCE_TEST_THREADS' unless defined $force_var;
 my $force  = $ENV{$force_var} ? 1 : !1;
 skip_all 'perl 5.13.4 required to test thread safety'
                                             unless $force or "$]" >= 5.013_004;

 unless ($INC{'threads.pm'}) {
  my $test_module;
  if ($INC{'Test/Leaner.pm'}) {
   $test_module = 'Test::Leaner';
  } elsif ($INC{'Test/More.pm'}) {
   $test_module = 'Test::More';
  }
  die "$test_module was loaded too soon" if defined $test_module;
 }

 load_or_skip_all 'threads',         $force ? '0' : '1.67', [
  exit => 'threads_only',
 ];
 load_or_skip_all 'threads::shared', $force ? '0' : '1.14', [ ];

 diag "Threads testing forced by \$ENV{$force_var}" if $force;

 return spawn => \&spawn;
}

sub spawn {
 local $@;
 my @diag;
 my $thread = eval {
  local $SIG{__WARN__} = sub { push @diag, "Thread creation warning: @_" };
  threads->create(@_);
 };
 push @diag, "Thread creation error: $@" if $@;
 diag @diag;
 return $thread ? $thread : ();
}

=head2 C<usleep>

=over 4

=item *

Import :

    use VPIT::TestHelpers 'usleep' => [ @impls ];

where :

=over 8

=item -

C<@impls> is the list of desired implementations (which may be C<'Time::HiRes'>, C<'select'> or C<'sleep'>), in the order they should be checked.
When the list is empty, it defaults to all of them.

=back

=item *

Dependencies : none

=item *

Exports :

=over 8

=item -

C<usleep $microseconds>

=back

=back

=cut

sub init_usleep {
 my (@impls) = @_;

 my %impls = (
  'Time::HiRes' => sub {
   if (do { local $@; eval { require Time::HiRes; 1 } }) {
    defined and diag "Using usleep() from Time::HiRes $_"
                                                      for $Time::HiRes::VERSION;
    return \&Time::HiRes::usleep;
   } else {
    return undef;
   }
  },
  'select' => sub {
   if ($Config::Config{d_select}) {
    diag 'Using select()-based fallback usleep()';
    return sub ($) {
     my $s = $_[0];
     my $r = 0;
     while ($s > 0) {
      my ($found, $t) = select(undef, undef, undef, $s / 1e6);
      last unless defined $t;
      $t  = int($t * 1e6);
      $s -= $t;
      $r += $t;
     }
     return $r;
    };
   } else {
    return undef;
   }
  },
  'sleep' => sub {
   diag 'Using sleep()-based fallback usleep()';
   return sub ($) {
    my $ms = int $_[0];
    my $s  = int($ms / 1e6) + ($ms % 1e6 == 0 ? 0 : 1);
    my $t  = sleep $s;
    return $t * 1e6;
   };
  },
 );

 @impls = qw<Time::HiRes select sleep> unless @impls;

 my $usleep;
 for my $impl (@impls) {
  next unless defined $impl and $impls{$impl};
  $usleep = $impls{$impl}->();
  last if defined $usleep;
 }

 skip_all "Could not find a suitable usleep() implementation among: @impls"
                                                                 unless $usleep;

 return usleep => $usleep;
}

=head1 CLASSES

=head2 C<VPIT::TestHelpers::Guard>

Syntax :

    {
     my $guard = VPIT::TestHelpers::Guard->new($coderef);
     ...
    } # $codref called here

=cut

package VPIT::TestHelpers::Guard;

sub new {
 my ($class, $code) = @_;

 bless { code => $code }, $class;
}

sub DESTROY { $_[0]->{code}->() }

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

=head1 COPYRIGHT & LICENSE

Copyright 2012,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
