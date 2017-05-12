# NAME

WWW::Lipsum - perl interface to www.lipsum.com

# SYNOPSIS

    use WWW::Lipsum;

    my $lipsum = WWW::Lipsum->new(
        html => 1, amount => 50, what => 'bytes', start => 0
    );

    print "$lipsum\n"; # auto-fetches lipsum text


    # Change an arg and check for errors explicitly
    $lipsum->generate( html => 0 )
        or die "Error: " . $lipsum->error;

    print $lipsum->lipsum . "\n";


    # Change some args and fetch using interpolation overload
    $lipsum->start(0);
    $lipsum->amount(5);
    $lipsum->what('paras');

    print "$lipsum\n";

    # generate a whole bunch of lipsums
    my @lipsums = map "$lipsum", 1..10;

# DESCRIPTION

Generate _Lorem Ipsum_ place holder text from perl, using
[www.lipsum.com](http://www.lipsum.com/)

# SEE ALSO

You most likely want [Text::Lorem](https://metacpan.org/pod/Text::Lorem) or [Text::Lorem::More](https://metacpan.org/pod/Text::Lorem::More)
instead of this module, as those generate _Lorem Ipsum_ text without
using a web service.

# METHODS

## `new`

    my $lipsum = WWW::Lipsum->new;

    my $lipsum = WWW::Lipsum->new(
        html => 1, amount => 50, what => 'bytes', start => 0
    );

Creates and returns a brand new `WWW::Lipsum` object. Takes
a number of **optional** arguments that are given as key/value
pairs. These specify the format of the generated lipsum
text and can be changed either individually, using the
appropriate accessor methods, or when calling `->generate` method.
Possible arguments are as follows:

### `what`

    my $lipsum = WWW::Lipsum->new( what => 'paras' );
    my $lipsum = WWW::Lipsum->new( what => 'lists' );
    my $lipsum = WWW::Lipsum->new( what => 'words' );
    my $lipsum = WWW::Lipsum->new( what => 'bytes' );

**Optional.** Specifies in what form to get the
_Lorem Ipsum_ text. Valid values are lowercase strings
`paras`, `lists`, `words`, and `bytes` that mean to get the text
as `paragraps`, `lists`, `words`, or `bytes` respectively.
**Defaults to:** `paras`.

The meaning is most relevant for the `amount` argument (see below). The
`lists` value will cause generation of variable-item-number lists of
_Lorem Ipsum_ text. **Note:** there seems to be very loose adherence
to the `amount` you specified and what you get when you
request `bytes`, and the value seems to be ignored
if `amount` is set too low.

### `amount`

    my $lipsum = WWW::Lipsum->new( amount => 10 );

**Optional.** **Takes** a positive integer as a value. Large values
will likely be abridged by [www.lipsum.com](http://www.lipsum.com/) to something reasonable.
Specifies the number of `what` (see above) things to get.
**Defaults to:** `5`.

### `html`

    my $lipsum = WWW::Lipsum->new( html => 1 );

**Optional.** **Takes** true or false values. **Specifies** whether to wrap
_Lorem Ipsum_ text in HTML markup (will wrap in HTML when set to
a true value). This will be `<ul>/<li>`
elements when `what` is set to `lists` and `<p>` elements
for everything else. When set to false, paragraphs and lists will
be separated by double new lines. **Defaults to:** `0` (false).

### `start`

    my $lipsum = WWW::Lipsum->new( start => 0 );

**Optional.** **Takes** true or false values as a value. When set
to a true value, will ask [www.lipsum.com](http://www.lipsum.com/)
to start the generated
text with _"Lorem Ipsum"_. **Defaults to:** `1` (true)

**Note:** it seems sometimes [www.lipsum.com](http://www.lipsum.com/)
would return text that starts with _"Lorem Ipsum"_ simply by chance.

## `generate`

    my $text = $lipsum->generate(
        html => 1, amount => 50, what => 'bytes', start => 0
    ) or die $lipsum->error;
    my $x = $text;

    # or
    $lipsum->generate or die $lipsum->error;
    $text = $lipsum->lipsum;

    # or
    my $text = "$lipsum";

Accesses [www.lipsum.com](http://www.lipsum.com/) to obtain requested
chunk of _Lorem Ipsum_ text.
**Takes** the same arguments as `new` (see above); all **optional**.
**On success** returns generated _Lorem Ipsum_ text. **On failure**
returns `undef` or an empty list, depending on the context, and
the reason for failure will be available via the `->error` method.

**Note:** if you call `->generate` with arguments, the new
values will persist for all subsequent calls to `->generate`,
until you change them either by, again, passing arguments to
`->generate`, or by using accessor methods.

You can call `->generate` by simply interpolating the `WWW::Lipsum`
object in a string. When called this way, if an error occurs, the
interpolated value will be `[Error: ERROR_DESCRIPTION_HERE]`, where
`ERROR_DESCRIPTION_HERE` is the return value of `->error` method.
On success, the interpolated value will be the generated _Lorem Ipsum_
text.

## `lipsum`

    $lipsum->generate or die $lipsum->error;
    $text = $lipsum->lipsum;

**Takes** no arguments. Must be called after a successful call to
`->generate`. Returns the same thing the last successful call
to `->generate` returned.

## `error`

    $lipsum->generate
        or die 'Error occured: ' . $lipsum->error;

**Takes** no arguments. Returns the human-readable message, explaining
why the last call to `->generate` failed.

## `what`

    my $current_what = $lipsum->what;
    $lipsum->what('paras');
    $lipsum->what('lists');
    $lipsum->what('words');
    $lipsum->what('bytes');

**Takes** a single **optional** argument that is the same as the value for the
`what` argument of the `->new` method.
When given an argument, modifies the currently active value for the
`what` argument.
**Returns** the currently active value of `what` argument (which
will be the provided argument, if one is given).
See `->new` method for more info.

## `start`

    my $current_start = $lipsum->start;
    $lipsum->start(0);
    $lipsum->start(1);

**Takes** a single **optional** argument that is the same as the value for the
`start` argument of the `->new` method.
When given an argument, modifies the currently active value for the
`start` argument. **Returns** the currently active value of `start`
argument (which will be the provided argument, if one is given).
See `->new` method for more info.

## `amount`

    my $current_amount = $lipsum->amount;
    $lipsum->amount(50);
    $lipsum->amount(15);

**Takes** a single **optional** argument that is the same as the value for the
`amount` argument of the `->new` method.
When given an argument, modifies the currently active value for the
`amount` argument.
See `->new` method for more info.

## `html`

    my $current_html = $lipsum->html;
    $lipsum->html(1);
    $lipsum->html(0);

**Takes** a single **optional** argument that is the same as the value for the
`html` argument of the `->new` method.
When given an argument, modifies the currently active value for the
`html` argument. **Returns** the currently active value of `html`
argument (which will be the provided argument, if one is given).
See `->new` method for more info.

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-Lipsum](https://github.com/zoffixznet/WWW-Lipsum)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-Lipsum/issues](https://github.com/zoffixznet/WWW-Lipsum/issues)

If you can't access GitHub, you can email your request
to `bug-www-lipsum at rt.cpan.org`

# AUTHOR

Zoffix Znet <zoffix at cpan.org>
([http://zoffix.com/](http://zoffix.com/), [http://haslayout.net/](http://haslayout.net/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.

# HISTORY AND NOTES ON OLD VERSION

There used to be another version of `WWW::Lipsum` on CPAN, developed
by Earle Martin. I have a couple of modules that depend on
`WWW::Lipsum`. Earle, or someone else, subsequently deleted it from
CPAN, leaving my modules dead.

At first, I resurrected Earle's version, but it had a bug. The code
was using [HTML::TokeParser](https://metacpan.org/pod/HTML::TokeParser) and was a pain in the butt
to maintain, and the interface really irked me.
So, I rewrote the whole thing from scratch, broke the API
(more or less), and released the module under a same-as-perl license.

If you are looking for Earle's version, it can still be accessed on
[BackPAN](http://backpan.perl.org/authors/id/E/EM/EMARTIN/).
