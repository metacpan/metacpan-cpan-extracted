package App::Metabase::Relayd;
$App::Metabase::Relayd::VERSION = '0.40';
#ABSTRACT: the guts of the metabase-relayd command

use strict;
use warnings;
use Pod::Usage;
use Config::Tiny;
use File::Spec;
use Cwd;
use Getopt::Long;
use Module::Pluggable search_path => ['App::Metabase::Relayd::Plugin'];
use Module::Load::Conditional qw[can_load];
use if ( $^O eq 'linux' ), 'POE::Kernel', { loop => 'POE::XS::Loop::EPoll' };
use unless ( $^O =~ /^(?:linux|MSWin32|darwin)$/ ), 'POE::Kernel', { loop => 'POE::XS::Loop::Poll' };
use if ( scalar grep { $^O eq $_ } qw(MSWin32 darwin) ), 'POE::Kernel', { loop => 'POE::Loop::Event' };
use POE;
use POE::Component::Metabase::Relay::Server;

sub _metabase_dir {
  return $ENV{PERL5_MBRELAYD_DIR}
     if  exists $ENV{PERL5_MBRELAYD_DIR}
     && defined $ENV{PERL5_MBRELAYD_DIR};

  my @os_home_envs = qw( APPDATA HOME USERPROFILE WINDIR SYS$LOGIN );

  for my $env ( @os_home_envs ) {
      next unless exists $ENV{ $env };
      next unless defined $ENV{ $env } && length $ENV{ $env };
      return $ENV{ $env } if -d $ENV{ $env };
  }

  return cwd();
}

sub _read_config {
  my $metabase_dir = File::Spec->catdir( _metabase_dir(), '.metabase' );
  return unless -d $metabase_dir;
  my $conf_file = File::Spec->catfile( $metabase_dir, 'relayd' );
  return unless -e $conf_file;
  my $Config = Config::Tiny->read( $conf_file );
  my @config;
  if ( defined $Config->{_} ) {
    my $root = delete $Config->{_};
	  @config = map { $_, $root->{$_} } grep { exists $root->{$_} }
		              qw(debug url idfile dbfile address port multiple nocurl norelay offline submissions);
    push @config, 'plugins', $Config;
  }
  return @config;
}

sub _display_version {
  print "metabase-relayd version ", $App::Metabase::Relayd::VERSION,
    ", powered by POE::Component::Metabase::Relay::Server ", POE::Component::Metabase::Relay::Server->VERSION, "\n\n";
  print <<EOF;
Copyright (C) 2014 Chris 'BinGOs' Williams
This module may be used, modified, and distributed under the same terms as Perl itself.
Please see the license that came with your Perl distribution for details.
EOF
  exit;
}

sub run {
  my $package = shift;
  my %config = _read_config();
  $config{offline} = delete $config{norelay} if $config{norelay};
  my $version;
  GetOptions(
    "help"        => sub { pod2usage(1); },
    "version"     => sub { $version = 1 },
    "debug"       => \$config{debug},
    "address=s@"  => \$config{address},
    "port=s"      => \$config{port},
    "url=s"	      => \$config{url},
    "dbfile=s"    => \$config{dbfile},
    "idfile=s"	  => \$config{idfile},
    "multiple"	  => \$config{multiple},
    "norelay|offline" => \$config{offline},
    "nocurl"      => \$config{nocurl},
    "submissions" => \$config{submissions},
  ) or pod2usage(2);

  _display_version() if $version;

  $config{idfile} = File::Spec->catfile( _metabase_dir(), '.metabase', 'metabase_id.json' ) unless $config{idfile};
  $config{dbfile} = File::Spec->catfile( _metabase_dir(), '.metabase', 'relay.db' ) unless $config{dbfile};

  print "Running metabase-relayd with options:\n";
  printf("%-20s %s\n", $_, ref $config{$_}
    ? (join q{, } => @{ $config{$_} })
    : $config{$_})
	  for grep { defined $config{$_} } qw(debug url dbfile idfile address port multiple offline nocurl);

  my $self = bless \%config, $package;

  if ( $self->{address} ) {
    $self->{address} = [
      split(/,/,join(',',( ref $self->{address} eq 'ARRAY' ? @{ $self->{address} } : $self->{address} )))
    ];
    s/\s+//g for @{ $self->{address} };
  }

  $self->{id} = POE::Session->create(
    object_states => [
        $self => [qw(_start _child _recv_evt)],
    ],
  )->ID();

  $self->{relayd} = POE::Component::Metabase::Relay::Server->spawn(
    ( defined $self->{address} ? ( address => $self->{address} ) : () ),
    ( defined $self->{port} ? ( port => $self->{port} ) : () ),
    id_file     => $self->{idfile},
    dsn         => 'dbi:SQLite:dbname=' . $self->{dbfile},
    uri         => $self->{url},
    debug       => $self->{debug},
    multiple    => $self->{multiple},
    no_relay    => $self->{offline},
    no_curl     => $self->{nocurl},
    session     => $self->{id},
    recv_event  => '_recv_evt',
    ( defined $self->{submissions} ? ( submissions => $self->{submissions} ) : () ),
  );

  $poe_kernel->run();
  return 1;
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{id} = $_[SESSION]->ID();
  $kernel->refcount_increment( $self->{id}, __PACKAGE__ );
  # Initialise plugins
  foreach my $plugin ( $self->plugins() ) {
     next unless can_load( modules => { $plugin => '0' } );
     eval { $plugin->init( $self->{plugins} ); };
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

sub _recv_evt {
  my ($kernel,$self,$data,$ip) = @_[KERNEL,OBJECT,ARG0,ARG1];
  $kernel->post( $_, 'mbrd_received', $data, $ip ) for @{ $self->{_sessions} };
  return;
}

'Relay it!';

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Metabase::Relayd - the guts of the metabase-relayd command

=head1 VERSION

version 0.40

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  BEGIN { eval "use Event;"; }
  use App::Metabase::Relayd;
  App::Metabase::Relayd->run();

=head2 run

This method is called by L<metabase-relayd> to do all the work.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
