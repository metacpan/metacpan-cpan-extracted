package WebService::MyGengo::Job;

use Moose;
use namespace::autoclean;

BEGIN { extends 'WebService::MyGengo::Base' };

use Scalar::Util qw(blessed);
use DateTime::Format::Strptime;

=head1 NAME

WebService::MyGengo::Job - A translation Job in the myGengo system.

=head1 SYNOPSIS

    my $job = WebService::MyGengo::Job->new( { lc_src => 'en', lc_tgt => 'ja'... } );

    my $client = WebService::MyGengo::Client->new( $params );
    $job = $client->get_job( 123 );

=head1 ATTRIBUTES

See L<http://mygengo.com/api/developer-docs/payloads/> for more information,
as well as the various tests in t/*.t.

=head2 job_id|id (Int)

A unique identifier for the Job.

=head2 group_id (Int)

A unique identifier for a group of Jobs.

See L<WebService::MyGengo::Client>'s `submit_jobs` method.

=head2 slug (Str)

Undocumented. Appears to act as a 'title' for the Job.

=head2 body_src (Str)

The text to be translated in UTF-8 encoding.

=head2 body_tgt (Str)

The translation result text in UTF-8 encoding.

If the Job has not been completed, this will be en empty string.

=head2 lc_src (Str)

2-character ISO code for the source language.

=head2 lc_tgt (Str)

2-character ISO code for the target language.

=head2 custom_data (Str)

Up to 1024 bytes of arbitrary text describing the Job in UTF-8 encoding.

=head2 unit_count (Int)

The number of units (words or characters) in the body_src.

=head2 tier (Str)

The tier under which this Job is being translated: machine, standard, pro, ultra, ultra_pro

=head2 credits (Num)

A decimal figure representing how many credits this Job will cost.

=head2 status (Str)

The Job's status: unpaid, available, pending, reviewable, revising, approved, rejected, cancelled, held

=head2 eta (DateTime::Duration)

A L<DateTime::Duration> object representing an estimate of when the Job will be
completed.

Usually used as `$job->eta->seconds`.

=head2 ctime (DateTime)

A L<DateTime> representing the Job's creation date and time.

=head2 force (Bool)

Whether to force a Job to be translated, even if a Job with the same body_src
already exists.

=head2 use_preferred (Bool)

Whether to only allow a "preferred translator" to work this Job.

=head2 auto_approve (Bool)

Whether to automatically approve this Job once the translation is completed.

=head2 mt (Bool)

Whether the body_tgt was translated via machine translation.

=head2 callback_url (Str)

A URL to which events related to this Job should be posted.

=head2 captcha_url (Str)

A URL pointing to a captcha image.

This will be set on Jobs in 'reviewable' status and must be submitted when
rejecting a Job.

See L<WebService::MyGengo::Client>'s `reject_job` method.

=head2 preview_url (Str)

A URL pointing to a graphical representation of the translated text.

=cut
sub id { shift->job_id }
has [qw/job_id group_id/] => ( is => 'ro' , isa => 'Int' );
has 'slug' => ( is => 'ro' , isa => 'Str', default => 0 );
has 'body_src' => ( is => 'ro' , isa => 'Str', required => 1 );
has 'body_tgt' => ( is => 'ro' , isa => 'WebService::MyGengo::body_tgt' );
has [qw/lc_src lc_tgt/] => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::LanguageCode'
    , required  => 1
    );
has 'custom_data' => ( is => 'ro', isa => 'Str' );
has 'unit_count' => ( is => 'ro' , isa => 'Int' );
has 'tier' => ( is => 'ro' , isa => 'WebService::MyGengo::Tier', required => 1 );
has 'credits' => ( is => 'ro' , isa => 'WebService::MyGengo::Num' );
has 'status' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::Job::Status'
    , default   => 'available'
    );
has 'eta' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::DateTime::Duration'
    , coerce    => 1
    );
has 'ctime' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::DateTime'
    , coerce    => 1
    , trigger   => sub {
        shift->ctime->set_formatter(
            DateTime::Format::Strptime->new( pattern => '%F %H:%M:%S %Z' )
            );
        }
    );
has [qw/force use_preferred auto_approve mt/] => (
    is          => 'ro'
    , isa       => 'Bool'
    , default   => 0
    );
has [qw/callback_url captcha_url preview_url/] => (
    is          => 'ro'
    , isa       => 'Maybe[Str]' # todo URI constraint/coercion
    );

=head2 comment (WebService::MyGengo::Comment|Undef)

This is only here to support the 'comment' option for the constructor.

Returns the most recently-added comment.

=cut
has comment => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::Comment|Undef'
# todo Results in coercion errors
#    , isa       => 'Maybe[WebService::MyGengo::Comment]'
    , coerce    => 1
    , lazy      => 1
    , clearer   => '_clear_comment'
    , default   => sub {
        my ( $self ) = ( shift );
        my $c = $self->get_comment( $self->comment_count - 1 );
        return blessed($c) ? $c->body : undef;
        }
    , trigger   => sub {
        my ( $self ) = ( shift );
        @_ or next;
        $self->_add_comment( @_ );
        $self->_clear_comment; # Refresh comment on every call
        }
    );

=head2 comments (Array)

A list of L<WebService::MyGengo::Comment> objects for this Job.

Provides:

=over

=item fetched_comments - Returns true if comments have been fetched from the API

=item has_comments - Returns the number of comments in the list

=item comment_count - Returns the number of comments in the list

=item get_comment($id) - Returns a specific comment by list index

=back

=cut
has '_comments' => (
    traits      => ['Array']
    , is        => 'ro'
    , isa       => 'WebService::MyGengo::CommentThread'
    , coerce    => 1
    , default   => sub { [] }
    , trigger   => sub { shift->_set_fetched_comments(1) }
    , handles   => {
        comments            => 'elements'
        , comment_count     => 'count'
        , has_comments      => 'count' # See fetched_comments
        , get_comment       => 'get'
        , _add_comment      => 'push' # todo immutable object
        , _clear_comments   => 'clear'
        }
    );
has fetched_comments => (
    is          => 'rw'
    , isa       => 'Bool'
    , init_arg  => undef
    , lazy      => 1
    , default   => 0
    , writer    => '_set_fetched_comments'
    );

#=head2 _set_comments( ArrayRef[WebService::MyGengo::Comment] )
#
#Replace the existing comment collection with a new one.
#
#Returns the new comment list.
#
#todo It would be nice to have an immutable object...
#
#=cut
sub _set_comments {
    my ( $self, $comments ) = ( shift, @_ );

    $self->_clear_comments;
    $self->_add_comment( $_ ) foreach ( @$comments );

    return $self->comments;
}

=head2 revisions (Array)

A list of L<WebService::MyGengo::Revision> objects for this Job.

Provides:

=over

=item fetched_revisions - Returns true if revisions have been fetched from the API

=item has_revisions - Returns the number of revisions in the list

=item revision_count - Returns the number of revisions in the list

=item get_revision($id) - Returns a specific revision by list index

=back

=cut
has '_revisions' => (
    traits      => ['Array']
    , is        => 'ro'
    , isa       => 'ArrayRef[WebService::MyGengo::Revision]'
    , default   => sub { [] }
    , trigger   => sub { shift->_set_fetched_revisions(1) }
    , handles   => {
        revisions           => 'elements'
        , revision_count    => 'count'
        , has_revisions     => 'count' # See fetched_revisions
        , get_revision      => 'get'
        , _add_revision     => 'push' # todo immutable object
        , _clear_revisions  => 'clear'
        }
    );
has fetched_revisions => (
    is          => 'rw'
    , isa       => 'Bool'
    , init_arg  => undef
    , lazy      => 1
    , default   => 0
    , writer    => '_set_fetched_revisions'
    );

#=head2 _set_revisions( ArrayRef[WebService::MyGengo::Comment] )
#
#Replace the existing revision collection with a new one.
#
#Returns the new revision list.
#
#todo It would be nice to have an immutable object...
#
#=cut
sub _set_revisions {
    my ( $self, $revs ) = ( shift, @_ );

    $self->_clear_revisions;
    $self->_add_revision( $_ ) foreach ( @$revs );

    return $self->revisions;
}

=head2 feedback (WebService::MyGengo::Feedback|Undef)

A L<WebService::MyGengo::Feedback> object for this Job.

Provides:

=over

=item fetched_feedback - Returns true if feedback has been fetched from the API

=item has_feedback - Returns true if feedback is defined

=back

=cut
has 'feedback' => (
    is          => 'rw'
    , isa       => 'Maybe[WebService::MyGengo::Feedback]'
    , lazy      => 1
    , default   => undef
    , trigger   => sub { shift->_set_fetched_feedback(1) }
    , predicate => 'has_feedback'
    , writer    => '_set_feedback'
    );
has fetched_feedback => (
    is          => 'rw'
    , isa       => 'Bool'
    , init_arg  => undef
    , lazy      => 1
    , default   => 0
    , writer    => '_set_fetched_feedback'
    );

=head1 METHODS

=head2 is_(unpaid|available|pending|reviewable|revising|approved|rejected|cancell?ed|held)

Returns true if the Job is of the given status, false otherwise

=cut
sub _is_status      { shift->status eq shift }
sub is_unpaid       { shift->_is_status('unpaid') }
sub is_available    { shift->_is_status('available') }
sub is_pending      { shift->_is_status('pending') }
sub is_reviewable   { shift->_is_status('reviewable') }
sub is_revising     { shift->_is_status('revising') }
sub is_approved     { shift->_is_status('approved') }
sub is_rejected     { shift->_is_status('rejected') }
sub is_canceled     { shift->_is_status('cancelled') }
sub is_cancelled    { shift->is_canceled }
sub is_held         { shift->_is_status('held') }

#=head2 _build_attributes_to_serialize
#
#The list of attributes to serialize via the `to_hash` method.
#
#See: L<WebService::MyGengo::Base>
#
#todo Use traits
#
#=cut
sub _build_attributes_to_serialize {
    return [qw/
            body_src lc_src lc_tgt tier force comment use_preferred
            callback_url auto_approve custom_data
            /];
}

=head2 around to_hash

HACKS: The eta value (a L<DateTime::Duration>) does not stringify to a
meaningful value, so we convert it to seconds here.

We also remove the feedback entry.

See: L<WebService::MyGengo::Base>

=cut
#todo Use traits for serialization
around to_hash => sub {
    my ( $orig, $self ) = ( shift, shift );

    my $hash = $self->$orig( @_ );

    # todo This assumes the duration object was built from seconds,
    #   which ours always are. Using a DateTime::Format::Duration
    #   with a '%s' is safer.
    defined $hash->{eta} and $hash->{eta} = $self->eta->seconds;

    delete $hash->{feedback};

    return $hash;
};


__PACKAGE__->meta->make_immutable();
1;

=head1 TODO

 * We really need to make a decision in the immutability of this object.
Is it just pedantic to try and attempt it? We could save time using
mutability. This could affect caching, though.

=head1 SEE ALSO

L<http://mygengo.com/api/developer-docs/methods/translate-job-id-get/>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
