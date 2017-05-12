package Text::TEI::Markup;

use strict;
use vars qw( $VERSION @EXPORT_OK );
use Encode;
use Exporter 'import';
use XML::LibXML;

use utf8;

$VERSION = '1.9';
@EXPORT_OK = qw( &to_xml &word_tag_wrap );

=head1 NAME

Text::TEI::Markup - a transcription markup syntax for TEI XML

=head1 SYNOPSIS

 use Text::TEI::Markup qw( to_xml );
 my $xml_string = to_xml( file => $markup_file, 
	template => $template_xml_string,
	%opts );  # see below for available options

 use Text::TEI::Markup qw( word_tag_wrap );
 my $word_wrapped_xml = word_tag_wrap( $tei_xml_string );

=head1 DESCRIPTION

TEI XML is a wonderful thing. The elements defined therein allow a
transcriber to record and represent just about any feature of a text that
he or she encounters.

The problem is the transcription itself. When I am transcribing a
manuscript, especially if that manuscript is in a bunch of funny characters
on the keymap for another language, I do not want to be switching back and
forth between keyboard layouts in order to type "<tag attr="attr>"
arrow-arrow-arrow-arrow-arrow "</tag> every six seconds. It's prone to
typo, it's astonishingly slow, and it makes my wrists hurt just to think
about it. I also don't really want to fire up an XML editor, select the
words or characters that need to be tagged, and click a lot. That way is
not prone to typo, but it's still pretty darn slow, and it makes my wrists
hurt B<even more> to think about.

Text::TEI::Markup is my solution to that problem. It defines a bunch of
single- or double-character sigils that represent tags. These are a lot
faster and easier to type; I don't have to worry about typos; and I can do
it all with a plain text editor, thus minimizing use of the mouse.

I have tried to pick sigils that don't conflict with characters that are
found in manuscripts. I have succeeded for my particular set of
manuscripts, but I have not succeeded for the general case. If you like the
idea behind this module, you are still almost guaranteed to hate the sigils
I've picked. That's okay; you can re-define them.

=head2 Extra bonus solution: word wrapping with <w/> and <seg/>

Even if you are happy as a clam in the graphical XML editor of your choice,
this module exports a function that may be useful to you. The TEI P5
guidelines include a module called "analysis", which allows the user to tag
sentences, clauses, words, morphemes, or any other sort of semantic segment
of a text. This is really good for programmatic applications, but very
boring and repetitive to have to tag.

The function B<word_tag_wrap> solves part of this problem for you. It takes
an XML string as input, looks for words (defined by whitespace separation)
and returns an XML string with each of these words wrapped in an
appropriate tag. If the word has complex elements (e.g. editorial
expansion), it will be wrapped in a <seg type="word/> tag. If not, it will
be in a simple <w/> tag. It handles line breaks and page breaks within
words, as long as there is no trailing whitespace before the <lb/> (or
<pb/>) tag, and as long as the whitespace after the tag contains a carriage
return.

=head1 MARKUP SYNTAX

The input file has a header and a body. The header begins with a '=HEAD'
tag, and consists of a colon-separated list of key_value pairs. These keys,
which are case insensitive, get directly substituted into an XML template;
the idea is that your TEI header won't change very much between files, so
you write it once with template values, pass it to &to_xml, and the
substitution happens as if by magic. The keyword /MAIN/i is reserved for
the content between the <body></body> tags - that is, all the content that
will be generated after the '=BODY' tag.

A very simple template looks like this:

 <?xml version="1.0" encoding="UTF-8">
 <TEI>
   <teiHeader>
	 <fileDesc>
	   <titleStmt>
		 <title>__TITLE__</title>
		 <author__AUTHOR__</author>
		 <respStmt xml:id="#__MYINITIALS__">
		   <resp>Transcription by</resp>
		   <name>__MYNAME__</name>
		 </respStmt>
	   </titleStmt>
	 </fileDesc>
   </teiHeader>
   <text>
	 <body>
	 __MAIN__
	 </body>
   </text>
 </TEI>

