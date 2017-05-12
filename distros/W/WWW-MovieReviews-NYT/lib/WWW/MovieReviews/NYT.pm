package WWW::MovieReviews::NYT;

$WWW::MovieReviews::NYT::VERSION = '0.05';

=head1 NAME

WWW::MovieReviews::NYT - Interface to NewYorkTimes Movie Reviews API.

=head1 VERSION

Version 0.05

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;

my $API_VERSION = 'v2';
my $API_URL     = {
    1 => "http://api.nytimes.com/svc/movies/${API_VERSION}/reviews/search.xml",
    2 => "http://api.nytimes.com/svc/movies/${API_VERSION}/reviews/",
    3 => "http://api.nytimes.com/svc/movies/${API_VERSION}/reviews/reviewer/",
    4 => "http://api.nytimes.com/svc/movies/${API_VERSION}/critics/",
};

=head1 DESCRIPTION

With the Movie Reviews API,you can search New York Times movie reviews by keyword
and  get  lists  of  NYT Critics' Picks.Usage is limited to 5000 requests per day
(rate limits are subject to change). Currently supports version v2.  As of now it
only gets result in XML format.

The Movie Reviews service uses a RESTful style. Four request types are available:

    +-----+----------------------------------------------+
    | No. | Type                                         |
    +-----+----------------------------------------------+
    |  1  | Search reviews by keyword.                   |
    |  2  | Get lists of reviews and NYT Critics' Picks. |
    |  3  | Get reviews by reviewer.                     |
    |  4  | Get information about reviewers.             |
    +-----+----------------------------------------------+

=head1 CONSTRUCTOR

The constructor  expects your application API, which you can get it for FREE from
The New York Times Developer site. You need to create an account first with them.
You only need to pick any username of your choice and password to get it started.
Once you have the account setup you can then request for API Key and accept their
Terms and Condition for usage. Here is the link for L<registration|https://myaccount.nytimes.com/register>.

    use strict; use warnings;
    use WWW::MovieReviews::NYT;

    my $api_key = 'Your_API_Key';
    my $movie   = WWW::MovieReviews::NYT->new($api_key);

=cut

sub new {
    my ($class, $key) = @_;

    die("ERROR: API Key is missing.\n") unless defined $key;
    my $self = { key     => $key,
                 browser => LWP::UserAgent->new()
               };
    bless $self, $class;
    return $self;
}

=head1 METHODS

=head2 by_keyword()

Search the reviews by given keyword. Possible parameters listed below:

    +------------------+-----------------------------------------+------------------------+
    | Name             | Description                             | Example                |
    +------------------+-----------------------------------------+------------------------+
    | query            | Search keyword; matches movie title.    | 'wild+west'            |
    | critics-pick     | Limits by NYT Critics Picks status.     | Y | N                  |
    | thausand-best    | Limits by Best 1,000 Movies status.     | Y | N                  |
    | dvd              | Limits by format.                       | Y | N                  |
    | reviewer         | Limits by a specific NYT critic.        | monohla.dargis         |
    | publication-date | Limits by date or range of dates.       | YYYY-MM-DD;YYYY-MM-DD  |
    | opening-date     | Limits by date or range of dates.       | YYYY-MM-DD;YYYY-MM-DD  |
    | offset           | Sets the starting point of the results. | Multiple of 20.        |
    | order            | Sets the sort order of the results.     | by-title               |
    |                  |                                         | or by-publication-date |
    |                  |                                         | or by-opening-date     |
    |                  |                                         | or by-dvd-release-date |
    +------------------+-----------------------------------------+------------------------+

You  can specify  up to  three  search parameters (order, limit and offset do not
count toward this maximum, but query does).

    use strict; use warnings;
    use WWW::MovieReviews::NYT;

    my $api_key = 'Your_API_Key';
    my $movie   = WWW::MovieReviews::NYT->new($api_key);
    print $movie->by_keyword({'query' => 'wild+west'});

=cut

# http://api.nytimes.com/svc/movies/v2/reviews/search.xml?query=big&thousand-best=Y&opening-date=1930-01-01;2000-01-01
sub by_keyword {
    my ($self, $param) = @_;

    _validate_by_keyword_param($param);

    my ($url, $request, $response);
    $url      = sprintf("%s?api-key=%s", $API_URL->{1}, $self->{key});
    $url     .= sprintf("&query=%s", $param->{'query'}) if exists($param->{'query'});
    $url     .= sprintf("&critics-pick=%s", $param->{'critics-pick'}) if exists($param->{'critics-pick'});
    $url     .= sprintf("&thausand-best=%s", $param->{'thausand-best'}) if exists($param->{'thausand-best'});
    $url     .= sprintf("&dvd=%s", $param->{'dvd'}) if exists($param->{'dvd'});
    $url     .= sprintf("&reviewer=%s", $param->{'reviewer'}) if exists($param->{'reviewer'});
    $url     .= sprintf("&publication-date=%s", $param->{'publication-date'}) if exists($param->{'publication-date'});
    $url     .= sprintf("&opening-date=%s", $param->{'opening-date'}) if exists($param->{'opening-date'});
    $url     .= sprintf("&offset=%d", $param->{'offset'}) if exists($param->{'offset'});
    $url     .= sprintf("&order=%s", $param->{'order'}) if exists($param->{'order'});
    $request  = HTTP::Request->new(GET=>$url);
    $response = $self->{browser}->request($request);

    die("ERROR: Couldn't connect to [$url].\n") unless $response->is_success;

    return $response->content;
}

