package WebService::MyGengo::Language;

use Moose;
use namespace::autoclean;

BEGIN { extends 'WebService::MyGengo::Base' };

=head1 NAME

WebService::MyGengo::Language - An object representing a translatable language in the myGengo system

=head1 SYNOPSIS

    my @langs = $client->get_service_languages();
    printf("I can translate %s, also known as %s or language code %s,
            by units of %s\n"
            , $_->language, $_->localized_name, $_->lc, $_->unit_type)
        foreach @$langs;

=head1 ATTRIBUTES

=head2 language (Str)

The English representation of the Langauge name in UTF-8 encoding.

=head2 localized_name (Str)

The localized representation of the Langauge name in UTF-8 encoding.

=cut
has [qw/language localized_name/] => (
    is          => 'ro'
    , isa       => 'Str'
    , required  => 1
    );

=head2 unit_type (Str)

The translation unit used for this language.

Valid values are: word, character

=cut
has 'unit_type' => (
    is => 'ro'
    , isa => 'WebService::MyGengo::UnitType'
    , required => 1
    );

=head2 lc (Str)

The 2-character ISO language code.

=cut
has 'lc' => (
    is => 'ro'
    , isa => 'WebService::MyGengo::LanguageCode'
    , required => 1
    );


__PACKAGE__->meta->make_immutable();
1;

=head2 SEE ALSO

L<http://mygengo.com/api/developer-docs/methods/translate-service-languages-get/>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
