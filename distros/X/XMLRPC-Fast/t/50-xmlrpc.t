#!perl
use utf8;
use strict;
use warnings;

use Data::Dumper;
use Encode;
use Storable    qw< dclone >;
use Test::More;
use XMLRPC::Fast;

# if we don't have Test::LongString, use Test::More's classic functions instead
BEGIN {
    if (not eval "use Test::LongString; 1") {
        eval "sub is_string { goto &Test::More::is }";
    }
}

my @modules;

#push @modules, "Frontier::RPC2"
#    if eval "use Frontier::RPC2; 1";

#push @modules, "RPC::XML"
#    if eval "use RPC::XML; use RPC::XML::ParserFactory; 1";

#push @modules, "XML::RPC"
#    if eval "use XML::RPC; 1";

push @modules, "XMLRPC::Lite"
    if eval "use XMLRPC::Lite 0.712; 1";

use lib "/home/voice/current/agi-bin";
push @modules, "Diabolo::XMLRPC_Lite"
    if eval "use XMLRPC::Lite 0.712; use Diabolo::XMLRPC_Lite; 1";

plan skip_all => "no other XML-RPC module available to test against"
    unless @modules;


# Data::Dumper configuration
$Data::Dumper::Indent       = 1;
$Data::Dumper::Quotekeys    = 0;
$Data::Dumper::Sortkeys     = 1;
$Data::Dumper::Sparseseen   = 0;
$Data::Dumper::Terse        = 1;


# construct variables with more than one value field filled up,
# but only one valid, to check that the module doesn't mess up
# while reading internal flags
my $iv = "plonk";   $iv = 123;
my $nv = "plonk";   $nv = 2.718;
my $pv = 123456;    $pv = "plonk";

# construct variables which get upgraded from IV and NV
# to PVIV and PVNV by interpolating them in a string
my $s;
my $pviv6 = 123456;     $s = "$pviv6";
my $pviv7 = 1234567;    $s = "$pviv7";
my $pviv8 = 12345678;   $s = "$pviv8";
my $pviv9 = 123456789;  $s = "$pviv9";
my $pvivA = 1234567890; $s = "$pvivA";
my $pvnv  = 3.14159;    $s = "$pvnv";

my @attrs = ( name => "var" );

my @cases = (
    # [ XML-RPC structure, case options ]
    [
        [ "var.set", { @attrs, type => "none",   value => undef } ],
        { can_fail => { "XMLRPC::Lite" => 1, "Diabolo::XMLRPC_Lite" => 1 } },
    ],

    # integer values
    [
        [ "var.set", { @attrs, type => "int",    value => 0 } ],
    ],
    [
        [ "var.set", { @attrs, type => "int",    value => 123 } ],
    ],
    [
        [ "var.set", { @attrs, type => "int",    value => $iv } ],
    ],
    [
        [ "var.set", { @attrs, type => "int",    value => $pviv6 } ],
    ],
    [
        [ "var.set", { @attrs, type => "int",    value => $pviv7 } ],
    ],
    [
        [ "var.set", { @attrs, type => "int",    value => $pviv8 } ],
    ],
    [
        [ "var.set", { @attrs, type => "int",    value => $pviv9 } ],
    ],
    [
        [ "var.set", { @attrs, type => "int",    value => $pvivA } ],
    ],

    # floating point values
    [
        [ "var.set", { @attrs, type => "double", value => 0. } ],
        { can_fail => { "XMLRPC::Lite" => 1 } },
        # XMLRPC::Lite doesn't know how to detect such a case
    ],
    [
        [ "var.set", { @attrs, type => "double", value => 3.14 } ],
    ],
    [
        [ "var.set", { @attrs, type => "double", value => $nv } ],
    ],
    [
        [ "var.set", { @attrs, type => "double", value => $pvnv } ],
    ],

    # string values
    [
        [ "var.set", { @attrs, type => "string", value => "0" } ],
        { can_fail => { "XMLRPC::Lite" => 1, "Diabolo::XMLRPC_Lite" => 1 } },
        # XMLRPC::Fast is more conservative when guessing what is a number
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "123" } ],
        { can_fail => { "XMLRPC::Lite" => 1, "Diabolo::XMLRPC_Lite" => 1 } },
        # XMLRPC::Fast is more conservative when guessing what is a number
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "12_alpha" } ],
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "+33123456" } ],
        { can_fail => { "XMLRPC::Lite" => 1 } },
        # XMLRPC::Fast is more conservative when guessing what is a number,
        # especially in such a case when one (like the author) works with
        # data that are like this (phone numbers) and MUST be kept as strings
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "plonk" } ],
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "eacute(é)" } ],
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "lambda(λ)" } ],
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "snowman(☃)" } ],
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "hiragana_a(あ)" } ],
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "thiuth(𐌸)" } ],
    ],
    [
        [ "var.set", { @attrs, type => "string", value => "pile_of_poo(💩)" } ],
    ],
);


