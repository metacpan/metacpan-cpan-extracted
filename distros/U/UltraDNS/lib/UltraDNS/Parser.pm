package UltraDNS::Parser;

use strict;
use warnings;
use 5.00800;

our $VERSION = '0.04';

use base qw/Exporter/;
use RPC::XML;
use XML::LibXML;
use MIME::Base64;
use Carp;

use UltraDNS::Type;


my $udns_types = UltraDNS::Type->_type_to_class_map();

our $TYPE_MAP = {
    int                => 'RPC::XML::int',
    i4                 => 'RPC::XML::int',
    boolean            => 'RPC::XML::boolean',
    string             => 'RPC::XML::string',
    double             => 'RPC::XML::double',
    'dateTime.iso8601' => 'RPC::XML::datetime_iso8601',
    array              => 'RPC::XML::array',
    struct             => 'RPC::XML::struct',
    %$udns_types,
};

my $value_xpath = join "|", map "./$_",
	keys %$TYPE_MAP,
	qw(base64 struct array);

sub _parse_rpc_xml {
    my $self = shift;
    my $xml = shift;

    my $x = XML::LibXML->new;
    my $doc = $x->parse_string($xml)->documentElement;
    my @nodes;

    # the common case first
    if (@nodes = $doc->findnodes('/methodResponse/params/param/value')) {
        return RPC::XML::response->new(_extract_values(@nodes));
    }
    # sometimes <param> doesn't contain a <value>,
    elsif (@nodes = $doc->findnodes('/methodResponse/params/param')) {
        # so long as we find a <param> we're happy to return an undef
        # XXX RPC::XML doesn't really understand undefs, but this'll do:
        return RPC::XML::response->new(RPC::XML::simple_type->new(undef));
        # else fall thru and croak
    }
    elsif ($doc->findnodes('/methodResponse/fault')) {
        return RPC::XML::response->new(
            RPC::XML::fault->new(
                $doc->findvalue('/methodResponse/fault/value/struct/member/value/int'),
                $doc->findvalue('/methodResponse/fault/value/struct/member/value/string'),
            ),
        );
    }
    croak "Invalid methodResponse: $xml";
}


sub _extract_values {
    my @value_nodes = @_;

    my @values;
    for my $node (grep defined, @value_nodes) {
        my($v_node) = $node->findnodes($value_xpath);
        my $value;
        if (defined $v_node) {
            $value = _extract($v_node);
        } else {
            # <value>foo</value> is treated as <string> by default
            $value = RPC::XML::string->new($node->textContent);
        }

        push @values, $value;
    }

    return @values;
}

sub _extract {
    my $node = shift;

    return unless defined $node;

    my $nodename = $node->nodeName;
    my $val = $node->textContent;
    if ($nodename eq 'base64')  {
        return RPC::XML::base64->new(decode_base64($val));
    } else {
        my $class = $TYPE_MAP->{ $nodename }
            or return;
        if ($class->isa('RPC::XML::struct')) {
            my @members = $node->findnodes('./member'); # XXX
            my $result = {};
            for my $member (@members) {
                my($name)  = $member->findnodes('./name');
                my($value) = _extract_values($member->findnodes('./value') );
                ($result->{$name->textContent}, ) = $value;
            }
            return $class->new($result);
        }
        elsif ($class->isa('RPC::XML::array')) {
            return $class->new(_extract_values($node->findnodes($node->nodePath . '/data/value')));
        }
        else {
            return $class->new($val);
        }
    }
}

1;
__END__

=head1 NAME

UltraDNS::Parser - Fast parser for the non-standard UltraDNS variant of XML-RPC

=head1 DESCRIPTION

This is an internal module of the UltraDNS distribution.

=head1 AUTHOR

Tim Bunce. Based almost entirely on RPC::XML::Parser::LibXML by Tokuhiro
Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>, Tatsuhiko Miyagawa
E<lt>miyagawa@cpan.orgE<gt>.

=head1 SEE ALSO

L<RPC::XML::Parser::LibXML>, L<RPC::XML::Parser>, L<RPC::XML::Parser::XS>, L<XML::LibXML>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
