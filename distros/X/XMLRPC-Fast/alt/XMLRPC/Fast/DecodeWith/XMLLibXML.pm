package XMLRPC::Fast::DecodeWith::XMLLibXML;
use strict;
use warnings;
use MIME::Base64;
use XML::LibXML;


#
# decode_xmlrpc()
# -------------
sub decode_xmlrpc {
    my ($xml) = shift;

    # parse the XML document
    my $parser = XML::LibXML->new(
        no_network      => 1,
        expand_xinclude => 0,
        expand_entities => 1,
        load_ext_dtd    => 0,
        no_blanks       => 1
    );

    my $doc  = $parser->parse_string($xml);
    my $root = $doc->documentElement;
    my %struct;

    # detect the message type
    if ($root->nodeName eq "methodCall") {
        $struct{type} = "request";
        $struct{methodName}
            = ($root->getChildrenByTagName("methodName"))[0]->textContent;
    }
    elsif ($root->nodeName eq "methodResponse") {
        $struct{type} = "response";

        my $fault = ($root->getChildrenByTagName("fault"))[0];

        if ($fault) {
            $struct{type}  = "fault";
            $struct{fault} = decode_value($fault->firstChild);
        }
    }
    else {
        die "unknown type of message";
    }

    # handle parameters
    my $params = ($root->getChildrenByTagName("params"))[0];
    if ($params) {
        $struct{params} = [
            map decode_value($_->firstChild),
                $params->getChildrenByTagName("param")
        ];
    }

    return \%struct
}


#
# decode_value()
# ------------
sub decode_value {
    my ($value) = shift;

    my $v    = $value->firstChild or return undef;
    my $type = $v->nodeName;

    if ($type eq "array") {
        return [
            map { decode_value($_->getChildrenByTagName("value")) }
                $v->getChildrenByTagName("data")
        ]
    }
    elsif ($type eq "struct") {
        return {
            map { ($_->getChildrenByTagName("name"))[0]->textContent,
                  decode_value($_->getChildrenByTagName("value")) }
                $v->getChildrenByTagName("member")
        }
    }
    elsif ($type eq "int" or $type eq "i4" or $type eq "boolean") {
        return int $v->textContent
    }
    elsif ($type eq "double") {
        return $v->textContent / 1.0
    }
    elsif ($type eq "base64") {
        return decode_base64($v->textContent)
    }
    else { # string, datetime
        return $v->textContent
    }
}

__PACKAGE__

__END__

=head1 NAME

XMLRPC::Fast::DecodeWith::XMLLibXML - XML-RPC decoder based on XML::LibXML

=head1 DESCRIPTION

This is an alternate decoding function for L<XMLRPC::Fast>, using L<XML::LibXML>
as the XML engine. Based on L<RPC::XML::Parser::XMLLibXML>, heavily simplified.
Performs pretty well, but a bit less than L<XML::Parser>.

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>saper@cpan.orgE<gt>


