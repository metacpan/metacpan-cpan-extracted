#!/usr/local/bin/perl -w

#
# Crawler.pm
# by Andreas Borchert
# nearly everything has been shamelessly copied from:
#
# AltaVista.pm
# by John Heidemann
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Crawler.pm,v 1.5 2008/02/01 02:50:25 Daddy Exp $
#
# Complete copyright notice follows below.
#


=head1 NAME

WWW::Search::Crawler - class for searching Crawler


=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Crawler');


=head1 DESCRIPTION

This class is an Crawler specialization of WWW::Search.
It handles making and interpreting Fireball searches
F<http://www.crawler.de>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.


=head1 HOW DOES IT WORK?

C<native_setup_search> is called before we do anything.
It initializes our private variables (which all begin with underscores)
and sets up a URL to the first results page in C<{_next_url}>.

C<native_retrieve_some> is called (from C<WWW::Search::retrieve_some>)
whenever more hits are needed.  It calls the LWP library
to fetch the page specified by C<{_next_url}>.
It parses this page, appending any search hits it finds to 
C<{cache}>.  If it finds a ``next'' button in the text,
it sets C<{_next_url}> to point to the page for the next
set of results, otherwise it sets it to undef to indicate we're done.


=head1 AUTHOR

C<WWW::Search::Crawler> has been shamelessly copied by
Andreas Borchert, <borchert@mathematik.uni-ulm.de> from
C<WWW::Search::AltaVista> by John Heidemann, <johnh@isi.edu>.


=head1 COPYRIGHT

The original parts from John Heidemann are subject to
following copyright notice:

Copyright (c) 1996-1998 University of Southern California.
All rights reserved.                                            
                                                               
Redistribution and use in source and binary forms are permitted
provided that the above copyright notice and this paragraph are
duplicated in all such forms and that any documentation, advertising
materials, and other materials related to such distribution and use
acknowledge that the software was developed by the University of
Southern California, Information Sciences Institute.  The name of the
University may not be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut
#'

#
#  Test cases:
# ./altavista.pl xxxasdf                        --- no hits
# ./altavista.pl '"lsam replication"'           --- single page return
# ./altavista.pl '+"john heidemann" +work'      --- 9 page return
#



#####################################################################

package WWW::Search::Crawler;

use strict;
use warnings;

use base 'WWW::Search';

use Carp ();
use WWW::Search(generic_option);
use WWW::SearchResult;

