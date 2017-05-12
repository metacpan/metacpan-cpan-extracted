package App::SmokeBox::Mini;
$App::SmokeBox::Mini::VERSION = '0.66';
#ABSTRACT: the guts of the minismokebox command

use strict;
use warnings;
use Pod::Usage;
use Config::Tiny;
use File::Spec;
use File::Path qw[mkpath];
use Cwd;
use Getopt::Long;
use Time::Duration qw(duration_exact);
use Module::Pluggable search_path => ['App::SmokeBox::Mini::Plugin'];
use Module::Load;
use if ( $^O eq 'linux' ), 'POE::Kernel', { loop => 'POE::XS::Loop::EPoll' };
use unless ( $^O =~ /^(?:linux|MSWin32|darwin)$/ ), 'POE::Kernel', { loop => 'POE::XS::Loop::Poll' };
use if ( scalar grep { $^O eq $_ } qw(MSWin32 darwin) ), 'POE::Kernel', { loop => 'POE::Loop::Event' };
use POE;
use POE::Component::SmokeBox;
use POE::Component::SmokeBox::Smoker;
use POE::Component::SmokeBox::Job;
use POE::Component::SmokeBox::Dists;
use POE::Component::SmokeBox::Recent;
use App::SmokeBox::PerlVersion;

use constant CPANURL => 'ftp://cpan.cpantesters.org/CPAN/';

$ENV{PERL5_MINISMOKEBOX} = $App::SmokeBox::Mini::VERSION;

sub _smokebox_dir {
  return $ENV{PERL5_SMOKEBOX_DIR}
     if  exists $ENV{PERL5_SMOKEBOX_DIR}
     && defined $ENV{PERL5_SMOKEBOX_DIR};

  my @os_home_envs = qw( APPDATA HOME USERPROFILE WINDIR SYS$LOGIN );

  for my $env ( @os_home_envs ) {
      next unless exists $ENV{ $env };
      next unless defined $ENV{ $env } && length $ENV{ $env };
      return $ENV{ $env } if -d $ENV{ $env };
  }

  return cwd();
}

sub _read_config {
  my $smokebox_dir = File::Spec->catdir( _smokebox_dir(), '.smokebox' );
  return unless -d $smokebox_dir;
  my $conf_file = File::Spec->catfile( $smokebox_dir, 'minismokebox' );
  return unless -e $conf_file;
  my $Config = Config::Tiny->read( $conf_file );
  my @config;
  if ( defined $Config->{_} ) {
    my $root = delete $Config->{_};
	  @config = map { $_, $root->{$_} } grep { exists $root->{$_} }
		              qw(debug perl indices recent backend url home nolog rss random noepoch perlenv);
  }
  push @config, 'sections', $Config if scalar keys %{ $Config };
  return @config;
}

sub _read_ts_data {
  my $timestamp = File::Spec->catfile( _smokebox_dir(), '.smokebox', 'timestamp' );
  my %data;
  if ( -e $timestamp ) {
    open my $fh, '<', $timestamp or die "Could not open 'timestamp': $!\n";
    while (<$fh>) {
      chomp;
      my ($prefix,$ts) = $_ =~ /^(\[.+?\])([\d\.]+)$/;
      if ( $prefix and $ts ) {
        $data{ $prefix } = $ts;
      }
    }
    close $fh;
  }
  return %data if wantarray;
  return \%data;
}

sub _get_jobs_from_file {
  my $jobs = shift || return;
  unless ( open JOBS, "< $jobs" ) {
     warn "Could not open '$jobs' '$!'\n";
     return;
  }
  my @jobs;
  while (<JOBS>) {
    chomp;
    push @jobs, $_;
  }
  close JOBS;
  return @jobs;
}

sub _display_version {
  print "minismokebox version ", $App::SmokeBox::Mini::VERSION,
    ", powered by POE::Component::SmokeBox ", POE::Component::SmokeBox->VERSION, "\n\n";
  print <<EOF;
Copyright (C) 2011 Chris 'BinGOs' Williams
This module may be used, modified, and distributed under the same terms as Perl itself.
Please see the license that came with your Perl distribution for details.
EOF
  exit;
}

