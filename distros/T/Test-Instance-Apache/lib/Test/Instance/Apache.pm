package Test::Instance::Apache;

use Moo;
use File::Temp;
use File::Spec;
use File::Which qw/ which /;
use IPC::System::Simple qw/ capture /;
use Net::EmptyPort qw/ empty_port /;
use IO::All;

use Test::Instance::Apache::Config;
use Test::Instance::Apache::Modules;

use namespace::clean;

our $VERSION = '0.001';

=head1 NAME

Test::Instance::Apache - Create Apache instance for Testing

=head1 SYNOPSIS

  use FindBin qw/ $Bin /;
  use Test::Instance::Apache;

  my $instance = Test::Instance::Apache->new(
    config => [
      "VirtualHost *" => [
        DocumentRoot => "$Bin/root",
      ],
    ],
    modules => [ qw/ mpm_prefork authz_core mime / ],
  );

  $instance->run;

=head1 DESCRIPTION

Test::Instance::Apache allows you to spin up a complete Apache instance for
testing. This is useful when developing various plugins for Apache, or if your
application is tightly integrated to the webserver.

=head2 Attributes

These are the attributes available on Test::Instance::Apache.

=cut

has _temp_dir => (
  is => 'lazy',
  builder => sub {
    return File::Temp->newdir;
  },
);

=head3 server_root

The root folder for creating the Apache instance. This folder is passed to
Apache during instantiation as the server root configuration, and normally
contains all the configuration files for Apache. If not set during object
creation, a new folder will be created using File::Temp.

=cut

has server_root => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return $self->_temp_dir->dirname;
  },
);

=head3 conf_dir

The directory for holding the configuration files. Defaults to
C<$server_root/conf>. If set during object creation, then you will need to
create the folder manually.

=cut

has conf_dir => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return $self->make_server_dir( 'conf' );
  },
);

=head3 log_dir

The directory for holding all the log files. Defaults to C<$server_root/logs>.
If set during object creation, then you will need to create the folder
manually.

=cut

has log_dir => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return $self->make_server_dir( 'logs' );
  },
);

=head3 conf_file_path

The path to the main configuration file. Defaults to C<$conf_dir/httpd.conf>.
This is then used by L<Test::Instance::Apache::Config> to create the base
configuration file.

=cut

has conf_file_path => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return File::Spec->catfile( $self->conf_dir, 'httpd.conf' );
  },
);

has _config_manager => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return Test::Instance::Apache::Config->new(
      filename => $self->conf_file_path,
      config => [
        PidFile => $self->pid_file_path,
        Listen  => $self->listen_port,
        @{$self->_module_manager->include_modules},
        @{$self->config},
      ]
    );
  },
);

=head3 config

Takes an arrayref of values to pass to L<Test::Instance::Apache::Config>.

=cut

has config => (
  is => 'ro',
  default => sub { return [] },
);

=head3 modules

Takes an arrayref of modules to load into Apache. These are the same names as
they appear in C<a2enmod>, so only the modules which are available on your
local machine can be used.

=cut

has modules => (
  is => 'ro',
  required => 1,
  isa => sub { die "modules must be an array!\n" unless ref $_[0] eq 'ARRAY' },
);

has _module_manager => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return Test::Instance::Apache::Modules->new(
      modules => $self->modules,
      server_root => $self->server_root,
    );
  },
);

=head3 pid_file_path

Path to the pid file for Apache. Defaults to C<$server_root/httpd.pid>.

=cut

has pid_file_path => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return File::Spec->catfile( $self->server_root, 'httpd.pid' );
  },
);

=head3 listen_port

Port for Apache master process to listen on. If not set, will use
L<Net::EmptyPort/empty_port> to find an unused high-number port.

=cut

has listen_port => (
  is => 'lazy',
  builder => sub {
    return empty_port;
  },
);

=head3 apache_httpd

Path to the main Apache process. Uses L<File::Which/which> to determine the
path of the binary from your C<$PATH>.

=cut