our
$VERSION = do { my @r = ( q$Revision: 1.5 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

sub undef_to_emptystring {
    return defined($_[0]) ? $_[0] : "";
}


# private
sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    # set the text=yes option to provide next links with <a href>
    # (suggested by Guy Decoux <decoux@moulon.inra.fr>).
    if (!defined($self->{_options})) {
	# defaults:
	# http://crawler.de/suche.php3?Maschine=Crawler&Custom=Crawler&query=zisterzienser
	$self->{_options} = {
	    'Maschine' => 'Crawler',
	    'Custom' => 'Crawler',
	    'search_url' => 'http://crawler.de/suche.php3',
        };
    };
    my($options_ref) = $self->{_options};
    if (defined($native_options_ref)) {
	# Copy in new options.
	foreach (keys %$native_options_ref) {
	    $options_ref->{$_} = $native_options_ref->{$_};
	};
    };
    # Process the options.
    my($options) = '';
    foreach (keys %$options_ref) {
	# printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
	next if (generic_option($_));
	$options .= $_ . '=' . $options_ref->{$_} . '&';
    };
    $self->{_debug} = $options_ref->{'search_debug'};
    $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    
    # Finally figure out the url.
    $self->{_base_url} = 
	$self->{_next_url} =
	$self->{_options}{'search_url'} .
	"?" . $options .
	"query=" . $native_query;
    print $self->{_base_url} . "\n" if ($self->{_debug});
}

# private
sub begin_new_hit
{
    my($self) = shift;
    my($old_hit) = shift;
    my($old_raw) = shift;

    # Save the hit we were working on.
    if (defined($old_hit)) {
	$old_hit->raw($old_raw) if (defined($old_raw));
	push(@{$self->{cache}}, $old_hit);
    };

    # Make a new hit.
    return (new WWW::SearchResult, '');
}


# private
sub native_retrieve_some
{
    my ($self) = @_;

    # fast exit if already done
    return undef if (!defined($self->{_next_url}));

    # get some
    print STDERR "WWW::Search::Crawler::native_retrieve_some: fetching " . $self->{_next_url} . "\n" if ($self->{_debug});
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;
    if (!$response->is_success) {
	return undef;
    };

    # parse the output
    my($HEADER, $HITS, $DESC, $POST_NEXT) = (1..10);  # order matters
    my($hits_found) = 0;
    my($state) = ($HEADER);
    my($hit) = undef;
    my($raw) = '';
    foreach ($self->split_lines($response->content())) {
        next if m@^$@; # short circuit for blank lines
	if ($state == $HEADER &&
	       /^Meine Nachforschungen sind leider erfolglos geblieben/) {
	    $self->approximate_result_count(0);
	    print STDERR "PARSE(2:HEADER->POST_NEXT): no documents found.\n" if ($self->{_debug} >= 2);
	    $state = $POST_NEXT;
        }
	elsif ($state == $HEADER &&
	       m{
		  <select\s.*>
		  <option>.*?:(\d+)$
	       }xi) {
	    # actual end of line:
	    # <SELECT Name = "menu0" ><OPTION>zisterzienser:1401

	    my($n) = $1;
	    $n =~ s/\.//g;
	    $self->approximate_result_count($n);
	    $state = $HITS;
	    print STDERR "PARSE(2:HEADER->HITS): $n documents found.\n" if ($self->{_debug} >= 2);
	} elsif ($state == $HITS &&
	      m{
		 ^<b>\d+\.\s*\&nbsp;
		 <a\shref="(.*)$
	      }xi) {
	    # actual line:
	    # <b>1. &nbsp;<A HREF="http://www.bistum-essen.de/bochum/zisterzienser/

	    ($hit, $raw) = $self->begin_new_hit($hit, $raw);
	    $raw .= $_;
	    $hit->add_url($1);
	    $hits_found++;
	    print STDERR "PARSE(3:HITS->DESC): hit found.\n" if ($self->{_debug} >= 2);
	    $state = $DESC;
	} elsif ($state == $DESC &&
	    m{
	       ^">(.*?)</a>              # $1: title
	       </b><br><font\ssize=-1>
	       (.*?)                     # $2: description
	       </font><br>
	    }xi) {
	    $hit->title($1);
	    $hit->description($2);
	    $state = $HITS;
	    print STDERR "PARSE(3:DESC->HITS): description found.\n" if ($self->{_debug} >= 2);
	} elsif (($state == $HITS || $state == $DESC) &&
	       m{
		  <a\shref="(.*?)">
		  <img\ssrc="http://crawler.de/images/w.gif"
	       }ix) {
	    # set up next page
	    # <TABLE border=0><TR><TD ALIGN=CENTER><a href="http://www.Crawler.de/suche.php3?show=840126.1&Maschine=Crawler&Custom=Crawler"><img src="http://Crawler.de/images/w.gif" border=0 width=47 height=42></a></TD></TR>
	    # <TD ALIGN=CENTER><a href="http://www.Crawler.de/suche.php3?show=320630.2&Maschine=Crawler&Custom=Crawler"><img src="http://Crawler.de/images/w.gif" border=0 width=47 height=42></a></TD></TR>

	    my($relative_url) = $1;
	    $self->{_next_url} = new URI::URL($relative_url, $self->{_base_url});
	    $state = $POST_NEXT;
	    print STDERR "Next URL: $self->{_next_url}\n" if ($self->{_debug} >= 2);
	    print STDERR "PARSE(9a:HITS/DESC->POST_NEXT): found next.\n" if ($self->{_debug} >= 2);
	} else {
	    # accumulate raw
	    $raw .= $_;
	    print STDERR "PARSE(RAW): $_\n" if ($self->{_debug} >= 3);
	};
    };
    if ($state != $POST_NEXT) {
	# end, no other pages (missed ``next'' tag)
	$self->{_next_url} = undef;
    };

    # sleep so as to not overload fireball
    # $self->user_agent_delay if (defined($self->{_next_url}));

    return $hits_found;
}

1;

__END__

