package WebService::MyGengo::Feedback;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

BEGIN { extends 'WebService::MyGengo::Base' };

=head1 NAME

WebService::MyGengo::Feedback - A Feedback entry in the myGengo system.

=head1 SYNOPSIS

    # Submit feedback
    $client->approve_job( $job, 5, "Good Job", "Nice xlation", 1 );

    # Elsewhere...
    my $fb = $client->get_job_feedback( $job->id );
    is( $fb->rating, "5.0" );
    is( $fb->for_translator, "Good Job" );

=head1 ATTRIBUTES

=head2 rating (Num)

A decimal figure representing the rating for the translation between 0.0 and
5.0.

=cut
has 'rating' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::Num'
    , required  => 1
    );

=head2 for_translator (Str)

The comment that was left for the translator in UTF-8 encoding.

Sometimes the API returns 'null' (undef) for this value. In this case
the value will be coerced into an empty string.

=cut
subtype 'WebService::MyGengo::Feedback::for_translator'
    , as 'Str';
coerce 'WebService::MyGengo::Feedback::for_translator'
    , from 'Undef', via { '' } ;
has 'for_translator' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::Feedback::for_translator'
    , coerce    => 1
    , required  => 0
    );

=head1 METHODS
=cut

#=head2 around BUILDARGS
#
#Allow single-argument constructor for `rating`
#
#=cut
around BUILDARGS => sub {
    my ( $orig, $class, $val ) = ( @_ );
    ref($val) eq 'HASH' and return $val;
    return { rating => $val };
};


__PACKAGE__->meta->make_immutable();

1;

=head2 SEE ALSO

L<WebService::MyGengo::Client>

L<http://mygengo.com/api/developer-docs/methods/translate-job-id-feedback-get/>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
