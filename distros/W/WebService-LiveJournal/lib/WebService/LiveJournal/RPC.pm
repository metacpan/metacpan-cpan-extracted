package WebService::LiveJournal::RPC;

use strict;
use warnings;
use Exporter;
use RPC::XML;
use RPC::XML::ParserFactory;
use RPC::XML::Client;
our @ISA = qw/ Exporter /;
our @EXPORT_OK = qw/ xml2hashref xml2hash /;

# ABSTRACT: (Deprecated) RPC utilities for WebService::LiveJournal
our $VERSION = '0.09'; # VERSION


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

WebService::LiveJournal::RPC - (Deprecated) RPC utilities for WebService::LiveJournal

=head1 VERSION

version 0.09

=head1 DESCRIPTION

B<NOTE>: This distribution is deprecated.  It uses the outmoded XML-RPC protocol.
LiveJournal has also been compromised.  I recommend using DreamWidth instead
(L<https://www.dreamwidth.org/>) which is in keeping with the original philosophy
LiveJournal regarding advertising.

=head1 SEE ALSO

L<WebService::LiveJournal>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
