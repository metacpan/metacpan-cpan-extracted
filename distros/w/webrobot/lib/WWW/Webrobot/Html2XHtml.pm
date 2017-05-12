package WWW::Webrobot::Html2XHtml;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

=head1 NAME

WWW::Webrobot::Html2XHtml - convert HTML to XML

=head1 SYNOPSIS

 use WWW::Webrobot::Html2XHtml;
 my $converter = WWW::Webrobot::Html2XHtml -> new();
 $converter->to_xhtml($dirty_html, $encoding);


=head1 DESCRIPTION

=head1 METHODS

=over

=cut


use HTML::TreeBuilder;
use HTML::Entities;
use WWW::Webrobot::MyEncode qw/has_Encode octet_to_internal_utf8/;


my $XML_HEADER = qq(<?xml version="1.0" encoding="UTF-8"?>\n);


my %e2c =
    map {$_ => pack("U", ord $HTML::Entities::entity2char{$_})}
    grep {my $value = ord($HTML::Entities::entity2char{$_}); 128 <= $value && $value < 256}
    keys %HTML::Entities::entity2char;


=item new

Constructor

=cut

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    return $self;
}

sub html_decode_entities_utf8 {
    my ($value) = @_;
    foreach ($value) {
        s/(&\#(\d+);?)/ 128<=$2 && $2<256 ? pack("U", $2) : $1 /eg;
        s/(&\#[xX]([0-9a-fA-F]+);?)/ my $c = hex($2); 128<=$c && $c<256 ? pack("U", $c) : $1 /eg;
        s/(&(\w+);?)/ $e2c{$2} || $1 /eg;
    }
    return $value;
}

=item to_xhtml($dirty_html, $encoding)

Convert C<$dirty_html> to XML.
C<$dirty_html> is a sequence of octets and is assumend to be
coded in C<$encoding>.

=cut

sub to_xhtml {
    my ($self, $dirty_html, $encoding) = @_;
    #return "NO VALID ENCODING='$encoding'\n" if ! $encoding;

    my $parser = new HTML::TreeBuilder();
    $parser->no_space_compacting(1);
    $parser->ignore_ignorable_whitespace(0);

    # Encode $dirty_html to Perls internal encoding UTF-8.
    $dirty_html = octet_to_internal_utf8($encoding, $dirty_html);

    # Decode HTML entities, because HTML::TreeBuilder doesn't handle it right.
    # Can't use HTML::Entities::decode_entities because it uses 'chr($x)'
    # instead of 'pack("U",$x)'
    $dirty_html = html_decode_entities_utf8($dirty_html);

    # Parse $dirty_html and encode all remaining bytes as html entities.
    # That works because all non-ASCII UTF-8 character bytes are 1xxxxxxx
    my $tree = $parser->parse($dirty_html);
    my $xml = $XML_HEADER . $tree->as_XML();
    # $xml has all byte encoded as &#xx;
    $tree = $tree -> delete;

    if (! has_Encode()) {
        # Decode UTF-8 characters and control characters, $xml is ASCII
        $xml =~ s/(&\#(\d+);)/ 32 <= $2 && $2 < 128 ? $1 : pack("C", $2) /eg;
    }
    elsif (Encode::is_utf8($xml)) { # SunOS 5.7 / perl 5.8.5
        # Decode UTF-8 characters and control characters, $xml is UTF-8
        $xml =~ s/(&\#(\d+);)/ 32 <= $2 && $2 < 128 ? $1 : pack("U", $2) /eg;
    }
    else { # Linux perl 5.8.0/5.8.5, Win32 perl 5.8.0
        # Decode UTF-8 characters and control characters, $xml is ASCII
        $xml =~ s/(&\#(\d+);)/ 32 <= $2 && $2 < 128 ? $1 : pack("C", $2) /eg;
        # Now we have an UTF-8 string and must Perl believe so too.
        Encode::_utf8_on($xml);
    }

    return $xml;
}

=back

=cut

1;
