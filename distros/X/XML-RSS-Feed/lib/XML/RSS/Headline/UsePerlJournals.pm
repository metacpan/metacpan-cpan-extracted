package XML::RSS::Headline::UsePerlJournals;
use strict;
use warnings;
use base qw(XML::RSS::Headline);

our $VERSION = 2.32;

sub item {
    my ( $self, $item ) = @_;
    $self->SUPER::item($item);    # set url and description

    my $headline = $self->headline;
    my $url      = $self->url;
    my ($id) = $url =~ /\/\~(.+?)\//;
    $headline =~ s/\s+\(.+\)\s*$//;

    $self->headline("[$id] $headline");

    return;
}

1;

__END__

=head1 NAME

XML::RSS::Headline::UsePerlJournals - XML::RSS::Headline Example Subclass

=head1 VERSION

2.32

=head1 SYNOPSIS

You can also subclass XML::RSS::Headline to tweak the rss content to your 
liking.  In this example. I change the headline to remove the date/time 
and add the Use Perl Journal author's ID.  Also in this use Perl; rss 
feed you get the actual link to the journal entry, rather than the link 
just to the user's journal.  (meaning that the journal URLs contain 
the entry's ID)

    use XML::RSS::Feed;
    use XML::RSS::Headline::UsePerlJournals;
    use LWP::Simple qw(get);

    my $feed = XML::RSS::Feed->new(
	name  => "useperljournals",
	hlobj => "XML::RSS::Headline::UsePerlJournals",
	delay => 60,
	url   => "http://use.perl.org/search.pl?tid=&query=&" 
                 . "author=&op=journals&content_type=rss",
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

Here is the output from rssbot on irc.perl.org in channel #news (which uses
these modules)

    <rssbot>  + [pudge] New Cool Journal RSS Feeds at use Perl;
    <rssbot>    http://use.perl.org/~pudge/journal/21884

=head1 MUTAITED METHOD

=head2 $headline->item( $item )

Init the object for a parsed RSS item returned by L<XML::RSS>.

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

    perldoc XML::RSS::Headline::UsePerlJournals

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

L<XML::RSS::Feed>, L<XML::RSS::Headline>, L<XML::RSS::Headline::PerlJobs>, L<XML::RSS::Headline::Fark>, L<POE::Component::RSSAggregator>

