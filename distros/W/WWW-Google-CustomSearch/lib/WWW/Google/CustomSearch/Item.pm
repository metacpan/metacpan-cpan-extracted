package WWW::Google::CustomSearch::Item;

$WWW::Google::CustomSearch::Item::VERSION   = '0.38';
$WWW::Google::CustomSearch::Item::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::CustomSearch::Item - Placeholder for Google JSON/Atom Custom Search Item.

=head1 VERSION

Version 0.38

=cut

use 5.006;
use Data::Dumper;

use Moo;
use namespace::autoclean;

has [qw(kind link displayLink snippet htmlSnippet cacheId formattedUrl htmlFormattedUrl title htmlTitle)] => (is => 'ro');

=head1 DESCRIPTION

Provides  the  interface  to the individual search page result items based on the
search criteria.

=head1 METHODS

=head2 kind()

Returns the 'kind' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item Kind: ", $item->kind, "\n" if defined $item->kind;
    }

=head2 link()

Returns the 'link' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item Link: ", $item->link, "\n" if defined $item->link;
    }

=head2 displayLink()

Returns the 'displayLink' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item Display Link: ", $item->displayLink, "\n" if defined $item->displayLink;
    }

=head2 snippet()

Returns the 'snippet' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item Snippet: ", $item->snippet, "\n" if defined $item->snippet;
    }

=head2 htmlSnippet()

Returns the 'htmlSnippet' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item HTML Snippet: ", $item->htmlSnippet, "\n" if defined $item->htmlSnippet;
    }

=head2 cacheId()

Returns the 'cacheId' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item Cache Id: ", $item->cacheId, "\n" if defined $item->cacheId;
    }

=head2 formattedUrl()

Returns the 'formattedUrl' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item Formatted URL: ", $item->formattedUrl, "\n" if defined $item->formattedUrl;
    }

=head2 htmlFormattedUrl()

Returns the 'htmlFormattedUrl' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item HTML Formatted URL: ", $item->htmlFormattedUrl, "\n" if defined $item->htmlFormattedUrl;
    }

=head2 title()

Returns the 'title' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item Title: ", $item->title, "\n" if defined $item->title;
    }

=head2 htmlTitle()

Returns the 'htmlTitle' attribute of the search.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);
    my $result  = $engine->search("Google");
    foreach my $item (@{$result->items}) {
        print "Item HTML Title: ", $item->htmlTitle, "\n" if defined $item->htmlTitle;
    }

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-CustomSearch>

=head1 CONTRIBUTORS

David Kitcher-Jones (m4ddav3)

=head1 BUGS

Please  report  any  bugs or feature requests to C<bug-www-google-customsearch at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-CustomSearch>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::CustomSearch::Item

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
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
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

1; # End of WWW::Google::CustomSearch::Item
