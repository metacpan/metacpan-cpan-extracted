package WWW::Extractor;
use strict;
$WWW::Extractor::VERSION = '0.8';

=head1 NAME

WWW::Extractor - Semi-automated extraction of records from WWW pages

=head1 SYNOPSIS

   use strict;
   use WWW::Extractor;

   my($extractor) = WWW::Extractor->new();

   $extractor->process($string);

=head1 DESCRIPTION

WWW::Extractor is a tool for semi automated extraction of records from
a string containing HTML.  One record within the string is marked up
with extraction markups and the modules uses a pattern matching
algorithm to match up the remaining records.

=head2 Extraction markup

The user markups up one record withing the HTML stream with the
following symbols.

=over 4

=item (((BEGIN))) 

Begin a record

=item (((fieldname))) 

Begin a field named fieldname

=item [[[literal string]]] 

This identifies a block of text that the
extractor attempts to match.  This string is dumped out when the
records are extracted.

=item {{{literal string}}} 

This identifies a block of text that the
extractor attempts to match.  This string is not dumped out when
the records are extracted.

=item (((nodump))) 

This marks an area of text that is not to be dumped out.

=item (((/nodump)))

This ends a section of text that is not to be dumped out.

=item (((END)))

End a record.

=back

=head1 ALGORITHM

The algorithm used is based on the edit distance wrapper generation
method described in

@inproceedings{ chidlovskii00automatic,
    author = "Boris Chidlovskii and Jon Ragetli and Maarten de Rijke",
    title = "Automatic Wrapper Generation for Web Search Engines",
    booktitle = "Web-Age Information Management",
    pages = "399-410",
    year = "2000",
    url = "citeseer.nj.nec.com/chidlovskii00automatic.html" }

but with two major enhancements.

=over

=item 1 Before calculating edit distance, the system divides the tokens
into different classification groups.

=item 2 Instead of creating a general grammar from all of the records in a
file, the data extractor creates one grammar from the sample entry and
then matches the rest of the text to that one grammar.

=back

=head1 METHODS

=over 4

=cut

use PDL::Lite;
use Data::Dumper;
use strict;
use integer;
use English;

=pod

=item $self->new()

Standard constructor

=cut


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{'debug'} = 0;
    $self->{'exact_tables'} = 1;
    $self->{'start_tags'} =  2;
    $self->{'end_tags'} = 1;
    $self->{'expand_hrefs'} = 0;
    $self->{'tokens'} = [];
    $self->{'finish_tag'} = [];
    $self->{'grammar'} = [];
    $self->{'capture_regexp'} = "";
    $self->{'capture_field'} = "";
    $self->{'capture_string'} = "";
    return $self;
}

=pod

=item $self->open($string)

Opens a string for processing.

=cut

sub open {
    my ($self, $lp, $grammar) = @_;
    if ($grammar eq undef) {
	$self->{'tokens'} = $self->tokenize($lp);
	my ($g, $context) = $self->extract_grammar($self->{'tokens'});
	$self->{'grammar'} = $g;
	if ($self->{'debug'} > 250) {
	    print "Initial grammar: ", Dumper($g), "\n";
	    print "Initial content: ", Dumper($context), "\n";
	}
    } else {
	$self->{'grammar'} = $grammar;
	$self->{'tokens'} = $self->tokenize($lp);
    }

    my (@ap) = @{$self->{'tokens'}};
    my ($item);
    $self->{'tokens'} = [];
    foreach $item (@ap) {
	if ($self->_classify($item) !~ /^\(\(\(.*?\)\)\)$/s) {
	    push(@{$self->{'tokens'}}, $item);
	}
    }

}



=pod

=item $self->read($hashref)

Read the next processed entry into a hash pointer.

=cut

