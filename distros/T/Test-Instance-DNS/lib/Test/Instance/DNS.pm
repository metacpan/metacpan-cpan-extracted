package Test::Instance::DNS;

use Moo;
use IPC::System::Simple qw/ system /;
use Net::EmptyPort qw/ empty_port /;
use File::Temp;

our $VERSION = '0.001';

=head1 NAME

Test::Instance::DNS - Mock DNS server for testing

=head1 SYNOPSIS

  use Test::More;
  use Test::DNS;
  use Test::Instance::DNS;

  my $t_i_dns = Test::Instance::DNS->new(
    listen_addr => '127.0.0.1',
    zone_file => 't/etc/db.example.com',
  );

  $t_i_dns->run;

  my $dns = Test::DNS->new(nameservers => ['127.0.0.1']);
  $dns->object->port($t_i_dns->listen_port);

  $dns->is_a('example.com' => '192.0.2.1');

  done_testing;

=head1 DESCRIPTION

Provides a local mock DNS server usable for testing.

=cut

has listen_port => (
  is => 'lazy',
  builder => sub {
    return empty_port;
  },
);

has listen_addr => (
  is => 'lazy',
  coerce => sub {
    ref( $_[0] ) eq 'ARRAY' ? $_[0] : [ $_[0] ];
  },
  builder => sub {
    return ['::1', '127.0.0.1' ],
  },
);

has zone_file => (
  is => 'ro',
  required => 1,
);

has nameserver => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    my $module = __PACKAGE__ . '::Server';
    s/::/\//g, s/$/.pm/ for $module;
    if ( require $module ) {
      return $INC{$module};
    }
    die "Couldnt find $module";
  },
);

has pid => ( is => 'rwp' );

has _temp_dir => (
  is => 'lazy',
  builder => sub {
    return File::Temp->newdir;
  },
);

has pid_file_path => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return File::Spec->catfile( $self->_temp_dir->dirname, 'server.pid' );
  },
);

sub _nameserver_cmd {
  my $self = shift;

  return join ( ' ',
    'perl', $self->nameserver,
    'run',
    '--listen_port', $self->listen_port,
    '--zone', $self->zone_file,
    '--pid', $self->pid_file_path,
    '&',
  );
}

sub run {
  my $self = shift;

  system( $self->_nameserver_cmd );

  for (1 .. 10) {
    $self->_set_pid( $self->get_pid );
    last if defined $self->pid;
    sleep 1;
  }
}

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

sub DEMOLISH {
  my $self = shift;
 
  if ( my $pid = $self->pid ) {
    # print "Killing nameserver with pid " . $pid . "\n";
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
  return unless $self->pid;
  my $ret = kill $signal, $self->pid;
  #print "Kill Return code: [" . $ret . "]\n";
  return $ret;
}

1;

=head1 AUTHOR
 
Tom Bloor E<lt>t.bloor@shadowcat.co.ukE<gt>
 
=head1 COPYRIGHT
 
Copyright 2018- Tom Bloor
 
=head1 LICENSE
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=head1 SEE ALSO
 
L<Test::DNS> L<Net::DNS>
 
=cut
