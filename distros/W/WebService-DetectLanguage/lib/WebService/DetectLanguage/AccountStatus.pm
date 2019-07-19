package WebService::DetectLanguage::AccountStatus;
$WebService::DetectLanguage::AccountStatus::VERSION = '0.04';
use 5.010;
use Moo;

has date                 => ( is => 'ro' );
has requests             => ( is => 'ro' );
has bytes                => ( is => 'ro' );
has plan                 => ( is => 'ro' );
has plan_expires         => ( is => 'ro' );
has daily_requests_limit => ( is => 'ro' );
has daily_bytes_limit    => ( is => 'ro' );
has status               => ( is => 'ro' );

1;

=head1 NAME

WebService::DetectLanguage::AccountStatus - holds account status from detectlanguage.com

=head1 SYNOPSIS

 my $status = $api->account_status();
 printf "language = %s\n", $status->date;
 printf "requests = %d\n", $result->requests;
 printf "plan     = %s\n", $result->plan;
 printf "status   = %s\n", $result->status;
 ...

=head1 DESCRIPTION

This module is a class for data objects returned
by the C<account_status()> method
of L<WebService::DetectLanguage>.

See the documentation of that module for more details.

=head1 ATTRIBUTES

=head2 date

Today's date, in ISO 8601 format (YYYY-MM-DD),
for the UTC timezone.

=head2 requests

The number of requests sent today.

=head2 bytes

Text bytes sent today.

=head2 plan

The text code for the plan you're on.
A list of the supported plans can be seen at L<https://detectlanguage.com/plans>.

=head2 plan_expires

The date when your plan will expire.
This will be C<undef> is there's no planned expiry.

=head2 daily_requests_limit

The maximum number of requests you can make in a day.

=head2 daily_bytes_limit

The number of bytes you can send per day.

=head2 status

A text string giving the status for your account.


=head1 SEE ALSO

L<WebService::DetectLanguage> the main module for talking
to the language detection API at detectlanguage.com.

L<https://detectlanguage.com/documentation#account-status>
the API's documentation for the account status method.

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
