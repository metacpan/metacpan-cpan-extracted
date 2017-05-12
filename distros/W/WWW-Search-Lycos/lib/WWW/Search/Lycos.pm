# Lycos.pm
# by Wm. L. Scheding and Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Lycos.pm,v 2.223 2008/12/15 22:47:13 Martin Exp $

=head1 NAME

WWW::Search::Lycos - class for searching www.lycos.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Lycos');
  my $sQuery = WWW::Search::escape_query("+sushi restaurant +Columbus Ohio");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Lycos specialization of L<WWW::Search>.  It handles
making and interpreting Lycos-site searches F<http://www.lycos.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

Warning!  As of 2004-01, lycos.com often returns an error page in
place of the third page of results.  So it is very difficult to get
more than 20 hits for any query!

www.lycos.com is sometimes slow to respond; but I have not had a
problem with the default timeout.

www.lycos.com does not give the date nor size of the pages at the
resulting URLs; therefore change_date() and size() will never have a
value.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

As of 1998-12-07, C<WWW::Search::Lycos> is maintained by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Lycos> was originally written by Martin Thurn,
based on C<WWW::Search::Yahoo> version 1.12 of 1998-10-22.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Lycos;

use strict;
use warnings;

my
$VERSION = 2.225;
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

use Carp;
use URI::Escape;
use base 'WWW::Search';
use WWW::Search::Result;

sub gui_query
  {
  my $self = shift;
  my $sQuery = shift;
  $self->{_options} = {
                       search_url => q{http://search.lycos.com/},
                       query => $sQuery,
                      };
  return $self->native_query(@_);
  } # gui_query


sub native_setup_search
  {
  my ($self, $native_query, $native_options_ref) = @_;
  $self->{_debug} = $native_options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
  $self->{_debug} = 0 if (!defined($self->{_debug}));

  # lycos.com returns 10 hits per page no matter what.
  $self->{'_hits_per_page'} = 10;

  # $self->{agent_e_mail} = 'mthurn@cpan.org';
  $self->user_agent('non-robot');

  $self->{_next_to_retrieve} = 1;
  $self->{'_num_hits'} = 0;

  if (! defined($self->{_options}))
    {
    $self->{'search_base_url'} = 'http://search.lycos.com';
    $self->{_options} = {
                         'search_url' => $self->{'search_base_url'} .'/web/',
                         'q' => $native_query,
                         # 'loc' => 'searchbox',
                         # 'tab' => 'web',
                        };
    } # if

  my $options_ref = $self->{_options};

  # Copy in options which were passed in our second argument:
  if (defined($native_options_ref))
    {
    foreach (keys %$native_options_ref)
      {
      $options_ref->{$_} = $native_options_ref->{$_};
      } # foreach
    } # if

  # Copy in options which were set by a child object:
  if (defined($self->{'_child_options'}))
    {
    foreach (keys %{$self->{'_child_options'}})
      {
      $self->{'_options'}->{$_} = $self->{'_child_options'}->{$_};
      } # foreach
    } # if

  # Finally figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
  } # native_setup_search


sub preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  print STDERR '='x 10, $sPage, '='x 10, "\n";
  return $sPage;
  } # preprocess_results_page


sub _parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  warn " DDD start Lycos::_parse_tree()\n" if (3 <= $self->{_debug});
  my $hits_found = 0;
  unless ($self->approximate_result_count)
    {
    my $oTITLE = $oTree->look_down(
                                   _tag => 'div',
                                   class => 'search-numbers',
                                  );
    if (ref $oTITLE)
      {
      my $sRC = $oTITLE->parent->as_text;
      warn " DDD   RC == $sRC\n" if 2 <= $self->{_debug};
      if ($sRC =~ m!\b([0-9,]+)\s*results\b!i)
        {
        my $sCount = $1;
        warn " DDD     raw    count == $sCount\n" if 3 <= $self->{_debug};
        $sCount =~ s!,!!g;
        warn " DDD     cooked count == $sCount\n" if 3 <= $self->{_debug};
        $self->approximate_result_count($sCount);
        } # if
      } # if
    } # unless
  my ($sURL, $sTitle, $sDesc);
  my $sScore = '';
  my $sSize = '';
  my $sDate = '';
  my @aoIS = $oTree->look_down(_tag => 'h2',
                               class => 'result-title',
                              );
 IS_TAG:
  foreach my $oIS (@aoIS)
    {
    next IS_TAG unless ref $oIS;
    warn " DDD   oIS is ===". $oIS->as_HTML ."===\n" if 2 <= $self->{_debug};
    my $sTitle = $oIS->as_text;

    my $oTDhit = $oIS->parent;
    next IS_TAG unless ref $oTDhit;
    warn " DDD   oTDhit is ===". $oTDhit->as_HTML ."===\n" if 2 <= $self->{_debug};
    my $oSPAN = $oTDhit->look_down(_tag => 'span',
                                   class => 'result-url');
    my $sURL = 'http://'. $oSPAN->as_text;
    $oSPAN = $oTDhit->look_down(_tag => 'span',
                                class => 'result-description');
    my $sDesc = $oSPAN->as_text;
    warn " DDD   found desc ===$sDesc===\n" if 2 <= $self->{_debug};

    my $hit = new WWW::Search::Result;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description(_strip($sDesc));
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach $oB
  # Find the next link, if any:
  my @aoA = $oTree->look_down(_tag => 'a',
                             sub { $_[0]->as_text eq 'Next' } );
 A_TAG:
  # We want the last "next" link on the page:
  my $oA = $aoA[-1];
  if (ref $oA)
    {
    warn " DDD   oAnext is ===", $oA->as_HTML, "===\n" if 2 <= $self->{_debug};
    $self->{_next_url} = $self->absurl($self->{'_prev_url'}, $oA->attr('href'));
    } # if
 SKIP_NEXT_LINK:

  return $hits_found;
  } # _parse_tree


sub _strip
  {
  my $sRaw = shift;
  my $s = &WWW::Search::strip_tags($sRaw);
  # Strip leading whitespace:
  $s =~ s!\A[\240\t\r\n\ ]+  !!x;
  # Strip trailing whitespace:
  $s =~ s!  [\240\t\r\n\ ]+\Z!!x;
  return $s;
  } # _strip

1;

__END__
