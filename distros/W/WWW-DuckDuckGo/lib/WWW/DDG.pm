package WWW::DDG;
BEGIN {
  $WWW::DDG::AUTHORITY = 'cpan:DDG';
}
{
  $WWW::DDG::VERSION = '0.016';
}
# ABSTRACT: Short alias for L<WWW::DuckDuckGo>

use Moo;

extends 'WWW::DuckDuckGo';

1;

__END__

=pod

=head1 NAME

WWW::DDG - Short alias for L<WWW::DuckDuckGo>

=head1 VERSION

version 0.016

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=item *

Michael Smith <crazedpsyc@duckduckgo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by L<DuckDuckGo, Inc.|https://duckduckgo.com/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
