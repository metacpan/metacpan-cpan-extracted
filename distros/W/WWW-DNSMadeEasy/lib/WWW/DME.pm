package WWW::DME;
BEGIN {
  $WWW::DME::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::DME::VERSION = '0.001';
}
# ABSTRACT: Shorter package name for accessing DNSMadeEasy API

use Moo;
extends 'WWW::DNSMadeEasy';

1;


__END__
=pod

=head1 NAME

WWW::DME - Shorter package name for accessing DNSMadeEasy API

=head1 VERSION

version 0.001

=head1 DESCRIPTION

See L<WWW::DNSMadeEasy>

=encoding utf8

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

