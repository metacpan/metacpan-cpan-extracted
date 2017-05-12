
=head1 NAME

WWW::Search::Yahoo::Deutschland - class for searching Yahoo! Deutschland (Germany)

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::Deutschland');
  my $sQuery = WWW::Search::escape_query("Perl OOP Freelancer");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    {
    print $oResult->url, "\n";
    } # while

=head1 DESCRIPTION

This class is a Yahoo! Deutschland (Germany) specialization of
L<WWW::Search>.  It handles making and interpreting searches on Yahoo!
Deutschland (Germany) F<http://de.yahoo.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 TESTING

There are no tests defined for this module.

=head1 AUTHOR

C<WWW::Search::Yahoo::Deutschland> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

package WWW::Search::Yahoo::Deutschland;

use strict;
use warnings;

use Data::Dumper;  # for debugging only
use WWW::Search::Yahoo;

use vars qw( @ISA $VERSION $MAINTAINER );
@ISA = qw( WWW::Search::Yahoo );

$VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

=head2 native_setup_search


See WWW::Search for documentation.

=cut

sub native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  # print STDERR " +   in Deutschland::native_setup_search, rh is ", Dumper($rh);
  $self->{'_options'} = {
                         'p' => $sQuery,
                         'y' => 'y',   # german sites only
                         n => 100,
                        };
  $rh->{'search_base_url'} = 'http://de.search.yahoo.com';
  $rh->{'search_base_path'} = '/search/de';
  # print STDERR " +   Yahoo::Deutschland::native_setup_search() is calling SUPER::native_setup_search()...\n";
  return $self->SUPER::native_setup_search($sQuery, $rh);
  } # native_setup_search


sub _string_has_count
  {
  my $self = shift;
  my $s = shift;
  # print STDERR " DDD Deutschland::_string_has_count($s)?\n";
  return $1 if ($s =~ m!\bvon\s+(?:(?:etwa|ungefähr)\s+)?([,.0-9]+)!i);
  return -1;
  } # _string_has_count

sub _a_is_next_link
  {
  my $self = shift;
  my $oA = shift;
  return 0 unless (ref $oA);
  my $sID = $oA->attr('id') || '';
  return 1 if ($sID eq 'pg-next');
  my $s = $oA->as_text;
  my $WS = q{[\t\r\n\240\ ]};
  return ($s =~ m!\A$WS*weitere$WS+&gt;$WS*\z!i);
  } # _a_is_next_link


1;

__END__