=head2 by_reviews_critics()

Search by reviews and NYT critics. Possible parameters listed below:

    +---------------+-----------------------------------------+-------------------------+
    | Name          | Description                             | Example                 |
    +---------------+-----------------------------------------+-------------------------+
    | resource-type | All reviews or NYT Critics Picks.       | all | picks | dvd-picks |
    | offset        | Sets the starting point of the results. | Multiple of 20.         |
    | order         | Sets the sort order of the results.     | by-title                |
    |               |                                         | or by-publication-date  |
    |               |                                         | or by-opening-date      |
    |               |                                         | or by-dvd-release-date  |
    +---------------+-----------------------------------------+-------------------------+

    use strict; use warnings;
    use WWW::MovieReviews::NYT;

    my $api_key = 'Your_API_Key';
    my $movie   = WWW::MovieReviews::NYT->new($api_key);
    print $movie->by_reviews_critics({'resource-type' => 'all', 'order' => 'by-title'});

=cut

# http://api.nytimes.com/svc/movies/v2/reviews/dvd-picks.xml?order=by-date&offset=40
sub by_reviews_critics {
    my ($self, $param) = @_;

    _validate_by_reviews_critics_param($param);

    my ($url, $request, $response);
    $url      = sprintf("%s%s.xml?api-key=%s", $API_URL->{2}, $param->{'resource-type'}, $self->{key});
    $url     .= sprintf("&offset=%d", $param->{'offset'}) if exists($param->{'offset'});
    $url     .= sprintf("&order=%s", $param->{'order'}) if exists($param->{'order'});
    $request  = HTTP::Request->new(GET=>$url);
    $response = $self->{browser}->request($request);

    die("ERROR: Couldn't connect to [$url].\n") unless $response->is_success;

    return $response->content;
}

=head2 by_reviewer()

Search by reviewer. Possible parameters listed below:

    +---------------+-----------------------------------------+------------------------+
    | Name          | Description                             | Example                |
    +---------------+-----------------------------------------+------------------------+
    | reviewer-name | The name of the Times reviewer.         | manohla-dargis         |
    | critics-pick  | Limits by NYT Critics Picks status.     | Y | N                  |
    | offset        | Sets the starting point of the results. | Multiple of 20.        |
    | order         | Sets the sort order of the results.     | by-title               |
    |               |                                         | or by-publication-date |
    |               |                                         | or by-opening-date     |
    |               |                                         | or by-dvd-release-date |
    +---------------+-----------------------------------------+------------------------+

    use strict; use warnings;
    use WWW::MovieReviews::NYT;

    my $api_key = 'Your_API_Key';
    my $movie   = WWW::MovieReviews::NYT->new($api_key);
    print $movie->by_reviewer({'reviewer-name' => 'manohla-dargis',
                               'critics-pick'  => 'Y',
                               'order'         => 'by-title'});

=cut

# http://api.nytimes.com/svc/movies/v2/reviews/reviewer/manohla-dargis/all.xml?order=by-title
sub by_reviewer {
    my ($self, $param) = @_;

    _validate_by_reviewer_param($param);

    my ($url, $request, $response);
    $url      = sprintf("%s%s/all.xml?api-key=%s", $API_URL->{3}, $param->{'reviewer-name'}, $self->{key});
    $url     .= sprintf("&critics-pick=%s", $param->{'critics-pick'}) if exists($param->{'critics-pick'});
    $url     .= sprintf("&offset=%d", $param->{'offset'}) if exists($param->{'offset'});
    $url     .= sprintf("&order=%s", $param->{'order'}) if exists($param->{'order'});
    $request  = HTTP::Request->new(GET=>$url);
    $response = $self->{browser}->request($request);

    die("ERROR: Couldn't connect to [$url].\n") unless $response->is_success;

    return $response->content;
}

=head2 get_reviewer_details()

Get reviewer details. Possible parameters listed below:

    +---------------+--------------------------------------------+-----------------------------+
    | Name          | Description                                | Example                     |
    +---------------+--------------------------------------------+-----------------------------+
    | resource-type | A set of reviewers or a specific reviewer. | all | full-time | part-time |
    |               |                                            | reviewer | [reviewer-name]  |
    +---------------+--------------------------------------------+-----------------------------+

    use strict; use warnings;
    use WWW::MovieReviews::NYT;

    my $api_key = 'Your_API_Key';
    my $movie   = WWW::MovieReviews::NYT->new($api_key);
    print $movie->get_reviewer_details('all');

=cut

