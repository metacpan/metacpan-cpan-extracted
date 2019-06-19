package WebService::MinFraud::Record::ScoreIPAddress;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

with 'WebService::MinFraud::Role::Record::HasRisk';

1;

# ABSTRACT: Contains data for the IP address's risk

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Record::ScoreIPAddress - Contains data for the IP address's risk

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );
  my $request    = { device => { ip_address => '24.24.24.24' } };
  my $score      = $client->score($request);
  my $ip_address = $score->ip_address;
  say $ip_address->risk;

=head1 DESCRIPTION

This class contains the risk for the given C<ip_address>.

=head1 METHODS

This class provides the following method:

=head2 risk

Returns the risk associated with the IP address. The value ranges from 0.01 to
99. A higher value indicates a higher risk. The IP address risk is distinct
from the value returned by C<< risk_score >> methods of
L<WebService::MinFraud::Model::Insights> and
L<WebService::MinFraud::Model::Score> modules.

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_risk

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
