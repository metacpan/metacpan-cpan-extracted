package WWW::Google::CustomSearch::Result;

$WWW::Google::CustomSearch::Result::VERSION   = '0.39';
$WWW::Google::CustomSearch::Result::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::CustomSearch::Result - Placeholder for Google JSON/Atom Custom Search Result.

=head1 VERSION

Version 0.39

=cut

use 5.006;
use Data::Dumper;
use WWW::Google::CustomSearch::Item;
use WWW::Google::CustomSearch::Page;
use WWW::Google::CustomSearch::Request;

use Moo;
use namespace::autoclean;

has [qw(api_key raw)] => (is => 'ro', required => 1);
has [qw(kind formattedTotalResults formattedSearchTime totalResults searchTime url_template url_type request nextPage previousPage items)] => (is => 'ro');

sub BUILD {
    my ($self) = @_;

    my $raw  = $self->raw;
    $self->{'kind'} = $raw->{'kind'};
    $self->{'formattedTotalResults'} = $raw->{'searchInformation'}->{'formattedTotalResults'};
    $self->{'formattedSearchTime'} = $raw->{'searchInformation'}->{'formattedSearchTime'};
    $self->{'totalResults'} = $raw->{'searchInformation'}->{'totalResults'};
    $self->{'searchTime'} = $raw->{'searchInformation'}->{'searchTime'};

    $self->{'url_template'} = $raw->{'url'}->{'template'};
    $self->{'url_type'} = $raw->{'url'}->{'type'};

    $raw->{'queries'}->{'request'}->[0]->{'api_key'} = $self->api_key;
    $self->{'request'} = WWW::Google::CustomSearch::Request->new($raw->{'queries'}->{'request'}->[0]);

    if (defined $raw->{'queries'}->{'nextPage'} && (scalar(@{$raw->{'queries'}->{'nextPage'}}))) {
        $raw->{'queries'}->{'nextPage'}->[0]->{'api_key'} = $self->api_key;
        $self->{'nextPage'} = WWW::Google::CustomSearch::Page->new($raw->{'queries'}->{'nextPage'}->[0]);
    }

    if (defined $raw->{'queries'}->{'previousPage'} && (scalar(@{$raw->{'queries'}->{'previousPage'}}))) {
        $raw->{'queries'}->{'previousPage'}->[0]->{'api_key'} = $self->api_key;
        $self->{'previousPage'} = WWW::Google::CustomSearch::Page->new($raw->{'queries'}->{'previousPage'}->[0]);
    }

    foreach (@{$raw->{items}}) {
        push @{$self->{items}}, WWW::Google::CustomSearch::Item->new($_);
    }
}

=head1 DESCRIPTION

Provides the interface to the individual search results based on the search criteria.

=head1 METHODS

=head2 kind()

Returns the 'kind' attribute of the search result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    print "Kind: ", $result->kind, "\n";

=head2 formattedTotalResults()

Returns the 'formattedTotalResults' attribute of the search result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    print "Formatted Total Results: ", $result->formattedTotalResults, "\n";

=head2 formattedSearchTime()

Returns the 'formattedSearchTime' attribute of the search result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    print "Formatted Search Time: ", $result->formattedSearchTime, "\n";

=head2 totalResults()

Returns the 'totalResults' attribute of the search result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    print "Total Results: ", $result->totalResults, "\n";

=head2 searchTime()

Returns the 'searchTime' attribute of the search result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    print "Search Time: ", $result->searchTime, "\n";

=head2 url_template()

Returns the URL template attribute of the search result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    print "URL Template: ", $result->url_template, "\n";

=head2 url_type()

Returns the URL Type attribute of the search result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    print "URL Type: ", $result->url_type, "\n";

=head2 request()

Returns the request L<WWW::Google::CustomSearch::Request> object used in the last
search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    my $request = $result->request;

=head2 nextPage()

Returns the next page L<WWW::Google::CustomSearch::Page> object which can be used
to fetch the next page result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    my $page    = $result->nextPage;

=head2 previousPage()

Returns the previous page L<WWW::Google::CustomSearch::Page> object which can  be
used to fetch the previous page result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx, start => 2);
    my $result  = $engine->search("Google");
    my $page    = $result->previousPage;

=head2 items()

Returns list of search item L<WWW::Google::CustomSearch::Item> based on the search
criteria.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    my $items   = $result->items;

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-CustomSearch>

=head1 CONTRIBUTORS

David Kitcher-Jones (m4ddav3)

=head1 BUGS

Please report  any  bugs  or feature requests to C<bug-www-google-customsearch at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-CustomSearch>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::CustomSearch::Result

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-CustomSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-CustomSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-CustomSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-CustomSearch/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
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

1; # End of WWW::Google::CustomSearch::Result
