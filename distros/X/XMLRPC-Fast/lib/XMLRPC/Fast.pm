package XMLRPC::Fast;

use strict;
use warnings;

use B               qw< svref_2object SVf_IOK SVf_NOK >;
use Encode;
use Exporter        qw< import >;
use MIME::Base64;
use XML::Parser;


our $VERSION = "0.11";

our @EXPORT = qw<
    decode_xmlrpc encode_xmlrpc
    encode_xmlrpc_request encode_xmlrpc_response encode_xmlrpc_fault
>;


my $utf8 = find_encoding("UTF-8");



#
# encode_xmlrpc_request()
# ---------------------
sub encode_xmlrpc_request {
    encode_xmlrpc(method => @_)
}


#
# encode_xmlrpc_response()
# ----------------------
sub encode_xmlrpc_response {
    encode_xmlrpc(response => "", @_)
}


#
# encode_xmlrpc_fault()
# -------------------
sub encode_xmlrpc_fault {
    encode_xmlrpc(fault => "", $_[0], $_[1])
}


#
# encode_xmlrpc()
# -------------
sub encode_xmlrpc {
    my ($type, $method, @args) = @_;

    my $tag = $type eq "method" ? "methodCall" : "methodResponse";

    my $xml = q{<?xml version="1.0" encoding="UTF-8"?>};
    $xml .= "<$tag>";
    $xml .= "<methodName>$method</methodName>" if $type eq "method";

    if ($type eq "fault") {
        $args[0] = "" unless defined $args[0];
        $args[1] = "" unless defined $args[1];

        $xml .= "<fault><value><struct><member><name>faultCode</name>"
              . "<value><int>$args[0]</int></value></member>"
              . "<member><name>faultString</name>"
              . "<value><string>$args[1]</string></value></member>"
              . "</struct></value></fault>"
    }
    else {
        if (@args) {
            $xml .= "<params>";
            $xml .= "<param><value>".encode_xmlrpc_thing($_)."</value></param>"
                for @args;
            $xml .= "</params>";
        }
    }

    $xml .= "</$tag>";
}


#
# encode_xmlrpc_thing()
# -------------------
sub encode_xmlrpc_thing {
    if (ref $_[0]) {
        # handle structures and objects
        my $struct = $_[0];

        if (ref $struct eq "ARRAY") {
            return join "",
                "<array><data>",
                (map encode_xmlrpc_thing($_), @$struct),
                "</data></array>"
        }
        elsif (ref $struct eq "HASH") {
            return join "",
                "<struct>",
                (map "<member><name>$_</name><value>"
                    . encode_xmlrpc_thing($struct->{$_})
                    . "</value></member>",
                    keys %$struct),
                "</struct>"
        }
        elsif (ref $struct eq "DateTime") {
            my $date = $struct->strftime("%Y-%m-%dT%H:%M:%S");
            return "<dateTime.iso8601>$date</dateTime.iso8601>"
        }
        elsif (ref $struct eq "DateTime::Tiny") {
            my $date = $struct->as_string;
            return "<dateTime.iso8601>$date</dateTime.iso8601>"
        }
    }
    else {
        # handle scalar values
        return "<nil/>" if not defined $_[0];

        my $copy  = $_[0];
        my $sv    = svref_2object(\$_[0]);

        return "<double>$copy</double>" if $sv->FLAGS & SVf_NOK;
        return "<int>$copy</int>"       if $sv->FLAGS & SVf_IOK;

        if (Encode::is_utf8($_[0])) {
            $copy = $utf8->encode($_[0]);
        }

        if ($copy ne $_[0] or $copy =~ /[^\x09\x0a\x0d\x20-\x7f]/) {
            return "<base64>" . encode_base64($copy, "") . "</base64>"
        }
        else {
            $copy =~ s/&/&amp;/g;
            $copy =~ s/</&lt;/g;
            $copy =~ s/>/&gt;/g;
            return "<string>$copy</string>"
        }
    }
}


#
# decode_xmlrpc()
# -------------
sub decode_xmlrpc {
    my ($xml) = shift;

    # parse the XML document
    my $parser = XML::Parser->new(Style => "Tree");
    my $tree = $parser->parse($xml);
    my $root = $tree->[1];
    my %struct;

    # detect the message type
    if ($tree->[0] eq "methodCall") {
        $struct{type} = "request";
    }
    elsif ($tree->[0] eq "methodResponse") {
        $struct{type} = "response";
    }
    else {
        die "unknown type of message";
    }

    # handle first-level elements + detect if fault message
    while (defined (my $e = shift @$root)) {
        next if ref $e eq "HASH";           # skip attributes
        shift @$root and next if $e eq "0"; # skip text outside elements

        if ($e eq "params") {
            $struct{params} = [ decode_node(shift @$root) ];
        }
        elsif ($e eq "methodName") {
            $struct{methodName} = (shift @$root)->[2];
        }
        elsif ($e eq "fault") {
            %struct = (
                type    => "fault",
                fault   => decode_node(shift @$root),
            );
        }
    }

    return \%struct;
}


