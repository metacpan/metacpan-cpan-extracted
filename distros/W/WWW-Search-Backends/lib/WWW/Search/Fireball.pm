#!/usr/local/bin/perl -w

#
# Fireball.pm
# by Andreas Borchert
# nearly everything has been shamelessly copied from:
# $Id: Fireball.pm,v 2.12 2008/02/01 02:50:25 Daddy Exp $

=head1 NAME

WWW::Search::Fireball - class for searching Fireball


=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Fireball');


=head1 DESCRIPTION

This class is an Fireball specialization of WWW::Search.
It handles making and interpreting Fireball searches
F<http://www.fireball.de>.

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

C<WWW::Search::Fireball> has been shamelessly copied by
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

package WWW::Search::Fireball;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 2.12 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Carp ();
use WWW::Search qw( generic_option strip_tags );
use WWW::SearchResult;

my $MAINTAINER = 'Jim Smyser <jsmyser@bigfoot.com>';
my $TEST_CASES = <<"ENDTESTCASES";
&test('Fireball', '$MAINTAINER', 'zero', '4036e7757s5', \$TEST_EXACTLY);
&test('Fireball', '$MAINTAINER', 'one', 'iR'.'over', \$TEST_RANGE, 1,9);
&test('Fireball', '$MAINTAINER', 'multi', '+a'.'sh +mis'.'ty', \$TEST_GREATER_THAN, 10);
ENDTESTCASES


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
    # http://www.fireball.de/query-fireball.fcg?action=query&pg=express&q=Jobwunder&what=german_web&fmt=d
        $self->{_options} = {
        'action' => 'query',
        'pg' => 'express',
        'what' => 'german_web',
        'fmt' => 'd',
        'search_url' => 'http://www.fireball.de/query-fireball.fcg',
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
    "q=" . $native_query;
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
    print STDERR "**Fetching-> " . $self->{_next_url} . "\n" if ($self->{_debug});
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;
    if (!$response->is_success) {
    return undef;
    };
    print STDERR "**Got Response**\n" if ($self->{_debug});
    # parse the output
    my($HEADER, $HITS, $DESC, $TRAILER, $POST_NEXT, $FINISH) = (1..10);  # order matters
    my($hits_found) = 0;
    my($state) = ($HEADER);
    my($hit) = undef;
    my($raw) = '';
    foreach ($self->split_lines($response->content())) {
        next if m@^$@; # short circuit for blank lines
      if ($state == $HEADER &&
           m|von\s(\d+)\sTreffern|i) {
        # current variants:
        # Dokument 1-10 von 221 Treffern, beste Treffer zuerst.
        # Keine passenden Dokumente gefunden
        my($n) = $1;
        $n =~ s/\.//g;
        $self->approximate_result_count($n);
        print STDERR "HEADER->HIT: $n documents found.\n" if 2 < $self->{_debug};
        $state = $HITS;
     } elsif ($state == $HITS && m@<b><a href="([^"]+)">(.*)$@i) {
       my $sURL = $1;
       next if $sURL =~ m/heavymetal.fireball.de/;
       print STDERR "HIT FOUND.\n" if ($self->{_debug} >= 2);
       ($hit, $raw) = $self->begin_new_hit($hit, $raw);
       $raw .= $_;
       $hit->add_url($sURL);
       $hits_found++;
       $hit->title(&strip_tags($2));
       $state = $HITS;
    } elsif ($state == $HITS &&
       m@<td><font FACE.*?>(.*)<br></font><font FACE=.*?>@i) {
       print STDERR "HITS->Description.\n" if ($self->{_debug} >= 2);
       $raw .= $_;
       $hit->description($1) if (defined($hit));

    } elsif ($state == $HITS && m@^<!--- end hits --->@i) {
        print STDERR "HITS->TRAILER.\n" if ($self->{_debug} >= 2);
        ($hit, $raw) = $self->begin_new_hit($hit, $raw);
        $state = $TRAILER;

    } elsif ($state == $TRAILER && m|<b><A HREF="(.*?)"\s+TARGET=_top>n&auml;chste\sSeite</A>|i) {
        my($relative_url) = $1;
        $self->{_next_url} = new URI::URL($relative_url, $self->{_base_url});
        $state = $POST_NEXT;
        print STDERR "Next URL: $self->{_next_url}\n" if ($self->{_debug} >= 2);
    } else {
        # accumulate raw
        $raw .= $_;
        print STDERR "PARSE(RAW): $_\n" if ($self->{_debug} >= 3);
        };
        };
    if ($state != $POST_NEXT) {
        # end, no other pages (missed ``next'' tag)
    if ($state == $HITS) {
        $self->begin_new_hit($hit, $raw);   # save old one
        print STDERR "PARSE: never got to TRAILER.\n" if ($self->{_debug} >= 2);
        };
        $self->{_next_url} = undef;
        };
        # sleep so as to not overload fireball
        $self->user_agent_delay if (defined($self->{_next_url}));
        return $hits_found;
        }

1;

__END__