Your input file should then begin something like this:

 =HEAD
 title:My Summer Vacation: a novel
 author:John Smith
 myinitials:tla
 myname:Tara L Andrews
 =BODY
 The ^real^ text b\e\gins +(above)t+here.
 ...


The real work begins after the '=BODY' tag.	 The currently-defined sigil
list is:

 %SIGILS = ( 
	'comment' => '##',
	'add' => '+',
	'del' => '-',
	'subst' => "\x{b1}",	# Unicode PLUS-MINUS SIGN
	'div' => "\x{a7}",		# Unicode SECTION SIGN
	'p' => "\x{b6}",		# Unicode PILCROW SIGN
	'ex' => '\\',
	'expan' => '^',
	'supplied' => '@',
	'abbr' => [ '{', '}' ],
	'num' => '%',
	'pb' => [ '[', ']' ],
	'cb' => '|',
	'hi' => '*',
	'unclear' => '?',
	'q' => "\x{2020}",		# Unicode DAGGER
	);

Non-identical matched sets of sigla (e.g. '{}' for abbreviations) should be
specified in a listref, as seen here.

Whitespace is only significant at the end of lines. If a line which
contains non-tag text (i.e. words) ends in whitespace, it is assumed that
the previous word is a complete word. If the line ends with a
non-whitespace character, it is assume that the word continues onto the
next line.

All the sigils must be balanced, and they must nest properly. Remember that
this is a shorthand for XML. I could be convinced to try to autocorrect
some unbalanced sigils, but it would be worth at least a few pints of cider
(or, of course, a patch.)

=head2 Tag arguments

Certain of the tags can be passed extra arguments:

=over 4 

=item C<add / del>

Anything that appears in parentheses immediately after the add/del opening
sigil ( + or - in the examples above) will get added as an attribute. If
the string in parentheses has no '=' sign in it, the attribute for the
"add" tag will be "place", and the attribute for the "del" tag will be
"type". Ergo:

 +(margin)This is an addition+
 -(overwrite)and a deletion- to the sentence.

will get translated to

 <add place="margin">This is an addition</add> 
 <del type="overwrite">and a deletion</del> to the sentence.

This behavior ought to be more configurable and/or flexible; make it worth
my while.

=item C<num>

A number value can calculated using a number_conversion function, or it can
simply be specified. It is also possible to specify the type of number being 
represented (B<card>inal, B<ord>inal, B<frac>tion, B<perc>entage). The arguments 
are separated with a comma, and in the order "value", "type". So for example:

 The lead was taken by the Exeter %(8)VIII%. This was their 
 %(13,ord)thirteenth% straight win.

will become:

 The lead was taken by the Exeter <num value="8">VIII</num>. This was their 
 <num value="13" type="ordinal">thirteenth</num> straight win.

=item C<hi>

When text highlighting is encoded, it is almost always a good idea to say 
something about how the highlight was rendered. This information can be passed 
as an argument:

 *(red)IN the beginning* was the word
 
will become

 <hi rend="red">IN the beginning</hi> was the word
 
=back

=head1 SUBROUTINES

=over 4

=item B<to_xml>( file => '$filename', %opts );

Takes the name of a file that holds a marked-up version of text. Returns a
TEI XML string to represent that text. Options include:

=over 4

=item C<template>

a string containing the XML template that you want to use for the markup.
If none is specified, there is a default. That default is useful for me,
but is very unlikely to be useful for you. =item C<fileopen_mode>

a mode string to pass to the open() call on the file. Default "<:utf8".

=item C<number_conversion>

a subroutine ref that will calculate the value of number representations.
Useful for, e.g., Latin numerals. This is optional - if nothing is passed,
no number value calculation will be attempted. =item C<sigils>

a hashref containing the preferred sigil representations of TEI tags.
Defaults to the list above. 

=item C<wrap_words>

Defaults to "true". If you pass a false value, the word wrapping will be
skipped. 

=item C<format>

Defaults to 0. Controls whether rudimentary formatting is applied to the
XML returned. Possible values are 0, 1, and "more than 1". See
XML::LibXML::Document::serialize for more information. (Personally I just
xmllint it separately.)

=back

