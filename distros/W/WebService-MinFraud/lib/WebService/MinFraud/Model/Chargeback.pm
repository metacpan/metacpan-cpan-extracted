package WebService::MinFraud::Model::Chargeback;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

1;

# ABSTRACT: Model class for minFraud Chargeback

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Model::Chargeback - Model class for minFraud Chargeback

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );

  my $request = { ip_address => '24.24.24.24' } ;
  my $chargeback = $client->chargeback($request);

  say $chargeback->isa('WebService::MinFraud::Model::Chargeback');

=head1 DESCRIPTION

This class provides an interface consistent with the fraud services' model interfaces.

The Chargeback API will not return any content. See L<API
documentation|https://dev.maxmind.com/minfraud/chargeback/>
for more details.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
