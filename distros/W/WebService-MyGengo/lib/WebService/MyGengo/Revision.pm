package WebService::MyGengo::Revision;

use Moose;

BEGIN { extends 'WebService::MyGengo::Base' };

# Stringify to the comment body
use overload ( '""' => sub { shift->body_tgt } );

=head1 NAME

WebService::MyGengo::Revision - A Revision in the myGengo system.

=head1 SYNOPSIS

    # Note: Revisions can't actually be submitted via API,
    #   so creating one by hand is only useful for testing
    my $rev = WebService::MyGengo::Revision->new( { body_tgt => 'Hello.' } );
    # or
    $rev = WebService::MyGengo::Revision->new( 'Hello.' );

    # Elsewhere...
    my @revs = $client->get_job_revisions( $job->id );

    # $body_tgt eq 'Hello.'
    my $body_tgt = "$revs[0]"; # Overloads stringification to ->body_tgt

=head1 ATTRIBUTES

=head2 rev_id|id (Int)

A unique identifier for this Revision.

=cut
sub id { shift->rev_id }
has 'rev_id' => (
    is          => 'ro'
    , isa       => 'Int'
    , required  => 1
    );

=head2 body_tgt (Src)

The translation results.

Sometimes the API returns 'null' (undef) for this value. In this case
the value will be coerced into an empty string.

=cut
has 'body_tgt' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::body_tgt'
    , coerce    => 1
    , required  => 1
    );

=head2 ctime (DateTime)

The L<DateTime> at which this Revision was created.

This value is set by the API.

=cut
has 'ctime' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::DateTime'
    , coerce    => 1
    );

=head1 METHODS
=cut

#=head2 around BUILDARGS
#
#Allow single-argument constructor for `body_tgt`
#
#=cut
around BUILDARGS => sub {
    my ( $orig, $class, $val ) = ( @_ );
    ref($val) eq 'HASH' and return $val;
    return { body_tgt => $val };
};


no Moose;
__PACKAGE__->meta->make_immutable();

1;

=head2 SEE ALSO

L<http://mygengo.com/api/developer-docs/methods/translate-job-id-revision-rev-id-get/>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
