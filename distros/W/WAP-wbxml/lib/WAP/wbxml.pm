
package WAP::wbxml;

use strict;
use warnings;

our $VERSION = '1.14';

=head1 NAME

WAP::wbxml - Binarization of XML file

=head1 SYNOPSIS

  use XML::DOM;
  use WAP::wbxml;

  $parser = new XML::DOM::Parser;
  $doc_xml = $parser->parsefile($infile);

  $rules = WAP::wbxml::WbRules::Load();
  $wbxml = new WAP::wbxml($rules, $publicid);
  $output = $wbxml->compile($doc_xml, $encoding);

=head1 DESCRIPTION

This module implements binarisation of XML file according the specification :

WAP - Wireless Application Protocol /
Binary XML Content Format Specification /
Version 1.3 WBXML (15th May 2000 Approved)

The XML input file must refere to a DTD with a public identifier.

The file WAP/wap.wbrules.xml configures this tool for all known DTD.

This module needs I18N::Charset and XML::DOM modules.

WAP Specifications, including Binary XML Content Format (WBXML)
 are available on E<lt>http://www.wapforum.org/E<gt>.

=over 4

=cut

use integer;
use bytes;

use MIME::Base64;
use WAP::wbxml::WbRules;
use XML::DOM;

# Global tokens
use constant SWITCH_PAGE    => 0x00;
use constant _END           => 0x01;
use constant ENTITY         => 0x02;
use constant STR_I          => 0x03;
use constant LITERAL        => 0x04;
use constant EXT_I_0        => 0x40;
use constant EXT_I_1        => 0x41;
use constant EXT_I_2        => 0x42;
use constant PI             => 0x43;
use constant LITERAL_C      => 0x44;
use constant EXT_T_0        => 0x80;
use constant EXT_T_1        => 0x81;
use constant EXT_T_2        => 0x82;
use constant STR_T          => 0x83;
use constant LITERAL_A      => 0x84;
use constant EXT_0          => 0xC0;
use constant EXT_1          => 0xC1;
use constant EXT_2          => 0xC2;
use constant OPAQUE         => 0xC3;
use constant LITERAL_AC     => 0xC4;
# Global token masks
use constant NULL           => 0x00;
use constant HAS_CHILD      => 0x40;
use constant HAS_ATTR       => 0x80;

=item new

 $wbxml = new WAP::wbxml($rules, $publicid);

Create a instance of WBinarizer for a specified kind of DTD.

If PublicId is undefined, the first found rules are used.

If the DTD is not known in the rules, default rules are used.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($rules, $publicid) = @_;
    $self->{publicid} = $publicid;
    $self->{rules} = $rules;
    if ($publicid) {
        $self->{rulesApp} = $rules->{App}->{$publicid};
        unless ($self->{rulesApp}) {
            $self->{rulesApp} = $rules->{DefaultApp};
            warn "Using default rules.\n";
        }
    }
    else {
        my ($val) = values %{$rules->{App}};
        $self->{rulesApp} = $val;
    }
    $self->{skipDefault} = $self->{rulesApp}->{skipDefault};
    $self->{variableSubs} = $self->{rulesApp}->{variableSubs};
    $self->{tagCodepage} = 0;
    $self->{attrCodepage} = 0;
    return $self;
}

sub compileDatetime {
    # WAP / WML
    my $self = shift;
    my ($content) = @_;
    my $str;
    if ($content =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/) {
        my $year  = chr (16 * ($1 / 1000) + (($1 / 100) % 10))
                  . chr (16 * (($1 / 10) % 10) + ($1 % 10));
        my $month = chr (16 * ($2 / 10) + ($2 % 10));
        my $day   = chr (16 * ($3 / 10) + ($3 % 10));
        my $hour  = chr (16 * ($4 / 10) + ($4 % 10));
        my $min   = chr (16 * ($5 / 10) + ($5 % 10));
        my $sec   = chr (16 * ($6 / 10) + ($6 % 10));
        $str  = $year . $month . $day;
        $str .= $hour if (ord $hour or ord $min or ord $sec);
        $str .= $min  if (ord $min or ord $sec);
        $str .= $sec  if (ord $sec);
    }
    else {
        warn "Validate 'Datetime' error : $content.\n";
        $str = "\x19\x70\x01\x01";
    }
    $self->putb('body', OPAQUE);
    $self->putmb('body', length $str);
    $self->putstr('body', $str);
}

