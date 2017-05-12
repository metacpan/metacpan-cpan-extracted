# Copyright (c) 2014, 2015 Yon <anaseto@bardinflor.perso.aquilenet.fr>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# vim:sw=4:sts=4:expandtab

package Text::Frundis;

# as in the perlunicook
use utf8;
use v5.12;
use strict;
use warnings;
use open qw(:std :utf8);

use Text::Frundis::Processing;
use Carp;

our $VERSION = "2.16";

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
}

sub process_source {
    my ($self, %opts) = @_;

    $opts{use_carp} //= 1;
    croak("`target_format' parameter required")
      unless defined $opts{target_format}
      or $opts{script};
    carp(
        "`all_in_one_file' parameter doesn't make sense when exporting to epub")
      unless $opts{script}
      or not($opts{all_in_one_file} and $opts{target_format} eq "epub");
    if (    not $opts{script}
        and $opts{target_format} eq "epub"
        and not defined $opts{output_file})
    {
        croak "when exporting to epub the ``output_file'' parameter is mandatory";
    }
    if (    not $opts{script}
        and $opts{target_format} eq "xhtml"
        and not $opts{all_in_one_file}
        and not defined $opts{output_file})
    {
        croak "when exporting to xhtml, unless ``all_in_one_file'' is specified, "
          . "``output_file'' is mandatory";
    }

    my $macros = $self->{macros};
    if (defined $macros) {
        foreach my $macro (keys %$macros) {
            $opts{user_macros}{$macro} = {
                perl => 1,
                lnum => 0,
                code => $macros->{$macro},
            };
        }
    }
    my $filters = $self->{filters};
    if (defined $filters) {
        foreach my $filter (keys %$filters) {
            $opts{filters}{$filter} = {
                code => $filters->{$filter},
            };
        }
    }

    Text::Frundis::Processing::process_frundis_source(\%opts);
}

sub add_macro {
    my ($self, $macro, $code) = @_;

    unless (defined $macro and $macro ne "") {
        carp "undefined macro name";
        return;
    }
    if ($macro =~ /\s/) {
        carp "macro name should not contain spaces";
        return;
    }
    unless (defined $code and ref($code) eq "CODE") {
        carp "a coderef is required";
        return;
    }

    $self->{macros}{$macro} = $code;
}

sub add_filter {
    my ($self, $tag, $code) = @_;

    unless (defined $tag and $tag ne "") {
        carp "undefined tag name";
        return;
    }
    unless (defined $code and ref($code) eq "CODE") {
        carp "a coderef is required";
        return;
    }

    $self->{filters}{$tag} = $code;
}

1;

__END__

=pod

=head1 NAME

Text::Frundis - object interface for the frundis markup language

=head1 SYNOPSIS

    my $frundis = Text::Frundis->new;
    
    # file written in the frundis language 
    my $file = "somefile.frundis";

    # produce a directory named "htmldir" of indexed html files
    $frundis->process_source(
        input_file    => $file,
        target_format => 'xhtml',
        output_file   => 'htmldir',
    );

    # produce a file with an html fragment
    $frundis->process_source(
        input_file      => $file,
        target_format   => 'xhtml',
        all_in_one_file => 1,
        output_file     => 'fragment.html',
    );

    # produce a complete html file
    $frundis->process_source(
        input_file      => $file,
        target_format   => 'xhtml',
        all_in_one_file => 1,
        standalone      => 1,
        output_file     => 'document.html',
    );

    # produce a complete LaTeX file
    $frundis->process_source(
        input_file    => $file,
        target_format => 'latex',
        standalone    => 1,
        output_file   => 'document.tex',
    );

    # produce a directory "epubdir" ready to be zipped into an epub
    $frundis->process_source(
        input_file    => $file,
        target_format => 'epub',
        output_file   => 'epubdir',
    );

    # add an user defined macro
    $frundis->add_macro(
        'some-name' => sub {
            my $self = shift;
            # some code...
        }
    );

=head1 DESCRIPTION

C<frundis> intends to be a semantic markup language with a roff-like syntax for
supporting authoring of a variety of light to medium weight documents, from
novels to technical tutorials.

The documentation of the C<frundis> tool and C<frundis> language are maintained
as the mdoc manual pages frundis(1) and frundis_syntax(5), respectively. This
man page describes the module interface.

C<Text::Frundis> provides the following methods:

=over

=item process_source(%opts)

This function processes frundis source from an UTF-8 encoded file, a decoded
string, or reads from standard input. The %opts hash accepts the following keys:

=over

=item input_file

The name of an input file.

=item input_string

The name of a decoded string.

=item target_format

The format to produce. Can be C<xhtml>, C<epub> or C<latex>.

=item standalone

Produce a complete document. It is implied by C<epub> target format, and
C<xhtml> target format unless C<all_in_one_file> is specified.

=item all_in_one_file

Boolean flag that, in case of exporting to C<xhtml>, specifies that output
should be a single file.

=item output_file

The name of an output file or directory. A directory when exporting to C<epub>
or C<xhtml> (unless C<all_in_one_file> is specified for the last one).

=back

=item add_macro($macro_name, $code)

Add an user defined macro for a posterior C<process_source> invocation, with
name $macro_name and code $code, where $code is a coderef that takes an object
as first argument, that accepts methods described in frundis_syntax(5).  Works
as a C<de -perl> in frundis source, except that @Arg isn't exported by
C<Text::Frundis>.

=item add_filter($tag_name, $code)

Add an user defined filter for a posterior C<process_source> invocation, with
tag $tag_name and code $code, where $code is a coderef that takes an object as
first argument, that accepts methods described in frundis_syntax(5). Works as a
C<X ftag -code> in frundis source, except that @Arg isn't exported by
C<Text::Frundis>.

=back

=head1 SEE ALSO

frundis(1), frundis_syntax(5).

L<http://bardinflor.perso.aquilenet.fr/frundis/intro-en> (homepage of the project)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, 2015 Yon E<lt>anaseto@bardinflor.perso.aquilenet.frE<gt>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut
