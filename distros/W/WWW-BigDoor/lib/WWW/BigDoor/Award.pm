package WWW::BigDoor::Award;

use strict;
use warnings;

#use Smart::Comments -ENV;

use base qw(WWW::BigDoor::Resource Class::Accessor);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( qw(id end_user_login named_award_id read_only) );

sub _parent_end_point { ## no critic (ProhibitUnusedPrivateSubroutines)
    return 'end_user';
}

sub _parent_id_attr { ## no critic (ProhibitUnusedPrivateSubroutines)
    return 'end_user_login';
}

1;
__END__

=head1 NAME

WWW::BigDoor::Award - Award Resource Object for BigDoor API

=head1 VERSION

This document describes BigDoor version 0.1.1

=head1 SYNOPSIS

    use WWW::BigDoor;
    use WWW::BigDoor::Award;

    my $client = new WWW::BigDoor( $APP_SECRET, $APP_KEY );

    my $named_award_collections = WWW::BigDoor::NamedAwardCollection->all( $client );

    my $named_award_collection =
      new WWW::BigDoor::NamedAwardCollection( {
                pub_title            => 'application achievements',
                pub_description      => 'a set of achievements that the user can earn',
                end_user_title       => 'achievements',
                end_user_description => 'things you can get',
            };
      );
    
    $named_award_collection->save( $client );

    my $named_award = new WWW::BigDoor::NamedAward({
        pub_title                 => 'obligatory early achievement ',
        pub_description           => 'the sort of achievement you get when you can turn on an xbox',
        end_user_title            => 'just breath',
        end_user_description      => 'congratulations you rock so hard; keep on breathing',
        relative_weight           => 1,
        named_award_collection_id => $named_award_collection->get_id,
    });

    $named_award->save( $client );
    
    my $award = WWW::BigDoor::Award->new(
        {
            end_user_login => $username,
            named_award_id => $named_award_collection->get_named_awards->[0]->{'id'},
        }
    );
    $award->save( $client );

    $award->remove( $client );

    $named_award->remove( $client );

    $named_award_collection->remove( $client );

  
=head1 DESCRIPTION

This module provides object corresponding to BigDoor API /end_user/{id}/award end point.
For description see online documentation L<http://publisher.bigdoor.com/docs/>

=head1 INTERFACE 

All methods except accessor/mutators are provided by base
WWW::BigDoor::Resource object

=head1 DIAGNOSTICS

No error messages produced by module itself.

=head1 CONFIGURATION AND ENVIRONMENT

WWW:BigDoor::Award requires no configuration files or environment variables.

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