The return string is run through the basic formatting mechanism provided by
XML::LibXML. You may wish to pass it through a pretty printer more to your
taste. 

=cut

# Default list of funky signs I use.
# TODO: Add header support
my %SIGILS = ( 
	'comment' => '##',
	'add' => '+',
	'del' => '-',
	'subst' => "\x{b1}",
	'div' => "\x{a7}",
	'p' => "\x{b6}",
	'ex' => '\\',
	'expan' => '^',
	'supplied' => '@',
	'abbr' => [ '{', '}' ],
	'num' => '%',
	'pb' => [ '[', ']' ],
	'cb' => '|',
	'hi' => '*',
	'unclear' => '?',
	'q' => "\x{2020}",
	);
	
my @DTL = <DATA>;
my $DEFAULT_TEMPLATE = join( '', @DTL );

sub to_xml {
	my %opts = (
		'number_conversion' => undef,
		'fileopen_mode' => '<:utf8',
		'wrap_words' => 1,
		'sigils' => \%SIGILS,
		'template' => undef,
		'format' => 0,
		@_,
	);

	unless( defined( $opts{'file'} ) ) {
		warn "No file specified!  Doing nothing.";
		return undef;
	}

	if( defined $opts{'number_conversion'} 
		&& ref( $opts{'number_conversion'} ) ne 'CODE' ) {
		warn "number_conversion argument must be a subroutine ref";
		$opts{'number_conversion'} = undef;
	}

	my $inbody;
	 
	my $rc = open( FILE, $opts{'fileopen_mode'}, $opts{'file'} );
	unless( $rc ) {
		warn "Could not open $opts{'file'}: $@";
		return undef;
	}

	my $tmpl;
	if( defined $opts{'template'} ) {
		$tmpl = $opts{'template'};
	} else {
		$tmpl = $DEFAULT_TEMPLATE;
	}

	my $main_xml;

	my( $in_p, $in_div ) = ( undef, undef );
	while(<FILE>) {
		s/\R+$//g; # chomp, no matter the newline char
		next if /^\s*$/;
		s/^\s*//; # but keep trailing spaces - they're significant!
		_current_context( $_ );
		
		if( /^=BODY/ ) {
			$inbody = 1;
			# Have we found a responsible person?
			unless( exists $opts{'resp'} ) {
				warn "No responsible person specified for edits!";
			}
			next;
		}
		
		if( /^(\w+)\s*:\s*(.*)$/ ) {
			# Make the header template substitution.
			_make_warning( "We are in the BODY section but this looks like a header" )
				if $inbody;
			my( $key, $val ) = ( lc( $1 ), $2 );
			$val =~ s/\s+$//;
			if( $key eq 'main' ) {
				warn "You cannot use '$key' as a substitution key!";
			} else {
				$tmpl =~ s/__${key}__/$val/gi;
			}
			if( $key eq 'transcriberid' ) {
				$opts{'resp'} = '#' . $val;
			}
		}
		
		if( $inbody ) {
			# Send it to the parser.
			my $line;
			## TODO: Upgrade to perl 5.10 to get state variables.
			( $line, $in_div, $in_p ) = _process_line( $_, $in_div, $in_p, %opts );
			$main_xml .= $line;
		}
	}
	close FILE;

	$tmpl =~ s/__MAIN__/$main_xml/;
	if( $opts{'wrap_words'} ) {
		$tmpl = word_tag_wrap( $tmpl, $opts{'format'} );
	} else {
		# Just make sure it parses, and format it if asked.
		my $parser = XML::LibXML->new();
		my $doc;
		my $ok = eval{ $doc = $parser->parse_string( $tmpl ); };
		unless( $ok ) {
		   warn "Parsing of the new XML doc failed: $@";
		   return undef;
		}
		$tmpl = decode( $doc->encoding, $doc->serialize( $opts{'format'} ) );
	}
	return $tmpl;
}

