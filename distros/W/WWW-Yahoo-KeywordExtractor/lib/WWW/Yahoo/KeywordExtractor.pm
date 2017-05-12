package WWW::Yahoo::KeywordExtractor;

use strict;
use warnings;

use LWP::UserAgent;

use constant KEYWORD_API_URL => 'http://api.search.yahoo.com/ContentAnalysisService/V1/termExtraction';

our $VERSION = '0.5';

sub new {
	my ($class, %args) = @_;
	my $self = bless {%args}, $class;
	return $self;
}

sub extract {
    my ($self, $content) = @_;
    if (! $content) { die 'No content specified'; }
    my $ua = LWP::UserAgent->new();
    my $response = $ua->post(
        KEYWORD_API_URL,
        { 'appid' => 'WWWYahooKeywordExtractor',
        'query' => 'null',
        'context' => $content, }
    );
    if (! $response->is_success()) {
    	die "Error getting data!\n";
    }
    my $xml = $response->content();
    my @results = ();
    while ($xml =~ m!<Result>([^<]*)</Result>!g) {
        push @results, $1;
    }
    return \@results;
}

1;
__END__

=pod

=head1 NAME

WWW::Yahoo::KeywordExtractor - Get keywords from summary text via the Yahoo API

=head1 SYNOPSIS

This module will submit content to the Yahoo keyword extractor API to return
a list of relevant keywords.

  use WWW::Yahoo::KeywordExtractor;
  my $yke = WWW::Yahoo::KeywordExtractor->new();
  my $keywords = $yke->extract('My wife and I love to cook together. Carolyn surprises me with new things to love about her everyday.');
  print join q{}. 'Keyword 1: ', $keywords->[0], "\n";

=head1 SUBROUTINES/METHOD

=head2 new

The new subroutine creates and returns a WWW:Yahoo::KeywordExtractor object.

=head2 extract

This method will return a list of keywords based on sample data. It will die
if there is no 'content' arg given.

Note: In older versions this method would also cache the keywords returned,
however this is no longer the case.

=head1 AUTHOR

Nick Gerakines, C<< <nick at socklabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-yahoo-keywordextractor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Yahoo-KeywordExtractor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Yahoo::KeywordExtractor

You can also look for information at:

=over 4

=item * WWW-Yahoo-KeywordExtractor SVN Repository

L<http://code.sixapart.com/svn/WWW-Yahoo-KeywordExtractor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Yahoo-KeywordExtractor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Yahoo-KeywordExtractor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Yahoo-KeywordExtractor>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Yahoo-KeywordExtractor>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the bright developers at Yahoo for creating a nifty keyword API.

Subbu Allamaraju ( http://www.subbu.org ) gave some good feedback and is also
worth mentioning here.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
