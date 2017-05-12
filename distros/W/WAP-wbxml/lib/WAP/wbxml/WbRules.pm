
use strict;
use warnings;

package WAP::wbxml::Token;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($token, $codepage) = @_;
    $self->{ext_token} = 256 * hex($codepage) + hex($token);
    return $self;
}

package WAP::wbxml::TagToken;

use base qw(WAP::wbxml::Token);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($token, $name, $codepage, $encoding) = @_;
    my $self = new WAP::wbxml::Token($token, $codepage);
    bless $self, $class;
    $self->{name} = $name;
    $self->{encoding} = $encoding if ($encoding ne q{});
    return $self;
}

package WAP::wbxml::AttrStartToken;

use base qw(WAP::wbxml::Token);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($token, $name, $value, $codepage, $default, $fixed, $validate, $encoding) = @_;
    my $self = new WAP::wbxml::Token($token, $codepage);
    bless $self, $class;
    $self->{name} = $name;
    $self->{value} = $value if ($value ne q{});
    $self->{default} = $default if ($default ne q{});
    $self->{fixed} = $fixed if ($fixed ne q{});
    $self->{validate} = $validate if ($validate ne q{});
    $self->{encoding} = $encoding if ($encoding ne q{});
    return $self;
}

package WAP::wbxml::AttrValueToken;

use base qw(WAP::wbxml::Token);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($token, $value, $codepage) = @_;
    my $self = new WAP::wbxml::Token($token, $codepage);
    bless $self, $class;
    $self->{value} = $value;
    return $self;
}

package WAP::wbxml::ExtValue;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($index, $value) = @_;
    $self->{index} = hex($index);
    $self->{value} = $value;
    return $self;
}

package WAP::wbxml::WbRulesApp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($publicid, $use_default, $variable_subs, $textual_ext, $tokenised_ext, $xml_space) = @_;
    $self->{publicid} = $publicid;
    $self->{skipDefault} = $use_default eq 'yes';
    $self->{variableSubs} = $variable_subs eq 'yes';
    $self->{textualExt} = $textual_ext || 'xml';
    $self->{tokenisedExt} = $tokenised_ext || 'wbxml';
    $self->{xmlSpace} = $xml_space || 'preserve';
    $self->{TagTokens} = [];
    $self->{AttrStartTokens} = [];
    $self->{AttrValueTokens} = [];
    return $self;
}

sub getTag {
    my $self = shift;
    my ($tagname, $curr_page) = @_;
    if ($tagname) {
        my @found = ();
        foreach (@{$self->{TagTokens}}) {
            if ($tagname eq $_->{name}) {
#                print "Tag $_->{name}.\n";
                if ($_->{ext_token} / 256 == $curr_page) {
                    return $_;
                }
                else {
                    push @found, $_;
                }
            }
        }
        if (scalar @found) {
            return shift @found;
        }
    }
    return undef;
}

sub getAttrStart {
    my $self = shift;
    my ($name, $value, $curr_page) = @_;
    my $best = undef;
    my $remain = $value;
    if ($name) {
        my $max_len = -1;
        foreach (@{$self->{AttrStartTokens}}) {
            if ($name eq $_->{name}) {
                if (exists $_->{value}) {
                    my $attr_value = $_->{value};
                    my $len = length $attr_value;
                    if ( ($attr_value eq $value) or
                         ($len < length $value and $attr_value eq substr($value, 0, $len)) ) {
                        if ($len > $max_len) {
                            $max_len = $len;
                            $best = $_;
                        }
                        elsif ($len == $max_len) {
                            if ($_->{ext_token} / 256 == $curr_page) {
                                $best = $_;
                            }
                        }
                    }
                }
                else {
                    if ($max_len == -1) {
                        $max_len = 0;
                        $best = $_;
                    }
                    elsif ($max_len == 0) {
                        if ($_->{ext_token} / 256 == $curr_page) {
                            $best = $_;
                        }
                    }
                }
            }
        }
        if ($best and $max_len != -1) {
            $remain = substr $remain, $max_len;
#            if (exists $best->{value}) {
#                print "AttrStart : $best->{name} $best->{value}.\n";
#            }
#            else {
#                print "AttrStart : $best->{name}.\n";
#            }
        }
    }
    return ($best, $remain);
}