sub _process_line {
	my( $line, $in_div, $in_p, %opts ) = @_;
	chomp $line;	
	my $checkline = $line; # This should be well-formed by the end
	my $clopts = { %opts, 'nowarn' => 1 };
	# Look for paragraph and div markers, i.e. our tags that can span multiple lines
	# and that should be disregarded in the checkline. 
	my $sigils = $opts{'sigils'};
	my( $divsig, $pgsig ) = ( $sigils->{'div'}, $sigils->{'p'} );
	while( $line =~ /\Q$divsig\E(\d*)/g ) {	  
		my $divno = $1;
		# Calculate the starting position.
		my $pos = pos( $line ) - 1;
		$pos -= length( $divno ) if $divno;
		
		if( $in_div ) {
			_make_warning( "Nonsensical division number at end-division tag; are your '$divsig' tags balanced?" )
				if $divno;
			substr( $line, $pos, 1, '</div>' );
		} else {
			my $divstr = '<div' . ( $divno ? " n=\"$divno\"" : '' ) . ">";
			substr( $line, $pos, pos( $line ) - $pos, $divstr );
		}
		$in_div = !$in_div;
	}
	$checkline =~ s/\Q$divsig\E//g;
			
	while( $line =~ /\Q$pgsig\E/g ) {
		my $p_str = '<' . ( $in_p ? '/' : '' ) . 'p>';
		substr( $line, pos( $line ) - 1, 1, $p_str );
		$in_p = !$in_p;
	}
	$checkline =~ s/\Q$pgsig\E//g;
	
	# Add and delete tags.	Do this first so that we do not stomp later
	# instances of the dash (e.g. in XML comments).
	my $add_del_re = qr/([-+])(\(([^\)]+)\))?(.*?)\1/;
	while( $line =~ /$add_del_re/g ) {
		my( $op, $attr, $word ) = ( $1, $3, $4 );
		#  Calculate starting position.
		my $pos = pos( $line ) - ( length( $word ) + 2 );
		#  Also for the checkline.
		$checkline =~ /$add_del_re/g;
		my $cpos = pos( $checkline ) - ( length( $word ) + 2 );
		$pos -= ( length( $attr ) + 2 ) if $attr;
		$cpos -= ( length( $attr ) + 2 ) if $attr;
		# Figure out what the attribute string, if any, should be.
		my $attr_str;
		if( $attr && $attr =~ /\=/ ) {
			$attr_str = $attr;
		} elsif ( $attr ) {
			$attr_str = ( $op eq '+' ? "place" : "type" ) 
				. "=\"$attr\"";
		}
		my $interp_str = '<' . ( $op eq '+' ? 'add' : 'del' )
			. ( $attr_str ? " $attr_str" : '' )
			. ">$word</" . ( $op eq '+' ? 'add' : 'del' ) . '>';
		substr( $line, $pos, pos( $line ) - $pos, $interp_str );
		substr( $checkline, $cpos, pos( $checkline ) - $cpos, $interp_str );
	}

	# All the tags that are not very special cases.
	foreach my $tag ( qw( subst abbr hi ex expan num unclear q supplied ) ) {
		my $tag_sig = $sigils->{$tag};
		my( $tag_open, $tag_close );
		if( ref( $tag_sig ) eq 'ARRAY' ) {
			( $tag_open, $tag_close ) = @$tag_sig;
		} else {
			$tag_open = $tag_close = $tag_sig;
		}
		$line =~ s|\Q$tag_open\E(.*?)\Q$tag_close\E|_open_tag( $tag, $1, \%opts ) . "</$tag>"|ge;
		$checkline =~ s|\Q$tag_open\E(.*?)\Q$tag_close\E|_open_tag( $tag, $1, $clopts ) . "</$tag>"|ge;
	} 

	# Standalone tags that aren't special cases.  Currently only cb.
	foreach my $tag ( qw( cb ) ) {
		my $tag_sig = $sigils->{$tag};	
		$line =~ s|\Q$tag_sig\E|"<$tag/>"|ge;
		$checkline =~ s|\Q$tag_sig\E|"<$tag/>"|ge;
	} 
	
	
	# Page breaks.	Defined by the delimiters, plus an optional
	# page/folio number & recto/verso indicator, on a line by itself.
	# Of course other languages may use other sigils to indicate recto
	# verso, so do not look for 'r' and 'v' specifically.
	my $pb_sig = $sigils->{'pb'};
	my ( $pb_open, $pb_close );
	if( ref( $pb_sig ) eq 'ARRAY' ) {
		( $pb_open, $pb_close ) = @$pb_sig;
	} else {
		$pb_open = $pb_sig;
		$pb_close = $pb_sig;
	}
	$line =~ s|^\Q$pb_open\E(\d+(.)?)\Q$pb_close\E\s*$|<pb n=\"$1\"/>|;
	$checkline =~ s|^\Q$pb_open\E(\d+(.)?)\Q$pb_close\E\s*$|<pb n=\"$1\"/>|;
	
	# XML comments.	 Convert ## text ## to <!-- text -->
	my $com_sig = $sigils->{'comment'};
	my ( $com_open, $com_close );
	if( ref( $com_sig ) eq 'ARRAY' ) {
		( $com_open, $com_close ) = @$com_sig;
	} else {
		$com_open = $com_close = $com_sig;
	}
	$line =~ s|\Q$com_open\E(.*?)\Q$com_close\E|<!--$1-->|g;
	$checkline =~ s|\Q$com_open\E(.*?)\Q$com_close\E|<!--$1-->|g;
	
	# At this point our check-line should be well-balance. Send a warning if not.
	my $parser = XML::LibXML->new();
	my $fragment;
	my $ok = eval{ $fragment = $parser->parse_balanced_chunk( "<TAG>$checkline</TAG>" ); };
	unless( $ok ) {
		_make_warning( "Sigils are not properly nested." );
	}

	# Finally, every line with text outside an XML tag must have a line
	# break.  Any lb tag should be inside a cb, p, or div tag.
	my $testline = $line;
	$testline =~ s/<[^>]*>//g;
	if( $testline =~ /\S/ ) {
		no warnings 'uninitialized';
		$line =~ s!(</p>|</div>|<cb/>)?$!<lb/>$1!;
	}	

	# Return the expanded line.
	return( "$line\n", $in_div, $in_p );
}

