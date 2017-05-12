package WebService::Cmis::ServerException;

=head1 NAME

WebService::Cmis::ServerException

=head1 DESCRIPTION

This exception will be raised when an error happened on the server
while the client communicates with it.

See L<WebService::Cmis::Client/processErrors>.

Parent class: Error

=cut

use strict;
use warnings;
use Error ();
our @ISA = qw(Error);

=head1 METHODS

=over 4

=item new()

=cut

sub new {
  my ($class, $client) = @_;

  #print STDERR "creating a ServerException class=$class\n";

  my $reason = $client->responseStatusLine;
  my $url = $client->responseBase;

  my $text = $client->responseContent;

  # clean up response to make *any* sense of it.
  # why is it so hard to track the reason for a 500 server error
  $text =~ s/<!--.*?-->//gs;  # remove all HTML comments
  $text =~ s/<(?!nop)[^>]*>//g; # remove all HTML tags except <nop>
  $text =~ s/\&[a-z]+;/ /g; # remove entities
  $text =~ s/\n[^\n]+\.java:.*//gs;  # remove java stack trace
  $text =~ s/^\s+//gm;

  return $class->SUPER::new(-text => "$reason at $url\n\n" . $text);
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

