package XAS::Lib::WS::Base;

our $VERSION = '0.01';

use Try::Tiny;
use Data::UUID;
use HTTP::Request;
use XAS::Lib::XML;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Curl::HTTP',
  accessors => 'xml uuid',
  utils     => ':validation dotid',
  constants => 'TRUE FALSE',
  vars => {
    PARAMS => {
      -default_namespace => { optional => 1, default => 'wsman' },
      -url               => { optional => 1, default => 'http://localhost:5985/wsman' },
    }
  },
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub identify {
    my $self = shift;

    my $nodes;
    my $vendor = '';
    my $version = '';
    my $protocol = '',
    my $xpath = '//wsmid:IdentifyResponse';

    my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
    s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
    xmlns:s="http://www.w3.org/2003/05/soap-envelope"
    xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
    xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <s:Header>
    <WinRM>Is a pain</WinRM>
  </s:Header>

  <s:Body>
    <wsmid:Identify />
  </s:Body>
</s:Envelope>
XML

    $self->_make_call($xml);
    $nodes = $self->xml->get_items($xpath);

    foreach my $node (@$nodes) {

        $protocol = $node->textContent if ($node->nodeName =~ /ProtocolVersion/);
        $version  = $node->textContent if ($node->nodeName =~ /ProductVersion/);
        $vendor   = $node->textContent if ($node->nodeName =~ /ProductVendor/);

    }

    return $protocol, $vendor, $version;

}

sub connected {
    my $self = shift;

    $self->identify();

    return TRUE;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _make_call {
    my $self = shift;
    my ($xml) = validate_params(\@_, [1]);

    my $response;
    my $count = 0;
    my $request = HTTP::Request->new(POST => $self->url);

    $request->header('Accept' => [
        'text/xml', 'multipart/*', 'application/soap'
    ]);

    $request->header('SOAPAction',  => '#WinRM');
    $request->header('User-Agent',  => 'XAS-WebServices');
    $request->header('Content-Type' => 'application/soap+xml;charset=UTF-8');
    $request->header('Connection'   => 'Keep-Alive') if ($self->keep_alive);

    $request->content($xml);

    $self->log->debug(sprintf("make_call - request:\n%s", $request->as_string));
    $response = $self->request($request);

    if ($response->is_success) {

        my $stuff = $response->content;
        $self->xml->load($stuff);
        $self->log->debug(sprintf("make_call - reponse:\n%s", $self->xml->doc->toString(1)));

    } else {

        if ($response->code eq '500') {
            
            my $stuff = $response->content;
            $self->xml->load($stuff);
            $self->log->debug(sprintf("make_call - reponse:\n%s", $self->xml->doc->toString(1)));
            
            $self->_error_msg;
            
        } else {

            $self->throw_msg(
                dotid($self->class) . '._make_call.request',
                'ws_badrequest',
                $response->status_line
            );

        }

    }

}

sub _check_relates_to {
    my $self = shift;
    my ($uuid) = validate_params(\@_, [1]);

    my $temp;
    my $xpath = '//a:RelatesTo';

    $temp = $self->xml->get_item($xpath);
    ($temp) = $temp =~ /uuid:(.*)/;

    $self->log->debug(sprintf('check_relates_to: %s = %s', $uuid, $temp));

    unless ($temp eq $uuid) {

        $self->throw_msg(
            dotid($self->class) . '.check_relates_to.wronguuid',
            'ws_wronguuid'
        );

    }

}

sub _check_action {
    my $self = shift;
    my $action = shift;

    my $xpath = '//a:Action';
    my $item = $self->xml->get_item($xpath);

    $self->log->debug(sprintf('check_action: %s =~ %s', $action, $item));

    unless ($item =~ /$action/) {

        $self->throw_msg(
            dotid($self->class) . '.check_action.wrongaction',
            'ws_wrongaction',
            $action
        );

    }

}

sub _error_msg {
    my $self = shift;

    my $message = '';
    my $extended = '';
    my $wsmanfault = '';
    my $faultdetail = '';
    my $extendederror = '';
    my $providerfault = '';

    my $value   = $self->xml->get_item('/s:Envelope/s:Body/s:Fault/s:Code/s:Value');
    my $subcode = $self->xml->get_item('/s:Envelope/s:Body/s:Fault/s:Code/s:Subcode/s:Value');
    my $reason  = $self->xml->get_item('/s:Envelope/s:Body/s:Fault/s:Reason/s:Text');

    if (my $text = $self->xml->get_item('/s:Envelope/s:Body/s:Fault/s:Detail/w:FaultDetail')) {

        $faultdetail = sprintf(', error type: %s', $text);

    }

    if (my $nodes = $self->xml->get_node('/s:Envelope/s:Body/s:Fault/s:Detail/f:WSManFault')) {

        foreach my $node (@$nodes) {

            if ($node->localname eq 'WSManFault') {

                $wsmanfault = sprintf(', machine: %s, code: %s',
                    $node->getAttribute('Machine'),
                    $node->getAttribute('Code')
                );

                last;

            }

        }

    }

    if (my $node = $self->xml->get_node('/s:Envelope/s:Body/s:Fault/s:Detail/f:WSManFault/f:Message')) {

        unless (ref($node) eq 'XML::LibXML::NodeList') {

            $message = sprintf(', message: %s', $node->textContent);

        }

    }

    if (my $nodes = $self->xml->get_node('/s:Envelope/s:Body/s:Fault/s:Detail/f:WSManFault/f:Message/f:ProviderFault')) {

        if (ref($nodes) eq 'XML::LibXML::NodeList') {

            foreach my $node (@$nodes) {

                if ($node->localname eq 'ProviderFault') {

                    $providerfault = sprintf(', path: %s, provider: %s',
                        $node->getAttribute('path'),
                        $node->getAttribute('provider')
                    );

                    last;

                }

            }

        } else {

            $providerfault = sprintf(', path: %s, provider: %s',
                $nodes->getAttribute('path'),
                $nodes->getAttribute('provider')
            );

        }

    }

    if (my $nodes = $self->xml->get_items('/s:Envelope/s:Body/s:Fault/s:Detail/f:WSManFault/f:Message/f:ProviderFault/f:ExtendedError')) {

        foreach my $child (@$nodes)  {

            next if ($child->localname eq '_ExtendedStatus');

            $extendederror .= sprintf(', %s: %s', $child->localname, $child->textContent);

        }

    }

    $extended = $faultdetail . $message . $wsmanfault . $providerfault . $extendederror;

    $self->throw_msg(
        dotid($self->class) . '.request.protocol',
        'ws_protocol',
        $value, $subcode, $reason, $extended
    );

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'uuid'} = Data::UUID->new();

    $self->{'xml'} = XAS::Lib::XML->new(
        -default_namespace => $self->default_namespace
    );

    return $self;

}

