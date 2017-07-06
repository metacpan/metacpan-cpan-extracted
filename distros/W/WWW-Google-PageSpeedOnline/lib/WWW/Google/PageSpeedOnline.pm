package WWW::Google::PageSpeedOnline;

$WWW::Google::PageSpeedOnline::VERSION   = '0.24';
$WWW::Google::PageSpeedOnline::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::PageSpeedOnline - Interface to Google Page Speed Online API.

=head1 VERSION

Version 0.24

=cut

use 5.006;
use JSON;
use Data::Dumper;

use WWW::Google::UserAgent;
use WWW::Google::UserAgent::DataTypes -all;
use WWW::Google::PageSpeedOnline::Params qw(validate $FIELDS);
use WWW::Google::PageSpeedOnline::Stats;
use WWW::Google::PageSpeedOnline::Advise;
use WWW::Google::PageSpeedOnline::Result;
use WWW::Google::PageSpeedOnline::Result::Rule;

use Moo;
use namespace::clean;
extends 'WWW::Google::UserAgent';

has prettyprint => (is => 'ro', isa => TrueFalse, default => sub { 'true'    });
has strategy    => (is => 'ro', isa => Strategy,  default => sub { 'desktop' });
has locale      => (is => 'ro', isa => Locale,    default => sub { 'en_US'   });
has [ qw(stats result advise) ] => (is => 'rw');

our $BASE_URL   = 'https://www.googleapis.com/pagespeedonline/v2/runPagespeed';

=head1 DESCRIPTION

Google Page  Speed  is  a tool that helps developers optimize their web pages  by
analyzing the pages and generating tailored suggestions to make the pages faster.
You  can  use  the  Page Speed Online API to programmatically generate Page Speed
scores and suggestions.  Currently it  supports version v2. Courtesy limit is 250
queries per day.

IMPORTANT: The  version v1 of the Google Page Speed Online API is in Labs and its
features might change unexpectedly until it graduates.

The official Google API document can be found L<here|https://developers.google.com/speed/docs/insights/v2/reference/>.

=head1 STRATEGIES

    +-------------+
    | Strategy    |
    +-------------+
    | desktop     |
    | mobile      |
    +-------------+

=head1 RULES

    +---------------------------------------+
    | Rule                                  |
    +---------------------------------------+
    | AvoidCssImport                        |
    | InlineSmallJavaScript                 |
    | SpecifyCharsetEarly                   |
    | SpecifyACacheValidator                |
    | SpecifyImageDimensions                |
    | MakeLandingPageRedirectsCacheable     |
    | MinimizeRequestSize                   |
    | PreferAsyncResources                  |
    | MinifyCss                             |
    | ServeResourcesFromAConsistentUrl      |
    | MinifyHTML                            |
    | OptimizeTheOrderOfStylesAndScripts    |
    | PutCssInTheDocumentHead               |
    | MinimizeRedirects                     |
    | InlineSmallCss                        |
    | MinifyJavaScript                      |
    | DeferParsingJavaScript                |
    | SpecifyAVaryAcceptEncodingHeader      |
    | LeverageBrowserCaching                |
    | OptimizeImages                        |
    | SpriteImages                          |
    | RemoveQueryStringsFromStaticResources |
    | ServeScaledImages                     |
    | AvoidBadRequests                      |
    | UseAnApplicationCache                 |
    +---------------------------------------+

=head1 LOCALES

    +-------+------------------------------+
    | Code  | Description                  |
    +-------+------------------------------+
    | ar    | Arabic                       |
    | bg    | Bulgarian                    |
    | ca    | Catalan                      |
    | zh_TW | Traditional Chinese (Taiwan) |
    | zh_CN | Simplified Chinese           |
    | fr    | Croatian                     |
    | cs    | Czech                        |
    | da    | Danish                       |
    | nl    | Dutch                        |
    | en_US | English                      |
    | en_GB | English UK                   |
    | fil   | Filipino                     |
    | fi    | Finnish                      |
    | fr    | French                       |
    | de    | German                       |
    | el    | Greek                        |
    | lw    | Hebrew                       |
    | hi    | Hindi                        |
    | hu    | Hungarian                    |
    | id    | Indonesian                   |
    | it    | Italian                      |
    | ja    | Japanese                     |
    | ko    | Korean                       |
    | lv    | Latvian                      |
    | lt    | Lithuanian                   |
    | no    | Norwegian                    |
    | pl    | Polish                       |
    | pr_BR | Portuguese (Brazilian)       |
    | pt_PT | Portuguese (Portugal)        |
    | ro    | Romanian                     |
    | ru    | Russian                      |
    | sr    | Serbian                      |
    | sk    | Slovakian                    |
    | sl    | Slovenian                    |
    | es    | Spanish                      |
    | sv    | Swedish                      |
    | th    | Thai                         |
    | tr    | Turkish                      |
    | uk    | Ukrainian                    |
    | vi    | Vietnamese                   |
    +-------+------------------------------+

=head1 CONSTRUCTOR

The constructor expects at the least the API Key that you can get from Google for
FREE. You can also provide prettyprint switch as well, which can have either true
or false values.You can pass param as scalar the API key, if that is the only the
thing you would want to pass in.In case you would want to pass prettyprint switch
then you would have to pass as hashref like:

    +-------------+----------------------+
    | Parameter   | Meaning              |
    +-------------+----------+-----------+
    | api_key     | API Key (required)   |
    +-------------+----------------------+

    use strict; use warnings;
    use WWW::Google::PageSpeedOnline;

    my $api_key = 'Your_API_Key';
    my $page    = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });

=head1 METHODS

=head2 process()