sub getAttrValue {
    my $self = shift;
    my ($start, $curr_page) = @_;
    my $best = undef;
    my $end = q{};
    if ($start ne q{}) {
        my $max_len = 0;
        my $best_found = length $start;
        foreach (@{$self->{AttrValueTokens}}) {
            my $value = $_->{value};
            if ($value ne q{}) {
                my $len = length $value;
                my $found = index $start, $value;
                if ($found >= 0) {
                    if    ($found == $best_found) {
                        if ($len > $max_len) {
                            $max_len = $len;
                            $best = $_;
                        }
                        elsif ($len == $max_len) {
                            if ($_->{ext_token} / 256 == $curr_page) {
                                $best = $_;
                            }
                        }
                    }
                    elsif ($found <  $best_found) {
                        $best = $_;
                        $best_found = $found;
                        $max_len = $len;
                    }
                }
            }
        }
        if ($best) {
            $end = substr $start, $best_found+$max_len;
            $start = substr $start, 0, $best_found;
#            print "AttrValue : $best->{value} ($start, $end).\n";
        }
    }
    return ($best, $start, $end);
}

sub getExtValue {
    my $self = shift;
    my ($value, $ext) = @_;
    if ($value and exists $self->{$ext} and scalar $self->{$ext}) {
        foreach (@{$self->{$ext}}) {
            if ($value eq $_->{value}) {
#                print "ExtValue : $value\n";
                return $_->{index} ;
            }
        }
    }
    return undef;
}

package WAP::wbxml::WbRules;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($version) = @_;
    if ($version =~ /(\d+)\.(\d+)/) {
        $self->{version} = 16 * ($1 - 1) + $2;
    }
    else {
        $self->{version} = 0x03;        # WBXML 1.3 : latest known version
    }
    $self->{PublicIdentifiers} = {};
    $self->{App} = {};
    $self->{DefaultApp} = new WAP::wbxml::WbRulesApp('DEFAULT', q{}, q{}, q{}, q{}, q{});
    return $self;
}

package WAP::wbxml::constructVisitor;
use XML::DOM;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($doc) = @_;
    $self->{doc} = $doc;
    return $self;
}

sub visitwbxml {
    my $self = shift;
    my ($parent) = @_;
    my $version = $parent->getAttribute('version');
    $self->{wbrules} = new WAP::wbxml::WbRules($version);
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self);
        }
    }
}

sub visitCharacterSets {
    # empty
}

sub visitPublicIdentifiers {
    my $self = shift;
    my ($parent) = @_;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self);
        }
    }
}

sub visitPublicIdentifier {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->getAttribute('name');
    my $value = $node->getAttribute('value');           # hexadecimal
    $self->{wbrules}->{PublicIdentifiers}->{$name} = hex $value;
}

sub visitApp {
    my $self = shift;
    my ($parent) = @_;
    my $publicid = $parent->getAttribute('publicid');
    my $use_default = $parent->getAttribute('use-default');
    my $variable_subs = $parent->getAttribute('variable-subs');
    my $textual_ext = $parent->getAttribute('textual-ext');
    my $tokenised_ext = $parent->getAttribute('tokenised-ext');
    my $xml_space = $parent->getAttribute('xml-space');
    my $app = new WAP::wbxml::WbRulesApp($publicid, $use_default, $variable_subs, $textual_ext, $tokenised_ext, $xml_space);
    $self->{wbrules}->{App}->{$publicid} = $app;
    $self->{wbrulesapp} = $app;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self);
        }
    }
}

sub visitTagTokens {
    my $self = shift;
    my ($parent) = @_;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self);
        }
    }
}

sub visitTAG {
    my $self = shift;
    my ($node) = @_;
    my $token = $node->getAttribute('token');
    my $name = $node->getAttribute('name');
    my $codepage = $node->getAttribute('codepage');
    my $encoding = $node->getAttribute('encoding');
    my $tag = new WAP::wbxml::TagToken($token, $name, $codepage, $encoding);
    push @{$self->{wbrulesapp}->{TagTokens}}, $tag;
}

sub visitAttrStartTokens {
    my $self = shift;
    my ($parent) = @_;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self);
        }
    }
}

sub visitATTRSTART {
    my $self = shift;
    my ($node) = @_;
    my $token = $node->getAttribute('token');
    my $name = $node->getAttribute('name');
    my $value = $node->getAttribute('value');
    my $codepage = $node->getAttribute('codepage');
    my $default = $node->getAttribute('default');
    my $fixed = $node->getAttribute('fixed');
    my $validate = $node->getAttribute('validate');
    my $encoding = $node->getAttribute('encoding');
    my $tag = new WAP::wbxml::AttrStartToken($token, $name, $value, $codepage, $default, $fixed, $validate, $encoding);
    push @{$self->{wbrulesapp}->{AttrStartTokens}}, $tag;
}

sub visitAttrValueTokens {
    my $self = shift;
    my ($parent) = @_;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self);
        }
    }
}

sub visitATTRVALUE {
    my $self = shift;
    my ($node) = @_;
    my $token = $node->getAttribute('token');
    my $value = $node->getAttribute('value');
    my $codepage = $node->getAttribute('codepage');
    my $tag = new WAP::wbxml::AttrValueToken($token, $value, $codepage);
    push @{$self->{wbrulesapp}->{AttrValueTokens}}, $tag;
}

