package WebService::MinFraud::Record::Disposition;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use Types::UUID;
use WebService::MinFraud::Types qw( Str );

has action => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

has reason => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

1;

# ABSTRACT: The disposition for the request as set by custom rules

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Record::Disposition - The disposition for the request as set by custom rules

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );
  my $request  = { device => { ip_address => '24.24.24.24' } };
  my $insights = $client->insights($request);
  my $disposition   = $insights->disposition;
  say 'Disposition action was ' . $disposition->action . ' with a reason of '
      . $disposition->reason;

=head1 DESCRIPTION

This class contains the disposition for the request as set by custom rules.

=head1 METHODS

This class provides the following methods:

=head2 action

The action to take on the transaction as defined by your custom rules. The
current set of values are "accept", "manual_review", and "reject". If you do
not have custom rules set up, this attribute will not be set.

=head2 reason

The reason for the action. The current possible values are "custom_rule",
"block_list", and "default". If you do not have custom rules set up,
this attribute will not be set.

=head1 PREDICATE METHODS

The following predicate methods are available, which return true if the related
data was present in the response body, false if otherwise:

=head2 has_action

=head2 has_reason

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