The method process() accepts URL (mandatory) parameter and optionally three other
parameters as well namely locale, strategy and rule.

    +-----------+----------+-----------------------------------------------------------------------------------+
    | Parameter | Required | Meaning                                                                           |
    +-----------+----------+-----------------------------------------------------------------------------------+
    | url       | YES      | The URL of the page for which the Page Speed Online API should generate results.  |
    | locale    | NO       | The locale that results should be generated in. Default is en_US.                 |
    | strategy  | NO       | The strategy to use when analyzing the page. Default is desktop.                  |
    | rule      | NO       | The Page Speed rules to run. Can have multiple rules something like for example,  |
    |           |          | ['AvoidBadRequests', 'MinifyJavaScript'] to request multiple rules.               |
    +-----------+----------+-----------------------------------------------------------------------------------+

    use strict; use warnings;
    use WWW::Google::PageSpeedOnline;

    my $api_key = 'Your_API_Key';
    my $page    = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({ url => 'http://code.google.com/speed/page-speed/' });

=cut

sub process {
    my ($self, $values) = @_;

    my $response    = $self->_process($values);
    $self->{stats}  = $self->_stats($response);
    $self->{result} = $self->_result($response);
    $self->{advise} = $self->_advise($response);
}

sub _process {
    my ($self, $values) = @_;

    my $params   = { url => 1, strategy => 0, locale => 0, rule => 0 };
    my $url      = $self->_url($params, $values);
    my $response = $self->get($url);

    return from_json($response->{content});
}

=head2 stats()

Returns the object L<WWW::Google::PageSpeedOnline::Stats>.

    use strict; use warnings;
    use WWW::Google::PageSpeedOnline;

    my $api_key = 'Your_API_Key';
    my $page    = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({ url => 'http://code.google.com/speed/page-speed/' });
    my $stats   = $page->stats();

    print "Total Request Bytes: ", $stats->totalRequestBytes, "\n";
    print "HTML Response Bytes: ", $sstas->htmlResponseBytes, "\n";

=cut

sub _stats {
    my ($self, $response) = @_;

    return WWW::Google::PageSpeedOnline::Stats->new($response->{pageStats});
}

=head2 result()

Returns the object L<WWW::Google::PageSpeedOnline::Result>.

    use strict; use warnings;
    use WWW::Google::PageSpeedOnline;

    my $api_key = 'Your_API_Key';
    my $page    = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({ url => 'http://code.google.com/speed/page-speed/' });
    my $result  = $page->result();

    print "Id: ", $result->id, "\n";
    print "Titile: ", $result->title, "\n";
    print "Score: ", $result->score, "\n";

=cut

sub _result {
    my ($self, $response) = @_;

    my $rules  = [];
    my $result = $response->{formattedResults}->{ruleResults};
    foreach my $rule (keys %{$result}) {
        push @$rules, WWW::Google::PageSpeedOnline::Result::Rule->new($result->{$rule});
    }

    return WWW::Google::PageSpeedOnline::Result->new(
        id    => $response->{id},
        title => $response->{title},
        score => $response->{score},
        rules => $rules);
}

=head2 advise()

Returns reference to the list of the objects L<WWW::Google::PageSpeedOnline::Advise>.

    use strict; use warnings;
    use WWW::Google::PageSpeedOnline;

    my $api_key = 'Your_API_Key';
    my $page    = WWW::Google::PageSpeedOnline->new({ api_key => $api_key });
    $page->process({ url => 'http://code.google.com/speed/page-speed/' });
    my $advise  = $page->advise();

    foreach (@$advise) {
       print "Id: ", $_->id, ", Header: ", $_->header, "\n";
    }

=cut

sub _advise {
    my ($self, $response) = @_;

    my $advise = [];
    my $result = $response->{formattedResults}->{ruleResults};
    foreach my $rule (keys %{$result}) {
        next unless exists $result->{$rule}->{urlBlocks};

        foreach my $block (@{$result->{$rule}->{urlBlocks}}) {
            my $header = _format($block->{header}->{format}, $block->{header}->{args});
            my $items  = [];
            if (exists($block->{urls}) && (scalar(@{$block->{urls}}))) {
                foreach my $url (@{$block->{urls}}) {
                    push @$items, _format($url->{result}->{format}, $url->{result}->{args});
                }
            }
            push @$advise, WWW::Google::PageSpeedOnline::Advise->new(
                id     => $rule,
                header => $header,
                items  => $items);
        }
    }

    return $advise;
}

#
# PRIVATE METHODS
#

sub _url {
    my ($self, $params, $values) = @_;

    my $url = sprintf("%s?key=%s&prettyprint=%s",
                      $BASE_URL, $self->api_key, $self->prettyprint);

    if (defined $params && defined $values) {
        validate($params, $values);

        foreach my $key (keys %$params) {
            my $_key = "&$key=%" . $FIELDS->{$key}->{type};
            if (defined $values->{$key}) {
                $url .= sprintf($_key, $values->{$key});
            }
            elsif (exists $values->{$key}) {
                $url .= sprintf($_key, $self->{$key});
            }
        }
    }

    return $url;
}

sub _format {
    my ($data, $args) = @_;

    $data =~ s/\s+/ /g;
    my $counter = 1;
    foreach my $arg (@{$args}) {
        $data =~ s/\$$counter/$arg->{value}/e;
        $counter++;
    }

    return $data;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-PageSpeedOnline>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-google-pagespeedonline at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-PageSpeedOnline>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::PageSpeedOnline

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-PageSpeedOnline>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-PageSpeedOnline>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-PageSpeedOnline>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-PageSpeedOnline/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Google::PageSpeedOnline
