
# $Id: Japan.pm,v 1.8 2008/12/25 18:55:43 Martin Exp $

=head1 NAME

WWW::Search::Yahoo::Japan - WWW::Search backend for searching Yahoo! Japan

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::Japan');
  my $sQuery = WWW::Search::escape_query("Iijima Ai");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo! Japan specialization of L<WWW::Search>.  It
handles making and interpreting searches on Yahoo! Japan
F<http://yahoo.co.jp>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 OPTIONS

If your query is in UTF-8, send option {ei => 'UTF-8'}
in the second argument to native_query().

=head1 PRIVATE METHODS

=cut

package WWW::Search::Yahoo::Japan;

use strict;
use warnings;

use Data::Dumper;  # for debugging only
use WWW::Search::Yahoo 2.377;
use base 'WWW::Search::Yahoo';

our
$VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub _native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                         p => $sQuery,
                         # Caller should send this option if desired:
                         # ei => 'UTF-8',
                         n => 100,
                         dups => 1,
                        };
  $rh->{'search_base_url'} = 'http://search.yahoo.co.jp';
  $rh->{'search_base_path'} = '/search';
  return $self->SUPER::_native_setup_search($sQuery, $rh);
  } # _native_setup_search

sub _where_to_find_count
  {
  my %hash = (
              _tag => 'div',
              id => 'yschinfo',
             );
  return \%hash;
  } # _where_to_find_count

sub _string_has_count
  {
  my $self = shift;
  my $s = shift;
  return $1 if ($s =~ m{([,0-9]+)Ã¤Â»Â¶\s+-\s+}i);
  return $1 if ($s =~ m{([,0-9]+)\344\273\266\s+-\s+}i);
  return $1 if ($s =~ m{([,0-9]+)&auml;&raquo;&para;\s+-\s+}i);
  return -1;
  } # _string_has_count

sub _result_list_tags_OFF
  {
  return (
          _tag => 'div',
          class => 'i',
         );
  } # _result_list_tags


sub _result_list_items
  {
  my $self = shift;
  my $oTree = shift || die;
  my @aoDIV = $oTree->look_down(
                                _tag => 'div',
                                class => 'web'
                               );
  return @aoDIV;
  } # _result_list_items

sub _a_is_next_link
  {
  my $self = shift;
  my $oA = shift;
  return 0 unless (ref $oA);
  my $s = $oA->as_text;
  return 1 if ($s =~ m!æ¬¡ã¸!i);
  return 1 if ($s =~ m!æ¬¡\343\201\270!i);
  return 1 if ($s =~ m!\346\254\241\343\201\270!i);
  return 1 if ($s =~ m!æ¬¡&atilde;&#129;&cedil;!i);
  } # _a_is_next_link


=head2 parse_details

This is part of the basic WWW::Search::Yahoo mechanism.

=cut

sub parse_details
  {
  my $self = shift;
  # Required arg1 = (part of) an HTML parse tree:
  my $oLI = shift;
  # Required arg2 = a WWW::SearchResult object to fill in:
  my $hit = shift;
  my $oTR = $oLI->look_down(_tag => 'div',
                            class => 'abs',
                           );
  if (ref $oTR)
    {
    $hit->description($oTR->as_text);
    } # if
  else
    {
    # warn
    }
  } # parse_details

1;

__END__

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 AUTHOR

Martin Thurn <mthurn@cpan.org>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut
