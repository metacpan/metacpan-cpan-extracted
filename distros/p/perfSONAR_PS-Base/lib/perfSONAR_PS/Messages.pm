package perfSONAR_PS::Messages;

use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Messages - A module that provides common methods for performing
actions on message constructs.

=head1 DESCRIPTION

This module is a catch all for message related methods in the perfSONAR-PS
framework.  As such there is no 'common thread' that each method shares.  This
module IS NOT an object, and the methods can be invoked directly (and
sparingly). 

=cut

use Exporter;
use Log::Log4perl qw(get_logger :nowarn);
use Params::Validate qw(:all);

use perfSONAR_PS::Common;
use perfSONAR_PS::ParameterValidation;

use base 'Exporter';

our @EXPORT = (
        'startMessage',
        'endMessage',
        'startMetadata',
        'endMetadata',
        'startData',
        'endData',
        'startParameters',
        'endParameters',
        'addParameter',
        'getResultCodeMessage',
        'getResultCodeMetadata',
        'getResultCodeData',
        'statusReport',
        'createMessage',
        'createMetadata',
        'createData',
        'getErrorResponseMessage',
        );

=head2 startMessage($output, $id, $messageIdRef, $type, $content, $namespaces)

Start message element.

=cut

sub startMessage {
    my ($output, $id, $messageIdRef, $type, $content, $namespaces) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    my %attrs = ();
    $attrs{"type"} = $type;
    $attrs{"id"} = $id;
    $attrs{"messageIdRef"} = $messageIdRef if (defined $messageIdRef and $messageIdRef ne "");

    return $output->startElement(prefix => "nmwg", tag => "message", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => \%attrs, extra_namespaces => $namespaces, content => $content);
}

=head2 endMessage($output)

End message element.

=cut

sub endMessage {
    my ($output) = @_;

    return $output->endElement("message");
}

=head2 startMetadata($output, $id, $metadataIdRef, $namespaces)

Start a metadata element.

=cut

sub startMetadata {
    my ($output, $id, $metadataIdRef, $namespaces) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    if (not defined $id or $id eq "") {
        $logger->error("Missing argument(s).");
        return -1;
    }

    my %attrs = ();
    $attrs{"id"} = $id;
    $attrs{"metadataIdRef"} = $metadataIdRef if (defined $metadataIdRef and $metadataIdRef ne "");

    return $output->startElement(prefix => "nmwg", tag => "metadata", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => \%attrs, extra_namespaces => $namespaces);
}

=head2 endMetadata($output)

End a metadata element.

=cut

sub endMetadata {
    my ($output) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    return $output->endElement("metadata");
}

=head2 startData($output, $id, $metadataIdRef, $namespaces)

Start a data element.

=cut

sub startData {
    my ($output, $id, $metadataIdRef, $namespaces) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    if (not defined $id or $id eq "" or not defined $metadataIdRef or $metadataIdRef eq "") {
        $logger->debug("createData failed: \"$id\" \"$metadataIdRef\"");
        return -1;
    }

    return $output->startElement(prefix => "nmwg", tag => "data", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => { id=>$id, metadataIdRef=>$metadataIdRef }, extra_namespaces => $namespaces);
}

=head2 endData($output)

End a data element

=cut

sub endData {
    my ($output) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    return $output->endElement("data");
}

=head2 startParameters($output)

Start a parameters element.

=cut

sub startParameters {
    my ($output, $id) = @_;

    return $output->startElement(prefix => "nmwg", tag => "parameters", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => { id=>$id });
}

=head2 endParameters($output)

End a parameters element.

=cut

sub endParameters {
    my ($output) = @_;

    return $output->endElement("parameters");
}

=head2 addParameter($output, $name, $value, $args)

Add a parameter element, returns the results.

=cut

# XXX this should probably ensure that the parameters are being created inside a parameters block
sub addParameter {
    my ($output, $name, $value, $args) = @_;
    my $logger = get_logger("perfSONAR_PS::Messages");
    
    # XXX jason 3/6/08 - Fix the parameters hack after conversion to new argument types
    my %attrs = ();
    if(defined $args) {
      %attrs = %{$args};
    }
    $attrs{"name"} = $name;
    
    return $output->createElement(prefix => "nmwg", tag => "parameter", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => \%attrs, content => $value);
}

=head2 getResultCodeMessage($output, $id, $messageIdRef, $metadataIdRef, $type, $event, $description, $namespaces, $escape_content)

Create an entire result code message.

=cut

sub getResultCodeMessage {
    my ($output, $id, $messageIdRef, $metadataIdRef, $type, $event, $description, $namespaces, $escape_content) = @_;   
    my $logger = get_logger("perfSONAR_PS::Messages");

    my $n;

    my $ret_mdid = "metadata.".genuid();
    my $ret_did = "data.".genuid();

    $n = startMessage($output, $id, $messageIdRef, $type, "", undef);
    return $n if ($n != 0);
    $n = getResultCodeMetadata($output, $ret_mdid, $metadataIdRef, $event);
    return $n if ($n != 0);
    $n = getResultCodeData($output, $ret_did, $ret_mdid, $description, $escape_content);
    return $n if ($n != 0);
    $n = endMessage($output);

    return 0;
}

=head2 getResultCodeMetadata($output, $id, $metadataIdRef, $event)

Create a metadata element to pair with a result code.

=cut

sub getResultCodeMetadata {
    my ($output, $id, $metadataIdRef, $event) = @_; 
    my $logger = get_logger("perfSONAR_PS::Messages");

    if (not defined $id or $id eq "" or not defined $event or $event eq "") {
        $logger->error("Missing argument(s).");
        return -1;
    }

    my %attrs = ();
    $attrs{"id"} = $id;
    $attrs{"metadataIdRef"} = $metadataIdRef if (defined $metadataIdRef and $metadataIdRef ne "");

    $output->startElement(prefix => "nmwg", tag => "metadata", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => \%attrs);
    $output->startElement(prefix => "nmwg", tag => "eventType", namespace => "http://ggf.org/ns/nmwg/base/2.0/", content => $event);
    $output->endElement("eventType");
    $output->endElement("metadata");

    $logger->debug("Result code metadata created.");

    return 0;
}

=head2 getResultCodeData($output, $id, $metadataIdRef, $description, $escape_content)

Create a data element for a result code.

=cut

sub getResultCodeData {
    my ($output, $id, $metadataIdRef, $description, $escape_content) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    if (not defined $id or $id eq "" or not defined $metadataIdRef or $metadataIdRef eq "" or not defined $description or $description eq "") {
        return -1;
    }

    if (defined $escape_content and $escape_content == 1) {
        $description = escapeString($description);
    }

    $output->startElement(prefix => "nmwg", tag => "data", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => { id=>$id, metadataIdRef=>$metadataIdRef });
    $output->startElement(prefix => "nmwgr", tag => "datum", namespace => "http://ggf.org/ns/nmwg/result/2.0/", content => $description);
    $output->endElement("datum");
    $output->endElement("data");

    return 0;
}

=head2 statusReport($output, $mdId, $mdIdRef, $dId, $eventType, $msg)

Create a 'status' pair of data and metadata.

=cut

sub statusReport {
    my ($output, $mdId, $mdIdRef, $dId, $eventType, $msg) = @_;
    my $logger = get_logger("perfSONAR_PS::Messages");

    my $n = getResultCodeMetadata($output, $mdId, $mdIdRef, $eventType);

    return $n if ($n != 0);

    return getResultCodeData($output, $dId, $mdId, $msg, 1); 
}

=head2 createMessage($output, $id, $messageIdRef, $type, $content, $namespaces)

Craft a message element.

=cut

sub createMessage {
    my ($output, $id, $messageIdRef, $type, $content, $namespaces) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    my $n = startMessage($output, $id, $messageIdRef, $type, $content, $namespaces);

    return $n if ($n != 0);

    return endMessage($output);
}

=head2 createMetadata($output, $id, $metadataIdRef, $content, $namespaces)

Craft a metadata element.

=cut

sub createMetadata {
    my ($output, $id, $metadataIdRef, $content, $namespaces) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    if (not defined $id or $id eq "") {
        $logger->error("Missing argument(s).");
        return -1;
    }

    my %attrs = ();
    $attrs{"id"} = $id;
    $attrs{"metadataIdRef"} = $metadataIdRef if (defined $metadataIdRef and $metadataIdRef ne "");

    my $n = $output->startElement(prefix => "nmwg", tag => "metadata", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => \%attrs, extra_namespaces => $namespaces, content => $content);
    return $n if ($n != 0);
    return $output->endElement("metadata");
}

=head2 createData($output, $id, $metadataIdRef, $content, $namespaces)

Craft a data element.

=cut

sub createData {
    my ($output, $id, $metadataIdRef, $content, $namespaces) = @_;  
    my $logger = get_logger("perfSONAR_PS::Messages");

    if (not defined $id or $id eq "" or not defined $metadataIdRef or $metadataIdRef eq "") {
        $logger->debug("createData failed: \"$id\" \"$metadataIdRef\"");
        return -1;
    }

    $output->startElement(prefix => "nmwg", tag => "data", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => { id=>$id, metadataIdRef=>$metadataIdRef }, extra_namespaces => $namespaces, content => $content);
    $output->endElement("data");

    return 0;
}

=head2 getErrorResponseMessage({ output, id, messageIdRef, metadataIdRef, eventType, description });

Craft an error response message.

XXX: Jason 3/12/08 - Document_string is still used here.

=cut

sub getErrorResponseMessage {
	my $args = validateParams(@_, 
			{
				output => { optional => 1 },
				id => { type => SCALAR | UNDEF, optional => 1 },
				messageIdRef => { type => SCALAR | UNDEF, optional => 1 },
				metadataIdRef => { type => SCALAR | UNDEF, optional => 1 },
				eventType => { type => SCALAR },
				description => { type => SCALAR },
			});

    my $logger = get_logger("perfSONAR_PS::Messages");

    my $output = $args->{output};
    my $id = $args->{id};
    my $messageIdRef = $args->{messageIdRef};
    my $metadataIdRef = $args->{messageIdRef};
    my $eventType = $args->{eventType};
    my $description = $args->{description};

    if (not defined $args->{id}) {
        $id = "message.".genuid();
    }

    if (not defined $args->{output}) {
        $output = new perfSONAR_PS::XML::Document_string();
    }

    my $n = getResultCodeMessage($output, $id, $messageIdRef, $metadataIdRef, "ErrorResponse", $eventType, $description, undef, 0);

    if (not defined $args->{output}) {
        return $output->getValue;
    } else {
        return 0;
    }
}

1;

__END__
 
=head1 SEE ALSO

L<Exporter>, L<Log::Log4perl>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::ParameterValidation>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
