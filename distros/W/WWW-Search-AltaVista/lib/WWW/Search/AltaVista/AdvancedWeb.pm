#############################################################
# AdvancedWeb.pm
# by Jim Smyser
# Copyright (c) 1999 by Jim Smyser & USC/ISI
# $Id: AdvancedWeb.pm,v 2.85 2008/01/21 02:04:50 Daddy Exp $
#############################################################

package WWW::Search::AltaVista::AdvancedWeb;

use strict;
use warnings;

=head1 NAME

WWW::Search::AltaVista::AdvancedWeb - class for advanced Alta Vista web searching

=head1 SYNOPSIS

  use WWW::Search;
  my $search = new WWW::Search('AltaVista::AdvancedWeb');
  $search->native_query(WWW::Search::escape_query('(bmw AND mercedes) AND NOT (used OR Ferrari)'));
  $search->maximum_to_retrieve('100'); 
  while (my $result = $search->next_result())
    {
    print $result->url, "\n";
    }

=head1 DESCRIPTION

Class hack for Advance AltaVista web search mode originally written by  
John Heidemann F<http://www.altavista.com>. 

This hack now allows for AltaVista AdvanceWeb search results
to be sorted and relevant results returned first. Initially, this 
class had skiped the 'r' option which is used by AltaVista to sort
search results for relevancy. Sending advance query using the 
'q' option resulted in random returned search results which made it 
impossible to view best scored results first.  

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 HELP

Use AND to join two terms that must both be present for a
document to count as a match.

Use OR to join two terms if either one counts.

Use AND NOT to join two terms if the first must be present and
the second must NOT.

Use NEAR to join two terms if they both must appear and be within
10 words of each other.

Try this example:

cars AND bmw AND mercedes 

You don't have to capitalize the "operators" AND, OR, AND NOT, or
NEAR. But many people do to make it clear what is a query term
and what is an instruction to the search engine.

One other wrinkle that's very handy: you can group steps together
with parentheses to tell the system what order you want it to
perform operations in.

(bmw AND mercedes) NEAR cars AND NOT (used OR Ferrari) 

Keep in mind that grouping should be used as much as possible
because if you attempt to enter a long query using AND to join
the words you may not receive any results because the entire
query would be like one long phrase. For best reuslts follow
the example herein.

=head1 AUTHOR

C<WWW::Search> hack by Jim Smyser, <jsmyser@bigfoot.com>.

=head1 COPYRIGHT

Copyright (c) 1996 University of Southern California.
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

2.07 - unescape URLs, and bugfix for undefined $hit

2.06 - do not use URI::URL

2.02 - Added HELP POD. Misc. Clean-up for latest changes.

2.01 - Additional query modifiers added for even better results.

2.0 - Minor change to set lowercase Boolean operators to uppercase.

1.9 - First hack version release.

=cut

#####################################################################

use WWW::Search qw( generic_option );
use WWW::Search::AltaVista;
use base 'WWW::Search::AltaVista';

our
$VERSION = do { my @r = (q$Revision: 2.85 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head2 native_setup_search

This private method does the heavy lifting after native_query() is called.

=cut

sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    # Upper case all lower case Boolean operators. Be nice if
    # I could just uppercase the entire string, but this may
    # have undesirable search side effects.
    if (!defined($self->{_options}))
      {
      $self->{_options} =
        {
         'pg' => 'aq',
         'avkw' => 'tgz',
         'aqmode' => 'b',
         'kl' => 'XX',
         'nbq' => 50,
         'd2' => 0,
         'aqb' => $native_query,
         'search_url' => 'http://www.altavista.com/sites/search/web',
        };
      } # if
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

    # Here I remove known Boolean operators from the 'r' query option 
    # which is used by AltaVista to sort the results. Finally, clean 
    # up by removing as many of the double ++'s as possibe left behind.
    $native_query =~ s/\bAND\b//ig;
    $native_query =~ s/\bOR\b//ig;
    $native_query =~ s/\bNOT\b//ig;
    $native_query =~ s/\bNEAR\b//ig;
    $native_query =~ s/"//g;
    $native_query =~ s/%28//g;
    $native_query =~ s/%29//g;
    $native_query =~ s/(\w)\053\053/$1\053/g;
    # strip down the query words
    $native_query =~ s/\W*(\w+\W+\w+\w+\W+\w+).*/$1/;
    $self->{_base_url} = 
    $self->{_next_url} =
    $self->{_options}{'search_url'} .
    "?" . $options .
    "r=" . $native_query;
    } # native_setup_search

# All other methods are inherited from WWW::Search::AltaVista

1;

__END__

http://www.altavista.com/sites/search/web?pg=aq&avkw=tgz&aqa=&aqp=&aqn=&aqmode=b&aqb=LSAM+AND+AutoSearch&aqs=&kl=XX&dt=tmperiod&d2=0&d0=&d1=&rc=rgn&sgr=all&swd=&lh=&nbq=50

