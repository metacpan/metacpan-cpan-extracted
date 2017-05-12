package OnSearch::Cache;

#$Id: Cache.pm,v 1.23 2005/08/16 02:07:56 kiesling Exp $

use strict;
use warnings;
use Carp;
use POSIX;

use OnSearch;
use OnSearch::AppConfig;
use OnSearch::Regex;
use OnSearch::StringSearch;
use OnSearch::Utils;
use OnSearch::WebLog;

=head1 NAME

OnSearch::Cache - Cacheing library for OnSearch.

=head1 DESCRIPTION

OnSearch::Cache provides the library routines that store and 
retrieve search results in OnSearch's cache.  The library routines 
do some ordering of retrievals based on closeness of the match, and 
perform checks to ensure consistency of the cache with the site's
documents.

=head1 EXPORTS

=cut

my ($VERSION)= ('$Revision: 1.23 $' =~ /:\s+(.*)\s+\$/);

require Exporter;
require DynaLoader;
our (@ISA, @EXPORT);
@ISA = qw(Exporter DynaLoader);
@EXPORT=qw/posting_to_cache add_to_cache cache_retrieve caching_enabled/;

my $logfunc = \&OnSearch::WebLog::clf;
my $searchstr = \&OnSearch::StringSearch::_strindex;

my $FILEEXPR = qr'.*?:::(.*?):::';
my $WORDOFFSETSEXPR = qr'(.*?):::.*?:::(.*)';

=head2 add_to_cache (I<session_id>, I<entries>);

Add_to_cache adds a matching document and the term or terms it
matches to the cache.

=cut

sub add_to_cache {
    my $session_id = $_[0];
    my $newentries = $_[1];
    my ($l, @existing_entries, $entry, $entryexp);
    my ($cachefile, $cachefh, $lockfn, $lockfh);

    return unless caching_enabled ();

    foreach $entry (@$newentries) {
	$cachefile = cache_file_name_from_term ($entry);
	$lockfn = "$cachefile.lck";
	if (! -f $cachefile) {
	    open $cachefh, ">$cachefile" || browser_warn ("$cachefile: $!");
	    print $cachefh "$entry\n";
	    close $cachefh;
	} else {
	    ###
	    ### A lock file is preferable to flock (), because 
	    ### a flock lock would be lost if a process respawns,
	    ### and the flock locks are advisory - it's necessary
	    ### to maintain the integrity of the cache, because
	    ### multiple writes from concurrent searches can 
	    ### easily corrupt the data.
	    ### 
	    while (valid_lock ($lockfn)) { }

	    open $lockfh, "+>$lockfn" || do {
		browser_warn ("add_to_cache open $lockfn: $!");
		return;
	    };
	    print $lockfh $session_id;
	    close $lockfh;

	    no warnings;
	    ###
	    ### The Perl I/O abstraction layer issues a warning 
	    ### if the fileno is 0, which is STDOUT, and is open 
	    ### only for input.
	    ###
	    local $!;
	    open $cachefh, "$cachefile" or browser_warn ("$cachefile: $!");
	    use warnings;
	    ###
	    ### But issue our own warning if necessary.
	    ###
	    if (! defined (fileno ($cachefh)) || $!) {
		&$logfunc ('error', "add_to_cache $cachefile: $!.");
	    }
	    while (defined ($l = <$cachefh>)) {
		push @existing_entries, ($l);
	    }
	    close $cachefh;
	    $entryexp = quotemeta ($entry);
	    ###
	    ### TO DO See comments in Search.pm about
	    ### str_in_list that matches regexes.
	    ###
	    unshift @existing_entries, ($entry) unless
		scalar grep /$entryexp/, @existing_entries;
	    ###
	    ### Suppress I/O abstraction layer warnings
	    ### about standard I/O channels.
	    ###
	    no warnings;
	    open $cachefh, ">$cachefile" or browser_warn "$cachefile: $!";
	    foreach $l (@existing_entries) {
		chomp $l;
		print $cachefh "$l\n";
	    }
	    close $cachefh;
	    use warnings;
	    $#existing_entries = -1;
	    unlink ($lockfn) || do {
		browser_warn "add_to_cache delete PID $$ $lockfn: $!";
		return;
	    };
	}
    }
}

my $PATHTAG = qr'<file path="(.*)">';
my $WORDTAG = qr'\s*<word chars="(.*)">(.*)</word>'i;

