#
# WAP::SAXDriver::wbxml
#

package WAP::SAXDriver::wbxml;

use strict;
use warnings;

use base qw(XML::SAX::Base);
use IO::File;
use IO::String;

our $VERSION = '2.07';

sub _parse_characterstream {
    my $p       = shift;
    my $xml     = shift;
    my $opt     = $p->{ParseOptions};

    $p->_init_parser($opt);
    die __PACKAGE__,": Not an IO::Handle\n"
            unless ($xml->isa('IO::Handle'));
    $p->{io_handle} = $xml;
    my $result = $p->_parse($opt);
    $p->_cleanup;
    return $result;
}

sub _parse_bytestream {
    my $p       = shift;
    my $xml     = shift;
    my $opt     = $p->{ParseOptions};

    $p->_init_parser($opt);
    die __PACKAGE__,": Not an IO::Handle\n"
            unless ($xml->isa('IO::Handle'));
    $p->{io_handle} = $xml;
    my $result = $p->_parse($opt);
    $p->_cleanup;
    return $result;
}

sub _parse_string {
    my $p       = shift;
    my $xml     = shift;
    my $opt     = $p->{ParseOptions};

    $p->_init_parser($opt);
    $p->{io_handle} = new IO::String($xml);
    my $result = $p->_parse($opt);
    $p->_cleanup;
    return $result;
}

sub _parse_systemid {
    my $p       = shift;
    my $xml     = shift;
    my $opt     = $p->{ParseOptions};

    $p->_init_parser($opt);
    $p->{io_handle} = new IO::File($xml, 'r');
    die "Can't open $xml ($!)\n"
            unless (defined $p->{io_handle});
    binmode $p->{io_handle}, ':raw';
    my $result = $p->_parse($opt);
    $p->_cleanup;
    return $result;
}

our ($default_rules, $rules);

sub _init_parser {
    my $self = shift;
    my $opt  = shift;

    die __PACKAGE__,": parser instance ($self) already parsing\n"
            if defined $self->{_InParse};

    $self->{_InParse} = 1;

    if ($opt->{UseOnlyDefaultRules}) {
        $self->{Rules} = undef;
    }
    else {
        unless (defined $rules) {
            my $infile;
            if ($opt->{RulesPath}) {
                $infile = $opt->{RulesPath};
            }
            else {
                my $path = $INC{'WAP/SAXDriver/wbxml.pm'};
                $path =~ s/\.pm$//i;
                $infile = $path . '/wap.wbrules2.pl';
            }
            require $infile;
        }
        $self->{Rules} = $rules;
    }
}


sub _cleanup {
    my $self = shift;

    $self->{_InParse} = 0;
    delete $self->{PublicId};
    delete $self->{Encoding};
    delete $self->{App};
    delete $self->{publicid_idx};
    delete $self->{root_name};
    delete $self->{io_strtbl} if (exists $self->{io_strtbl});
    delete $self->{strtbl} if (exists $self->{strtbl});
    delete $self->{io_handle};
}

sub location {
    my $self = shift;

    my $pos = $self->{io_handle}->tell();

    my @properties = (
        ColumnNumber    => $pos,
        LineNumber      => 1,
        BytePosition    => $pos,
    );

    push (@properties, PublicId => $self->{PublicId})
            if (defined $self->{PublicId});

    return { @properties };
}

################################# W B X M L ##################################

use integer;

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
use constant TAG_MASK       => 0x3F;
use constant ATTR_MASK      => 0x7F;

