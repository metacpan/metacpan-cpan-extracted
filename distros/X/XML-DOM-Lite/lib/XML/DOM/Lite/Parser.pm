package XML::DOM::Lite::Parser;

use XML::DOM::Lite::Document;
use XML::DOM::Lite::Node;
use XML::DOM::Lite::Constants qw(:all);

#========================================================================
# These regular expressions have been gratefully borrowed from:
#
# REX/Perl 1.0 
# Robert D. Cameron "REX: XML Shallow Parsing with Regular Expressions",
# Technical Report TR 1998-17, School of Computing Science, Simon Fraser 
# University, November, 1998.
# Copyright (c) 1998, Robert D. Cameron. 
# The following code may be freely used and distributed provided that
# this copyright and citation notice remains intact and that modifications
# or additions are clearly identified.

our $TextSE = "[^<]+";
our $UntilHyphen = "[^-]*-";
our $Until2Hyphens = "$UntilHyphen(?:[^-]$UntilHyphen)*-";
our $CommentCE = "$Until2Hyphens>?";
our $UntilRSBs = "[^\\]]*](?:[^\\]]+])*]+";
our $CDATA_CE = "$UntilRSBs(?:[^\\]>]$UntilRSBs)*>";
our $S = "[ \\n\\t\\r]+";
our $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
our $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
our $Name = "(?:$NameStrt)(?:$NameChar)*";
our $QuoteSE = "\"[^\"]*\"|'[^']*'";
our $DT_IdentSE = "$S$Name(?:$S(?:$Name|$QuoteSE))*";
our $MarkupDeclCE = "(?:[^\\]\"'><]+|$QuoteSE)*>";
our $S1 = "[\\n\\r\\t ]";
our $UntilQMs = "[^?]*\\?+";
our $PI_Tail = "\\?>|$S1$UntilQMs(?:[^>?]$UntilQMs)*>";
our $DT_ItemSE = "<(?:!(?:--$Until2Hyphens>|[^-]$MarkupDeclCE)|\\?$Name(?:$PI_Tail))|%$Name;|$S";
our $DocTypeCE = "$DT_IdentSE(?:$S)?(?:\\[(?:$DT_ItemSE)*](?:$S)?)?>?";
our $DeclCE = "--(?:$CommentCE)?|\\[CDATA\\[(?:$CDATA_CE)?|DOCTYPE(?:$DocTypeCE)?";
our $PI_CE = "$Name(?:$PI_Tail)?";
our $EndTagCE = "$Name(?:$S)?>?";
our $AttValSE = "\"[^<\"]*\"|'[^<']*'";
our $ElemTagCE = "$Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?/?>?";
our $ElementCE = "/(?:$EndTagCE)?|(?:$ElemTagCE)?";
our $MarkupSPE = "<(?:!(?:$DeclCE)?|\\?(?:$PI_CE)?|(?:$ElementCE)?)";
our $XML_SPE = "$TextSE|$MarkupSPE";

#========================================================================

# these have captures for parsing the attributes
our $AttValSE2 = "\"([^<\"]*)\"|'([^<']*)'";
our $ElemTagCE2 = "(?:($Name)(?:$S)?=(?:$S)?($AttValSE2))+(?:$S)?/?>?";

sub new {
    my ($class, %options) = @_;
    my $self = bless {
        stack   => [ ],
        options => \%options,
    }, $class;
    return $self;
}

sub parse {
    my ($self, $XML) = (shift, shift);
    unless (ref($self)) {
        $self = __PACKAGE__->new(@_);
    }
    my @nodes = $self->_shallow_parse($XML);

    $self->{document} = XML::DOM::Lite::Document->new();
    push @{$self->{stack}}, $self->{document};

    STEP : foreach my $n ( @nodes ) {
        substr($n, 0, 1) eq '<' && do {
            substr($n, 1, 1) eq '!' && do {
                $self->_handle_decl_node($n);
                next STEP;
            };
            substr($n, 1, 1) eq '?' && do {
                $self->_handle_pi_node($n);
                next STEP;
            };
            $self->_handle_element_node($n);
            next STEP;
        };
        $self->_handle_text_node($n);
    }

    return $self->{document};
}

sub parseFile {
    my ($self, $filename) = @_;
    unless (ref $self) {
	$self = __PACKAGE__->new;
    }
    my $stream;
    {
        open FH, $filename or
            die "can't open file $filename for reading ".$!;
        local $/ = undef;
        $stream = <FH>;
        close FH;
    }
    return $self->parse($stream);
}

sub _shallow_parse { 
    my ($self, $XML) = @_;

    # Check the options.
    my %options = %{$self->{options}};
    if (defined($options{'whitespace'})) {
        my $mode = $options{'whitespace'};
        if (index($mode, 'strip') >= 0) {
            $XML =~ s/>$S/>/sg;
            $XML =~ s/$S</</sg;
        }
        if (index($mode, 'normalize') >= 0) {
            $XML =~ s/$S/ /sg
        }
    }

    return $XML =~ /$XML_SPE/go;
}