sub delete_from_cache {
    my $session_id = $_[0];
    my $entry = $_[1];

    my ($cachefn, $lockfn, $tmpfn, $cacheline);
    my ($cachefh, $lockfh, $tmpfh);
    $cachefn = cache_file_name_from_term ($entry);
    $lockfn = "$cachefn.lck";
    $tmpfn = "$cachefn.tmp";
    my $ret = 0;

    while (valid_lock ($lockfn)) { }

    ###
    ### Suppress I/O abstraction layer warning here
    ### also if fileno ($lockfh) is 0, 1, or 2.
    ###
    no warnings;
    sysopen ($lockfh, $lockfn, O_WRONLY | O_TRUNC | O_CREAT) || do {
	browser_warn "add_to_cache open $lockfn: $!";
	return -1;
    };
    use warnings;
    print $lockfh $session_id;
    close $lockfh;
    
    open $cachefh, "$cachefn" || do { 
	browser_warn "$cachefn: $!";
	return -1;
    };
    open $tmpfh, ">$tmpfn" || do {
	browser_warn "$tmpfn: $!";
	return -1;
    };
    while (defined ($cacheline = <$cachefh>)) {
	chomp $cacheline;
	if ($cacheline eq $entry) {
	    $ret = 1;
	    next;
	}
	print $tmpfh "$cacheline\n";
    }
    close $tmpfh;
    close $cachefh;
    unless (rename ($tmpfn, $cachefn)) {
	browser_warn ("Replacing $cachefn: $!");
	return -1;
    }
    unlink ($lockfn) || do {
	&$logfunc ('warning', 
	   "delete_from_cache session ID $session_id delete $lockfn: $!");
	return -1;
    };
    return $ret;
}

###
### Verifies that the target file exists. 
###
sub _is_valid_targetfile {
    my $targetfn = shift;
    return (-f $targetfn) ? 1 : 0;
}

=head2 posting_to_cache (I<postings>, I<searchterms>, I<matchtype>, I<matchcase>);

Posting_to_cache formats a cache entry from an index posting.

=cut

###
### Examine the search terms to find out what term a posting matched on.
### Except in the case of exact string matches, cache under the search 
### term(s) when they match part of a word.
###
### Because the search has already filtered for case, matches
### should work with upper and lower case.
###
sub posting_to_cache {
    my $postbuf = $_[0];
#    my $postref = $_[0];
    my $termref = $_[1];
    my $matchtype = $_[2];
    my $matchcase = $_[3];
    my ($fn, $term, $p, $w, $o, @l);
    @l = split /\n/, $postbuf;
    my @posting_strs = ();
#    foreach my $p (@{$postref}) {
    foreach my $p (@l) {
	if ($p =~ $PATHTAG) {
	    ($fn) = ($p =~ $PATHTAG);
	    next;
	} elsif ($p =~ /<word chars=\"/) {
	    ($w, $o) = ($p =~ $WORDTAG);
	    if ($matchtype !~ /exact/) {
		foreach $term (@{$termref}) {
		    if ($w =~ m"$term"i) {
			push @posting_strs, ($w.':::'.$fn.':::'.$o);
		    }
		}
	    } else {
		push @posting_strs, ($w.':::'.$fn.':::'.$o);
	    }
	}
    }
    return \@posting_strs;
}

###
### TO DO: We can assume that all of the file names in the 
### list of cache hits will have the same target file name,
### but it wouldn't hurt to check.
###
### Collating the words here results in a 
### 20 - 30 percent speed improvement.  
### Precompiling the regexes helps also.
###
sub cache_to_posting {
    my @cachelist = @_;

    return if $#cachelist == -1;

    my $posting = _new_array_ref ();

    my ($c, $fn, $word, $offsets, %words, $buf);
    ($fn) = ($cachelist[0] =~ $FILEEXPR);
    push @{$posting}, (qq|<file path="$fn">|);

    foreach $c (@cachelist) {
	($word, $offsets) = 
	    ($c =~ $WORDOFFSETSEXPR);
	###
	### TO DO figure out some strategy to recover from
	### a corrupted cache file.
	###
	unless (defined ($fn) && defined ($word) && defined ($offsets)) {
	    warn "Bad cache entry $c." ;
	    return undef;
	}
	unless (exists $words{$word}) {
	    $words{$word} = $offsets;
	} else {
	    $words{$word} = $words{$word} . ',' . $offsets;
	}
    }
    foreach (keys %words) {
	push @{$posting}, (qq| <word chars="$_">$words{$_}</word>|);
    }
    push @{$posting}, (qq|</file>|);
    $buf = join "\n", @{$posting};
    return $buf;
}