sub read {
    my ($self, $f) = @_;
    my ($i, $gp, $w);
    my($score, $i) = $self->_find_next_item();
    
    %{$f} = ();

    if ($self->{'debug'} > 150) {
	print "Next item: ", $score, Dumper($i);
    }
    if (!$i) {
	return 0;
    }
    my($context) = $self->_incorporate_item($i);
       
    $self->_dump_hash($context, $f);
    return 1;
}


=pod

=item $self->close()

Closes off the string

=cut

sub close {
    my ($self) = @_;
}

=pod

=item $self->capture($field, $regexp)

Captures a string that is outside of an entry and inserts it into an entry hash.  The
routine takes two arguments.  One is the field that the entry hash is to be included 
in.  The other is the regular expression which matches the field.

=cut

sub capture {
    my ($self, $capture_field, $capture_regexp) = @_;
    $self->{'capture_field'} = $capture_field;
    $self->{'capture_regexp'} = $capture_regexp;
    $self->{'capture_string'} = "";
}


=pod

=item $self->debug(i)

Set the debug level.  Higher numbers turn on more debug levels.

=cut

sub debug {
    my($self, $debug) = @_;
    if (defined($debug)) {
	$self->{'debug'} = $debug;
    }
    return $self->{'debug'};
}

=pod

=item $self->expand_hrefs(i)

If set to one then expand out the internal A tags and IMG tags to
moving the href outside the tag.

=cut

sub expand_hrefs {
    my($self, $d1) = @_;
    if (defined($d1)) {
	$self->{'expand_hrefs'} = $d1;
    }
    return $self->{'expand_hrefs'};
}

=pod

=item $self->start_tags(i)

Set to the number of tags to match at the beginning of each entry.
Default is 2.

=cut

sub start_tags {
    my($self, $d1) = @_;
    if (defined($d1)) {
	$self->{'start_tags'} = $d1;
    }
    return $self->{'start_tags'};
}


=pod

=item $self->end_tags(i)

Number of tags to match at the end of an entry,  The default is 1.

=cut

sub end_tags {
    my($self, $d1) = @_;
    if (defined($d1)) {
	$self->{'end_tags'} = $d1;
    }
    return $self->{'end_tags'};
}


=pod
=item $self->exact_tables(i)

If set to one then match table tags exactly.  Otherwise ignore internal
table items.

=cut

sub exact_tables {
    my($self, $d1) = @_;
    if (defined($d1)) {
	$self->{'exact_tables'} = $d1;
    }
    return $self->{'exact_tables'};
}


sub process {
    my ($self, $lp) = @_;
    my (%f);
    $self->open($lp);

    while ($self->read(\%f)) {
	my ($item);
	foreach $item (keys %f) {
	    print "$item  $f{$item}\n";
	}
	print "\n";
    }
    $self->close();
}

sub tokenize {
    my($self, $lp) = @_;
    my($i) = $lp;
    my (@match_token) = ();
    my(@imatch_token) = ();

    while ($i =~ m/\[\[\[([^\]]+)\]\]\]/s) {
	if ($self->{'debug'} > 1000) {
	    print "added $1 to match tokens\n";
	}
	push(@match_token, $1);
	$i = $POSTMATCH;
    }


    $i = $lp;
    while ($i =~ m/\{\{\{([^\}]+)\}\}\}/s) {
	if ($self->{'debug'} > 1000) {
	    print "added $1 to imatch tokens\n";
	}
	push(@imatch_token, $1);
	$i = $POSTMATCH;
    }

    if ($self->{'grammar'} ne undef) {
	foreach $i (@{$self->{'grammar'}}) {
	    if ($i =~ m/\[\[\[([^\]]+)\]\]\]/s) {push(@match_token, $1);}
	    if ($i =~ m/\{\{\{([^\}]+)\}\}\}/s) {push(@imatch_token, $1);}
	}
    }

    if ($self->{'debug'} > 500) {
	print Dumper(\@match_token);
	print Dumper(\@imatch_token);
    }

    $lp =~ s/\[\[\[(.*?)\]\]\]/$1/gs;
    $lp =~ s/\{\{\{(.*?)\}\}\}/$1/gs;

    foreach $i (@match_token) {
	my ($iin) = $i;
	$iin =~ s/([\[\(\)\]])/\\$1/gs;
	$lp =~ s/$iin/[[[$i]]]/gs;
    }

    foreach $i (@imatch_token) {
	my ($iin) = $i;
	$iin =~ s/([\[\(\)\]])/\\$1/gs;
	$lp =~ s/$iin/{{{$i}}}/gs;
    }

    push(@match_token, @imatch_token);
    my ($insert_string) = "";
    if ($self->{'capture_regexp'} ne "") {
	$insert_string = $self->{'capture_regexp'} . "|";
    } else {
	$insert_string = "";
    }
    $lp =~ s/&nbsp;/ /gi;
    my (@lp) = split(/\s*(${insert_string}\(\(\([^\)]+?\)\)\)|\[\[\[[^\]]+?\]\]\]|\{\{\{[^\}]+?\}\}\}|<[^>]+>|\-\s+|\n\s+|\&\#183|\;|\|)\s*/, $lp);
    @lp = grep {$_ ne ""} @lp;
    return \@lp;
}

