package WWW::BigDoor::URL;

use strict;
use warnings;

use Carp;
#use Smart::Comments -ENV;

use base qw(WWW::BigDoor::Resource Class::Accessor);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( qw(id read_only url attributes is_for_end_user_ui is_media_url) );

# FIXME DRY with Attribute
sub associate_with {
    my ( $self, $resource, $client ) = @_;

    unless ( defined $self->get_id ) {
        croak 'URL should have ID - save before associating';
    }
    unless ( defined $resource->get_id ) {
        croak 'Object should have ID - save before associating';
    }
    my $ep = $self->_end_point;

    my $result = $client->POST(
        sprintf( '%s/%s/%s/%s',
            $ep, $self->get_id, $resource->get_resource_name,
            $resource->get_id ),
        {format => 'json'}
    );
    return $result;
}

1;
__END__

=head1 NAME

WWW::BigDoor::URL - URL Resource Object for BigDoor API

=head1 VERSION

This document describes BigDoor version 0.1.1

=head1 SYNOPSIS

    use WWW::BigDoor;
    use WWW::BigDoor::URL;
    use WWW::BigDoor::Currency;
    
    my $client = new WWW::BigDoor( $APP_SECRET, $APP_KEY );

    my $urls = WWW::BigDoor::URL->all( $client );

    my $url_payload = {
        pub_title            => 'Test URL',
        pub_description      => 'test description',
        end_user_title       => 'end user title',
        end_user_description => 'end user description',
        url                  => 'http://example.com/',
    };
    my $url_obj = new WWW::BigDoor::URL( $url_payload );

    $url_obj->save( $client );

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

    $url_obj->associate_with( $currency_obj, $client );

    $currency_obj->remove( $client );

    $url_obj->remove( $client );

    $urls = WWW::BigDoor::URL->all( $client );
  
=head1 DESCRIPTION

This module provides object corresponding to BigDoor API /attribute end point.
For description see online documentation L<http://publisher.bigdoor.com/docs/>

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

Most of methods are provided by base WWW::BigDoor::Resource object.

=head3  associate_with( $resource, $client )

=over 4

=item resource

WWW::BigDoor::Resource object

=item client

WWW::BigDoor object.

=back

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

WWW::BigDoor::URL requires no configuration files or environment variables.

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
