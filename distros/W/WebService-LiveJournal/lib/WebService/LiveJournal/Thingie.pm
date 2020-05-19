package WebService::LiveJournal::Thingie;

use strict;
use warnings;
use overload '""' => sub { $_[0]->as_string };

# ABSTRACT: (Deprecated) base class for WebService::LiveJournal classes
our $VERSION = '0.09'; # VERSION


sub client
{
  my($self, $new_value) = @_;
  $self->{client} = $new_value if defined $new_value;
  $self->{client};
}

sub error { shift->client->error }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LiveJournal::Thingie - (Deprecated) base class for WebService::LiveJournal classes

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