sub _new_array_ref { my @a = (); return \@a; }

=head2 cache_retrieve (I<session_id>, I<searchterm>, I<term_ref>, I<matchtype>, I<matchcase>);

Cache_retrieve returns cache entries that match the search term and other 
search criteria.

=cut


###
### Return an array of array refs.
###
sub cache_retrieve {
    my $session_id = shift;
    my $searchterm = shift;
    my $termref = shift;
    my $matchtype = shift;
    my $matchcase = shift;
    my ($r, $l, $term, $termnc, $offsets, $cachefile, @cachelines, @cacherecs);
    my ($targetterm, $targetfn, $targetoffsets);
    my (%h, $k, $newposting, %collated, %filed);
    my ($searchtermnc, $exactphraseexpr, $partialphraseexpr);
    my (@bad_entries, $recordswritten, $cfg, $CacheReports);
    my (@selectedvolumes, $matchcasep);

    return undef unless caching_enabled ();

    $cfg = OnSearch::AppConfig -> new;
    $CacheReports = $cfg -> on (qw/CacheReports/);
    @selectedvolumes = get_selected_volumes ();

    $matchcasep = ($matchcase =~ /yes/) ? 1 : 0;

    if ($matchtype =~ /exact/) {
	if ($matchcasep) {
	    $searchtermnc = lc $searchterm;
	} else {
	    $searchtermnc = $searchterm;
	}
	$exactphraseexpr = qr"^$searchtermnc\:\:\:";
	$partialphraseexpr = qr"^[^:]*?$searchtermnc.*?\:\:\:";
    }

    foreach $term (@{$termref}) {
	$cachefile = cache_file_name_from_term ($term);
	next unless (-f $cachefile);

	###
	### If there's a lock file, wait.
	###
	while (valid_lock ("$cachefile.lck")) { }

	open CACHE, "$cachefile" or browser_warn "$cachefile: $!";
      LINE: while (defined ($l = <CACHE>)) {
	  chomp $l;
	  ###
	  ### Verify the entry as early as possible, 
	  ### but delete invalid entries after the cache 
	  ### file has been processed.
	  ###

	  ($targetterm, $targetfn, $targetoffsets) = split /\:\:\:/, $l;

	  unless ($targetfn && _is_valid_targetfile ($targetfn)) {
	      push @bad_entries, ($l);
	      next;
	  }

	  foreach (@selectedvolumes) {
	      next LINE unless $targetfn =~ m"^$_";
	  }

	  next if exists $filed{$targetfn};

	  ###
	  ### Check for exact phrase if the matchtype is exact.
	  ### Unshift exact matches to the front of the list, 
	  ### and push partial matches to the back. Do the same 
	  ### below for each of the search terms.
	  ###
	  if ($matchtype =~ /exact/) {
	      if ($l =~ $exactphraseexpr) {
		  unshift @cachelines, ($l);
		  $filed{$targetfn} = '';
		  next LINE;
	      } elsif ($l =~ $partialphraseexpr) {
		  push @cachelines, ($l);
		  $filed{$targetfn} = '';
		  next LINE;
	      }
	  }

	  $targetterm = lc ($targetterm) unless $matchcasep;
	  if (! $matchcasep) {
	      $termnc = lc $term;
	  } else {
	      $termnc = $term;
	  }

	  if ((defined ($r = &$searchstr ($termnc, $targetterm))) 
	      && ($r == 0)) {
	      unshift @cachelines, ($l);
	  } elsif (defined $r) {
	      push @cachelines, ($l);
	  }
	  ###
	  ### With, "all," type matches, we need to save 
	  ### all possible occurrences of the terms before
	  ### collating them below.
	  ###
	  $filed{$targetfn} = $termnc if $matchtype =~ /any/;
      }
      close CACHE;
    }

    ###
    ### Delete invalid entries.
    ###
    foreach $l (@bad_entries) {
	if (($r = delete_from_cache ($session_id, $l)) < 0) {
	    ($targetfn) = ($l =~ $FILEEXPR);
	    &$logfunc ('error', 
	       "cache_retrieve: $targetfn not found, removing cache entry.");
	} elsif ($r < 0) {
	    &$logfunc ('error', 
      "cache_retrieve: invalid entry for $targetfn not deleted");
	}
    }

    $recordswritten = 0;

    if ($matchtype =~ /any/) {

	foreach $l (@cachelines) {
 	    ($targetfn) = ($l =~ $FILEEXPR);
	    next unless ($targetfn);
	    ###
	    ### Only push the first cache entry for a file.
	    ### This avoids displaying duplicate files 
	    ### later.
	    ###
	    unless (exists $h{$targetfn}) {
		$h{$targetfn} = _new_array_ref ();
		push @{$h{$targetfn}}, ($l);
		$newposting = cache_to_posting (@{$h{$targetfn}});
		if ($newposting) {
		    push @cacherecs, ($newposting) if $newposting;
		    client_write ($session_id, $newposting);
		    ++$recordswritten;
		}
	    } else {
		if (($r = delete_from_cache ($session_id, $l)) == 1) {
		    ($targetfn) = ($l =~ $FILEEXPR);
		    if ($CacheReports) {
			&$logfunc ('notice', 
       "cache_retrieve: removing duplicate $targetfn entry from cache.");
		    }
		} elsif ($r < 0) {
		    &$logfunc ('error', 
	       "cache_retrieve: duplicate $targetfn entry not deleted");
		}
	    }
	}

    } elsif ($matchtype =~ /all/) {

	foreach $l (@cachelines) {
	    ($targetfn) = ($l =~ $FILEEXPR);
	    next unless ($targetfn);
	    unless (exists $h{$targetfn}) {
		$h{$targetfn} = _new_array_ref ();
		push @{$h{$targetfn}}, ($l);
	    } else {
		($term, $offsets) = ($l =~ $WORDOFFSETSEXPR);
		unless (scalar grep /^$term/, @{$h{$targetfn}}) {
		    push @{$h{$targetfn}}, ($l);
		} else {
		    ###
		    ### Remove cache entries that duplicate both 
		    ### the term and the filename.
		    ###
		    if (($r = delete_from_cache ($session_id, $l)) == 1) {
			($targetfn) = ($l =~ $FILEEXPR);
			if ($CacheReports) {
			    &$logfunc ('notice', 
       "cache_retrieve: removing duplicate $targetfn entry from cache.");
			}
		    } elsif ($r < 0) {
			&$logfunc ('error', 
	       "cache_retrieve: duplicate $targetfn entry not deleted");
		    }
		}
	    }
	}

	foreach $targetfn (keys %h) {
	    ###
	    ### TO DO see if we can use a search regex here.
	    ###
	    foreach $term (@{$termref}) {
		if (! $matchcasep) {
		    $termnc = lc $term;
		} else {
		    $termnc = $term;
		}
		delete $h{$targetfn} unless 
		    (scalar grep /$termnc/, @{$h{$targetfn}});
	    }
	}

	###
	### TO DO write posting as soon as cache entry is determined
	### valid.
	###
	foreach $k (keys %h) {
	    $newposting = cache_to_posting (@{$h{$k}});
	    if ($newposting) {
		push @cacherecs, ($newposting);
		client_write ($session_id, $newposting);
		++$recordswritten;
	    }
	}

    } elsif ($matchtype =~ /exact/) {
	my %hpartial;
	foreach $l (@cachelines) {
	    ($targetfn) = ($l =~ $FILEEXPR);
	    next unless ($targetfn);

	    if ($l =~ $partialphraseexpr) {
		###
		### Write phrase entries from the cache.
		###
		unless (exists $h{$targetfn}) {
		    $h{$targetfn} = _new_array_ref ();
		    push @{$h{$targetfn}}, ($l);
		    ###
		    ### Write out the phrase matches.
		    ###
		    $newposting = cache_to_posting (@{$h{$targetfn}});
		    if ($newposting) {
			push @cacherecs, ($newposting);
			client_write ($session_id, $newposting);
			++$recordswritten;
		    }
		} else {
		    if (($r = delete_from_cache ($session_id, $l)) == 1) {
			($targetfn) = ($l =~ $FILEEXPR);
			if ($CacheReports) {
			    &$logfunc ('notice', 
       "cache_retrieve: removing duplicate $targetfn entry from cache.");
			}
		    } elsif ($r < 0) {
			&$logfunc ('error', 
	       "cache_retrieve: duplicate $targetfn entry not deleted");
		    }
		}
	    } else {
		###
		### Push partial entries.
		###
		unless (exists $h{$targetfn}) {
		    foreach $term (@{$termref}) {
			if ($l =~ m"$term") {
			    unless (exists ($hpartial{$targetfn}) || 
				exists ($h{$targetfn})) {
				$hpartial{$targetfn} = _new_array_ref ();
				push @{$hpartial{$targetfn}}, ($l);
			    }
			}
		    }
		}
	    }
	}
	foreach $targetfn (keys %hpartial) {
	    ###
	    ### TO DO see if we can use a search regex here.
	    ### TO DO see if each $hpartial{n} can be an 
	    ### array of vectors.
	    ###
	    foreach $term (@{$termref}) {
		unless (scalar grep /$term/, @{$hpartial{$targetfn}}) {
		    delete $hpartial{$targetfn};
		}
	    }
	}
	###
	### This is the worst-case scenario: finding a phrase from
	### a file containing the unordered set of terms.  Have to 
	### string search... try to keep this to a minimum.  But 
	### text searching here for the first time from existing 
	### cache data makes it unnecessary to repeat the text 
	### search in Search.pm.  Create a new cache-format entry 
	### if successful.
	###
	my ($offsets, $offset_ref);
	foreach $targetfn (keys %hpartial) {
	    $offset_ref = 
		cache_text_search ($searchtermnc, $targetfn, $matchcase);
	    if ($#{$offset_ref} >= 0) {
		$offsets = join ',', @{$offset_ref};
		push @{$h{$targetfn}}, 
                    ($searchtermnc.':::'.$targetfn.':::'.$offsets);
		add_to_cache ($session_id, $h{$targetfn});

		$newposting = cache_to_posting (@{$h{$targetfn}});
		if ($newposting) {
		    push @cacherecs, ($newposting);
		    client_write ($session_id, $newposting);
		    ++$recordswritten;
		}

	    } 
	}
    }
    my $retained = $#cacherecs + 1;
    if ($CacheReports) {
	&$logfunc ('notice', "$recordswritten cache records found, $retained cache records retained.");
    }
    return @cacherecs;
}