# http://api.nytimes.com/svc/movies/v2/critics/a-o-scott.xml
sub get_reviewer_details {
    my ($self, $type) = @_;

    _validate_resource_type($type);

    my ($url, $request, $response);
    $url      = sprintf("%s%s.xml?api-key=%s", $API_URL->{4}, $type, $self->{key});
    $request  = HTTP::Request->new(GET=>$url);
    $response = $self->{browser}->request($request);

    die("ERROR: Couldn't connect to [$url].\n") unless $response->is_success;

    return $response->content;
}

sub _validate_by_keyword_param {
    my ($param) = @_;

    die("ERROR: Missing input parameters.\n") unless defined $param;
    die("ERROR: Input param has to be a ref to HASH.\n") if (ref($param) ne 'HASH');
    die("ERROR: Missing key query.\n") unless exists($param->{'query'});
    die("ERROR: Invalid value for key reviewer [". $param->{'reviewer'} . "].\n")
        if (defined($param->{'reviewer'}) && ($param->{'reviewer'} !~ /\b[a-z\.\-]+\b/i));

    _validate_y_n('critics-pick', $param->{'critics-pick'});
    _validate_y_n('thausand-best', $param->{'thausand-best'});
    _validate_y_n('dvd', $param->{'dvd'});
    _validate_date('publication-date', $param->{'publication-date'});
    _validate_date('opening-date', $param->{'opening-date'});
    _validate_key_offset($param->{'offset'});
    _validate_key_order($param->{'order'});
}

sub _validate_by_reviews_critics_param {
    my ($param) = @_;

    die("ERROR: Missing input parameters.\n") unless defined $param;
    die("ERROR: Input param has to be a ref to HASH.\n") if (ref($param) ne 'HASH');
    die("ERROR: Missing key resource-type.\n") unless exists($param->{'resource-type'});
    die("ERROR: Invalid value for key resource-type [". $param->{'resource-type'} . "].\n")
        unless ($param->{'resource-type'} =~ /\ball\b|\bpicks\b|\bdvd\-picks\b/i);

    _validate_key_offset($param->{'offset'});
    _validate_key_order($param->{'order'});
}

sub _validate_by_reviewer_param {
    my ($param) = @_;

    die("ERROR: Missing input parameters.\n") unless defined $param;
    die("ERROR: Input param has to be a ref to HASH.\n") if (ref($param) ne 'HASH');
    die("ERROR: Missing key reviewer-name.\n") unless exists($param->{'reviewer-name'});
    die("ERROR: Invalid value for key reviewer-name [". $param->{'reviewer-name'} . "].\n")
        unless ($param->{'reviewer-name'} =~ /\b[a-z\.\-]+\b/i);

    _validate_y_n('critics-pick', $param->{'critics-pick'});
    _validate_key_offset($param->{'offset'});
    _validate_key_order($param->{'order'});
}

sub _validate_date {
    my ($key, $value) = @_;

    return unless defined $value;

    my @values;
    ($value =~ /\;/)
    ?
    (@values = split /\;/,$value)
    :
    (@values = ($value));

    foreach (@values) {
        die("ERROR: Invalid value for key $key [$value].\n")
            if (defined($_) && ($_ !~ /^\d{4}\-\d{2}\-\d{2}$/));
    }
}

sub _validate_y_n {
    my ($key, $value) = @_;

    return unless defined $value;

    die("ERROR: Invalid value for key $key [$value].\n") if (defined($value) && ($value !~ /^[y|n]$/i));
}

sub _validate_key_offset {
    my ($offset) = @_;

    return unless defined $offset;

    die("ERROR: Invalid value for key offset [$offset].\n")
        unless (defined($offset)
                &&
                ($offset =~ /^\d{1,}$/)
                &&
                (($offset == 0) || ($offset%20 == 0)));
}

sub _validate_key_order {
    my ($order) = @_;

    die("ERROR: Invalid value for key order [$order].\n")
        if (defined($order)
            &&
            ($order !~ /\bby\-title\b|\bby\-publication\-date\b|\bby\-opening\-date\b|\bby\-dvd\-release\-date\b/i));
}

sub _validate_resource_type {
    my ($type) = @_;

    die("ERROR: Missing key resource-type.\n") unless defined $type;
    die("ERROR: Invalid value for key resource-type [$type].\n")
        unless ($type =~ /\ball\b|\bfull\-time\b|\bpart\-time\b|\breviewer\b|[a..z\.\-]+/i);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/WWW-MovieReviews-NTY>

=head1 BUGS

Please  report  any bugs or feature requests to C<bug-www-moviereviews-nyt at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-MovieReviews-NYT>.
I will be notified and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::MovieReviews::NYT

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-MovieReviews-NYT>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-MovieReviews-NYT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-MovieReviews-NYT>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-MovieReviews-NYT/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mohammad S Anwar.

This  program  is  free  software; you can redistribute it and/or modify it under the terms of
either:  the  GNU  General Public License as published by the Free Software Foundation; or the
Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This  program  is  distributed  in  the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1; # End of WWW::MovieReviews::NYT
