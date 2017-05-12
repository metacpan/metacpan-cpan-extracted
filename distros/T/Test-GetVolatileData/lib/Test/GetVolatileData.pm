package Test::GetVolatileData;

use 5.006;
use strict;
use warnings FATAL => 'all';

use LWP::UserAgent;
use Carp qw/croak/;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_data);

our $VERSION = '1.0102';

our $ERROR;

sub get_data {
    undef $ERROR;

    my $url = shift;
    my %args = @_;

    $args{num} = 1 unless exists $args{num};
    $args{num} =~ /\A\d+\z/
        or croak q{'num' argument can take only positive integers};

    my $res = LWP::UserAgent->new(
        agent   => 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:26.0) '
            . 'Gecko/20100101 Firefox/26.0',
        timeout => 30,
    )->get( $url );

    unless ( $res->is_success ) {
        $ERROR = 'Network error: ' . $res->status_line;
        return;
    }

    my $c = $res->decoded_content;
    my @data = split /\n/, defined($c) ? $c : '';
    @data or do { $ERROR = 'Got empty data'; return };
    my @return;
    for ( 1.. $args{num} ) {
        @data or last;
        push @return, splice @data, int(rand @data), 1;
    }

    return @return > 1 ? @return : $return[0];
}


q|
Knock knock.

Race condition.

Who's there?
|;

__END__

=head1 NAME

Test::GetVolatileData - load frequently-changed data in your tests without uploading new distros

=head1 SYNOPSIS

    use 5.006;
    use strict;
    use warnings FATAL => 'all';
    use Test::More;
    use Test::GetVolatileData;
    plan tests => 2;

    ### That .txt file contains data, like:
    ### apikey1foobarbaz
    ### apikey2fooberbeer
    ### etc.

    SKIP: {
        # get a single data line; randomly chosen
        my $key = get_data('http://zoffix.com/CPAN/Test-GetVolatileData.txt')
            or skip "Failed to fetch API key; error is: $Test::GetVolatileData::ERROR", 2;

        like($test, qr/apikey\d/, 'got volatile API key');

        my $module = My::Module::New->( apikey => $key );
        ok( $module->get_stuff, 'Got stuff!' );
    }

    # get three data lines; randomly chosen
    my @moar_keys = get_data('http://zoffix.com/CPAN/Test-GetVolatileData.txt',
        num => 3,
    );

    unless ( @moar_keys ) {
        diag "Error getting fresh keys: $Test::GetVolatileData::ERROR";
        diag "Falling back on old ones";
        @keys = qw/The Old Keys/;
    }

    ... # do the rest of testing with @moar_keys data here

=head1 DESCRIPTION

A tiny wrapper module to load up random volatile data into your tests;
like API keys, tracking numbers, whatever.
For example, you wrote a module for a delivery package tracker. It would
be nice to privide a fresh supply of tracking numbers for your tests,
but that means uploading a new distro every so often.

With this module, you can store, and update, those tracking
numbers on an online page, and have your tests access it.

=head1 EXPORTS

Exports C<get_data> by default:

=head2 C<get_data>

    # get a random key
    my $key = get_data('http://zoffix.com/CPAN/Test-GetVolatileData.txt')
        or skip 'Error getting keys: ' . $Test::GetVolatileData::ERROR, 42;

    # get at most 42 random keys
    my @keys = get_data(
        'http://zoffix.com/CPAN/Test-GetVolatileData.txt',
        num => 42,
    );

    unless ( @keys ) {
        diag "Error getting keys: $Test::GetVolatileData::ERROR";
        diag "Falling back on old keys";
        @keys = qw/Old Keys That Came With The Distro/;
    }

B<Takes> a B<mandatory> URL to the data document and any number of
B<optional> arguments in a key/value format. The referenced document
must have each entry separated by a new line (take a look at
L<this example|http://zoffix.com/CPAN/WWW-Purolator-TrackingInfo.txt>
and L<this one|http://zoffix.com/CPAN/Test-GetVolatileData.txt>.
If the referenced
document contains several such lines, the line to be returned will be
selected randomly.

B<On failure> returns C<undef> or an empty list, depending
on the context, and the human-readable reason for failure will be
present in the C<$Test::GetVolatileData::ERROR> variable.

Possible optional arguments are as follows:

=head3 C<num>

    # get at most 42 random keys
    my @keys = get_data(
        'http://zoffix.com/CPAN/Test-GetVolatileData.txt',
        num => 42,
    );

B<Takes> a positive interger as a value.
Tells C<get_data()> to get more than one line, and
the value specifies the maximum number of results to return. If the
data document has fewer than C<num> entries, then all the
available entries will be B<returned> as a list. Otherwise,
a C<num> number of randomly-selected entries will be returned.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-getvolatiledata at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-GetVolatileData>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::GetVolatileData

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-GetVolatileData>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-GetVolatileData>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-GetVolatileData>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-GetVolatileData/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Zoffix Znet.

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
