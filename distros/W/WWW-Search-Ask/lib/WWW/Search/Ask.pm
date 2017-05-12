# $Id: Ask.pm,v 1.11 2008/11/30 01:38:15 Martin Exp $

=head1 NAME

WWW::Search::Ask - class for searching www.search.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ask');
  my $sQuery = WWW::Search::escape_query("+sushi restaurant +Columbus Ohio");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a search.com specialization of L<WWW::Search>.  It handles
making and interpreting searches at F<http://www.search.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The query is applied as "ALL these words"
(i.e. boolean AND of all the query terms)

=head1 PRIVATE METHODS

In order to use this module,
you do NOT need to know about these methods;
they are just part of the underlying WWW::Search mechanism.

=over

=cut

#####################################################################

package WWW::Search::Ask;

use strict;
use warnings;

use base 'WWW::Search';

my
$VERSION = do { my @r = (q$Revision: 1.11 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
my $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

use Carp;
use WWW::Search;
use WWW::Search::Result;

=item gui_query

In WWW::Search::Ask, the default query is the same as the GUI query.

=cut

sub gui_query
  {
  my $self = shift;
  return $self->native_query(@_);
  } # gui_query


sub _native_setup_search
  {
  my ($self, $native_query, $native_options_ref) = @_;
  $self->{_debug} = $native_options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
  $self->{_debug} = 0 if (!defined($self->{_debug}));

  # search.com returns 10 hits per page no matter what.
  $self->{'_hits_per_page'} = 10;

  # $self->{agent_e_mail} = 'mthurn@cpan.org';
  $self->user_agent('non-robot');

  $self->{_next_to_retrieve} = 1;
  $self->{'_num_hits'} = 0;

  if (!defined($self->{_options}))
    {
    $self->{'search_base_url'} = 'http://www.ask.com';
    $self->{_options} = {
                         'search_url' => $self->{'search_base_url'} .'/web',
                         'q' => $native_query,
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
  } # _native_setup_search


sub _preprocess_results_page_OFF
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
  my $hits_found = 0;
  if (! $self->approximate_result_count)
    {
    print STDERR " DDD   look for RC...\n" if 2 <= $self->{_debug};
    my $oTITLE = $oTree->look_down(_tag => 'div',
                                   class => 'T7',
                                  );
    if (ref $oTITLE)
      {
      my $sRC = $oTITLE->as_text;
      print STDERR " +   RC == $sRC\n" if 2 <= $self->{_debug};
      if ($sRC =~ m!SHOWING(?:\sRESULTS)?\s+\d+\s*-\s*\d+\s+OF\s+(?:ABOUT\s+)?([0-9,]+)!i)
        {
        my $sCount = $1;
        print STDERR " +     raw    count == $sCount\n" if 3 <= $self->{_debug};
        $sCount =~ s!,!!g;
        print STDERR " +     cooked count == $sCount\n" if 3 <= $self->{_debug};
        $self->approximate_result_count($sCount);
        } # if number pattern matches
      } # if found DIV
    } # if don't have approx count yet
  my $sScore = '';
  my $sSize = '';
  my $sDate = '';
  my @aoDIV = $oTree->look_down('_tag' => 'div',
                                'class' => 'T1',
                               );
 DIV_TAG:
  foreach my $oDIVdesc (@aoDIV)
    {
    next DIV_TAG unless ref $oDIVdesc;
    my $sDesc = $oDIVdesc->as_text;
    print STDERR " +   found desc ===$sDesc===\n" if 2 <= $self->{_debug};
    my $oDIV = $oDIVdesc->left;
    next DIV_TAG unless ref $oDIV;
    my $oAtitle = $oDIV->look_down(_tag => 'a',
                                   class => 'L4');
    next DIV_TAG unless ref $oAtitle;
    my $sTitle = $oAtitle->as_text;
    my $sURL = $oAtitle->attr('href');
    my $hit = new WWW::Search::Result;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description(&strip($sDesc));
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach DIV_TAG
SKIP_RESULTS_LIST:
  # Find the next link, if any:
  my @aoAnext = $oTree->look_down('_tag' => 'a',
                                  # class => 'L7',
                                 );
 NEXT_LINK:
  while (my $oAnext = pop(@aoAnext))
    {
    if (ref $oAnext)
      {
      my $s = $oAnext->as_text;
      print STDERR " +   oAnext is ===$s===\n" if 2 <= $self->{_debug};
      if ($s =~ m!\ANext!)
        {
        $self->{_next_url} = $self->absurl($self->{'_prev_url'},
                                           $oAnext->attr('href'));
        last NEXT_LINK;
        } # if
      } # if
    } # while
 SKIP_NEXT_LINK:
  return $hits_found;
  } # _parse_tree


=item strip

=cut

sub strip
  {
  my $sRaw = shift;
  my $s = &WWW::Search::strip_tags($sRaw);
  # Strip leading whitespace:
  $s =~ s!\A[\240\t\r\n\ ]+  !!x;
  # Strip trailing whitespace:
  $s =~ s!  [\240\t\r\n\ ]+\Z!!x;
  return $s;
  } # strip

1;

__END__

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Originally written by Martin Thurn,
based loosely on the code for C<WWW::Search::Search>.

=head1 LICENSE

This software is released under the same license as Perl itself.

=cut
