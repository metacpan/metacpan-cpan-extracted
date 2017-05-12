package XML::Writer::Simpler;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

XML::Writer::Simpler - Perl extension for writing XML data

=head1 SYNOPSIS


=head1 DESCRIPTION

This is a convenience module for writing XML. It's a subclass of
C<XML::Writer>, with a single convenience method so you usually won't have
to deal with remembering to call C<startTag()>, C<endTag()>, and
C<emptyTag()>.

This module is lies somewhere in between L<XML::Generator|XML::Generator> and
L<XML::Writer::Nest>. It nests calls like XML::Generator, but allows for
arbitrary subroutine calls as well. It requires fewer braces in general than
XML::Writer::Nest.

This module is a subclass of XML::Writer, so if you can't do what you want to
with the C<tag> method, you can fall back to the methods native to XML::Writer.

=cut

use base qw/Exporter XML::Writer/;
use vars qw/@EXPORT_OK $VERSION/;

use Carp;


$VERSION = '0.11';
# package vars for ref to output file
my $out;

=head1 METHODS

=over 4

=item * C<new>

    XML::Writer::Simpler->new(%params);

Creates the object. Acceptable hash keys for %params are the same as those
for L<XML::Writer>. This module assumes everything is UTF-8, so you can
omit that if you like; it will be provided for you.

=cut

sub new {
    my ($class, %params) = @_;
    $params{ENCODING} ||= 'utf-8';

    my $self = $class->SUPER::new(%params);
    $out = &{$self->{GETOUTPUT}};
    $self->xmlDecl('UTF-8') if $params{ENCODING} eq 'utf-8';
    bless $self, $class;
    return $self;
}

=item * tag

    $xml->tag($tagName, [ \@attributes ], $content);

If C<$content> is a plain scalar value, will output the tag with that content.
If no content is provided, will output an empty tag:

    $xml->tag('example', 'foo');    # <example>foo</example>
    $xml->tag('example');           # <example />

You may also pass an array ref of key/value pairs that wind up as attributes:

    # <example bar="baz">foo</example>
    $xml->tag('example', [bar => 'baz'], 'foo');

    # <example bar="baz" />
    $xml->tag('example', [bar => 'baz']);

If C<$content> is a code ref, this will start the tag, execute the code ref,
then close the tag. This allows arbitrarily deep/complex tag structures.

    # <example1><exA>Text 1</exA><exB>Text 2</exB></example1>
    $xml->tag('example1', sub {
        $xml->tag('exA', 'Text 1');
        $xml->tag('exB', 'Text 2');
    });

    # <example2><a>100</a><b>101</b><c>102</c></example2>
    $xml->('example2', sub {
        for (my $tag = 'a', my $num = 100; $num < 103; $tag++, $num++) {
            $xml->($tag, $num);
        }
    });

These different styles of calling can be combined in a number of ways to
output basically whatever you like.


    # <example3 id='ex3'>text z</example3>
    $xml->tag('example3', [id => 'ex3'], 'text z');

    # <example4 id="ex4"><exZ>more text</exZ></example4>
    $xml->tag('example4', [id => 'ex4'], sub {
        $xml->tag('exZ', 'more text');
    });


=cut

sub tag {
    my $self = shift;
    my $tagName = shift;    # name of tag, required
    my $content = pop;      # might be text or a coderef
    my $aref = shift;       # attribute arrayref

    croak unless $tagName;

    my @attrs;
    # if we just have a tag name and an array ref, then the thing we popped
    # off of @_ might actually be the attribute array ref
    if (ref $content eq 'ARRAY') {
        $aref = $content;
        undef($content);
    }
    @attrs = @$aref if ref $aref eq 'ARRAY';

    if (ref $content eq 'CODE') {
        $self->startTag($tagName, @attrs);
        $content->();
        $self->endTag($tagName);
    } else {
        if ($content) {
            $self->dataElement($tagName, $content, @attrs);
        } else {
            $self->emptyTag($tagName, @attrs);
        }
    }
    return;
}


1;

__END__

=back

=head1 SEE ALSO

L<XML::Writer>

=head1 AUTHOR

Michael McClimon, C<< <michael at mcclimon.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-writer-simple at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Writer-Simpler>. I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes. See also the Github repository at
L<http://github.com/mmcclimon/XML-Writer-Simpler>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Writer::Simpler

You can also look for information at:

=over 4

=item * Github

L<http://github.com/mmcclimon/XML-Writer-Simpler>.

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Writer-Simpler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Writer-Simpler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Writer-Simpler>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Writer-Simpler/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Michael McClimon.

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