sub cache_text_search {
    my $searchterm = $_[0];
    my $path = $_[1];
    my $matchcase = $_[2];

    my ($vf, $offset_ref, $buf, $content, $stnc, $bufnc);
    $vf = OnSearch::VFile -> new;
    $vf -> vfopen ($path);
####
#### FIXME!!!
####
    return undef unless $vf;

    if ($matchcase =~ /no/) {
	$stnc = lc $searchterm;
    } else {
	$stnc = $searchterm;
    }

    $content = '';
    while (1) {
	$buf = $vf -> vfread (1024);
	if ($matchcase =~ /no/) {
	    $bufnc = lc $buf;
	} else {
	    $bufnc = $buf;
	}
	$content .= $bufnc;
	last if length ($buf) < 1024;
    }
    $vf -> vfclose;
    $content =~ s/\n/ /gs;

    return  OnSearch::StringSearch::_search_string ($searchterm, $content);
}

sub cache_file_name_from_term {
    my $term = $_[0];
    my $cachepath = cache_path ();
    my $initial = substr ($term, 0, 1);
    $initial = lc $initial;
    return "$cachepath/$initial";
}

=head2 caching_enabled ();

Returns 1 if caching is enabled, or undef otherwise.

=cut

sub caching_enabled {
    my $cfg = OnSearch::AppConfig -> new;
    my $cachingenabled = $cfg -> str (qw/CacheResults/);
    return ($cachingenabled eq '0') ? undef : 1;
}