sub _parse {
    my $self = shift;
    my ($opt) = @_;

    $self->{PublicId} = undef;
    $self->{Encoding} = undef;
    $self->{App} = undef;

    my $version = $self->get_version();
    $self->get_publicid();
    $self->get_charset();
    if (        !defined $self->{Encoding}
            and exists $opt->{Source}{Encoding} ) {
        $self->{Encoding} = $self->{Source}{Encoding};
    }
    $self->get_strtbl();
    $self->{PublicId} = $self->get_str_t($self->{publicid_idx})
            if (exists $self->{publicid_idx});
    if ($self->{PublicId} eq 'PublicId-Unknown') {
        my ($val) = values %{$self->{Rules}->{App}};
        $self->{App} = $val;
    }
    else {
        $self->{App} = $self->{Rules}->{App}{$self->{PublicId}};
    }

    $self->SUPER::start_document( {
            Version         => '1.0',
            Encoding        => $self->{Encoding},
            Standalone      => undef,
            VersionWBXML    => $version,
    } );
    $self->SUPER::xml_decl( {
            Version         => '1.0',
            Encoding        => $self->{Encoding},
            Standalone      => undef,
            VersionWBXML    => $version,
    } );

    my $rc = $self->body();
    my $end = $self->SUPER::end_document( { } );

    unless (defined $rc) {
        my $pos = $self->{io_handle}->tell();
        $self->SUPER::fatal_error( {
                Message         => q{},
                PublicId        => $self->{PublicId},
                ColumnNumber    => $pos,
                LineNumber      => 1,
                BytePosition    => $pos
        } );
        warn __PACKAGE__,": Fatal error at position $pos\n";
    }

    return $end;
}

sub getmb32 {
    my $self = shift;
    my $byte;
    my $val = 0;
    my $nb = 0;
    do {
        $nb ++;
        return undef unless ($nb < 6);
        my $ch = $self->{io_handle}->getc();
        return undef unless (defined $ch);
        $byte = ord $ch;
        $val <<= 7;
        $val += ($byte & 0x7f);
    }
    while (0 != ($byte & 0x80));
    return $val
}

sub get_version {
    my $self = shift;
    my $ch = $self->{io_handle}->getc();
    return undef unless (defined $ch);
    my $v = ord $ch;
    return (1 + $v / 16) . '.' . ($v % 16);
}

sub get_publicid {
    my $self = shift;
    my $publicid = $self->getmb32();
    return undef unless (defined $publicid);
    if ($publicid == 1) {
        $self->{PublicId} = "PublicId-Unknown";
    }
    elsif ($publicid) {
        if (exists $self->{Rules}->{PublicIdentifier}{$publicid}) {
            $self->{PublicId} = $self->{Rules}->{PublicIdentifier}{$publicid};
        }
        else {
            $self->warning("PublicId-$publicid unreferenced");
            $self->{PublicId} = "PublicId-$publicid";
        }
    }
    else {
        $self->{publicid_idx} = $self->getmb32();
    }
}

sub get_charset {
    my $self = shift;
    my $charset = $self->getmb32();
    return unless (defined $charset);
    if ($charset != 0) {
        my $default_charset = {
        # here, only built-in encodings of Expat.
        # MIBenum   =>  iana name
            3       => 'ANSI_X3.4-1968',    # US-ASCII
            4       => 'ISO_8859-1:1987',
            106     => 'UTF-8',
        };
        if (exists $default_charset->{$charset}) {
            $self->{Encoding} = $default_charset->{$charset};
            return;
        }
        eval "use I18N::Charset";
        unless ($@) {
            if (defined I18N::Charset::mib_to_charset_name($charset)) {
                $self->{Encoding} = I18N::Charset::mib_to_charset_name($charset);
                return;
            }
        }
        $self->{Encoding} = "MIBenum-$charset";
        $self->warning("$self->{Encoding} unreferenced");
    }
}

sub get_strtbl {
    my $self = shift;
    my $len = $self->getmb32();
    if ($len) {
        my $str = q{};
        $self->{io_handle}->read($str,$len);
        $self->{strtbl} = $str . chr 0;
        $self->{io_strtbl} = new IO::String($self->{strtbl});
    }
}

sub get_str_t {
    my $self = shift;
    my ($idx) = @_;
    return undef unless (defined $idx);
    return undef unless (exists $self->{io_strtbl});
    $self->{io_strtbl}->setpos($idx);
    my $str = q{};
    my $ch = $self->{io_strtbl}->getc();
    return undef unless (defined $ch);
    while (ord $ch != 0) {
        $str .= $ch;
        $ch = $self->{io_strtbl}->getc();
        return undef unless (defined $ch);
    }
    return $str;
}

