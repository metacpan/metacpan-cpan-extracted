package XML::RSS::Headline::PerlJobs;
use strict;
use warnings;
use base qw(XML::RSS::Headline);

our $VERSION = 2.32;

sub item {
    my ($self,$item) = @_;
    $self->SUPER::item($item); # set url and description

    my $key = 'http://jobs.perl.org/rss/';

    my $name     = $item->{$key}{company_name}     || '';
    my $location = $item->{$key}{location}         || 'Unknown Location';
    my $hours    = $item->{$key}{hours}            || 'Unknown Hours';
    my $terms    = $item->{$key}{employment_terms} || 'Unknown Terms';

    my $name_location = $name ? $name . ' - ' . $location : $location;
    $self->headline("$item->{title}\n$name_location\n$hours, $terms");

    return;
}

1;

__END__

=head1 NAME

XML::RSS::Headline::PerlJobs - XML::RSS::Headline Example Subclass

=head1 VERSION

2.32

=head1 SYNOPSIS

You can also subclass XML::RSS::Headline to provide a 'multiline' RSS headline
based on additional information inside the RSS Feed.  Here is an example for 
the Perl Jobs (jobs.perl.org) RSS feed by simply passing in the C<hlobj> class
name.

    use XML::RSS::Feed;
    use XML::RSS::Headline::PerlJobs;
    use LWP::Simple qw(get);

    my $feed = XML::RSS::Feed->new(
	name  => "perljobs",
	url   => "http://jobs.perl.org/rss/standard.rss",
	hlobj => "XML::RSS::Headline::PerlJobs",
    );

    while (1) {
	$feed->parse(get($feed->url));
	print $_->headline . "\n" for $feed->late_breaking_news;
	sleep($feed->delay); 
    }

Here is the output from rssbot on irc.perl.org in channel #news (which uses
these modules)

    <rssbot>  + Part Time Perl
    <rssbot>    Brian Koontz - United States, TX, Dallas
    <rssbot>    Part time, Independent contractor (project-based)
    <rssbot>    http://jobs.perl.org/job/950

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

    perldoc XML::RSS::Headline::PerlJobs

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

L<XML::RSS::Feed>, L<XML::RSS::Headline>, L<XML::RSS::Headline::Fark>, L<XML::RSS::Headline::UsePerlJournals>, L<POE::Component::RSSAggregator>

