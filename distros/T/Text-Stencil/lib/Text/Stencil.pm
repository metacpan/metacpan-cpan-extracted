package Text::Stencil;
use v5.20;
use warnings;
our $VERSION = '0.03';
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# The compiled template is a malloc'd C struct addressed by a raw pointer in the
# blessed IV; cloning it into a thread would give two interpreters one pointer
# to free.
sub CLONE_SKIP { 1 }

# Storable would copy that pointer into a second object and both would free it.
sub STORABLE_freeze {
    die "Text::Stencil: objects cannot be serialised; build one where you use it\n";
}

sub from_file {
    my ($class, $file, %opts) = @_;
    open my $fh, '<:encoding(UTF-8)', $file
        or die "Text::Stencil: can't open $file: $!";
    local $/;
    my $content = <$fh>;
    # open can succeed on something that cannot be read -- a directory is the
    # easy case -- and an unchecked read then built a silently empty renderer
    # after warning from inside here. An empty file reads as a defined "", so
    # this still accepts one.
    defined $content
        or die "Text::Stencil: can't read $file: $!";
    close $fh;
    # split on whichever section markers are present, in any order
    my @parts = split /^__(HEADER|ROW|FOOTER)__[^\S\n]*\n/m, $content;
    if (@parts > 1) {
        shift @parts;                      # text before the first marker
        my %section;
        while (@parts) {
            my ($name, $body) = splice @parts, 0, 2;
            $section{lc $name} = defined $body ? $body : '';
        }
        die "Text::Stencil: $file has section markers but no __ROW__ section\n"
            unless exists $section{row};
        return $class->new(%opts, map { exists $section{$_} ? ($_ => $section{$_}) : () }
                                      qw(header row footer));
    }
    $class->new(%opts, row => $content);
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Stencil - fast XS list/table renderer with escaping, formatting, and transform chaining

=head1 SYNOPSIS

    use Text::Stencil;

    my @rows = ([1, 'Alice'], [2, 'Bob & Co']);

    my $table = Text::Stencil->new(
        header => '<table><tr><th>id</th><th>name</th></tr>',
        row    => '<tr><td>{0:int}</td><td>{1:html}</td></tr>',
        footer => '</table>',
    );
    my $html = $table->render(\@rows);

    # hashrefs, chaining, separator
    my $list = Text::Stencil->new(
        header => '<ul>',
        row    => '<li>{title:default:Untitled|trim|trunc:80|html}</li>',
        footer => '</ul>',
        separator => "\n",
    );
    print $list->render_one({ id => 1, title => 'Hello' });

    # stream to a byte handle
    open my $fh, '>:raw', 'out.html' or die $!;
    $table->render_to_fh($fh, \@rows);
    close $fh or die $!;

=head1 DESCRIPTION

Renders lists of uniform data (arrayrefs or hashrefs) into text output
using a pre-compiled row template. The template is parsed once at
construction; rendering is a tight C loop with direct buffer writes
and zero Perl interpretation overhead.

About 2x faster than L<Text::Xslate> for arrayref rows, ~1.6x for hashref
rows (see L</PERFORMANCE>). Not safe for concurrent renders from
multiple threads (see L</THREAD SAFETY>).

=head1 CONSTRUCTOR

=head2 new

    my $s = Text::Stencil->new(%opts);

Options:

=over 4

=item C<header>

String prepended before all rows (default: empty).

=item C<row>

Row template with C<{field:type}> placeholders. Omitting it renders just the
header and footer.

=item C<footer>

String appended after all rows (default: empty).

=item C<separator>

String inserted between rows (default: none).

=item C<escape_char>

Delimiter character instead of C<{> (default: C<{>). Paired closing:
C<[> E<rarr> C<]>, C<(> E<rarr> C<)>, C<< < >> E<rarr> C<< > >>; others use
the same character for open and close. Useful for JSON templates where
literal braces are needed.

It must be exactly one byte, and not C<NUL>. Anything else is an error: a
two-character string, or a character that encodes to more than one byte,
would match nothing - the whole template would then render literally with no
field ever substituted.

A byte above 0x7F is accepted only when the row template is a byte string.
Against a character string it is an error, because the row is split on raw
bytes and a high delimiter would cut a multi-byte character in half. Note
that C<from_file> always decodes, so a template loaded from a file always
needs an ASCII delimiter.

=item C<skip_if>

Column index or field name. Rows where this field is truthy (non-empty, not
C<"0">, not undef) are skipped.

=item C<skip_unless>

Column index or field name. Rows where this field is B<not> truthy are
skipped.

=back

An unrecognised option is an error, not a silent no-op: a misspelled
C<seperator> would otherwise give you a table with no separators and nothing
to explain it.

As a shorthand, C<new> may be called with a single string argument, which is
used as the C<row> template: C<< Text::Stencil->new($template) >> is equivalent
to C<< Text::Stencil->new(row => $template) >>.

=head2 from_file

    my $s = Text::Stencil->from_file('template.tpl', separator => "\n");

Load template from a file. The file is read as UTF-8. It can use section
markers:

    __HEADER__
    <table>
    __ROW__
    <tr><td>{0:html}</td></tr>
    __FOOTER__
    </table>

Any subset of the markers may be used, in any order, as long as C<__ROW__>
is present; any text before the first marker is ignored. Without markers,
the entire file content is used as the row template.

=head2 clone

    my $s2 = $s->clone(row => '{0:uc}');
    my $s3 = $s->clone(row => '{0:uc}', separator => "\n");

Create a new renderer reusing the original's header, footer, C<escape_char>
and skip conditions. C<row> is required; C<separator> may also be replaced.
Any other option is an error rather than a silent no-op, since everything
else is inherited.

=head1 METHODS

=head2 render

    my $output = $s->render(\@rows);

Render all rows. Returns a string (see L</UNICODE> for its encoding).

=head2 render_one

    my $output = $s->render_one(\@row);
    my $output = $s->render_one(\%row);

Render a single row without wrapping in an arrayref. The header and footer
are still applied, and C<skip_if>/C<skip_unless> still apply - a skipped row
gives C<"">. Only C<row_count> is left alone.

=head2 render_sorted

    my $output = $s->render_sorted(\@rows, $sort_by);
    my $output = $s->render_sorted(\@rows, $sort_by, {descending => 1, numeric => 1});

Render rows sorted by a field. C<$sort_by> is a column index for
arrayref rows or a field name for hashref rows. A leading C<-> on the
field name sorts descending: C<'-score'>. It can also be an arrayref
for multi-column sort: C<[0, 1]> or C<['name', 'age']>. Sorts
lexically ascending by default. Optional third argument is a hashref:
C<descending> sorts descending, C<numeric> compares numerically.
C<descending> and a leading C<-> select the same thing rather than cancelling:
with either one present the sort descends, so C<< '-name' >> with
C<< {descending => 0} >> still descends. A spec of the wrong kind for
the template - field names against C<{0}>, or column indices against
C<{name}> - is an error rather than a sort that quietly does nothing, since
it could not have fetched a key from any row. As with C<new>, an unrecognised key
in that hashref is an error - a misspelled C<decending> would otherwise sort
the wrong way with nothing to explain it.

The leading C<-> is a B<hashref-only> shorthand. On arrayref rows a leading
C<-> is a negative column index, exactly as in a template, so
C<< render_sorted(\@rows, '-1') >> sorts B<ascending> by the last column;
use C<< {descending => 1} >> there.

In the multi-field form the C<-> works the same way, but direction belongs
to the sort as a whole rather than to one field: C<< ['-name', 'age'] >>
sorts by name then age, all descending. Per-field directions are not
supported.

=head2 render_to_fh

    $s->render_to_fh($fh, \@rows);

Render directly to a filehandle, flushing in 64KB chunks. Bytes are written
as assembled, so use a byte handle; an C<:encoding> layer will mangle
non-ASCII output. Print the result of C<render> instead if you want the
handle's layers applied.

A failing write croaks. As with C<print>, an error the handle only notices
when its own buffer is flushed surfaces at C<close> rather than here, so
still check C<close>.

The handle is resolved once, at the start. Closing or reopening it from code
that runs during the render - a tied C<FETCH>, an overloaded C<""> - leaves
the rest of the output going to whatever now occupies that slot, so don't.
Don't write to it either: the render's own output is buffered in chunks, so
anything you C<print> to the same handle mid-render - or send there with a
nested C<render_to_fh> - lands B<ahead> of the output being assembled around
it, not where you wrote it.

=head2 render_cb

    my $output = $s->render_cb(sub { return \@row_or_undef });
    $s->render_cb(sub { return \@row_or_undef }, $fh);

Callback-based rendering. The callback is called repeatedly and should
return an arrayref or hashref (one row) or undef to stop. Anything else -
undef, a plain string, some other kind of reference - also stops it.
If a filehandle is given, output is streamed to it; otherwise returns a
string.

Leaving the callback with C<last>, C<next> or C<goto> aimed at a label outside
the sub does not work, but it fails cleanly: the callback runs on a call stack
of its own, so the jump finds no such label and dies - C<Label not found for
"last LABEL">, or C<Can't find label LABEL> for C<goto> - which you can catch
like any other error. (Before 0.03 it
unwound this call mid-flight and the interpreter could resume inside a block
it had already left, run the following statements twice, or crash.) C<die> is
the supported way to abort early; it propagates out of C<render_cb> unchanged.
To stop without an error, return C<undef>.

=head2 columns

    my $cols = $s->columns;    # [0, 2] or ['name', 'id']

Field references used in the row template, each listed once, in the order
it first appears. C<{#}> is the row number rather than a field reference,
and is not listed.

=head2 row_count

    $s->render(\@rows);
    my $n = $s->row_count;

Number of rows the last C<render>, C<render_sorted>, C<render_to_fh> or
C<render_cb> was given, including any skipped by C<skip_if>/C<skip_unless>.
C<render_one> does not change it.

=head1 TEMPLATE SYNTAX

=head2 Field references

C<{0}>, C<{1}> for arrayref rows. C<{name}>, C<{id}> for hashref rows.
Mode auto-detected from the template. Negative indices count from the
end: C<{-1}> is the last element, C<{-2}> the second-to-last, etc.

A template uses one row mode throughout, so mixing numeric and named
references (C<'{0} {name}'>) is a compile-time error, as is an empty
reference (C<{}>) or an unclosed delimiter.

C<{#}> is the current row number (0-based). It numbers the rows you passed
in, not the ones that come out, so with C<skip_if>/C<skip_unless> the numbers
have gaps and need not start at 0 - the same rows C<row_count> counts. Under
C<render_sorted> it is the position after sorting rather than the position
you passed the row in at, since sorting is what the row number is usually
wanted for; skipped rows still leave gaps. Works with chaining:
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

Values are read leniently, not validated. C<int>, C<int_comma>, C<float>
and C<sprintf> numify as Perl would; C<date>, C<elapsed>, C<ago> and
C<plural> instead take the digits and ignore everything else, so C<"1e3">
is 13 to them and 1000 to C<int>. C<plural> keeps a leading C<->, the other
three drop it. Junk formats as zero rather than failing.

The integer conversions then narrow the number the way C does, so a value too
large for an C<IV> wraps exactly as Perl's own C<sprintf "%d"> wraps it:
C<"1e19"> and C<"1e30"> give the same answers here as there. An B<infinite>
value is the one place to be careful - Perl's C<%d> prints the word C<Inf>,
while this hands the value to the platform's C<IV> conversion, and what that
produces differs between perl versions. C<NaN> is 0 everywhere, like other
junk.

The Perl-numification half of that holds only where those four come B<first>
in a chain, which is where the original scalar is still there to numify. Later
in a chain they are reading the previous transform's text instead, and change
behaviour accordingly: C<int>, C<int_comma> and C<sprintf>'s integer
conversions become digit-takers, so C<< {0:int} >> on C<" 1e3 "> is 1000 while
C<< {0:trim|int} >> is 13; C<float> and C<sprintf>'s floating conversions fall
back to C C<strtod>, which accepts forms Perl does not, so
C<< {0:float:2} >> on C<"0x1f"> is C<0.00> while C<< {0:raw|float:2} >> is
C<31.00>. The digit-takers are digit-takers in either position - there is
nothing for them to change to.

C<number_si> and C<bytes_si> follow neither rule: they always use C C<strtod>,
first in a chain or not. So on C<"0x1f"> C<int> gives C<0>, C<elapsed> gives
C<1s>, and C<number_si> gives C<31>.

C<float> formats at C C<double> precision, so on a perl built with
C<-Duselongdouble> or C<-Dusequadmath> it will show fewer significant
digits than Perl's own C<sprintf>.

C<sprintf> accepts one conversion written as
C<%[flags][width][.precision]CONV>, where C<CONV> is one of C<dixXoufegs>
and is the B<last character of the format>. Flags are C<-+ #0>; width and
precision are at most eight digits. Anything else - a trailing literal
(C<%dx>), a second conversion, C<*>, a positional specifier (C<%2$d>), or a
length modifier (C<%ld>) - is not applied and the value passes through
unchanged.

Formatting is done by the C library, so an accepted format follows C's
printf rather than Perl's C<sprintf>: C<%08s> pads with spaces, where Perl
would pad with zeros. C<%s> also stops at the first NUL byte, since that is
where a C string ends - every other transform passes NULs through, so use
C<raw> rather than C<sprintf:%s> for values that may contain one.

=head3 String transforms

C<trim>, C<uc>, C<lc>, C<pad:N>, C<rpad:N>, C<trunc:N>, C<substr:S:L>,
C<replace:OLD:NEW>, C<mask:N>, C<length>

C<trunc:N> never returns more than N bytes: above 3 it appends C<...>
within the budget, at or below 3 it cuts hard.

C<mask:N> keeps the last N bytes and replaces what precedes them with C<*>.
B<A value of N bytes or fewer is left untouched> - C<mask:4> on C<"abc"> is
C<"abc">, not C<"***"> - so choose N against your shortest value.

C<replace:OLD:NEW> replaces every non-overlapping occurrence left to right,
never re-examining what it inserted. C<replace:OLD> deletes C<OLD>; an
empty C<OLD> is a no-op.

=head3 Logic / conversion

C<default:VALUE>, C<bool:TRUTHY:FALSY>, C<if:TEXT>, C<unless:TEXT>,
C<map:K1=V1:K2=V2:*=DEFAULT>, C<wrap:PREFIX:SUFFIX> - with one parameter the
prefix alone; an empty or absent value emits nothing at all, not the wrapper

C<default:VALUE> supplies VALUE only when the field is undef or absent; an
empty string is a value and passes through.

=head3 Data formatting

C<count>, C<date:FMT> (a Unix epoch formatted in B<UTC> by strftime; the
format goes straight to the platform C<strftime>, and a few GNU extensions -
notably C<%s> - are computed in local time there rather than UTC),
C<plural:SINGULAR:PLURAL> - emits the count and the
word ("2 items"); with one form given, the plural is that form plus C<s>,
C<number_si>, C<bytes_si>,
C<elapsed> - a duration in seconds as C<"1d 1h 1m 1s">, dropping the larger
units that are zero but always ending in seconds (3600 is C<"1h 0s">), and
always non-negative,
C<ago> - a Unix epoch as C<"5m ago">, C<"2d ago">, C<"1mo ago"> (a month is
30 days, a year 365) or C<"in the future">,
C<coalesce:FIELD1:FIELD2:DEFAULT> - use the primary field if non-empty
(unlike C<bool>/C<if>, the string C<"0"> counts as present), otherwise try
each fallback field in order; the last parameter is a literal default string

C<count> is the size of the arrayref or hashref in the field, tied
containers included, and C<0> for any other defined value; an undef or
absent field renders empty. C<number_si> scales by
1000 up to C<P> and C<bytes_si> by 1024 up to C<EB>; past the top tier the
mantissa keeps growing rather than gaining a larger prefix.

=head2 Chaining

    {0:trim|trunc:80|html}     # pipe transforms left to right

C<count> and C<coalesce> act on the raw field value (a container's size, or
the first non-empty field), so each must be the first transform in its chain.
Using either later in a chain is a compile-time error.

An unrecognised transform name is a compile-time error too, so a typo such
as C<{0:hmtl}> is reported rather than quietly passing the value through
unescaped. Names are case-sensitive and are not trimmed, so C<{0:HTML}> and
C<< {0: html} >> are errors as well. A trailing delimiter with nothing after
it - C<{0:}> or C<< {0:trim|} >> - is not a transform at all and is simply
ignored. An empty segment anywhere else (C<< {0:|trim} >>, C<< {0:trim||} >>)
is an error.

A parameter given to a transform that does not take one - C<{0:uc:1}>,
C<{0:html:5}> - is a compile-time error for the same reason: it reads as
though it does something.

=head2 Transform parameters

Transforms taking a number (C<float>, C<pad>, C<rpad>, C<trunc>, C<mask>,
C<substr>) require a non-negative decimal integer; anything else, or a
value above 100_000_000, is a compile-time error. An B<empty> parameter is
the exception: it is ignored, leaving the transform its own default - zero
for C<trunc>, C<pad>, C<rpad> and the C<substr> offset, but B<2> for
C<float> and B<4> for C<mask>, so C<< {0:mask:} >> still shows the last four
bytes. Precision above 30 decimals (and within the 100_000_000 bound) is
silently clamped to 30 rather than rejected. An omitted C<substr> bound is
unbounded: C<substr:3:> runs to the end.

The 100_000_000 bound caps the value, not the work it implies:
C<< {0:pad:100000000} >> compiles and then allocates 100MB per row.

Column indices may be negative, and an index with no matching element
simply renders empty. They must still fit in a C C<int>: a larger one is
rejected, in a template at compile time and in C<skip_if>, C<skip_unless>
or a C<render_sorted> sort spec when the call is made.

A field value larger than 2GB is returned unchanged by the string
transforms. The ones that read the scalar as a number rather than as text -
C<int>, C<int_comma>, C<float>, C<count>, and C<sprintf> with any conversion
but C<%s> - never look at the string, so they behave the same at any length.

=head1 UNICODE

The output follows the input. The result is a character string only if
something character-ish contributed and nothing ruled it out: a high byte in
a template piece or field value that arrived as B<bytes> forces a byte
string, as does a transform that cuts a character in half. That holds even
where the assembled output happens to be well-formed UTF-8 - a character
template rendering the bytes C<"\xc3\xa9"> gives those two bytes back
unflagged. Rendering only byte strings therefore round-trips Latin-1 and
binary data unchanged.

Do not mix the two in one render: decode your inputs, or leave them all as
bytes. Feeding already-encoded UTF-8 bytes alongside decoded characters is
ambiguous, and whether the result comes back flagged then depends on the
order the values are seen in - where a byte value carrying high bytes is
seen before anything character-ish, the decision is deferred and settled by
validating the whole output instead.

A row that is not an arrayref or hashref renders every field empty rather
than failing, and still counts towards C<row_count>.

All string operations are byte-level: C<length> counts bytes and
C<pad>/C<rpad> pad to a byte width, while C<trunc>, C<substr> and C<mask>
can cut a multi-byte character in half; the result is then returned as
bytes rather than as a malformed character string.
C<uc>/C<lc> are ASCII-only. C<json> escapes only what JSON requires and
passes bytes E<gt>= 0x80 through untouched, so encode the value first if
the consumer expects UTF-8.

=head1 THREAD SAFETY

The object is B<not> safe for concurrent renders from multiple threads
due to shared render buffer and C<last_row_count> state. Create
separate objects per thread, or serialize access. Separate objects are
enough: no render path keeps state outside its own object.

Under ithreads the compiled template is not cloned into new threads
(C<CLONE_SKIP>), so an object must be created in the thread that uses it.
On Windows C<fork> is implemented with ithreads, so the same applies
there: build the renderer in the child, not before the fork.

=head1 PERFORMANCE

Perl 5.40, x86_64 Linux. Absolute rates depend heavily on the machine and
move 20% or more between runs on a busy one, so the comparisons below are
given as B<ratios>; the absolute figures in the later sections are from a
single run and are only useful against each other. Run C<perl -Mblib bench.pl> for
your own numbers.

B<HTML table> (13 rows, html escape), relative to L<Text::Xslate>:

    render arrayref     ~2.0-2.1x
    render chained      ~1.6x
    render hashref      ~1.6x
    render_one          ~8-11x     (one row against Xslate rendering the whole
                                   13-row table; not a per-row comparison)

Hashref rows cost a hash lookup per field where arrayref rows index
directly, which is most of the gap between the two.

B<Transform throughput> (1000 rows, single transform):

    int_comma  28.1K/s    int       27.8K/s    trunc:20  27.7K/s
    uc         26.6K/s    default:x 25.3K/s    json      23.8K/s
    raw        23.3K/s    url       22.6K/s    html      14.4K/s
    trim|html  13.9K/s    float:2    4.2K/s

B<Chain depth scaling> (1000 rows), relative to a single C<html>:

    2 (trim|html)               ~0.8x
    3 (trim|uc|html)            ~0.6x
    4 (trim|uc|trunc:20|html)   ~0.6x   (trunc shortens the string before
                                         html, offsetting its own cost)

B<Row count scaling> (int + html escape per row):

    ~11-17M rows/s; roughly flat from 100 to 10000 rows, ~20% lower at 10
    where the per-render setup is not amortised

B<render vs render_one> (single row):

    render_one  ~4-5M/s  (~40% faster than render for single rows)

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
