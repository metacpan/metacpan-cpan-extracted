package WebService::TypeSafe;

use 5.020;
use strict;
use warnings;
use Exporter 'import';
use WebService::TypeSafe::Client ();
use WebService::TypeSafe::Question ();
use WebService::TypeSafe::RetryPolicy ();

our $VERSION = '0.01';
our @EXPORT_OK = qw(choice noul score retry_policy);

sub new { shift; return WebService::TypeSafe::Client->new(@_) }
sub choice { return WebService::TypeSafe::Question::Choice->new(@_) }
sub noul { return WebService::TypeSafe::Question::Noul->new(@_) }
sub score { return WebService::TypeSafe::Question::Score->new(@_) }
sub retry_policy { return WebService::TypeSafe::RetryPolicy->new(@_) }

1;

=head1 NAME

WebService::TypeSafe - Perl client for TypeSafe AI's System One (Jev) API

=head1 SYNOPSIS

    use WebService::TypeSafe qw(choice noul score);

    my $client = WebService::TypeSafe->new(
        api_key => $api_key,
    );
    my $result = $client->system_one(
        state => { message => 'My payment failed. Please help now.' },
        questions => {
            urgent => noul(
                instructions => 'Does `message` convey urgency?',
            ),
            department => choice(
                instructions => 'Which team should handle `message`?',
                criteria => {
                    billing   => 'Payments, invoices, or refunds',
                    technical => 'Bugs, outages, or integrations',
                    other     => undef,
                },
            ),
            frustration => score(
                instructions => 'How frustrated is the customer?',
                criteria => ['Calm', 'Concerned', 'Very angry'],
            ),
        },
    );

    say $result->answers->{urgent}->noul;
    say $result->choices->{department}->choice;

=head1 DESCRIPTION

This module provides an idiomatic synchronous Perl interface matching the
official TypeSafe Python and JavaScript SDKs: typed question constructors,
typed response objects, model listing, retries, environment configuration,
and structured exceptions.

=head1 CONFIGURATION

Pass the API key explicitly when constructing the client:

    my $client = WebService::TypeSafe->new(
        api_key => $api_key,
    );

The value can come from your application's configuration or secret manager.
Do not hard-code or commit the actual key.

If C<api_key> is omitted, the client optionally falls back to
C<TYPESAFE_API_KEY>:

    my $client = WebService::TypeSafe->new;

Explicit constructor values take precedence over environment variables.

=over 4

=item * C<api_key> constructor option (primary API)

=item * C<TYPESAFE_API_KEY> (optional fallback when C<api_key> is omitted)

=item * C<TYPESAFE_DEFAULT_MODEL> (defaults to C<jev-latest>)

=item * C<TYPESAFE_BASE_URL> (defaults to C<https://api.typesafe.ai>)

=back

=head1 AUTHOR

Provided by Data Sculpting Inc.

Email: C<info@datasculpting.com>

Website: L<https://datasculpting.com/>

=head1 LICENSE

Copyright (c) 2026 Data Sculpting Inc.

This library is released under the MIT License.

=cut
