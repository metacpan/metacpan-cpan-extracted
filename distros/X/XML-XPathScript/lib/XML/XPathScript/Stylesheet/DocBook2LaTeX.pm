package XML::XPathScript::Stylesheet::DocBook2LaTeX;
our $AUTHORITY = 'cpan:YANICK';
$XML::XPathScript::Stylesheet::DocBook2LaTeX::VERSION = '2.00';
# ABSTRACT: Transforms DocBook into LaTeX

use warnings;
use strict;

use XML::XPathScript::Processor;
use Carp;

our $processor;

our $stylesheet = <<'END_STYLESHEET';
<%
    $XML::XPathScript::current->interpolating( 0 );
    $XML::XPathScript::Stylesheet::DocBook2LaTeX::processor = $processor;
    $template->import_template( 
        $XML::XPathScript::Stylesheet::DocBook2LaTeX::template );
%><%~ / %>
END_STYLESHEET

our $numbered_sections = 1;

our $firstpage;

our @documentclass_args = qw/ 11pt twoside a4paper /;
# LaTeX packages in use with their options
our @packages=(
			   ["fontenc" => "T1"],
			   ["inputenc" => "latin1"],
			   "fancybox",
			   "textcomp",  # For \textcurrency
               ["aeguill" => "cyr"],
               "aecompl",
			   "graphicx",
			   "epsfig",
			   "amssymb",
			   "wasysym",
			   "pifont",
			   );
# "longtable" and "multirow" will be \usepackage'd if $fancytables=1, even
# though they don't belong to this list.

# Do we want bells-n'whistles with LaTeX tables ?
our $fancytables = 1;

# Arguments to the opening \documentclass{} macro call
our $documentclass;

# Section hierarchy
our @sectionnames = qw(part chapter section subsection subsubsection paragraph subparagraph);
my @secttypes=qw( part chapter section sect1 sect2 sect3 sect4 sect5
				 preface refentry refsect1 refsect2 refsect3 refsect4
				 refsect5);