sub body {
    my $self = shift;
    my $rc;
    $self->{codepage_tag} = 0;
    $self->{codepage_attr} = 0;
    my $tag = $self->get_tag();
    while ($tag == PI) {
        $rc = $self->pi();
        return undef unless (defined $rc);
        $tag = $self->get_tag();
    }
    $rc = $self->element($tag);
    return undef unless (defined $rc);
    $tag = $self->get_tag();
    if (defined $tag) {
        while ($tag == PI) {
            $rc = $self->pi();
            return undef unless (defined $rc);
            $tag = $self->get_tag();
        }
    }
    return 1;
}

sub pi {
    my $self = shift;
    my $attr = $self->get_attr();
    my $rc = $self->attribute($attr);
    return undef unless (defined $rc);
    my $target = $self->{attrs};
    $attr = $self->get_attr();
    my $data = q{};
    while ($attr != _END) {
        $rc = $self->attribute($attr);
        return undef unless (defined $rc);
        $data .= $self->{attrv};
        $attr = $self->get_attr();
    }
    delete $self->{attrs};
    delete $self->{attrv};
    $self->SUPER::processing_instruction( {
            Target      => $target,
            Data        => $data
    } );
    return 1;
}

sub element {
    my $self = shift;
    my ($tag) = @_;

    return undef unless (defined $tag);
    my $token = $tag & TAG_MASK;
    my $name;
    if ($token == LITERAL) {
        my $idx = $self->getmb32();
        $name = $self->get_str_t($idx);
        return undef unless (defined $name);
    }
    else {
        $token += 256 * $self->{codepage_tag};
        if (        defined $self->{App}
                and exists $self->{App}{TAG}{$token}) {
            $name = $self->{App}{TAG}{$token};
        }
        else {
            $name = "TAG-$token";
            $self->warning("$name unreferenced");
        }
    }
    unless (exists $self->{root_name}) {
        if ($self->{PublicId} ne 'PublicId-Unknown') {
            my $system_id = $self->{App}->{systemid} || $name . '.dtd';
            $self->SUPER::start_dtd( {
                    Name            => $name,
                    PublicId        => $self->{PublicId},
                    SystemId        => $system_id
            } );
            $self->SUPER::end_dtd( { } );
        }
        $self->{root_name} = $name;
    }
    my %saxattr;
    if ($tag & HAS_ATTR) {
        my $attr = $self->get_attr();
        while ($attr != _END) {
            my $rc = $self->attribute($attr);
            return undef unless (defined $rc);
            if (exists $self->{attrs}) {
                my $lname = $self->{attrs};
                my $at = {
                        Name        => $lname,
                        Value       => $self->{attrv}
                };
                $saxattr{"{}$lname"} = $at;
            }
            $attr = $self->get_attr();
        }
        delete $self->{attrs};
        delete $self->{attrv};
    }
    $self->SUPER::start_element( {
            Name        => $name,
            Attributes  => \%saxattr
    } );
    if ($tag & HAS_CHILD) {
        while ((my $child = $self->get_tag()) != _END) {
            my $rc = $self->content($child,$token);
            return undef unless (defined $rc);
        }
    }
    $self->SUPER::end_element( {
            Name        => $name
    } );
    return 1;
}

