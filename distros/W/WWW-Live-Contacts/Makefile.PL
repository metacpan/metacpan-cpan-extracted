package Makefile;
use strict;
use warnings;
use 5.005;
use ExtUtils::MakeMaker;
use English qw(-no_match_vars);

WriteMakefile(
              'NAME'          => 'WWW::Live::Contacts',
              'AUTHOR'        => q(Andrew M. Jenkinson <jenkinson@cpan.org>),
              'ABSTRACT_FROM' => 'lib/WWW/Live/Contacts.pm',
              'VERSION_FROM'  => 'lib/WWW/Live/Contacts.pm',
              'DISTNAME'      => 'WWW-Live-Contacts',
              'PREREQ_PM'     => {
                                  'LWP'             => 0,
                                  'Crypt::SSLeay'   => 0,
                                  'XML::Simple'     => 0,
                                  'Carp'            => 0,
                                  'WWW::Live::Auth' => '1.0.0',
                                 },
              'dist'          => { COMPRESS => 'gzip', SUFFIX => 'gz', },
              'LICENSE'       => 'lgpl',
             );

1;
__END__

=head1 AUTHOR

Andrew M. Jenkinson <jenkinson@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 Andrew M. Jenkinson.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