our $TeXkludges=<<'KLUDGES';
    \makeatletter
    \let\IDXbacksl\@backslashchar
    \let\IDX@oldtt\texttt
    \def\texttt#1{{%
    \@ifundefined{NoAutoSpaceBeforeFDP}{}{\NoAutoSpaceBeforeFDP}%
    \IDX@oldtt{#1}}}
    \makeatother
KLUDGES


# Hash table for converting Unicode to LaTeX characters or macro sequences.
# The keys are the Unicode character codes
# (http://www.unicode.org/charts/charindex.html). The corresponding values
# are the LaTeX counterpart to use to represent those characters. By
# default, whitespace and Latin1 characters are replaced with
# themselves; unknown characters are replaced with $uniunknown (see below)

our %uniconvs=(
		# Those are Latin1 and have no business here, except that
		# we use them to quote things to protect during the
		# quoting process (elegant hack if I may)
		ord('<') => '{<}', # Also prevents kerning into "«"
		ord('>') => '{>}',

		# TeX's shenanigans
	    ord('µ') => '\ensuremath{µ}',
	    ord('_') => '\_',
	    ord('^') => '{\^\relax}',
	    ord('$') => '\$',
	    ord('%') => '\%',
	    ord('~') => '{\string~}',
	    ord('@') => "{\\string @}",
	    ord('{') => '\{',
	    ord('}') => '\}',
	    ord('#') => '\#',
	    ord('&') => '\&',
	    ord('[') => '{[}',
	    ord(']') => '{]}',
	    ord('\\') => '{\IDXbacksl}',
		ord('-') => '{-}', # Prevents unwanted kerning
		ord("'") => "{'}", # Ditto
		ord("`") => "{`}", # Ditto
		ord(",") => "{,}", # Ditto

        # Extra Unicode characters
		0x0152 => '{\OE}',  # &OElig;
		0x0153 => '{\oe}',  # &oelig;

		0x2009 => '{\,}',   # &thinsp;
		0x2011 => '~',      # &nbsp;
		0x2013 => "{--}",     # &ndash;
		0x2014 => "{---}",    # &mdash;
		0x2026 => '...',    # &hellip; - FIXME : this is OK for french
			                # only, english uses \ldots
		0x2605 => '\ensuremath{\bigstar}',

		0x263a => '\smiley{}', # No ISO entity set, use &#x263A;
		0x2713 => '\ding{51}', # &check;
		0x2717 => '\ding{55}', # &cross;
			  );

# This is the regexp that matches characters that are _not_ invariant
# through utf8totex(). We cache it for efficiency.
our $noninvarchar = RE_of_uniconvs(\%uniconvs);

our $uniunknown= '???';     # replaces unknown unicode chars in output

our $TeXpreamble=<<'PREAMBLE';
    \cornersize*{6pt} % For fancybox
    \setlength{\topmargin}{0.1in}
    \setlength{\oddsidemargin}{0.5cm}
    \setlength{\evensidemargin}{0.5cm}
    \setlength{\textwidth}{6in}
    \setlength{\hoffset}{0cm}
PREAMBLE

our $TeXbegindocument=<<'BEGINDOCUMENT';
\sloppypar
BEGINDOCUMENT

our $maketitle;
our $title;

# Useful as a return value in many templates
our $_doNotProcessTitles=qq'*[name()!="title" and name() != "subtitle" and name() != "titleabbrev"]';


our @tablesatbeginning=qw(tableofcontents);
our @tablesatend=();

our %character_emph=( pre=>'\emph{', post=>'}');

our $template = XML::XPathScript::Template->new;

$template->set( '*' => { testcode => \&tc_catchall } );
$template->set( beginpage => { pre => "\\newpage\n" } );
$template->set( [ qw/ article book / ] 
                    => { testcode => \&tc_wholedoc } );
$template->set( 'author' => { testcode => \&tc_author } );
$template->set( [ qw/ editor    collab    corpauthor    othercredit
                    firstname   honorific surname       affiliation
                    authorblurb credit    publishername 
                    orgname link refentrytitle productname 
                    / ] => { showtag => 0 } );
$template->set( [ @secttypes ] => { testcode => \&tc_section } );
$template->set( 'para' => { testcode => \&tc_para } );
$template->set( [ qw/ screen programlisting / ] 
                    => { testcode => \&tc_screen,
                         post => "\\par\n\n" } );
$template->set( 'emphasis' => { 
                      testcode => \&tc_emphasis,
                      pre=>'\emph{', 
                      post=>'}' 
} );
$template->set( variablelist => { testcode => \&tc_variablelist,
                                  pre => '\begin{description}',
                                  post => '\end{description}', } );
$template->set( 'varlistentry' => { testcode => \&tc_varlisentry } );
$template->set( 'anchor' => { showtag => 0 } );
$template->set( [ qw/literal email command application citerefentry
                constant token function option olink systemitem
                 classname type / ] => {
                    pre  => '\texttt{',
                    post => '}',
                 } );
$template->set( quote => { testcode => \&tc_quote } );
$template->set( itemizedlist => { 
                    testcode => \&tc_itemizedlist,
                    pre  => '\begin{itemize}',
                    post => "\\end{itemize}\n" } );
$template->set( listitem => {
                    testcode => \&tc_listitem,
                    pre => "\n\\item ",
                } );
$template->set( 'text()' => { testcode => \&tc_text } );                

#===== testcode functions =================================

sub tc_text {
	my ($self, $t)=@_;

	my $value=utf8totex($self);
	unless ($value =~ m/^\s+$/s) {
		$t->{pre}= $value;
		return DO_SELF_ONLY;
	}

	# Here comes XML inter-tag whitespace brain twisting:
    # </footnote> <literal>                 should produce whitespace
    # </footnote> </para>    .              should not produce whitespace
    # <footnote> <para>...                  should not (but we don't care)
    # bla <!-- bla -->ware                  should render "bla ware"
    # </footnote> <!-- ha --> </para>    .  should not produce whitespace!
    # so it _looks like_ whitespace is legitimate iff we have both a
    # preceding and following non-empty-rendering sibling element to
    # separate from. We neglect the case of elements such as <anchor/>
    # that have no text representation and should therefore be counted
    # as empty.

	my $neighbours=0;
	foreach my $axis (qw(preceding-sibling following-sibling)) {
		$neighbours++ if grep {
			$processor->is_text_node($_) ?
			  ($processor->xpath_to_string($_) =~ m/\S/) :
				$processor->is_element_node($_)
		} ($self->findnodes("${axis}::node()"));
	};

    $t->{pre} = $value unless $neighbours < 2;

	return DO_SELF_ONLY;
};

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# author ::=
# ((honorific|firstname|surname|lineage|othername|affiliation|
# 	authorblurb|contrib)+)
# The "+" is bizarre - we assume there are only one of each.

sub tc_author {
	my ($self, $t)=@_;

	my @nameparts;

	foreach my $tag (qw(honorific firstname othername surname lineage)) {
		if (my ($node)=findnodes($tag,$self)) {
			my $name=apply_templates($node);
			$name =~ s/^\s*//g; $name =~ s/\s*$//g;
			push(@nameparts, $name);
		};
	};

	$t->{pre}=join(" ",@nameparts);

	if (my ($node)=findnodes("affiliation",$self)) {
		$t->{pre}.=sprintf(" (%s)",apply_templates($node));
	};

	return -1;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub tc_listitem {	
    my ($self,$t)=@_;
	if (my $label=thelabel($self)) {
		$t->{pre}.=" $label";
	};
	return 1;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub tc_itemizedlist {
	my ($self,$t)=@_;

	$t->{pre}=listtitle($self).$t->{pre};

	return '*[name()!="title"]';
}

sub tc_quote {
	my ($self,$t)=@_;

	my $lang=langofnode($self);
	my ($nested)= $self->findnodes("ancestor::quote");

	if ($lang && $lang =~ m/^fr/i) {
		if ($nested) {
			$t->{pre}=" ``";
			$t->{post}="''";
		} else {
			$t->{pre}=" «";
			$t->{post}="»";
		};
	} else {
		if ($nested) {
			$t->{pre}=" `";
			$t->{post}="'";
		} else {
			$t->{pre}=" ``";
			$t->{post}="''";
		};
	};
	return 1;
}

sub langofnode {
    my $self = shift;
    return $self->findvalue('(ancestor::*/@lang)[position()=last()]');
}

sub tc_varlisentry {
	my ($self,$t)=@_;
	my $header= join ', ',
                map { apply_templates_under( $_ ) }
					$self->findnodes("term");

	$t->{pre}='\item['.$header.']\\ \\\\'."\n";
	$t->{post}= apply_templates_under("listitem", $self );

	return -1;
}

sub tc_variablelist {
	my ($self,$t)=@_;
	$t->{pre}= listtitle($self) . $t->{pre};
	return $_doNotProcessTitles;
}

sub listtitle {
    my $title = apply_templates_under( 'title', $_[0] );

    return "\\paragraph*{$title}\n" x !!$title;
}

sub tc_screen {
    no warnings qw/ uninitialized /;
	my ($self,$t)=@_;
	my $ret= verbatimcode($self,$t,1);

	$t->{pre}="\\par\\noindent\n".$t->{pre};
    $t->{post} .= "\n";  # *sigh*..

	return $ret;
}

sub tc_emphasis {
	my ($self, $t)=@_;
	my $mode= $self->findvalue('@role');

	if ($mode && ($mode =~ m/strong|bold/i)) {
		$t->{pre}='\textbf{';
		$t->{post}='}';
	} 

    return 1;
};

# Renders text "verbatim", not as a LaTeX verbatim environment (which
# would badly get in the way of re-entrance w.r.t. sub-elements of
# verbatim-style Docbook elements), but by emitting appropriate
# spacing and newlines so as to respect source whitespace. If $trim is
# true, trims leading and trailing whitespace. $typesetbegin and
# $typesetend indicate which TeX markup should go at the beginning and
# the end of each piece of verbatim text. A line-numbering decoration
# is automatically added for portions of verbatim stuff inside
# <programlistingco> or <screenco>.
sub verbatimcode {
	my ($self, $t, $trim, $typesetbegin, $typesetend)=@_;

	$typesetbegin ||= '\texttt{';
	$typesetend   ||= '}';
	my ($linebegin, $lineend) = ("\\hspace*{0pt}", "\\break\n");
	# Number lines inside callout environments.
	if ( $self->findvalue("name(..)") =~ m/^(programlisting|screen)co$/) {
		$linebegin = "\\markLineLeft{}".$linebegin;
	}

	foreach my $subnode ( $self->findnodes('node()')) {
		if ( $processor->is_text_node($subnode)) {
			my $text=utf8totex($subnode,
							   {
								ord("\n")=>"$lineend$linebegin",
								ord(" ")=>"\\ ",
								ord("\t")=>"\\ "x8,
								ord('@')=>'@',
								# Allowing free-style line breaks like
								# below is more questionable.
								ord('/')=>'/\allowbreak{}',
								ord('&')=>'\allowbreak{}\&',
								ord('=')=>'=\allowbreak{}',
							   });

			$t->{post}=$typesetbegin.$linebegin.$text.$lineend.$typesetend
                            . $t->{post};
		} elsif (is_element_node($subnode)) {
			$t->{post}=apply_templates($subnode).$t->{post}; # Up to child
			# elements to take precautions for respecting verbatim
			# style, if appropriate.
		};
	};
	$t->{post} =~ s/^(\\ |\n)*(.*?)(\\ |\n)*$/$2/gs if $trim;

	return -1;
};

sub RE_of_uniconvs {
    no warnings qw/ digit /;
	my ($uni)=@_;
	my @latin1variants=grep {$_ < 0xFF} (keys %$uni);
	my $RE='[^\x9\xA\x20-\xFF]|'.
	  join("|",map {sprintf('\x%x',$_)} @latin1variants);
	return qr"$RE";
}

# Converts a Unicode string into a piece of text that means something
# to TeX: recodes some special characters in Unicode, quotes TeX's special
# characters, suppresses bogus paragraph breaks (unless $significantspace
# is set).

{ my %uniwarned;
sub utf8totex {
    my ($uni, $significantspace)=@_;

	$uni = $processor->xpath_to_string($uni);

	my ($escapeRE,$uniref);
    if ("HASH" eq ref($significantspace)) {
		$uniref={%uniconvs,%$significantspace};
		$escapeRE=RE_of_uniconvs($uniref);
	} else {
		$escapeRE=$noninvarchar;
		$uniref=\%uniconvs;
	};
	do {
 	 use utf8;

    no warnings qw/ digit /;
	 $uni =~ s/($escapeRE)/
	     my $c=ord($1);
		 if (exists $$uniref{$c}) { "<$c>"; } else {
			 unless ($uniwarned{$c}) {
				 no utf8;
				 if (eval {require Unicode::CharName; 1; }) {
					 warn sprintf("Unknown Unicode character (code 0x%x) : %s\n",
								  $c,Unicode::CharName::uname($c));
				 } else {
					 warn sprintf("Unknown Unicode character (code $c)\n");
				 };
				 warn "Modify me! ".
				   "(array \%uniconvs at the top of docbook2latex.xps)\n"
				   if (! %uniwarned);

				 $uniwarned{$c}++;
		     };
			 "<?>";
		 }; /ge;  # / emacs seems to have trouble with this one

    }; # End "use utf8"

	my $tex=utf8tolatin1($uni);

	# Insignificance of spaces: keep source indentation, remove
	# unwanted paragraph breaks.

	unless ($significantspace) {
		$tex =~ s/\s*\n/\n/gs;
		$tex =~ s/^\n/ /;
	};

	$tex =~ s/<\?>/$uniunknown/ge;
	$tex =~ s/<([0-9]*)>/$$uniref{$1}/ge;

	# Will the XML deities ever forgive me for this one ? :-)
	$tex =~ s/\bTeX\b/\\TeX{}/g;
	$tex =~ s/\bLaTeX\b/\\LaTeX{}/g;

    return $tex;
}

} # End of scope for %uniwarned

sub tc_para {
	my ($self,$t)=@_;

	# We put a paragraph break only if there is a following element
	# (so as not to break e.g. itemizations)
	my ($brother)= $self->findnodes('following-sibling::*[1]');
	$t->{post}=($brother ? "\n\n": undef );
	return 1;
};

sub tc_section {
    my ($n, $t ) = @_;

    # TODO will break for anything not directly mapped to LaTeX 
    # sections

    my $name = $n->getName;

    if( $name eq 'section' ) {
        my $parent = $n->parentNode->getName;
        $name = 'sub'.$parent if $parent =~ /section/;
    }

    my $title = apply_templates_under('title',$n);
    my( $abbrev_node ) = $n->findnodes('titleabbrev');
    my $titleabbrev;
    if ( $abbrev_node ) {
        $titleabbrev = apply_templates_under( $abbrev_node );
    }
    $titleabbrev ||= $title ;

    if ( $numbered_sections ) {
        $t->{pre}="\n\n".sprintf '\%s[%s]{%s}',$name ,$titleabbrev, $title ;
    }
    else {
        $t->{pre} = "\n\n".sprintf '\%s*{%s}',$name, $title ;
        $t->{pre} .= "\\addcontentsline{toc}{$name}{$titleabbrev}\n";
    }
	$t->{pre}.=thelabel($n)."\n\n";

    if( $name eq 'chapter' ) {
        $t->{pre} .= "\n\\markboth{$titleabbrev}{}\n";
    }
    elsif( $name eq 'section' ) {
        $t->{pre} .= "\n\\markright{$titleabbrev}\n";
    }

    return $_doNotProcessTitles;
};

sub thelabel {
    return unless @_;

    no warnings qw/ uninitialized /;

    my $label = id2label( $_[0] );

    return $label ? "\\label{$label}\n" : q{} ;
}

# Handle UTF-8 braindamage and prevent utf8 tainting from propagating
# to the whole document (TeX dislikes UTF-8). See documentation at
# the end.
sub utf8tolatin1 {
	my $orig=shift;

	$orig = $processor->xpath_to_string($orig);

	return pack("C*",grep {$_<255} (unpack("U*",$orig)));
}

sub id2label {
	my ($node,$attrname)=@_;
	$attrname ||= "id";
	my ($attr)= $node->findnodes( '@'.$attrname );
	return undef if (! $attr);
	my $text=utf8tolatin1($attr);
	$text =~ s/[^a-zA-Z0-9:-]/-/g;
	return $text;
}

sub section_nesting_depth {
	my ($self)=@_;
	# Computing of the nesting depth, which equals the number of
	# ancestors that are either sections or appendices.
    my $p=0;
    for(my $ancetre=$self;
   	 ($ancetre)=findnodes("..",$ancetre);
   	 1) {
   	 my $nom=findvalue("name()",$ancetre);
   	 last unless grep {$nom eq $_} (@secttypes,"appendix", "glossary",
								   "bibliography", "bibliodiv");
   	 $p++;
    };

    die_at($self,"Nesting too deep") if ($p > scalar(@sectionnames));

	return $p;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
    my $class = shift;
    my $self = XML::XPathScript::Template->new();
    bless $self, $class;
    return $self;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub tc_catchall {
    my $node = shift;

    my $name = $node->getName;

    die "tag $name not recognized\n";
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub tc_wholedoc {
	my ($self,$t)=@_;

    my $documentclass = $documentclass;

    my %class = (
        book => 'book',
        article => 'article',
    );

    unless( $documentclass ) {
        my $name = $self->getName;
        $documentclass = $class{ $name } || 'report';
    }

	$t->{pre}= '\documentclass[' 
               . join( ',', @documentclass_args )
               . "]{$documentclass}\n";

	my @packages=@packages; #Huuh.

    push @packages, qw/ longtable multirow / if $fancytables;

	foreach my $p (0..$#packages) {
	  if (ref($packages[$p]) eq 'ARRAY') {
		  my ($package,@options)=@{$packages[$p]};
		  $t->{pre}.="\\usepackage[".join(",",@options)."]{$package}\n";
	  } elsif (! ref($packages[$p])) {
		  my $package=$packages[$p];
		  $t->{pre}.="\\usepackage{$package}\n";
	  } else {
		  warn sprintf("No clue for entry number %p in \@packages\n");
	  };
  };

	$t->{pre}.=<<"PREAMBLE";
$TeXkludges

$TeXpreamble

PREAMBLE

	my $titlenode;
	foreach my $pos (all_paths_for_header_element("title")) {
		last if (($titlenode)= $self->findnodes($pos));
	};
	my $title = $title     ? $title
              : $titlenode ? apply_templates_under($titlenode) 
              :              undef
              ;

	my @subtitles=map { apply_templates_under($_) }
	  (map { $self->findnodes($_)}
	   (qw(articleinfo/subtitle artheader/subtitle bookinfo/subtitle subtitle)));

	my $author = render_authors('stack', $self);

   if (! $maketitle) {
	   my $typeset_title=$title;
	   $typeset_title.=join("",map
			{sprintf(<<'SUBTITLE',$_)} @subtitles);
\\
\vspace{1ex}
{\LARGE{}%s}
SUBTITLE

        if ($typeset_title) { $t->{pre}.=sprintf(<<'TITLE',$typeset_title);}
\title{\textbf{\textsc{\Huge{}%s}}}
TITLE

        no warnings qw/ uninitialized /;
		$t->{pre}.="\n\\author{$author}\n";
   };

   $t->{pre}.="\n\n\\begin{document}\n\n";

   $t->{pre}.=$TeXbegindocument if $TeXbegindocument;
   $t->{pre}.= ( $firstpage? $firstpage : $maketitle ? (&$maketitle($title,\@subtitles,$author)) :
		($title ? "\\maketitle\n" : "") );

	foreach my $subnode (all_paths_for_header_element("abstract"),
						 all_paths_for_header_element("legalnotice"),
						 "epigraph") {
		if (my ($node)= $self->findnodes($subnode)) {
			$t->{pre}.= $processor->apply_templates($node);
		}
	}

	$t->{pre}.=join("",map { "\\$_".'{}'."\n" } @tablesatbeginning);

	$t->{pre}.="\\clearpage\n" if(scalar(@tablesatbeginning));

  $t->{post}=join("",map { "\\$_".'{}'."\n" } @tablesatend);
  $t->{post}.='\end{document}';

  return '*[name()!="articleinfo" and name()!="artheader" '.
  ' and name()!="bookinfo"'.
  ' and name()!="epigraph" and name()!="title" and name() != "subtitle"]';
}

# The DTD has variants, this is annoying...
sub all_paths_for_header_element {
    return map { ( "articleinfo/$_", "bookinfo/$_",
                 "artheader/$_", $_ ) }  @_;
}

# A convenience function to pass through forbidden or unhandled tags:
sub apply_templates_under {
	my ($xpath, $node);

	if (scalar(@_) == 0 || scalar(@_) > 2) {
		carp sprintf("apply_templates_under() called with %d args",scalar(@_));
		return "";
	};

	if (scalar(@_) == 2) {
		($xpath, $node)=@_;
	} else {
		if (ref $_[0]) {
			($node)=@_;
		} else {
			($xpath)=@_;
		};
	}

	$xpath = ($xpath ? "$xpath/node()" : "node()");

	unless ( $processor->is_element_node($node) ) {
		confess("Wrong call to apply_templates_under");
	};

	my @subnodes= $node->findnodes($xpath);
	@subnodes=grep {
		my $n=$_;
		($processor->is_element_node($n) || $processor->is_text_node($n));
	} (@subnodes);

	return "" unless @subnodes;
	return $processor->apply_templates(@subnodes);
}

sub render_authors {
	my ($rendermode, @authors)=@_;

	if (ref($authors[0])) { # Not quite the same meaning
		my $self = $authors[0];
		my $nodename= $self->findvalue('name()');

		if ($nodename =~ m/^(?:artheader|(article|book)(info)?)/) {
			my @paths = qw(author corpauthor
						   authorgroup/author authorgroup/corpauthor);
			if (($nodename ne "artheader") && (! $2)) {
				push @paths,
				  ($1 eq "article" ?
				   (map { ("articleinfo/$_", "artheader/$_") } @paths) :
				   (map { "bookinfo/$_" } @paths));
			}

			@authors=map { $processor->apply_templates($_) }
			  (map { $self->findnodes($_) } @paths);
		}
	}

    return unless @authors;

    return $authors[0] if @authors == 1;

	if ($rendermode eq "stack") {
        my $a = "\\begin{tabular}{rl}\n";
        $a .= join '', map "by & $_ \\\\\n", shift @authors;
        $a .= $_ for map "& $_ \\\\\n", @authors;
        $a.= '\end{tabular}';

        return $a;
	} 
    
    if ($rendermode eq "ampersand") {
		my $lastauthor=pop @authors;
		return join(", ",@authors)." \\& $lastauthor";
	}
    
    carp "Unknown rendermode $rendermode";
    return join ", ",@authors ;
}



$template->{'orderedlist'}->{testcode}=sub {
	my ($self,$t)=@_;

	$t->{pre}=listtitle($self);

	$t->{'pre'}.="\\begin{enumerate}";
	$t->{'post'}="\\end{enumerate}\n";

	# Handling of the "continuation=Continues" attribute in a context-
	# dependent fashion (as opposed to crude hacks with global variables).
	# Algorithm: add the number of sons of all lists that preceed and
	# also have "continuation=Continues" set, and then another list
	# that doesn't have it.

	my $cont= $self->findvalue('@continuation');
	if ($cont && ($cont =~ m/continues/i)) {
		my $num=0;

		my @pals=reorder_backaxis("backward",
								  findnodes('preceding::orderedlist',$self));

		foreach my $pal (@pals) {
			$num += findvalue("count(*)",$pal);
			my $cont=findvalue('@continuation',$pal);
			last if ($cont && ($cont !~ m/continues/i));
		};
		
		$t->{pre}.="\n".'\makeatletter\setcounter{\@enumctr}{'.
		  "$num}\\makeatother";
	};
	return '*[name()!="title"]';
};

$template->{'ulink'}->{testcode}=sub {
	my ($self, $t)=@_;

	my $url="\\texttt{".utf8totex( $self->findvalue('@url'), 
								  {
								   ord(" ")=>"\\ ",
								   ord('@')=>'@',
								  })."}";

	if ( $self->findnodes("node()") ) {
		$t->{post}=render_footnote($self, $url);
		$t->{pre}="";
		return 1;
	} else {
		$t->{pre}=$url;
		$t->{post}="";
		return -1;
	}
};


our $_render_footnote;

sub render_footnote {
	$_render_footnote ?
	  goto &$_render_footnote :
		goto &_default_render_footnote;
}

sub _default_render_footnote {
	my ($self, $text)=@_;

	if (! footnotes_allowed($self)) {
		return ("\\footnotemark{}");
	} else {
		return ("\\footnote{".thelabel($self)."$text}");
	}
}

sub collect_trapped_footnotes {
	my ($self)=@_;

# my $selfpath=get_xpath_of_node($self); warn "collect_trapped_footnotes($selfpath)";

	return "" if ($_render_footnote);
	return "" if (! footnotes_allowed($self));

	my ($text, @collected);

	do {
		local $_render_footnote=sub {
			my ($self, $text)=@_;
			my $defaultresult=_default_render_footnote(@_);

			if ($defaultresult eq "\\footnotemark{}") {
				push(@collected, [$self, $text]);
				return "\\footnotemark{$#collected}";
			} else {
				return $defaultresult;
			}
		};
		$text = apply_templates($self);
	};

	return _recurse_layout_footnotetexts($text, @collected);
}

sub _recurse_layout_footnotetexts {
	my ($raw_footnotetext, @context)=@_;

#warn "_recurse_layout_footnotetexts($raw_footnotetext,...)";
	my @occurences=($raw_footnotetext =~ m/\\footnotemark\{(\d+)\}/g);

	my @footnotetexts=map {
		my $node;
		($node, $_)=@{$context[$_]};
		my $substuff=_recurse_layout_footnotetexts($_, @context);
		s/\\footnotemark\{(\d+)\}/\\footnotemark{}/g;
		"\\footnotetext{".thelabel($node)."$_}\n$substuff";
	} @occurences;

	die "assertion failed" unless (@footnotetexts == @occurences);

	# OK this would be enough assuming that \footnotemark and
	# \footnotetext each run on their own counter. Unfortunately
	# they don't: LaTeX dumbly assumes that \footnotetext is only
	# ever used when there is exactly one outstanding
	# \footnotemark to be terminated. Let's fiddle with the counter
	# to compensate.

	if (@footnotetexts == 0) {
		return "";
	} elsif (@footnotetexts == 1) {
		return $footnotetexts[0];
	} else {
		return "\\addtocounter{footnote}{-".($#footnotetexts)."}\n".
		  join("\\addtocounter{footnote}{1}\n", @footnotetexts);
	}

}

our @footnote_blockers;
push(@footnote_blockers, "footnote");
$template->{'footnote'}->{testcode}=sub {
	my ($self,$t)=@_;

	my $retval;
	$t->{pre}=render_footnote($self, apply_templates_under($self));
	$t->{post}=collect_trapped_footnotes($self);
	return -1;
};

our $is_footnote_blocker;

# Tells whether footnotes are allowed at $self, if $virtroot were to
# be the root of the document. $self itself is not taken into account
# even if it is a footnote blocker.
sub footnotes_allowed {
	my ($self)=@_;
#warn "footnotes_allowed",get_xpath_of_node($self);

	my ($parent)= $self->findnodes('..');
	if (!defined $parent) {
#warn "footnotes_allowed hit root";
		return 1
	}
	if (&$is_footnote_blocker($parent)) {
#warn sprintf("&\$is_footnote_blocker(%s) is true", get_xpath_of_node($parent));
		return 0
	}
	return footnotes_allowed($parent);
}

$is_footnote_blocker=sub {
	my ($self)=@_;

	my $nodename= $self->findvalue('name()');
	return undef if (! $nodename); # Root node
	return grep {$_ eq $nodename} @footnote_blockers;
};
1;

=pod

=encoding UTF-8

=head1 NAME

XML::XPathScript::Stylesheet::DocBook2LaTeX - Transforms DocBook into LaTeX

=head1 VERSION

version 2.00

=head1 SYNOPSIS

    use XML::XPathScript;
    use XML::XPathScript::Stylesheet::DocBook2LaTeX;

    my $latex = $xps->transform( 
        $docbook => XML::XPathScript::Stylesheet::DocBook2LaTeX::stylesheet
    );

=head1 WARNING

This module is still in a very beta-ish stage.
We heavily recommend to wait till we tell you to to use it. 
But if you are in an adventurous mode, by all means, go ahead. :-)

=begin devel

=head1 NAME

docbook2latex.xps - an XPathScript stylesheet for LaTeX.

=head1 SYNOPSIS

  xpathscript yourdoc.xml docbook2latex.xps > yourdoc.tex

=head1 DESCRIPTION

This is docbook2latex.xps version number $Revision: 32928 $, by IDEALX
(http://www.idealx.org/docbook2latex/).

Using Matt Sergeant's XPathScript framework (see L<SEE ALSO>), this stylesheet
translates Docbook XML into LaTeX for beautiful typesetting of Docbook
articles (reports, books and other kinds of whole documents defined by
the DTD are not supported yet).

Provided you have the Perl dependencies installed (XML::XPathScript,
from CPAN, as well as all sub-dependencies of those), the command
shown in the synopsis will turn any (DTD-conformant) C<mydoc.xml> into
pure LaTeX (that is, using only packages included in the TeTeX
distribution to compile). Every unknown Unicode character or XML tag
present in the document will trigger appropriate warnings, but the
stylesheet will recover nicely and still produce a valid LaTeX output.

This stylesheet supports french and english typesetting, on a per-tag basis.

Of course, I bet you won't be pleased with the aesthetics of the result,
or maybe there are some tags (from the 400+ in Docbook) or characters (from
the 30000+ in Unicode) that aren't typeset and that you absolutely want. So
read on...
=head1 USER DOCUMENTATION

=head1 CUSTOMIZING AND ADDING FUNCTIONALITY

You could just modify the stylesheet: there are plenty of comments,
but grasping the big picture at once can be difficult. Fortunately,
XPathScript allows for overload-oriented customization; the same
philosophy is followed throughout this stylesheet, so that there are a
number graft points (beside whole XML tags, as specified in the
XPathScript documentation) where you can modify part of the stylesheet
behaviour without interfering with the overall functionality. Working
knowledge of XPathScript is assumed (see L<SEE ALSO>).

=head2 An example

Cut-and-paste the following text into test.xps, then run
C<xpathscript mydoc.xml test.xps>:

E<32>E<32><% our $inhibitOutput; $inhibitOutput++; %I<>>

E<32>E<32><!--#I<>include file="docbook2latex.xps"-->

E<32>E<32><% $inhibitOutput--; %I<>>

  <%
  # Change the style to add fancy headers and the word "draft" behind
  # every page
  push(@packages,"fancyhdr");
  push(@packages,[ "draftcopy" => "all", "english" ]);

  # override the varname tag to display as sans-serif
  delete $t->{varname}; $t->{varname}->{testcode}=sub {
	  my ($self, $return)=@_;
	  $return->{pre}='\textss{';
	  $return->{post}='}';
	  return 0;
  };

  # double the ruler on top of each table.
  our $typeset_tableframe;
  my $ORIG_typeset_tableframe=$typeset_tableframe;
  $typeset_tableframe=sub {
     return '\hline'.($ORIG_typeset_tableframe(@_));
  }

E<32>E<32>%I<>>

E<32>E<32><%= $inhibitOutput ? "" : apply_templates()  %I<>>
=head2 Modification points

The modification points fall into 3 categories: configuration variables,
overridable templates and overridable function references. The example
above shows how to override all three.

=over 4

=item Environment variables

There is no standard method yet for passing arguments to an
XML::XPathScript stylesheet. Waiting for something better, the UNIX
environment is used instead. At present, no environment variable is
recognized and any customization must be done by a cascading
stylesheet (but in order to get customization e.g. for outputting
variadic documents, said stylesheet may need to read the environment).

=item Configuration variables

There are package-global variables that are read at runtime to
customize the stylesheet's behaviour. Examples are C<$fancytables> (if
true, use the C<longtable> package to typeset tables) and C<@packages>
(the list of TeX packages to invoke in the preamble).  The list of
such configuration variables is shown in L</REFERENCE MANUAL>.

=item Overridable templates

As stated in the XPathScript documentation, the $t variable (which is
in scope from every < % ... % > construct) holds a reference to a hash
of XML element handlers keyed by element name, which can be replaced
with your own (see C<<
http://axkit.org/docs/xpathscript/guide.dkb?section=6 >>). The code in
the templates is fully context-dependent, in that it only ever reads
data from the XML document to reach a typesetting decision, and does
not use any muddy global variables to pass sticky state information
around (the only exception is that a function is allowed to cache its
results). This means it is perfectly OK to replace only some of the
element handlers with your own, without messing up with the way the
others work. Beware though that some tags are not rendered as part of
the C<apply_templates()> mechanism, but are treated in an ad-hoc way
by the stylesheet - for example, <title> tags are always rendered in
TeX as part of the parent <section>, <table>, <figure> or such.

The rule of thumb for overriding templates is: B<a template for some
tag is overridable if and only if it C<exist()s> in the C<$t> hash,
and is not listed in the C<@abstracttags> variable> provided by the
stylesheet as package-global for this purpose.
=item Overridable function references

In some particularly tedious places of the stylesheet (e.g. for
tables), there is a function reference in a package-global variable
that holds a function that will be called for typesetting
something. For example, C<&$typeset_tablerow(something)> will be
called to typeset a row in a table.  The list of such function
references and their prototypes and expected semantics is described in
L</REFERENCE MANUAL>, so that you may code your own replacements for
those in use in this stylesheet.

=back

=head2 Unicode guidelines

By far the greatest pain when enhancing this stylesheet (and even
before, when writing it...) is Unicode support. XML input through
I<XML::Parser> always happens in Unicode, as per the XML standard;
Perl stores the result in its new polymorphic strings (with UTF-8 as
the in-memory representation) which exhibit the "contamination
problem" (see L</XML::XPathScript::Toys::translate_node>). LaTeX barfs
on Unicode input, of course. Therefore, there needs to be a kind of
"unicode firewall" throughout the stylesheet(s) that correctly
transcodes every kind of Unicode input into LaTeX (which for our
purpose is a subset of Latin1 since we use the C<inputenc> package).

=over 4

=item *

Text nodes explicitly computed by user code should be converted using
extra utf8tolatin1() or utf8totex() calls (which see) :

  $t->{pre}.=findnodes("/article/articleinfo/title/text()"); # WRONG

would produce a bogus C<XML::XPath::Node::Text=SCALAR(0xdeadbeef)>, while

  $t->{pre}.=findvalue("/article/articleinfo/title/text()"); # WRONG

as suggested by the XPathScript documentation, would UTF8-taint the result.

Use this instead:

  my ($node)=findnodes("/article/articleinfo/title/text()"); # WARNING,
     # scalar context would not work - see Quirks.
  $t->{pre}=utf8totex($node);

or even simpler, use L</apply_templates_under> that was created for this
very purpose:

  my $rendered=apply_templates_under("/article/articleinfo/title");
=item *

Element nodes should never be converted to text directly:

    $t->{pre}.=findnodes("/some/path",$self);  # WRONG, as
     # would be any variation thereof with findvalue() or such

Use something like L</apply_templates_under> instead to recurse into
their substructure. The rationale is that outputting stringified
element nodes only has meaning if the output is XML too, or tagless UTF-8
at the very least, and has no meaning for TeX.
=item *

XPath values that are not nodes should be dealt with using the
UTF8-to-something-else functions:

  $t->{pre}.=utf8totex(findvalue('@url',$self));

  my $filename=utf8tolatin1(findvalue('@fileref',$graphicnode));

=item *

If you don't copy the part of the document into the output but are
merely testing something about it, then Unicode won't hurt you. For
example, in

   $t->{pre}.="\\textbf{" if (findvalue("@role",$self) eq "strong");

Here C<findvalue("@role",$self)> is UTF-8 but you won't ever have
to bother since it does not make its way to the output stream. The
test works as expected ("strong" is promoted to Unicode but this does
not change its value), the Boolean test result is not tainted (it
never is), and therefore the result, "\\textbf{" is Latin1 as it
should.
=back

=head2 Quirks

Bugs and oddities were spotted in various places of the Perl XML support
software (XML::XPath version 1.12), and the following workarounds were used
to circumvent them. You may find it useful to do likewise in
your own extensions:

=over 4

=item *

the clever object model in I<XML::XPath> with shadow objets geared at
good garbage collection gets in the way for the I<matches()> function,
which only works toward ancestors of the node (as of version 1.12);

=item *

findnodes() in scalar context returns an object which is I<not> a node,
but an I<XML::XPath::NodeSet>. Be careful to always call it in list
context if you are interested in nodes and not NodeSets; if you just
want one node, say

   my ($attrnode)=findnodes('@url',$xrefnode);
=item *

apply_templates() with no arguments does what the spec does, which is
exactly what you don't want (re-render the whole document through the
stylesheet!). Use apply_templates_under instead:

   $t->{pre}.=apply_templates(findnodes("para",$node)); # WRONG if
                    # findnodes() yields no results

   $t->{pre}.=apply_templates_under("para",$node); # OK
=item *

findnodes() performed on a backward axis (ex 'preceding::') in array
context should return the value in reverse document order (according
to the XPath spec and reasonable expectation), but doesn't in versions
1.12 and 1.13. The manpage is not clear as to whether this is a bug or
a feature. In order to accomodate both possible outcomes of this
behaviour (stays the same or is reversed) in future versions of
I<XML::XPath>, the I<reorder_backaxis()> function compensates this
(see L</reorder_backaxis>).

=back

See also L</Unicode guidelines> which may, as a whole, be considered
as a big quirk of its own, and also L<XML::XPathScript/Stylesheet
Guidelines>.

=head1 PROGRAMMING FAQ

=over 4

=item I<I get a strange error about an XPath query with pieces of LaTeX
inside, which is nowhere to be found in my source...>

This is because your {testcode} routine did not return a satisfactory
value. Remember: you have to return -1 ("do not render the subtree of
this node, I did it already, just output $t->{pre} and $t->{post} side
by side"), 1 ("please render the subtree in full"), 0 ("render
nothing at all please") or an XPath expression ("only render those
subnodes that match this expression").

Forgetting the C<return> altogether is a common mistake: in the
following code, "\end{stuff}" would be the return value, thus causing
the reported behaviour:

$t->{sometag}->{testcode}=sub {
   my ($node,$t)=@_;
   $t->{pre}="\\begin{stuff}";
   $t->{post}="\\end{stuff}";
};
=item I<I get an internal error in an XML::XPath module. What next?>

Please keep in mind that some XPath expressions, although
syntactically correct, lead to errors. Consider the following snippet:

   my $targetname=findvalue("name(id($label))");

It is an error for the XPath function name() to be called with
anything but one stringifiable argument. Thus, if $label does not
exist, you are screwed - and the evaluation of the XPath expression
will produce a most cryptic error. Rewrite your code into this:

   my ($targetnode)=findnodes("id($label)");
   return "" if (! $targetnode);
   my $targetname=findvalue("name()",$targetnode);

(but the real solution in this particular case is of course to
validate your document against the DTD beforehand - that would have
spotted the inexisting reference $label was supposed to point to.)
=back

=head1 REFERENCE MANUAL

=head2 Support functions and global variables

This stylesheet defines a number of convenience functions and global
variables that can be reused inside your own extensions.

=head3 Basic pipework

=over 4

=item warn_at($node, $message);

=item die_at($node, $message);

Same as warn() and die(), but produce appropriate messages indicating the
point of the error, using get_xpath_of_node().

=item my $text=framederror($error);

=item my $text=centerederror($error);

Typesets an error text in a 0.4\columnwidth wide framed box, which
provides fancy error messages in place of missing images, bogus
tables, etc. instead of quitting the stylesheet abruptly. The
centerederror() function adds a centering environment around the box.

=item @nodes=reorder_backaxis("forward",@nodes);

=item @nodes=reorder_backaxis("backward",@nodes);

Assuming that @nodes was obtained through a call to I<findnodes> on a
backward axis (which has ordering issues, see L</Quirks>), Do The
Right Thing and reverse them if needed (e.g. when you want your nodes
backwards w.r.t. document order and the I<XML::XPath> du jour provides
them forwards, or vice versa). Will die if the behaviour of the
XML::XPath version in use is unknown (right now, we are backward
compatible, pun intended, with all versions up to 1.13).

=item my $outputtext=apply_templates_under( [ $xpath ] , [ $node ] );

Same as L<XML::XPathScript/apply_templates>, but allows for "skipping"
node types that are not handled directly (for example because they are
abstract - see L<@abstracttags>). C<apply_templates_under($node)>
applies the templates to all children of $node (excluding $node
itself), and returns the concatenation of all results;
C<apply_templates_under($xpath, $node)> applies the templates to those
nodes that match C<$xpath> starting from C<$node>, and returns the
concatenation of all results.

=item call_template($node,$t,$template);

Calls a template from a "testcode" routine, and updates $t accordingly
as if calling the appropriate "testcode" entry in $template, a
standard XML::XPathScript template structure. Returns the same value
as said testcode would. This function is useful for overloading
templates in cascaded stylesheets:

  my $oldtemplate=delete $t->{someelement};
  $t->{someelement}->{testcode}=sub {
     my ($node,$t)=@_;
     return call_template($node,$t,$oldtemplate);
  };

(the above example is trivial, as it does exactly the same thing as
the old template would. But you get the idea).

If $template has no "testcode" tag, the functionality is emulated
(e.g. $t->{pre} is set from $template->{pre} etc.)
=item %uniconvs

A hash whose keys are numeric Unicode codes (see L</SEE ALSO>) and whose
values are the corresponding LaTeX sequences to render the character.
%uniconvs need not contain space, tab, newline nor any Latin1 character
(those are done automatically), but it doesn't hurt if it does.

One must call reload_uniconvs() after modifying this variable.
=item $uniunknown

The sequence of characters rendered in place of an unknown character.

=item reload_uniconvs();

Refreshes the internal variables of this stylesheet (namely, a regexp
cache). To be called whenever %uniconvs is modified.

=item my $textinlatin1 = utf8tolatin1($textinunicode);

Returns a Unicode-untainted, Latin1-only copy of its input (which may
be a text node or a stringifiable object). Unicode characters above
0x0fe in $textinunicode are removed.

=item my $textinlatex = utf8totex($textinunicode, $significantspace);

=item my $textinlatex = utf8totex($textinunicode, $translations);

Converts an UTF8-encoded string, stringifiable object or text node
(that is, most kinds of stuff coming down from the XML data model)
into a form that is GROKked by LaTeX using the C<inputenc> package
(most Latin1 characters are supported directly). This function first
uses the C<%uniconvs> configuration variable (see above), then a
direct Latin1 mapping if the character is either whitespace or in
Latin1 range. If this also fails, C<$uniunknown> is rendered and an
appropriate warning is emitted.  Unless $significantspace is set to a
true value, sequences of consecutive whitespace are collapsed to one
and purely whitespace strings are converted to the empty string.

If $translations is additionnally a hash reference, it may supply
additional character transliterations that will override those in
L<%uniconvs>. This is most useful for verbatim modes.
=item my $labelstring = langofnode($node);

Returns the language that prevails in node $node (as defined by the closest
ancestor having a "lang" tag). Returns the empty string if no ancestor has
a "lang" tag.

=item my $text= flatten_textnodes ($node);

=item my $text= flatten_textnodes ($node,$xpath);

Returns a text version of $node's content, obtained by concatenating
all text subnodes in $node, normalizing all whitespace to just one
space, and suppressing ISO Latin1 accents. The return value is in
Latin1. This is used for example in the <indexterm> template, to get
alphabetic sorting right in C<makeindex>. $xpath, if specified, is an
XPath expression to filter the right text subnodes in $node (the
default is ".//text()").

=back

=head3 General LaTeX support

Functions and global variables in there deal with day-to-day LaTeX,
excluding character set issues (dealt with in L</Basic pipework>) and
tables (see L</LaTeX tables>).

=over 4

=item $documentclass

=item @documentclass_args

The arguments to the opening \documentclass{} macro call. By default,
docbook2latex produces a 11pt, twoside, a4paper report (that is,
C<$documentclass="report"> and C<< @documentclass_args = ("11pt",
"twoside", "a4paper") >>).

=item $dvidriver or $ENV{DVIDRIVER}

The name of the DVI driver used for rendering this document, such as
C<dvipdfm> or C<dvips>. This variable also helps making decisions for
rendering images (the <graphic> tag for example). This stylesheet
indeed has support for both PostScript® and PDF document rendering,
but unfortunately not through the same TeX output file (due to
restrictions on LaTeX's side) so the DVI driver has to be chosen at
XML-to-LaTeX conversion time.

As a not-really-functional-style but oh-so-convenient temporary kludge
(pending a standard means of passing stylesheet arguments on the
xpathscript command line), $ENV{DVIDRIVER} is the default value of
$dvidriver, that is, one can change this parameter through the
environment, without even altering the stylesheet.
=item @abstracttags

The list of tags that are abstract, that is, that should never have
apply_templates() applied to them directly. An example is <title>
tags that cannot be rendered properly alone, but only as part of their
parent <section>, <table> or the like. This variable is read-only and
only serves as a convenience to the programmer (``is it of any use
for me to overload this tag in $t ?''), modifying it has no effect.

=item $fancytables

If set to a true value (the default), tables are typeset using the
C<longtable> and C<multirows> LaTeX packages. If set to a false value,
plain C<tabular>s are used instead.

=item $glosstermsinindex

If set to a true value (the default), then <glossterm> nodes that do
not appear in a <glosslist> will be included automatically in the
index with a status of preferred entries (equivalent to <indexterm
significance="preferred">).

=item @packages

The list of packages to be included into the LaTeX preamble. This array
may contain plain strings, or references to sub-arrays for packages that
want options (the package name comes first in the sub-array, then the
function - see L</An example>).

=item @sectionnames

The sequence of section-like TeX macros, from highest (e.g. 'part') to lowest
(e.g. 'subparagraph'). Customizing this is likely to be a priority for
those not satisfied with the aesthetics.

=item @tablesatbeginning

The macros for the table(s) to be generated at the beginning of the
document (without the backslash). By Default "tableofcontents" is
always first and then "listoffigures" and "listoftables" (in that
order) are appended iff there is at least one figure (resp. table) in
the document.

=item @tablesatend

The macros for the table(s) to be generated at the end of the document
(without the backslash). Defaults to empty, or just "printindex" if
there is at least one <indexterm> in the document.

=item $TeXkludges

The set of macro definitions that has to be present in the document in order
to get it to process. We tried very hard to keep this to a minimum - but there
still was quite a bit of Knuth cursing going on at IDEALX during the making
of this stylesheet. If you have solutions without those, let us know.

=item $TeXpreamble

A variable to append to to your liking to include TeX directives
into the LaTeX preamble.

=item $TeXbegindocument

A variable to set to your liking to include TeX directives just after
the LaTeX \begin{document}. Initially set to some general typesetting
directives.

=item $inhibitOutput

If set to one, this stylesheet doesn't apply_templates() by itself. Useful
if you want to overload it (see L</An example>)

=item %boxlabels

=item %boxstyles

Both variables govern the rendering of I<tip>, I<remark>, I<note>,
I<example>, I<warning>, I<important> and I<caution> elements. Entries
in %boxstyles are keyed by element names, and the matching values are
the LaTeX command that is used to wrap them, without the backslash
(fancybox macros are set up by default, see the LaTeX Companion page
278).

%boxlabels holds the translations of the default titles for those
environments. it is a hash of hashes, whose outermost keys are
two-letter language abbreviations (e.g. "en" and "fr"), and whose
innermost keys are the element names.
=item my $TeXlength = TeXlength($docbooklength);

=item my $TeXlength = TeXlength($docbooklength, $starlength);

Returns the conversion of $docbooklength into a LaTeX length. If
$starlength is specified, this is the value of "1*" (default is
\fill).

=item my $TeXlength = multiply_TeX_dimension($TeXlength, $factor);

As the name implies, multiplies a TeX dimension by the given factor.

=item my $label = id2label($node [, $labelname ] );

Takes the attribute named $labelname ("id" by default) from $node and
turns it into a string that is "more or less" unique and may be used
as the argument of a \label{} or \ref{} command in TeX (e.g. bogus
characters stripped). Returns undef if $node has no id (or no
attribute named $labelname).

=item my $labelstring = thelabel($node);

Supports cross-referencing in LaTeX. If C<$node> has an C<id> tag,
returns C<\label{id}>, else returns the empty string. The function id2label()
above is used for this purpose.

=item my $titleornothing = listtitle($node);

Returns a typeset title as "\paragraph*{Title}", or the empty string,
depending on whether $node has a <title> child. Appropriate for
paragraph-like elements that may have a title, such as <itemizedlist>,
<orderedlist>, <formalpara> etc.

=item my $n = section_nesting_depth($node);

Returns the depth of the current section nesting, in terms of an index
into @sectionnames that would be appropriate for placing a sectionning macro
for $node if it were itself a section.

=item my $author_or_authors = render_authors($rendermode, $node);

When $node is an <article> or <book> node, returns the typeset string
of the author(s) of the article or book. $rendermode is the rendering
style; recognizes modes for now are "stack" (returns multiple authors
as a tabular that stacks authors vertically) and "ampersand" (returns
a string of the form "Johnson, Johnson \& Johnson").

=item my $author_or_authors = render_authors($rendermode, @author_names);

When @author_names are already typeset author names (typically using
the template for C<author>), returns the typeset string of the group
of said authors according to $rendermode (see above).

=item my $text=render_graphic($node);

=item my $text=render_graphic($node, $scale);

If $node is a <graphic> or <inlinegraphic> element node object, then
render the appropriate \includegraphics{} command for it (but not the
surrounding TeX material for centering or making a float of it). This
is shared code for <graphic> and <inlinegraphic> templates. $scale is
an optional scale factor (default is 1) to multiply the
document-specified dimensions with (using L</multiply_TeX_dimension>).

=back

=head3 LaTeX footnotes

Mostly every time some kind of tabular or minipage environment is
used, the \footnote{} macro becomes nonfunctional inside it. It is
still possible to typeset footnotes; the trick is page 71 of the LaTeX
Companion - you have to look for it, though: instead of

  \begin{table}{|c|}
  foo\footnote{bar}
  \end{table}

one says

  \begin{table}{|c|}
  foo\footnotemark{}
  \end{table}
  \footnotetext{bar}

This looks like too tough a job for a pure context-dependent
stylesheet paradigm right? Wrong :-).
=over 4

=item @footnote_blockers

The list of element names that may typeset themselves in such a way that
the \footnote{} macro does not work inside them. Stylesheet extension
writers should add (or subtract, why not?) elements there according to
their LaTeX design.

=item my $latex = render_footnote($node, $text)

Returns an appropriate LaTeX snippet for signalling a footnote as part
of $node's rendering, containing $text as the text.  Appropriate for
implementing the templates of <footnote>, <ulink> et al. This function
is not as trivial as it seems, because it handles the necessary magic
of \footnotemark / \footnotetext in minipages environments
(e.g. tables) where normal footnotes cannot be used because of
limitations in LaTeX.

=item collect_trapped_footnotes($node)

=item collect_trapped_footnotes($node, @children)

Returns a string made up of all \footnotetext{}'s that are to appear
below $node's rendering, assuming it blocks footnotes. This list is
collected by rendering @children again (by default, all of $node's
children) using a skewed definition of render_footnote().

=back

=head3 LaTeX tables

=over 4

=item my $x = table_getcolXbyname($row, $name);

=item my ($xstart, $xend) = table_getspanXbyname($row, $name);

Returns the 1-based x coordinate(s) of a column / span in the column
/span set of a table, or dies if the named column / span does not
exist. These functions cache results. $row is a C<row> node object,
and $name must match a C<colname> attribute in an applicable
C<colspec>, resp. a C<spanname> attribute in an applicable C<spanspec>
(see the CALS table model in L<SEE ALSO>). C<table_getcolXbyname>
applies C<colspec> overloading according to the CALS semantics (see
L</table_getcolspecbyX>).

=item my $colspec = table_getcolspecbyX($row_or_entry, $x)

Returns the C<colspec> in vigor for the specified, 1-based X
coordinate, or undef if no such C<colspec> is in the
document. Overloading of <colspec> sub-elements in C<thead> or
C<tfoot> is handled according to the CALS specification, that is, if
there is any C<colspec> at C<thead> or C<tfoot> model, they shadow the
above ones at C<tgroup> level entirely, and only the inner set is then
taken into account (e.g. shadowing, not merging, occurs when
overloading).

Note that CALS dictates that there should not be more than one colspec
for a given column, so there is no discussion of list context for this
function.
=item my $spanspec = table_getspanspecbyX($row_or_entry, $xstart, $xend)

=item my @several_spanspecs = table_getspanspecbyX($row_or_entry, $xstart, $xend)

Returns the. C<spanspec> in vigor for the specified, 1-based X
coordinates, or undef if no such C<spanspec> is in the document. In
list context, I<table_getspanspecbyX()> may return several different
spanspecs, in document order - in scalar context, in case of a tie,
this function would only return the last relevant one in document
order.

=item my $colspec = table_getspecbyentry($entry, $leftcolumn);

=item my $colspec = table_getspecbyentry($entry, $leftcolumn, $nojusthappen);

Returns the "best" (see below) <colspec> or <spanspec> element node
object associated with the column or group of columns spanned by
$entry, or undef if there is no such colspec or spanspec. $leftcolumn
(mandatory) is to be the 1-based column number at which $entry starts
(the caller, which is typically L</typeset_tablerow>, must know
this). Useful for querying style parameters from the parent column.

$entry may either refer to the result by an explicit C<colname> or
C<spanname> attribute in the document, or alternatively, unless
$nojusthappen is set to a true value, it may also "just happen" to
occupy the same column set.

In case of multiple possible outcomes to this function, the
"nominative" specs have priority over the "just happening" ones, the
spanspecs have priority over the colspecs, and C<spanspec>s coming
last in document order have priority in the "just happening" mode.
=back

=head2 Overridable function references

Extension authors may wish to re-use part of this stylesheet's
functionality at a sub-template level: typically, one may want to
alter the outlook of tables without having to duplicate the tedious,
stateful table filling algorithm that transcodes XML CALS tables into
LaTeX. This stylesheet supports that by defining overridable function
references at appropriate points, that extension authors may replace
with their own implementation (see L</Modification points>).

=head3 Pluggable LaTeX

=over 4

=item my $outputtext = &$typeset_pageref($node,$linkend);

Typesets a reference containing a page number, to be put right after
the \ref{$linkend} in the typesetting of $node, wich is an <xref>,
without an intervening space. Possible values are " (page
\pageref{$linkend})" (mind the leading space) or something like that,
or the empty string if you don't want pagerefs. The default function
tries to be smart and avoid the double closing parentheses problem
when the <xref> is itself between parentheses. $linkend will be passed
properly escaped, in such a way that outputting it to TeX in forms
such as "\\ref{$linkend}" and "\\pageref{$linkend}" without any further
transformation will produce the correct links.

=item my $outputtext = &$maketitle($title,\@subtitles,@authors);

This function shall typeset a titlepage (to be put just after the
\begin{document}). If not set, the standard \title, \author,
\maketitle mechanism of LaTeX will be used instead. zero, one or more
subtitles may be passed as a list reference in the second argument.

=item &$typeset_bibentry($node,$t,$lang);

This function shall typeset a <biblioentry> or <biblioset>, ignoring the
<biblioset> children. $node is the node to typeset in language $lang. There
is a concept of $t->{pre} and $t->{post} analogous to the second argument
of a testcode function; the semantics is that when an article and its
proceedings are to be typeset together, the result will be made up with
$tarticle->{pre}, $tproceedings->{pre}, $tproceedings->{post} and
$tarticle->{post} (which is the normal way in french and in english, so
that page numbers and the like appear last).

The return value is ignored. Unrecognized element children should be
appropriately warned.
=back

=head3 Pluggable table rendering

=over 4

=item my $outputtext = &$typeset_tablerow($style,@row);

This function shall typeset a row in a table, given a style (which is
either 'thead', 'tbody' or 'tfoot' --- typesetting happens in that
order), and a list of hashrefs containing a description of the cells
in this line: $row[0]->{height} and $row[0]->{width} contain the
dimensions of the cell, and $row[0]->{cell} contains either undef (a
blank cell - in this case height and width are always 1) or a
reference to the XML::XPath::Element::Node object for this cell (an
<entry> tag - <entrytbl>s are not supported yet).

The entries are positionned according to their upper left corner;
elements in @row that have an undef ->{cell} represent coordinate
points under a multiple-cell entry, to be skipped. @row is guaranteed
to be of the same width as the whole table. Warning, though, many
XPath functions (and functions in this stylesheet) start numbering at
1, while Perl starts numbering at 0; the code for your very own
version of &$typeset_tablerow should therefore probably start like
this:

    my ($style, @row)=@_;
	for(my $colnum=1; $colnum <= (scalar @row); $colnum++) {
		my $elem=$row[$colnum - 1];
        # Do stuff
    }

=item my $outputtext = &$typeset_tablerule($style,\@rowbefore,\@rowafter);

This function shall typeset a separator between two rows. It also gets
called before the first row in a group (the second parameter is then undef),
and after the last row in a group (the first parameter is undef). A I<group>
is the amount of rows represented by a whole <thead>, <tbody> or <tfoot>
element. The contents of the lists pointed to by the second and third
parameters (if defined) are not to be modified, and have the same structure
as @row above. $style is as above.

=item my $outputtext = &$typeset_tableframe($tgroup,$headtxt,$bodytxt,$foottxt);

This function shall re-order $headtxt, $bodytxt and $foottxt (which
are rendered TeX snippets for their respective parts of the $tgroup
element node object, or undef if said <tgroup> lacks one of them) and
eventually produce a valid overall TeX code for the whole table. This
function is B<not> responsible for outputting the C<\begin{table}> or
C<\end{table}> stuff; on the other hand, it shall render the table
caption and the cross-reference label(s) (in $fancytables mode
only). It had better pay attention to the value of the global variable
$fancytables, since the surrounding TeX table frame will be very
different according to its boolean value (tabular vs. longtable).

By default, the function Does The Right Thing for multipage tables to
work properly with longtable (if enabled).
=item my $outputtext= &$typeset_tablecolumnpattern($node,$kind,$tgroup,$width);

This function shall typeset the TeX column specification, this is, the
"c|" part of "\begin{table}{c|}". The "|" after the "c" is meant:
indeed, the CALS specification dictates that columns, spans and
entries specify the rulings which lie on their right, except for the
rightmost column (that you need not worry about; the stylesheet will
take care of removing any separator material at the end of your column
pattern if needed).

This function shall apply both to <colspec> nodes (in order to render
the TeX table header), <spanspec> nodes (for \multicolumn patterns
inside the table) and <entry> nodes (for another, one-column
\multicolumn that is the only way in TeX to typeset one cell centered,
for example, when all the others in the same column are
left-justified). $kind will be set to either "colspec", "spanspec" or
"entry", respectively. The first argument may be undef for columns
that don't have a colspec, and for multicolumn cells that do not
specify a spanspec. In this case, it is still possible to get
typesetting data using $tgroup, which always contains an element node
object pointing to the table's <tgroup> element.

By default, &$typeset_tablecolumnpattern() handles the 'colwidth' and
'align' attributes only. A width may also be specified by caller using
the optional $width argument, in which case
&$typeset_tablecolumnpattern() should attempt to honor it by priority.
=back

=head2 Self-test

The I<integrationtest()> function tests the behaviour of foreign
packages that this stylesheet depends on (namely Perl itself
for the UTF8-tainting issues, and I<XML::XPath> for minor API
issues). The following derived stylesheet, when run on any document,
will produce a text output compatible with L<Test::Harness>:

E<32>E<32><% our $inhibitOutput; $inhibitOutput++; %I<>>

E<32>E<32><!--#I<>include file="docbook2latex.xps"-->

E<32>E<32><% integrationtest() %I<>>
=head1 DOCBOOK EXTENSIONS

The I<tgroupstyle> attribute of <tgroup> nodes is interpreted as a
comma-separated list of LaTeX commands to wrap all cells with. A
useful example is "footnotesize", for large tables.

=head1 NONSTANDARD DOCBOOK CONSTRUCTIONS

When using a format attribute "linespecific" in a <graphic> element,
the LaTeX mechanism of selecting a file by trying various extensions
is used. In this case, and contrary to what the DTD documentation
says, one should omit the extension in the "fileref" attribute.

Cross references are rendered in a context-sensitive way which is much
more like Perl's DWIM (Do What I Mean) than XML's OTFA
(One Template Fits All): the stylesheet parses the surrounding text to
determine which one of "Figure 3.2, page 42", "Figure 3.2 (page 42)"
or "3.2 (page 42)" is the correct rendering for <xref linkend="FIG-3-2">.
This is to overcome a design limitation in the DTD spec, which make
<xref>s inappropriate for any language but english.

The words "TeX" and "LaTeX" are rendered as you might imagine they
should. This is the only form of "semantic kerning" that should occur
in the stylesheet, though (e.g. "---" really produces 3 dashes in the
DVI and is not he same as "&mdash;" in the XML source).
=head1 BUGS / TODO / LIMITATIONS

Only a subset of DocBook is implemented. Adding tags is easy most of
the time though.

MediaObject's are the only portable, kosher way of dealing with
multi-format graphics (such as PostScript® vs. PNG in PDF's). They are
not implemented.

Bibliography support is far from optimal and will result in bogus
punctuation and label spacing every so often.

There is no support for variadic typesetting of characters according
to the language (for example, &hellip; is rendered the same way under
french and english, but shouldn't). Using additional character
packages on-demand (that is, usepackage'ing them only when some
Unicode characters are present in the input) isn't possible. Both
restrictions stem from the flat Unicode character space in XML that
disregards the level of strangeness of character entities (e.g. it is
impossible to construct an XPath formula meaning "give me all strange
characters in this document"). Building a list of all characters in
the document from Perl would be a solution, although I cannot think of
an efficient way of doing that.
=head1 SEE ALSO

XPathScript documentation:

  http://axkit.org/docs/xpathscript/guide.dkb

XPath documentation from W3C:

  http://www.w3.org/TR/xpath

The Docbook DTD:

  http://www.docbook.org/tdg/en/html/docbook.html

The CALS table model:

      http://www.oasis-open.org/specs/a502.htm

Unicode character table (needed to add more character support into a
stylesheet):

  http://www.unicode.org/charts/charindex.html

Ditto, less complete but more LaTeX-friendly:

  http://www.bitjungle.com/~isoent/
=head1 COPYRIGHT

This program is copyright (C) Dominique Quatravaux
<dom@idealx.com>, all rights reserved. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.



=end devel

=head1 AUTHORS

=over 4

=item *

Yanick Champoux <yanick@cpan.org>

=item *

Dominique Quatravaux <domq@cpan.org>

=item *

Matt Sergeant <matt@sergeant.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2008, 2007 by Matt Sergeant.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
<% # -*-perl-*-

# XPathScript stylesheet for Docbook 4.1.2, LaTeX output.
# Â©-IDEALX
# http://www.idealx.org/DocBkXML2LaTeX/
#
# >; # Help Emacs out

# Perl dependencies:
require 5.6.1;
use XML::XPathScript 0.14;
use strict;

warn 'This is $Id: docbook2latex.xps 32928 2006-02-01 17:59:52Z dom $'.
	"\n";
my $parser_version = do { no strict "refs";
				   ${$XML::XPathScript::XML_parser."::VERSION"} };
	warn "Using $XML::XPathScript::XML_parser version $parser_version, XML::XPathScript version $XML::XPathScript::VERSION\n";

# Output from this stylesheet is Latin-1, regardless of locale.
binmode(STDOUT);

#####################################################################
#####################################################################
###########################  CUSTOMIZATION  #########################
#####################################################################
#####################################################################

# Please consult the POD doc instead of modifying things by hand.
# More document-dependent modifications of these variables happens below,
# look for "DOCUMENT-DEPENDENT SETTINGS".


# Do we want lone <glossterm>s to appear in the index?
our $glosstermsinindex=1;

# These are references to functions that take a style parameter
# (either 'thead', 'tbody' or 'tfoot') and a list of hashes representing
# the rows of a column (see POD documentation below).
our $typeset_tablerow;
our $typeset_tablerule;
our $typeset_tableframe;

# This function typesets the "c|" style table header (as in \begin{table}{c|}).
our $typeset_tablecolumnpattern;

# Character styles of many uses.
our %character_tt;
our %character_emph;
our %character_ss;






# Tags that are not directly handled by the stylesheet (see POD doc).
# This is a read-only value; modifying it from a derived stylesheet
# has no effect.
our @abstracttags=qw(title subtitle titleabbrev biblioset screeninfo);

# Tags that block footnotes (this variable is filled in in the stylesheet
# code proper).

# Tags that may produce footnotes (this variable is filled in in the stylesheet
# code proper).
our @footnote_producers;


# Support for the DocBook2LaTeX compilation suite - See comments in
# images/Makefile
if ($dvidriver =~ m/^dvipdfm/i) {
	$TeXkludges .= <<'DECLARE';
\DeclareGraphicsExtensions{.epsf,.png,.jpg}
DECLARE
}


if (findnodes('//screenco') || findnodes('//programlistingco')) {
	$TeXpreamble .= <<'LINE_COUNTING';
%% Stuff below shamelessy lifted from lineno.sty, from CPAN.
\newcounter{linenumber}

\newdimen\linenumbersep
\newdimen\linenumberwidth
\linenumberwidth=10pt
\linenumbersep=10pt

\def\linenumberfont{\normalfont\tiny\sffamily}

%% This macro's source code is lifted too, but the name is an invention
\makeatletter
\def\markLineLeft{%
   \hbox to\z@{\hss\linenumberfont\the\c@linenumber\hskip\linenumbersep}\advance\c@linenumber\@ne
}
\makeatother

LINE_COUNTING
}



####################### DOCUMENT-DEPENDENT SETTINGS ###################

if (findnodes('//indexterm') || findnodes('//glossary')) {
	push @tablesatend,"printindex" unless findnodes('//index');
	push @packages,"makeidx";
	$TeXpreamble.="\\makeindex\n";
};

push @tablesatbeginning,"listoftables" if (findnodes('//table'));
push @tablesatbeginning,"listoffigures" if (findnodes('//graphic'));

if (my ($node)=findnodes('//*[@lang="fr"]')) {
	push @packages, ["babel" => "francais"];
};


######################################################################
######################################################################
#############################  PIPEWORK  #############################
######################################################################
######################################################################

our $inhibitOutput;

# Load some functions from the Carp package on demand.
sub carp    { require Carp; goto &Carp::carp; }
sub confess { require Carp; goto &Carp::confess; }
sub croak   { require Carp; goto &Carp::croak; }
sub cluck   { require Carp; goto &Carp::cluck; }



sub reload_uniconvs {
	$noninvarchar=_RE_of_uniconvs(\%uniconvs);
}

reload_uniconvs();

# warning or dying with a message that tells where in the document the
# problem is.

sub warn_at {
	my $path=get_xpath_of_node(shift);
    my (undef, $file, $line) = caller();
    warn ("$path:\n     " . shift . " in $file line $line\n");
};

sub die_at {
	my $path=get_xpath_of_node(shift);
    my (undef, $file, $line) = caller();
    die ("$path:\n     " . shift . " in $file line $line\n");
};

##### Bugware management beyond Unicode issues

# XPath spec stipulates that backward axes (to which preceding::
# belongs) have their nodes sorted in reverse document order. This is
# not what happens with XML::XPath 1.12 and 1.13. This stylesheet
# breaks if that bug gets corrected in XML::XPath (see the
# <orderedlist> template for example)

sub reorder_backaxis {
	my ($direction,@nodes)=@_;
	die "Unknown semantics for backward axes in list context, ".
	  "update the reorder_backaxis() function" if
		($XML::XPath::VERSION gt 1.13);

	if ($direction =~ m/^back/i) {
		return (reverse @nodes);
	} else {
		return @nodes;
	};
}


# Test all the Unicode and XPath assumptions this stylesheet makes.

sub integrationtest {
	print "1..9\n";

	print "ok 1\n" if ! is_utf8_tainted(" ");

	my $utf8=do { use utf8; "ÃÂ©" }; # literal e acute in UTF-8
	print "ok 2\n" if is_utf8_tainted($utf8);

	require Unicode::String;
	my @codes=Unicode::String::utf8($utf8)->unpack();
	print "ok 3\n" if ( (@codes == 1) && ($codes[0] == 233) );

	$utf8=utf8tolatin1($utf8);

	print "ok 4\n" if !is_utf8_tainted($utf8);

	print "ok 5\n" if ($utf8 eq "Ã©");

	print "ok 6\n" if $XML::XPath::VERSION le '1.13'; # see reorder_backaxis()

	# Regression tests
	print "ok 7\n" if 
	  (!is_utf8_tainted("Documentation d<39>administration de IDX<45>ReverseProxyÃ©"));

	print "ok 8\n" if (is_utf8_tainted("\x{263A}"));

	print "ok 9\n" if ("" eq utf8tolatin1("\x{263A}"));

	1;
}

################### NON-TEMPLATE FORMATTING INSTRUCTIONS ##############

XML::XPathScript->current()->binmode();
XML::XPathScript->current()->interpolating(0);

$t->{"comment()"}->{testcode} = sub {
    my ($self, $t) = @_;
	$t->{post}="";

	my $value=utf8totex($self);
    $value =~ s/^/%/gm;
    $t->{pre} = $value;
};


#################### Enhancements to XML::XPathScript ################

sub call_template {
	my ($self,$t,$template)=@_;

	if (defined(my $sub=$template->{testcode})) {
		return &$sub($self,$t);
	} elsif (exists $t->{prechild} || exists $t->{prechildren} ||
			 exists $t->{postchild} || exists $t->{postchildren}) {
		warn_at $self,"call_template: cannot handle this sort of templates yet.\n";
		$t->{pre}="";
		$t->{post}="";
		return 1;
	} else {
		$t->{pre}=$template->{pre};
		$t->{post}=$template->{post};
		return 1;
	};
}

######################################################################
######################################################################
######################   TEMPLATE DEFINITIONS   ######################
######################################################################
######################################################################

# There is roughly one template for each tag type. To add support for
# a new tag type (see http://www.docbook.org/tdg/en/html/),
# take example from an existing 'testcode' subroutine and the XPathScript
# documentation (http://axkit.org/docs/xpathscript/guide.dkb).



####
#### Useful functions and variables (as if they always weren't)
####


sub TeXlength {
	my ($doclength, $starlength)=@_;
	$starlength ||= '\fill';

	if ($doclength =~ m/\+/) {
		carp "Cannot parse length $doclength right now (CODEME)";
		$doclength =~ s/\+(.*?)$/$1/g;
	}

	my ($docunit, $starunit);
	($doclength,  $docunit)  = ($doclength  =~ m/([0-9.]+)?([A-Za-z\\%*]+)/)
	  or do {
		  carp "Cannot parse Docbook length $doclength";
		  return $starlength;
	};
	($starlength, $starunit) = ($starlength =~ m/([0-9.]+)?([\\a-z]+)/) 
	  or do {
		  carp "Cannot parse standard length $starlength";
		  ($starlength, $starunit)=(1, "\fill");
	};

	$doclength = 1 if (!defined $doclength);
	$starlength = 1 if (!defined $starlength);

	if ($docunit eq "%") {
		$doclength = $doclength / 100;
		$docunit = "*";
	}

	if ($docunit eq "*") {
		return utf8tolatin1(($doclength*$starlength).$starunit);
	} else {
		$docunit =~ s/px/mm/g; # Sure we can do better. Someday.
		return utf8tolatin1("$doclength$docunit");
	}
}


sub flatten_textnodes {
	my ($self,$path)=@_;
	my $plaintext=join(" ",map 
					   {utf8tolatin1($_)}
					   (findnodes(($path or ".//text()"),$self)));
	$plaintext =~ s/\s+/ /gs;
	$plaintext =~ s/^ //; $plaintext =~ s/ $//;
	$plaintext =~ tr/ÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃ¡Ã Ã¢Ã¤Ã§Ã©Ã¨ÃªÃ«Ã­Ã¬Ã®Ã¯Ã±Ã³Ã²Ã´Ã¶ÃºÃ¹Ã»Ã¼Ã½Ã¿/AAAACEEEEIIIINOOOOUUUUYaaaaceeeeiiiinoooouuuuyy/;
	return $plaintext;
}


####
#### The fallback element handler
####

$t->{'*'}->{showtag}=0;  # This also suppresses an Unicode effect

#Â The default behaviour is to output a warning but still process the
# contents.

{
my %unknowntags;
$t->{'*'}->{testcode}=sub {
	my ($self,$t)=@_;
	my $nom=findvalue("name()", $self);

	return 1 if (! "$nom"); # root node

	return 1 if ($unknowntags{$nom});
	my $message="Unhandled tag $nom";
	$message .= " (please modify docbook2latex.xps!!! It is not that hard!)" if
	  (! %unknowntags);
	$unknowntags{$nom}++;
	warn_at $self, "$message\n";

	return 1;
};

} # End of scope for %unknowntags

####
#### Element types not handled by the apply_templates() mechanism
####

{
my %abstractwarned;
foreach my $tag (@abstracttags) {
	$t->{$tag}->{testcode}=sub {
		my ($self, $t)=@_;
		my $pere=findvalue("name(..)", $self);

		return 1 if ($abstractwarned{$pere});
		$abstractwarned{$pere}++;
		warn_at $self, "The $tag type is not to be handled directly
      (modify the handler of the father instead: $pere)\n";
		return 1;
	};
}

} # end of scope for %abstractwarned

#######################################################################
####
####                Character-level typesetting
####

our %character_slant=(
    pre=>'\textsl{',
	post=>'}',
);

our %character_sans=(
    pre=>'\textsf{',
	post=>'}',
);


foreach (qw(foreignphrase citetitle)) { $t->{$_} = {%character_emph}; };

foreach (qw(literal email command application citerefentry
            constant token function option olink systemitem
		    classname type)) {
	$t->{$_} = {%character_tt};
};

foreach (qw(varname replaceable)) {
	$t->{$_}={%character_slant};
};

foreach (qw(guilabel guibutton guimenu guimenuitem guisubmenu keysym)) {
	$t->{$_}={%character_sans};
};

$t->{keycombo}->{testcode}=sub {
	my ($self, $t)=@_;
	$t->{post}="";
	$t->{pre}=join("+", map {apply_templates($_)} (findnodes("*",$self)));
	return -1;
};

$t->{phrase}->{pre}="";
$t->{phrase}->{post}="";

my $hyphenable_texttt=sub {
	my ($self,$t)=@_;

	$t->{pre}="\\texttt{";
	$t->{post}="}";
	foreach my $subnode (findnodes("node()",$self)) {
		if (is_text_node($subnode)) {
			my ($intitle) = findnodes("ancestor::title",$self);
			if ($intitle) {
				$t->{pre}.=utf8totex($subnode); # lest LoF gets berserk
			} else {
				$t->{pre}.=utf8totex($subnode,
									 {
									  ord("/")=>'/\allowbreak{}',
									  ord(":")=>':\allowbreak{}',
									  ord(",")=>',\allowbreak{}',
									  ord(".")=>'.\allowbreak{}',
									 });
			};
		} else {
			$t->{pre}.=apply_templates($subnode); # Up to child
			# elements to take precautions for respecting verbatim
			# style, if appropriate.
		};
	};

	return -1;
};

foreach (qw(filename olink)) {
	$t->{$_}={testcode=>$hyphenable_texttt};
}

$t->{acronym}->{pre}="\\index{";
$t->{acronym}->{post}="}";

$t->{index}->{pre}="";
$t->{index}->{post}="\\printindex\n";



$t->{manvolnum}->{pre}="(";
$t->{manvolnum}->{post}=")";

$t->{trademark}->{post}="\\texttrademark{}";

####
#### Footnotes
####

# Whew. The POD boasts about being able to do that in functional
# style, but we save neither the recursive pain nor the use of a local
# variable set in a side-effective fashion (for lack of an XSLT-like
# parameter dictionnary that would allow closures as members).

####
#### Subscripts, superscripts
####

$t->{subscript}->{pre}="\\ensuremath{_{\\mbox{";
$t->{subscript}->{post}="}}}";

$t->{superscript}->{pre}="\\ensuremath{^{\\mbox{";
$t->{superscript}->{post}="}}}";

####
#### Misc.
####

# Needs handling of the "class" attribute
$t->{sgmltag}->{pre}="\\texttt{<";
$t->{sgmltag}->{post}=">}";


###########################################################################

####
####              Paragraph-level typesetting
####

$t->{'formalpara'}->{testcode}=sub {
	my ($self,$t)=@_;

	$t->{pre}=listtitle($self);

	$t->{post}="";

	return '*[name()!="title"]';
};


####
#### Displayed environments
####

our %boxlabels=
	  (en=>{
			note=>"Note",
			example=>"Example",
			tip=>"Tip",
			warning=>"Warning",
			important=>"Important",
			caution=>"Caution",
			},
	   fr=>{
			note=>"Note",
			example=>"Exemple",
			tip=>"Conseil",
			warning=>"Attention",
			important=>"Important",
			caution=>"Prenez garde...",
		   },
	   );

our %boxstyles=(
				tip=>"ovalbox",

				note=>"framebox",
				example=>"framebox",

				warning=>"doublebox",
				important=>"doublebox",

				caution=>"shadowbox",
			   );

foreach my $tagname (keys %boxstyles) {
	$t->{$tagname}->{testcode}=sub {
		my ($self,$t)=@_;
		my $title=apply_templates_under("title",$self) ||
		  ($boxlabels{langofnode($self) || "en"}->{$tagname});
		$t->{pre}=sprintf(<<'BOX',$boxstyles{$tagname},$title);
\begin{quote}
\%s{\parbox{\linewidth}{
\textbf{%s}
\smallskip

BOX
		$t->{post}="}}\n\\end{quote}\n";
		return '*[name()!="title"]';
	};
};


$t->{epigraph}->{testcode}=sub {
	my ($self, $t)=@_;
	$t->{pre}="\\begin{quote}\\sl{}\n";
	$t->{post}="\\end{quote}";
	if (my ($wiseguy)=findnodes("attribution", $self)) {
		$t->{post}.=apply_templates($wiseguy);
	};
	return '*[name()!="attribution"]';
};

$t->{attribution}->{pre}="\\begin{flushright}\n";
$t->{attribution}->{post}="\\end{flushright}\n";

# Remarks are not boxed comments, but draft notes (maybe typeset them
# in the margin ?)
$t->{remark}->{pre}=$t->{remark}->{post}="";


####
#### Misc. lists
####

;


$t->{glosslist}->{pre}='\begin{description}';
$t->{glosslist}->{post}='\end{description}';

$t->{glossterm}->{testcode}=sub {
	my ($self,$t)=@_;
	if (my ($parent)=findnodes("parent::glossentry",$self)) {
	    if(findnodes("parent::glosslist",$parent)) {
		# This is for typesetting glossterm's inside glosslist's...
		$t->{pre}='\item[';
		$t->{post}='] \\ \\\\'."\n";
	    } else {
		$t->{pre} =   "\\subsection*{".
		  flatten_textnodes($self)."}\n\\index{";
		$t->{post}="}\n\n";
	    }
	} else {
		# ... but glossterm's may be "on the loose" in a <para> too.
		$t->{pre}='\textbf{';
		$t->{post}='}';

		if ($glosstermsinindex) {
			$t->{post}.=sprintf('\index{%s@%s|textbf}',
								flatten_textnodes($self),
								apply_templates_under($self));
		};
	};
	if (my $label=thelabel($self)) {
		$t->{pre}.=" $label";
	};
	return 1;
};

$t->{glossdef}->{pre}="";
$t->{glossdef}->{post}="";

$t->{glossentry}->{testcode}=sub {
	my ($self,$t)=@_;
	$t->{pre}=thelabel($self);
	$t->{post}="\n";
	return 1;
};



####
#### Segmentedlists in list style (table style is not supported)
####

$t->{segmentedlist}->{testcode}=sub {
	my ($self, $t)=@_;
	my @titres=map {apply_templates_under($_)} (findnodes("segtitle",$self));

	$t->{pre}=thelabel($self)."\\begin{itemize}\n";

	foreach my $seglistitem (findnodes("seglistitem",$self)) {
		my $textitem="\\item";
		if (my $label=thelabel($seglistitem)) {
			$textitem.=" $label";
		};
		$textitem .= "\n";
		my @segs=findnodes("seg",$seglistitem);
		if ($#segs > $#titres) {
			warn_at $seglistitem,
			  sprintf("surnumerary <seg> w.r.t. the %d <segtitle>s !\n",
				scalar(@titres));
		};

		$textitem.="\\begin{description}\n";
		for(my $i=0; $i<=$#segs; $i++) {
			$textitem.=sprintf("\\item[%s :] %s\n",
							   ( $titres[$i] or " " ),
							   apply_templates_under($segs[$i]));
		};
		$textitem.="\\end{description}\n";

		$t->{pre}.=$textitem;
	};

	$t->{post}="\\end{itemize}\n";
	return -1;
};

$t->{blockquote}->{pre}="\\begin{quote}\n";
$t->{blockquote}->{post}="\\end{quote}\n";

####
#### Verbatim environments
####


sub _is_inside_verbatim {
	my ($self)=@_;
	return scalar(findnodes('ancestor::*[name()="programlisting" or name()="screen"]',
							$self));
}

$t->{userinput}->{testcode}=sub {
	my ($self,$t)=@_;
	if (_is_inside_verbatim($self)) {
		return _verbatimcode($self,$t,0);
	} else {
		$t->{pre}='\texttt{';
		$t->{post}='}';
		return 1;
	};
};

$t->{prompt}->{testcode}=sub {
	my ($self,$t)=@_;
	if (_is_inside_verbatim($self)) {
		return _verbatimcode($self,$t,0,
							 '\ensuremath{\underline{\texttt{','}}}');
	} else {
		$t->{pre}='\ensuremath{\underline{\texttt{';
		$t->{post}='}}}';
		return 1;
	};
};

$t->{computeroutput}->{testcode}=sub {
	my ($self,$t)=@_;
	if (_is_inside_verbatim($self)) {
		return _verbatimcode($self,$t,0, '\texttt{\textsl{','}}');
	} else {
		$t->{pre}='\texttt{\textsl{';
		$t->{post}='}}';
		return 1;
	};
};

####
#### Verbatim environments w/ callouts
####

# FIXME: the result is quite dull visually, and line references cannot
# be made clickable as they stand.

$t->{programlistingco}->{testcode}=
$t->{screenco}->{testcode}=sub {
	my ($self, $t) = @_;
	$t->{pre} = "\n\n\\setcounter{linenumber}{1}\n";

	$t->{pre} .= join
		("\n\n",
		 map {apply_templates($_)}
		 (findnodes("screen", $self), findnodes("programlisting", $self)));

	$t->{pre} .= "\n\n";

	return "calloutlist";
};

$t->{calloutlist}->{testcode} = sub {
	my ($self, $t) = @_;

	$t->{pre} .= "\\begin{description}\n";

	if (my ($title) = findnodes("title", $self)) {
		$t->{pre} .= sprintf("\\subsection*{%s}",
							 apply_templates_under($title));
	}

	$t->{post} .= "\\end{description}\n";

	return $_doNotProcessTitles;
};

$t->{callout}->{testcode} = sub {
	my ($self, $t) = @_;
	my @areas = map {
		my $ref = $_;
		local $_; # Fixes a dirty bug in XML::XPath::Function::id()
		my ($node) = findnodes(qq'id("$ref")', $self);
		warn_at $self, "No area definition found for $ref for this callout" if (! $node);
		(findvalue("name()", $node) eq "areaset") ?
			findnodes("area", $node) :
				$node;
	} (do { local $_ = findvalue('@arearefs', $self); split });

	# FIXME: we do not check units and therefore always assume
	# whole-line callouts. Baad, baad.
	my $itemlabel = join(", ",map {
		my $rawarea = utf8totex(findvalue('@coords', $_));
		$rawarea =~ s/\s+/--/; # Numeric interval wants n-dash
		$rawarea;
	} @areas);
	my $lang = langofnode($self);
	my $french = ($lang && $lang =~ m/^fr/i);
	if ($itemlabel =~ m/[^0-9]/) {
		$itemlabel = ($french ? "Lignes " : "Lines ").$itemlabel;
	} else {
		$itemlabel = ($french ? "Ligne " : "Line ").$itemlabel;
	};
	$t->{pre} = "\\item[$itemlabel:]\n";
	return DO_SELF_AND_KIDS;
};

#####################################################################
####
####                   Sections, subsections
####


our $extrasectionheader;


####
#### Appendix
####

# According to the DTD, an appendix can only appear in <article>s, <book>s or
# <part>s. This stylesheet doesn't handle the latter case very well, since
# appendixes are always rendered at the top level in the section hierarchy.

$t->{'appendix'}->{testcode}=sub {
	  my ($self,$t)=@_;

	  $t->{pre}="\n\n";
	  $t->{pre}.="\\appendix\\def\\appendix{}\n";

	  $t->{pre}.=sprintf('\%s{%s}',
					 $sectionnames[0],apply_templates_under('title',$self)).
					   thelabel($self)."\n";

	  my $title=apply_templates_under('title',$self);
	  my $titleabbrev; if (my ($n)=findnodes('titleabbrev',$self)) {
		  $titleabbrev=apply_templates_under($n);
	  };

	  do {$t->{pre}.=&$extrasectionheader($self,0,$title,$titleabbrev)}
		if $extrasectionheader;

	  $t->{pre}.="\n\n";

	  $t->{post}="";

	  return $_doNotProcessTitles;
};

$t->{'glossary'}->{testcode}=sub {
	  my ($self,$t)=@_;

	  $t->{pre}="\n\n";
	  $t->{pre}.="\\appendix\\def\\appendix{}\n";

	  $t->{pre}.=sprintf('\%s{%s}',
					 $sectionnames[0],apply_templates_under('title',$self)).
					   thelabel($self)."\n";

	  my $title=apply_templates_under('title',$self);
	  my $titleabbrev; if (my ($n)=findnodes('titleabbrev',$self)) {
		  $titleabbrev=apply_templates_under($n);
	  };

	  do {$t->{pre}.=&$extrasectionheader($self,0,$title,$titleabbrev)}
		if $extrasectionheader;

	  $t->{pre}.="\n\n";

	  $t->{post}="";

	  return $_doNotProcessTitles;
};

#### Abstracts
#
# There are whole-document abstracts, rendered with \begin{abstract}
# and \end{abstract}, and abstracts in bibliographies and sections,
# rendered as-is.

$t->{abstract}->{testcode}=sub {
	my ($self,$t)=@_;
	if (findnodes('parent::*[name()="articleinfo" or name()="bookinfo"]',
				  $self)) {
		$t->{pre}="\\begin{abstract}\n";
		$t->{post}="\\end{abstract}\n";
	} else {
		$t->{pre}=$t->{post}="";
	};

	return 1;
};

$t->{legalnotice}->{testcode}=sub {
	my ($self, $t)=@_;
	my $legalname = (langofnode($self) =~ m/^fr/i) ?
	  "Informations lÃ©gales" :
		"Legal information";
	$t->{pre}="{\\def\\abstractname{$legalname}\\begin{abstract}\n";
	$t->{post}="\\end{abstract}}\n";
	return 1;
};

########################################################################
####
####                  Tables and graphics
####

# This is the hardest part: hairy semantics, special cases everywhere
# in sight, and the locality properties of XML are molested quite
# deeply in the resulting TeX. A pleasure.

# The reference for DocBook tables:
#      http://www.oasis-open.org/specs/a502.htm

# Warning, <informaltable>s are tables, but <table>s are table floats!
#    informaltable ::= (graphic+|mediaobject+|tgroup+)

# Informal tables and tables share almost all their code, and besides
# the differences between the two typesetting styles are intermixed
# in the TeX output. Therefore we let the tgroup template do all the
# grunt work.

$t->{informaltable}->{pre}=$t->{informaltable}->{post}="";

$t->{table}->{testcode}=sub {
	my ($self,$t)=@_;
	$t->{pre}=$t->{post}="";
	return $_doNotProcessTitles;
};

push(@footnote_blockers, "tgroup");
$t->{tgroup}->{testcode}=sub {
	my ($self, $t)=@_;

	my $numcols=findvalue('@cols',$self);

	my $title;
	if (findvalue('name(..)',$self) eq "table") {
		$title=apply_templates_under("../title",$self);
	};
	# So "defined($title)" is a valid test for "this is a formal table".

	my @styles=split m/,/,utf8tolatin1(findvalue('@tgroupstyle',$self));

	my @TeXspecs=map {&$typeset_tablecolumnpattern($_->{colspec},
												   "colspec",$self);
				  } _table_getcolspecs_onelevel($self);

	$TeXspecs[$#TeXspecs] =~ s/\|$//;

	$t->{pre}=join("",map {"\\".$_."{"} @styles)."\n";

	if ($fancytables) {
		if (defined $title) {
			# Yet another longtable bugware... (Why did I choose this package
			# in the first place ?)
			$t->{pre}.=<<"ADDCONTENTSLINE";
\\addtocounter{table}{1}
\\addcontentsline{lot}{table}{\\protect\\numberline{\\thetable}{$title}}
\\addtocounter{table}{-1}
ADDCONTENTSLINE
		} else {
			$t->{pre}.=<<"NOINCRTABLECOUNTER";
\\addtocounter{table}{-1}
NOINCRTABLECOUNTER
		};

		$t->{pre}.="\\begin{longtable}";
		$t->{pre}.="[H]" if (!defined $title);
	} else {
		$t->{pre}.="\\begin{table}" if (defined $title);
		$t->{pre}.="\\begin{center}
\\begin{tabular}";
	};

	$t->{pre}.="{|".join("",@TeXspecs)."|}\n";

	if ($fancytables) {
		$t->{post}="\\end{longtable}\n";
	} else {
		$t->{post}="\\end{tabular}
\\end{center}
";
		$t->{post}.="\\caption{$title}
\\end{table}\n" if (defined $title);
	};

	$t->{post}.=join("",map {"}"} @styles);

	my @tablenodes;
	foreach my $nodetype (qw(thead tbody tfoot)) {
		my ($node)=findnodes($nodetype,$self);
		push @tablenodes,$node;
	};

	if (! grep {defined $_} @tablenodes) {
		warn_at $self, "Nothing in table?!";
		return -1;
	};

	my @tableTeXs;
	eval {
		foreach my $node (@tablenodes) {
			push @tableTeXs, (defined $node ? _do_tblock($node) : undef);
		};
		1;
	} || do {
		warn "$@\n";
		$t->{pre}=framederror($@);
		$t->{post}="";
		return -1;
	};

    my $tableframes = &$typeset_tableframe($self,@tableTeXs);
    die_at($self, "return value of \$typeset_tableframe is UTF8-tainted\n".
           "$tableframes")
        if is_utf8_tainted($tableframes);
	$t->{pre} .= $tableframes;
	$t->{post}.=collect_trapped_footnotes($self);

	return -1;
};


$t->{entry}->{testcode}=sub {
	my ($self,$t)=@_;

	$t->{pre}=$t->{post}="";

	# Alignment is managed in typeset_tablerow() instead.

	if (findvalue('@rotate',$self)) {
		$t->{pre}.="\\rotatebox{90}{";
		$t->{post}="}".$t->{post};
	};

	return 1;
};



# There is something really braindamaged in the CALS spec as regards
# cascading defaults: I do not guarantee I got it right (especially
# the colspec merging stuff).

{
my %cache_colspecs;

# Reads the colspec entries from a <tgroup>, <thead> or <tfoot> node
# object (specified as the only argument) and affects real x
# coordinate numbers to them.  Returns an array of { name = $name,
# colspec = $colspec } structures where $colspec's are XPath node
# objects, or possibly "undef" holes in the result array instead of
# such structures (for columns that have no name). The length of the
# result (in array context - scalar context has no meaning to this
# function) is equal to the width of the table. Beware of the 1-based
# coordinate problem: numbering of Perl lists starts at 0, but the
# Perl-wise 0th element of the return value would be numbered 1st by
# XPath and other user-visible functions of this stylesheet.

sub _table_getcolspecs_onelevel {
	my ($self)=@_;

	if (exists $cache_colspecs{$self}) {return @{$cache_colspecs{$self}}};

	my $colindex=1; my @cols;
	foreach my $col (findnodes("colspec",$self)) {
		my $cname=findvalue('@colname',$col) ||
		  die_at $self,"column nr $colindex without a name";

		do { my $c=findvalue('@colnum',$col); $colindex=$c if $c; };

		$cols[$colindex-1]={
			 name=>$cname,
			 colspec=>$col
		};
		$colindex++;
	};
	$#cols=utf8tolatin1(findvalue('@cols',$self))-1;
	$cache_colspecs{$self}=\@cols; return @cols;
}

# Returns a list of structures similar to what
# _table_getcolspecs_onelevel() does, except the fact that <thead>s
# and <tfoot>s also contain colspecs is properly accounted for
# (e.g. overloading takes place). Note that the overloading semantics
# is not merging of <colspec> sets, but a simple shadowing: The
# smallest amount of <colspec> at <thead> or <tfoot> level entirely
# shadows and voids any <colspec> at <tgroup> level (as dictated by
# CALS, in the definition of the colspec element).
sub _table_getcolspecs {
	my ($row_or_entry)=@_;

	if ($cache_colspecs{$row_or_entry}) {
		return @{$cache_colspecs{$row_or_entry}};
	};

	my ($uprow, $uprowtwice);
	my $name=findvalue("name()", $row_or_entry);
	if ($name eq "row") {
		$uprow = "..";
		$uprowtwice = "../..";
	} elsif ($name eq "entry") {
		$uprow = "../..";
		$uprowtwice = "../../..";
	} else {
		confess "expecting a <row> or <entry> node instead of <$name>";
	}

	my @up=_table_getcolspecs_onelevel(findnodes($uprowtwice,$row_or_entry));
	# @down will not find anything in <tbody> but may in <thead> or <tfoot>:
	my @down=_table_getcolspecs_onelevel(findnodes($uprow,$row_or_entry));
	# Overloading is shadowing, not merging:
	my @colspecs=(@down?@down:@up);

	$cache_colspecs{$row_or_entry}=\@colspecs; return @colspecs;
}

} # end of scope for %cache_colspecs

sub table_getcolXbyname {
	my ($row_or_entry, $name)=@_;

	confess "Wrong calling convention for table_getcolXbyname\n" unless
	  ($name && (is_element_node($row_or_entry)) );
	my $i=1;
	foreach my $col (_table_getcolspecs($row_or_entry)) {
		($col->{name} eq $name) && return $i;
		$i++;
	};
	die_at $row_or_entry, "Unknown column name $name";
}

sub table_getspanXbyname {
	my ($row_or_entry, $name)=@_;

	my ($xstart, $xend);

	die "UNIMPLEMENTED";
	return ($xstart, $xend);
}

sub table_getcolspecbyX {
	my ($row_or_entry, $x)=@_;
	confess "Wrong calling convention for table_getcolspecbyX\n" unless
	  ($x && (is_element_node($row_or_entry)) );

	my @row=_table_getcolspecs($row_or_entry);
	return $row[$x-1]->{colspec};
}

sub table_getspanspecbyX {
	my ($row_or_entry, $xstart, $xend)=@_;

	confess "Wrong calling convention for table_getspanspecbyX\n" unless
	  ($xstart && $xend && (is_element_node($row_or_entry)) );

	my ($namest, $nameend)=map {
		my $colspec=table_getcolspecbyX($row_or_entry, $_);
		defined($colspec) ? scalar findvalue('@colname', $colspec) :
		  undef
	} ($xstart, $xend);
	my @candidates=findnodes(qq'../../spanspec[\@namest="$namest" and '.
							 qq'\@nameend="$nameend"]',
							 $row_or_entry) unless
							   (!defined $namest || !defined $nameend);
	return (wantarray ? @candidates : $candidates[$#candidates]);
}

sub table_getspecbyentry {
	my ($entry, $leftcolnum, $nojusthappen)=@_;

	croak <<MESSAGE unless (findvalue('name()',$entry) eq "entry");
table_getspecbyentry must be called with an entry node as its first argument.
MESSAGE

	# For the benefit of caller:
	my $maxcol=findvalue('../../../@cols', $entry);
	unless ( ($leftcolnum >= 1) &&
			 ($leftcolnum <= $maxcol) ) {
		my $leftcolvalue = (defined $leftcolnum ? qq'"$leftcolnum"' :
							"undef");
		croak(<<MESSAGE);
table_getspecbyentry must be called with a valid column number
as its second argument (between 1 and $maxcol, instead of $leftcolvalue).
MESSAGE
	}

	if (my $spanname=findvalue('@spanname',$entry)) {
		my ($span)=findnodes
		  (qq'../../../spanspec[\@spanname="$spanname"]',$entry);
		die_at $entry, "unmatched spanname reference" unless (defined $span);
		return $span;
	} elsif (my $colname=findvalue('@colname',$entry)) {
		my $x=table_getcolXbyname($colname);
		die_at $entry, "unmatched colname reference" unless (defined $x);
		return table_getcolspecbyX($entry, $x);
	}

	return undef if $nojusthappen; # Done with the symbolic references, now
	# count beans.

	my ($mincol, $maxcol) = _explicit_column_span($entry);
	if (!defined $mincol) {
		$mincol = $maxcol = $leftcolnum;
	}

	my $spanspec=table_getspanspecbyX($entry, $mincol, $maxcol);
	return $spanspec if (defined $spanspec);
	if ($mincol == $maxcol) {
		my $colspec=table_getcolspecbyX($entry, $mincol);
		return $colspec if (defined $colspec);
	}

	return undef;
}

# Computes the (1-based) interval of columns that this cell is
# interested with. Returns a pair of undef's if nothing found (caller
# then has to compute that from XML context).
sub _explicit_column_span {
	my ($entry)=@_;
	my ($mincol, $maxcol);
	my ($mincolname, $maxcolname);
	my ($row)=findnodes("..", $entry);

	if (my $spanname=findvalue('@spanname', $entry)) {
		$mincolname=
		  findvalue(qq'../../../spanspec[\@spanname="$spanname"]/\@namest',
						$entry) or
		die_at ($entry,"Nonexistent spanname or \@namest thereof: ".
				"``$spanname''");
		$maxcolname=
		  findvalue(qq'../../../spanspec[\@spanname="$spanname"]/\@nameend',
						$entry) or
			die_at ($entry,
					"Nonexistent \@nameend for span $spanname");
	} elsif ($mincolname=findvalue('@namest',$entry)) {
		$maxcolname=findvalue('@nameend',$entry) ||
		  $mincolname; # Specifying a "namest" without a "nameend",
		# even though redundant with "colname", is legit in CALS.
	} elsif (my $cname=findvalue('@colname',$entry)) {
		$mincol=$maxcol=table_getcolXbyname($row, $cname);
	};

	if ( (!defined $mincol) && $mincolname ) {
		$mincol=table_getcolXbyname($row, $mincolname);
		$maxcol=table_getcolXbyname($row, $maxcolname);
	};

	return (defined($mincol) ? ($mincol, $maxcol) : (undef, undef));
}

# Typesets a thead, tbody or tfoot.
sub _do_tblock {
	my ($self)=@_;

	my $style=findvalue("name()",$self);

	# By blind chance, rows have the same semantics as in LaTeX.
	# We just need to maintain the list of ``leaning'' rows that occupy
	# cells below themselves, and leave empty "&"s accordingly.
	my $numcols=findvalue('../@cols',$self);
	die_at ($self,"incorrect or absent cols attribute in tgroup")
	  unless ($numcols > 0);

	my $return; my @leaningrows;
	my @rows=findnodes("row",$self);
	my @thisrow; my @oldrow;

	for(my $i=0, my $row;
		($row=$rows[$i]) , ( ($i<=$#rows) || (grep {$_} @leaningrows) );
		$i++) {

		# Docbook says: "Entrys cannot be given out of order". That's
		# cool, because we are allowed to construct @thisrow from left
		# to right.  Thus @thisrow is always set up so that insertion
		# of the next cell is to begin after its last element (padding
		# with undefs if needed).
		@oldrow=@thisrow; @thisrow=();

		# Mind the case of a leaning multicolumn that goes beyond the
		# end of the table as set up in the XML source ! I don't know
		# if CALS forbids this, anyway we support it because it's
		# easy: we just invent empty rows at the end.
		my @entries=(defined $row ? findnodes("entry",$row) : ());

		for(my $j=0, my $entry;
			($entry=$entries[$j]), ($j<=$#entries);
			$j++) {
			# Warning, $j counts entries in the XML source, NOT their
			# x coordinate in the resulting table. Use scalar(@thisrow)
			# for this latter purpose; it is maintained this way.
			my $dieat="row ".($i+1).", entry ".($j+1);

			my ($mincol, $maxcol);
			eval {
				($mincol, $maxcol) = _explicit_column_span($entry);
				1;
			} || die "$@ ($dieat)";
			$mincol-- if (defined $mincol); $maxcol-- if (defined $maxcol);

			if (defined $mincol) {
				# Docbook says: columns must not overlap nor get out of range.
				die_at($self,
					   "Cell horizontally out of range (starting at column $mincol, ending at $maxcol) ($dieat)") if
				  (($mincol<0) || ($maxcol >= $numcols));

				die_at($self,
					   "Cell overlapping other multiline cells above ($dieat)")
				  if (grep {$leaningrows[$_]} ($mincol..$maxcol));

				# CALS says: columns may not be specified out of order.
				die_at($self,
					   "Cell x coordinate moving backwards ($dieat)") if
						 ($#thisrow >= $mincol);
				# Fill in skipped cells with empty slots so that they
				# still get their border drawn.
				foreach my $fill (scalar(@thisrow)..$mincol-1) {
					$thisrow[$fill]={height=>1, width=>1,
									 cell=>undef};
				};
			} else {
				# no column specified, $mincol (and $maxcol) are the first
				# available column if there are any left.
				for(my $k=scalar(@thisrow);
					(($k < $numcols) || die_at ($self,
					     "No more room for this cell ($dieat)"));
					$k++) {
					next if $leaningrows[$k];
					$mincol=$maxcol=$k;
					last;
				};
			}

			die_at($self,"Reversed interval for span ($dieat)") if
				  ($mincol > $maxcol);

			# Update parameters for the next iteration

			my $morerows=(findvalue('@morerows',$entry) || 0);
			foreach my $k ($mincol..$maxcol) {
				$leaningrows[$k]=$morerows+1;
			}

			$thisrow[$mincol]={height=>$morerows+1, width=>$maxcol-$mincol+1,
							   cell=>$entry};
			$#thisrow=$maxcol; # Automatically fills slots "under" the new
			# cell with undef's.

		}; # END loop over @entries and $j

		# Maybe the last <entry> did not reach the
		# rightmost column. Fill with empty cells.
		foreach my $fill (scalar(@thisrow)..$numcols-1) {
			$thisrow[$fill]={height=>1, width=>1,
							 cell=>undef} unless ($leaningrows[$fill]);
		};

		my $tablerule =
            &$typeset_tablerule($style, (@oldrow ? \@oldrow : undef),
                                \@thisrow);
        die_at($self, "top typeset_tablerule() is UTF8-tainted".
               " ($tablerule)") if (is_utf8_tainted($tablerule));
        $return .= $tablerule;

        my $tablerow = &$typeset_tablerow($style,@thisrow);
        die_at($self, "typeset_tablerow() is UTF8-tainted".
               " ($tablerow)") if (is_utf8_tainted($tablerow));
		$return .= $tablerow;

		# We move one step down, updating @leaningrows accordingly:
		map {$_-- if $_} @leaningrows;


	};# end for @rows $i

    my $tablerule = &$typeset_tablerule($style, \@thisrow, undef);
    die_at($self, "bottom typeset_tablerule() is UTF8-tainted".
           " ($tablerule)") if (is_utf8_tainted($tablerule));
	$return .= $tablerule;

    # Bogosity filter for all of the above:
	die_at($self, "_do_tblock is UTF8-tainted ($return)") if
	  (is_utf8_tainted($return));


	return $return;
}

####
#### Default table rendering functions
####

our $typeset_tablerow=sub {
	my ($style,@row)=@_;

	my @texts;
	for(my $colnum=1; $colnum <= (scalar @row); $colnum++) {
		my $elem=$row[$colnum - 1];
		do { push @texts,""; next} unless
		  (defined($elem) && defined($elem->{cell}));

		my $text=apply_templates($elem->{cell});

		my $texwidth="*";
		my $failed=0; my $unit=undef; my $total=0;
#warn "Computing width (Columns $colnum to $colnum+$elem->{width}-1)";
		foreach my $x ($colnum..$colnum+$elem->{width}-1) {

			my $colspec=table_getcolspecbyX($elem->{cell}, $x);

#warn "Is there a column?";
			do {$failed++; last} if (!defined $colspec);
			my $colwidth = utf8tolatin1(findvalue('@colwidth',$colspec));
#warn "Does $colwidth match RE?";
			do {$failed++; last} unless
			  ($colwidth &&
			   ($colwidth =~ m/^(\d*(?:\.\d*)?)(cm|mm|ex)$/));

#warn "Yes! ($1/$2)";

			if (!defined $unit) {
				$unit=$2;
			} else {
				do {$failed++; last} unless ($unit eq $2);
			}

			$total += $1;
#warn "Added column, total is now $total";
		}
		$texwidth="$total$unit" unless ($failed);
#warn "Grand total is $texwidth";

		my $localalign;
		if (findvalue('@align',$elem->{cell})) {
			if ($fancytables) {
				$localalign=&$typeset_tablecolumnpattern($elem->{cell},
					 "entry",findnodes("../../..",$elem->{cell}), $texwidth);
			} else {
				warn_at $elem->{cell},
				  "individual cell alignment is only done in fancytables mode yet.";
			}
		}


		# Those style elements require array context, since the height
		# and width are not easily available from the <entry> template.
		# However, other fancy stuff (such as rotation) are, and should
		# be handled there instead.
		if ($elem->{height}>1) {
			if ($fancytables) {
				$text=sprintf('\multirow{%d}{%s}{%s}',
							  $elem->{height},$texwidth, $text);
			};

			if ($localalign && ! our $warned_multiline_cells) {
				warn_at $elem->{cell},
				  "I don't know how to align multiline cells in TeX";
				$warned_multiline_cells++;
			};
		};

		if ($elem->{width}>1) {
			my $spanspec=table_getspecbyentry($elem->{cell}, $colnum);
			$colnum += $elem->{width} - 1;

            my $columnpattern;
            if ($localalign && $elem->{height} == 1) {
                $columnpattern = $localalign;
            } else {
                $columnpattern = &$typeset_tablecolumnpattern
				    ($spanspec, "spanspec",
                     findnodes("../../..", $elem->{cell}),
					 $texwidth);
                die_at($self,
                       "_typeset_tablecolumnpattern is UTF8-tainted".
                       " ($columnpattern)")
                if (is_utf8_tainted($columnpattern));
            }

			$text = sprintf('\multicolumn{%d}{%s%s}{%s}',
                            $elem->{width},
                            "|", # TODO: handle table struts correctly
                            $columnpattern,
                            $text);
		};

		push @texts, $text;
	};


	return join(" & ",@texts)." \\\\\n";
};

our $typeset_tablerule=sub {
	my ($style,$prevrowref,$nextrowref)=@_;

	return "\\hline\n" if ((!defined $prevrowref) ||
	  (!defined $nextrowref));

	my $return=""; my $holes;
	for(my $i=0;$i<=$#$nextrowref;) {
		if (defined $nextrowref->[$i]) {
			$return.=sprintf('\cline{%d-%d}',$i+1,
							 $i+$nextrowref->[$i]->{width});
			$i+=$nextrowref->[$i]->{width};
		} else {
			$holes++;
			$i++;
		};
	};
	$return.="\n";
	return $holes ? $return : "\\hline\n";
};

our $typeset_tableframe=sub {
	my ($tgroup,$TeXhead,$TeXbody,$TeXfoot)=map {defined $_ ? $_ : ""} @_;

 	my $labels="\\noalign{".
	  thelabel($tgroup).thelabel(findnodes("..",$tgroup)).
		"}";

	return join("",$labels,$TeXhead,$TeXbody,$TeXfoot) if
	  (!$fancytables);

	my $title;
	if (findvalue('name(..)',$tgroup) eq "table") {
		$title=apply_templates_under("../title",$tgroup);
	};

	my $numcols=utf8tolatin1(findvalue('@cols',$tgroup));

	my ($caption,$lastcaption)=("","");
	if (defined $title) {
		($caption,$lastcaption)=map {sprintf("\\multicolumn{$numcols}{c}{}\\\\
\\caption[]{\\normalsize{$title%s}}",$_)}
		  ( (langofnode($tgroup) =~ m/fr/i) ?
			(" (\\textit{TSVP})","") :
			(" (\\textit{more})",""));
	};

	# Fix up the double rules spread over the header and body or body and
	# footer (longtable bugs ?)
	if ($TeXbody =~ s|^\s*(\\hline)||s) {
		$TeXhead.=$1;
	};

	if ($TeXbody =~ m|(\\hline)\s*$| && $TeXfoot =~ m|^\s*(\\hline)|) {
		$TeXfoot="\\noalign{\\vskip\\doublerulesep}$TeXfoot";
	};

	return <<"TEXT";
$TeXhead
\\endhead
$TeXfoot
$caption
\\endfoot
$TeXfoot
$lastcaption
\\endlastfoot
$labels
$TeXbody
TEXT
};

our $typeset_tablecolumnpattern=sub {
	my ($node,$kind,$group,$width)=@_;

	my $rightsep="|"; # Perfectible.
	do { $width ||= findvalue('@colwidth', $node) } if (defined $node);

	if ((defined $node) && $width) {
		$width=~s|\*|\\fill|;
		return sprintf("p{%s}$rightsep",utf8tolatin1($width));
	};
	my $align;
	$align=findvalue('@align',$node) if (defined $node);
	$align=findvalue('@align',$group) if (! $align);

	if ($align) {
		warn_at ( (defined $node ? $node : $group),
				  "justified paragraphs without a colwidth specified
are very poorly supported") if ( ($align eq "justify") && ! $width);
		$width ||= "2cm"; # Yuck indeed.
		my %xml2tex=(
					 "left"=>"l","center"=>"c","right"=>"r",
					 "justify"=>"p{$width}",
					);
		die "Unknown alignment style $align" unless (exists $xml2tex{$align});
		return sprintf("%s$rightsep",$xml2tex{$align});
	};

	return "l$rightsep"; # CALS says: default is to align left.
};


# Only encapsulated PostScript graphics are handled for now.

sub framederror {
	my ($error)=@_;
	$error=utf8totex($error);
	return "\\fbox{\\parbox{0.4\\columnwidth}{\\textbf{$error}}}";
}

sub centerederror {
	return '\begin{center}'.framederror(@_).'\end{center}';
}

sub multiply_TeX_dimension {
	my ($value, $factor) = @_;
	my ($val, $unit) = ($value =~ m/([0-9]+(.*))/);
	$val = $val * $factor;
	return "$val".$unit;
}

{ my $PSwarned;

sub render_graphic {
	my ($self, $factor)=@_;

	my $format=findvalue('@format',$self); $format ||= 'EPS';
	my @options;

	# Scaling, rotating, whatever.
	if (my $scale=findvalue('@scale',$self)) {
		if(defined $factor) {
			push(@options,"scale=".(($factor * $scale)/100));
		} else {
			push(@options,"scale=".($scale/100));
		}
	};
	if (my $scalefit=findvalue('@scalefit',$self)) {
		my ($defaultheight, $defaultwidth)=
		  (findvalue("name(..)", $self) eq "screenshot") ?
			qw(0.24\textheight \columnwidth) :
			qw(0.8\textheight \columnwidth);
		my $height = findvalue('@depth', $self) || "100%";
		$height = TeXlength($height, $defaultheight);
		my $width = findvalue('@width', $self) || "100%";
		$width = TeXlength($width, $defaultwidth);

		if(defined $factor) {
			$height = multiply_TeX_dimension($height, $factor);
			$width = multiply_TeX_dimension($width, $factor);
		}

		push(@options,"keepaspectratio=true","height=$height",
			 "width=$width");
	};

	my ($filerefnode)=findnodes('@fileref',$self);
	my $fileref=utf8tolatin1($filerefnode);
	# We don't want LaTeX escaping in filenames, thus the unusual form of
	# attribute evaluation.

	if (($format !~ m/^(EPS|linespecific)$/) and ($dvidriver eq "dvips")) {
		warn_at $self, "only PostScript figures are supported yet." unless
		  $PSwarned;
		$PSwarned++;
		return centerederror("Unsupported figure format $format");
	};

	if ($format eq 'EPS') {
		# Bugware for ill-formed EPS (maybe full-page PostScript?)
		# Warning, in the current implementation of
		# /usr/bin/xpathscript this workaround requires the DTD to be
		# in the current directory.
		local *EPSFILE;
		if (open(EPSFILE,"<$fileref")) {
			my ($landscape, $boundingbox);
			while(<EPSFILE>) {
				last if (! m/^%/);

				$landscape=1 if m/^%%Orientation.*landscape/i;
			};
			close(EPSFILE);

			if ($landscape) {
				push(@options,"angle=270");
			};
		} else {
			# We do not even bother warn the user, LaTeX will do it :>
		};
	}

	return sprintf("\\includegraphics%s{%s}",
					  ( @options ? ("[".join(",",@options)."]") : ""),
					  $fileref);
}

} # end of scope for $PSwarned

$t->{graphic}->{testcode}=sub {
	my ($self, $t)=@_;

	$t->{post}="";

	my $graphic=render_graphic($self);
	my $align=findvalue('@align',$self) || 'center';

	if ($align =~ m/left/i) {
		$t->{pre}="\\begin{flushleft}$graphic\\end{flushleft}\n";
	} elsif ($align =~ m/right/i) {
		$t->{pre}="\\begin{flushright}$graphic\\end{flushright}\n";
	} else {
		$t->{pre}="\\begin{center}$graphic\\end{center}\n";
	};

	return 1;
};

$t->{inlinegraphic}->{testcode}=sub {
	my ($self, $t)=@_;

	$t->{post}="";
	$t->{pre}=render_graphic($self);

	return 1;
};

####
#### Figure and table floats
####

$t->{figure}->{testcode}=sub {
	my ($self,$t)=@_;

	$t->{pre}="\\begin{figure}[H]\n";

	# This forced ordering is messy, and needs rewriting according to what
	# can really fit in a <figure> in DocBook.
	$t->{pre}.=apply_templates("graphic",$self);
	$t->{pre}.=sprintf("\\caption{%s%s}\n",thelabel($self),
					  apply_templates_under(findnodes("title",$self)));
	$t->{post}.="\\end{figure}\n";

	return qq'*[name()!="graphic" and name()!="title" and name()!="subtitle" and name()!="titleabbrev"]';

};

$t->{screenshot}->{testcode}=sub {
	my ($self,$t)=@_;

	$t->{pre}="\\begin{figure}[H]\n";
	

	if (my ($info)=findnodes("screeninfo",$self)) {
		$t->{post}=sprintf("\\caption{%s%s}\n",thelabel($self),
						   apply_templates_under($info));
	};
	$t->{post}.="\\end{figure}\n";

	return qq'*[name()!="screeninfo"]';

};


##########################################################################
####
####          Cross references, indices, bibliography
####

$t->{lot}->{pre}="\\listoftables";

my $typeset_pageref=sub {
	my ($self,$linkend)=@_;
	my ($nextnode)=findnodes("following-sibling::text()[1]", $self);
	return ", page \\pageref{$linkend}" if
	  ($nextnode &&
	   utf8tolatin1($nextnode) =~ m/^\s*\)/);
	return " (page \\pageref{$linkend})";
};

$t->{xref}->{testcode}=sub {
	my ($self, $t)=@_;


	$t->{post}='';

	my $lang=langofnode($self);

	# Gathering info about the target of the link.
	my $linkend=findvalue('@linkend',$self);
	my $linkendtex=id2label($self,"linkend");

	local $_; # Fixes a dirty bug in XML::XPath::Function::id()
	my ($targetelement)=findnodes(qq'id("$linkend")',$self);
	if (! $targetelement) {
		warn_at $self, qq'label "$linkend" not found';
		$t->{pre}=sprintf('\[label "%s" not found\]',utf8tolatin1($linkend));
		$t->{post}="";
		return -1;
	};
    my $targetelementname=findvalue("name()",$targetelement);

	# We do pagerefs too, with a twist (see perldoc).
	my $pageref=&$typeset_pageref($self,$linkendtex);

	my $txtq;
	do {
		# Rendering a string to indicate target. This is from Docbook spec...

		my $text;
		if (my $endterm=findvalue('@endterm',$self)) {
			$text=apply_templates_under(qq'id("$endterm")',$self);
		} elsif (my $label=findvalue(qq'id("$linkend")/\@xreflabel')) {
			$text=utf8tolatin1($label);
		} elsif ( ($targetelementname eq "glossterm") ) {
			$text=apply_templates_under($targetelement);

		# ... And this is from my very own fantasy.

		} elsif ($targetelementname eq "glossentry" ) {
			my ($glossterm)=findnodes("glossterm", $targetelement);
			$text=apply_templates_under($glossterm) if $glossterm;
		};

		# Quote the reference text, if any, according to language,
		# for inclusion in the formula just after "the word".
		$txtq=((!$text) ? "" :
			   ( ($lang eq "fr") ? qq '\\og{}$text\\fg{}' : "``$text''"));
	}; # End of scope for $text

	# Bogosity filter here for code above.
	die_at($self,"linkendtex is UTF8-tainted ($linkendtex)") if
	  (is_utf8_tainted($linkendtex));
	die_at($self,"txtq is UTF8-tainted ($txtq)") if (is_utf8_tainted($txtq));

	# I had quite a bit of a dilemma to figure out whether <xref
	# linkend="FIGURE-3.2"> should render as "Figure 3.2" or just
	# "3.2", given that a leading capital letter is not acceptable in
	# french. I finally settled for the following heuristics:
	#    * compute "the word" among "figure", "table", "chapter" or undef,
	#      according to current language.
	#    * if the last word of preceding text node matches "the word"
	#      or an abbreviation thereof, choose short form ("3.2").
	#    * otherwise output the word, captialized for english, and
	#      lowercase for french (rationale: "la figure so-and-so" is not
    #      supposed to be at the beginning of a sentence in french).

	my ($theword,$theregexp);

	if ($targetelementname =~ m/image|figure|pict|screen/i) {
		$theword=($lang eq "fr" ? "la figure": "Figure");
		$theregexp=q/fig(ure|)/;
	} elsif ($targetelementname =~ m/table/i) {
		$theword=($lang eq "fr" ? "la table": "Table");
		$theregexp=q/tab(le|leau|)/;
	} elsif ($targetelementname =~ m/^sect/) {
		$theword=($lang eq "fr" ? "le chapitre": "Chapter");
		$theregexp=q/(chap(itre|ter|)|sect(ion|)|par(a|agraph|agraphe|t|tie|)|Â§)/;
	}
elsif ($targetelementname =~ m/^appendix/) {
		$theword=($lang eq "fr" ? "l'annexe": "Appendix");
		$theregexp=q/(app(endice|endix))/;
	}

 elsif ($targetelementname =~ m/^(listitem)/) {
		# No word decoration/minimization in this case, but still prepend
		# the reference number.
	} else {
		# Unknown tag ? Then no word and reference number at all.
		$t->{pre}="$txtq$pageref";
		return -1;
	};

	my $protolink=join(", ","\\ref{$linkendtex}",($txtq ? ($txtq) : ())).
	  $pageref;

	my ($previoustext)=findnodes("preceding-sibling::text()[1]", $self);
	$previoustext=utf8tolatin1($previoustext) if $previoustext;
	if ($previoustext && scalar($previoustext =~ m/$theregexp\W*$/si)) {
		$t->{pre}=$protolink;
	} elsif ($previoustext && $previoustext =~ m/(?<!Cf)\.\s*$/) {
		$t->{pre}=ucfirst($theword)." $protolink";
	} else {
		$t->{pre}="$theword $protolink";
	};
	return -1;
};

####
#### Bibliography
####

$t->{citation}->{testcode}=sub {
	my ($self,$t)=@_;
	# Warning, LaTeX wants citation labels verbatim (no backslashes).
	my ($contents)=findnodes("text()",$self);
	$t->{pre}=sprintf('\cite{%s}',utf8tolatin1($contents));
	$t->{post}="";
	return -1;
};

$t->{bibliography}->{testcode}=
$t->{bibliodiv}->{testcode}=sub {
	my ($self, $t)=@_;

	my $preparetitle = _handle_section
		($self, $t,
		 -defaulttitle=>"{\\bibname}");

	# Top-level bibliography handled like an appendix (chapter numbering
	# turns to letter)
	$t->{pre}="\\appendix\\def\\appendix{}\n".$t->{pre} if
		((findvalue("name()", $self) eq "bibliography") &&
		 (section_nesting_depth($self) == 0));

	# The DTD guarantees that if we have sub-bibliodivs, we cannot
	# have direct-children entries. In this case, act like a mere
	# section.
	return $preparetitle if (findnodes("bibliodiv", $self));

	# Support for the leading <para> in a bibliography or bibliodiv.
	foreach my $prematter
		(findnodes(qq'*[not(starts-with(name(), "biblio")) and '.
				   'not(name() = "title")]',$self)) {
			$t->{pre} .= apply_templates($prematter);
		}

	my $maxlength="";
	map {my $word=apply_templates_under($_);
			$maxlength=$word if (length($word) > length($maxlength));}
		   (findnodes("//abbrev",$self));
	$t->{pre}.=sprintf(<<'BEGINBIBLIO',"M".$maxlength);
{
%%%% We deal with bibliography sections ourselves thank you.
\def\chapter*#1{{}}
\def\section*#1{{}}
\nocite{*}
\begin{thebibliography}{%s}
BEGINBIBLIO

	$t->{post}="\\end{thebibliography}\n}\n".$t->{post};

	return qq'*[starts-with(name(),"biblio")]';
};

my @_grokkedbibtags=qw(abbrev
author authorblurb authorgroup corpauthor
orgname title subtitle abstract address
publisher isbn date pubdate edition issuenum
biblioset bibliomisc);

our $typeset_bibentry; # Function pointer, see below and the POD

$t->{biblioentry}->{testcode}=sub {
	my ($self, $t)=@_;

	my ($abbrev)=findnodes("abbrev/text()",$self);
	# Warning, TeX wants bibliographic labels in pure Latin1 (no \_)
	$t->{pre}=sprintf("\n\n".'\bibitem%s{%s} ',
					  ($abbrev ? ("[".utf8totex($abbrev)."]") : ""),
					 ($abbrev ? utf8tolatin1($abbrev): "???")
					 );
	$t->{post} = "\n\n";

	# Biblioentries are typeset according to the ancestor's language -
	# I personnaly don't like mixed french/english bibitems.

	my $lang=langofnode(findnodes("..",$self));
	my @bibsets=map {
		my $tbis={};
		&$typeset_bibentry($_,$tbis,$lang);
		$tbis;
	} ($self,findnodes(".//biblioset",$self));
	# FIXME : @bibsets should be sorted.

	foreach my $tbis (@bibsets) {
		$t->{pre}.=$tbis->{pre}." ";
	};

	foreach my $tbis (reverse @bibsets) {
		$t->{post}.=$tbis->{post}." ";
	};

	foreach my $tag (qw(abstract authorblurb)) {
		my @nodes=findnodes($tag,$self);
		next if ! @nodes;
		$t->{post}.=join("\n\n","",apply_templates(@nodes));
	}

	return -1;
};

# Typesets a biblioentry or a biblioset, extracting only those informations
# that are available at this level (tying up the pieces together is the
# job of the two testcodes above).
our $typeset_bibentry=sub {
	my ($self,$t,$lang)=@_;

	# Keep them warned
	foreach my $kid (findnodes("*",$self)) {
		my $kidname=findvalue('name()',$kid);
		next if (grep {$_ eq $kidname} @_grokkedbibtags);
		warn_at $kid, "unsupported tag in bibliography $kidname\n";
	};

	# Prepare the pieces first

	my @authors=map {apply_templates($_)}
	  (findnodes('*[name()="author" or name()="authorgroup" or name()="corpauthor" or name()="orgname"]',
							$self));
	my $role=findvalue('@role',$self);
	my ($title, $subtitle, $date, $publisher, $isbn, $pubdate,
		$edition, $issuenum, $address)=map {
		apply_templates_under($_,$self)
	} (qw(title subtitle date publisher isbn pubdate edition issuenum address));

	# Then assemble them.
	if ($lang =~ m/^fr/) {
		if (@authors) {
			$t->{pre}=join(", ", @authors);
		};
		
		if ($title) {
			$title="$title --- $subtitle" if ($subtitle);
			my $typesettitle=(
				 ($role =~ m/^(proceedings|conference)$/i)?
				   "\\emph{$title}":
				   "Â«$titleÂ»");
			$t->{pre}=join(", ",($t->{pre} ? $t->{pre}:()),$typesettitle);
		};

		$t->{pre}.=". ";
	} else { # In english
		if (@authors) {
			$t->{pre}=join(", ", @authors);
		};

		if ($title) {
			$title="$title --- $subtitle" if ($subtitle);

			my $typesettitle=(
				 ($role =~ m/^(proceedings|conference)$/i)?
				   "\\emph{$title}":
				   $title);
			$t->{pre}=join(". ",($t->{pre} ? $t->{pre}:()),$typesettitle);
		};

		$t->{pre}.=". ";

	};
	$t->{post}="";
	$t->{post}.=$publisher if ($publisher);
	$t->{post}=join(", ",($t->{post}?$t->{post}:()),
					"$edition ") if ($edition);

	if ($lang =~ m/^fr/i) {
		$t->{post}=join(", ",($t->{post}?$t->{post}:()),
						utf8totex("nÂ° $issuenum")) if ($edition);
	} else {
		$t->{post}=join(", ",($t->{post}?$t->{post}:()),
						utf8totex("# $issuenum")) if ($edition);
	};

	$t->{post}.=" ($date) " if ($date);
	$t->{post}.=" ($pubdate) " if ($pubdate);
	$t->{post}=join(" --- ",($t->{post}?$t->{post}:()),
					"ISBN $isbn") if ($isbn);



	$t->{post}.="." if $t->{post};

	$t->{post}.= $address if ($address);
};

####
#### Indexes
####

# Page ranges are not supported yet (boy, what a mess!)

$t->{indexterm}->{testcode}=sub {
	my ($self,$t)=@_;
	$t->{pre}="\\index{";

	# Constrain the alphabetic order a bit: LaTeX will do horrible
	# things otherwise.

	my $plaintext=flatten_textnodes($self,"primary//text()");
	$t->{pre}.="$plaintext\@" if ($plaintext);

	my $afterpipe;

	if ("preferred" eq findvalue('@significance',$self)) {
		$afterpipe.="textbf";
	};

	$t->{post}=((defined $afterpipe) ? "|$afterpipe" : "");

	$t->{post}.="}";

	return 1;
};

$t->{primary}->{pre}="";
$t->{secondary}->{pre}="!";
$t->{tertiary}->{pre}="!";

$t->{see}->{pre}="|see{";
$t->{see}->{post}="}";



###########################################################################
####
####              Tags for whole documents
####

####
#### Title
####

####
#### Author(s)
####

$t->{authorgroup}->{testcode}=sub {
	my ($self, $t)=@_;
	my @authors=map {apply_templates($_)} (findnodes("*",$self));
	my $rendermode =
	  (findnodes('ancestor::*[contains(name(),"info")]',$self)) ?
		"stack" : "ampersand";
	$t->{pre}=render_authors($rendermode, @authors);
	$t->{post}="";
	return -1;
};

$t->{othername}->{testcode}=sub {
	my ($self, $t)=@_;

	my $text=apply_templates_under($self);
	$text =~ s/^\s*//g; $text =~ s/\s*$//g;

	if ((length($text) == 1) || ( findvalue('@role',$self) =~ m/^mi$/g)) {
		$t->{pre}="";
		$t->{post}=".";
	} else {
		$t->{pre}='"';
		$t->{post}='"';
	};


	$t->{pre}.=$text;

	return -1;
};

__END__

#########################################################################
#########################################################################
#################       POD DOCUMENTATION      ##########################
#########################################################################
#########################################################################



%>

<%= $inhibitOutput ? "" : apply_templates() %>