sub content {
    my $self = shift;
    my ($tag,$parent) = @_;

    return undef unless (defined $tag);
    if      ($tag == ENTITY) {
        my $entcode = $self->getmb32();
        return undef unless (defined $entcode);
        $self->SUPER::characters( {
                Data => chr $entcode
        } );
    }
    elsif ($tag == STR_I) {
        my $string = $self->get_str_i();
        return undef unless (defined $string);
        if (        defined $self->{App}
                and exists $self->{App}{variable_subs} ) {
            $string =~ s/\$/\$\$/g;
        }
        $self->SUPER::characters( {
                Data => $string
        } );
    }
    elsif ($tag == EXT_I_0) {
        my $string = $self->get_str_i();
        return undef unless (defined $string);
        if (        defined $self->{App}
                and exists $self->{App}{variable_subs} ) {
            $self->SUPER::characters( {
                    Data => "\$($string:escape)"
            } );
        }
        else {
            $self->error("EXT_I_0 unexpected");
        }
    }
    elsif ($tag == EXT_I_1) {
        my $string = $self->get_str_i();
        return undef unless (defined $string);
        if (        defined $self->{App}
                and exists $self->{App}{variable_subs} ) {
            $self->SUPER::characters( {
                Data => "\$($string:unesc)"
            } );
        }
        else {
            $self->error("EXT_I_1 unexpected");
        }
    }
    elsif ($tag == EXT_I_2) {
        my $string = $self->get_str_i();
        return undef unless (defined $string);
        if (        defined $self->{App}
                and exists $self->{App}{variable_subs} ) {
            $self->SUPER::characters( {
                Data => "\$($string)"
            } );
        }
        else {
            $self->error("EXT_I_2 unexpected");
        }
    }
    elsif ($tag == PI) {
        my $rc = $self->pi();
        return undef unless (defined $rc);
    }
    elsif ($tag == EXT_T_0) {
        my $idx = $self->getmb32();
        if (        defined $self->{App}
                and exists $self->{App}{variable_subs} ) {
            my $string = $self->get_str_t($idx);
            return undef unless (defined $string);
            $self->SUPER::characters( {
                    Data => "\$($string:escape)"
            } );
        }
        elsif (   defined $self->{App}
                and exists $self->{App}{EXT0VALUE}) {
            if (exists $self->{App}{EXT0VALUE}{$idx}) {
                $self->SUPER::characters( {
                        Data => $self->{App}{EXT0VALUE}{$idx}
                } );
            }
            else {
                $self->error("EXT_T_0 $idx unknown");
            }
        }
        else {
            $self->error("EXT_T_0 unexpected");
        }
    }
    elsif ($tag == EXT_T_1) {
        my $idx = $self->getmb32();
        if (        defined $self->{App}
                and exists $self->{App}{variable_subs} ) {
            my $string = $self->get_str_t($idx);
            return undef unless (defined $string);
            $self->SUPER::characters( {
                Data => "\$($string:unesc)"
            } );
        }
        elsif (   defined $self->{App}
                and exists $self->{App}{EXT1VALUE}) {
            if (exists $self->{App}{EXT1VALUE}{$idx}) {
                $self->SUPER::characters( {
                        Data => $self->{App}{EXT1VALUE}{$idx}
                } );
            }
            else {
                $self->error("EXT_T_1 $idx unknown");
            }
        }
        else {
            $self->error("EXT_T_1 unexpected");
        }
    }
    elsif ($tag == EXT_T_2) {
        my $idx = $self->getmb32();
        if (        defined $self->{App}
                and exists $self->{App}{variable_subs} ) {
            my $string = $self->get_str_t($idx);
            return undef unless (defined $string);
            $self->SUPER::characters( {
                Data => "\$($string)"
            } );
        }
        elsif (   defined $self->{App}
                and exists $self->{App}{EXT2VALUE}) {
            if (exists $self->{App}{EXT2VALUE}{$idx}) {
                $self->SUPER::characters( {
                        Data => $self->{App}{EXT2VALUE}{$idx}
                } );
            }
            else {
                $self->error("EXT_T_2 $idx unknown");
            }
        }
        else {
            $self->error("EXT_T_2 unexpected");
        }
    }
    elsif ($tag == STR_T) {
        my $idx = $self->getmb32();
        my $string = $self->get_str_t($idx);
        return undef unless (defined $string);
        if (        defined $self->{App}
                and exists $self->{App}{variable_subs} ) {
            $string =~ s/\$/\$\$/g;
        }
        $self->SUPER::characters( {
                Data => $string
        } );
    }
    elsif ($tag == EXT_0) {
        $self->error("EXT_0 unexpected");
    }
    elsif ($tag == EXT_1) {
        $self->error("EXT_1 unexpected");
    }
    elsif ($tag == EXT_2) {
        $self->error("EXT_2 unexpected");
    }
    elsif ($tag == OPAQUE) {
        my $data = $self->get_opaque();
        return undef unless (defined $data);
        my $encoding = (defined $self->{App} and exists $self->{App}{TagEncoding}{$parent})
                     ? $self->{App}{TagEncoding}{$parent} : q{};
        if      ($encoding eq 'base64') {
            use MIME::Base64;
            my $encoded = encode_base64($data);
            $self->SUPER::characters( {
                    Data => $encoded
            } );
        }
        elsif ($encoding eq 'datetime') {
            my $len = length $data;
            my $value = q{};
            if ($len == 6) {
                my @byte  = unpack 'C*', $data;
                my $year  = ($byte[0] << 6) | ($byte[1] >> 2);
                my $month = (($byte[1] & 0x3) << 2) | ($byte[2] >> 6);
                my $day   = (($byte[2] >> 1) & 0x1F);
                my $hour  = (($byte[2] & 0x1) << 4) | ($byte[3] >> 4);
                my $min   = (($byte[3] & 0xF) << 2) | ($byte[4] >> 6);
                my $sec   = ($byte[4] & 0x3F);
                my $tz    = $byte[5];
                $value = sprintf('%04d%02d%02dT%02d%02d%02d%c',$year,$month,$day,$hour,$min,$sec,$tz);
            }
            else {
                $self->error("OPAQUE : invalid 'datetime'");
            }
            $self->SUPER::characters( {
                    Data => $value
            } );
        }
        elsif ($encoding eq 'integer') {
            my $len = length $data;
            my $value = 0;
            if      ($len == 1) {
                $value = unpack 'C', $data;
            }
            elsif ($len == 2) {
                $value = unpack 'n', $data;
            }
            elsif ($len == 4) {
                $value = unpack 'N', $data;
            }
            else {
                $self->error("OPAQUE : invalid 'integer'");
            }
            $self->SUPER::characters( {
                    Data => "$value"
            } );
        }
        else {
            $self->SUPER::characters( {
                    Data => $data
            } );
        }
    }
    else {
        my $rc = $self->element($tag);  # LITERAL and all TAG
        return undef unless (defined $rc);
    }
    return 1;
}

