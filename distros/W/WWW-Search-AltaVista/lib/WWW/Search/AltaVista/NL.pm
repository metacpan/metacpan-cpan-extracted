#
# NL.pm
# by Erik Smit
# Copyright (C) 1996-1998 by USC/ISI
# Copyright (C) 2001 by Different Soft
# $Id: NL.pm,v 1.113 2008/01/21 02:04:11 Daddy Exp $
#
# Complete copyright notice follows below.
#


=head1 NAME

WWW::Search::AltaVista::NL - class for searching the dutch version of Alta Vista 

=head1 SYNOPSIS

  require WWW::Search;
  $search = new WWW::Search('AltaVista::NL');

=head1 DESCRIPTION

This class is an modified version of the AltaVista specialization of WWW::Search.
It handles making and interpreting Dutch AltaVista searches
F<http://nl.altavista.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 OPTIONS

The default is for simple web queries.

=over 8

=item search_url=URL

Specifies who to query with the AltaVista protocol.
The default is at
C<http://nl.altavista.com/cgi-bin/query>;

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=item pg=aq

Do advanced queries.
(It defaults to simple queries.)

=back

=head1 PUBLIC METHODS

There are none defined here; see WWW::Search.

=cut

#####################################################################

package WWW::Search::AltaVista::NL;

use strict;
use warnings;