sub run {
  my $package = shift;
  my %config = _read_config();
  my $version;
  GetOptions(
    "help"      => sub { pod2usage(1); },
    "version"   => sub { $version = 1 },
    "debug"     => \$config{debug},
    "perl=s" 	  => \$config{perl},
    "indices"   => \$config{indices},
    "recent"    => \$config{recent},
    "jobs=s"    => \$config{jobs},
    "backend=s" => \$config{backend},
    "author=s"  => \$config{author},
    "package=s" => \$config{package},
    "phalanx"   => \$config{phalanx},
    "url=s"	    => \$config{url},
    "reverse"   => \$config{reverse},
    "home=s"    => \$config{home},
    "nolog"     => \$config{nolog},
    "noepoch"   => \$config{noepoch},
    "rss"       => \$config{rss},
    "random"    => \$config{random},
    "perlenv"   => \$config{perlenv},
  ) or pod2usage(2);

  _display_version() if $version;

  $config{perl} = $^X unless $config{perl} and -e $config{perl};
  $ENV{PERL5_SMOKEBOX_DEBUG} = 1 if $config{debug};
  $ENV{AUTOMATED_TESTING} = 1;   # We need this because some backends do not set it.
  $ENV{PERL_MM_USE_DEFAULT} = 1; # And this.
  $ENV{PERL_EXTUTILS_AUTOINSTALL} = '--defaultdeps'; # Got this from CPAN::Reporter::Smoker. Cheers, xdg!

  if ( $config{jobs} and -e $config{jobs} ) {
     my @jobs = _get_jobs_from_file( $config{jobs} );
     $config{jobs} = \@jobs if scalar @jobs;
  }

  my $env = delete $config{sections}->{ENVIRONMENT} || { };

  print "Running minismokebox with options:\n";
  printf("%-20s %s\n", $_, $config{$_})
	for grep { defined $config{$_} } qw(debug indices perl jobs backend author package
                                      phalanx reverse url home nolog random noepoch perlenv);
  if ( keys %{ $env } ) {
    print "ENVIRONMENT:\n";
    printf("%-20s %s\n", $_, $env->{$_}) for keys %{ $env };
  }

  if ( $config{home} and ! -e $config{home} ) {
     mkpath( $config{home} ) or die "Could not create '$config{home}': $!\n";
  }

  if ( $config{home} and ! -d $config{home} ) {
     warn "Home option was specified but '$config{home}' is not a directory, ignoring\n";
     delete $config{home};
  }

  my $self = bless \%config, $package;

  $self->{_tsdata} = _read_ts_data();

  $self->{env} = $env;
  $self->{env}->{HOME} = $self->{home} if $self->{home};
  $self->{env}->{PERL5LIB} = $ENV{PERL5LIB}
     if $self->{perlenv} and $ENV{PERL5LIB};

  $self->{sbox} = POE::Component::SmokeBox->spawn(
	smokers => [
	   POE::Component::SmokeBox::Smoker->new(
		perl => $self->{perl},
    ( scalar keys %{ $self->{env} } ? ( env => $self->{env} ) : () ),
	   ),
	],
  );

  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { recent => '_submission', dists => '_submission', },
	   $self => [qw(_start _stop _check _child _indices _smoke _search _perl_version)],
	],
	heap => $self,
  )->ID();

  $poe_kernel->run();
  return 1;
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  # Run a check to make sure the backend exists in the designated perl
  $kernel->post( $self->{sbox}->session_id(), 'submit', event => '_check', job =>
     POE::Component::SmokeBox::Job->new(
	( $self->{backend} ? ( type => $self->{backend} ) : () ),
	command => 'check',
     ),
  );
  $self->{stats} = {
	started => time(),
	totaljobs => 0,
	avg_run => 0,
	min_run => 0,
	max_run => 0,
	_sum => 0,
	idle => 0,
	excess => 0,
  };
  # Initialise plugins
  foreach my $plugin ( $self->plugins() ) {
     load $plugin;
     $plugin->init( $self->{sections} );
  }
  return;
}

sub _child {
  my ($kernel,$self,$reason,$child) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $reason eq 'create';
  push @{ $self->{_sessions} }, $child->ID();
  $kernel->detach_child( $child );
  return;
}

