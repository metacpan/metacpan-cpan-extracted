package XML::GrammarBase::Role::DataDir;

use strict;
use warnings;


=head1 NAME

XML::GrammarBase::Role::DataDir - provide the data_dir accessor.

=head1 VERSION

Version 0.2.3

=cut

use MooX::Role 'late';

use File::ShareDir qw(dist_dir);

our $VERSION = '0.2.3';

my $_component_re = qr/[A-Za-z_]\w*/;

has 'module_base' => (isa => sub {
        my ($dist_name) = @_;
        if (not (
                (ref($dist_name) eq '')
                &&
                ($dist_name =~ m/\A$_component_re(?:-$_component_re)*\z/)
            )
        )
        {
            die "module_base must be a distribution string of components separated by dashes";
        }
    },
    , is => 'rw');
has 'data_dir' => (isa => 'Str', is => 'rw',
    default => sub { return shift->_calc_default_data_dir(); },
    lazy => 1,
);

sub _calc_default_data_dir
{
    my ($self) = @_;

    return dist_dir( $self->module_base() );
}

sub _undefize
{
    my $class = shift;
    my $v = shift;

    return defined($v) ? $v : "(undef)";
}

sub dist_path
{
    my ($self, $basename) = @_;

    return File::Spec->catfile($self->data_dir, $basename);
}

sub dist_path_slot
{
    my ($self, $slot) = @_;

    return $self->dist_path($self->$slot());
}

=head1 SYNOPSIS

    package MyClass::WithDataDir;

    use MooX 'late';

    with ('XML::GrammarBase::Role::DataDir');

    has '+module_base' => (default => 'XML-Grammar-MyGrammar');

    package main;

    my $obj = MyClass::WithDataDir->new(
        data_dir => "/path/to/data-dir",
    );

=head1 SLOTS

=head2 module_base

The basename of the distribution - used for dist dir.

=head2 data_dir

The data directory where the XML assets can be found (the RELAX NG schema, etc.)

=head1 METHODS

=head2 $self->dist_path($basename)

Returns the $basename relative to data_dir().

Utility method.

=head2 $self->dist_path_slot($slot)

Returns the basename of $self->$slot() relative to data_dir().

Utility method.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammarbase at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-GrammarBase>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::GrammarBase

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-GrammarBase>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-GrammarBase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-GrammarBase>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-GrammarBase/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Shlomi Fish.

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

1; # End of XML::GrammarBase::RelaxNG::Validate