#
# decode_node()
# -----------
sub decode_node {
    my ($node) = shift;
    my @result;

    while (defined (my $e = shift @$node)) {
        next if ref $e eq "HASH";           # skip attributes
        shift @$node and next if $e eq "0"; # skip text outside elements

        if ($e eq "value") {
            # small dance to correctly handle empty values, which must
            # generate an undef in order to keep things balanced
            my $v = shift @$node;
            push @result, @$v > 1 ? decode_node($v) : undef;
        }
        elsif ($e eq "data" or $e eq "member" or $e eq "param") {
            push @result, decode_node(shift @$node);
        }
        elsif ($e eq "array") {
            push @result, [ decode_node(shift @$node) ];
        }
        elsif ($e eq "struct") {
            push @result, { decode_node(shift @$node) };
        }
        elsif ($e eq "int" or $e eq "i4" or $e eq "boolean") {
            push @result, int((shift @$node)->[2]);
        }
        elsif ($e eq "double") {
            push @result, (shift @$node)->[2] / 1.0;
        }
        elsif ($e eq "string" or $e eq "name" or $e eq "dateTime.iso8601") {
            push @result, (shift @$node)->[2];
        }
        elsif ($e eq "base64") {
            push @result, decode_base64((shift @$node)->[2]);
        }
        elsif ($e eq "nil") {
            push @result, undef;
        }
    }

    return @result
}



__END__

=pod

=encoding UTF-8

=head1 NAME

XMLRPC::Fast - fast XML-RPC encoder/decoder

=head1 SYNOPSIS

    use XMLRPC::Fast;

    my $xml = encode_xmlrpc_request("auth.login" => {
        username => "cjohnson", password => "tier3"
    });

    my $rpc = decode_xmlrpc($xml);


=head1 DESCRIPTION

C<XMLRPC::Fast>, as its name suggests, tries to be a fast XML-RPC encoder
& decoder. Contrary to most other XML-RPC modules on the CPAN, it doesn't
offer a RPC-oriented framework, and instead behaves more like a serialization
module with a purely functional interface. The other main difference is
that, contrary to other XML-RPC modules, which all use regexps to detect
scalar types, XMLRPC::Fast uses Perl's internal flags. See L<"MAPPING">
for more details. This choice was made because there are many kinds of
data which can defeat the regexps, and a string can be confused with an
integer. This module should DWIM most of the time, but it might not
correspond to your own use cases.


=head1 RATIONALE

