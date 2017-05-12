package YAX::Parser;

use strict;

use YAX::Node;
use YAX::Text;
use YAX::Element;
use YAX::Fragment;
use YAX::Document;
use YAX::Constants qw/:all/;

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

# these have captures for parsing attributes
our $AttValSE2 = "\"([^<\"]*)\"|'([^<']*)'";
our $ElemTagCE2 = "(?:($Name)(?:$S)?=(?:$S)?(?:$AttValSE2))+(?:$S)?/?>?";

sub new {
    my ( $class ) = @_;
    my $self = bless { }, $class;
    return $self;
}

sub parse {
    my ( $self, $xstr ) = ( shift, shift );
    return unless $xstr;
    my @nodes = $self->tokenize( $xstr );

    my $xdoc  = YAX::Document->new();
    my @stack = ( $xdoc );
    my ( $spec, $elmt );
    foreach my $node ( $self->tokenize( $xstr ) ) {
        $spec = substr( $node, 0, 2 );
        if ( index( $spec, '<' ) != 0 ) {
            $self->_mk_text( $node, $stack[-1] );
            next;
        }
        if ( $spec eq '</' ) {
            pop @stack;
            next;
        }
        if ( $spec eq '<!' ) {
            $self->_mk_decl( $node, $stack[-1] );
            next;
        }
        if ( $spec eq '<?' ) {
            $self->_mk_proc( $node, $stack[-1] );
            next;
        }

        $elmt = $self->_mk_elmt( $node, $stack[-1] );
        push( @stack, $elmt ) unless ( $node =~ m{/>$} );
        $xdoc->set( $elmt->{id} => $elmt ) if $elmt->{id}
    }

    return $xdoc;
}

sub stream {
    my ( $self, $xstr, $state ) = ( shift, shift, shift );
    my %subs;
    if ( @_ == 1 and ref $_[0] eq 'HASH' ) {
        %subs = %{$_[0]};
    } else {
        %subs = @_;
    }

    my $text = delete $subs{text} || $subs{pass};
    my $decl = delete $subs{decl} || $subs{pass};
    my $proc = delete $subs{proc} || $subs{pass};
    my $elmt = delete $subs{elmt} || $subs{pass};
    my $elcl = delete $subs{elcl} || $subs{pass};

    my ( $spec, $name, $copy, $atts, %atts );
    foreach my $node ( $self->tokenize( $xstr ) ) {
        $spec = substr( $node, 0, 2 );
        if ( index( $spec, '<' ) != 0 ) {
            $text && $text->( $state, $node );
            next;
        }
        if ( $spec eq '</' ) {
            $elcl && $elcl->( $state, substr( $node, 2, -1 ) );
            next;
        }
        if ( $spec eq '<!' ) {
            $decl && $decl->( $state, $node );
            next;
        }
        if ( $spec eq '<?' ) {
            $proc && $proc->( $state, $node );
            next;
        }

        $elmt && do {
            $copy = substr( $node, 1, -1 );
            ( $name, $atts ) = split( /\s+/, $copy, 2 );
            $name =~ s{/$}{};
            %atts = $atts ? $self->parse_attributes( $atts ) : ( );
            $elmt->( $state, $name, %atts );
        };

        if ( substr( $node, -2 ) eq '/>' ) {
            $elcl && $elcl->( $state, $name );
        }
    }
}

sub read_file {
    my ( $self, $file ) = @_;
    my $xstr;
    {
        open FH, $file or return;
        local $/ = undef;
        $xstr = <FH>;
        close FH;
    }
    return $xstr;
}

sub parse_file {
    my ( $self, $file ) = @_;
    return $self->parse( $self->read_file( $file ) );
}

sub stream_file {
    my ( $self, $file, $state, %subs ) = @_;
    return $self->stream( $self->read_file( $file ), $state, %subs );
}

sub parse_as_fragment {
    my ( $self, $xstr ) = @_;
    my $xdoc = $self->parse( '<yax:frag>'.$xstr.'</yax:frag>' );
    my $root = $xdoc->root;
    my $frag = YAX::Fragment->new;
    $frag->append( $root->[0] ) while @$root;
    return $frag;
}

sub parse_file_as_fragment {
    my ( $self, $file ) = @_;
    my $xstr = $self->read_file( $file );
    my $frag = $self->parse_as_fragment( $xstr );
    return $frag;
}

sub tokenize { 
    my ( $self, $xstr ) = @_;
    return $xstr =~ /$XML_SPE/g;
}

sub _mk_decl {
    my ( $self, $decl, $parent ) = @_;
    my ( $type, $name );
    my $offset = 1;
    my $length = length( $decl );

    substr( $decl, 0, 4 ) eq '<!--' && do {
	$offset = 4;
	$length = $length - $offset - 3;
	$type   = COMMENT_NODE;
        $name   = '#comment';
    };
    substr( $decl, 0, 9 ) eq '<![CDATA[' && do {
	$offset = 9;
	$length = $length - $offset - 3;
	$type   = CDATA_SECTION_NODE;
        $name   = '#cdata';
    };
    substr( $decl, 0, 9 ) eq '<!DOCTYPE' && do {
	$offset = 10;
	$length = $length - $offset - 3;
        $type   = DOCUMENT_TYPE_NODE;
        $name   = "#document-type";
    };
    return $self->_mk_node(
        $name, $type, substr( $decl, $offset, $length ), $parent
    );
}