sub _open_tag {
	my( $tag, $text, $opts ) = @_;

	my $opened_tag;
	# Does the tag take a parenthesized argument?
	my $arg = '';
	if( $text =~ /^\(([^\)]+)\)(.*)$/ ) {
		( $arg, $text ) = ( $1, $2 );
	}
	if( $tag =~ /^(ex|expan|supplied)$/ ) {
		# It takes a resp agent.
		$opened_tag = '<'. $tag .' resp="' . $opts->{'resp'} . "\">$text";
	} elsif ( $tag eq 'q' ) {
		# Special case - we mean a biblical quote.
		$opened_tag = '<q type="biblical">' . $text;
	} elsif ( $tag eq 'num' ) {
		# Derive the number's value if requested.
		my $nv;
		if( $arg ) {
			my $nt;
			my %ntabbr = ( 
				'ord' => 'ordinal', 
				'card' => 'cardinal', 
				'frac' => 'fraction', 
				'perc' => 'percentage' );
			( $nv, $nt ) = split( /,/, $arg );
			$nt = $ntabbr{$nt} || $nt;
			if( $nt ) {
				$opened_tag = sprintf( '<num value="%s" type="%s">%s', 
					$nv, $nt, $text );
			} else {
				$opened_tag = sprintf( '<num value="%s">%s', $nv, $text );
			}
		} 
		unless( defined $nv ) {
			my $numconvert = $opts->{'number_conversion'};
			if( defined $numconvert ) {
				# Strip any XML markup from the element contents.
				my $parser = XML::LibXML->new();
				my $fragment;
				my $ok = eval{ $fragment = $parser->parse_balanced_chunk( $text ); };
				if( $ok ) {
					$nv = &$numconvert( uc( $fragment->textContent() ) );
				} else {
					_make_warning( "Unbalanced chunk in number tag: $text" )
						unless $opts->{nowarn};
				}
				$opened_tag = sprintf( '<num value="%s">%s', $nv, $text ) 
					if defined $nv;
			}
		}
	} elsif ( $tag eq 'hi' ) {
		unless( $arg ) {
			_make_warning( "What kind of highlighting is this?" )
				unless $opts->{nowarn};
			$arg = 'DEFAULT';
		}
		$arg =~ s/\s+/_/g;
		$opened_tag = sprintf( '<%s rend="%s">%s', $tag, $arg, $text );
	}

	# The default
	$opened_tag = "<$tag>$text" unless $opened_tag;
	return $opened_tag;
}

