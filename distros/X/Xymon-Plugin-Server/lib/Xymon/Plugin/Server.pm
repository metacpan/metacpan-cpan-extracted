package Xymon::Plugin::Server;

use strict;
use warnings FATAL => 'all';

use Carp;

=head1 NAME

Xymon::Plugin::Server - Xymon Server side plugin helper

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 DESCRIPTION

Xymon::Plugin::Server package contains some useful modules to write
Xymon plugin executed in server side.

=over

=item  Xymon::Plugin::Server::Status

Status reporter

=item  Xymon::Plugin::Server::Devmon

Data generator in devmon style

=item  Xymon::Plugin::Server::Dispatch

Dispatcher

=back

Check example directory to see how to each modules.


=head1 SUBROUTINES/METHODS

=head2 home

Get Xymon/Hobbit home directory.
This is a class method. call like this:

    my $home = Xymon::Plugin::Server->home;

=cut

sub home {
    return $ENV{XYMONHOME} if (defined($ENV{XYMONHOME})); # xymn 4.3
    return $ENV{BBHOME} if (defined($ENV{BBHOME}));	  # xymn 4.2

    if (defined($ENV{HOME})) {
	my $xyhome = "$ENV{HOME}/server";

	return $xyhome if (-f "$xyhome/etc/hosts.cfg");	# xymon 4.3
	return $xyhome if (-f "$xyhome/etc/bb-hosts");	# xymon 4.2
    }

    croak "environment variable BBHOME/XYMONHOME is not set.";
}

=head2 version

Guess Xymon version and returns resulst as ARRAYREF like [major, minor].

This is a class method. call like this:

    my $ver = Xymon::Plugin::Server->version;

=cut

sub version {
    my $xyhome = __PACKAGE__->home;

    return [4, 3] if (-f "$xyhome/etc/hosts.cfg");	# xymon 4.3

    return [4, 2];
}

=head2 display_hosts

Guess display hosts and returns ARRAY.

This is a class method. call like this:

    my @hosts = Xymon::Plugin::Server->display_hosts;

=cut

sub display_hosts {
    my $display = $ENV{'BBDISP'} || '127.0.0.1';

    return $display if ($display ne '0.0.0.0');

    my $multi_display = $ENV{'BBDISPLAYS'};
    if (defined($multi_display)) {
	return split(/\s+/, $multi_display);
    }

    return $display;
}

=head1 AUTHOR

Toshimitsu FUJIWARA, C<< <tttfjw at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xymon-plugin-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Xymon-Plugin-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Xymon::Plugin::Server


You can also look for information at:

=over 4

=item * About Xymon

L<http://xymon.sourceforge.net/>

=item * About RRDTool

L<http://oss.oetiker.ch/rrdtool/>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Xymon-Plugin-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Xymon-Plugin-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Xymon-Plugin-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Xymon-Plugin-Server/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Toshimitsu FUJIWARA.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Xymon::Plugin::Server