sub _stop {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->call( $self->{sbox}->session_id(), 'shutdown' );
  my $finish = time();
  my $cumulative = duration_exact( $finish - $self->{stats}->{started} );
  my @stats = map { $self->{stats}->{$_} } qw(totaljobs idle excess avg_run min_run max_run);
  $kernel->call( $_, 'sbox_stop', $self->{stats}->{started}, $finish, @stats ) for @{ $self->{_sessions} };
  $stats[$_] = duration_exact( $stats[$_] ) for 3 .. 5;
  print "minismokebox started at: \t", scalar localtime($self->{stats}->{started}), "\n";
  print "minismokebox finished at: \t", scalar localtime($finish), "\n";
  print "minismokebox ran for: \t", $cumulative, "\n";
  print "minismokebox tot jobs:\t", $stats[0], "\n";
  print "minismokebox idle kills:\t", $stats[1], "\n" if $stats[1];
  print "minismokebox excess kills:\t", $stats[2], "\n" if $stats[2];
  print "minismokebox avg run: \t", $stats[3], "\n";
  print "minismokebox min run: \t", $stats[4], "\n";
  print "minismokebox max run: \t", $stats[5], "\n";
  return if $self->{noepoch};
  my $smokebox_dir = File::Spec->catdir( _smokebox_dir(), '.smokebox' );
  mkpath( $smokebox_dir ) unless -d $smokebox_dir;
  {
    $self->{_tsdata}->{ $self->{_tsprefix} } = $self->{stats}->{started};
    open my $ts, '>', File::Spec->catfile( $smokebox_dir, 'timestamp' ) or die "Could not open 'timestamp': $!\n";
    print {$ts} join('', $_, $self->{_tsdata}->{$_} ), "\n" for sort keys %{ $self->{_tsdata} };
    close $ts;
  }
  return;
}

sub _check {
  my ($kernel,$self,$data) = @_[KERNEL,OBJECT,ARG0];
  my ($result) = $data->{result}->results;
  unless ( $result->{status} == 0 ) {
     my $backend = $self->{backend} || 'CPANPLUS::YACSmoke';
     warn "The specified perl '$self->{perl}' does not have backend '$backend' installed, aborting\n";
     return;
  }
  App::SmokeBox::PerlVersion->version(
    perl => $self->{perl},
    event => '_perl_version',
    session => $_[SESSION]->postback( '_perl_version' ),
  );
  return;
}

sub _perl_version {
  my ($kernel,$self,$args) = @_[KERNEL,OBJECT,ARG1];
  my $data = shift @{$args};
  my ($version,$archname,$osvers) = @{ $data }{qw(version archname osvers)};
  if ( $version and $archname and $osvers ) {
    print "Perl Version: $version\nArchitecture: $archname\nOS Version: $osvers\n";
    $kernel->post( $_, 'sbox_perl_info', $version, $archname, $osvers ) for @{ $self->{_sessions} };
    $self->{_perlinfo} = [ $version, $archname ];
    $self->{_tsprefix} = "[$version$archname]";
    $self->{_epoch} = $self->{_tsdata}->{ $self->{_tsprefix} } unless $self->{noepoch};
  }
  if ( $self->{indices} ) {
     $kernel->post( $self->{sbox}->session_id(), 'submit', event => '_indices', job =>
        POE::Component::SmokeBox::Job->new(
	   ( $self->{backend} ? ( type => $self->{backend} ) : () ),
	   command => 'index',
        ),
     );
     return;
  }
  $kernel->yield( '_search' );
  return;
}

sub _indices {
  my ($kernel,$self,$data) = @_[KERNEL,OBJECT,ARG0];
  my ($result) = $data->{result}->results;
  unless ( $result->{status} == 0 ) {
     my $backend = $self->{backend} || 'CPANPLUS::YACSmoke';
     warn "There was a problem with the reindexing\n";
     return;
  }
  $kernel->yield( '_search' );
  return;
}

