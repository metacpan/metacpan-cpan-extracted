package WebService::MyGengo::Comment;

use Moose;
use Moose::Util::TypeConstraints;
# This interferes with stringification overload
# See https://rt.cpan.org/Public/Bug/Display.html?id=50938
#use namespace::autoclean;

BEGIN { extends 'WebService::MyGengo::Base' };

# Stringify to the comment body
use overload ( '""' => sub { shift->body } );

=head1 NAME

WebService::MyGengo::Comment - A Comment in the myGengo system.

=head1 SYNOPSIS

    my $comment = WebService::MyGengo::Comment->new( { body => 'Hello.' } );
    # or
    $comment = WebService::MyGengo::Comment->new( 'Hello.' );

    # Do something with the Comment
    $job = $client->add_job_comment( $job, $comment );

    # Returns ->body on stringification
    my $body = "$comment"; # $body eq "Hello."

=head1 ATTRIBUTES

=head2 body (Str)

The body of the comment in UTF-8 encoding.

B<Note:> Sometimes the API returns 'null' (undef) for this value. In this case
the value will be coerced into an empty string.

=cut
subtype 'WebService::MyGengo::Comment::body'
    , as 'Str';
coerce 'WebService::MyGengo::Comment::body'
    , from 'Undef', via { '' };
has 'body' => (
    is          => 'ro'
    , isa => 'WebService::MyGengo::Comment::body'
    , required => 1
    );

=head2 author (Str)

The author of the message.

This value is set by the API to one of the following: translator, customer

=cut
subtype 'WebService::MyGengo::CommentAuthor'
    , as 'Str'
    , where { $_ eq 'translator' || $_ eq 'customer' }
    , message { "Legal values for 'author': translator, customer" }
    ;
has 'author' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::CommentAuthor'
    );

=head2 ctime (DateTime)

The timestamp at which this Comment was created.

This value is set by the API.

=cut
has 'ctime' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::DateTime'
    , coerce    => 1
    );

#=head1 METHODS
#
#=head2 around BUILDARGS
#
#Allow single-argument constructor for `body`
#
#=cut
around BUILDARGS => sub {
    my ( $orig, $class, $val ) = ( shift, shift, @_ );
    (ref($val) eq 'HASH' || $#_) and return $class->$orig( @_ );
    return { body => $val };
};


no Moose;
__PACKAGE__->meta->make_immutable();

1;

=head2 SEE ALSO

L<http://mygengo.com/api/developer-docs/methods/translate-job-id-comments-get/>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
