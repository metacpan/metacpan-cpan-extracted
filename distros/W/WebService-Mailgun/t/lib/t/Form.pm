package t::Form;
use strict;
use warnings;
use Exporter 'import';
use WebService::Mailgun;

our @EXPORT_OK = qw(mailgun fields values_of field);

# For the tests of the form-data requests (message, mime). They never reach a real API server:
# the HTTP client is replaced with one that keeps the request it is given and answers with an
# empty success.
{
    package t::Form::Client;
    sub new     { bless {}, shift }
    sub request { $_[0]{request} = $_[1]; t::Form::Response->new }

    package t::Form::Response;
    sub new         { bless {}, shift }
    sub is_success  { 1 }
    sub status_line { '200 OK' }
    sub content     { '{"id":"<1@example.com>","message":"Queued. Thank you."}' }
}

my $client = t::Form::Client->new;

# A WebService::Mailgun whose requests are kept by the client above.
sub mailgun {
    my $mailgun = WebService::Mailgun->new(
        api_key => 'dummy-api-key',
        domain  => 'example.com',
    );
    $mailgun->{_client} = $client;
    return $mailgun;
}

# The last request, or undef. Cleared with t::Form::forget().
sub request { $client->{request} }
sub forget  { delete $client->{request} }

# The form fields of the last request, in order, as [name, value, filename].
sub fields {
    my $req = request();
    my ($boundary) = $req->header('Content-Type') =~ /boundary="?([^";]+)"?/;
    my @fields;
    for my $part (grep { length } split /--\Q$boundary\E(?:--)?\r\n/, $req->content) {
        my ($head, $body) = split /\r\n\r\n/, $part, 2;
        my ($name)     = $head =~ /name="([^"]*)"/;
        my ($filename) = $head =~ /filename="([^"]*)"/;
        $body =~ s/\r\n\z//;
        push @fields, [ $name, $body, $filename ];
    }
    return @fields;
}

# The values of the field $name, in order.
sub values_of {
    my ($name) = @_;
    return [ map { $_->[1] } grep { $_->[0] eq $name } fields() ];
}

# The first field named $name, or undef.
sub field {
    my ($name) = @_;
    my ($field) = grep { $_->[0] eq $name } fields();
    return $field;
}

1;