sub attribute {
    my $self = shift;
    my ($attr) = @_;

    return undef unless (defined $attr);
    if      ($attr == ENTITY) {     # ATTRV
        my $entcode = $self->getmb32();
        return undef unless (defined $entcode);
        $self->{attrv} .= chr $entcode;
    }
    elsif ($attr == STR_I) {        # ATTRV
        my $string = $self->get_str_i();
        return undef unless (defined $string);
        if (        exists $self->{ATTRSTART}{validate}
                and $self->{ATTRSTART}{validate} eq 'vdata' ) {
            $string =~ s/\$/\$\$/g;
        }
        $self->{attrv} .= $string;
    }
    elsif ($attr == LITERAL) {  # ATTRS
        my $idx = $self->getmb32();
        my $string = $self->get_str_t($idx);
        return undef unless (defined $string);
        $self->{attrs} = $string;
        $self->{attrv} = q{};
        $self->{ATTRSTART} = undef;
    }
    elsif ($attr == EXT_I_0) {  # ATTRV
        my $string = $self->get_str_i();
        return undef unless (defined $string);
        if (        defined $self->{ATTRSTART}
                and $self->{ATTRSTART}{validate} eq 'vdata' ) {
            $self->{attrv} .= "\$($string:escape)";
        }
        else {
            $self->error("EXT_I_0 unexpected");
        }
    }
    elsif ($attr == EXT_I_1) {  # ATTRV
        my $string = $self->get_str_i();
        return undef unless (defined $string);
        if (        defined $self->{ATTRSTART}
                and $self->{ATTRSTART}{validate} eq 'vdata' ) {
            $self->{attrv} .= "\$($string:unesc)";
        }
        else {
            $self->error("EXT_I_1 unexpected");
        }
    }
    elsif ($attr == EXT_I_2) {  # ATTRV
        my $string = $self->get_str_i();
        return undef unless (defined $string);
        if (        defined $self->{ATTRSTART}
                and $self->{ATTRSTART}{validate} eq 'vdata' ) {
            $self->{attrv} .= "\$($string)";
        }
        else {
            $self->error("EXT_I_2 unexpected");
        }
    }
    elsif ($attr == EXT_T_0) {  # ATTRV
        my $idx = $self->getmb32();
        if (        defined $self->{ATTRSTART}
                and $self->{ATTRSTART}{validate} eq 'vdata' ) {
            my $string = $self->get_str_t($idx);
            return undef unless (defined $string);
            $self->{attrv} .= "\$($string:escape)";
        }
        elsif (   defined $self->{App}
                and exists $self->{App}{EXT0VALUE}) {
            if (exists $self->{App}{EXT0VALUE}{$idx}) {
                $self->{attrv} .= $self->{App}{EXT0VALUE}{$idx}
            }
            else {
                $self->error("EXT_T_0 $idx unknown");
            }
        }
        else {
            $self->error("EXT_T_0 unexpected");
        }
    }
    elsif ($attr == EXT_T_1) {  # ATTRV
        my $idx = $self->getmb32();
        if (        defined $self->{ATTRSTART}
                and $self->{ATTRSTART}{validate} eq 'vdata' ) {
            my $string = $self->get_str_t($idx);
            return undef unless (defined $string);
            $self->{attrv} .= "\$($string:unesc)";
        }
        elsif (   defined $self->{App}
                and exists $self->{App}{EXT1VALUE}) {
            if (exists $self->{App}{EXT1VALUE}{$idx}) {
                $self->{attrv} .= $self->{App}{EXT1VALUE}{$idx}
            }
            else {
                $self->error("EXT_T_1 $idx unknown");
            }
        }
        else {
            $self->error("EXT_T_1 unexpected");
        }
    }
    elsif ($attr == EXT_T_2) {  # ATTRV
        my $idx = $self->getmb32();
        if (        defined $self->{ATTRSTART}
                and $self->{ATTRSTART}{validate} eq 'vdata' ) {
            my $string = $self->get_str_t($idx);
            return undef unless (defined $string);
            $self->{attrv} .= "\$($string)";
        }
        elsif (   defined $self->{App}
                and exists $self->{App}{EXT2VALUE}) {
            if (exists $self->{App}{EXT2VALUE}{$idx}) {
                $self->{attrv} .= $self->{App}{EXT2VALUE}{$idx}
            }
            else {
                $self->error("EXT_T_2 $idx unknown");
            }
        }
        else {
            $self->error("EXT_T_2 unexpected");
        }
    }
    elsif ($attr == STR_T) {        # ATTRV
        my $idx = $self->getmb32();
        my $string = $self->get_str_t($idx);
        return undef unless (defined $string);
        if (        exists $self->{ATTRSTART}{validate}
                and $self->{ATTRSTART}{validate} eq 'vdata' ) {
            $string =~ s/\$/\$\$/g;
        }
        $self->{attrv} .= $string;
    }
    elsif ($attr == EXT_0) {        # ATTRV
        $self->error("EXT_0 unexpected");
    }
    elsif ($attr == EXT_1) {        # ATTRV
        $self->error("EXT_1 unexpected");
    }
    elsif ($attr == EXT_2) {        # ATTRV
        $self->error("EXT_2 unexpected");
    }
    elsif ($attr == OPAQUE) {       # ATTRV
        my $data = $self->get_opaque();
        return undef unless (defined $data);
        if (        exists $self->{ATTRSTART}{encoding}
                and $self->{ATTRSTART}{encoding} eq 'iso-8601' ) {
            foreach (split //, $data) {
                $self->{attrv} .=  sprintf('%02X', ord $_);
            }
        }
        else {
            $self->error("OPAQUE unexpected");
        }
    }
    else {
        my $token = $attr; # & ATTR_MASK;
        $token += 256 * $self->{codepage_attr};
        if ($attr & 0x80) {
            if (        defined $self->{App}
                    and exists $self->{App}{ATTRVALUE}{$token}) {
                $self->{attrv} .= $self->{App}{ATTRVALUE}{$token};
            }
            else {
                $self->{attrv} .=  "ATTRV-$token";
                $self->warning("ATTRV-$token unreferenced");
            }
        }
        else {
            $self->{attrv} = q{};
            $self->{ATTRSTART} = undef;
            if (        defined $self->{App}
                    and exists $self->{App}{ATTRSTART}{$token} ) {
                $self->{ATTRSTART} = $self->{App}{ATTRSTART}{$token};
                $self->{attrs} = $self->{ATTRSTART}{name};
                $self->{attrv} = $self->{ATTRSTART}{value}
                        if (exists $self->{ATTRSTART}{value});
            }
            else {
                $self->{attrs} = "ATTRS-$token";
                $self->warning("ATTRS-$token unreferenced");
            }
        }
    }
    return 1;
}

