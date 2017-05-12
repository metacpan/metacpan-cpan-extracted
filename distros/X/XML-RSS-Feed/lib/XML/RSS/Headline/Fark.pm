package XML::RSS::Headline::Fark;
use strict;
use warnings;
use base qw(XML::RSS::Headline);
use URI::Escape qw(uri_unescape);

our $VERSION = 2.32;

sub item {
    my ( $self, $item ) = @_;
    $self->SUPER::item($item);    # set url and description

    my $headline = $self->headline;
    $headline =~ s/\[.+?\]\s+//;
    $self->headline($headline);

    my $domain = qr{ http [:] [/] [/] go [.] fark [.] com }x;
    my $uri    = qr{ [/] cgi [/] fark [/] go [.] pl }x;
    my $args   = qr{ [?] IDLink [=] \d+ [&] location [=] }x;

    my $url = $self->url;
    $url =~ s/$domain$uri$args//;
    $self->url( uri_unescape($url) );

    return;
}

1;

__END__

=head1 NAME

XML::RSS::Headline::Fark - XML::RSS::Headline Example Subclass

=head1 VERSION

2.32

=head1 SYNOPSIS

Strip out the extra Fark redirect URL and strip out the various [blahblah]
blocks in the headline

    use XML::RSS::Feed;
    use XML::RSS::Headline::Fark;
    use LWP::Simple qw(get);

    my $feed = XML::RSS::Feed->new(
	name  => "fark",
	url   => "http://www.pluck.com/rss/fark.rss",
	hlobj => "XML::RSS::Headline::Fark",
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

Here is the before output in #news on irc.perl.org

    <rssbot>  - [Sad] Elizabeth Edwards diagnosed with breast cancer
    <rssbot>    http://go.fark.com/cgi/fark/go.pl?IDLink=1200026&location=http://www.msnbc.msn.com/id/6408022

and here is the updated output   

    <rssbot>  - Elizabeth Edwards diagnosed with breast cancer
    <rssbot>    http://www.msnbc.msn.com/id/6408022

=head1 MUTAITED METHOD

=over 4

=item B<< $headline->item( $item ) >>

Init the object for a parsed RSS item returned by L<XML::RSS>.

=back

=head1 AUTHOR

Jeff Bisbee, C<< <jbisbee at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-rss-feed at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-RSS-Feed>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::RSS::Headline::Fark

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-RSS-Feed>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-RSS-Feed>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-RSS-Feed>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-RSS-Feed>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to Rocco Caputo, Martijn van Beers, Sean Burke, Prakash Kailasa
and Randal Schwartz for their help, guidance, patience, and bug reports. Guys 
thanks for actually taking time to use the code and give good, honest feedback.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jeff Bisbee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::RSS::Feed>, L<XML::RSS::Headline>, L<XML::RSS::Headline::PerlJobs>, L<XML::RSS::Headline::UsePerlJournals>, L<POE::Component::RSSAggregator>