use base 'WWW::Search::AltaVista';
use Carp ();
use WWW::Search qw( generic_option );
use WWW::SearchResult;
our
$VERSION = do { my @r = (q$Revision: 1.113 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 PRIVATE METHODS

=head2 native_setup_search

This private method does the heavy lifting after you call native_query().

=cut

sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    # set the text=yes option to provide next links with <a href>
    # (suggested by Guy Decoux <decoux@moulon.inra.fr>).
    if (!defined($self->{_options})) {
	$self->{_options} = {
	    'pg' => 'q',
	    'text' => 'yes',
	    'what' => 'nl',
	    'fmt' => 'd',
	    'search_url' => 'http://nl.altavista.com/cgi-bin/query',
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
    # (Now in sorted order for consistency regarless of hash ordering.)
    my($options) = '';
    foreach (sort keys %$options_ref) {
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
	"q=" . $native_query;
    print STDERR $self->{_base_url} . "\n" if ($self->{_debug});
}

# private
sub _save_old_hit {
    my($self) = shift;
    my($old_hit) = shift;
    my($old_raw) = shift;

    if (defined($old_hit)) {
	$old_hit->raw($old_raw) if (defined($old_raw));
	push(@{$self->{cache}}, $old_hit);
    };

    return(undef, undef);
}

# private
sub _begin_new_hit
{
    my($self) = shift;
    my($old_hit) = shift;
    my($old_raw) = shift;

    $self->_save_old_hit($old_hit, $old_raw);

    # Make a new hit.
    return (new WWW::SearchResult, '');
}


=head2 native_retrieve_some

This private method does the heavy lifting of fetching and parsing web pages.

=cut

sub native_retrieve_some
{
    my ($self) = @_;

    # fast exit if already done
    return undef if (!defined($self->{_next_url}));

    # get some
    print STDERR "WWW::Search::AltaVistaNL::native_retrieve_some: fetching " . $self->{_next_url} . "\n" if ($self->{_debug});
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;
    if (!$response->is_success) {
	return undef;
    };

# parse the output
    my($HEADER, $HITS, $INHIT, $TRAILER, $POST_NEXT) = (1..10);  # order matters
    my($hits_found) = 0;
    my($state) = ($HEADER);
    my($hit) = undef;
    my($raw) = '';
    foreach ($self->split_lines($response->content())) {
        next if m@^$@; # short circuit for blank lines
	######
	# HEADER PARSING: find the number of hits
	#
	if (0) {
	} elsif ($state == $HEADER && /AltaVista vond geen documenten voor uw zoekbewerking/i) {
	    # 25-Oct-99
	    $self->approximate_result_count(0);
	    $state = $TRAILER;
	    print STDERR "PARSE(10:HEADER->HITS): no documents found.\n" if ($self->{_debug} >= 2);
        ######
	} elsif ($state == $HEADER && /([\d,]+) gevonden? pagina's/i) {
	    # 25-Oct-99
	    my($n) = $1;
	    $n =~ s/,//g;
	    $self->approximate_result_count($n);
	    $state = $HITS;
	    print STDERR "PARSE(10:HEADER->HITS): $n documents found.\n" if ($self->{_debug} >= 2);
	######
	# HITS PARSING: find each hit
	#
	} elsif ($state == $HITS && /(<table width="100%" align="center">)/i) {
$state = $TRAILER;
	    print STDERR "PARSE(11:HITS->TRAILER): done.\n" if ($self->{_debug} >= 2);

	} elsif ($state == $HITS && /<dl><dt>/i) {
	    # 25-Oct-99
	    ($hit, $raw) = $self->_begin_new_hit($hit, $raw);
	    $hits_found++;
	    $raw .= $_;
	    $state = $INHIT;
	    print STDERR "PARSE(12:HITS->INHIT): hit start.\n" if ($self->{_debug} >= 2);

	} elsif ($state == $INHIT && /^<b>URL: <\/b><FONT color="#777777">([^"]+)<br>/i) { #"
	    # 25-Oct-99
	    $raw .= $_;
	    $hit->add_url($1);
	    print STDERR "PARSE(13:INHIT): url: $1.\n" if ($self->{_debug} >= 2);

	} elsif ($state == $INHIT && /^<a.*HREF.*>(.+)<\/a>.*<\/dt>/i) {
	    # 25-Oct-99
	    $raw .= $_;
	    my($title) = $1;
	    # $title =~ s/<\/?em>//ig;  # strip keyword emphasis (use raw if you want to get it bacK)
	    $hit->title($title);
	    print STDERR "PARSE(13:INHIT): title: $1.\n" if ($self->{_debug} >= 2);

	} elsif ($state == $INHIT && /^<dd>(.*)<br>/i) {
	    # 25-Oct-99
	    $raw .= $_;
	    $hit->description($1);
	    print STDERR "PARSE(13:INHIT): description.\n" if ($self->{_debug} >= 2);

	} elsif ($state == $INHIT && /^Laatste wijziging: (.*)$/i) {
	    # 25-Oct-99
	    $raw .= $_;
	    $hit->change_date($1);
	    print STDERR "PARSE(13:INHIT): mod date.\n" if ($self->{_debug} >= 2);

	} elsif ($state == $INHIT && /^<\/dl>/i) {
	    # 25-Oct-99
	    $raw .= $_;
	    ($hit, $raw) = $self->_save_old_hit($hit, $raw);
	    $state = $HITS;
	    print STDERR "PARSE(13:INHIT->HITS): end hit.\n" if ($self->{_debug} >= 2);

	} elsif ($state == $INHIT) {
	    # other random stuff in a hit---accumulate it
	    $raw .= $_;
	    print STDERR "PARSE(14:INHIT): no match.\n" if ($self->{_debug} >= 2);
            print STDERR ' 'x 12, "$_\n" if ($self->{_debug} >= 3);

	} elsif ($hits_found && ($state == $TRAILER || $state == $HITS) && /<a[^>]+href="([^"]+)".*\&gt;\&gt;/i) { # "
	    # (above, note the trick $hits_found so we don't prematurely terminate.)
	    # set up next page
	    my($relative_url) = $1;
	    # hack:  make sure fmt=d stays on news URLs
	    $relative_url =~ s/what=news/what=news\&fmt=d/ if ($relative_url !~ /fmt=d/i);
            my($n) = new URI::URL($relative_url, $self->{_base_url});
            $n = $n->abs;
            $self->{_next_url} = $n;	    $state = $POST_NEXT;
	    print STDERR "PARSE(15:->POST_NEXT): found next, $n.\n" if ($self->{_debug} >= 2);

	} else {
	    # accumulate raw
	    $raw .= $_;
	    print STDERR "PARSE(RAW): $_\n" if ($self->{_debug} >= 3);
	};
    };
    if ($state != $POST_NEXT) {
	# end, no other pages (missed ``next'' tag)
	if ($state == $HITS) {
	    $self->_begin_new_hit($hit, $raw);   # save old one
	    print STDERR "PARSE: never got to TRAILER.\n" if ($self->{_debug} >= 2);
	};
	$self->{_next_url} = undef;
    };

    # sleep so as to not overload altavista
    $self->user_agent_delay if (defined($self->{_next_url}));

    return $hits_found;
}

1;

__END__

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,


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


=head1 AUTHOR and CURRENT VERSION

C<WWW::Search::AltaVista::NL> is written and maintained
by Erik Smit, <zoiah@zoiah.nl>.

The best place to obtain C<WWW::Search::AltaVista::NL>
is from Martin Thurn's WWW::Search releases on CPAN.
Because AltaVista sometimes changes its format
in between his releases, sometimes more up-to-date versions
can be found at
F<http://www.zoiah.nl/programming/AltaVistaNL/index.html>.


=head1 COPYRIGHT

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