sub _classify {
    my ($self, $item) = @_;
    if ($item =~ /^\s+$/is) {
	return "B";
    }

    $item =~ s/\s+$//i;
    if ($item =~ /^<t.*>$/is && $self->{'exact_tables'}) {
	return lc($item);
    }
    if ($item =~ /^\[\[\[.*?\]\]\]$/s) {
	return $item;
    }

    if ($item =~ /^\(\(\(.*?\)\)\)$/s) {
	return $item;
    }

    if ($item =~ /^\{\{\{.*?\}\}\}$/s) {
	return $item;
    }

    if ($item =~ /^<([^>\s]+)\s*.*>$/is) {
	return "<" . lc($1) . ">";
    }
    if ($item =~ /^\(/) {
	return "(";
    }
    if ($item =~ /^&/) {
	return $item;
    } 
    if ($item =~ /^\)/) {
       return ")";
    }
    if ($item =~ /^\|/) {
	return "|";
    } 
    if ($item =~ /^\;/) {
	return ";";
    }
    return "C";
}

sub extract_grammar {
    my ($self, $ap) = @_;
    if ($self->{'debug'} > 50) {
	print "initializing\n";
    }
    my ($start, $finish) = $self->_find_indices($ap, [q/(((BEGIN)))/,
						     q/(((END)))/]);

    if ($self->{'debug'} > 100) {
	print "start finish $start $finish\n";
    }
    my (@out) = @{$ap}[($start+1)..($finish-1)];
    my (@out_grammar) = @out;
    return (\@out_grammar, \@out);
}


sub _edit_distance {
    my ($self, $s1, $s2) = @_;
    my ($item, @s1p, @s2p);
    @s1p = grep {$self->_classify($_) !~ /\(\(\(.*\)\)\)/} @$s1;
    @s2p = grep {$self->_classify($_) !~ /\(\(\(.*\)\)\)/} @$s2;
    
    my ($m) = $self->_edit_distance_matrix(\@s1p, \@s2p);
    my (@a) = $m->dims();
    return $m->at($a[0] - 1, $a[1] - 1);
}