sub get_tag {
    my $self = shift;
    my $ch = $self->{io_handle}->getc();
    return undef unless (defined $ch);
    my $tag = ord $ch;
    if ($tag == SWITCH_PAGE) {
        $ch = $self->{io_handle}->getc();
        return undef unless (defined $ch);
        $self->{codepage_tag} = ord $ch;
        $ch = $self->{io_handle}->getc();
        return undef unless (defined $ch);
        $tag = ord $ch;
    }
    return $tag;
}

sub get_attr {
    my $self = shift;
    my $ch = $self->{io_handle}->getc();
    return undef unless (defined $ch);
    my $attr = ord $ch;
    if ($attr == SWITCH_PAGE) {
        $ch = $self->{io_handle}->getc();
        return undef unless (defined $ch);
        $self->{codepage_attr} = ord $ch;
        $ch = $self->{io_handle}->getc();
        return undef unless (defined $ch);
        $attr = ord $ch;
    }
    return $attr;
}

sub get_str_i {
    my $self = shift;
    my $str = q{};
    my $ch = $self->{io_handle}->getc();
    return undef unless (defined $ch);
    while (ord $ch != 0) {
        $str .= $ch;
        $ch = $self->{io_handle}->getc();
        return undef unless (defined $ch);
    }
    return $str;
}

