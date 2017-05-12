package WWW::TypePad::Conversations;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::conversations { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Conversations - Conversations API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item add_external_response

  my $res = $tp->conversations->add_external_response($id);

Record a response to a conversation originating from somewhere other than a TypePad blog.

Returns hash reference which contains following properties.

=over 8

=item response

(ConversationResponse) A ConversationResponse object representing the created response.


=back

=cut

sub add_external_response {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/conversations/%s/add-external-response.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item add_poll_response

  my $res = $tp->conversations->add_poll_response($id);

Record a response choosing one of the polling options for this conversation.

Returns hash reference which contains following properties.

=over 8

=item responseToken

(string) A secret token associated with the responseId.

=item responseId

(string) An identifier for the poll response.


=back

=cut

sub add_poll_response {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/conversations/%s/add-poll-response.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_responses

  my $res = $tp->conversations->get_responses($id);

Retrieve a list of responses for the selected conversation.

Returns StreamE<lt>ConversationResponseE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole stream of which this response contains a subset. CE<lt>nullE<gt> if an exact count cannot be determined.

=item estimatedTotalResults

(integer) An estimate of the total number of items in the whole list of which this response contains a subset. CE<lt>nullE<gt> if a count cannot be determined at all, or if an exact count is returned in CE<lt>totalResultsE<gt>.

=item moreResultsToken

(string) An opaque token that can be used as the CE<lt>start-tokenE<gt> parameter of a followup request to retrieve additional results. CE<lt>nullE<gt> if there are no more results to retrieve, but the presence of this token does not guarantee that the response to a followup request will actually contain results.

=item entries

(arrayE<lt>ConversationResponseE<gt>) A selection of items from the underlying stream.


=back

=cut

sub get_responses {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/conversations/%s/responses.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub responses {
    my $self = shift;
    Carp::carp("'responses' is deprecated. Use 'get_responses' instead.");
    $self->get_responses(@_);
}

=pod



=item get_featured_responses

  my $res = $tp->conversations->get_featured_responses($id);

Retrieve a list of featured responses for the selected conversation.

Returns StreamE<lt>ConversationResponseE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole stream of which this response contains a subset. CE<lt>nullE<gt> if an exact count cannot be determined.

=item estimatedTotalResults

(integer) An estimate of the total number of items in the whole list of which this response contains a subset. CE<lt>nullE<gt> if a count cannot be determined at all, or if an exact count is returned in CE<lt>totalResultsE<gt>.

=item moreResultsToken

(string) An opaque token that can be used as the CE<lt>start-tokenE<gt> parameter of a followup request to retrieve additional results. CE<lt>nullE<gt> if there are no more results to retrieve, but the presence of this token does not guarantee that the response to a followup request will actually contain results.

=item entries

(arrayE<lt>ConversationResponseE<gt>) A selection of items from the underlying stream.


=back

=cut

sub get_featured_responses {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/conversations/%s/responses/@featured.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub featured_responses {
    my $self = shift;
    Carp::carp("'featured_responses' is deprecated. Use 'get_featured_responses' instead.");
    $self->get_featured_responses(@_);
}

=pod



=item get_from_voices_responses

  my $res = $tp->conversations->get_from_voices_responses($id);

Retrieve a list of responses from invited participants for the selected conversation.

Returns StreamE<lt>ConversationResponseE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole stream of which this response contains a subset. CE<lt>nullE<gt> if an exact count cannot be determined.

=item estimatedTotalResults

(integer) An estimate of the total number of items in the whole list of which this response contains a subset. CE<lt>nullE<gt> if a count cannot be determined at all, or if an exact count is returned in CE<lt>totalResultsE<gt>.

=item moreResultsToken

(string) An opaque token that can be used as the CE<lt>start-tokenE<gt> parameter of a followup request to retrieve additional results. CE<lt>nullE<gt> if there are no more results to retrieve, but the presence of this token does not guarantee that the response to a followup request will actually contain results.

=item entries

(arrayE<lt>ConversationResponseE<gt>) A selection of items from the underlying stream.


=back

=cut

sub get_from_voices_responses {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/conversations/%s/responses/@from-voices.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub from_voices_responses {
    my $self = shift;
    Carp::carp("'from_voices_responses' is deprecated. Use 'get_from_voices_responses' instead.");
    $self->get_from_voices_responses(@_);
}

=pod

=back

=cut

### END auto-generated

1;
