# NAME

WWW::Pastebin::PastebinCa::Create - create new pastes on http://pastebin.ca/ from Perl

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use strict;
    use warnings;

    use WWW::Pastebin::PastebinCa::Create;

    my $paster = WWW::Pastebin::PastebinCa::Create->new;

    $paster->paste('testing')
        or die $paster->error;

    print "Your paste can be found on $paster\n";

<div>
    </div></div>
</div>

# DESCRIPTION

The module provides means of pasting large texts into
[http://pastebin.ca/](http://pastebin.ca/) pastebin site.

**Note:** pastebin.ca was rebuilt in 2026 and now exposes a documented API
(see [https://pastebin.ca/api/v1/openapi.json](https://pastebin.ca/api/v1/openapi.json)) instead of the old HTML
paste form. This module creates pastes anonymously through that API,
solving the site's proof-of-work challenge in place of the browser
Turnstile widget (no account or API key is required). Because the site
requires anonymous pastes to expire, an `expire` that is empty or longer
than 90 days is capped at pastebin.ca's 90-day maximum (see `expire`
below).

# CONSTRUCTOR

## new

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $paster = WWW::Pastebin::PastebinCa::Create->new;

    my $paster = WWW::Pastebin::PastebinCa::Create->new( timeout => 10 );

    my $paster = WWW::Pastebin::PastebinCa::Create->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

Bakes and returns a fresh WWW::Pastebin::PastebinCa::Create object. Takes two
_optional_ arguments which are as follows:

### timeout

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">
</div>

    my $paster = WWW::Pastebin::PastebinCa::Create->new( timeout => 10 );

Takes a scalar as a value which is the value that will be passed to
the [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize) object to indicate connection timeout in seconds.
**Defaults to:** `30` seconds

### mech

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png">
</div>

    my $paster = WWW::Pastebin::PastebinCa::Create->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

If a simple timeout is not enough for your needs feel free to specify
the `mech` argument which takes a [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize) object as a value.
**Defaults to:** plain [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize) object with `timeout` argument
set to whatever WWW::Pastebin::PastebinCa::Create's `timeout` argument is set to
as well as `agent` argument is set to mimic FireFox.

# METHODS

## paste

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $uri = $paster->paste('some long text')
        or die $paster->error;

    my $uri2 = $paster->paste(
        'some long text',
        name    => 'Zoffix',
        lang    => 6, # perl syntax highlights
        expire  => '5 minutes',
        desc    => 'some codes',
        tags    => 'some space separated tags',
    ) or die $paster->error;

Instructs the object to create a new paste. If an error occured during
pasting the method will return either `undef` or an empty list
depending on the context and the error will be available via `error()`
method. On success returns a [URI](https://metacpan.org/pod/URI) object poiting to the newly created
paste (see also `uri()` method). The first argument is
_mandatory_ content of your paste. The rest are optional arguments which
are passed in a key/value pairs. The optional arguments are as follows:

### name

    { name    => 'Zoffix' }

**Optional**. Takes a scalar as an argument which specifies the name of the
poster or
the titles of the paste. **Defaults to:** empty string, which in turn results
to word `Stuff` being the title of the paste. **Defaults to:** empty string.

## lang

    { lang    => 6 }

**Optional**. Takes an integer value from `1` to `34` representing the
(computer)
language of the paste, or, in other words, the syntax highlights to turn
on. **Defaults to:** `1` (Raw). The integer `lang` codes are as follows:

         1 => 'Raw',
         2 => 'Asterisk Configuration',
         3 => 'C Source',
         4 => 'C++ Source',
         5 => 'PHP Source',
         6 => 'Perl Source',
         7 => 'Java Source',
         8 => 'Visual Basic Source',
         9 => 'C# Source',
        10 => 'Ruby Source',
        11 => 'Python Source',
        12 => 'Pascal Source',
        13 => 'mIRC Script',
        14 => 'PL/I Source',
        15 => 'XML Document',
        16 => 'SQL Statement',
        17 => 'Scheme Source',
        18 => 'Action Script',
        19 => 'Ada Source',
        20 => 'Apache Configuration',
        21 => 'Assembly (NASM)',
        22 => 'ASP',
        23 => 'BASH Script',
        24 => 'CSS',
        25 => 'Delphi Source',
        26 => 'HTML 4.0 Strict',
        27 => 'JavaScript',
        28 => 'LISP Source',
        29 => 'Lua Source',
        30 => 'Microprocessor ASM',
        31 => 'Objective C',
        32 => 'Visual Basic .NET',
        33 => 'Script Log',
        34 => 'Diff / Patch',

### expire

    { expire  => '5 minutes' }

**Optional**. Takes a "valid expire string" as an argument. Specifies when
the paste should expire. **Note:** the rebuilt pastebin.ca requires anonymous
pastes to expire within 90 days, so an empty value (historically "never")
or any value longer than 90 days is capped at 90 days. **Defaults to:**
empty string, which is now treated as "the 90-day maximum". Possible
"valid expire string"s are as follows:

    '2 hours'
    '4 hours'
    '1 year'
    '2 weeks'
    '45 minutes'
    '2 months'
    '30 minutes'
    '1 week'
    '1 hour'
    '15 minutes'
    '10 minutes'
    '3 days'
    '5 months'
    '4 months'
    '5 minutes'
    '8 hours'
    '2 days'
    '3 months'
    '1 day'
    '12 hours'
    '3 weeks'
    '6 months'
    '1 month'

### desc

    { desc => 'some codes' }

**Optional**. Takes a scalar string representing the description of the paste.
**Defaults to:** empty string. **Note:** the rebuilt pastebin.ca no longer
stores a separate paste description, so this argument is accepted for
backwards compatibility but has no effect.

### tags

    { tags => 'some space separated tags' }

**Optional**.
Takes a scalar string which should be space separated "tags" to tag
the paste with. **Defaults to:** empty string. **Note:** the rebuilt
pastebin.ca no longer supports paste tags, so this argument is accepted for
backwards compatibility but has no effect.

## error

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $uri = $paster->paste('some long text')
        or die $paster->error;

If an error occured during
a call to `paste()` it will return either `undef` or an empty list
depending on the context and the error will be available via `error()`
method. Takes no arguments, returns an error message explaining why
`paste()` failed.

## paste\_uri

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $paste_uri = $paster->paste_uri;

    print "Paste was pasted on $paster\n";

Must be called after a successfull call to `paste()`. Takes no arguments,
returns a [URI](https://metacpan.org/pod/URI) object pointing to a newly created paste. This method
is overloaded with `q|""|`, thus you can simply interpolate your object
in a string to obtain the URI of newly created paste.

## valid\_langs

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-key-value.png">
</div>

    my %valid_lang_codes_and_descriptions = $paster->valid_langs;
    use Data::Dumper;
    print Dumper \%valid_lang_codes_and_descriptions;

Takes no arguments. Returns a flattened hash of valid language codes
to use in `lang` argument to `paste()` method as keys and the language
descriptions as values.

## valid\_expires

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-list.png">
</div>

    print "'$_' is a valid expire value\n"
        for $paster->valid_expires;

Takes no arguments. Returns a list of valid values for `expire` argument
to `paste()` method

## mech

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $old_mech = $paster->mech;

    $paster->mech( WWW::Mechanize->new( agent => '007' ) );

Returns a [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize) object used internally for pasting. When
called with an optional argument (which must be a [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize) object)
will use it for pasting.

# NO SPAM

Please note that pastebin.ca has a spam protection and will ban you for
pasting too much. So don't abuse it, ktnx.

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Create](https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Create)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Create/issues](https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Create/issues)

If you can't access GitHub, you can email your request
to `bug-www-pastebin-pastebinca-create at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
