#!perl
package App::Prove::Plugin::Test::OnlySomeP::Formatter;
use 5.012;
use strict;
use warnings;

use parent 'TAP::Formatter::Console';   # TODO make the parent a parameter

use Best [ [qw(YAML::XS YAML)], qw(DumpFile) ];

#use Data::Dumper;

our $VERSION = '0.001003';

# Docs {{{2

=head1 NAME

App::Prove::Plugin::Test::OnlySomeP::Formatter - formatter supporting Test::OnlySome

=head1 INSTALLATION

See L<Test::OnlySome>, with which this module is distributed.

=head1 EXPORTS

=head2 summary

Called after the tests run.  Outputs the test results to a YAML file.

=cut

# }}}2

#sub _initialize {  # DEBUG
#    my $self = shift;
#    print STDERR "Formatter got args: ", Dumper([@_]), "\n";
#    return $self->SUPER::_initialize(@_);
#} #_initialize()

sub summary {
    my $self = shift;
    my ($aggregate, $interrupted) = @_;
    my %results;

    $self->SUPER::summary(@_);

    # Collect the results.  Can't use $parser->next, since App::Prove has
    # already iterated over the results.

    while( my ($fn, $parser) = each %{$aggregate->{parser_for}} ) {
        # Save the results for this test file
        $results{$fn} = {};
        $results{$fn}->{$_} = _ary($parser->$_)
            for qw(passed failed skipped actual_passed actual_failed todo todo_passed);
    } #foreach result file

    # Save the output
    DumpFile $App::Prove::Plugin::Test::OnlySomeP::Filename, \%results;
        # The plugin guarantees this exists.
} #summary()

# Wrap the arg(s) in an arrayref unless the first arg already is one.
sub _ary {
    return $_[0] if ref $_[0] eq 'ARRAY';
    return [@_];
}

# More docs {{{2
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

# }}}2
# License {{{2

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

# }}}2
1;
# vi: set fdm=marker fdl=1 fo-=ro: #
