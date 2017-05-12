# $Id: Clean.pm,v 1.6 2003/09/21 14:04:37 petr Exp $

=head1 NAME

XML::Clean - Ensure, that I<(HTML)> text pass throught an XML parser.

=head1 SYNOPSIS

	use XML::Clean;

	print XML::Clean::clean ("<foo bar>barfoo");
		# <foo>barfoo</foo>
	
	print XML::Clean::clean ("<foo bar>barfoo",1.5);
		# <?xml version="1.5" encoding="ISO-8859-1"?>
		# <foo bar>barfoo</foo> 
	
	print XML::Clean::clean ("bar <foo bar=10> bar",1.6,){root=>"XML_ROOT",encoding=>"ISO-8859-2"} ); 
		# <?xml version="1.6" encoding="ISO-8859-2"?>
		# <XML_ROOT
		# bar <foo bar="10"> bar</foo></XML_ROOT> 

=head1 DESCRIPTION

The ultimate quest of this module is to produce from non-XML text
text, that will will most probably pass throught any XML parser one
could find. 

Basic cleaning is just XML tag matching (for every opening tag there
will be closing tag as well, and they will form a tree structure). 

When you add some extra parameters, you will receive complete XML
text, including XML head and root element (if none were defined in
text, then some will be added).

=head1 FUNCTIONS AND METHODS

=over 4

=item XML::Clean::clean($text, [$version, [%options] ])


Return (almost) XML text, made from input parameter C<$text>.

When C<$version> is false, only match tags, and escapes any unmatched
tags.

When you pass C<$version> parameter, then text is checked for standard
XML head (<!XML VERSION=..>), and depending on options (force_root), some is
added / existing is modified. Also depending on options, text is checked for
root element. VERSION XML head parameter in output text is set to parameter
value you pass.

Options are:

encoding - String to be added as XML encoding attribute in XML header. Defaults
to I<ISO-8859-1>.

force_root - If true, output text will have XML root. Defaults to I<false>.

root - Output text will have that tag as root element. Defaults to
I<xml_root>.

=item clean_file $filename [$version [%options] ] 

Open file called C<$filename>, reads all text from it, pass it to clean
with C<$version> and C<%options>, write output text to file called
C<$filename>.

Die on I/O error.

=back

=head1 BUGS

This module is still under development. Not all XML errors are
corrected with it.

Its otherwise too ineficient and slow:).

=head1 AUTHOR

=for html 
<a href="mailto:petr@kubanek.net">petr@kubanek.net</a>. Send there any complains, comments and so on.

=head1 DISTRIBUTION

=for html
<a href="http://www.kubanek.net/xmlclean">http://www.kubanek.net/xmlclean</a>

=cut

BEGIN {
	$VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
}

use strict;
use warnings;

package 	XML::Clean;
use vars 	qw(@ISA @EXPORT);
require		Exporter;
@ISA	  	=qw(Exporter);

my @stack;

my %escapes = ( "<" => "&lt;", ">" => "&gt;", "&" => "&amp;"  ) ;
my $escapes_keys = "(" . join ( "|",  keys %escapes ) . ")";

# help routine to ensure, that xml attributes for tags are correct.
# It means, they match variable="value" style

sub clean_attr {
	my $attr = shift;
	return "" unless $attr;
	my $ret;
	$ret = "";
	# put to result only well-formed or almost-well formed values
	while ($attr =~ m/((?:\w|_|-)+)\s*=\s*((?:\w|\d|_|-)+|".*?")/g) {
		my $name=$1;
		my $val=$2;
		$val =~ s#(^["']|["']$)##g;
		$ret .= ' '.$name.'="'.$val.'"';
	}
	$ret = $ret."/" if ($attr =~ m#/$#);
	return $ret;
}

# help routine to handle start tags. Check, if they aren't legal XML
# tag (not ending with /), then push them to @stack.

sub handle_start {
	my $element = shift;
	my $attr = shift;

	push @stack, $element unless ($attr =~ m#/$#);

	$attr = clean_attr $attr;

	return "<$element$attr>";
}

# help routine to handel end tags. pop from @stack while it doesn't
# find matching same end tag, write end tag to output, returns

sub handle_end {
	# exit, if empty
	return "" unless @stack;
	my $element = shift;

	my $end_tags = "";
	my @tmp_stack = @stack;
	
	my $end;
	
	do {
		$end = pop @tmp_stack;
		$end_tags .= "</$end>";

	} until ($end eq $element) or ($#tmp_stack == -1); 

	if (not(@tmp_stack) and (($#stack !=0) and ($stack[0] ne $element))) {
		return 1;
	}

	@stack = @tmp_stack;

	return $end_tags;
}

sub handle_text {
	my $element = shift;
	
	# escape our elements
	$element =~ s#$escapes_keys#$escapes{$1}#exg if defined $element;
	
	return $element;
}

sub clean {

	my $text = shift;
	my $version = shift;
	my $options = shift;
	
	my $root = $$options{root};
	my $encoding = $$options{encoding};

	my $output = "";

	$encoding = "ISO-8859-1" unless $encoding;

	if ($version) {
		# first, check for <?xml ?> tag
		if ($text !~ m/^<\?xml[^<>]*\?>\s*(<!\w+[^<>]*>)?\s*<\w+[^<>]*>/s ) {
			$output = "<?xml version=\"$version\" encoding=\"$encoding\"?>\n";
			$text = "<$root>\n". $text if ($root);
		}
	}

	# if there is something in $output, it must be <?xml
	# version..> string

	$text =~ s/^<\?xml[^<>]*\?>\s*(<!\w+[^<>]*>)?\s*//s if defined $text;
	$output = $& unless $output; 

	# if we are asked to produce full-correct text with root as root
	# element, then do it

	if (($version) and ($$options{force_root}) and 
		($text !~ m/<$root[^<>]*>/s)) {
			$text = "<$root>\n". $text;	
	}

	undef @stack;

	if (defined $text) {
 	  while ($text =~ m#^(.*?)<(/?\w+.*?)>(.*)#s) {
	
		my ($bg, $cont, $en) = ($1, $2, $3);
		
		$output .= handle_text ($bg);

		if ($cont =~ /^\w+/s) {
			my ($tag, $attr);
			if ($cont =~ /(\w*?)\s(.*)/s) {
				($tag, $attr) = ($1, " ".$2);
			}
			else {
				($tag, $attr) = ($cont, "");
			}
			$output .= handle_start ($tag, $attr);
		}
	
		elsif ($cont =~ m#^/\w+#s) {
			my ($tag, $attr);
			if ($cont =~ /^\/(\w*?)\s(.*)/s) {
				($tag, $attr) = ($1, " ".$2);
			}
			else {
				($tag, $attr) = ($cont, "");
				$tag =~ s/^\///;
			}
			$output .= handle_end ($tag);
		}

		else {
			$output .= handle_text ("<$cont>");	
		}

		$text = $en;
	  }
	}
	
	$output .= handle_text ($text) if defined $text;
	
	my $x;
	foreach $x (reverse @stack) {
		$output .= "</$x>";
	}

	return $output;
}

sub clean_file {
	my $filename = shift;
	my $version = shift;
	my $options = shift;

	$version = "1.0" unless $version;

	open FILE, "<$filename" or die "Cannot open $filename for reading: $!";

	undef $/;

	my $text = <FILE>;

	close FILE or print "Cannot close $filename after reading from it: $!";

	$text = clean $text, $version, $options;

	open FILE, ">$filename" or die "Cannot open $filename for writing: $!";
	
	print FILE $text;

	close FILE or die "Cannot close $filename after writing to it: $!";
}

1;