sub _make_warning {
	my $message = shift;
	my $context = _current_context();
	my $warning = "($.) $context\n\tPossible problem! $message";
	warn $warning;
}


## Utility to keep track of where we are
{
	my $curr_line;
	
	sub _current_context {
		if( @_ ) {
			$curr_line = shift;
		}
		return $curr_line;	
	}
}

=item B<word_tag_wrap>( $xml_string )

Takes a string containing a TEI XML document, and returns that
document with all its words wrapped in <w/> (or <seg/>) tags.  A
"word" is defined as a series of text characters separated by
whitespace.	 A word can have a line break, or even a page break, in
the middle; if this is the case, there I<may not> be any whitespace
between the end of the first word segment and the <lb/> (or <pb/>)
tag.  Conversely, there I<must> be whitespace separating the <lb/> (or
<pb/>) from a complete word.

=cut

sub word_tag_wrap {
	my( $xml, $format ) = @_;

	my $ret;
	my $doc;
	my $root;
	if( !ref( $xml ) ) {
		$ret = 'string';
		my $parser = XML::LibXML->new();
		$doc = $parser->parse_string( $xml );
		$root = $doc->getDocumentElement();
	} elsif( ref( $xml ) eq 'XML::LibXML::Document' ) {
		$ret = 'xml';
		$root = $xml->getDocumentElement();
	} elsif( ref( $xml ) eq 'XML::LibXML::Element' ) {
		$ret = 'xml';
		$root = $xml;
	} else {
		die "Passed argument is neither string, Document, or Element";
	}
		
	my @paragraphs;
	foreach my $t ( $root->getElementsByTagName( 'text' ) ) {
		# Get the paragraphs in this text node; if it is already the same as
		# a paragraph in our list, skip it.
		foreach my $p ( $t->getElementsByTagName( 'p' ) ) {
			next if grep { $_->isSameNode( $p ) } @paragraphs;
			push( @paragraphs, $p );
		}
	}
	foreach my $p ( @paragraphs ) {
		my $new_p = _wrap_children( $p );
		# Remove the final whitespace from the paragraphs
		my $lc = $new_p->lastChild;
		if( ref( $lc ) eq 'XML::LibXML::Text' && $lc->data =~ /^\s+$/ ) {
			$new_p->removeChild( $lc );
		}
		$p->replaceNode( $new_p );
	}
	
	# Annoyingly, we have to decode the encoding that takes place when
	# the string is returned.
	if( $ret eq 'string' ) {
		$format = 0 unless $format;
		return decode( $doc->encoding(), $doc->serialize( $format ) );
	} # else the doc has been modified and we need return nothing.
}

