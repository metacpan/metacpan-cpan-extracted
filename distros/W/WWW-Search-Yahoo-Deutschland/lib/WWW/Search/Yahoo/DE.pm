
=head1 NAME

WWW::Search::Yahoo::DE - class for searching Yahoo! Deutschland (Germany)

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::DE');
  my $sQuery = WWW::Search::escape_query("mein Deutsch ist schlecht");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    {
    print $oResult->url, "\n";
    } # while

=head1 DESCRIPTION

This module is just a synonym for WWW::Search::Yahoo::Deutschland.

=head1 AUTHOR

Martin Thurn (mthurn@cpan.org).

=cut

package WWW::Search::Yahoo::DE;

use strict;
use warnings;

use base 'WWW::Search::Yahoo::Deutschland';

our
$VERSION = do { my @r = (q$Revision: 2.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

1;

__END__