sub _edit_distance_matrix {
    my ($self, $s1p, $s2p) = @_;
    if ($self->{'debug'} > 10) {
	print "**** Edit distance matrix " .
	    (scalar(@$s1p) + 1) . " by " . (scalar(@$s2p) + 1) . "\n";
    }
    my ($j, $i);
    my ($m) = PDL->zeroes (scalar(@$s1p) + 1, scalar(@$s2p) + 1);
    PDL::set($m, 0, 0, 0);
    for ($j=1; $j <= scalar(@$s2p); $j++) {
	PDL::set ($m, 0, $j, $m->at(0, $j-1) - 0 + 1);
    }
    for ($i=1; $i <= scalar(@$s1p) ; $i++) {
	PDL::set ($m, $i, 0, $m->at($i-1, 0) - 0 +1);
	for ($j=1; $j <= scalar(@$s2p) ; $j++) {

	    my ($diag) = $m->at($i-1, $j-1);
	    if ($self->_classify($s1p->[$i-1]) ne
		$self->_classify($s2p->[$j-1])) {
		$diag++;
	    }
	    my ($item) = $diag;
	    if ($item > $m->at($i-1, $j) + 1) {
		$item = $m->at($i-1, $j) + 1;
	    }
	    if ($item > $m->at($i, $j-1) + 1) {
		$item = $m->at($i, $j-1) + 1;
	    }
	    PDL::set($m, $i, $j, $item);
	}
    }
    return $m;
}

