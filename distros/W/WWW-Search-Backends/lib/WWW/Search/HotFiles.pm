# HotFiles.pm
# by Jim Smyser
# Copyright (C) 1996-1998 by USC/ISI
# $Id: HotFiles.pm,v 2.12 2008/02/01 02:50:26 Daddy Exp $
# Complete copyright notice follows below.

=head1 NAME

WWW::Search::HotFiles - class for searching ZDnet HotFiles

=head1 SYNOPSIS

require WWW::Search;
$search = new WWW::Search('HotFiles');

=head1 DESCRIPTION

Class for searching ZDnet HotFiles (shareware, freeware) via Lycos.
F<http://www.hotfiles.lycos.com>.

If you use the raw method for this backend you will need to include
a "<p>" at end of your print statement, example:
     print $result->raw(), "<p>\n";

This is so that each result returned will have a HTML break since
the HTML is being extracted from tables, and, there is no <p> or 
<br> trailing returned HITS to properly format the results. No
BIG deal really.

Print optioins:
Using score will return nice star images for rating purposes
at end of each description line for each HIT if desired.

Using index_date will return the files date.

Raw returns description, star rating image, date, downloads, 
OS version.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 USAGE EXAMPLE

 One of several print samples for this backend (this is a WebSearch
 example):

 print <<END;
 <FONT SIZE=2><B>$count. <a href="$prefix$_">$result->{'title'}</A></B><BR>
 $result->{'description'} 
 $result->{'index_date'} $result->{'score'}<P></SMALL></FONT>
 END

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 AUTHOR

Maintained by Jim Smyser <jsmyser@bigfoot.com>

=head1 TESTING

HotFiles.pm adheres to the WWW::Search test mechanism.
See $TEST_CASES below.

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

package WWW::Search::HotFiles;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 2.12 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $MAINTAINER = 'Jim Smyser <jsmyser@bigfoot.com>';
my $TEST_CASES = <<"ENDTESTCASES";
&test('HotFiles', '$MAINTAINER', 'zero', \$bogus_query, \$TEST_EXACTLY);
&test('HotFiles', '$MAINTAINER', 'one', 'replication', \$TEST_RANGE, 2,24);
&test('HotFiles', '$MAINTAINER', 'two', 'Medicine', \$TEST_GREATER_THAN, 25);
ENDTESTCASES

use Carp ();
use WWW::Search(generic_option);
use WWW::SearchResult;

# private
sub native_setup_search
  {
  my ($self, $native_query, $native_options_ref) = @_;
  # Set some private variables:
  $self->{_debug} = $native_options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
  $self->{_debug} ||= 0;

  my $DEFAULT_HITS_PER_PAGE = 25;
  $DEFAULT_HITS_PER_PAGE = 25 if $self->{_debug};
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;
  # Add one to the number of hits needed, because Search.pm does ">"
  # instead of ">=" on line 672!
  my $iMaximum = 1 + $self->maximum_to_retrieve;
  # Divide the problem into N pages of K hits per page.
  my $iNumPages = 1 + int($iMaximum / $self->{'_hits_per_page'});
  if (1 < $iNumPages)
    {
    $self->{'_hits_per_page'} = 1 + int($iMaximum / $iNumPages);
    } 
  else {
    $self->{'_hits_per_page'} = $iMaximum;
    }
  $self->{agent_e_mail} = 'jsmyser@bigfoot.com';
  $self->user_agent(1);
  $self->{'_next_to_retrieve'} = 0;
  $self->{'_num_hits'} = 0;
  if (!defined($self->{_options})) {
    $self->{_options} = {
                         'search_url' => 'http://www.hotfiles.lycos.com/cgi-bin/texis/swlib/lycos/search.html',
                         'Usrt' => 'rel&Usrchtype=simple&search_max=26',
                         'Utext' => $native_query,
                        };
    }
  my $options_ref = $self->{_options};
  if (defined($native_options_ref))
    {
    # Copy in new options.
    foreach (keys %$native_options_ref)
      {
      $options_ref->{$_} = $native_options_ref->{$_};
      } # foreach
    } # if
  # Process the options.
  my $options = '';
  foreach (keys %$options_ref)
    {
    # printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
    next if (generic_option($_));
    $options .= $_ . '=' . $options_ref->{$_} . '&';
    } # foreach
  # Finally, figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;
  } # native_setup_search