1;

__END__
  
=head1 NAME

XAS::Lib::WS::Base - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::WS::Base;

 my $wsman = XAS::Lib::WS::Base->new(
     -username    => 'username',
     -password    => 'password',
     -url         => 'http://windowserver:5985/wsman',
     -auth_method => 'any',
 );

 my ($protocol, $vendor, $version) = $wsman->identify();

 printf("vendor:   %s\n", $vendor);
 printf("version:  %s\n", $version);
 printf("protocol: %s\n", $protocol);

=head1 DESCRIPTION

This package initilaizes and provides some basic methods for using WS-Manage
functionality.

=head1 METHODS

=head2 new

This class inherits from L<XAS::Lib::Curl::HTTP|XAS::Lib::Curl::HTTP> and uses
the same parameters.

=head2 identify

This method makes an identify call to the server and returns the following
values.

     $vendor   - the vendor of the remote servers
     $protocol - the protocol the remote server is using
     $version  - the version of that protocol
   
=over 4

=item B<Example:>

 my ($protocol, $vendor, $version) = $wsman->indentify;

=back

=head2 connected

This method returns TRUE or FALSE on wither it can connect to the remote server.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::WS::Transfer|XAS::Lib::WS::Transfer>

=item L<XAS::Lib::WS::RemoteShell|XAS::Lib::WS::RemoteShell>

=item L<XAS::Lib::WS::Manage|XAS::Lib::WS::Manage>

=item L<XAS::Lib::WS::Exec|XAS::Lib::WS::Exec>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