sub visitExt0Values {
    my $self = shift;
    my ($parent) = @_;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self, 'Ext0Values');
        }
    }
}

sub visitExt1Values {
    my $self = shift;
    my ($parent) = @_;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self, 'Ext1Values');
        }
    }
}

sub visitExt2Values {
    my $self = shift;
    my ($parent) = @_;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self, 'Ext0Values');
        }
    }
}

sub visitEXTVALUE {
    my $self = shift;
    my ($node, $ext) = @_;
    my $index = $node->getAttribute('index');
    my $value = $node->getAttribute('value');
    my $tag = new WAP::wbxml::ExtValue($index, $value);
    push @{$self->{wbrulesapp}->{$ext}}, $tag;
}

sub visitCharacterEntities {
    my $self = shift;
    my ($parent) = @_;
    for (my $node = $parent->getFirstChild();
            $node;
            $node = $node->getNextSibling() ) {
        if ($node->getNodeType() == ELEMENT_NODE) {
            $self->{doc}->visitElement($node, $self);
        }
    }
}

sub visitCharacterEntity {
    my $self = shift;
    my ($node) = @_;
    my $code = $node->getAttribute('code');
    my $name = $node->getAttribute('name');
    $self->{wbrulesapp}->{CharacterEntity}{$name} = $code;
}

package WAP::wbxml::doc;

use XML::DOM;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($file) = @_;
    my $parser = new XML::DOM::Parser;
    eval { $self->{doc} = $parser->parsefile($file); };
    die $@ if ($@);
    return undef unless ($self->{doc});
    $self->{root} = $self->{doc}->getDocumentElement();
    return $self;
}

sub visitElement {
    my $self = shift;
    my $node = shift;
    my $visitor = shift;
    my $name = $node->getNodeName();
    $name =~ s/^wbxml://;   # backward compat
    my $func = 'visit' . $name;
    if($visitor->can($func)) {
        $visitor->$func($node, @_);
    }
    else {
        warn "unknown element '$name'\n";
    }
}

package WAP::wbxml::WbRules;

=head1 NAME

WAP::wbxml::WbRules

=head1 DESCRIPTION

=over 4

=item Load

 $rules = WbRules::Load( [PATH] );

Loads rules from PATH.

WAP/wap.wbrules.pl is a serialized version (Data::Dumper).

WAP/wap.wbrules.xml supplies rules for WAP files, but it could extended to over XML applications.

=back

=cut

sub Load {
    my ($path) = @_;
    my $config;
    my $persistance;

    if ($path) {
        $config = $path;
        $persistance = $path;
        $persistance =~ s/\.\w+$//;
        $persistance .= '.pl';
    }
    else {
        $path = $INC{'WAP/wbxml.pm'};
        $path =~ s/\.pm$//i;
        $persistance = $path . '/wap.wbrules.pl';
        $config = $path . '/wap.wbrules.xml';
    }

    my @st_config = stat($config);
    die "can't found original rules ($config).\n" unless (@st_config);
    my @st_persistance = stat($persistance);
    if (@st_persistance) {
        if ($st_config[9] > $st_persistance[9]) {   # mtime
            print "$persistance needs update\n";
            die "can't unlink serialized rules ($persistance).\n"
                    unless (unlink $persistance);
        }
    }
    use vars qw($rules);
    do $persistance;
    unless (ref $rules eq 'WAP::wbxml::WbRules') {
        use Data::Dumper;
        print "parse rules\n";
        my $doc = new WAP::wbxml::doc($config);
        if ($doc) {
            use POSIX qw(ctime);
            my $visitor = new WAP::wbxml::constructVisitor($doc);
            $doc->visitElement($doc->{root}, $visitor);
            $rules = $visitor->{wbrules};
            $doc = undef;
            my $d = Data::Dumper->new([$rules], [qw($rules)]);
#            $d->Indent(1);
            $d->Indent(0);
            if (open my $PERSISTANCE, '>', $persistance) {
                print $PERSISTANCE "# This file is generated. DO NOT modify it.\n";
                print $PERSISTANCE "# From file : ",$config,"\n";
                print $PERSISTANCE "# Generation date : ",POSIX::ctime(time());
                print $PERSISTANCE $d->Dump();
                close $PERSISTANCE;
            }
            else {
                warn "cannot open '$persistance': $!\n";
            }
        }
        else {
            $WAP::wbxml::WbRules::rules = new WAP::wbxml::WbRules(q{});
        }
    }
    return $WAP::wbxml::WbRules::rules;
}

1;

