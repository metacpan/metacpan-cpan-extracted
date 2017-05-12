package XTaTIK::Docs::01_Installation;

use strict;
use warnings;

our $VERSION = '0.005002'; # VERSION

1;
__END__

=encoding utf8

=for stopwords eCommerce GEOIP Perlbrew PostgreSQL

=head1 NAME

XTaTIK::Docs::01_Installation - Installation instructions for XTaTIK

=head1 NOTE ON OPERATING SYSTEM

All instructions below are for Debian 8.1 (Jessie) Linux.
If you'd like to provide installation instructions for other operating
systems, please submit a
L<pull request|https://github.com/XTaTIK/XTaTIK/pulls>.

=head1 NOTE ON PERL VERSION

XTaTIK supports the current and previous major releases of Perl.
You can use L<Perlbrew|http://perlbrew.pl/> to obtain the latest
versions of Perl, if you're currently lacking one.

=head1 SOFTWARE NOT FOUND ON CPAN

Some of the software required to run XTaTIK or to compile one of the modules
it uses is not available on CPAN.

=head2 PostgreSQL and Development C Libraries

You need to install PostgreSQL database, development files for it
(needed by L<Mojo::Pg>), and development files for C<libdb>
(needed by L<Search::Indexer>).

I<Note: choose the appropriate version for the C<postgresql-server-dev-9.4>
package (run C<aptitude search postgresql-server>)>.

    sudo apt-get install libdb-dev postgresql postgresql-server-dev-9.4;

=head2 GEOIP DATABASE

Currently, XTaTIK only supports the Free version of
L<IP2Location.com|https://www.ip2location.com/>'s database.
Paid-for version will likely work just fine, but it has never been
tested yet.

You will need to create a B<free> account to download the
B<free> database files.
Download IPv4 B<DB3.LITE> C<.bin> file (or just B<DB3>, if you're using
a paid-for version) of the
L<Lite database|http://lite.ip2location.com/databases>.

Create a folder somewhere nice and safe. It will be your B<Company Silo>.
A place to put global config and product pics for all your sites.
Save the IP2Locations in that folder.

=head1 XTaTIK CORE

Simply install package L<XTaTIK> from CPAN. Using L<cpanm>, it's as
simple as:

    cpanm XTaTIK

=head1 WHAT'S NEXT?

Next, you should set up your I<Company Silo>. You already saved your
IP2Location file into it.

You don't really need a I<Company Silo>, if you're going to run just
a single eCommerce site. If that is the case, simply assume all
I<Company Silo> instructions refer to your I<Site Silo>—that is,
a directory with all of our site's files.

See L<XTaTIK::Docs::02_PreparingCompanySilo> next.

=cut