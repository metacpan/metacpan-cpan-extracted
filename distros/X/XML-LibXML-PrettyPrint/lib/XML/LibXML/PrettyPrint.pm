use 5.008001;
use strict;
use warnings;
use utf8;

no warnings qw( once void uninitialized );

use IO::Handle 0 qw();

package XML::LibXML::PrettyPrint;

use constant { FALSE => 0, TRUE => 1 };
use constant { EL_BLOCK => 1, EL_COMPACT => 2, EL_INLINE => 3};

BEGIN
{
	$XML::LibXML::PrettyPrint::AUTHORITY = 'cpan:TOBYINK';
	$XML::LibXML::PrettyPrint::VERSION   = '0.006';
}

use Carp 0 qw(croak carp);
use Scalar::Util 0 qw(blessed refaddr);
use XML::LibXML 1.62 qw(:ns);

use Exporter::Tiny ();

our @ISA         = 'Exporter::Tiny';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(print_xml EL_BLOCK EL_COMPACT EL_INLINE);
our %EXPORT_TAGS = (
	constants => [qw(EL_BLOCK EL_COMPACT EL_INLINE)],
	io        => sub {
		*IO::Handle::print_xml = sub ($$;$) {
			my ($handle, $xml, $indent) = @_;
			unless (blessed($xml)) {
				local $@ = undef;
				eval { $xml = XML::LibXML->new->parse_string($xml); 1; }
					or croak("Could not parse XML: $@");
			}
			$indent = 0 unless defined $indent;
			$handle->print(__PACKAGE__->pretty_print($xml, $indent)->toString);
		};
		return;
	},
);

our $Whitespace = qr/[\x20\t\r\n]/; # @@TODO need to check XML spec

sub new
{
	my ($class, %options) = @_;
	$options{element} = delete $options{elements} unless defined $options{element};
	if (defined $options{indent_string})
	{
		carp("Non-whitespace indent_string supplied")
			unless $options{indent_string} =~ /^$Whitespace*$/ 
	}
	bless \%options, $class;
}

{
	my @compact = qw[area audio base basefont bgsound br button canvas
	                 caption col command dd details dt embed figcaption
	                 frame h1 h2 h3 h4 h5 h6 hr iframe img input isindex
	                 keygen legend li link meta option p param summary td
	                 th title video];
	my @inline  = qw[a abbr b bdi bdo big cite code dfn em font i kbd label
	                 mark meter nobr progress q rp rt ruby s samp small span
	                 strike strong sub sup time tt u var wbr];
	my @block   = qw[address applet article aside blockquote body center
	                 colgroup datalist del dir div fieldset figure footer
	                 form frameset head header hgroup html ins listing map
	                 marquee menu nav noembed noframes noscript object ol
	                 optgroup select section source table tbody tfoot thead
	                 tr track ul dl];
	my @pre     = qw[plaintext output pre script style textarea xmp];
	
	my $rdfa_lit_content = sub
	{
		my ($el) = @_;
		return TRUE
			if ($el->hasAttribute('property') and not $el->hasAttribute('content'));
		return undef;
	};
	
	sub new_for_html
	{
		my ($class, %options) = @_;
		
		return $class->new(
			%options,
			element => {
				block    => [@block],
				compact  => [@compact],
				inline   => [@inline],
				preserves_whitespace => [@pre, $rdfa_lit_content],
				},
			);
	}
}

sub _ensure_self
{
	blessed($_[0]) ? $_[0] : $_[0]->new;
}

