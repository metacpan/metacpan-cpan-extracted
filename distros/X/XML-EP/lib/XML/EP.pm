# -*- perl -*-

use strict;
use XML::EP::Config ();
use XML::EP::Control ();
use XML::EP::Error ();
use XML::EP::Response ();

package XML::EP;

$XML::EP::VERSION = '0.01';


sub new {
    my $proto = shift;
    my $self = (@_ == 1) ? \%{ shift() } : { @_ };
    bless($self, (ref($proto) || $proto));
}

sub MakeConfig {
    my $self = shift;
    my $request = $self->{request};
    my $config = ($self->{config} ||= $XML::EP::Config::config || []);
    my $cfg = {};
    foreach my $c (@$config) {
	if (my $vhost = $c->{"match_virtual_host"}) {
	    my $vh = $request->VirtualHost();
	    next if !$vh  ||  $vh !~ /$vhost/;
	}
	if (my $loc = $c->{"match_location"}) {
	    my $lc = $request->Location();
	    next if !$lc  ||  $lc !~ /$loc/;
	}
	if (my $client = $c->{"match_client"}) {
	    my $cl = $request->Client();
	    next if !$cl  ||  $cl !~ /$client/;
	}
	while (my($key, $var) = each %$c) {
	    $cfg->{$key} = $var;
	}
    }
    $self->{cfg} = $cfg;
}

sub Control {
    my $self = shift;
    my $class = $self->{cfg}->{Controller} || "XML::EP::Control";
    $class->new();
}

{
    my %loaded;
    sub Require {
	my $self = shift;  my $class = shift;
	return if $loaded{$class};
	my $cl = "$class.pm";
	$cl =~ s/\:\:/\//g;
	require $cl;
	$loaded{$class} = $cl;
    }
}

sub Handle {
    my $self = shift;  $self->{request} = shift;
    $self->{response} = XML::EP::Response->new();
    eval {
	$self->MakeConfig();
	my $control = $self->Control();
	my $xml = $control->CreatePipe($self);
	while (my $p = shift @{$self->{processors}}) {
	    if (!ref($p)) {
		$self->Require($p);
		$p = $p->new();
	    }
	    $xml = $p->Process($self, $xml);
	}
	my $formatter = $self->{formatter};
	$self->Require($formatter);
	$self->{formatter}->Format($self, $xml);
    };
    $@
}

sub Processors {
    my $self = shift;
    @_ ? ($self->{processors} = shift) : $self->{processors};
}

sub Formatter {
    my $self = shift;
    @_ ? ($self->{formatter} = shift) : $self->{formatter};
}

sub Request {
    my $self = shift;
    @_ ? ($self->{request} = shift) : $self->{request};
}

sub Response {
    my $self = shift;
    @_ ? ($self->{response} = shift) : $self->{response};
}


1;

__END__

=pod

=head1 NAME

XML::EP - A framework for embedding XML into a web server


=head1 SYNOPSIS

  # Generate a new XML::EP instance
  use XML::EP();
  my $ep = XML::EP->new();

  # Let the instance process an HTTP request
  $ep->handle($request);


=head1 DESCRIPTION

XML::EP is an administrative framework for embedding XML into a
web server. That means that the system allows you to retrieve
XML documents from external storage (files, a Tamino database
engine, or whatever), parse them, pipe the parsed XML tree into
processors (modules, that change the tree, for example the DBI
processor will issue SQL queries and insert the result as XML
elements). Finally the XML tree will be piped into a so-called
formatter, that converts XML to HTML and prints the result.

The architecture is as follows:

		+---------------------+
		|   Control element   |
		+---------------------+
               /          |            \
              /           |             \
   +----------+ XML  +------------+ XML  +-----------+
   | Producer | ---> | Processors | ---> | Formatter |
   +----------+      +------------+      +-----------+

The control element, an instance of XML::EP::Control, will be
created first. Its purpose is the creation of the other
elements, the producer (an instance of XML::EP::Producer),
one or more processors (instances of XML::EP::Processor) and
finally a formatter (an instance of XML::EP::Formatter).
The producer, processors, formatters are selected based on
virtual host, location (file part of the URL being requested)
and in particular depending on the client. For example, an
HTML formatter will be selected, if the client seems to
request HTML, WML formatter will be created, if the client
appears to be WAP HANDY and so on.


=head1 METHOD INTERFACE

Public available methods are:


=head2 Creating a control element

  my $control = $ep->control();

(Instance method) This method will create an instance of
XML::EP::Control. The main task of this instance is its
I<CreatePipe> method, which will then be called for creating
an XML tree, a list of processors and a formatter.


=head2 Getting or setting the processors, formatters

  my $processors = $self->Processors();
  $self->Processors($processors);
  my $formatter = $self->Formatter();
  $self->Formatter($formatter);
  my $request = $self->Request();
  $self->Request($request);
  my $response = $self->Response();
  $self->Response($response);

(Instance methods) These methods are used for querying or modifying
the list of processors (an array ref) or the formatter. Processors
are explicitly permitted to use this methods.

The response object is designed for receiving HTTP headers, cookies,
etc. that are being sent to the client. Response objects are instances
of XML::EP::Response.


=head2 Handling an HTTP request

  $self->Handle($request);

(Instance method) This method is called with an request object (an
instance of XML::EP::Request) as argument. The request object contains
all information about the client and its request, in particular HTTP
headers, etc.

The method implements the HTTP requests full life cycle: A control
object is created (an instance of XML::EP::Control), the control
objects I<CreatePipe> method is called for creating an XML tree
and initializing the processor list and the formatter, the processors
are called and finally the formatter which has to send data to the
client.

=cut