sub get_opaque {
    my $self = shift;
    my $data;
    my $len = $self->getmb32();
    return undef unless (defined $len);
    $self->{io_handle}->read($data,$len);
    return $data;
}

sub warning {
    my $self = shift;
    my ($msg) = @_;
    my $pos = $self->{io_handle}->tell();
    $self->{message_no_op} = __PACKAGE__ . ": Warning: $msg\n\tat position $pos\n";
    $self->SUPER::warning( {
            Message         => $msg,
            PublicId        => $self->{PublicId},
            ColumnNumber    => $pos,
            LineNumber      => 1,
            BytePosition    => $pos
    } );
}

sub error {
    my $self = shift;
    my ($msg) = @_;
    my $pos = $self->{io_handle}->tell();
    $self->{message_no_op} = __PACKAGE__ . ": Error: $msg\n\tat position $pos\n";
    $self->SUPER::error( {
            Message         => $msg,
            PublicId        => $self->{PublicId},
            ColumnNumber    => $pos,
            LineNumber      => 1,
            BytePosition    => $pos
    } );
}

sub no_op {
    my $self = shift;
    if (exists $self->{message_no_op}) {
        warn $self->{message_no_op};
        delete $self->{message_no_op};
    }
}

1;

__END__

=head1 NAME

WAP::SAXDriver::wbxml - SAX parser for WBXML file

=head1 SYNOPSIS

 use WAP::SAXDriver::wbxml;

 $parser = WAP::SAXDriver::wbxml->new( [OPTIONS] );
 $result = $parser->parse( [OPTIONS] );

=head1 DESCRIPTION

C<WAP::SAXDriver::wbxml> is a SAX2 driver, and it inherits of XML::SAX::Base.
This man page summarizes the specific options, handlers, and
properties supported by C<WAP::SAXDriver::wbxml>; please refer to the
SAX 2.0 standard for general usage information.

A WBXML file is the binarized form of XML file according the specification :

 WAP - Wireless Application Protocol /
 Binary XML Content Format Specification /
 Version 1.3 WBXML (15th May 2000 Approved)

This module could be parametrized by the file C<WAP::SAXDriver::wbrules.pl>
what contains all specific values used by WAP applications.

This module needs IO::File, IO::String and I18N::Charset modules.

=head1 METHODS

=over 4

=item new

Creates a new parser object.  Default options for parsing, described
below, are passed as key-value pairs or as a single hash.  Options may
be changed directly in the parser object unless stated otherwise.
Options passed to `C<parse()>' override the default options in the
parser object for the duration of the parse.

=item parse

Parses a document.  Options, described below, are passed as key-value
pairs or as a single hash.  Options passed to `C<parse()>' override
default options in the parser object.

=item parse_file, parse_uri, parse_string

These are all convenience variations on parse(), and in fact simply
set up the options before calling it.

=item location (SAX1)

Returns the location as a hash:

  BytePosition    The current byte position of the parse.
  ColumnNumber    The column number of the parse, equals to BytePosition.
  LineNumber      The line number of the parse, always equals to 1.
  PublicId        A string containing the public identifier, or undef
                  if none is available.

