package Test::Instance::DNS::Server;

use MooX::Options::Actions;
use Net::DNS::Nameserver;
use Net::DNS::ZoneFile;
use Net::DNS qw/ rrsort /;
use IO::All;

option listen_addr => (
  is => 'ro',
  format => 's@',
  doc => 'Addresses to listen on',
  default => sub { ['::1', '127.0.0.1' ] },
);

option listen_port => (
  is => 'ro',
  format => 'i',
  doc => 'Listen Port',
  required => 1,
);

option verbose => (
  is => 'ro',
  default => 0,
  doc => 'Turn on Verbose Debugging',
);

option zone => (
  is => 'ro',
  format => 's',
  required => 1,
  doc => 'The zone file to use',
);

option pid => (
  is => 'ro',
  format => 's',
  default => 'dns-server.pid',
  doc => 'Pidfile for the server',
);

has ns => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return Net::DNS::Nameserver->new(
      LocalAddr => $self->listen_addr,
      LocalPort => $self->listen_port,
      ReplyHandler => sub { $self->reply_handler( @_ ) },
      Verbose => $self->verbose,
    ) || die "Couldn't create nameserver object\n";
  },
);

has _zone_file => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return Net::DNS::ZoneFile->new( $self->zone );
  },
);

has _zone_data => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return [ $self->_zone_file->read ];
  },
);

has _zone_lookup => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    my $data = {};
    for my $zone ( @{ $self->_zone_data } ) {
      my $ref = ref( $zone );
      my ( $type ) = $ref =~ /^.*::(.*)$/;
      push @{ $data->{$type} }, $zone;
    }
    return $data;
  },
);

has _is_running => (
  is => 'rwp',
  default => 1,
);

has _pidfile => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return io($self->pid);
  },
);

sub BUILD {
  my $self = shift;
  $SIG{'INT'} = sub { $self->sig_handler( @_ ) };
  $SIG{'TERM'} = sub { $self->sig_handler( @_ ) };
}

sub _create_pidfile {
  my $self = shift;
  $self->_pidfile->println($$)->autoflush;
}

sub _cleanup_pidfile {
  my $self = shift;
  $self->_pidfile->unlink;
}

sub cmd_run {
  my $self = shift;
  print "Creating Nameserver on port " . $self->listen_port . "\n" if $self->verbose;

  $self->_create_pidfile;
  # same as calling main_loop on the Nameserver, but with a dropout
  while ( $self->_is_running ) {
    $self->ns->loop_once(10);
  }
  $self->_cleanup_pidfile;
}

sub sig_handler {
  my $self = shift;
  $self->_set__is_running(0);
  print "Stopping Nameserver on port " . $self->listen_port . "\n" if $self->verbose;
}

sub lookup_records {
  my $self = shift;
  my ( $qtype, $qname ) = @_;
  my @ans;
  for my $rr ( @{ $self->_zone_lookup->{ $qtype } } ) {
    push @ans, $rr if $rr->owner eq $qname;
  }
  return @ans; 
}

sub reply_handler {
  my $self = shift;

  my ( $qname, $qclass, $qtype, $peerhost, $query, $conn ) = @_;
  my ( $rcode, @ans, @auth, @add );

  print "Received query from $peerhost to " . $conn->{sockhost} . "\n" if $self->verbose;
  $query->print if $self->verbose;

  $rcode = "NOERROR";
  # use rrsort???
  if ( grep { $_ eq $qtype } qw/ A AAAA CNAME TXT SRV / ) {
    push @ans, $self->lookup_records( $qtype, $qname );
    $rcode = "NXDOMAIN" unless scalar(@ans);
  } else {
    if ( exists $self->_zone_lookup->{ $qtype } ) {
    }
    $rcode = "NXDOMAIN";
  }

  # mark the answer as authoritative (by setting the 'aa' flag)
  my $headermask = {aa => 1};

  # specify EDNS options  { option => value }
  my $optionmask = {};

  return ( $rcode, \@ans, \@auth, \@add, $headermask, $optionmask );
}

sub _run_if_script {
  unless ( caller(1) ) {
    Test::Instance::DNS::Server->new_with_actions;
  }
  return 1;
}

Test::Instance::DNS::Server->_run_if_script;
