package Test::Internet;

$Test::Internet::VERSION   = '0.06';
$Test::Internet::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Test::Internet - Interface to test internet connection.

=head1 VERSION

Version 0.06

=cut

use strict; use warnings;

use 5.006;
use Socket;
use Net::DNS;
use Data::Dumper;
use Test::Builder ();

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(connect_ok);

our $DEFAULT_TIMEOUT = 2;
our $STD_NAMESERVERS = [ 'a.root-servers.net',
                         'b.root-servers.net',
                         'c.root-servers.net',
                         'd.root-servers.net',
                         'e.root-servers.net',
                         'f.root-servers.net',
                         'g.root-servers.net',
                         'h.root-servers.net',
                         'i.root-servers.net',
                         'j.root-servers.net' ];

=head1 DESCRIPTION

It provides a simple interface to test the internet connection reliably. I needed
this feature in the test script for one of my package L<WWW::Google::Places>. The
code can be found L<here|https://raw.githubusercontent.com/Manwar/WWW-Google-Places/master/t/05-paging.t>.

=head1 METHODS

=head2 connect_ok($timeout)

Return true/false depending on whether there is an active internet connection.The
default  timeout  is  2 seconds  unless the user pass the timeout period. It gets
exported by default.

    use strict; use warnings;
    use Test::More;
    use Test::Internet;

    plan skip_all => "No internet connection." unless connect_ok();
    ok(connect_ok());
    done_testing();

=cut

sub connect_ok {
    my ($timeout) = @_;

    my @nameservers = ();
    foreach (@$STD_NAMESERVERS) {
        inet_aton($_) && (push @nameservers, $_);
    }

    return 0 unless (scalar(@nameservers));

    $timeout = $DEFAULT_TIMEOUT unless defined $timeout;
    my $resolver = Net::DNS::Resolver->new;
    $resolver->tcp_timeout($timeout);
    $resolver->udp_timeout($timeout);
    $resolver->nameservers(@nameservers);

    my $response = $resolver->query("root-servers.net", "NS");
    if (defined $response) {
        return 1 if (grep { $_->type eq 'NS' } $response->answer);
    }

    return 0;
}

=head1 Why L<Test::Internet>?

Karen Etheridge raised this question as in RT# 102095 and introduced me to a very
similar module L<Test::RequiresInternet> on CPAN.What a shame that it didn't turn
up in a search on CPAN, while I was looking for any module with the word Internet.
I am not an expert on how the CPAN search engine works, though. Had I known about
it, I wouldn't have bothered creating L<Test::Internet> to be honest.

The nice thing about the L<Test::RequiresInternet> is  that  it does not need any
external module and just uses what is available in core perl i.e. Socket. However
it relies on a webservice to exist and respond, so if that webservice is down the
module will give a false negative.

So if the  requirement is to check if there is an active internet connection only
then  I  would  recommend L<Test::Internet>. In case you want to check if you can
reach a particular given host as well then go for L<Test::RequiresInternet>.

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Test-Internet>

=head1 ACKNOWLEDGEMENT

David Kitcher-Jones (m4ddav3) for his immensely valuable inputs.

=head1 SEE ALSO

L<Test::RequiresInternet>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-internet at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Internet>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Internet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Internet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Internet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Internet>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Internet/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2016 Mohammad S Anwar.

This  program  is  free software;  you can redistribute it and/or modify it under
the  terms  of the the Artistic  License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Test::Internet
