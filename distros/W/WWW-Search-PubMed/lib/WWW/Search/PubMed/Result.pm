package WWW::Search::PubMed::Result;

=head1 NAME

WWW::Search::PubMed::Result - NCBI Search Result

=head1 SYNOPSIS

 use WWW::Search;
 my $s = new WWW::Search ('PubMed');
 $s->native_query( 'ACGT' );
 while (my $result = $s->next_result) {
  print $result->title . "\n";
  print $result->description . "\n";
  print $result->pmid . "\n";
  print $result->abstract . "\n";
 }

=head1 DESCRIPTION

WWW::Search::PubMed::Result objects represent query results returned
from a WWW::Search::PubMed search. See L<WWW::Search:PubMed> for more
information.

=head1 VERSION

This document describes WWW::Search::PubMed version 1.004,
released 31 October 2007.

=head1 REQUIRES

 L<WWW::Search::PubMed|WWW::Search::PubMed>

=head1 METHODS

=over 4

=cut

our($VERSION)	= '1.004';

use strict;
use warnings;

use base qw(WWW::Search::Result);

our $debug				= 0;

=item C<< abstract >>

The article abstract.

=cut

sub abstract { return shift->_elem('abstract', @_); }

=item C<< pmid >>

The article PMID.

=cut

sub pmid { return shift->_elem('pmid', @_); }


=item C<< date >>

The article's publication date ("YYYY Mon DD").

=cut

sub date { return shift->_elem('date', @_); }

=item C<< year >>

The article's publication year.

=cut

sub year { return shift->_elem('year', @_); }

=item C<< month >>

The article's publication month.

=cut

sub month { return shift->_elem('month', @_); }

=item C<< day >>

The article's publication day.

=cut

sub day { return shift->_elem('day', @_); }


1;

__END__

=back

=head1 COPYRIGHT

Copyright (c) 2003-2007 Gregory Todd Williams. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=cut