has apache_httpd => (
  is => 'lazy',
  builder => sub {
    my ($httpd) = do {
      local $ENV{PATH} = join( ':',
        map {
          my $copy = $_;
          ( $copy =~ s!/bin$!/sbin!
              ? ( $copy,$_ )
              : $_
          )
        } split ':', $ENV{PATH}
      );
      grep defined, map scalar( which $_ ), qw/ httpd apache apache2 /;
    };
    return $httpd if defined $httpd;
    die "Apache server program not found - please check your path\n";
  },
);

=head3 pid

Pid number for the main Apache process. Set during L</run> and then used during
L</DEMOLISH> to kill the correct process.

=cut

has pid => ( is => 'rwp' );

sub _httpd_cmd {
  my $self = shift;

  return join ( ' ', $self->apache_httpd,
    '-d', $self->server_root,
    '-f', $self->conf_file_path,
  );
}

=head2 Methods

These are the various methods inside this module either for internal or basic
usage.

=head3 run

Sets up all the pre-required folders, writes the config files, loads the
required modules, and then starts Apache itself.

=cut

sub run {
  my $self = shift;

  $self->_config_manager->write_config;
  $self->_module_manager->load_modules;
  $self->log_dir;

  # capture will wait until the standard apache fork has finished
  capture( $self->_httpd_cmd );

  for (1 .. 10) {
    $self->_set_pid( $self->get_pid );
    last if defined $self->pid;
    sleep 1;
  }
}

=head3 make_server_dir

Used internally to create folders under the server root. Will take an array of
directory names, which are then passed to File::Spec - so if you do the
following:

  $instance->make_server_dir( 'a', 'b', 'c' );

Then a path of C<$server_root/a/b/c> will be created.

=cut

sub make_server_dir {
  my ( $self, @dirnames ) = @_;
  my $dir = File::Spec->catdir( $self->server_root, @dirnames );
  mkdir $dir;
  return $dir;
}

=head3 get_pid

Returns the contents of the first line of the pid file. Used internally to set
the pid after startup.

=cut

sub get_pid {
  my $self = shift;

  my $pid = undef;
  if ( -f $self->pid_file_path ) {
    open( my $fh, '<', $self->pid_file_path );
    $pid = <$fh>; # read first line
    chomp $pid;
    close $fh;
  }
  return $pid;
}

=head3 get_logs

This will return all the items in the log directory as a hashref of filename
and content. This is useful either during test development, or if you are
testing exceptions on your application. Please note that it does not recurse
subdirectories in the logs folder.

=cut

sub get_logs {
  my $self = shift;

  my $logs = {};
  my @files = io->dir( $self->log_dir )->all;
  for my $file ( @files ) {
    $logs->{ $file->filename } = $file->slurp;
  }

  return $logs;
}

=head3 debug

This is more for use during development of this module - prints out the path of
all the files and folders stored as attributes in this module.

=cut

sub debug {
  my $self = shift;
  for my $item ( qw/ server_root conf_dir conf_file_path apache_httpd / ) {
    my $string = sprintf( "%16s | [%s]\n", $item, $self->$item );
    print $string;
  }
}

=head3 DEMOLISH

Kills the Apache instance started during run.

=cut

sub DEMOLISH {
  my $self = shift;

  if ( my $pid = $self->pid ) {
    # print "Killing apache with pid " . $pid . "\n";
    for my $signal ( qw/ TERM TERM INT KILL / ) {
      $self->_kill_pid($signal);
      for ( 1..10 ) {
        last unless $self->_kill_pid( 0 );
        sleep 1;
      }
      last unless $self->_kill_pid( 0 );
    }
  }
}

sub _kill_pid {
  my ( $self, $signal ) = @_;

  #print "Signal [" . $signal . "]\n";
  #print "Pid [" . $self->pid . "]\n";
  return undef unless $self->pid;
  my $ret = kill $signal, $self->pid;
  #print "Kill Return code: [" . $ret . "]\n";
  return $ret;
}

=head1 AUTHOR

Tom Bloor E<lt>t.bloor@shadowcat.co.ukE<gt>

Initial development sponsored by L<Runbox|http://www.runbox.com/>

=head1 COPYRIGHT

Copyright 2016 Tom Bloor

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Test::Instance::Apache::Config>

=item * L<Test::Instance::Apache::Modules>

=item * L<Apache::Test>

=back

=cut

1;