sub _mk_proc {
    my ( $self, $text, $parent ) = @_;
    my ( $name, $data ) = ( $text =~ /^<\?([a-zA-Z0-9_-]+?)\s+(.*?)\s*\?>/ );
    return $self->_mk_node(
        $name, PROCESSING_INSTRUCTION_NODE, $data, $parent
    );
}

sub _mk_node {
    my ( $self, $name, $type, $data, $parent ) = @_;

    my $node = YAX::Node->new( $name, $type, $data );
    push @$parent, $node;
    $node->parent( $parent );

    return $node;
}

sub _mk_text {
    my ( $self, $text, $parent ) = @_;

    my $node = YAX::Text->new( $text );
    push @$parent, $node;
    $node->parent( $parent );

    return $node;
}

sub _mk_elmt {
    my ( $self, $elmt, $parent ) = @_;
    my $copy = substr( $elmt, 1, -1 );
    my ( $name, $atts ) = split(/\s+/, $copy, 2);

    $name =~ s/\/$//;

    my %atts = $atts ? $self->parse_attributes( $atts ) : ( );
    my $node = YAX::Element->new( $name, %atts );

    push @$parent, $node;
    $node->parent( $parent );

    return $node;
}

sub parse_attributes {
    my ( $self, $atts ) = @_;
    my %atts = ( );
    while ( $atts =~ /$ElemTagCE2/g ) {
        $atts{ $1 } = defined $2 ? $2 : $3;
    }
    return %atts;
}

1;

__END__

=head1 NAME

YAX::Parser - fast pure Perl tree and stream parser

=head1 SYNOPSIS

 use YAX::Parser;

 my $xml_str = <<XML
   <?xml version="1.0" ?>
   <doc>
     <content id="42"><![CDATA[
        This is a cdata section, so >>anything goes!<<
     ]]>
     </content>
     <!-- comments are nodes too -->
   </doc>
 XML

 # tree parse - the common case
 my $xml_doc = YAX::Parser->parse( $xml_str );
 my $xml_doc = YAX::Parser->parse_file( $path );

 # shallow parse
 my @tokens = YAX::Parser->tokenize( $xml_str );

 # stream parse 
 YAX::Parser->stream( $xml_str, $state, %handlers )
 YAX::Parser->stream_file( '/some/file.xml', $state, %handlers );
 
=head1 DESCRIPTION

This module implements a fast DOM and stream parser based on Robert D. Cameron's
regular expression shallow parsing grammar and technique. It doesn't implement
the full W3C DOM API by design. Instead, it takes a more pragmatic approach. DOM
trees are constructed with everything being an object except for attributes, which
are stored as a hash reference.

We also borrow some ideas from browser implementations, in particular, nodes are
keyed in a table in the document on their C<id> attributes (if present) so you can
say:

 my $found = $xml_doc->get( $node_id );

Parsing is usually done by calling class methods on YAX::Parser, which,
if invoked as a tree parser, returns an instance of L<YAX::Document>

 my $xml_doc = YAX::Parser->parse( $xml_str );

=head1 METHODS

See the L</SYNOPSIS> for, here's just the list for now:

=over 4

=item parse( $xml_str )

Parse $xml_str and return a L<YAX::Document> object.

=item parse_file( $path )

Same as above by read the file at $path for the input.

=item stream( $xml_str, $state, %handlers )

Although not its main focus, YAX::Parser also provides for stream
parsing. It tries to be a bit more sane than Expat, in that it allows
you to specify a state holder which can be anything and is passed as
the first argument to the handler functions. A typical case is to
use a hash reference with a stack (for tracking nesting):

 my $state = { stack => [ ] };

all handler functions are optional, but the full list is:

 my %handlers = (
     text => \&handle_text,          # called for text nodes
     elmt => \&handle_element_open,  # called for open tags
     elcl => \&handle_element_close, # called for tag close
     decl => \&handle_declaration,   # called for declarations
     proc => \&handle_proc_inst,     # called for processing instructions
     pass => \&handle_passthrough,   # called when no handlers match
 );

an element handler is passed the state, tag name and attributes hash:

 sub handle_element_open {
     my ( $state, $name, %attributes ) = @_;
     if ( $name eq 'a' and $attributes{href} ) {
         ... 
     }
 }

element close handlers take two arguments: state and tag name:

 sub handle_element_close {
     my ( $state, $name ) = @_;
     die "not well formed" unless pop @{ $state->{stack} } eq $name;
 }

all other handlers take the state and the entire matched token

 sub handle_proc_inst {
     my ( $state, $token ) = @_;
     $token =~ /^<\?(.*?)\?>$/;
     my $instr = $1;
     ...
 }

=item stream_file( $path, $state, %handlers )

Same as above by read the file at $path for the input.

=item tokenize( $xml_str )

Useful for quick and dirty tokenizing of $xml_str. Returns a list of tokens.

=back

=head1 SEE ALSO

L<YAX::Document>, L<YAX::Node>

=head1 LICENSE

This program is free software and may be modified and distributed under
the same terms as Perl itself.

=head1 AUTHOR

 Richard Hundt

