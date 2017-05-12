# Profusion.pm
# by Jim Smyser
# Copyright (c) 1999 by Jim Smyser & USC/ISI
# $Id: Profusion.pm,v 2.22 2008/02/01 02:50:27 Daddy Exp $

=head1 NAME

WWW::Search::Profusion - class for searching Profusion.com!


=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Profusion');

=head1 DESCRIPTION

This class uses the Meta Search Engine F<http://www.profusion.com>.
Search engines searched are: 1) AltaVista 2) InfoSeek 3) Snap 4)
Excite 5) LookSmart 6) WebCrawler 7) Magellan 8) Yahoo 9) GoTo

Most of the above defaults to Boolean. Profusion returns all retrieved
hits to one page, so, there is no next page retrievals.  

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 USAGE OPTIONS

There is 5 possible option values for type of search (default is All):
Simple
All 
Any 
Boolean
Phrase

To search different categories with Profusion you simpy change the
the base search_url to one of the following:

Newsgroups = http://usenet.profusion.com/
Health = http://health.profusion.com/
Entertainment = http://entertainment.profusion.com/
Sports = http://sports.profusion.com/
MP3 = http://mp3.profusion.com/

You can turn on totalverify=0 to weed out any bad links returned, but be 
warned it is slowwwwww.  totalverify=20 would verify first 20 links and
so on....

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,
or the specialized AltaVista searches described in options.

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

C<WWW::Search::Profusion> is written and maintained
by Jim Smyser - <jsmyser@bigfoot.com>.

=head1 TESTING

This backend returns ALL results to *one* page.

This backend adheres to the C<WWW::Search> test mechanism.
See $TEST_CASES below.      
        
=head1 COPYRIGHT

Copyright (c) 1996-1999 University of Southern California.
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

=head1 VERSION HISTORY

2.01 New test mechanism.

1.05 Fix for new format change. Returning of search engine name 
with the description along with the full url of the found link.  

1.04 Fix for format change. Added striping of <b> tags in title so 
description does not get bolded over.

1.03 fixes minor parsing error where some hits were being ignored.
Also added returning of all HTML (raw).

=cut

package WWW::Search::Profusion;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 2.22 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $MAINTAINER = 'Jim Smyser <jsmyser@bigfoot.com>';
my $TEST_CASES = <<"ENDTESTCASES";
&test('Profusion', '$MAINTAINER', 'zero', \$bogus_query, \$TEST_EXACTLY);
&test('Profusion', '$MAINTAINER', 'one', 'astronomy', \$TEST_GREATER_THAN, 10);
ENDTESTCASES

use Carp ();
use WWW::Search(generic_option);
require WWW::SearchResult;

# private
sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->{agent_e_mail} = 'jsmyser@bigfoot.com';
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
    $self->{_options} = {
     'search_url' => 'http://www.profusion.com/cgi-bin/nph-ProFusion.pl',
     'option' => 'default', # see USAGE OPTIONS
     'display' => 'all&summary=yes&totalverify=0&auto=all&engine1=AltaVista&engine4=InfoSeek&engine5=LookSmart&engine2=Excite&engine8=Magellan&engine6=WebCrawler&engine9=GoTo&engine3=Google&engine7=Yahoo&search=web&log=yes&current=0&customEngines=1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C9&pid=profusion',

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
    "queryterm=" . $native_query;
    print $self->{_base_url} . "\n" if ($self->{_debug});
}

# private
sub native_retrieve_some
{
    my ($self) = @_;

    # fast exit if already done
    return undef if (!defined($self->{_next_url}));

    # get some
    print STDERR "**Fetching some....\n" if 2 <= $self->{_debug};
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;
    if (!$response->is_success) {
    return undef;
    };
    # parse the output
    my($HEADER, $HITS, $DESC) = (1..10);
    my($hits_found) = 0;
    my($state) = ($HEADER);
    my($hit, $raw, $title, $url, $desc) = ();
   foreach ($self->split_lines($response->content())) {
        next if m@^$@; # short circuit for blank lines
    if ($state == $HEADER && m@<td valign="top"><br>@i) { 
        print STDERR "PARSE(HEADER->HITS-1): $_\n" if ($self->{_debug} >= 2);
        $state = $HITS;                                                                                      

 } elsif ($state == $HITS && m@.*?<a href="/cgi-bin/process_result.pl.?url==([^"]+)\&engine.*?>(.*)</a>&nbsp;.*?(<i>(.*))</font><br>@i) { 
        print STDERR "**Parsing URL, Title & Desc...\n" if 2 <= $self->{_debug};
        my ($url, $title, $description) = ($1,$2,$3);
        my($hit) = new WWW::SearchResult;
        $title =~ s/<b>//g;
        $hit->add_url($url);
        $hit->title($title);
        $hit->description($description);
        $hit->raw($_);
        $hits_found++;
        push(@{$self->{cache}}, $hit);
        $state = $HITS;
#  Ignoring 'next' page url's since I am not defining them. 
    print STDERR "**All done!**\n" if 2 <= $self->{_debug};
    };
    if (defined($hit)) {
        push(@{$self->{cache}}, $hit);
    };
    $self->{_next_url} = undef;
    };
    return $hits_found;
}

1;

__END__
