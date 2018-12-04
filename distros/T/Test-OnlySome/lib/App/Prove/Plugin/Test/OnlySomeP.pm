#!perl
package App::Prove::Plugin::Test::OnlySomeP;
use 5.012;
use strict;
use warnings;
use Carp qw(croak);
use Test::OnlySome::PathCapsule;
#use Data::Dumper;

our $VERSION = '0.000007';
use constant DEFAULT_FILENAME => '.onlysome.yml';

our $Filename;  # The output filename to use, where the formatter can read it.

# TODO someday: find a cleaner way to pass the filename to the formatter.  I am
# not instantiating the formatter here because I don't want to remove
# prove(1)'s control of the formatter options.

# Docs {{{3

=head1 NAME

App::Prove::Plugin::Test::OnlySomeP - prove plugin supporting Test::OnlySome

=head1 INSTALLATION

See L<Test::OnlySome>, with which this module is distributed.

=head1 SYNOPSIS

    prove -PTest::OnlySomeP

This will save the test results in a form usable by Test::OnlySome::*.

=cut

# }}}3
# Caller-facing routines {{{1

=head1 EXPORTS

=head2 load

The entry point for the plugin.

=cut

sub load {
    my ($class, $prove) = @_;
    my %args = @{ $prove->{args} };
    print STDERR '# ', __PACKAGE__, " $VERSION loading\n";    # " with args ", Dumper(\%args), "\n";

    $Filename = Test::OnlySome::PathCapsule->new(
        $args{filename} // DEFAULT_FILENAME
    )->abs();
    #print STDERR "Output filename is $Filename\n";
    $prove->{app_prove}->formatter('App::Prove::Plugin::Test::OnlySomeP::Formatter');
} #load()

# }}}1
# More docs {{{3
=head1 AUTHOR

Christopher White, C<< <cxwembedded at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests on GitHub, at
L<https://github.com/cxw42/Test-OnlySome/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::OnlySome

You can also look for information at:

=over 4

=item * The GitHub repository

L<https://github.com/cxw42/Test-OnlySome>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-OnlySome>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Test-OnlySome>

=item * Search CPAN

L<https://metacpan.org/release/Test-OnlySome>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-OnlySome>

=back

=cut

# }}}3
# License {{{3

=head1 ACKNOWLEDGEMENTS

Thanks to sugyan for L<App::Prove::Plugin::Growl>, which provided inspiration.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Christopher White.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

# }}}3
1;
# vi: set fdm=marker fdl=2: #
