package Text::ANSI::Highlight::Block::embedz;

use v5.16;
use warnings;
use utf8;

# The parts of a block of pandoc-embedz, each with its language:
#
#     ---
#     YAML
#     ---
#     template of Jinja2
#     ---
#     data
#
# A block without the line of --- at the top is one part, and what it
# is depends on the attributes of the fence.

# the formats of the data which are the names of a language.  CSV is
# not here: its colors, one for each column, mean nothing in the data
my %FORMAT = map { $_ => $_ } qw(json yaml toml);

sub parts {
    my($info, $text) = @_;
    $text ne '' or return ();
    my %attr = map { $_ => 1 } $info =~ /(?<![\w.])([\w.-]+)=/g;
    my $format = $info =~ /(?<![\w.])format=["']?(\w+)/ ? $1 : undef;
    my $as = $attr{as} || $attr{template};

    if ($text !~ /\A---/) {
        return [ jinja => $text, 'template' ] if $attr{define};
        return [ yaml  => $text, 'config' ] if $as and $attr{data};
        return [ _data($format) => $text, 'data' ] if $as;
        return [ jinja => $text, 'template' ];
    }

    # the lines of --- and the sections between them: the third and
    # the following are in the data
    my @line = split /^/, $text;
    my @part = ([ undef, shift @line ]);
    my @section = ('');
    while (defined(my $line = shift @line)) {
        if (@section < 5 and $line =~ /\A\h*---\h*$/) {
            push @section, $line, '';
        } else {
            $section[-1] .= $line;
        }
    }
    my($yaml, $sep1, $template, $sep2, $data) = @section;
    $format //= $1 if $yaml =~ /^format:\h*["']?(\w+)/m;
    $as ||= $yaml =~ /^(?:as|template):/m;
    # the section after YAML is the data when a template is used
    my @middle = ($as and not defined $sep2)
        ? (_data($format), 'data') : ('jinja', 'template');
    push @part,
        [ yaml => $yaml, 'config' ],
        defined $sep1 ? ([ undef, $sep1 ], [ $middle[0], $template, $middle[1] ]) : (),
        defined $sep2 ? ([ undef, $sep2 ], [ _data($format), $data, 'data' ]) : ();
    grep { $_->[1] ne '' } @part;
}

sub _data {
    my $format = shift // return undef;
    $FORMAT{lc $format};
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Highlight::Block::embedz - the parts of a block of pandoc-embedz

=head1 DESCRIPTION

Tells L<Text::ANSI::Highlight> the parts of a code block of
L<pandoc-embedz|https://github.com/tecolicom/pandoc-embedz> in a
Markdown text, C<```embedz> or C<```{.embedz ...}>.

    ```embedz
    ---
    data: file.csv
    ---
    {% for row in data %}
    - {{ row.name }}
    {% endfor %}
    ---
    name,value
    ```

    PART                         LANGUAGE   LABEL
    configuration                yaml       config
    template                     jinja      template
    data                         its format data
    lines of ---                 none       none

The language of the data is that of C<format> in the attributes or in
the configuration, when it is C<json>, C<yaml> or C<toml>.  The data of
the other formats, as C<csv>, has no language, and is not colored.

A block which does not begin with a line of C<---> is one part, as
pandoc-embedz reads it: a template with C<define>, a configuration
with C<data> and C<as> (or C<template>), the data with C<as> alone,
and a template without them.

=head1 FUNCTIONS

=over 4

=item B<parts>(I<info>, I<text>)

Returns the parts as a list of C<[ I<language>, I<text>, I<label> ]>.
See L<Text::ANSI::Highlight/"BLOCK MODULES">.

=back

=head1 SEE ALSO

L<Text::ANSI::Highlight>

L<https://github.com/tecolicom/pandoc-embedz>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