=back

=head1 OPTIONS

The following options are supported by C<WAP::SAXDriver::wbxml> :

 Handler              default handler to receive events
 DocumentHandler      handler to receive document events
 DTDHandler           handler to receive DTD events
 ErrorHandler         handler to receive error events
 Source               hash containing the input source for parsing
 UseOnlyDefaultRules  boolean, if true the file wap.wbrules2.pl is not loaded
 RulesPath            path of alternate rules (standard is WAP/SAXDriver/wap.wbrules2.pl)

If no handlers are provided then all events will be silently ignored,
except for `C<fatal_error()>' which will cause a `C<die()>' to be
called after calling `C<end_document()>'.

The `C<Source>' hash may contain the following parameters:

 ByteStream       The raw byte stream (file handle) containing the
                  document.
 String           A string containing the document.
 Encoding         A string describing the character encoding.

If more than one of `C<ByteStream>', or `C<String>',
then preference is given first to `C<ByteStream>', then `C<String>'.

=head1 HANDLERS

The following handlers and properties are supported by
C<WAP::SAXDriver::wbxml> :

=head2 Content Events

=over 4

=item start_document

Receive notification of the beginning of a document.

 Version          The XML version, always 1.0.
 Encoding         The encoding string, if any.
 Standalone       undefined.
 VersionWBXML     The version used for the binarization.

=item end_document

Receive notification of the end of a document.

No properties defined.

=item start_element

Receive notification of the beginning of an element.

 Name             The element type name.
 Attributes       A hash containing the attributes attached to the
                  element, if any.

The `C<Attributes>' hash contains only string values.

=item end_element

Receive notification of the end of an element.

 Name             The element type name.

=item characters

Receive notification of character data.

 Data             The characters from the XML document.

=item processing_instruction

Receive notification of a processing instruction.

 Target           The processing instruction target.
 Data             The processing instruction data, if any.

=back

=head2 Error Events

=over 4

=item warning

Receive notification of a warning event.

  Message         The detailed explanation.
  BytePosition    The current byte position of the parse.
  ColumnNumber    The column number of the parse, equals to BytePosition.
  LineNumber      The line number of the parse, always equals to 1.
  PublicId        A string containing the public identifier, or undef
                  if none is available.

=item error

Receive notification of an error event.

  Message         The detailed explanation.
  BytePosition    The current byte position of the parse.
  ColumnNumber    The column number of the parse, equals to BytePosition.
  LineNumber      The line number of the parse, always equals to 1.
  PublicId        A string containing the public identifier, or undef
                  if none is available.

=item fatal_error

Receive notification of a fatal error event.

  BytePosition    The current byte position of the parse.
  ColumnNumber    The column number of the parse, equals to BytePosition.
  LineNumber      The line number of the parse, always equals to 1.
  PublicId        A string containing the public identifier, or undef
                  if none is available.

=back

=head2 Lexical Events

=over 4

=item start_dtd

Receive notification of the beginning of a DTD

 Name             The document type name
 PublicId         The declared public identifier for the external DTD
 SystemId         The declared system identifier for the external DTD (may be wrong)

=item end_dtd

Receive notification of the end of a DTD.

No properties defined.

=back

=head2 SAX1 methods

=over 4

=item xml_decl

Deprecated in favour of start_document.

Receive notification of a XML declaration event.

 Version          The XML version, always 1.0.
 Encoding         The encoding string, if any.
 Standalone       undefined.
 VersionWBXML     The version used for the binarization.

=back

=head1 COPYRIGHT

(c) 2002-2007 Francois PERRAD, France.

This program is distributed under the terms of the Artistic Licence.

The WAP Specifications are copyrighted by the Wireless Application Protocol Forum Ltd.
See E<lt>http://www.wapforum.org/what/copyright.htmE<gt>.

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=head1 SEE ALSO

XML::SAX, XML::SAX::Base, WAP::wbxml

Extensible Markup Language (XML) http://www.w3c.org/XML/
Binary XML Content Format (WBXML) http://www.wapforum.org/
Simple API for XML (SAX) http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/~checkout~/perl-xml/libxml-perl/doc/sax-2.0.html?rev=HEAD&content-type=text/html

=cut

