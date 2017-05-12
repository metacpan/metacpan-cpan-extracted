package OnSearch::Regex; 

=head1 NAME

OnSearch::Regex - Construct search and display regular expressions.

=head1 SYNOPSIS

  $regex = search_expr ($searchterm, $type_of_match, $case_sensitive, 
			$partial_word);

  $display_regex = display_expr ($searchterm, $type_of_match, $case_sensitive,
				 $partial_word);

=head1 DESCRIPTION

OnSearch::Regex constructs regular expressions for searching and
displaying word and phrase matches.  The I<searchterm> argument can be
any number of words.  The I<type_of_match> argument can be either,
"any," "all," or, "exact."  The third and fourth arguments,
I<case_sensitive> and I<partial_word>, can be either, "yes," or, "no."

Compound words are also treated as multiple words.  For example, 
"Net::Daemon," is treated as two words.

=head1 EXPORTS

=cut

#$Id: Regex.pm,v 1.10 2005/08/16 05:34:03 kiesling Exp $

use strict;
use warnings;
use Carp;

my $VERSION='$Revision: 1.10 $';

require Exporter;
require DynaLoader;
our (@ISA, @EXPORT);
@ISA = qw(Exporter DynaLoader);
@EXPORT = (qw/search_expr display_expr collate_expr/);

=head2 search_expr (I<searchterm>, I<matchtype>, I<matchcase>, I<partialword>);

Construct a search expression.

=cut

sub search_expr {
    my $searchterm = $_[0];
    my $matchtype = $_[1];
    my $matchcase = $_[2];
    my $partialword = $_[3];

    return undef if ! $searchterm || ! length ($searchterm);

    my ($regex, $sterm);

    if ($matchcase =~ /no/) {
	$searchterm = lc $searchterm;
    }

    if ($matchtype =~ /exact/) {
	$sterm = join '|', split /\W+/, $searchterm;
	$sterm = qq/\"($sterm)\"/;
	if ($matchcase =~ /no/) {
	    $regex = qr/$sterm/oi;
	} else {
	    $regex = qr/$sterm/o;
	}
    } else {
	$sterm = join '|', split /\W+/, $searchterm;
	if ($partialword =~ /no/) {
	    $sterm = qq/\"(?:$sterm)\"/;
	} else {
	    $sterm = qq/$sterm/;
	}

	if ($matchcase =~ /no/) {
	    $regex = qr/$sterm/oi;
	} else {
	    $regex = qr/$sterm/o;
	}
    }
    return $regex;
}

=head2 collate_expr (I<searchterm>, I<matchtype>, I<matchcase>, I<partialwordmatch>);

Construct an expression for collating search terms.

=cut

###
### This should be the only expression in the search process 
### that requires backreferences.
###

sub collate_expr {
    my $searchterm = $_[0];
    my $matchtype = $_[1];
    my $matchcase = $_[2];
    my $partialword = $_[3];

    return undef if ! $searchterm || ! length ($searchterm);

    my ($regex, $sterm);

    $sterm = join '|', split /\W+/, $searchterm;
    if ($partialword =~ /no/) {
	$sterm = qq/\"($sterm)\"/;
    } else {
	$sterm = qq/($sterm)/;
    }

    if ($matchcase =~ /no/) {
	$regex = qr/$sterm/oi;
    } else {
	$regex = qr/$sterm/o;
    }
    return $regex;
}

###
### NOTE: If changing these expressions, remember to check the 
### optimizations in search.cgi.
###

=head2 display_expr (I<searchterm>, I<matchtype>, I<matchcase>, I<partialword>);

Construct a display expression.

=cut

sub display_expr {
    my $searchterm = $_[0];
    my $matchtype = $_[1];
    my $matchcase = $_[2];
    my $partialword = $_[3];

    return undef unless $searchterm;

    my ($regex, $sterm);

    if ($matchtype =~ /exact/) {
	###
	### Match an arbitrary amount of whitespace in between
	### words. This should be sufficient in this application, 
	### but it could be made into an option if greater precision
        ### is necessary.  When reading the contents of the file,
	### we substitute white space for newlines.
	###

	my $pattern = $searchterm; $pattern =~ s/\s+/\\s\+/g;

	###
	### We only need to worry about matching the exact words 
	### within the phrase.  But we will still match either case 
	### if that option is selected.
	###
	### Plurals and other endings are displayed in the 
	### results for the matching file if the user also 
	### selected to match text within words, AND the file 
	### matches because it contains all of the exact words, 
	### in any order.
	###
	### This heuristic seems not to cause any misses, as in 
	### the phrases, "root name server," "file dialog box," 
	### and, "virtual private network," but it approximately 
	### doubles the speed of searching for phrases.
	###
	if ($partialword =~ /no/) {
	    $pattern = "\\b$pattern\\b";
	}

	### 
	### Phrases might be either at the beginning or middle of a 
        ### sentence, so allow case insensitive matching.
	###
	if ($matchcase =~ /no/) {
	    $regex = qr/$pattern/oi;
	} else {
	    $regex = qr/$pattern/o;
	}
    } else {

	if ($partialword =~ /no/) {
	    $sterm = join '\\b|\\b', split /\W+/, $searchterm;
	} else {
	    $sterm = join '|', split /\W+/, $searchterm;
	}

	if ($matchcase =~ /no/) {
	    if ($partialword =~ /no/) {
		$regex = qr/\b$sterm\b/oism;
	    } else {
		$regex = qr/$sterm/oi;
	    }
	} else {
	    if ($partialword =~ /no/) {
		$regex = qr/\b$sterm\b/osm
	    } else {
		$regex = qr/$sterm/o;
	    }
	}
    }
    return $regex;
}

1;
__END__

=head1 SEE ALSO

L<OnSearch(3)>

=cut




