# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2002,2012 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Tk::Pod::Cache;
use strict;
use vars qw($VERSION $MAX_CACHE %CACHE);

BEGIN {  # Make a DEBUG constant very first thing...
  if(defined &DEBUG) {
  } elsif(($ENV{'TKPODDEBUG'} || '') =~ m/^(\d+)/) { # untaint
    my $debug = $1;
    *DEBUG = sub () { $debug };
  } else {
    *DEBUG = sub () {0};
  }
}

$VERSION = '5.02';

$MAX_CACHE = 20; # documents # XXX not yet used, LRU etc...

sub add_to_cache {
    my($w, $pod) = @_;
    $pod = $w->cget(-path) if !defined $pod;
    return if !defined $pod;
    return if $CACHE{$pod}; # XXX check for recentness
    DEBUG and warn "Add contents for $pod to cache.\n";
    $CACHE{$pod} = $w->dump_contents;
}

sub get_from_cache {
    my($w, $pod) = @_;
    $pod = $w->cget(-path) if !defined $pod;
    return 0 if !$CACHE{$pod};
    # XXX check for recentness
    $w->delete("1.0", "end");
    DEBUG and warn "Restore contents for $pod from cache.\n";
    $w->restore_contents($CACHE{$pod});
    1;
}

sub delete_from_cache {
    my($w, $pod) = @_;
    $pod = $w->cget(-path) if !defined $pod;
    return if !defined $pod;
    DEBUG and warn "Delete contents for $pod from cache.\n";
    delete $CACHE{$pod};
}

sub clear_cache {
    %CACHE = ();
}

sub dump_contents {
    my $w = shift;
    my @dump = $w->dump('-all', "1.0", "end");
    if (@dump == 0) {
	warn "Workaround strange bug under RedHat 8.0 --- try dump again...";	
	@dump = $w->dump('-all', "1.0", "end");
	if (@dump == 0) {
	    warn "Giving up, cache disabled for current page";
	    return undef;
	}
    }
    my %tags_def;
    foreach my $tag ($w->tagNames) {
	# XXX check for used/existing tags missing
	my @tag_def;
	foreach my $item ($w->tagConfigure($tag)) {
	    my $value  = $item->[4];
	    my $option = $item->[0];
	    push @tag_def, $option, $value;
	}
	$tags_def{$tag} = \@tag_def;
    }
    return {Dump => \@dump,
	    Tags => \%tags_def,
	    Sections => $w->{'sections'},
	    PodTitle => $w->{'pod_title'},
	   };
}

sub restore_contents {
    my($w, $def) = @_;

    my $dumpref = $def->{Dump};
    my $tagref  = $def->{Tags};
    $w->{'sections'}  = $def->{Sections};
    $w->{'pod_title'} = $def->{PodTitle};

    $w->toplevel->title( "Tkpod: " . $w->{'pod_title'} . " (restoring)");
    $w->idletasks;
    # XXX  Is it bad form to manipulate the top level?

    my $process_no;
    $w->{ProcessNo}++;
    $process_no = $w->{ProcessNo};

    if ($tagref) {
	while(my($tag,$def) = each %$tagref) {
	    #XXX tagDelete?
	    $w->tagConfigure($tag, @$def);
	}
    }

    my @taglist;

    my $last_update = Tk::timeofday();
    for(my $i=0; $i<$#$dumpref; $i+=3) {
	my($key, $val, $index) = @{$dumpref}[$i..$i+2];
	if      ($key eq 'text') {
	    $w->insert($index, $val, [@taglist]);
	} elsif ($key eq 'tagon') {
	    unshift @taglist, $val;
	} elsif ($key eq 'tagoff') {
	    my $j;
	    for (0 .. $#taglist) {
		if ($taglist[$_] eq $val) {
		    $j = $_;
		    last;
		}
	    }
	    if (defined $j) {
		splice @taglist, $j, 1;
	    }
	    $w->tag('remove', $val, 'insert');
	} elsif ($key eq 'mark') {
	    $w->markSet($val, $index); # XXX ->see() to current or insert?
	} elsif ($key eq 'windows') {
	    die "not yet supported";
	} elsif ($key eq 'image') {
	    die "not yet supported";
	} elsif ($key eq 'imgdef') {
	    die "not yet supported";
	}

	if (Tk::timeofday() > $last_update+0.5) { # XXX make configurable
	    $w->update;
	    $last_update = Tk::timeofday();
	    do { warn "ABORT!"; return } if $w->{ProcessNo} != $process_no;
	}
    }

    $w->parent->add_section_menu if $w->parent->can('add_section_menu');
    $w->Callback('-poddone', $w->cget(-file));

    $w->toplevel->title( "Tkpod: " . $w->{'pod_title'});
}

1;

__END__

=head1 NAME

Tk::Pod::Cache - internal Tk-Pod module for cache control

=head1 DESCRIPTION

No user-servicable parts here.

=cut
