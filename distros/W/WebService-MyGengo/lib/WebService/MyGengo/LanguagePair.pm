package WebService::MyGengo::LanguagePair;

use Moose;
use namespace::autoclean;

BEGIN { extends 'WebService::MyGengo::Base' };

=head1 NAME

WebService::MyGengo::LanguagePair - An object representing a Src -> Dst translation language pair in the myGengo system

=head1 SYNOPSIS

    my $pairs = $client->get_service_language_pairs( 'en' );
    printf("Hey, I can translate from %s to %s\n", $_->lc_src, $_->lc_tgt)
        foreach @$pairs;

=head1 ATTRIBUTES

=head2 lc_src (Str)

The 2-character ISO code for the source language.

=cut
has 'lc_src' => (
    is => 'ro'
    , isa => 'WebService::MyGengo::LanguageCode'
    , required => 1
    );

=head2 lc_tgt (Str)

The 2-character ISO code for the target language.

=cut
has 'lc_tgt' => (
    is => 'ro'
    , isa => 'WebService::MyGengo::LanguageCode'
    , required => 1
    );

=head2 tier (Str)

The tier of service for this translation.

Legal values are: machine, standard, pro, ultra, ultra_pro

=cut
has 'tier' => (
    is => 'ro'
    , isa => 'WebService::MyGengo::Tier'
    , required => 1
    );

=head2 unit_price (Num)

A decimal figure representing the per-unit translation price, in USD.

=cut
has 'unit_price' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::Num'
    , required  => 1
    );


__PACKAGE__->meta->make_immutable();
1;

#=head2 TODO
#
# * Provide accessors to retrieve L<WebService::MyGengo::Language> objects for each of the languages
#
=head2 SEE ALSO

L<http://mygengo.com/api/developer-docs/methods/translate-service-language-pairs-get/>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