sub strip_whitespace
{
	my ($self, $node) = @_;
	$self = $self->_ensure_self;
	
	croak("First parameter must be an XML::LibXML::Node")
		unless blessed($node) && $node->isa('XML::LibXML::Node');
	
	if ($node->nodeName eq '#document')
	{
		return $self->strip_whitespace($node->documentElement);
	}
	elsif ($node->isa('XML::LibXML::Element'))
	{
		if ($self->element_preserves_whitespace($node))
		{
			return 0;
		}
		
		my $node_category = $self->element_category($node);
		
		$node->normalize;
		my @kids = $node->childNodes;
		my $activity = 0;
		
		for (my $i = 0; exists $kids[$i]; $i++)
		{
			my $kid  = $kids[$i];
			
			if ($kid->nodeName eq '#text')
			{
				my $prev = exists $kids[$i-1] ? $kids[$i-1] : undef;
				my $next = exists $kids[$i+1] ? $kids[$i+1] : undef;
				my $data = $kid->data;
				
				if ((defined $prev and $self->element_category($prev)==EL_INLINE)
				or  ($node_category==EL_INLINE and not defined $prev))
					{ $data =~ s/^$Whitespace+/ /; }
				else
					{ $data =~ s/^$Whitespace+//; }

				if ((defined $next and $self->element_category($next)==EL_INLINE)
				or  ($node_category==EL_INLINE and not defined $next))
					{ $data =~ s/$Whitespace+$/ /; }
				else
					{ $data =~ s/$Whitespace+$//; }
				
				$data =~ s/$Whitespace+/ /g;

				$activity++ if length $data ne length $kid->data;
				$node->removeChild($kid) unless length $data;
				$kid->setData($data);
			}
			else
			{
				$activity += $self->strip_whitespace($kid);
			}
		}
		
		return $activity;
	}
	else
	{
		carp(sprintf("Don't know how to handle %s object", ref $node))
			unless $node->nodeName eq '#comment'
			||     $node->isa('XML::LibXML::CDATASection')
			||     $node->isa('XML::LibXML::PI');
		return 0;
	}
}

sub indent
{
	my ($self, $node, $indent_level) = @_;
	$self = $self->_ensure_self;	
	
	$indent_level = 0 unless defined $indent_level;

	$self->indent($node->documentElement, $indent_level)
		if blessed($node) && $node->nodeName eq '#document';

	return unless blessed($node) && $node->isa('XML::LibXML::Element');

	return if $self->element_preserves_whitespace($node);

	my $node_category = $self->element_category($node);

	# EL_COMPACT nodes get treated as inline unless they contain a
	# block descendent.
	if ($node_category==EL_COMPACT)
	{
		$node_category = EL_INLINE;
		my $descs = $node->getElementsByTagName('*');
		DESC: while (my $desc = $descs->shift)
		{
			if ($self->element_category($desc) == EL_BLOCK)
			{
				$node_category = EL_BLOCK;
				last DESC;
			}
		}
	}
	
	if ($node_category==EL_BLOCK)
	{
		my $newline       = $self->new_line;
		my $indent_string = $self->indent_string($indent_level + 1);
		
		my @kids = $node->childNodes;
		$node->removeChildNodes;
		for (my $i = 0; exists $kids[$i]; $i++)
		{
			my $kid  = $kids[$i];
			my $did_indent = FALSE;
			
			if ($i==0)
			{
				$node->appendText($newline . $indent_string);
				$did_indent = TRUE;
			}
			elsif ($self->element_category($kid)==EL_BLOCK)
			{
				$node->appendText($newline . $indent_string);
				$did_indent = TRUE;
			}
			elsif ($self->element_category($kid)==EL_COMPACT)
			{
				$node->appendText($newline . $indent_string);
				$did_indent = TRUE;
			}
			elsif (defined $kids[$i-1])
			{
				my $prev_category = $self->element_category($kids[$i-1]);
				if (defined $prev_category
				and ($prev_category==EL_BLOCK or $prev_category==EL_COMPACT))
				{
					$node->appendText($newline . $indent_string);
					$did_indent = TRUE;
				}
			}
			
			if ($did_indent and $kid->nodeName eq '#text')
			{
				(my $data = $kid->data) =~ s/^ //;
				$kid->setData($data);
			}
			$node->appendChild($kid);
			$self->indent($kid, $indent_level + 1);
		}
		$node->appendText($newline . $self->indent_string($indent_level)) if @kids;
	}
}

sub pretty_print
{
	my ($self, $node, $indent_level) = @_;
	$self = $self->_ensure_self;
	
	$self->strip_whitespace($node);
	$self->indent($node, $indent_level);
	return $node;
}

sub _run_checks
{
	my ($self, $category, $node) = @_;

	return FALSE unless defined $self->{element}{$category};
	
	if (ref $self->{element}{$category} eq 'CODE'
	or !ref $self->{element}{$category})
	{
		$self->{element}{$category} = [$self->{element}{$category}];
	}
	
	if (ref $self->{element}{$category} eq 'ARRAY')
	{
		foreach my $check (@{$self->{element}{$category}})
		{
			if (!ref $check and $check =~ /^\{(.+)\}(.+)$/)
			{
				return TRUE if $node->namespaceURI eq $1 && $node->localname eq $2;
			}
			elsif (!ref $check)
			{
				return TRUE if $check eq $node->nodeName;
			}
			elsif (ref $check eq 'CODE')
			{
				my $return = $check->($node);
				return $return if defined $return;
			}
			else
			{
				carp(sprintf("Check for category '%s' ignored; is of type %s", $category, ref $check));
			}
		}
	}
	
	return FALSE;
}

sub indent_string
{
	my ($self, $level) = @_;
	$self = $self->_ensure_self;
	
	$self->{indent_string} = "\t"
		unless defined $self->{indent_string};
	
	$self->{indent_string} x $level;
}

sub new_line
{
	my ($self, $level) = @_;
	$self = $self->_ensure_self;
	
	$self->{new_line} = "\n"
		unless defined $self->{new_line};
	
	$self->{new_line};
}

sub element_category
{
	my ($self, $node) = @_;
	$self = $self->_ensure_self;

	return undef unless blessed($node);
	
	return EL_BLOCK   if $self->_run_checks(block => $node);
	return EL_COMPACT if $self->_run_checks(compact => $node);
	return EL_INLINE  if $self->_run_checks(inline => $node);

	return EL_BLOCK   if $node->isa('XML::LibXML::Element');
	return EL_COMPACT if $node->nodeName eq '#comment';
	return EL_COMPACT if $node->isa('XML::LibXML::PI');
	
	return undef;
}

sub element_preserves_whitespace
{
	my ($self, $node) = @_;
	$self = $self->_ensure_self;

	return undef unless blessed($node); 
	return TRUE if $node->nodeName eq '#comment';
	return TRUE if $node->isa('XML::LibXML::PI');
	
	return TRUE if $self->_run_checks(preserves_whitespace => $node);
	
	return TRUE
		if $node->isa('XML::LibXML::Element')
		&& $node->hasAttributeNS(XML_XML_NS, 'space')
		&& lc $node->getAttributeNS(XML_XML_NS, 'space') eq 'preserve'; 
	
	return FALSE if $node->isa('XML::LibXML::Element');
	return undef;
}

sub print_xml ($;$)
{
	my ($xml, $indent) = @_;
	unless (blessed($xml))
	{
		local $@ = undef;
		eval { $xml = XML::LibXML->new->parse_string($xml); 1; }
			or croak("Could not parse XML: $@");
	}
	$indent = 0 unless defined $indent;
	print __PACKAGE__->pretty_print($xml, $indent)->toString;
}

TRUE;

__END__

=head1 NAME

XML::LibXML::PrettyPrint - add pleasant whitespace to a DOM tree

=head1 SYNOPSIS

 my $document = XML::LibXML->new->parse_file('in.xml');
 my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
 $pp->pretty_print($document); # modified in-place
 print $document->toString;

=head1 DESCRIPTION

Long XML files can be daunting for humans to read. Of course, XML is really
designed for computers to read - not people - but there are times when mere
mortals do need to read and edit XML by hand. For example, if your
application stores its configuration in XML, or you need to dump some
XML to STDOUT for debugging purposes.

Syntax highlighting helps, but to really make sense of some XML, proper
indentation can be vital. Hence C<< XML::LibXML::PrettyPrint >> - it can
be applied to an L<XML::LibXML> DOM tree to reformat it into a more
readable result.

Pretty-printing XML is not as CPU-efficient as dumping it out sloppily,
so unless you're pretty sure that a human is going to need to make sense
of your XML, you should probably not use this module.

=head2 Constructors

=over

=item C<< new(%options) >>

Constructs a pretty-printer object.

Options:

=over

=item * B<indent_string> - The string to use to indent each line. Defaults to a single tab character. Setting it to a non-whitespace character is allowed, but will carp a warning.

=item * B<new_line> - The string to use to begin a new line. Defaults to "\n".

=item * B<element> - A hashref of element categorisations. Each categorisation is a reference to an array of element names or callback functions. Element names may use Clark notation.

  my $callback = sub {
    my $node = shift;
    return 1 if $node->hasAttribute('is_block');
    return undef;
  };
  my $pp = XML::LibXML::PrettyPrint->new(
      element => {
          inline   => [qw/span strong em b i a/],
          block    => [qw/p div body html head/, $callback],
          compact  => [qw/title caption li dd dt th td/],
          preserves_whitespace => [qw/pre script style/],
          }
      );

Callbacks should return 1 (true), 0 (false) or undef (dunno).

=back

=item C<< new_for_html(%options) >>

Constructs a pretty printer object pre-configured to be suitable for
HTML and XHTML. The B<indent_string> and B<new_line> options are
supported.

=back

=head2 Methods

If you just need to use a default configuration (no options passed to
the constructor, then you can call these as class methods, unless otherwise
stated.

=over

=item C<< strip_whitespace($node) >>

Strips superfluous whitespace from an C<XML::LibXML::Document> or 
C<XML::LibXML::Element>.

Whitespace just before, just after or leading/trailing within an inline
element is not considered superfluous. Runs of multiple whitespace
characters are replaced with a single space. Whitespace is not changed
within an element that preserves whitespace.

The node is modified in place.

=item C<< indent($node, $level) >>

Indents the node to a certain indentation level, and its direct children to
C<< $level + 1 >>, grandchildren to C<< $level + 2 >>, etc. Typically you'd
just want to indent the root node to level 0.

The node is modified in place.

Elements that preserve whitespace are not changed.

=item C<< pretty_print($node, $level) >>

Strip whitespace and indent. The node is modified in place and returned.

Example use as a class method:

 print XML::LibXML::PrettyPrint
   ->pretty_print(XML::LibXML->new->parse_string($XML))
   ->toString;

=item C<< indent_string($level) >>

Returns the string that would be used to indent something to a particular
level. Descendent classes could override this method to do funky indentation,
such as having varying levels of indentation.

=item C<< new_line >>

Returns the string that would be used to begin a new line.

=item C<< element_category($node) >>

Returns EL_INLINE, EL_BLOCK, EL_COMPACT or undef.

=item C<< element_preserves_whitespace($node) >>

Boolean indicating whether the contents of the element have significant
whitespace that needs preserving.

Returns undef if $node is not an C<XML::LibXML::Element>. 

=back

=head2 Functions

=over

=item C<< print_xml $xml >>

Given an XML string or an XML::LibXML::Node object, prints it nicely.

This function is not exported by default, but can be requested:

 use XML::LibXML::PrettyPrint 0.001 qw(print_xml);

Use like this:

 print_xml '<foo> <bar> </bar> </foo>';

=item C<< IO::Handle::print_xml($handle, $xml) >>

Partly experimental, partly mental. You can enable this feature like this:

 use XML::LibXML::PrettyPrint 0.001 qw(-io);

And that will allow stuff like this to work:

 open LOG, '>mylog.xml';
 print_xml LOG '<foo> <bar> </bar> </foo>';
 close LOG;

 open my $log, '>otherlog.xml';
 print_xml $log '<foo> <bar> </bar> </foo>';
 close $log;

 print_xml STDERR '<foo> <bar> </bar> </foo>';

=back

=head2 Constants

These can be exported:

 use XML::LibXML::PrettyPrint 0.001 qw(:constants);

=over

=item C<EL_BLOCK>

=item C<EL_COMPACT>

=item C<EL_INLINE>

=back

=head1 ELEMENT CATEGORIES

There are three categories of element: inline, block and compact.

For inline elements the presence of whitespace (though not the amount
of whitespace) is considered significant just before the element, just
after the element, or just within the element.

In XHTML, consider the difference between the block element C<< <div> >>:

 <div>Will</div><div>Carlton</div> <div>Ashley</div>

and the inline element C<< <span> >>:

 <span>Spider</span>-<span>Man</span> <span>lives</span>

The space or lackthereof between C<< <div> >> elements does not matter one
whit. The lack of spaces between the first two C<< <span> >> elements allows
them to be read as a single (in this case, hyphenated) word, whereas the space
before the third C<< <span> >> separates out the word "lives".

In terms of indentation, inline elements do not start a new indented line,
unless they are the first element within their block, or are preceded by a
block or compact element.

Block elements always start a new line, and cause their child nodes to be
indented to the next level.

Compact elements are somewhere in-between. When it comes to whitespace stripping,
they're treated as block elements. In terms of indentation, they always start
a new line, but they only cause their child nodes to be indented to the next
level if they have block descendents. If we imagine that in HTML, C<< <ul> >>
is a block element, C<< <i> >> is an inline element, and C<< <li> >> is a compact
element:

 <ul>
   <li>Will Smith - Will Smith</li>
   <li>Carlton Banks - Alfonso Ribeiro</li>
   <li>
     Vivian Banks:
     <ul>
       <li>Janet Hubert-Whitten <i>(seasons 1-3)</i></li>
       <li>Daphne Maxwell Reid <i>(seasons 3-6)</i></li>
     </ul>
   </li>
 </ul>

The third C<< <li> >> element is indented like a block element because it contains
a block C<< <ul> >> element. The other C<< <li> >> elements do not have their
contents indented, because they contain only inline content.

Elements default to being block, but you can specify particular elements as
inline or compact by passing node names or callbacks to the constructor. Elements
default to not preserving whitespace unless they have an C<< xml:space="preserve" >>
attribute, but again you can use the constructor to change this.

Comments and processing instructions default to being compact, but you can make
particular comments or PIs inline or block by passing appropriate callbacks to
the constructor. Whitespace within comments and PIs is always preserved. (There
is rarely any reason to make comments and processing instructions block, but
making them inline can occasionally be useful, as it will mean that the presence
of whitespace just before or just after the comment is treated as significant.)

Text nodes are always inline.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=XML-LibXML-PrettyPrint>.

=head1 SEE ALSO

Related: L<XML::LibXML>, L<HTML::HTML5::Writer>.

L<XML::Tidy> - similar, but based on L<XML::XPath>. Doesn't differentiate
between inline and block elements.

L<XML::Filter::Reindent> - similar again, based on L<XML::Parser>. Doesn't
differentiate between inline and block elements.

Sermon: L<http://www.derkarl.org/why_to_tabs.html>. Read it.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