sub cache_path { 
    my $cfg = OnSearch::AppConfig -> new;
    my $onsearchdir = $cfg -> str (qw/OnSearchDir/);
    undef $cfg;
    return $ENV{DOCUMENT_ROOT} . "/$onsearchdir/cache"; 
}

sub get_selected_volumes {

    my ($r, $k, $val, @cookies, $vol_prefs);
    my $c = OnSearch::AppConfig -> new;
    my %vols = $c -> Volumes;
    my @voldirs;

    if ($ENV{HTTP_COOKIE}) {
	@cookies = split /\;\s?/, $ENV{HTTP_COOKIE};
	($val) = grep (/onsearchvols/, @cookies);
	if ($val) {
	    ($val) = $val =~ /.*?\=(.*)/ if $val;
	    $vol_prefs = $c -> get_prefs ($val) if $val;
	}
	if (! $val) {
	    push @voldirs, ($vols{Default});
	} else {
	    my @preflist = split /,/, $vol_prefs;
	    foreach $k (keys %vols) {
		next unless scalar grep /$k/, @preflist;
		push @voldirs, ($vols{$k});
	    }
	}
    }
    return @voldirs;
}

1;

__END__

=head1 VERSION AND CREDITS

Written by Robert Kiesling <rkies@cpan.org> and licensed under the 
same terms as Perl.  Refer to the file, "Artistic," for information.

=head1 SEE ALSO

L<OnSearch(3)>

=cut
