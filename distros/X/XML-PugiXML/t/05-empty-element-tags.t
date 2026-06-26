use strict;
use warnings;
use Test::More;
use XML::PugiXML;

# FORMAT_NO_EMPTY_ELEMENT_TAGS (pugixml format_no_empty_element_tags) forces the
# long <e></e> form instead of the self-closing <e/> form. It is the opt-out for
# the pugixml 1.16 behaviour change where an element with a single empty PCDATA
# child is now printed self-closing.

# constant is exported and is a non-zero flag bit
my $flag = XML::PugiXML::FORMAT_NO_EMPTY_ELEMENT_TAGS();
ok defined $flag, 'FORMAT_NO_EMPTY_ELEMENT_TAGS is defined';
ok $flag, 'FORMAT_NO_EMPTY_ELEMENT_TAGS is a non-zero flag';

# an empty element is self-closing by default, long-form with the flag
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>') or die $@;

    my $default = $doc->to_string;
    like   $default, qr{<root\s*/>}, 'empty element is self-closing by default';
    unlike $default, qr{</root>},    'no closing tag by default';

    my $long = $doc->to_string("\t", XML::PugiXML::FORMAT_DEFAULT | $flag);
    like $long, qr{<root>\s*</root>}, 'FORMAT_NO_EMPTY_ELEMENT_TAGS forces <root></root>';
}

# pugixml 1.16 behaviour change: an element with a single empty PCDATA child
# (set_text('')) now prints self-closing by default; older pugixml prints the
# long form. Either way the flag forces (or keeps) the long form, so the binding
# supports system pugixml down to 1.8.
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>') or die $@;
    $doc->root->set_text('');   # single empty PCDATA child

    my $default = $doc->to_string;
    if (XML::PugiXML::PUGIXML_VERSION() >= 1160) {
        like $default, qr{<root\s*/>},
            'set_text("") element is self-closing by default (pugixml >= 1.16)';
    } else {
        like $default, qr{<root>\s*</root>},
            'set_text("") element is long-form by default (pugixml < 1.16)';
    }

    my $long = $doc->to_string("\t", XML::PugiXML::FORMAT_DEFAULT | $flag);
    like $long, qr{<root>\s*</root>},
        'FORMAT_NO_EMPTY_ELEMENT_TAGS keeps <root></root> for an empty PCDATA child';
}

done_testing;
