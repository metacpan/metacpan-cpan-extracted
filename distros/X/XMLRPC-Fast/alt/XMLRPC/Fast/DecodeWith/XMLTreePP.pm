package XMLRPC::Fast::DecodeWith::XMLTreePP;
use strict;
use warnings;
use MIME::Base64;
use XML::TreePP;


#
# decode_xmlrpc()
# -------------
sub decode_xmlrpc {
    my ($xml) = shift;

    # parse the XML document
    my $tpp  = XML::TreePP->new(
        force_array => [qw< data member param >],
    );

    my $tree = $tpp->parse($xml);
    my %struct;

    # detect the message type, decode the parameters
    if ($tree->{methodCall}) {
        %struct = (
            type        => "request",
            methodName  => $tree->{methodCall}{methodName},
            params      => [
                map decode_value($_->{value}),
                    @{ $tree->{methodCall}{params}{param} }
            ],
        );
    }
    elsif ($tree->{methodResponse}) {
        if ($tree->{methodResponse}{fault}) {
            # this is a fault message
            %struct = (
                type    => "fault",
                fault   => decode_value($tree->{methodResponse}{fault}),
            );
        }
        else {
            # this is a normal response message
            %struct = (
                type    => "response",
                params  => [
                    map decode_value($_->{value}),
                        @{ $tree->{methodResponse}{params}{param} }
                ],
            );
        }
    }
    else {
        die "unknown type of message";
    }

    return \%struct
}


#
# decode_value()
# ------------
sub decode_value {
    my ($node) = shift;

    return unless defined $node;
    my @list = ref $node eq "ARRAY" ? @$node : $node;
    my @result;

    for my $vnode (@list) {
        if ($vnode->{struct}) {
            push @result, {
                map { $_->{name} => decode_value($_->{value}) }
                    @{ $vnode->{struct}{member} }
            };
        }
        elsif ($vnode->{array}) {
            push @result, [
                map decode_value($_->{value}), @{ $vnode->{array}{data} }
            ];
        }
        else { # scalar
            my ($type, $val) = each %$vnode;
            push @result, $type eq "int"    ? int $val
                        : $type eq "i4"     ? int $val
                        : $type eq "boolean"? int $val
                        : $type eq "double" ? $val / 1.0
                        : $type eq "base64" ? decode_base64($val)
                        : $val; # string, datetime
        }
    }

    return @result
}


__PACKAGE__

__END__

=head1 NAME

XMLRPC::Fast::DecodeWith::XMLTreePP - XML-RPC decoder based on XML::TreePP

=head1 DESCRIPTION

This is an alternate decoding function for L<XMLRPC::Fast>, using L<XML::TreePP>
as the XML engine. Based on L<XML::RPC>, heavily simplified. Unsurprisingly,
performs rather poorly when compared to other modules.

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>saper@cpan.orgE<gt>


