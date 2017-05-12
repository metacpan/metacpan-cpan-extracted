package ebXML;

# standard
use strict;
use vars qw($AUTOLOAD $VERSION);
use Data::Dumper;

# XML stuff
use XML::Xerces;
use ebXML::Message;

# Xerces parsers (one for Schema, DTD and neither)
my $validate = $XML::Xerces::AbstractDOMParser::Val_Auto;
my $schemaparser = XML::Xerces::XercesDOMParser->new();
my $dtdparser = XML::Xerces::XercesDOMParser->new();
my $plainparser = XML::Xerces::XercesDOMParser->new();
my $error_handler = XML::Xerces::PerlErrorHandler->new();
my $c = 0;
foreach ( $schemaparser, $dtdparser, $plainparser) {
  $_->setValidationScheme ($validate);
  $_->setDoNamespaces (1);
  $_->setCreateEntityReferenceNodes(1);
  $_->setErrorHandler($error_handler);
}
$schemaparser->setDoSchema (1);

$VERSION = 0.01;

=head1 NAME

ebXML - a module for ebXML message services

=head1 DESCRIPTION

This module provides some basic ebXML Messaging functionality
using ebXML::Message objects and XML::Xerces XML parser.

=head1 SYNOPSIS

use ebXML;
use ebXML::Message;

my $message = ebXML->process_header($xml);

=head1 METHODS

=over

=cut

# Message Packaging.
# The final enveloping of an ebXML Message (ebXML header elements and payload) into its SOAP Messages with Attachments container.


sub build_header {
    warn "error : not implemented yet\n";
    return 0;
}

sub build_message {
    warn "error : not implemented yet\n";
    return 0;
}


#
# Processing functions

=head2 process_header($request)

  returns ebXML::Message object with status, etc set

  my $message = process_header($request, %options) or die "err:$!";

  if ($message->isActionRequired) {
     # do stuff

     ebXML->add_to_queue($message);

     log("foo\n");

     . . . do stuff . . .

  } else {
     # leave it to the module to handler error, ack, duplicates, etc
     log ("bar\n");
  }

  $reponse->set_message($message);

  $reponse->issue();

=cut
sub process_header {
  my ($class, $xml, %options) = (@_);

  my $parser = $plainparser;
  my $tmpfile = "/tmp/ebXML-".time.".xml";
  open (XML,">$tmpfile") or die "couldn't open tmp file ($tmpfile) : $! \n";
  print XML $xml;
  close XML;
  my $error_handler = XML::Xerces::PerlErrorHandler->new();
  $parser->setErrorHandler($error_handler);
  eval { $parser->parse ($tmpfile); };
  XML::Xerces::error($@) if ($@);

  my $doc = $parser->getDocument ();
  my $message = ebXML::Message->new_from_DOMDocument ($doc);

  unlink $tmpfile;

  return $message;
}

=head2 process_message($request)

=cut
sub process_message {
  my ($class, $xml, %options) = (@_);

  my $parser = $plainparser;
  my $tmpfile = "/tmp/ebXML-".time.".xml";
  open (XML,">$tmpfile") or die "couldn't open tmp file ($tmpfile) : $! \n";
  print XML $xml;
  close XML;
  my $error_handler = XML::Xerces::PerlErrorHandler->new();
  $parser->setErrorHandler($error_handler);
  eval { $parser->parse ($tmpfile); };
  XML::Xerces::error($@) if ($@);

  my $doc = $parser->getDocument ();
  my $message = ebXML::Message->new_from_DOMDocument ($doc);

  unlink $tmpfile;

  return $message;
}

=back

=head1 AUTHOR

Aaron Trevena

=head1 COPYRIGHT

(C)Copyright 2003 Surrey Technologies, Ltd

=cut

###########################################################
###########################################################

1;
