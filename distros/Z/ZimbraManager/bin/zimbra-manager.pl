#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../thirdparty/lib/perl5";
use lib "$FindBin::Bin/../lib";

use Getopt::Long qw(:config posix_default no_ignore_case);
use Pod::Usage;

my $VERSION = "0.15";

my %opt;

# Call GetOptions in BEGIN block as Mojo::Commands eats --help command line option
BEGIN {
    GetOptions(\%opt, 'help|h', 'man', 'logfile=s', 'loglevel=s') or exit(1);
};

use Mojolicious::Commands;
use ZimbraManager;

if($opt{help})     { pod2usage(1); exit; }
if($opt{man})      { pod2usage(-exitstatus => 0, -verbose => 2); exit; }

if (defined $opt{loglevel}) {
    $ENV{MOJO_LOG_LEVEL} = $opt{loglevel};
}
if (defined $opt{logfile}) {
    $ENV{MOJO_LOG_FILE}  = $opt{logfile};
}

# disable SSL certificate checks
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
$ENV{'PERL_LWP_SSL_VERIFY_MODE'}     = SSL_VERIFY_NONE;

# Start commands
Mojolicious::Commands->start_app('ZimbraManager');

__END__

=pod

=head1 NAME

zimbra-manager.pl - A Zimbra managing tool written in perl / soap

=head1 SYNOPSIS

B<zimbra-manager.pl> [I<options>...]

     --man          show man-page and exit
     --help         display mojo applicaiton help and exit
     --logfile      Path to logfile
     --loglevel     Mojo Loglevel (info, warn, error, debug, ...)

=head1 DESCRIPTION

zimbra-manager.pl is a Zimbra SOAP / REST Interface service written
in Mojolicious.

This script will disable the SSL checkings in HTTPS communication, 
so change that if you will be sure to have trusted connections.

=head2 Usage


    $ ./bin/zimbra-manager.pl prefork

or

    $ ./bin/zimbra-manager.pl daemon

=head1 SEE ALSO

L<ZimbraManager::SOAP> L<ZimbraManager::SOAP::Friendly>

=head1 COPYRIGHT

Copyright (c) 2014 by Roman Plessl. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Roman Plessl E<lt>roman@plessl.infoE<gt>>

=head1 HISTORY

 2014-03-19 rp Initial Version

=cut
