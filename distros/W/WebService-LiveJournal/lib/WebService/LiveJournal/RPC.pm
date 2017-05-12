package WebService::LiveJournal::RPC;

use strict;
use warnings;
use Exporter;
use RPC::XML;
use RPC::XML::ParserFactory;
use RPC::XML::Client;
our @ISA = qw/ Exporter /;
our @EXPORT_OK = qw/ xml2hashref xml2hash /;

# ABSTRACT: RPC utilities for WebService::LiveJournal
our $VERSION = '0.08'; # VERSION

my $parser = new RPC::XML::ParserFactory;

sub xml2hashref
{
  my $xml = shift;
  my $response = $parser->parse($xml);
  my $struct = $response->value;
  my $hash = $struct->value;
}

sub xml2hash { %{ xml2hashref(@_) } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LiveJournal::RPC - RPC utilities for WebService::LiveJournal

=head1 VERSION

version 0.08

=head1 SEE ALSO

L<WebService::LiveJournal>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
