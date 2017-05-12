# XML::LibXML > 1.90 overloads Element
use XML::LibXML ();

{
package # hide
	XML::LibXML::Node;
	use Scalar::Util ();
	use overload ();
	BEGIN {
		my $overloaded = sub {
			my ($m) = @_;
			overload::ov_method(overload::mycan(__PACKAGE__,'('.$m),__PACKAGE__);
		};
		overload->import( '""'   => sub { $_[0]->toString() } )            unless $overloaded->('""');
		overload->import( 'bool' => sub { 1 } )                            unless $overloaded->('bool');
		overload->import( '0+'   => sub { Scalar::Util::refaddr($_[0]) } ) unless $overloaded->('0+');
		overload->import( fallback => 1 );
	}
}
{
package # hide
	XML::LibXML::Element;
	use overload ();
	BEGIN {
		my $overloaded = sub {
			my ($m) = @_;
			overload::ov_method(overload::mycan(__PACKAGE__,'('.$m),__PACKAGE__);
		};
		overload->import( '""'   => sub { $_[0]->toString() } )            unless $overloaded->('""');
		overload->import( fallback => 1 ) if $overloaded->('bool');
		
	}
}
package XML::Declare;

use 5.008008;
use strict;
use warnings;
use Carp;

=head1 NAME

XML::Declare - Create XML documents with declaration style

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

	my $doc = doc {
		element feed => sub {
			attr xmlns => 'http://www.w3.org/2005/Atom';
			comment "generated using XML::Declare v$XML::Declare::VERSION";
			for (1..3) {
				element entry => sub {
					element title     => 'Title', type => 'text';
					element content   => sub {
						attr type => 'text';
						cdata 'Desc';
					};
					element published => '123123-1231-123-123';
					element author => sub {
						element name => 'Mons';
					}
				};
			}
		};
	} '1.0','utf-8';

	print $doc;

	doc { DEFINITIONS } < args to XML::LibXML::Document->new >

	Where DEFINITIONS are
	
	element name => sub { DEFINITIONS }
	or
	element
		name => 'TextContent',
		attr => value,
		attr1 => [qw(more values)];
	
	attr name => values;
	
	text $content;
	
	cdata $content;
	
	comment $content;

=head1 EXPORT

=head2 doc BLOCK [ $version, $charset ];

Create L<XML::LibXML::Document>;

=head2 element $name, sub { ... };

Create L<XML::LibXML::Element> with name C<$name>; everything, called within C<sub { ... }> will be appended as children to this element

=head2 element $name, ATTRS

Create L<XML::LibXML::Element> with name C<$name> and set it's attributes. C<ATTRS> is a pairs of C<key => "value">

=head2 attr $name, $value

Create L<XML::LibXML::Attribute> with name C<$name> and value C<$value>

=head2 text $content

Create L<XML::LibXML::Text> node with content C<$content>

=head2 cdata $content

Create L<XML::LibXML::CDATASection> node with content C<$content>

=head2 comment $content

Create L<XML::LibXML::Comment> node with content C<$content>

=cut


use strict;
use XML::LibXML;

sub import {
	my $caller = caller;
	no strict 'refs';
	*{ $caller . '::doc' }     = \&doc;
	*{ $caller . '::element' } = \&element;
	*{ $caller . '::attr' }    = \&attr;
	*{ $caller . '::text' }    = \&text;
	*{ $caller . '::cdata' }   = \&cdata;
	*{ $caller . '::comment' } = \&comment;
}

{
	our $is_doc;
	our $element;
	sub element ($;$@);
	sub attr (@);
	sub _attr(@) {
			eval {
				$element->setAttribute(@_);
				1;
			} or do {
				( my $e = $@ ) =~ s{ at \S+? line \d+\.\s*$}{};
				croak $e;
			};
	}
	sub text ($);
	sub _text ($) {
			$element->appendChild(XML::LibXML::Text->new(shift));
	}
	sub cdata ($);
	sub _cdata ($) {
			$element->appendChild(XML::LibXML::CDATASection->new(shift));
	}
	sub comment ($);
	sub _comment ($) {
			local $_ = shift;
			m{--}s and croak "'--' (double-hyphen) MUST NOT occur within comments";
			substr($_,-1,1) eq '-' and croak "comment MUST NOT end with a '-' (hyphen)";
			$element->appendChild(XML::LibXML::Comment->new($_));
	}
	
	sub element($;$@) {
			my $name = shift;
			defined $element or
			local *attr = \&_attr and
			local *text = \&_text and
			local *cdata = \&_cdata and
			local *comment = \&_comment;
			my ($code,$text);
			if (@_) {
				if (ref $_[-1] eq 'CODE') {
					$code = pop;
				} else {
					$text = shift;
				}
			}
			my $new;
			{
				#local $element = $doc->createElement($name);
				local $element;
				eval {
					$new = XML::LibXML::Element->new($name);
					$new->setNodeName($name); # Will invoke checks
					1;
				} or do {
					( my $e = $@ ) =~ s{ at \S+? line \d+\.\s*$}{};
					croak $e;
				};
				$new->appendText($text) if defined $text;
				while (my( $attr,$val ) = splice @_, 0, 2) {
					$new->setAttribute($attr, ref $val eq 'ARRAY' ? @$val : $val);
				}
				if ($code) {{
					local $element = $new;
					local $is_doc;
					$code->() if $code;
					#$element->appendChild($_) for @EL;
				}}
				#push @EL,$element;
			}
			if (defined $is_doc) {
				if ( $is_doc > 0 ) {
					$element->appendChild($new);
				} else {
					$element->setDocumentElement($new);
					$is_doc++;
				}
				return;
			} elsif (defined $element) {
				$element->appendChild($new);
				return;
			} else {
				return $new;
			}
		
	}
	
	sub doc (&;$$) {
		my $code = shift;
		my $version = shift || '1.0';
		my $encoding = shift || 'utf-8';
		my $doc = XML::LibXML::Document->new($version, $encoding);
		my $oldwarn = $SIG{__WARN__};
		local $SIG{__WARN__} = sub {
			my $warn = shift;
			substr($warn, rindex($warn, ' at '),-1,'');
			chomp $warn;
			local $SIG{__WARN__} = $oldwarn if defined $oldwarn;
			Carp::carp $warn;
		};
		local $element = $doc;
		no strict 'refs';
		local *attr = \&_attr;
		local *text = \&_text;
		local *cdata = \&_cdata;
		local *comment = \&_comment;
		local $is_doc = 0;
		$code->();
		if ($is_doc == 0) {
			Carp::carp "Empty document";
		}
		elsif ($is_doc > 1) {
			Carp::carp "More than one root element. All except first are ignored";
		}
		$doc;
	}
}


=head1 AUTHOR

Mons Anderson <mons@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1; # End of XML::Declare