plan tests => @cases * (3 + 8 * @modules);


for my $case (@cases) {
    my $orig = dclone $case->[0];
    my $message = $case->[0];
    my $name = defined $message->[1]{value} ? $message->[1]{value} : "<undef>";
    $name = "$message->[1]{type}:$name";
    $name = encode("UTF-8", $name);

    # serialize to XML-RPC a struct with a Perl string
    my $mine1 = eval { encode_request_with("XMLRPC::Fast", @$message) } || "";
    is $@, "", "[$name] encoding with XMLRPC::Fast (before encode_utf8)";
    $mine1 =~ s/^.+\?>//; # remove PI (RPC::XML, XML::RPC)

    $message->[1]{value} = encode("UTF-8", $message->[1]{value})
        if $message->[1]{type} eq "string";

    # serialize to XML-RPC a struct with an UTF-8 (octets) string
    my $mine2 = eval { encode_request_with("XMLRPC::Fast", @$message) } || "";
    is $@, "", "[$name] encoding with XMLRPC::Fast (after encode_utf8)";
    $mine2 =~ s/^.+\?>//; # remove PI (RPC::XML, XML::RPC)

    is_string $mine2, $mine1, "[$name] comparing both messages";

    for my $module (@modules) {
        # serialize with another XML-RPC module
        my $rfrc = eval { encode_request_with($module, @$message) } || "";
        is $@, "", "[$name] encoding with $module";
        $rfrc =~ s/^.+\?>//; # remove PI (RPC::XML, XML::RPC)
        $rfrc =~ s/\n//g;    # remove newlines (Frontier::RPC2, XML::RPC)

        if ($case->[1]{can_fail}{$module}) {
            TODO: {
                local $TODO = "known difference";
                is_string $mine1, $rfrc, "[$name] comparing with $module encoder";
            }
        }
        else {
            is_string $mine1, $rfrc, "[$name] comparing with $module encoder";
        }

        my $rpc1 = eval { decode_message_with($module, $mine1) } || {};
        is $@, "", "[$name] decoding mine1 with $module";

        my $rpc2 = eval { decode_message_with($module, $mine2) } || {};
        is $@, "", "[$name] decoding mine2 with $module";

        $rpc1->{params}[0]{value} = decode("UTF-8", $rpc1->{params}[0]{value})
            if $rpc1->{params}[0]{type} eq "string";

        $rpc2->{params}[0]{value} = decode("UTF-8", $rpc2->{params}[0]{value})
            if $rpc2->{params}[0]{type} eq "string";

        is_deeply $rpc1, $rpc2, "[$name] comparing both decoded structs"
            or diag "rpc1 = ", Dumper($rpc1), "\nrpc2 = ", Dumper($rpc2);

        is_deeply $rpc1->{params}[0], $orig->[1], "[$name] comparing the "
            . "params of a decoded struct with those of the original one"
            or diag "rpc1 = ", Dumper($rpc1), "\norig = ", Dumper($orig);

        # deserialize the message made by the current module
        my $rpc3 = eval { decode_message_with("XMLRPC::Fast", $rfrc) };
        is $@, "", "[$name] decoding with XMLRPC::Fast";

        $rpc3->{params}[0]{value} = decode("UTF-8", $rpc3->{params}[0]{value})
            if $rpc3->{params}[0]{type} eq "string";

        if ($case->[1]{can_fail}{$module}) {
            TODO: {
                local $TODO = "known difference";
                is_deeply $rpc3, $rpc1, "[$name] checking the decoded "
                    . "structure of the XML-RPC message made by $module"
                    or diag "input XML:\n$rfrc\nrpc3 = ", Dumper($rpc3),
                            "\nrpc1 = ", Dumper($rpc1);
            }
        }
        else {
            is_deeply $rpc3, $rpc1, "[$name] checking the decoded "
                . "structure of the XML-RPC message made by $module"
                or diag "input XML:\n$rfrc\nrpc3 = ", Dumper($rpc3),
                        "\nrpc1 = ", Dumper($rpc1);
        }
    }
}