sub compileBinaryWV {
    # WV
    my $self = shift;
    my ($value) = @_;
    $value =~ s/\s+//g;
    my $data = decode_base64($value);
    if (length $data) {
        $self->putb('body', OPAQUE);
        $self->putmb('body', length $data);
        $self->putstr('body', $data);
    }
}

sub compileIntegerWV {
    # WV
    my $self = shift;
    my ($value) = @_;
    $value =~ s/\s+/ /g;
    unless ($value =~ /^\s*$/) {
        if ($value < 0 and $value > 4294967295) {
            warn "'Integer' error : $value.\n";
            $self->compilePreserveStringI($value);
        }
        else {
            $self->putb('body', OPAQUE);
            if    ($value < 256) {
                $self->putmb('body', 1);
                $self->putb('body', $value);
            }
            elsif ($value < 65536) {
                $self->putmb('body', 2);
                $self->putstr('body', pack("n", $value));
            }
            else {
                $self->putmb('body', 4);
                $self->putstr('body', pack("N", $value));
            }
        }
    }
}

sub compileDatetimeWV {
    # WV
    my $self = shift;
    my ($content) = @_;
    my $str;
    if ($content =~ /^\s*(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(Z)?\s*$/) {
        my $year  = $1;
        my $month = $2;
        my $day   = $3;
        my $hour  = $4;
        my $min   = $5;
        my $sec   = $6;
        my $tz    = $7 || "\0";
        $self->putb('body', OPAQUE);
        $self->putmb('body', 6);
        $self->putb('body', $year >> 6);
        $self->putb('body', (($year & 0x03F) << 2) | ($month >> 2));
        $self->putb('body', (($month & 0x3) << 6) | ($day << 1) | ($hour >> 4));
        $self->putb('body', (($hour & 0xF) << 4) | ($min >> 2));
        $self->putb('body', (($min & 0x3) << 6) | $sec);
        $self->putb('body', ord $tz);
    }
    else {
        warn "'Datetime' error : $content.\n";
        $self->compilePreserveStringI($content);
    }
}

sub compilePreserveStringT {
    my $self = shift;
    my ($str) = @_;
    if (exists $self->{h_str}->{$str}) {
        $self->putmb('body', $self->{h_str}->{$str});
    }
    else {
        my $pos = length $self->{strtbl};
        $self->{h_str}->{$str} = $pos;
#       print $pos," ",$str,"\n";
        $self->putmb('body', $pos);
        $self->putstr('strtbl', $str);
        $self->putb('strtbl', NULL);
    }
}

sub compilePreserveStringI {
    my $self = shift;
    my ($str) = @_;
    my $idx = $self->{rulesApp}->getExtValue($str, 'Ext0Values');
    if (defined $idx) {
        $self->putb('body', EXT_T_0);
        $self->putmb('body', $idx);
        return;
    }
    $idx = $self->{rulesApp}->getExtValue($str, 'Ext1Values');
    if (defined $idx) {
        $self->putb('body', EXT_T_1);
        $self->putmb('body', $idx);
        return;
    }
    $idx = $self->{rulesApp}->getExtValue($str, 'Ext2Values');
    if (defined $idx) {
        $self->putb('body', EXT_T_2);
        $self->putmb('body', $idx);
        return;
    }
    $self->putb('body', STR_I);
    $self->putstr('body', $str);
    $self->putb('body', NULL);
}

sub compileStringI {
    my $self = shift;
    my ($str) = @_;
    $str =~ s/\s+/ /g;
    $self->compilePreserveStringI($str) unless ($str =~ /^\s*$/);
}

sub compileStringIwithVariables {
    # WAP / WML
    my $self = shift;
    my ($str) = @_;
    my $text = '';
    while ($str) {
        for ($str) {
            s/^([^\$]+)//
                    and $text .= $1,
                        last;

            s/^\$\$//
                    and $text .= '$',
                        last;

            s/^\$([A-Z_a-z][0-9A-Z_a-z]*)//
                    and $self->compileStringI($text),
                        $text = q{},
                        $self->putb('body', EXT_T_2),
                        $self->compilePreserveStringT($1),
                        last;

            s/^\$\(\s*([A-Z_a-z][0-9A-Z_a-z]*)\s*\)//
                    and $self->compileStringI($text),
                        $text = q{},
                        $self->putb('body', EXT_T_2),
                        $self->compilePreserveStringT($1),
                        last;

            s/^\$\(\s*([A-Z_a-z][0-9A-Z_a-z]*)\s*:\s*escape\s*\)//
                    and $self->compileStringI($text),
                        $text = q{},
                        $self->putb('body', EXT_T_0),
                        $self->compilePreserveStringT($1),
                        last;

            s/^\$\(\s*([A-Z_a-z][0-9A-Z_a-z]*)\s*:\s*unesc\s*\)//
                    and $self->compileStringI($text),
                        $text = q{},
                        $self->putb('body', EXT_T_1),
                        $self->compilePreserveStringT($1),
                        last;

            s/^\$\(\s*([A-Z_a-z][0-9A-Z_a-z]*)\s*:\s*noesc\s*\)//
                    and $self->compileStringI($text),
                        $text = q{},
                        $self->putb('body', EXT_T_2),
                        $self->compilePreserveStringT($1),
                        last;

            s/^\$\(\s*([A-Z_a-z][0-9A-Z_a-z]*)\s*:\s*([Ee]([Ss][Cc][Aa][Pp][Ee])?)\s*\)//
                    and $self->compileStringI($text),
                        $text = q{},
                        $self->putb('body', EXT_T_0),
                        $self->compilePreserveStringT($1),
                        warn "deprecated-var : $1:$2\n",
                        last;

            s/^\$\(\s*([A-Z_a-z][0-9A-Z_a-z]*)\s*:\s*([Uu][Nn]([Ee][Ss][Cc])?)\s*\)//
                    and $self->compileStringI($text),
                        $text = q{},
                        $self->putb('body', EXT_T_1),
                        $self->compilePreserveStringT($1),
                        warn "deprecated-var : $1:$2\n",
                        last;

            s/^\$\(\s*([A-Z_a-z][0-9A-Z_a-z]*)\s*:\s*([Nn][Oo]([Ee][Ss][Cc])?)\s*\)//
                    and $self->compileStringI($text),
                        $text = q{},
                        $self->putb('body', EXT_T_2),
                        $self->compilePreserveStringT($1),
                        warn "deprecated-var : $1:$2\n",
                        last;

            warn "Pb with: $str \n";
            return;
        }
    }
    $self->compileStringI($text);
}

sub compileEntity {
    my $self = shift;
    my ($entity) = @_;
    if (exists $self->{rulesApp}->{CharacterEntity}{$entity}) {
        my $code = $self->{rulesApp}->{CharacterEntity}{$entity};
        $self->putb('body', ENTITY);
        $self->putmb('body', $code);
    }
    else {
        warn "entity reference : $entity";
    }
}

sub compileAttributeExtToken {
    my $self = shift;
    my ($ext_token) = @_;
    my $codepage = $ext_token / 256;
    my $token = $ext_token % 256;
    if ($codepage != $self->{attrCodepage}) {
        $self->putb('body', SWITCH_PAGE);
        $self->putb('body', $codepage);
        $self->{attrCodepage} = $codepage;
    }
    $self->putb('body', $token);
}

sub compileTagExtToken {
    my $self = shift;
    my ($ext_token) = @_;
    my $codepage = $ext_token / 256;
    my $token = $ext_token % 256;
    if ($codepage != $self->{tagCodepage}) {
        $self->putb('body', SWITCH_PAGE);
        $self->putb('body', $codepage);
        $self->{tagCodepage} = $codepage;
    }
    $self->putb('body', $token);
}

sub compileAttributeValues {
    my $self = shift;
    my ($value) = @_;
    my $attr;
    my $start;
    my $end;
    while (1) {
        ($attr, $start, $end) = $self->{rulesApp}->getAttrValue($value, $self->{attrCodepage});
        last unless ($attr);
        $self->compilePreserveStringI($start) if (defined $start);
        $self->compileAttributeExtToken($attr->{ext_token});
        $value = $end;
    }
    $self->compilePreserveStringI($start) if (defined $start);
}

sub compileProcessingInstruction {
    my $self = shift;
    my ($target, $data) = @_;
    $self->putb('body', PI);
    my ($attr_start, $dummy) = $self->{rulesApp}->getAttrStart($target, q{}, $self->{attrCodepage});
    if ($attr_start) {
        # well-known attribute name
        $self->compileAttributeExtToken($attr_start->{ext_token});
    }
    else {
        # unknown attribute name
        $self->putb('body', LITERAL);
        $self->compilePreserveStringT($target);
    }
    if (defined $data) {
        $self->compileAttributeValues($data);
    }
    $self->putb('body', _END);
}

sub prepareAttribute {
    my $self = shift;
    my ($tagname, $attr) = @_;
    my $attr_name = $attr->getName();
    my $attr_value = $attr->getValue();
    my ($attr_start, $remain) = $self->{rulesApp}->getAttrStart($attr_name, $attr_value, $self->{attrCodepage});
    if ($attr_start) {
        # well-known attribute name
        my $default_list = $attr_start->{default} || q{};
        my $fixed_list = $attr_start->{fixed} || q{};
        if (! $remain) {
            return 0 if (index($fixed_list, $tagname) >= 0);
            return 0 if ($self->{skipDefault} and index($default_list, $tagname) >= 0);
        }
    }
    return 1;
}

sub compileAttribute {
    my $self = shift;
    my ($tagname, $attr) = @_;
    my $attr_name = $attr->getName();
    my $attr_value = $attr->getValue();
    my ($attr_start, $remain) = $self->{rulesApp}->getAttrStart($attr_name, $attr_value, $self->{attrCodepage});
    if ($attr_start) {
        # well-known attribute name
        my $default_list = $attr_start->{default} || q{};
        my $fixed_list = $attr_start->{fixed} || q{};
        my $validate = $attr_start->{validate} || q{};
        my $encoding = $attr_start->{encoding} || q{};
        unless ($remain) {
            return if (index($fixed_list, $tagname) >= 0);
            return if ($self->{skipDefault} and index($default_list, $tagname) >= 0);
        }
        $self->compileAttributeExtToken($attr_start->{ext_token});

        if ($encoding eq 'iso-8601') {
            $self->compileDatetime($attr_value);
        }
        else {
            if ($remain ne q{}) {
                if ($validate eq 'length') {
                    warn "Validate 'length' error : $remain.\n"
                            unless ($remain =~ /^[0-9]+%?$/);
                    $self->compilePreserveStringI($remain);
                }
                else {
                    if ($self->{variableSubs} and $validate eq 'vdata') {
                        if (index($remain, "\$") >= 0) {
                            $self->compileStringIwithVariables($remain);
                        }
                        else {
                            $self->compileAttributeValues($remain);
                        }
                    }
                    else {
                        $self->compileAttributeValues($remain);
                    }
                }
            }
        }
    }
    else {
        # unknown attribute name
        $self->putb('body', LITERAL);
        $self->compilePreserveStringT($attr_name);
        $self->putb('body', STR_T);
        $self->compilePreserveStringT($attr_value);
    }
}

sub compileElement {
    my $self = shift;
    my ($elt, $xml_lang, $xml_space) = @_;
    my $cpl_token = NULL;
    my $tagname = $elt->getNodeName();
    my $attrs = $elt->getAttributes();
    if ($attrs->getLength()) {
        my $attr;
        $attr = $elt->getAttribute('xml:lang');
        $xml_lang = $attr if ($attr);
        $attr = $elt->getAttribute('xml:space');
        $xml_space = $attr if ($attr);
        my $nb = 0;
        for (my $i = 0; $i < $attrs->getLength(); $i ++) {
            my $attr = $attrs->item($i);
            if ($attr->getNodeType() == ATTRIBUTE_NODE) {
                $nb += $self->prepareAttribute($tagname, $attr);
            }
        }
        $cpl_token |= HAS_ATTR if ($nb);
    }
    if ($elt->hasChildNodes()) {
        $cpl_token |= HAS_CHILD;
    }
    my $tag_token = $self->{rulesApp}->getTag($tagname, $self->{tagCodepage});
    if ($tag_token) {
        # well-known tag name
        $self->compileTagExtToken($cpl_token | $tag_token->{ext_token});
    }
    else {
        # unknown tag name
        $self->putb('body', $cpl_token | LITERAL);
        $self->compilePreserveStringT($tagname);
    }
    if ($cpl_token & HAS_ATTR) {
        for (my $i = 0; $i < $attrs->getLength(); $i ++) {
            my $attr = $attrs->item($i);
            if ($attr->getNodeType() == ATTRIBUTE_NODE) {
                $self->compileAttribute($tagname, $attr);
            }
        }
        $self->putb('body', _END);
    }
    if ($cpl_token & HAS_CHILD) {
        $self->compileContent($elt->getFirstChild(), $tag_token, $xml_lang, $xml_space);
        $self->putb('body', _END);
    }
}

sub compileContent {
    my $self = shift;
    my ($tag, $parent, $xml_lang, $xml_space) = @_;
    for (my $node = $tag;
            $node;
            $node = $node->getNextSibling() ) {
        my $type = $node->getNodeType();
        if    ($type == ELEMENT_NODE) {
            $self->compileElement($node, $xml_lang, $xml_space);
        }
        elsif ($type == TEXT_NODE) {
            my $value = $node->getNodeValue();
            if ($self->{variableSubs}) {
                $self->compileStringIwithVariables($value);
            }
            else {
                if ($xml_space eq 'preserve') {
                    $self->compilePreserveStringI($value) unless ($value =~ /^\s*$/);
                }
                else {
                    my $encoding = ($parent and exists $parent->{encoding}) ? $parent->{encoding} : "";
                    if    ($encoding eq 'base64') {
                        $self->compileBinaryWV($value);
                    }
                    elsif ($encoding eq 'datetime') {
                        $self->compileDatetimeWV($value);
                    }
                    elsif ($encoding eq 'integer') {
                        $self->compileIntegerWV($value);
                    }
                    else {
                        $self->compileStringI($value);
                    }
                }
            }
        }
        elsif ($type == CDATA_SECTION_NODE) {
            my $value = $node->getNodeValue();
            $self->compilePreserveStringI($value);
        }
        elsif ($type == COMMENT_NODE) {
            # do nothing
        }
        elsif ($type == ENTITY_REFERENCE_NODE) {
            $self->compileEntity($node->getNodeName());
        }
        elsif ($type == PROCESSING_INSTRUCTION_NODE) {
            my $target = $node->getTarget();
            my $data = $node->getData();
            $self->compileProcessingInstruction($target, $data);
        }
        else {
            die "unexcepted ElementType in compileContent : $type\n";
        }
    }
}

sub compileBody {
    my $self = shift;
    my ($doc) = @_;
    my $xml_lang = q{};
    my $xml_space = $self->{rulesApp}->{xmlSpace};
    for (my $node = $doc->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        my $type = $node->getNodeType();
        if      ($type == ELEMENT_NODE) {
            $self->compileElement($node, $xml_lang, $xml_space);
        }
        elsif ($type == PROCESSING_INSTRUCTION_NODE) {
            my $target = $node->getTarget();
            my $data = $node->getData();
            $self->compileProcessingInstruction($target, $data);
        }
    }
}

sub compileCharSet {
    my $self = shift;
    my ($encoding) = @_;
    if (defined $encoding) {
        eval "use I18N::Charset";
        die $@ if ($@);
        my $mib = charset_name_to_mib($encoding);
        if (defined $mib) {
            $self->putmb('header', $mib);
        }
        else {
            warn "unknown encoding.\n";
            $self->putmb('header', 0);  # unknown encoding
        }
    }
    else {
        $self->putmb('header', 106);        # UTF-8 : default XML encoding
    }
}

sub compilePublicId {
    my $self = shift;
    if (! $self->{publicid}) {
        $self->putmb('header', 1);
    }
    elsif (exists $self->{rules}->{PublicIdentifiers}->{$self->{publicid}}) {
        my $publicid = $self->{rules}->{PublicIdentifiers}->{$self->{publicid}};
        $self->putmb('header', $publicid);
    }
    else {
        $self->putb('header', NULL);
        my $pos = length $self->{strtbl};   # 0
        $self->{h_str}->{$self->{publicid}} = $pos;
        $self->putmb('header', $pos);
        $self->putstr('strtbl', $self->{publicid});
        $self->putb('strtbl', NULL);
    }
}

sub compileVersion {
    my $self = shift;
    $self->putb('header', $self->{rules}->{version});
}

=item compile

 $output = $wbxml->compile($doc_xml, $encoding);

Compiles a XML document.

=cut

sub compile {
    my $self = shift;
    my ($doc, $encoding) = @_;
    $self->{header} = q{};
    $self->{body} = q{};
    $self->{strtbl} = q{};
    $self->{h_str} = {};
    $self->{tagCodepage} = 0;
    $self->{attrCodepage} = 0;
    $self->compileVersion();
    $self->compilePublicId();
    $self->compileCharSet($encoding);
    $self->compileBody($doc);
    $self->putmb('header', length $self->{strtbl});
    my $out = $self->{header} . $self->{strtbl} . $self->{body};
    return $out;
}

=item outfile

 $filename = $wbxml->outfile($infile);

Builds output filename with the good extension.

=cut

sub outfile {
    my $self = shift;
    my ($infile) = @_;
    my $filename = $infile;
    if ($filename =~ /\.[^\.]+$/) {
        $filename =~ s/\.[^\.]+$/\./;
    }
    else {
        $filename .= '.';
    }
    $filename .= $self->{rulesApp}->{tokenisedExt};
    return $filename;
}

sub putb {
    my $self = shift;
    my ($str, $val) = @_;
    $self->{$str} = $self->{$str} . chr $val;
}

sub putmb {
    my $self = shift;
    my ($str, $val) = @_;
    my $tmp = chr ($val & 0x7f);
    for ($val >>= 7; $val != 0; $val >>= 7) {
        $tmp = chr (0x80 | ($val & 0x7f)) . $tmp;
    }
    $self->{$str} = $self->{$str} . $tmp;
}

sub putstr {
    my $self = shift;
    my ($str, $val) = @_;
    $self->{$str} = $self->{$str} . $val;
}

=back

=head1 SEE ALSO

wbxmlc, WAP::SAXDriver::wbxml

=head1 COPYRIGHT

(c) 2001-2016 Francois PERRAD, France.

This program (WAP::wbxml.pm and the internal DTD of wbrules.xml) is distributed
under the terms of the Artistic Licence.

The WAP Specification are copyrighted by the Wireless Application Protocol Forum Ltd.
See E<lt>http://www.wapforum.org/what/copyright.htmE<gt>.

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=cut

1;