sub _handle_decl_node {
    my ($self, $decl) = @_;
    my $kind;
    my $length = length($decl);
    my $start = 1;
    $parent = $self->{stack}->[$#{$self->{stack}}];
    substr($decl, 0, 4) eq '<!--' && do {
	$start = 4;
	$length = $length - $start - 3;
	$kind = COMMENT_NODE;
    };
    substr($decl, 0, 9) eq '<![CDATA[' && do {
	$start = 9;
	$length = $length - $start - 3;
	$kind = CDATA_SECTION_NODE;
    };
    substr($decl, 0, 9) eq '<!DOCTYPE' && do { # I'm cheating here, should be a separate node!
	$start = 9;
	$length = $length - $start - 1;
	$kind = DOCUMENT_TYPE_NODE;
    };
    return $self->_mk_gen_node(substr($decl, $start, $length), $parent, $kind);
}

sub _handle_pi_node {
    my ($self, $pi) = @_;
    $pi =~ s/^<\?\S+//o;
    $pi =~ s/\?>$//so;
    $parent = $self->{stack}->[$#{$self->{stack}}];
    return $self->_mk_gen_node($pi, $parent, PROCESSING_INSTRUCTION_NODE);
}

sub _handle_text_node {
    my ($self, $text) = @_;
    $parent = $self->{stack}->[$#{$self->{stack}}];
    $text =~ s/^\n//so; return unless defined $text;
    return $self->_mk_gen_node($text, $parent, TEXT_NODE);
}

sub _handle_element_node {
    my ($self, $elmnt) = @_;
    if ($elmnt =~ /^<\/($EndTagCE)/o) {
        $self->_handle_element_node_end($1);
    }
    elsif ($elmnt =~ /($ElemTagCE)>$/o) {
        $self->_handle_element_node_start($1);
    }
}

sub _handle_element_node_start {
    my ($self, $elmnt) = @_;
    # this node is a child of the last opened node (top of stack)
    my $parent = $self->{stack}->[$#{$self->{stack}}];
    my $node = $self->_mk_element_node($elmnt, $parent);

    # last opened node to the top of the stack
    push @{$self->{stack}}, $node;

    # deal with XML style empty tags
    if ($elmnt =~ /\/$/) {
	$node = $self->_handle_element_node_end($elmnt);
    }
    if (defined $node->getAttribute('id')) {
	$self->{document}->setElementById($node->getAttribute("id"), $node);
    }

    return $node;
}

sub _handle_element_node_end {
    my ($self, $elmnt) = @_;

    # node is now closed, pop it off the stack
    pop @{$self->{stack}};

    # parentNode is now at the top of the stack
    return $self->{stack}->[$#{$self->{stack}}];
}

sub _mk_gen_node {
    my ($self, $str, $parent, $type) = @_;
    $parent = $self->{stack}->[$#{$self->{stack}}] unless $parent;
    my $node = XML::DOM::Lite::Node->new({
        nodeType  => $type,
        nodeValue => $str,
    });

    $parent->appendChild($node);
    $node->ownerDocument($self->{document});

    if ($type == DOCUMENT_TYPE_NODE) {
        $node->{nodeName} = '#document-type';
    } elsif ($type == PROCESSING_INSTRUCTION_NODE) {
        $node->{nodeName} = '#processing-instruction';
    } elsif ($type == TEXT_NODE) {
        $node->{nodeName} = '#text';
    } elsif ($type == CDATA_SECTION_NODE) {
        $node->{nodeName} = '#cdata';
    } elsif ($type == COMMENT_NODE) {
        $node->{nodeName} = '#comment';
    }
    return $node;
}

sub _mk_text_node {
    my ($self, $str, $parent) = @_;
    $parent = $self->{stack}->[$#{$self->{stack}}] unless $parent;

    my $node = XML::DOM::Lite::Node->new({
	nodeName  => '#text',
	nodeType  => TEXT_NODE,
	nodeValue => $str,
    });

    $parent->appendChild($node);
    $node->ownerDocument($self->{document});

    return $node;
}

sub _mk_element_node {
    my ($self, $elmnt, $parent) = @_;

    ($tagName, $elmnt) = split(/\s+/, $elmnt, 2);
    $tagName =~ s/\/$//;
    my $attrs = $self->_parse_attributes($elmnt);
    my $node = XML::DOM::Lite::Node->new({
	nodeType   => ELEMENT_NODE,
	attributes => $attrs,
	nodeName   => $tagName,
	tagName    => $tagName,
    });
    $parent->appendChild($node);
    $node->ownerDocument($self->{document});

    return $node;
}

sub _parse_attributes {
    my ($self, $elmnt) = @_;

    my $attrs = XML::DOM::Lite::NodeList->new([ ]);
    return $attrs unless $elmnt;

    while ($elmnt =~ s/$ElemTagCE2//o) {
        push @$attrs, XML::DOM::Lite::Node->new({
            nodeType => ATTRIBUTE_NODE,
            nodeName => $1,
            nodeValue => defined($3) ? $3 : $4,
            ownerDocument => $self->{document}
        });
    }

    return $attrs;
}

1;


__END__


=head1 NAME

Parser - Pure Perl Lite XML Parser

=head1 SYNOPSIS

 use XML::DOM::Lite qw(Parser);
 
 $parser = Parser->new(%options);
 $doc = $parser->parse($xmlstring);
 $doc = $parser->parseFile('/path/to/file.xml');

=head1 DESCRIPTION



=cut