sub encode_request_with {
    my ($module, @message) = @_;

    if ($module eq "XMLRPC::Fast") {
        return encode_xmlrpc_request(@message)
    }
    elsif ($module eq "XMLRPC::Lite") {
        return XMLRPC::Serializer->envelope(method => @message)
    }
    elsif ($module eq "Diabolo::XMLRPC_Lite") {
        return Diabolo::XMLRPC_Serializer->envelope(method => @message)
    }
    elsif ($module eq "XML::RPC") {
        my $xml = XML::RPC->new("")->create_call_xml(@message);
        $xml =~ s:<i4>:<int>:g;
        $xml =~ s:</i4>:</int>:g;
        return $xml
    }
    elsif ($module eq "RPC::XML") {
        return RPC::XML::request->new(@message)->as_string
    }
    elsif ($module eq "Frontier::RPC2") {
        return Frontier::RPC2->new->encode_call(@message)
    }
}


sub decode_message_with {
    my ($module, $xml) = @_;

    if ($module eq "XMLRPC::Fast") {
        return decode_xmlrpc($xml)
    }
    elsif ($module eq "XMLRPC::Lite") {
        my $rpc = XMLRPC::Deserializer->deserialize($xml)->root;
        $rpc->{type} = $rpc->{methodName} ? "request"
                     : $rpc->{fault} ? "fault"
                     : "response";
        return $rpc
    }
    elsif ($module eq "Diabolo::XMLRPC_Lite") {
        my $rpc = Diabolo::XMLRPC_Deserializer->deserialize($xml)->root;
        $rpc->{type} = $rpc->{methodName} ? "request"
                     : $rpc->{fault} ? "fault"
                     : "response";
        return $rpc
    }
    elsif ($module eq "XML::RPC") {
        # extracted & simplified from XML::RPC::receive()
        my $client = XML::RPC->new("");
        my ($method, @params)
            = $client->unparse_call($client->{tpp}->parse($xml));
        return { methodName => $method, params => \@params }
    }
    elsif ($module eq "RPC::XML") {
        my $msg = RPC::XML::ParserFactory->new->parse($xml);
        (my $type = ref $msg) =~ s/^.*:://g;
        $type = "fault" if $type eq "response" and $msg->is_fault;
        return {
            type        => $type,
          ( methodName  => $msg->name ) x!! ($type eq "request"),
            params      => $type eq "request" ? $msg->args : $msg->value,
        }
    }
    elsif ($module eq "Frontier::RPC2") {
        my $call = Frontier::RPC2->new->decode($xml);
        return {
            type        => $call->{type} eq "call" ? "request" : $call->{type},
          ( methodName  => $call->{method_name} ) x!! ( $call->{type} eq "call" ),
            params      => $call->{value},
        }
    }
}


