package WebService::MinFraud::Model::Score;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use WebService::MinFraud::Record::Disposition;
use WebService::MinFraud::Record::ScoreIPAddress;

with 'WebService::MinFraud::Role::HasCommonAttributes',
    'WebService::MinFraud::Role::HasLocales',
    'WebService::MinFraud::Role::Model';

## no critic (ProhibitUnusedPrivateSubroutines)
sub _has { has(@_) }
## use critic

__PACKAGE__->_define_model_attributes(
    disposition => 'Disposition',
    ip_address  => 'ScoreIPAddress',
);

1;

# ABSTRACT: Model class for minFraud: Score

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Model::Score - Model class for minFraud: Score

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );

  my $request = { device => { ip_address => '24.24.24.24' } };
  my $score = $client->score($request);
  say $score->risk_score;

=head1 DESCRIPTION

This class provides a model for the data returned by the minFraud Score
web service.

For more details, see the L<API
documentation|https://dev.maxmind.com/minfraud/>.

=head1 METHODS

This class provides the following methods:

=head2 disposition

Returns a L<WebService::MinFraud::Record::Disposition> object representing the
disposition set for the transaction using custom rules.

=head2 funds_remaining

Returns the  I<approximate> US dollar value of the funds remaining on your
account. The fund calculation is near realtime so it may not be exact.

=head2 id

Returns a UUID that identifies the minFraud request. Please use this UUID in
bug reports or support requests to MaxMind so that we can easily identify a
particular request.

=head2 ip_address

Returns a L<WebService::MinFraud::Record::ScoreIPAddress> object representing
IP address data for the transaction.

=head2 queries_remaining

Returns the I<approximate> number of queries remaining for this service before
your account runs out of funds. The query counts are near realtime so they may
not be exact.

=head2 risk_score

Returns the risk score which is a number between 0.01 and 99. A higher score
indicates a higher risk of fraud.

=head2 warnings

Returns an ArrayRef of L<WebService::MinFraud::Record::Warning> objects. It is
B<highly recommended that you check this array> for issues when integrating the
web service.

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_funds_remaining

=head2 has_id

=head2 has_queries_remaining

=head2 has_risk_score

=head2 has_warnings

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