sub _wrap_children {
	my $node = shift;
	my @children = $node->childNodes;

	# Make a new version of the element in question, with its name & attributes
	my $new_node = XML::LibXML::Element->new( $node->nodeName );
	# Set the namespace
	my $docns = $node->namespaceURI;
	$new_node->setNamespace( $docns );
	foreach my $attr ( $node->attributes ) {
		my( $aname, $aval ) = split( /=/, $attr );
		$aname =~ s/\s+//g;
		$aval =~ s/\"//g;
		$new_node->setAttribute( $aname, $aval );
	}
	my $open_word_node = undef;
	foreach my $c ( @children ) {
		# Is it a text node?
		if( ref( $c ) eq 'XML::LibXML::Text' ) {
			# Get the text.
			my $str = $c->textContent;
			# Strip out carriage returns and their surrounding spaces.
			# Carriage returns should only occur after <lb/> elements,
			# and the spaces around them should therefore be insignificant.
			$str =~ s/^\s*\n\s*//gs;
			# If there is nothing at all but a newline + initial spaces,
			# pretend that the node isn't there at all.
			next unless $str;

			# Get the individual words.
			my @words = split( /\s+/, $str );

			# Finish out the last word if we need to.
			if( $open_word_node ) {
				# If there are any words in this text string, the
				# first one should be used to close out the open node.
				# If the first word is empty, it's a space and the
				# word should just be closed.  If there are no words
				# at all, it was just a space.	If the first word was
				# all there is, we haven't encountered a space yet and
				# need to keep the word open.
				if( @words ) {
					my $first = shift @words;
					$open_word_node->appendText( $first ) if $first;
				} else {
					$open_word_node = undef unless @words;
				}
			}

			foreach( @words ) {
				# Skip whitespace "words"
				next unless /\S/;

				# Make a new node for the word
				my $word_node = XML::LibXML::Element->new( 'w' );
				$word_node->setNamespace( $docns );
				$word_node->appendText( $_ );
				$new_node->appendChild( $word_node );
				$new_node->appendText(' ');
				# ...and keep it open until we find a new word or a space
				$open_word_node = $word_node;
			}
			
			# Close the last word node if our text node ends in a space.
			if( $str =~ /\s+$/s ) {
				$open_word_node = undef;
			}
		} else {
			my $wrapped_child;
			if ( ref( $c ) ne 'XML::LibXML::Comment' && $c->textContent ne ''
				 && $c->textContent =~ /\s+/ ) {
				# Recurse on any node that itself contains whitespace-separated text.
				my $new_c = _wrap_children( $c );
				$wrapped_child = ( $c->toString() ne $new_c->toString() );
				$c = $new_c;
			} 
			
			# If there is an open word node, make it a seg and append
			# our result there; if the child has text content but no
			# word children, wrap it in a new seg; otherwise just pass
			# it on through.
			if( $open_word_node ) {
				$open_word_node->setNodeName( 'seg' );
				$open_word_node->setAttribute( 'type', 'word' );
				$open_word_node->appendChild( $c );
			} elsif( ref( $c ) eq 'XML::LibXML::Comment' || $c->textContent eq '' 
				|| $wrapped_child ) {
				$new_node->appendChild( $c );
			} else {
				my $segment_node = XML::LibXML::Element->new( 'seg' );
				$segment_node->setNamespace( $docns );
				$segment_node->setAttribute( 'type', 'word' );
				$segment_node->appendChild( $c );
				$new_node->appendChild( $segment_node );
				$new_node->appendText(' ');
				# Keep it open in case there is not a leading space on the next
				# text node.
				$open_word_node = $segment_node;
			}
		}
	}

	return $new_node;	 
}

1;

=back

=head1 BUGS / TODO

The XML is not currently validated against a schema.  This is mostly
because I have been unable to get RelaxNG validation to work against
certain TEI schemas.

This module is currently in a state that I know to be useful to me.
If it looks like it might be useful to you, but something is bugging
you about it, report it!

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews, L<aurum@cpan.org>


=cut

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader>
	<fileDesc>
	  <titleStmt>
		<title>__TITLE__</title>
		<author>__AUTHOR__</author>
		<respStmt xml:id="__TRANSCRIBERID__">
		  <resp>Transcription by</resp>
		  <name>__TRANSCRIBER__</name>
		</respStmt>
	  </titleStmt>
	  <publicationStmt>
		<p>__PUBLICATIONSTMT__</p>
	  </publicationStmt>
	  <sourceDesc>
		<msDesc>
		  <msIdentifier>
			<settlement>__SETTLEMENT__</settlement>
			<repository>__REPOSITORY__</repository>
			<idno>__IDNO__</idno>
		  </msIdentifier>
		  <p>__PAGES__</p>
		</msDesc>
	  </sourceDesc>
	</fileDesc>
	<encodingDesc>
	  <appInfo>
		<application version="1.0" ident="Text::TEI::Collate">
		  <label>Sigil</label>
		  <ab>__SIGIL__</ab>
		</application>
	  </appInfo>
	</encodingDesc>
  </teiHeader>
  <text>
	<body>
__MAIN__
	</body>
  </text>
</TEI>
