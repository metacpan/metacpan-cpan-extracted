package WWW::BigDoor::NamedLevelCollection;

use strict;
use warnings;

#use Smart::Comments -ENV;

use base qw(WWW::BigDoor::Resource Class::Accessor);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( qw(id read_only currency_id named_levels attributes urls) );

1;
__END__

=head1 NAME

WWW::BigDoor::NamedLevelCollection - NamedLevelCollection Resource Object for BigDoor API

=head1 VERSION

This document describes BigDoor version 0.1.1

=head1 SYNOPSIS

    use WWW::BigDoor;
    use WWW::BigDoor::NamedLevelCollection;
    use WWW::BigDoor::NamedLevel;
    
    my $client = new WWW::BigDoor( $APP_SECRET, $APP_KEY );

    my $named_level_collections = WWW::BigDoor::NamedLevelCollection->all( $client );

    my $currency_obj = new WWW::BigDoor::Currency(
        {
            pub_title            => 'Coins',
            pub_description      => 'an example of the Purchase currency type',
            end_user_title       => 'Coins',
            end_user_description => 'can only be purchased',
            currency_type_id     => '1',                                         
            currency_type_title  => 'Purchase',
            exchange_rate        => 900.00,
            relative_weight      => 2,
        }
    );

    $currency_obj->save( $client );

    my $named_level_collection =
      new WWW::BigDoor::NamedLevelCollection({
            pub_title            => 'Test Named Level Collection',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
            currency_id          => $currency_obj->get_id,
        });

    $named_level_collection->save( $client );

    my @named_levels_payloads = (
        {
            pub_title                 => 'level1',
            pub_description           => 'level1 description',
            end_user_title            => 'novice',
            end_user_description      => "you don't know jack",
            named_level_collection_id => $named_level_collection->get_id,
        },
        {
            pub_title                 => 'level2',
            pub_description           => 'level2 description',
            end_user_title            => 'Neophyte',
            end_user_description      => "you kinda know something",
            named_level_collection_id => $named_level_collection->get_id,
        },
        {
            pub_title                 => 'level3',
            pub_description           => 'level3 description',
            end_user_title            => 'Expert',
            end_user_description      => "you rock",
            named_level_collection_id => $named_level_collection->get_id,
        },
    );

    foreach my $nlp ( @named_levels_payloads ) {
        my $nl = new WWW::BigDoor::NamedLevel( $nlp );
        $nl->save( $client );
    } 

    $named_level_collection->remove( $client );
  
=head1 DESCRIPTION

This module provides object corresponding to BigDoor API /named_level_collection end point.
For description see online documentation L<http://publisher.bigdoor.com/docs/>

=head1 INTERFACE 

All methods except accessor/mutators are provided by base
WWW::BigDoor::Resource object

=head1 DIAGNOSTICS

No error messages produced by module itself.

=head1 CONFIGURATION AND ENVIRONMENT

WWW:BigDoor::NamedLevelCollection requires no configuration files or environment variables.

=head1 DEPENDENCIES

WWW::BigDoor::Resource, WWW::BigDoor

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bigdoor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

WWW::BigDoor::Resource for base class description, WWW::BigDoor for procedural
interface for BigDoor REST API

=head1 AUTHOR

Alex L. Demidov  C<< <alexeydemidov@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

BigDoor Open License
Copyright (c) 2010 BigDoor Media, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to
do so, subject to the following conditions:

- This copyright notice and all listed conditions and disclaimers shall
be included in all copies and portions of the Software including any
redistributions in binary form.

- The Software connects with the BigDoor API (api.bigdoor.com) and
all uses, copies, modifications, derivative works, mergers, publications,
distributions, sublicenses and sales shall also connect to the BigDoor API and
shall not be used to connect with any API, software or service that competes
with BigDoor's API, software and services.

- Except as contained in this notice, this license does not grant you rights to
use BigDoor Media, Inc. or any contributors' name, logo, or trademarks.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
