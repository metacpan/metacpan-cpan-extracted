package WebService::XING::Response;

use Mo 0.30 qw(required);

use overload
    '""' => \&as_string,
    '0+' => sub { $_[0]->code },
    bool => \&is_success,
    fallback => 1;

has code => (required => 1);

has message => (required => 1);

has headers => (required => 1);

has content => (required => 1);

sub as_string { $_[0]->code . ' ' . $_[0]->message }

sub is_success { $_[0]->code < 400 }

1;

__END__

=head1 NAME

WebService::XING::Response - XING API Response Class

=head1 DESCRIPTION

Most methods of L<WebService::XING> return object instances of the
C<WebService::XING::Response> class, that contains HTTP status and
header information besides the actual response.

=head1 OVERLOADING

A C<WebService::XING::Response> object is L<overloaded|overload>
with the follwing behaviour:

=over

=item String context:

  say $response;      # => "200 OK"

The HTTP status message (L</code> . " " . L</message>).
Calls L</as_string> behind the curtain.

=item Numeric context:

  say "created" if $response == 201;

The HTTP status L</code>.

=item Boolean context:

  $res = $xing->get_user_details or die $res;

Is C<true> for L</code> E<lt> 400, otherwise C<false>.
Calls L</is_success> behind the curtain.

=back

=head1 ATTRIBUTES

=head2 code

3-digit HTTP status code.

=head2 message

A human readable message, but not intended to be displayed to the user.

=head2 headers

A L<HTTP::Headers> object. Never rely on this item, it is virtually only
useful for debugging.

=head2 content

The (decoded) content.

=head1 METHODS

=head2 as_string

  say $response->as_string;      # => "200 OK"

The HTTP status message (L</code> . " " . L</message>).

=head2 is_success

  $res->is_success or die $res->as_string;

Is C<true> for L</code> E<lt> 400, otherwise C<false>.