This module was born because in my current $work, we heavily use XML-RPC
messages over a pure TCP socket, not over HTTP like most modules assume.
As such, the RPC framework provided by the other modules is of no use,
and we simply use their serialization methods (which are not always well
documented). The module we use the most (because yes, we use more than one;
don't ask) is L<XMLRPC::Lite>, and basically only in one of these ways:

=over

=item *

encoding a XML-RPC message:

    my $xml = XMLRPC::Serializer->envelope($type, @message);

=item *

decoding a XML-RPC message:

    my $rpc = XMLRPC::Deserializer->deserialize($xml)->root

=back

C<XMLRPC::Fast> API was therefore made to follow these use cases, all the
while being faster.

=head1 MAPPING

This section describes how C<XMLRPC::Fast> maps types between Perl and
XML-RPC. It tries to do the right thing, but probably fails in some corner
cases.

=head2 XML-RPC to Perl

=head3 array

A XML-RPC C<array> becomes a Perl array reference.

=head3 base64

A XML-RPC C<base64> is decoded with L<MIME::Base64> and provided as
a Perl string value.

=head3 boolean

A XML-RPC C<boolean> becomes a Perl integer value (IV).
Note that the value is coerced to become an integer, which can lead to
surprises if the value was incorrectly typed.

=head3 date/time

A XML-RPC C<dateTime.iso8601> becomes a Perl string value

=head3 double

A XML-RPC C<double> becomes a Perl float value (NV).
Note that the value is coerced to become a float, which can lead to
surprises if the value was incorrectly typed.

=head3 integer

A XML-RPC C<integer> becomes a Perl integer value (IV).
Note that the value is coerced to become an integer, which can lead to
surprises if the value was incorrectly typed.

=head3 nil

A XML-RPC C<nil> becomes the undefined value (C<undef>).

=head3 string

A XML-RPC C<string> becomes a Perl string value (PV). 
The string is not decoded, and is therefore provided as octets.

=head3 struct

A XML-RPC C<struct> becomes a Perl array reference.


=head2 Perl to XML-RPC

=head3 scalar

There is unfortunately no way in Perl to know the type of a scalar value as
we humans expect it. Perl has its own set of internal types, not exposed at
language level, and some can overlap with others. The following heuristic(*)
is applied, in this order:

=over

=item *

if the scalar is C<undef>, it is converted to a XML-RPC C<nil>;

=item *

if the scalar has the C<SVf_NOK> flag (NV, PVNV), it is assumed to be a
float value, and converted to a XML-RPC C<double>;

=item *

if the scalar has the C<SVf_IOK> flag (IV, PVIV), it is assumed to be an
integer, and converted to a XML-RPC C<int>;

=item *

otherwise, the scalar is assumed to be a string (PV); if it a string of
Perl characters, it is first encoded to UTF-8 (this may change in the future
if it appears to create more problems than it tries to solve); if control
characters are detected, the value is encoded to Base64 and sent as a
XML-RPC C<base64>; otherwise, XML specific characters (C<&>, C<< < >>, C<< > >>)
are protected and the value is sent as a XML-RPC C<string>.

=back

(*) To quote Mark Jason Dominus, "this is a fancy way of saying that it
doesn't work," yet my guess (and experience) is that this one is less
buggy at guessing types than regexps. Obviously, your mileage may vary.

=head3 array reference

Array references are converted to XML-RPC C<array> structures.

=head3 hash reference

Hash references are converted to XML-RPC C<struct> structures.

=head3 object

L<DateTime> and L<DateTime::Tiny> objects are mapped to C<dateTime.iso8601>
values, and formatted accordingly. Other types of objects are ignored.



=head1 EXPORTS

C<XMLRPC::Fast> by default exports all its public functions: C<decode_xmlrpc>,
C<encode_xmlrpc>, C<encode_xmlrpc_request>, C<encode_xmlrpc_response>,
C<encode_xmlrpc_fault>.


=head1 FUNCTIONS

=head2 decode_xmlrpc

Parse a XML-RPC message and return a structure representing the message.

Argument: XML octets

Return: structure

Examples:

    # parsing a request message
    my $xml = <<'XML';
    <?xml version="1.0" encoding="UTF-8"?>
    <methodCall>
      <methodName>fluttergency.set_level</methodName>
      <params>
        <param>
          <value>
            <struct>
              <member><name>level</name><value><int>3</int></value></member>
            </struct>
          </value>
        </param>
      </params>
    </methodCall>
    XML

    my $rpc = decode_xmlrpc($xml);

    # $rpc = {
    #     type => "request",
    #     methodName => "fluttergency.set_level",
    #     params => [{ level => 3 }],
    # }


    # parsing a response message
    my $xml = <<'XML';
    <?xml version="1.0" encoding="UTF-8"?>
    <methodResponse>
      <params>
        <param>
          <value>
            <struct>
              <member>
                <name>angel.alert</name>
                <value> <string>missing Fluttershy</string> </value>
              </member>
            </struct>
          </value>
        </param>
      </params>
    </methodResponse>
    XML

    my $rpc = decode_xmlrpc($xml);

    # $rpc = {
    #     type  => "response",
    #     params => [{ "angel.alert" => "missing Fluttershy" }],
    # }


    # parsing a fault message
    my $xml = <<'XML'
    <?xml version="1.0" encoding="UTF-8"?>
    <methodResponse>
      <fault>
        <value>
          <struct>
            <member>
              <name>faultCode</name>
              <value> <int>20</int> </value>
            </member>
            <member>
              <name>faultString</name>
              <value> <string>needs to be 20% cooler</string> </value>
            </member>
          </struct>
        </value>
      </fault>
    </methodResponse>
    XML

    my $rpc = decode_xmlrpc($xml);

    # $rpc = {
    #     type  => "fault",
    #     fault => {
    #         faultCode => 20,  faultString => "it needs to be 20% cooler"
    #     },
    # }


=head2 encode_xmlrpc

Create a XML-RPC method message and return the corresponding XML document.
Type is C<"method"> for a request message, C<"response"> for a normal response
message, C<"fault"> for a fault response message. Method name is only used
for request messages.

Arguments: type of message, method name, parameters

Return: XML octets

Examples:

    # create a request message
    my $xml = encode_xmlrpc(request =>
        "fluttergency.set_level", { level => 3 });

    # create a normal response message
    my $xml = encode_xmlrpc(response => "",
        {"angel.alert" => "missing Fluttershy"});

    # create a fault response message
    my $xml = encode_xmlrpc(fault => 20, "it needs to be 20% cooler");


=head2 encode_xmlrpc_request

Create a XML-RPC method request message and return the corresponding XML
document. Calls C<encode_xmlrpc()> with the type C<"method"> and the rest
of the arguments.

Arguments: method name, parameters

Return: XML octets

Example:

    my $xml = encode_xmlrpc_request("fluttergency.set_level", { level => 3 });

    # <?xml version="1.0" encoding="UTF-8"?>
    # <methodCall>
    #   <methodName>fluttergency.set_level</methodName>
    #   <params>
    #     <param>
    #       <value>
    #         <struct>
    #           <member>
    #             <name>level</name>
    #             <value> <int>3</int> </value>
    #           </member>
    #         </struct>
    #       </value>
    #     </param>
    #   </params>
    # </methodCall>


=head2 encode_xmlrpc_response

Create a XML-RPC method response message and return the corresponding XML
document. Calls C<encode_xmlrpc()> with the type C<"response"> and the rest
of the arguments.

Arguments: parameters

Return: XML octets

Example:

    my $xml = encode_xmlrpc_response({"angel.alert" => "missing Fluttershy"});

    # <?xml version="1.0" encoding="UTF-8"?>
    # <methodResponse>
    #   <params>
    #     <param>
    #       <value>
    #         <struct>
    #           <member>
    #             <name>angel.alert</name>
    #             <value> <string>missing Fluttershy</string> </value>
    #           </member>
    #         </struct>
    #       </value>
    #     </param>
    #   </params>
    # </methodResponse>


=head2 encode_xmlrpc_fault

Create a XML-RPC method fault message and return the corresponding XML
document. Calls C<encode_xmlrpc()> with the type C<"response"> and the
appropriate structure filled with the given arguments.

Arguments: fault code, fault string

Return: XML octets

Example:

    my $xml = encode_xmlrpc_fault(20, "it needs to be 20% cooler");

    # <?xml version="1.0" encoding="UTF-8"?>
    # <methodResponse>
    #   <fault>
    #     <value>
    #       <struct>
    #         <member>
    #           <name>faultCode</name>
    #           <value> <int>20</int> </value>
    #         </member>
    #         <member>
    #           <name>faultString</name>
    #           <value> <string>needs to be 20% cooler</string> </value>
    #         </member>
    #       </struct>
    #     </value>
    #   </fault>
    # </methodResponse>


=head1 SIMILAR MODULES

This section describes the author's impressions about the other XML-RPC
modules available on the CPAN. You can find scripts to runs bench tests,
with both L<Benchmark> and L<Dumbbench>, in the F<tools/> directory of the
distribution.

=over

=item *

L<Frontier::RPC2> -- As I understand it, the grandparent of all XML-RPC
modules on the CPAN, made by the people who proposed the XML-RPC spec in
the first place, back in 1998. Very old (last release in 2002 or 2004).
Documented. Very fast; actually the fastest XML-RPC module on the CPAN
until C<XMLRPC::Fast>, and still is for decoding.

Encoding is very fast, but relies on regexps to detect scalar types.

    my $xml = Frontier::RPC2->new->encode_call(@message);

Decoding is very fast, based on L<XML::Parser>, but returns a structure
with objects, making it less practical than a pure Perl structure.

    my $rpc = Frontier::RPC2->new->decode($xml);

=item *

L<RPC::XML> -- Developped since a long time (2001-today).
Very well documented.

Encoding is pretty fast, but relies on regexps to detect scalar types.

    my $xml = RPC::XML::request->new(@message)->as_string;

Decoding is pretty fast, using either L<XML::Parser> or L<XML::LibXML>.

    my $rpc = RPC::XML::ParserFactory->new->parse($xml);

=item *

L<XML::Compile::RPC> -- Recent (2009-2013). Heavily object oriented,
complex to use. Strangely documented. Completely RPC/HTTP oriented,
client-side only, can't be used for generic encoding/decoding.

Encoding is slow, and a bit tedious given the complex structure you
need to give it in order to specify everything.

=item *

L<XML::RPC> -- Old (2008), basic documentation. Does not handle the
C<base64> type.

Encoding is slow and relies on regexps to detect scalar types

    my $xml = XML::RPC->new("")->create_call_xml(@message);

Decoding uses L<XML::TreePP>, and is therefore very slow.

    my $client = XML::RPC->new("");
    my ($method, @params) = $client->unparse_call($client->{tpp}->parse($xml));

=item *

L<XMLRPC::Lite> -- Barely documented, based on L<SOAP::Lite>, therefore
very object oriented and more than a bit heavy. On the positive side, this
allows you to override how the values are guessed.

Encoding is slow and relies on regexps to detect scalar types.

    my $xml = XMLRPC::Serializer->envelope(method => @message);

Decoding is quite slow.

    my $rpc = XMLRPC::Deserializer->deserialize($xml)->root;

=back

If C<XMLRPC::Fast> doesn't fit your needs, L<RPC::XML> is probably
your best bet.


=head1 CREDITS

The XML-RPC standard is Copyright 1998-2004 UserLand Software, Inc.
See L<http://www.xmlrpc.com/> for more information about the XML-RPC
specification.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>saper@cpan.orgE<gt>

