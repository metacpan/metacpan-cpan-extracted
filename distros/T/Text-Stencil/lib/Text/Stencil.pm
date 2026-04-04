package Text::Stencil;
use v5.20;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub from_file {
    my ($class, $file, %opts) = @_;
    open my $fh, '<:utf8', $file or die "Text::Stencil: can't open $file: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    if ($content =~ /^__HEADER__\s*\n(.*?)^__ROW__\s*\n(.*?)^__FOOTER__\s*\n(.*)/ms) {
        $class->new(%opts, header => $1, row => $2, footer => $3);
    } else {
        $class->new(%opts, row => $content);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Stencil - fast XS list/table renderer with escaping, formatting, and transform chaining

=head1 SYNOPSIS

    use Text::Stencil;

    my $s = Text::Stencil->new(
        header => '<table><tr><th>id</th><th>name</th></tr>',
        row    => '<tr><td>{0:int}</td><td>{1:html}</td></tr>',
        footer => '</table>',
    );
    my $html = $s->render(\@rows);

    # hashrefs, chaining, separator
    my $s = Text::Stencil->new(
        header => '<ul>',
        row    => '<li>{title:default:Untitled|trim|trunc:80|html}</li>',
        footer => '</ul>',
        separator => "\n",
    );

    # single row, stream to file
    print $s->render_one({id => 1, title => 'Hello'});
    $s->render_to_fh($fh, \@rows);

=head1 DESCRIPTION

Renders lists of uniform data (arrayrefs or hashrefs) into text output
using a pre-compiled row template. The template is parsed once at
construction; rendering is a tight C loop with direct buffer writes
and zero Perl interpretation overhead.

2-3x faster than L<Text::Xslate> for table/list rendering.

The template is parsed once; rendering is a tight C loop. Not safe
for concurrent renders from multiple threads (see THREAD SAFETY).

=head1 CONSTRUCTOR

=head2 new

    my $s = Text::Stencil->new(%opts);

Options:

=over 4

=item C<header> - string prepended before all rows (default: empty)

=item C<row> - row template with C<{field:type}> placeholders (required)

=item C<footer> - string appended after all rows (default: empty)

=item C<separator> - string inserted between rows (default: none)

=item C<escape_char> - delimiter character instead of C<{> (default: C<{>).
Paired closing: C<[> E<rarr> C<]>, C<(> E<rarr> C<)>, C<< < >> E<rarr> C<< > >>,
others use the same char for open and close. Useful for JSON templates
where literal braces are needed.

=item C<skip_if> - column index or field name. Rows where this field is
truthy (non-empty, not C<"0">, not undef) are skipped.

=item C<skip_unless> - column index or field name. Rows where this field
is B<not> truthy are skipped.

=back

=head2 from_file

    my $s = Text::Stencil->from_file('template.tpl', separator => "\n");

Load template from a file. The file can use section markers:

    __HEADER__
    <table>
    __ROW__
    <tr><td>{0:html}</td></tr>
    __FOOTER__
    </table>

Without markers, the entire file content is used as the row template.

=head2 clone

    my $s2 = $s->clone(row => '{0:uc}');

Create a new renderer reusing the original's header/footer.

=head1 METHODS

=head2 render

    my $output = $s->render(\@rows);

Render all rows. Returns a UTF-8 string.

=head2 render_one

    my $output = $s->render_one(\@row);
    my $output = $s->render_one(\%row);

Render a single row without wrapping in an arrayref.

=head2 render_sorted

    my $output = $s->render_sorted(\@rows, $sort_by);
    my $output = $s->render_sorted(\@rows, $sort_by, {descending => 1, numeric => 1});

Render rows sorted by a field. C<$sort_by> is a column index for
arrayref rows or a field name for hashref rows. A leading C<-> on the
field name sorts descending: C<'-score'>. It can also be an arrayref
for multi-column sort: C<[0, 1]> or C<['name', 'age']>. Sorts
lexically ascending by default. Optional third argument is a hashref:
C<descending> reverses order, C<numeric> compares numerically.

=head2 render_to_fh

    $s->render_to_fh($fh, \@rows);

Render directly to a filehandle, flushing in 64KB chunks.

=head2 render_cb

    my $output = $s->render_cb(sub { return \@row_or_undef });
    $s->render_cb(sub { return \@row_or_undef }, $fh);

Callback-based rendering. The callback is called repeatedly and should
return an arrayref or hashref (one row) or undef to stop. If a
filehandle is given, output is streamed to it; otherwise returns a
string.

=head2 columns

    my $cols = $s->columns;    # [0, 2] or ['name', 'id']

Returns field references used in the row template.

=head2 row_count

    $s->render(\@rows);
    my $n = $s->row_count;

Number of rows processed by the last C<render()>.

=head1 TEMPLATE SYNTAX

=head2 Field references

C<{0}>, C<{1}> for arrayref rows. C<{name}>, C<{id}> for hashref rows.
Mode auto-detected from the template. Negative indices count from the
end: C<{-1}> is the last element, C<{-2}> the second-to-last, etc.

C<{#}> is the current row number (0-based). Works with chaining:
C<{#:int_comma}>, C<{#:pad:4}>. In C<render_one>, the row number is 0.

=head2 Literal delimiters

C<{{> produces a literal C<{> in output. Useful for JSON templates:

    {{"id":{0:int}}    # produces {"id":42}

Works with any C<escape_char>: C<[[> produces C<[> when using
C<escape_char =E<gt> '['>.

=head2 Types

=head3 Escaping / encoding

C<html>, C<html_br>, C<url>, C<json>, C<hex>, C<base64>, C<base64url>, C<raw>

=head3 Numeric

C<int>, C<int_comma>, C<float:N>, C<sprintf:FMT>

=head3 String transforms

C<trim>, C<uc>, C<lc>, C<pad:N>, C<rpad:N>, C<trunc:N>, C<substr:S:L>,
C<replace:OLD:NEW>, C<mask:N>, C<length>

=head3 Logic / conversion

C<default:VALUE>, C<bool:TRUTHY:FALSY>, C<if:TEXT>, C<unless:TEXT>,
C<map:K1=V1:K2=V2:*=DEFAULT>, C<wrap:PREFIX:SUFFIX>

=head3 Data formatting

C<count>, C<date:FMT>, C<plural:SINGULAR:PLURAL>,
C<number_si>, C<bytes_si>, C<elapsed>, C<ago>,
C<coalesce:FIELD1:FIELD2:DEFAULT> - use the primary field if truthy,
otherwise try each fallback field in order; the last parameter is a
literal default string

=head2 Chaining

    {0:trim|trunc:80|html}     # pipe transforms left to right

=head1 UNICODE

UTF-8 transparent. All string operations preserve multi-byte sequences.
Output is flagged UTF-8. C<uc>/C<lc> are ASCII-only.

=head1 THREAD SAFETY

The object is B<not> safe for concurrent renders from multiple threads
due to shared render buffer and C<last_row_count> state. Create
separate objects per thread, or serialize access.

=head1 PERFORMANCE

Perl 5.40, x86_64 Linux.

B<HTML table> (13 rows, html escape):

                         Rate  Text::Xslate  hashref  chained  arrayref  render_one
    Text::Xslate     413K/s            --     -44%     -49%      -55%       -92%
    render hashref   733K/s           77%       --     -10%      -21%       -86%
    render chained   813K/s           97%      11%       --      -12%       -84%
    render arrayref  922K/s          123%      26%      13%        --       -82%
    render_one      5161K/s         1150%     604%     534%      460%         --

B<Transform throughput> (1000 rows, single transform):

    default:x  67.4K/s    int       52.4K/s    int_comma 50.1K/s
    trunc:20   44.4K/s    raw       39.8K/s    json      33.7K/s
    uc         36.4K/s    url       32.2K/s    html      28.7K/s
    trim|html  23.6K/s    float:2    6.3K/s

B<Chain depth scaling> (1000 rows):

    1 (html)                    19.1K/s
    2 (trim|html)               15.8K/s  (-17%)
    3 (trim|uc|html)            11.2K/s  (-29%)
    4 (trim|uc|trunc:20|html)   11.0K/s  (-1%)

B<Row count scaling> (int + html escape per row):

    ~25M rows/s constant from 10 to 10000 rows

B<render vs render_one> (single row):

    render_one  7.0M/s  (44% faster than render for single rows)

Run C<perl bench.pl> for your own numbers.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
