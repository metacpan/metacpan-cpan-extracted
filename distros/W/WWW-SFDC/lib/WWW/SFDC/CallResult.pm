package WWW::SFDC::CallResult;
# ABSTRACT: Provides a flexible container for calls to SFDC containers
use strict;
use warnings;
use overload
  bool => sub {!$_[0]->request->fault};

our $VERSION = '0.37'; # VERSION


use Log::Log4perl ':easy';

use Moo;


has 'request',
  is => 'ro',
  required => 1;


has 'headers',
  is => 'ro',
  lazy => 1,
  builder => sub {
    return $_[0]->request->headers()
  };


has 'result',
  is => 'ro',
  lazy => 1,
  builder => sub {
    $_[0]->request->result;
  };


has 'results',
  is => 'ro',
  lazy => 1,
  builder => sub {
    my $results = [$_[0]->request->paramsall()];
    TRACE sub { Dumper $results};
    return $results;
  };

1;

__END__

=pod

=head1 NAME

WWW::SFDC::CallResult - Provides a flexible container for calls to SFDC containers

=head1 VERSION

version 0.37

=head1 ATTRIBUTES

=head2 request

The original request sent to SFDC. This is a SOAP::SOM.

=head2 headers

A hashref of headers from the call, which might contain, for example, usage
limit info or debug logs.

=head2 result

The result of the call. This is appropriate when expecting a scalar - for
instance, a deployment ID.

=head2 results

The results of the call. This is appropriate when recieving a list of results,
for instance when querying or updating data.

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