sub _search {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  if ( $self->{jobs} and ref $self->{jobs} eq 'ARRAY' ) {
     foreach my $distro ( @{ $self->{jobs} } ) {
        print "Submitting: $distro\n";
        $kernel->post( $self->{sbox}->session_id(), 'submit', event => '_smoke', job =>
           POE::Component::SmokeBox::Job->new(
	      ( $self->{backend} ? ( type => $self->{backend} ) : () ),
	      command => 'smoke',
	      module  => $distro,
        ( $self->{nolog} ? ( no_log => 1 ) : () ),
           ),
        );
     }
  }
  if ( $self->{recent} ) {
    POE::Component::SmokeBox::Recent->recent(
        url => $self->{url} || CPANURL,
        event => 'recent',
        rss => $self->{rss},
        ( defined $self->{_epoch} ? ( epoch => $self->{_epoch} ) : () ),
    );
  }
  if ( $self->{package} ) {
    warn "Doing a distro search, this may take a little while\n";
    POE::Component::SmokeBox::Dists->distro(
        event => 'dists',
        search => $self->{package},
        url => $self->{url} || CPANURL,
    );
  }
  if ( $self->{author} ) {
    warn "Doing an author search, this may take a little while\n";
    POE::Component::SmokeBox::Dists->author(
        event => 'dists',
        search => $self->{author},
        url => $self->{url} || CPANURL,
    );
  }
  if ( $self->{phalanx} ) {
    warn "Doing a phalanx search, this may take a little while\n";
    POE::Component::SmokeBox::Dists->phalanx(
        event => 'dists',
        url => $self->{url} || CPANURL,
    );
  }
  if ( $self->{random} ) {
    warn "Doing a random search, this may take a little while\n";
    POE::Component::SmokeBox::Dists->random(
        event => 'dists',
        url => $self->{url} || CPANURL,
    );
  }
  return if !$self->{recent} and ( $self->{package} or $self->{author} or $self->{phalanx} or ( $self->{jobs} and ref $self->{jobs} eq 'ARRAY' ) );
  POE::Component::SmokeBox::Recent->recent(
      url => $self->{url} || CPANURL,
      event => 'recent',
      rss => $self->{rss},
      ( defined $self->{_epoch} ? ( epoch => $self->{_epoch} ) : () ),
  );
  return;
}

sub _submission {
  my ($kernel,$self,$state,$data) = @_[KERNEL,OBJECT,STATE,ARG0];
  if ( $data->{error} ) {
     warn $data->{error}, "\n";
     return;
  }
  if ( $state eq 'recent' and $self->{reverse} ) {
     @{ $data->{$state} } = reverse @{ $data->{$state} };
  }
  foreach my $distro ( @{ $data->{$state} } ) {
     print "Submitting: $distro\n";
     $kernel->post( $self->{sbox}->session_id(), 'submit', event => '_smoke', job =>
        POE::Component::SmokeBox::Job->new(
	   ( $self->{backend} ? ( type => $self->{backend} ) : () ),
	   command => 'smoke',
	   module  => $distro,
     ( $self->{nolog} ? ( no_log => 1 ) : () ),
        ),
     );
  }
  return;
}

sub _smoke {
  my ($kernel,$self,$data) = @_[KERNEL,OBJECT,ARG0];
  my $dist = $data->{job}->module();
  my ($result) = $data->{result}->results;
  print "Distribution: '$dist' finished with status '$result->{status}'\n";
  $kernel->post( $_, 'sbox_smoke', $data ) for @{ $self->{_sessions} };
  my $run_time = $result->{end_time} - $result->{start_time};
  $self->{stats}->{max_run} = $run_time if $run_time > $self->{stats}->{max_run};
  $self->{stats}->{min_run} = $run_time if $self->{stats}->{min_run} == 0;
  $self->{stats}->{min_run} = $run_time if $run_time < $self->{stats}->{min_run};
  $self->{stats}->{_sum} += $run_time;
  $self->{stats}->{totaljobs}++;
  $self->{stats}->{avg_run} = $self->{stats}->{_sum} / $self->{stats}->{totaljobs};
  $self->{stats}->{idle}++ if $result->{idle_kill};
  $self->{stats}->{excess}++ if $result->{excess_kill};
  $self->{_jobs}--;
  return;
}

'smoke it!';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBox::Mini - the guts of the minismokebox command

=head1 VERSION

version 0.66

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  BEGIN { eval "use Event;"; }
  use App::SmokeBox::Mini;
  App::SmokeBox::Mini->run();

=head2 run

This method is called by L<minismokebox> to do all the work.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
