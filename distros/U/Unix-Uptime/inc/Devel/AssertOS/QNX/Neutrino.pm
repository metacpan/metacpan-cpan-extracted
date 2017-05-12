package Devel::AssertOS::QNX::Neutrino;

use Devel::CheckOS;

$VERSION = '1.1';

sub os_is { $^O =~ /^nto$/i ? 1 : 0; }

sub expn { "The operating system is version 6 of QNX, also known as Neutrino" }

Devel::CheckOS::die_unsupported() unless(os_is());

=head1 COPYRIGHT and LICENCE

Copyright 2007 - 2014 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
