package MMDS::Output::Latex::String;

# $RCS_Id = '$Id: String.pm,v 1.11 2003-01-09 22:58:02+01 jv Exp $ ';
# Author          : Johan Vromans
# Created On      : Tue Jan  8 17:08:08 1991
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jan  9 21:30:32 2003
# Update Count    : 1131
# Status          : Development
# Based On        : gen_tex_string 1.5

use strict;

# TeX text conversion routines
# This is a separate and independent routine, so other packages can use it.
#
my $defmargin = 65;

# To support attributes:
#
use constant A_NORMAL	  =>  0;
use constant A_BOLD	  =>  1;
use constant A_ITALIC	  =>  2;
use constant A_UNDERLINE  =>  4;
use constant A_SMALLCAPS  =>  8;
use constant A_TTY	  => 16;
use constant A_FOOTNOTE	  => 32;

my $a_ctl = "\252";
my $curattrib = A_NORMAL;

sub ::tex_string {

    # Convert string to LaTeX format. The result may be multi-line.

    my ($line) = @_;
    my ($chr, $prev, $res);
    my $index      = $::opt_index;
    my $noindex    = $::noindex;
    my $makeindex  = $::opt_makeindex;


    my $att = A_NORMAL;
    my $tally = 0;
    my $res = '';

    while ( $line =~ /(.*?)
                      ([\040\200-\377\047\042\043%&_{}<>\|^~\\\$\t\[])
		      (.*)/sx ) {

	my $tmp = $1;		# what came before it
	$chr = $2;		# the special character
	$line = $3;		# what comes after it

	$prev = (length ($tmp) > 0) 
	    ? substr($tmp, length($tmp)-1,1)
		: substr($res,length($res)-1,1);
				# the character that came before

	if ( length($tmp) > 0 ) {
	    $res .= $tmp;
	    $tally += length ($tmp);
	}

        if ( $tally > $defmargin && $chr eq ' ' ) {
	    $res .= "\n";
	    $tally = 0;
	}

	if ( $chr eq ' ' ) {
	    if ( $tally > 0 ) {
		$res .= ' ';
		$tally++;
	    }
	    next;
	}

	# Parse index entries.
	if ( $chr eq '#' && !$noindex 
	     && $line =~ /^\[/ && (($tmp = index ($line, ']#', 1)) >= $[) ) {
	    my $tag = substr ($line, 1, $tmp-1);
	    $tmp = substr ($line, $tmp+2);
	    $tag =~ s/::/\000/g;
	    $tag =~ s/:/!/g;
	    $tag =~ s/\000/:/g;
	    if ( $tag =~ /!/ ) {
		$tag =~ s/!+$//;
		$line = $tmp;
	    }
	    else {
		$line = $tag.$tmp;
	    }
	    if ( $index || $makeindex ) {
		$tmp = '\index{' . ::tex_string ($tag) . '}';
		$res .= $tmp;
		$tally += length ($tmp);
	    }
	    next;
	}

	# Parse character attributes.
	if ( $chr eq $a_ctl && $line =~ /^([biftsu~]+)$a_ctl/o ) {
	    my $new = '';
	    my $neg = 0;
	    my $oldatt = $att;

	    $line = $';

	    # Close current attibute scope.
	    if ( $att & A_ITALIC ) {
		$new .= '\/';
	    }
	    # Apparantly a good idea, but doesn't work... the fixed spaces
	    # are unbreakable.
	    # elsif ( $att & A_TTY ) {
	    #	if ( $line =~ /^ / ) {
	    #	    $line = $';
	    #	    $new .= ' ';
	    #	}
	    # }
	    $new .= '}' if $att & A_UNDERLINE;
	    $new .= '}' unless $att == A_NORMAL;

	    $tmp = $1;
	    foreach $a ( split (/(.)/, $tmp) ) {
		if ( $a eq '~' ) {
		    $neg = 2;
		}
		else {
		    my $ca = 
			($a eq 'b') ? A_BOLD :
			($a eq 'i') ? A_ITALIC : 
			($a eq 'u') ? A_UNDERLINE :
			($a eq 't') ? A_TTY :
			($a eq 's') ? A_SMALLCAPS :
			($a eq 'f') ? A_FOOTNOTE :
			A_NORMAL;
		    if ( $neg ) {
			$neg = 1;
			$att &= ~$ca;
		    }
		    else {
			$att |= $ca;
		    }
		}
	    }

	    # neg == 2 -> reset all
	    $att = A_NORMAL if $neg == 2;

	    # Open new attribute scope.
	    if ( $att != A_NORMAL ) {
		$new .= '}'
		    if ($oldatt & A_FOOTNOTE) && !($att & A_FOOTNOTE);
		$new .= '\footnote{'
		    if !($oldatt & A_FOOTNOTE) && ($att & A_FOOTNOTE);
		$new .= '\underline{'
		    if $att & A_UNDERLINE;
		$new .= '{';

		# We cannot combine attributes at will.
		# Only specific combinations are possible.

		if ( $att & A_ITALIC ) {
		    $new .= '\it ';
		}
		elsif ( $att & A_BOLD ) {
		    $new .= ( $att & A_SMALLCAPS ) ? '\sl ' : '\bf ';
		}
		elsif ( $att & A_TTY ) {
		    $new .= '\tt ';
		    # See comment above.
		    # if ( $res =~ / $/ ) {
		    # chop ($res);
		    # $new .= '{ }';
		    # }
		}
		elsif ( $att & A_SMALLCAPS ) {
		    $new .= '\sc ';
		}
	    }
	    else {
		$new .= '}' if $oldatt & A_FOOTNOTE;
	    }

	    # Append to output.
	    if ( $new ne '' ) {
		$res .= $new;
		$tally += length ($new);
	    }
	    next;
	}

	if ( ord($chr) >= 128 ) {
	    # look out for specials, e.g. "\353" -> e-acute "\\'{e}"
	    if ( defined ($tmp = $::iso2tex{$chr}) ) {
		# Protect TeX control sequences from any following text
		$res .= '{' . $tmp . '}';
		$tally += length ($tmp) + 2;
		next;
	    }
	    else {
		# ignore it
		&::warn (sprintf ('unknown ISO character \%o (ignored)',
				  ord($chr)));
		next;
	    }
	}
	elsif ( $chr eq "'" && !($att & A_TTY) ) {
	    if ( $line =~ /^(s-|s\s|t\s)/ ) { # 's-Gravenhage, 't, 's nachts
		$chr = "'";
	    }
	    else {
		$chr = (($res eq '' && $prev eq '')
			|| ($prev =~ /^\s/)
			|| ($prev =~ /^[([]$/ && $line !~ /^[\s,.:]/)
			) ? '`' : "'";
	    }
	}
	elsif ( $chr eq '"' && !($att & A_TTY) ) {
	    $chr = (($res eq '' && $prev eq '')
		    || ($prev =~ /^\s/)
		    || ($prev =~ /^[([]$/ && $line !~ /^[\s,.:]/)
		    ) ? '``' : "''";
	}
	elsif ( $chr eq "\t" ) {
	    # $chr = '\tab ';
	    next;
	}
	elsif ( $chr eq '[' ) {
	    my $kc;
	    if ( $::keycaps && ($line =~ /([^]]+)]/) 
	         && defined ($kc = $::keycaps{$1}) ) {
		$line = $';
		$chr = '\kcp{' . $kc;
	        while ( $kc =~ /^(Ctrl|Shift|Alt|Compose|Meta)$/
		     && $line =~ /^\s*\[([^]]+)]/ 
		     && defined ($kc = $::keycaps{$1}) ) {
		    $line = $';
		    $chr .= "{-}$kc";
		}
		$chr .= '}';
	    }
	}

	# Trust PostScript fonts
	else {
	    $chr = '{\char' . ord($chr) . '}';	# \char64
	}

	$res .= $chr;
	$tally += length ($chr);

    }

    $res.$line.($att != A_NORMAL ? (($att & A_FOOTNOTE) ? '}}' : '}') : '');
}

1;