sub _find_next_item {
    my ($self) = @_;
    my ($ap) = $self->{'tokens'};
    my ($g) = $self->{'grammar'};
    my ($dnewlocal, $dlocal, $dbest) = 
	(998, 999, 1000);
    my ($ib, $ie, $newib) = (-1, -1, -1);
    my ($local_best_item, $best_item) = 
	("", "");
    my (@gprocessed) = grep {$self->_classify($_) !~ /\(\(\(.*\)\)\)/} @{$g};
    my (@start_tags) = @gprocessed[0..($self->{'start_tags'})-1];
    my ($glim) = scalar(@gprocessed);
    my (@end_tags) = @gprocessed[$glim-$self->{'end_tags'}..$glim-1];

    while ($dlocal < $dbest) {
	$dbest = $dlocal;

	if ($self->{'debug'} > 200) {
	    print "Start find indices for ",
	    Dumper(\@start_tags), "\n";
	}
	if ($self->{'debug'} > 1000) {
	    print "Match with ",
	    Dumper($ap), "\n";
	}

	($newib) = $self->_find_indices ($ap, [\@start_tags], $ib+1);
	if ($self->{'debug'} > 500) {
	    print "Newib: $newib\n";
	}
	if ($newib < 0) {
	    last;
	}
	$ie = $newib;
	while(1) {
	    if ($self->{'debug'} > 500) {
		print "Entering loop starting at $ie.  Searching for ",
		Dumper(\@end_tags), "\n";
	    }
	    my($newie) = $self->_find_indices($ap, [\@end_tags], $ie+1);
	    if ($self->{'debug'} > 500) {
		print "newie: $newie\n";
	    }
	    if ($newie < 0) {
		last;
	    }
	    $dlocal = $dnewlocal;

	    my(@new_local_best_item) =
		@{$ap}[$newib .. $newie];
	    my($new_local_best_item) = 
		\@new_local_best_item;
	    if ($self->{'debug'} > 250) {
		print Dumper($new_local_best_item);
	    }

	    $dnewlocal = $self->_edit_distance($g,
					$new_local_best_item);
	    if ($self->{'debug'} > 150) {
		print "Edit distance ", $dnewlocal, "\n";
	    }
	    if ($dnewlocal > $dlocal) {
		last;
	    }
	    $ie = $newie;
	    if ($self->{'debug'} > 500) {
		print "ie: $ie\n";
	    }

	    $local_best_item = $new_local_best_item;
	}
	$best_item = $local_best_item;
    }

    my (@ap) = @$ap;
    my ($scan_capture) = "";
    $self->{'capture_string'} = "";
    foreach $scan_capture (@ap[0..$ie]) {
	if ($scan_capture =~ m!$self->{'capture_regexp'}!) {
	    if ($self->{'debug'} > 50) {
		print "Capturing $1\n";
	    }
	    $self->{'capture_string'} = 
		$1;
	}
    }

    @{$ap} = @ap[($ie+1)..$#ap];
    return ($dbest, $best_item);
}

sub _incorporate_item {
    my ($self, $item) = @_;
    my ($g) = $self->{'grammar'};
    my ($i, $j, $gitem, $iprocess);
    my (@greturn) = ();
    my (@gprocessed) = ();
    my (@lbrace) = ();
    my (@rbrace) = ();
    my (@tag) = ();
    my ($ginopt) = (0, 0);
    my ($newginopt) = 0;
    my(@g) = @{$g};
    my(@item) = grep {$self->_classify($_) !~ /\(\(\(.*?\)\)\)/} @{$item};
    if ($self->{'debug'} > 10) {
	print Dumper(\@g);
    }

    $iprocess = 0;
    foreach $gitem (@g) {
	if ($gitem =~ /\(\(\((.*?)\)\)\)/) {
	    $tag[$iprocess] = $gitem;
	} else {
	    push (@gprocessed, $gitem);
	    $iprocess++;
	}   
    }
    my (@gblock, @iblock, $addtag);
    my ($m) = $self->_edit_distance_matrix(\@gprocessed, \@item);
    if ($self->{'debug'} > 10) {
	print $m, "\n";
    }
    $i = scalar(@gprocessed);
    $j = scalar(@item);

    while ($i > 0 && $j > 0) {
	my ($direction) = "";
	my ($dump_block) = 0;
	my ($oldi) = $i;
        if ($m->at($i-1, $j) + 1 == $m->at($i, $j)) {
	    $direction = "w";
	    $i--;
	    if ($tag[$oldi]) {
		@greturn = ($tag[$oldi],  @greturn);
	    }

	} elsif ($m->at($i, $j-1) + 1 == $m->at($i, $j)) {
	    $direction = "n";
	    $j--;
	    @greturn = ($item[$j], @greturn);
	} elsif ($m->at($i-1, $j-1) + 1 == $m->at($i, $j)) {
	    $direction = "nw";
	    $i--;
	    $j--;
	    if ($tag[$oldi]) {
		@greturn = ($tag[$oldi],  @greturn);
	    }
	    @greturn = ($item[$j], @greturn);
	} elsif ($m->at($i-1, $j-1) == $m->at($i, $j) &&
	    $self->_classify($gprocessed[$i-1]) eq 
		 $self->_classify($item[$j-1])) {
	    $direction = "eq";
	    $i--;
	    $j--;
	    if ($tag[$oldi]) {
		@greturn = ($tag[$oldi],  @greturn);
	    }
	    @greturn = ($item[$j], @greturn);
	} else {
	    print "ERROR:";
	}
    }

    return (\@greturn);
}

sub _find_indices {
    my ($self, $list, $itemref, $index) = @_;
    my ($i, $j, @out);
    my ($current_item) = 0;

    if ($self->{'debug'} > 100) {
	print "start find index\n   index: ", $index,
	Dumper($itemref), "\n";
    }

    if ($index eq undef) {
	$index = 0;
    }

  loop:
    for ($i=$index; $i < scalar(@$list); $i++) {
	if (ref($itemref->[$current_item]) eq "ARRAY") {
	    for ($j = 0; $j < scalar(@{$itemref->[$current_item]}); $j++) {
		if (($i + $j) >= scalar(@$list)) {
		    next loop;
		}
		if ($self->{'debug'} > 1024) {
		    print "Comparing ", 
		    $itemref->[$current_item]->[$j], 
		    " and ", $list->[$i + $j], " at $i $j\n";
		}
		if ($self->_classify($itemref->[$current_item]->[$j])
		    ne $self->_classify($list->[$i + $j])) {
		    next loop;
		}
	    }
	    if ($self->{'debug'} > 500) {
		print "Match at $i\n";
	    }
	    push (@out, $i);
	    $current_item++;
	    if ($current_item > scalar(@{$itemref})) {
		last loop;
	    }
	} else {
	    if ($self->{'debug'} > 1024) {
		print "Comparing ", 
		$itemref->[$current_item], 
		" and ", $list->[$i], " at $i\n";
	    }

	    if ($self->_classify($list->[$i]) eq 
		$self->_classify($itemref->[$current_item])) {
		push (@out, $i);
		$current_item++;
		if ($current_item > scalar(@{$itemref})) {
		    last loop;
		}
	    }
	}
    }
    for ($i=$current_item; $i <= scalar(@{$itemref}); $i++) {
	push (@out, -1);
    }
    return @out;
}

sub _dump_hash {
    my ($self, $context, $r) = @_;
    if ($self->{'debug'} > 200) {
	print "Dumping: ";
	print Dumper($context);
    }
    my ($item);
    my ($dump) = 1;
    my ($current_field) = "";
    my ($returnval) = "";

    foreach $item (@{$context}) {
	my ($class) = $self->_classify($item);
	if ($class eq "(((nodump)))") {
	    $dump = 0;
	} 
	if ($self->{'debug'} > 500) {
	    print "Item: ", $item, "\n";
	    print "Class: ", $class, "\n";
	    print "\n\n";
	}

     	if ($dump) {
	    if ($class =~ /\(\(\((.*?)\)\)\)/) {
		my($tag) = $1;
		if ($current_field ne "") {
		    $returnval =~ s/\s+$//gi;
		    $r->{$current_field} = $returnval;
		    $returnval = "";
		}
		$current_field = $tag;
	    } elsif ($class =~ /\[\[\[(.*?)\]\]\]/) {
		$returnval .= "$1";
	    } elsif ($class =~ /<a>/) {
		if ($item =~ /href/i && $self->{'expand_hrefs'}) {
		    if ($self->{'debug'} > 500) {
			print "Expand hrefs\n";
		    }
		    $item =~ /href=\"(.*?)\"/i;
		    $returnval .= "   $1 ";
		}
	    } elsif ($class =~ /<img>/) {
		if ($item =~ /src/i &&
		    $self->{'expand_hrefs'}) {
		    if ($self->{'debug'} > 500) {
			print "Expand hrefs\n";
		    }
		    $item =~ /src=\"(.*?)\"/i;
		    $returnval .= "   $1 ";
		}
	    } elsif ($class eq "C") {
		$item =~ s/\n/\n   /gis;
		$returnval .= $item;
	    } elsif ($class =~ /<.*?>/) {
		$returnval .= " ";
	    } elsif ($class eq "B") {
		$returnval .= " ";
	    } elsif ($class !~ /\{\{\{(.*?)\}\}\}/s) {
		$returnval .= $item;
	    }
	}
	if ($class eq "(((/nodump)))") {
	    $dump = 1;
	}
    }
    if ($current_field ne "") {
	$returnval =~ s/\s+$//gi;
	$r->{$current_field} = $returnval;
    }
    if ($self->{'capture_field'} ne "" &&
	$self->{'capture_string'} ne "") {
	$r->{$self->{'capture_field'}} =
	    $self->{'capture_string'};
    }
}
=pod

=back

=head1 EXAMPLES

The distribution contains a sample driver application and test data in
the examples directory.  To look at the markup for the test data,
search for the (((BEGIN))) tag.

=head2 Direct mode

To run

./learn.wrapper < ./sample1.html

To run an example with --expand-hrefs

./learn.wrapper --expand-hrefs < ./sample1.html

=head2 Saving a grammar

To save off a grammar

./learn.wrapper --extract-grammar < ./sample1.html > /tmp/saved.grammar

You can then use this grammar to do future parsing

./learn.wrapper --load-grammar /tmp/saved.grammar < ./sample1.html

=head1 DISCUSSION AND DEVELOPMENT

A wiki on this module is located at

http://www.gnacademy.org/twiki/bin/view/Gna/AutomatedDataExtraction

Please contact gna@gnacademy.org for ideas on improvements.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2004 Globewide Network Academy

Redistributed under the terms of the Lesser GNU Public License

=cut
