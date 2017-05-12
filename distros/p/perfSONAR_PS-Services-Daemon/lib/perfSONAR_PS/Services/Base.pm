package perfSONAR_PS::Services::Base;

use fields 'CONF',
	'DIRECTORY',
	'ENDPOINT',
	'PORT';

use strict;
use warnings;
use Log::Log4perl qw(get_logger);

our $VERSION = 0.09;

sub new {
	my ($class, $conf, $port, $endpoint, $directory) = @_;

	my $self = fields::new($class);

	if(defined $conf and $conf ne "") {
		$self->{CONF} = \%{$conf};
	}

	if (defined $directory and $directory ne "") {
		$self->{DIRECTORY} = $directory;
	}

	if (defined $port and $port ne "") {
		$self->{PORT} = $port;
	}

	if (defined $endpoint and $endpoint ne "") {
		$self->{ENDPOINT} = $endpoint;
	}

	return $self;
}

sub setConf {
  my ($self, $conf) = @_;   
  my $logger = get_logger("perfSONAR_PS::Services::Base");
  
  if(defined $conf and $conf ne "") {
    $self->{CONF} = \%{$conf};
  }
  else {
    $logger->error("Missing argument."); 
  }
  return;
}

sub setPort {
  my ($self, $port) = @_;   
  my $logger = get_logger("perfSONAR_PS::Services::Base");
  
  if(defined $port and $port ne "") {
    $self->{PORT} = $port;
  }
  else {
    $logger->error("Missing argument."); 
  }
  return;
}

sub setEndpoint {
  my ($self, $endpoint) = @_;   
  my $logger = get_logger("perfSONAR_PS::Services::Base");
  
  if(defined $endpoint and $endpoint ne "") {
    $self->{ENDPOINT} = $endpoint;
  }
  else {
    $logger->error("Missing argument."); 
  }
  return;
}

sub setDirectory {
  my ($self, $directory) = @_;   
  my $logger = get_logger("perfSONAR_PS::Services::Base");
  
  if(defined $directory and $directory ne "") {
    $self->{DIRECTORY} = $directory;
  }
  else {
    $logger->error("Missing argument."); 
  }
  return;
}

1;


__END__
=head1 NAME

perfSONAR_PS::Services::Base - A module that provides basic methods for Servicess.

=head1 DESCRIPTION

This module aims to offer simple methods for dealing with requests for information, and the 
related tasks of interacting with backend storage.  

=head1 SYNOPSIS

    use perfSONAR_PS::Services::Base;

    my %conf = ();
    $conf{"METADATA_DB_TYPE"} = "xmldb";
    $conf{"METADATA_DB_NAME"} = "/home/jason/perfSONAR-PS/MP/SNMP/xmldb";
    $conf{"METADATA_DB_FILE"} = "snmpstore.dbxml";
    
    my %ns = (
      nmwg => "http://ggf.org/ns/nmwg/base/2.0/",
      netutil => "http://ggf.org/ns/nmwg/characteristic/utilization/2.0/",
      nmwgt => "http://ggf.org/ns/nmwg/topology/2.0/",
      snmp => "http://ggf.org/ns/nmwg/tools/snmp/2.0/"    
    );
    
    my $self = perfSONAR_PS::Services::Base->new(\%conf, \%ns);

    # or
    # $self = perfSONAR_PS::Services::Base->new;
    # $self->setConf(\%conf);
    # $self->setNamespaces(\%ns);              

    $self->init;
    
    my $response = $self->respond;
    if(!$response) {
      $self->error($self, "Whoops...", __LINE__)
    }

=head1 DETAILS

This API is a work in progress, and still does not reflect the general access needed in an Services.
Additional logic is needed to address issues such as different backend storage facilities.  

=head1 API

The offered API is simple, but offers the key functions we need in a measurement archive. 

=head2 new(\%conf, \%ns)

The accepted arguments may also be ommited in favor of the 'set' functions.

=head2 setConf(\%conf)

(Re-)Sets the value for the 'conf' hash. 

=head2 init()

Initialize the underlying transportation medium.  This function depends
on certain conf file values.

=head2 respond()

Send message stored in $self->{RESPONSE}.

=head2 keyRequest(($self, $metadatadb, $m, $localContent, $messageId, $messageIdRef)

DEPRICATED

=head1 SEE ALSO

L<Exporter>, L<Log::Log4perl>, L<perfSONAR_PS::Transport>, 
L<perfSONAR_PS::Messages>, L<perfSONAR_PS::Services::General>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id: Base.pm 524 2007-09-05 17:35:50Z aaron $

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
