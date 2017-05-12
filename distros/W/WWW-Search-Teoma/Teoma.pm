# Teoma.pm
# by Jim Schneider
# Copyright (C) 2002, JRCS, Inc.
# Originally based on WWW::Search::AltaVista.pm

package WWW::Search::Teoma;
use strict;

=head1 NAME

WWW::Search::Teoma - class for searching www.teoma.com


=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Teoma');


=head1 DESCRIPTION

This class is a Teoma specialization of WWW::Search.
It handles making and interpreting Teoma searches
F<http://www.teoma.com>.  It is loosely based on the WWW::Search::AltaVista
class written by John Heidemann.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 SEE ALSO

L<WWW::Search>, L<WWW::Search::AltaVista>


=head1 AUTHOR

C<WWW::Search::Teoma> was hacked by Jim Schneider,
<perl@jrcsdevelopment.com>, using C<WWW::Search::AltaVista> as a guide.
C<WWW::Search::AltaVista> was written by John Heidemann,
<johnh@isi.edu>.  C<WWW::Search::AltaVista> is maintained by Martin Thurn,
<mthurn@cpan.org>.

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

Parts are copyright (c) 2002, JRCS, Inc.

=cut

#####################################################################

our @ISA = qw(WWW::Search);
our $VERSION = '0.01';

use Carp ();
use WWW::Search qw( generic_option unescape_query );
require WWW::SearchResult;

# private
sub native_setup_search
  {
  my($self, $native_query, $native_options_ref) = @_;
  $self->user_agent('user');
  $self->{_next_to_retrieve} = 0;
  if (!defined($self->{_options}))
    {
    $self->{_options} = {
                         'search_url' => 'http://s.teoma.com/search',
                        };
    } # if
  my($options_ref) = $self->{_options};
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
  foreach my $key (keys %$options_ref)
    {
    next if (generic_option($key));
    $options .= $key . '=' . $options_ref->{$key} . '&';
    } # foreach
  $self->{_debug} = $options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
  $self->{_debug} = 0 if (!defined($self->{_debug}));

  # Finally figure out the url.
  $self->{_base_url} = 'http://s.teoma.com/';
  $self->{_next_url} =
  $self->{_options}{'search_url'} . "?q=" . $native_query;
  print STDERR $self->{_next_url} . "\n" if ($self->{_debug});
  } # native_setup_search

# private
sub native_retrieve_some
{
    my ($self) = @_;

    # fast exit if already done
    return undef if (!defined($self->{_next_url}));

    # get some
    print STDERR "WWW::Search::Teoma::native_retrieve_some: fetching " . $self->{_next_url} . "\n" if ($self->{_debug});
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;
    if (!$response->is_success)
      {
      print STDERR " +   failed: $response\n" if ($self->{_debug});
      return undef;
      } # if

    # Clear the next URL first
    $self->{_next_url} = undef;
    # parse the output
    my($HEADER, $HITS, $INHIT, $DESC, $URL, $TRAILER, $POST_NEXT) = (1..10);  # order matters
    my($hits_found) = 0;
    my($state) = ($HEADER);
    my($hit) = undef;
    my($raw) = '';
    foreach ($self->split_lines($response->content()))
      {
      next if m@^$@; # short circuit for blank lines
      print STDERR "PARSE(0:RAW): $_\n" if ($self->{_debug} >= 3);
      if (0) { }

      ######
      # HEADER PARSING: find the number of hits
      #
      elsif ($state == $HEADER && m|<span id="ResultsControl_estimatedResults">(\d+(,\d+)*)|)
        {
        my($n) = $1;
        $n =~ s/,//g;
        $self->approximate_result_count($n);
        print STDERR "PARSE(10:HEADER->HITS): $n documents found.\n" if ($self->{_debug} >= 2);
        return 0 unless 0 < $n;
        $state = $HITS;
        }

        ######
        # HITS PARSING: find each hit
        #
      elsif ($state == $HITS && m|<span class="resultTxt">|i)
      {
	$state = $INHIT;
	print STDERR "PARSE(HITS): Start of hit.\n" if $self->{_debug}>=2;
	push @{$self->{cache}}, $hit if $hit;
	$hit = new WWW::SearchResult;
	$hits_found++;
      }
      elsif ($state == $INHIT && m|<a\s+href=".*\&u=([^&="]*)">(.*)</a>|i)
      {
      	$state = $DESC;
	$hit->title($1);
	$hit->add_url($1);
	print STDERR "PARSE(INHIT): Title: $1\n" if $self->{_debug}>=2;
      }
      elsif ($state == $DESC && m|\s+(.*)\s*<br\s*/>|i)
      {
      	$state = $HITS;
	$hit->description($1);
	print STDERR "PARSE(DESC): Description found.\n" if $self->{_debug}>=2;
      }
      elsif ($state == $HITS && m|href="(search?[^"]*)">>></a>|i)
      {
      	$self->{_next_url} = $self->{_base_url} . $1;
	print STDERR "PARSE(HITS): Found next URL\n", if $self->{_debug}>=2;
	last;
      }
      else
      {
      	print STDERR "*** No match ***\n" if $self->{_debug}>=2;
      }

    }
    # sleep so as to not overload Teoma
    $self->user_agent_delay if (defined($self->{_next_url}));

    push @{$self->{cache}}, $hit if $hit;
    return $hits_found;
    } # native_retrieve_some

1;

