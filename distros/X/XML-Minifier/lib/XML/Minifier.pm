package XML::Minifier;
use 5.010000;
use strict;
use warnings;

our $VERSION = "1.02";

use XML::LibXML; # To be installed from CPAN : sudo cpanm XML::LibXML 
# CPAN rules !

use Exporter 'import';
our @EXPORT = qw(minify);
our @EXPORT_OK = qw(minify);


my %do_not_remove_blanks;
my $we_have_infos_from_dtd;
my %opt = ();
my $doc;
my $tree;
my $root;
my $parser;
my $output;

sub traverse($$);

sub minify($%) {
	my $string = shift;

	%do_not_remove_blanks = ();
	$we_have_infos_from_dtd = 0;


	if(not defined $string) {
		return undef;
	}

	if($string eq "") {
		return "";
	}

	%opt = @_;

	# Reinit output
	$output = "";

	# remove_indent is an alias
	if($opt{remove_indent}) {
		$opt{remove_spaces_line_start} = 1;
	}

	# Accept "aggressive" and "agressive" (for people making typos... like me :D)
	if($opt{agressive}) {
		$opt{aggressive} = 1;
	}

	# Insane is more than destructive (and aggressive) 
	if($opt{insane}) {
		$opt{destructive} = 1;
	}

	# Destructive is more than aggressive
	if($opt{destructive}) {
		$opt{aggressive} = 1;
	}

	# Aggressive but relatively soft 
	if($opt{aggressive}) {
		(defined $opt{remove_empty_text}) or $opt{remove_empty_text} = 1;             # a bit aggressive
		(defined $opt{remove_blanks_start}) or $opt{remove_blanks_start} = 1;         # aggressive
		(defined $opt{remove_blanks_end}) or $opt{remove_blanks_end} = 1;             # aggressive
	}

	# Remove indent and pseudo invisible characters 
	if($opt{destructive}) {
		(defined $opt{remove_spaces_line_start}) or $opt{remove_spaces_line_start} = 1;         # very aggressive
		(defined $opt{remove_spaces_line_end}) or $opt{remove_spaces_line_end} = 1;             # very aggressive
	}

	# Densify text nodes but clearly change your data  
	if($opt{insane}) {
		(defined $opt{remove_spaces_everywhere}) or $opt{remove_spaces_everywhere} = 1;         # very very aggressive
		(defined $opt{remove_cr_lf_everywhere}) or $opt{remove_cr_lf_everywhere} = 1;           # very very aggressive 
	}
	
	# Configurable with expand_entities
	$parser = XML::LibXML->new(expand_entities => $opt{expand_entities});
	$tree = $parser->parse_string($string);
	if($opt{process_xincludes}) {
		$parser->process_xincludes($tree);
	}

	$root = $tree->getDocumentElement;

	# I disable automatic xml declaration as : 
	# - It would be printed too late (after pi and subset) and produce broken output
	# - I want to have full control on it
	$XML::LibXML::skipXMLDeclaration = 1;
	$doc = XML::LibXML::Document->new();

	# Configurable with no_prolog : do not put prolog (a bit aggressive for readers) 
	# version=1.0 encoding=UTF-8 : choose values
        # TODO : standalone ?
	my $version = $opt{version} // "1.0";
	my $encoding = $opt{encoding} // "UTF-8";
	$opt{no_prolog} or $output  .= "<?xml version=\"$version\" encoding=\"$encoding\"?>";

	my $rootnode;


	# Parsing first level 
	foreach my $flc ($tree->childNodes()) {

		if(($flc->nodeType eq XML_DTD_NODE) or ($flc->nodeType eq XML_DOCUMENT_TYPE_NODE)) { # second is synonym but deprecated
			# Configurable with keep_dtd 
			my $str = $flc->toString();
			# alternative : my $internaldtd = $tree->internalSubset(); my $str = $internaldtd->toString();
			$str =~ s/\R*//g;
			$opt{keep_dtd} and $output .= $str;
		
			# XML_ELEMENT_DECL
			# XML_ATTRIBUTE_DECL
			# XML_ENTITY_DECL 
			# XML_NOTATION_DECL

			# I need to manually (yuck) parse the node as XML::LibXML does not provide (wrap) such function
			if($opt{ignore_dtd}) {
				# Do not try to get infos from DTD
			} else {
				foreach my $dc ($flc->childNodes()) {
					if($dc->nodeType == XML_ELEMENT_DECL) {
						$we_have_infos_from_dtd = "We can remove empty text in leafs if not protected by DTD";
						# The .* could appear weak (and match towards other ELEMENTS), but we are working on ONLY ONE <!ELEMENT ... >
						# (because we are in one child node)
						if($dc->toString() =~ /<!ELEMENT\s*(\w+)\s*\(.*#PCDATA.*\).*>/) {
							$do_not_remove_blanks{$1} = "Not ignorable due to DTD declaration !";
						}
					}
				}
			}

			# Some notes : 
			# If I iterate over attributes of the childs of DTD (so ELEMENT, ATTLIST etc..) I get a segfault
			# Probable bug from XML::LibXML similar to https://rt.cpan.org/Public/Bug/Display.html?id=71076

			# If I try to access the content of XML_ENTITY_REF_DECL with getValue I get correct result, but on XML_ELEMENT_DECL I get empty string
			# Seems like there's no function to play with DTD
			# I guess we need to write the perl binding for xmlElementPtr xmlGetDtdElementDesc (xmlDtdPtr dtd, const xmlChar * name)

			# If I try to iterate over childNodes, I never see XML_NOTATION_DECL (why?!)

			# One word about DTD and XML::LibXML : 
			# DTD validation works like a charm of course... 
			# But reading from one xml and set to another with experimental function seems just broken or works very weirdly
			# Segfault when reading big external subset, weird message "can't import dtd" when trying to add DTD...

		} elsif($flc->nodeType eq XML_PI_NODE) {
			# Configurable with keep_pi
			my $str = $flc->toString();
			$opt{keep_pi} and $output .= $str;
		} elsif($flc->nodeType eq XML_COMMENT_NODE) {
			# Configurable with keep_comments
			my $str = $flc->toString();
			$opt{keep_comments} and $output .= $str;
		} elsif($flc->nodeType eq XML_ELEMENT_NODE) { # Actually document node as if we do getDocumentNode
			# "main" tree, only one (parser is protecting us)
			$rootnode = traverse($root, $doc);
			# XML_ATTRIBUTE_NODE
			# XML_TEXT_NODE
			# XML_ENTITY_REF_NODE
			# XML_COMMENT_NODE
			# XML_CDATA_SECTION_NODE

			# Ignore 
			# XML_XINCLUDE_START
			# XML_XINCLUDE_END
			
			# Will stay hidden in any case
			# XML_NAMESPACE_DECL

			# Not Applicable 
			# XML_DOCUMENT_NODE 
			# XML_DOCUMENT_FRAG_NODE
			# XML_HTML_DOCUMENT_NODE
			
			# What is it ?
			# XML_ENTITY_NODE
			
		} else {
			# Should I print these unattended things ?
			# Should it be configurable ?
		}
			
	}
		
	# XML_ELEMENT_NODE            => 1
	# E.G. : <tag></tag> or <tag/>

	# XML_ATTRIBUTE_NODE          => 2
	# E.G. : <tag attribute="value">

	# XML_TEXT_NODE               => 3
	# E.G. : This is a piece of text

	# XML_CDATA_SECTION_NODE      => 4
	# E.G. : <![CDATA[<sender>John Smith</sender>]]>
	# CDATA section (not for parsers)

	# XML_ENTITY_REF_NODE         => 5
	# Entities like &entity;

	# XML_ENTITY_NODE             => 6
	# XML_PI_NODE                 => 7 
	# Processing Instructions like <?xml-stylesheet href="style.css"> 

	# XML_COMMENT_NODE            => 8
	# Comments like <!-- comment -->

	# XML_DOCUMENT_NODE           => 9
	# The document itself

	# XML_DOCUMENT_TYPE_NODE      => 10
	# E.G. : Deprecated, use XML_DOCUMENT_TYPE_NODE

	# XML_DOCUMENT_FRAG_NODE      => 11
	# E.G. : Never read, for use, should be created as element node

	# XML_NOTATION_NODE           => 12
	# E.G. : <!NOTATION GIF SYSTEM "GIF"> seems not working

	# XML_HTML_DOCUMENT_NODE      => 13
	# E.G. : <catalog></catalog>
	# In HTML context, for us, should be treated as a document node

	# XML_DTD_NODE                => 14
	# E.G. : <!DOCTYPE book PUBLIC "blahblah" "http://www.example.com/docbookx.dtd" [

	# XML_ELEMENT_DECL            => 15
	# E.G. : <!ELEMENT element-name EMPTY>

	# XML_ATTRIBUTE_DECL          => 16
	# E.G. : <!ATTLIST image height CDATA #REQUIRED>

	# XML_ENTITY_DECL             => 17
	# E.G. : <!ENTITY Entity2 "<strong>Entity</strong>">

	# XML_NAMESPACE_DECL          => 18
	# E.G. : <catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform"> 

	# XML_XINCLUDE_START          => 19
	# <xi:include href="inc.xml"/> if we process includes

	# XML_XINCLUDE_END            => 20
	# <xi:include href="inc.xml"/> if we process includes

	$doc->setDocumentElement($rootnode);

	$output .= $doc->toString();

	return $output;
}

# Traverse the document
sub traverse($$) {
        my $node = shift;
        my $outnode = shift;


	my $name = $node->getName();
	my $newnode = $doc->createElement($name);

	if($outnode) {
		$outnode->addChild($newnode);
	}

	$outnode = $newnode;

        my @as = $node->attributes ;
        foreach my $a (@as) { 
                $outnode->setAttribute($a->nodeName, $a->value); 
        }

        foreach my $child ($node->childNodes) {
		if($child->nodeType eq XML_TEXT_NODE) {
			my $str = $child->data;

			
			if($do_not_remove_blanks{$child->parentNode->getName()}) {
				# DO NOT REMOVE, PROTECTED BY DTD ELEMENT DECL	
			} else {
				# All these substitutions aim to remove indentation that people tend to put in xml files...
				# ...Or just clean on demand (default behavior keeps these blanks)


				# Blanks are several things like spaces, tabs, lf, cr, vertical space...

				# Configurable with remove_blanks_start : remove extra space/lf/cr at the start of the string
				$opt{remove_blanks_start} and $str =~ s/\A\s*//g;
				# Configurable with remove_blanks_end : remove extra space/lf/cr at the end of the string
				$opt{remove_blanks_end} and $str =~ s/\s*\Z//g;


				# Only CR and LF

				# Configurable with remove_cr_lf_everywhere : remove extra lf/cr everywhere
				$opt{remove_cr_lf_everywhere} and $str =~ s/\R*//g;


				# Spaces are 2 things : space and tabs

				# Configurable with remove_spaces_line_start : remove extra spaces or tabs at the start of each line
				$opt{remove_spaces_line_start} and $str =~ s/^( |\t)*//mg;
				# Configurable with remove_spaces_line_end : remove extra spaces or tabs at the end of each line
				$opt{remove_spaces_line_end} and $str =~ s/( |\t)*$//mg;
				# Configurable with remove_spaces_everywhere : remove extra spaces everywhere
				$opt{remove_spaces_everywhere} and $str =~ s/( |\t)*//g;

				# Configurable with remove_empty_text : remove text nodes that contains only space/lf/cr
				$opt{remove_empty_text} and $str =~ s/\A\s*\Z//g;
			}
			
			# Let me explain, we could have text nodes basically everywhere, and we don't know if whitespaces are ignorable or not. 
			# As we want to minify the xml, we can't just keep all blanks, because it is generally indentation or spaces that could be ignored.
			# Here is the strategy : 
			# A. If we have <name>   </name> we should keep it anyway (unless forced with argument)
			# B. If we have </name>   </person> we should *maybe* remove (in this case parent node contains more than one child node : text node + element node)
			# C. If we have <person>   <name> we should *maybe* remove it (in this case parent node contains more than one child node : text node + element node)
			# D. If we have </person>   <person> we should *maybe* remove it (in this case parent node contains more than one child node : text node + element node)
			# B, C, D : remove... unless explicitely declared in DTD as potential #PCDATA container OR unless it contains something...
			# *something* is a comment (not removed), some other text not empty, some cdata.
			# Imagine </name>   <!-- comment --> some text </person> then we don't want to remove spaces in the first text node
			# Same with </name>   <!-- comment -->   </person>
			# But if comments are removed then the latter piece of code will become </name></person>

			my $empty = 1;
			
			my $childbak = $child;
			my @siblings = ();
			# We want to inspect siblings to the right until we reach an element
			while($child = $child->nextSibling) {
				if($child->nodeType eq XML_ELEMENT_NODE) {
					last;
				}
				push @siblings, $child;
			}
			$child = $childbak;
			# We inspect to the left also
			while($child = $child->previousSibling) {
				if($child->nodeType eq XML_ELEMENT_NODE) {
					last;
				}
				push @siblings, $child;
			}

			# Then we will look at each siling to check
			# If it is an empty text node or not
			# If it is something that will be removed or not
			foreach my $child (@siblings) {
				if($child->nodeType eq XML_TEXT_NODE) {
					if($child->data =~ m/[^ \t\r\n]/) {
						# Not empty
						$empty = 0;
						last;
					}
				}
				if($child->nodeType eq XML_COMMENT_NODE and $opt{keep_comments}) {
					$empty = 0;
					last;
				}
				if($child->nodeType eq XML_CDATA_SECTION_NODE and $opt{keep_cdata}) {
					$empty = 0;
					last;
				}
				if($child->nodeType eq XML_PI_NODE and $opt{keep_pi}) {
					$empty = 0;
					last;
				}
				# Entity refs : we can choose to expand or not... but not to drop them
				if($child->nodeType eq XML_ENTITY_REF_NODE) {
					$empty = 0;
					last;
				}
			}


			$child = $childbak;

			# Were all siblings empty ? 
			# Are we alone ? (count child nodes from parent instead of filtered siblings)
			# If there is a DTD, probably we can remove even in the leafs (I'm not doing this at the moment) 
			if($we_have_infos_from_dtd) {
				# Only trust DTD, no need to consider if we are in a leaf or node
				if($do_not_remove_blanks{$child->parentNode->getName()}) {
					# DO NOT REMOVE, PROTECTED BY DTD ELEMENT DECL	
				} else {
					$str =~ s/\A\R*\Z//mg;
					$str =~ s/\A\s*\Z//mg;
				}
			} elsif($empty and @{$child->parentNode->childNodes()} > 1) {
				# Should it be configurable ? 
				if($do_not_remove_blanks{$child->parentNode->getName()}) {
					# DO NOT REMOVE, PROTECTED BY DTD ELEMENT DECL	
				} else {
					$str =~ s/\A\R*\Z//mg;
					$str =~ s/\A\s*\Z//mg;
				}
			}
			$outnode->appendText($str);
		} elsif($child->nodeType eq XML_ENTITY_REF_NODE) {
			# Configuration will be done above when creating document
			my $er = $doc->createEntityReference($child->getName());
			$outnode->addChild($er); 
		} elsif($child->nodeType eq XML_COMMENT_NODE) {
			# Configurable with keep_comments
			my $com = $doc->createComment($child->getData());
			$opt{keep_comments} and $outnode->addChild($com); 
		} elsif($child->nodeType eq XML_CDATA_SECTION_NODE) {
			# Configurable with keep_cdata
			#my $cdata = $child->cloneNode(1);
			my $cdata = $doc->createCDATASection($child->getData());
			$opt{keep_cdata} and $outnode->addChild($cdata);
		} elsif($child->nodeType eq XML_PI_NODE) {
			# Configurable with keep_pi
			#my $pi = $child->cloneNode(1);
			my $pi = $doc->createPI($child->nodeName, $child->getData());
			$opt{keep_pi} and $outnode->addChild($pi);
		} elsif($child->nodeType eq XML_ELEMENT_NODE) {
			$outnode->addChild(traverse($child, $outnode)); 
		}
	} 
	return $outnode;
}


1;

__END__

=encoding utf-8

=head1 NAME

XML::Minifier - A configurable XML minifier.

=head1 WARNING

The API (option names) is almost stabilized (but not fully) and can therefore still change a bit.

=head1 SYNOPSIS

Here is the simplest way to use XML::Minifier :

    use XML::Minifier;

    my $maxi = "<person>   <name>tib   </name>   <level>  42  </level>  <city>   </city>  </person>";
    my $mini = minify($maxi);

But a typical use would include some parameters like this :

    use XML::Minifier qw(minify);

    my $maxi = "<person>   <name>tib   </name>   <level>  42  </level>  <city>   </city>  </person>";
    my $mini = minify($maxi, no_prolog => 1, aggressive => 1);

That will produce :

    <person><name>tib</name><level>42</level><city/></person>

B<aggressive>, B<destructive> and B<insane> are shortcuts that define a set of parameters. 

You can set indivually with :

    use XML::Minifier qw(minify);

    my $maxi = "<person>   <name>tib   </name>   <level>  42  </level>  <city>   </city>  </person>";
    my $mini = minify($maxi, no_prolog => 1, aggressive => 1, keep_comments => 1, remove_indent => 1);

The code above means "minify this string with aggressive mode BUT keep comments and in addition remove indent".

Not every parameter has a B<keep_> neither a B<remove_>, please see below for detailed list.

=head2 DEFAULT MINIFICATION

The minifier has a predefined set of options enabled by default. 

They were decided by the author as relevant but you can disable individually with B<keep_> options.

=over 4

=item Merge elements when empty

=item Remove DTD (configurable).

=item Remove processing instructions (configurable)

=item Remove comments (configurable).

=item Remove CDATA (configurable).

=back

In addition, the minifier will drop every blanks between the first level children. 
What you can find between first level children is not supposed to be meaningful data then we we can safely remove formatting here. 
For instance we can remove a carriage return between prolog and a processing instruction (or even inside a DTD).

In addition again, the minifier will I<smartly> remove blanks between tags. By I<smart> I mean that it will not remove blanks if we are in a leaf (more chances to be meaningful blanks) or if the node contains something that will persist (a I<not removed> comment/cdata/PI, or a piece of text not empty). The meaningfulness of blanks can be given by a DTD. Then if a DTD is present and *protects some nodes*, we oviously respect this. But you can decide to change this behaviour with **ignore_dtd** option.

If there is no DTD (very often), we are blind and simply use the approach I just described above (keep blanks in leafs, remove blanks in nodes if all siblings contains only blanks).


Everything listed above is the default and should be perceived as almost lossyless minification in term of semantic (for humans). 

It's not completely if you consider these things as data, but in this case you simply can't minify as you can't touch anything ;)


=head2 EXTRA MINIFICATION

In addition, you could enable mode B<aggressive>, B<destructive> or B<insane> to remove characters in the text nodes (sort of "cleaning") : 

=head3 Aggressive

=over 4

=item Remove empty text nodes.

=item Remove starting blanks (carriage return, line feed, spaces...).

=item Remove ending blanks (carriage return, line feed, spaces...).

=back

=head3 Destructive

=over 4

=item Remove indentation.

=item Remove invisible spaces and tabs at the end of line.

=back 

=head3 Insane

=over 4

=item Remove carriage returns and line feed into text nodes everywhere.

=item Remove spaces into text nodes everywhere.

=back 

=head2 OPTIONS

You can give various options:

=over 4

=item B<expand_entities>

Expand entities. An entity is like 
    
    &foo; 

=item B<process_xincludes>

Process the xincludes. An xinclude is like 
    
    <xi:include href="inc.xml"/>

=item B<remove_blanks_start>

Remove blanks (spaces, carriage return, line feed...) in front of text nodes. 

For instance 

    <tag>    foo bar</tag> 

will become 

    <tag>foo bar</tag>

It is aggressive and therefore lossy compression.

=item B<remove_blanks_end>

Remove blanks (spaces, carriage return, line feed...) at the end of text nodes. 

For instance 

    <tag>foo bar    
       </tag> 

will become 

    <tag>foo bar</tag>

It is aggressive and therefore lossy compression.

=item B<remove_spaces_line_start> or B<remove_indent>

Remove spaces and tabs at the start of each line in text nodes. 
It's like removing indentation actually.

For instance 

    <tag>
           foo 
           bar    
       </tag> 

will become 

    <tag>
    foo 
    bar
    </tag>

=item B<remove_spaces_line_end>

Remove spaces and tabs at the end of each line in text nodes.
It's like removing invisible things.

=item B<remove_empty_text>

Remove (pseudo) empty text nodes (containing only spaces, carriage return, line feed...). 

For instance 
  
    <tag>

    </tag>

will become 

    <tag/>

=item B<remove_cr_lf_everywhere>

Remove carriage returns and line feed everywhere (inside text !). 

For instance 

    <tag>foo
    bar
    </tag> 

will become 

    <tag>foobar</tag>

It is aggressive and therefore lossy compression.

=item B<keep_comments>

Keep comments, by default they are removed. 

A comment is something like :

    <!-- comment -->

=item B<keep_cdata>

Keep cdata, by default they are removed. 

A CDATA is something like : 

    <![CDATA[ my cdata ]]>

=item B<keep_pi>

Keep processing instructions. 

A processing instruction is something like :

    <?xml-stylesheet href="style.css"/>

=item B<keep_dtd>

Keep DTD.

=item B<ignore_dtd>

When set, the minifier will ignore informations from the DTD (typically where blanks are meaningfull)

This option can be used with B<keep_dtd>, you can decide to get informations from DTD then remove it (or the contrary).

Then I must repeat that B<ignore_dtd> is NOT the contrary of B<keep_dtd>

=item B<no_prolog>

Do not put prolog (having no prolog is aggressive for XML readers).

Prolog is at the start of the XML file and look like this :

    <?xml version="1.0" encoding="UTF-8"?>

=item B<version>

Specify version.

=item B<encoding>

Specify encoding.

=item B<aggressive>

Enable B<aggressive> mode. Enables options B<remove_blanks_starts>, B<remove_blanks_end> and B<remove_empty_text> if they are not defined only.
Other options still keep their value.

=item B<destructive>

Enable B<destructive> mode. Enable options B<remove_spaces_line_starts> and B<remove_spaces_line_end> if they are not defined only.
Enable also B<aggressive> mode.
Other options still keep their value.

=item B<insane>

Enable B<insane> mode. Enables options B<remove_cr_lf_everywhere> and B<remove_spaces_everywhere> if they are not defined only.
Enable also B<destructive> mode and B<aggressive> mode.
Other options still keep their value.

=back 

=head1 LICENSE

Copyright (C) Thibault DUPONCHELLE.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Thibault DUPONCHELLE

=cut

