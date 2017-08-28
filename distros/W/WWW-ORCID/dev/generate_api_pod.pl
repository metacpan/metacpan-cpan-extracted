#!perl

use strict;
use warnings;
use Class::Load qw(try_load_class);
use Carp;

my $api = shift;
my $class = "WWW::ORCID::API::$api";

try_load_class($class)
    or croak("Could not load $class: $!");

my $ops = $class->ops;
my ($major, $minor) = $api =~ /([0-9])_([0-9])/;
my ($name) = $api =~ /_([a-z]+)$/;
$name ||= 'member';
$name = "$major.$minor $name";

my $pod = <<EOF;

=pod

=head1 NAME

$class - A client for the ORCID $name API

=head1 CREATING A NEW INSTANCE

The C<new> method returns a new L<$name API client|$class>.

Arguments to new:

=head2 C<client_id>

Your ORCID client id (required).

=head2 C<client_secret>

Your ORCID client secret (required).

=head2 C<sandbox>

The client will talk to the L<ORCID sandbox API|https://api.sandbox.orcid.org/v2.0> if set to C<1>.

=head2 C<transport>

Specify the HTTP client to use. Possible values are L<LWP> or L<HTTP::Tiny>. Default is L<LWP>.

=head1 METHODS

=head2 C<client_id>

Returns the ORCID client id used by the client.

=head2 C<client_secret>

Returns the ORCID client secret used by the client.

=head2 C<sandbox>

Returns C<1> if the client is using the sandbox API, C<0> otherwise.

=head2 C<transport>

Returns what HTTP transport the client is using.

=head2 C<api_url>

Returns the base API url used by the client.

=head2 C<oauth_url>

Returns the base OAuth url used by the client.

=head2 C<access_token>

Request a new access token.

    my \$token = \$client->access_token(
        grant_type => 'client_credentials',
        scope => '/read-public',
    );

=head2 C<authorize_url>

Helper that returns an authorization url for 3-legged OAuth requests.

    # in your web application
    redirect(\$client->authorize_url(
        show_login => 'true',
        scope => '/person/update',
        response_type => 'code',
        redirect_uri => 'http://your.callback/url',
    ));

See the C</authorize> and C</authorized> routes in the included playground
application for an example.

=head2 C<record_url>

Helper that returns an orcid record url.

    \$client->record_url('0000-0003-4791-9455')
    # returns
    # http://orcid.org/0000-0003-4791-9455
    # or
    # http://sandbox.orcid.org/0000-0003-4791-9455

=head2 C<read_public_token>

Return an access token with scope C</read-public>.
EOF

$pod .= <<EOF if $class->can('read_limited_token');

=head2 C<read_limited_token>

Return an access token with scope C</read-limited>.
EOF

$pod .= <<EOF if $class->can('client');

=head2 C<client>

Get details about the current client.
EOF

$pod .= <<EOF if $class->can('search');

=head2 C<search>

    my \$hits = \$client->search(q => "johnson");
EOF

my $token_arg = 'token => $token';
my $orcid_arg = ', orcid => $orcid';
my $pc_arg = ", put_code => '123'";
my $pc_bulk_arg = ", put_code => ['123', '456']";

for my $op (sort keys %$ops) {
    my $spec = $ops->{$op};
    my $sym = $op;
    $sym =~ s|[-/]|_|g;

    my $base_args = $token_arg;
    $base_args .= $orcid_arg if $spec->{orcid};

    if ($spec->{get} || $spec->{get_pc} || $spec->{get_pc_bulk}) {
        $pod .= "=head2 C<${sym}>\n\n";

        if ($spec->{get} && ($spec->{get_pc} || $spec->{get_pc_bulk})) {
            $pod .= "    my \$recs = \$client->${sym}($base_args);\n";
        }
        elsif ($spec->{get}) {
            $pod .= "    my \$rec = \$client->${sym}($base_args);\n";
        }
        if ($spec->{get_pc}) {
            $pod .= "    my \$rec = \$client->${sym}($base_args$pc_arg);\n";
        }
        if ($spec->{get_pc_bulk}) {
            $pod .= "    my \$recs = \$client->${sym}($base_args$pc_bulk_arg);\n";
        }
        $pod .= "\nEquivalent to:\n\n    \$client->get('${op}', \%opts)\n\n";
    }

    if ($spec->{add}) {
        $pod .= "=head2 C<add_${sym}>\n\n";
        $pod .= "    \$client->add_${sym}(\$data, $base_args);\n";
        $pod .= "\nEquivalent to:\n\n    \$client->add('${op}', \$data, \%opts)\n\n";
    }

    if ($spec->{update}) {
        $pod .= "=head2 C<update_${sym}>\n\n";
        $pod .= "    \$client->update_${sym}(\$data, $base_args$pc_arg);\n";
        $pod .= "\nEquivalent to:\n\n    \$client->update('${op}', \$data, \%opts)\n\n";
    }

    if ($spec->{delete}) {
        $pod .= "=head2 C<delete_${sym}>\n\n";
        $pod .= "    my \$ok = \$client->delete_${sym}($base_args$pc_arg);\n";
        $pod .= "\nEquivalent to:\n\n    \$client->delete('${op}', \%opts)\n\n";
    }
}

$pod .= <<EOF;
=head2 C<last_error>

Returns the last error returned by the ORCID API, if any.

=head2 C<log>

Returns the L<Log::Any> logger.

=cut

EOF

print $pod;