sub begin_new_hit
  {
  my($self) = shift;
  my($old_hit) = shift;
  my($old_raw) = shift;
  # Save it
  if (defined($old_hit)) {
    $old_hit->raw($old_raw) if (defined($old_raw));
    push(@{$self->{cache}}, $old_hit);
    }
  ;
  # Make a new hit.
  return (new WWW::SearchResult, '');
  } # begin_new_hit

# private
sub native_retrieve_some
  {
  my ($self) = @_;
  # Fast exit if already done:
  return undef unless defined($self->{_next_url});
  # Sleep so as to not overload the server for next page(s)
  print STDERR "***Sending request (",$self->{_next_url},")\n" if $self->{'_debug'};
  my $response = $self->http_request('GET', $self->{_next_url});
  $self->{response} = $response;
  unless ($response->is_success)
    {
    return undef;
    }
  print STDERR "***Picked up a response..\n" if $self->{'_debug'};
  $self->{'_next_url'} = undef;
  # Parse the output
  my ($HEADER, $HITS, $DESC, $TRAILER) = qw(HE HH DE TR);
  my ($raw) = '';
  my $hits_found = 0;
  my $state = $HEADER;
  my $hit;
  foreach ($self->split_lines($response->content()))
    {
    next if m/^$/;          # short circuit for blank lines
    print STDERR " *** $state ===$_===" if 2 <= $self->{'_debug'};
    
    if ($state eq $HEADER && m@\<TR BGCOLOR="#FFFFFF">@i) 
      {
      $state = $HITS;
      }
    elsif ($state eq $HITS && m@\<TD ALIGN=left>\<FONT SIZE=2>\<b>\<A HREF="([^"]+)">(.*)\</FONT>\</A>\<BR>@i) 
      {
      print STDERR "hit url line\n" if 2 <= $self->{'_debug'};
      ($hit, $raw) = $self->begin_new_hit($hit, $raw);
      $raw .= $_;
      $self->{'_num_hits'}++;
      $hits_found++;
      $hit->add_url($1);
      $hit->title($2);
      $state = $DESC;
      }
    elsif ($state eq $DESC && m@^\<FONT SIZE=2>(.*)@) 
      {
      print STDERR "hit description line\n" if 2 <= $self->{'_debug'};
      $raw .= $_;
      $hit->description($1);
      $state = $HITS;
      }
    elsif ($state eq $HITS && m@\<TD>&nbsp;\</TD>@) 
      {
      $raw .= $_;
      # Get the date, most I think like to see a file date w/desc..
      }
    elsif ($state eq $HITS && m@\<TD NOWRAP ALIGN=left>(.*)\</TD>@) 
      {
      $raw .= $_;
      $hit->index_date($1);
      # the score here will display rating star images for a nice touch...
      }
    elsif ($state eq $HITS && m@\<TD ALIGN=left>(\<IMG SRC=(.+)>)@) 
      {
      $raw .= $_;
      $hit->score($1);
      }
    elsif ($state eq $HITS && m@\<TD ALIGN=left>\<FONT SIZE=2>(.*)@) 
      {
      $raw .= $_;
      }
    elsif ($state eq $HITS && m@\<TD ALIGN=left>\<FONT SIZE=2>(.*)\</FONT>\</TD>@) 
      {
      $raw .= $_;
      }
    elsif ($state eq $HITS && m@\<p>@i) 
      {
      # end of hits
      }
    elsif ($state eq $HITS && m/\<INPUT\s[^>]*VALUE=\"Hits\s(.+)\"/i) 
      {
      print STDERR " found next button\n" if 2 <= $self->{'_debug'};
      $self->{'_next_to_retrieve'} += $self->{'_hits_per_page'};
      $self->{'_options'}{'mainnext'} = $self->{'_next_to_retrieve'};
      my($options) = '';
      foreach (keys %{$self->{_options}})
        {
        next if (generic_option($_));
        $options .= $_ . '=' . $self->{_options}{$_} . '&';
        }
      # Finally, figure out the url.
      $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;
      $state = $TRAILER;
      } 
    else 
      {
      print STDERR "didn't match\n" if 2 <= $self->{'_debug'};
      }
    } # foreach line of input 
  if ($state ne $TRAILER)
    {
    # no other pages missed
    $self->{_next_url} = undef;
    }
  return $hits_found;
  } # native_retrieve_some

1;

__END__
