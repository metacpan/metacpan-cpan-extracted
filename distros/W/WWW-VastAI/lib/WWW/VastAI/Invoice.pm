package WWW::VastAI::Invoice;
our $VERSION = '0.001';
# ABSTRACT: Billing invoice wrapper for Vast.ai account history

use Moo;
extends 'WWW::VastAI::Object';

sub type        { shift->data->{type} }
sub source      { shift->data->{source} }
sub description { shift->data->{description} }
sub amount      { shift->data->{amount} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Invoice - Billing invoice wrapper for Vast.ai account history

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::Invoice> wraps a single invoice or billing line item returned by
L<WWW::VastAI::API::Invoices>.

=head1 METHODS

=head2 type

Returns the invoice entry type.

=head2 source

Returns the billing source or category.

=head2 description

Returns the human-readable line-item description.

=head2 amount

Returns the billed amount as provided by the API.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Invoices>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-vastai/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
