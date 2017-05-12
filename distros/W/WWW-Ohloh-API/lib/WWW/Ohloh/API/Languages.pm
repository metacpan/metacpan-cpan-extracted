package WWW::Ohloh::API::Languages;

use strict;
use warnings;

use Object::InsideOut qw/ WWW::Ohloh::API::Collection /;

use Carp;
use XML::LibXML;
use Readonly;
use List::MoreUtils qw/ any /;
use WWW::Ohloh::API::Language;

our $VERSION = '0.3.2';

my @ALLOWED_SORTING;
Readonly @ALLOWED_SORTING =>
  qw/ total code projects comment_ratio contributors commits name /;

sub element      { return 'WWW::Ohloh::API::Language' }
sub element_name { return 'language' }
sub query_path   { return 'languages.xml' }

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_allowed_sort {
    my $s = shift;
    return any { $s eq $_ } @ALLOWED_SORTING;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

'end of WWW::Ohloh::API::Languages';
__END__

=head1 NAME

WWW::Ohloh::API::Languages - a set of Ohloh languages

=head1 SYNOPSIS

    use WWW::Ohloh::API;
    use WWW::Ohloh::API::Languages;

    my $ohloh = WWW::Ohloh::API( api_key => $key );

    my $languages = $ohloh->get_languages( sort => 'code' );

    while ( my $l = $languages->next ) {
        print $l->nice_name;
    }

=head1 DESCRIPTION

W::O::A::Languages returns a list of languages known to Ohloh.

The object doesn't retrieve all languages from the Ohloh
server in one go, but rather fetch them in small groups as
required.  If you want to download all languages at the
same time, you can use the B<all()> method:

    my @langs = $ohloh->get_languages( sort => 'code' )->all;

=head1 METHODS 

=head2 new( %args )

Creates a new W::O::A::Languages object.  It accepts the following 
arguments:

=head3 Arguments

=over

=item  ohloh => I<$ohloh>

Mandatory.  Its value is the L<WWW::Ohloh::API> object that will be used
to query the Ohloh server.

=item max => I<$nbr_languages>

The maximum number of languages the set will contain.  If you want to 
slurp'em all, set it to 'undef' (which is the default).

=back

=head2 all

Returns the retrieved languages' information as
L<WWW::Ohloh::API::Language> objects.

=head2 next( I<$n> )

Returns the next I<$n> language (or all remaining languages if there are
less than I<$n>), or C<undef> if there is no more languages
to retrieve.  After it returned C<undef>, subsequent calls to B<next> will reset
the list.  If I<$n> is not given, defaults to 1 entry.

=head2 max

Returns the maximum number of languages the object will return, or C<undef>
if no maximum has been set.

=head2 total_entries

Returns the number of entries selected by the query. 

B<Beware>: this number can change during the life of the object!  Each
time the object retrieves a new batch of entries, this number is updated
with the value returned by the Ohloh server, which could differ from its
last invication is 
entries have been added or removed since the last retrieval.

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::Language>. 


=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/language

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
