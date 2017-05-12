# NAME

WWW::Pastebin::PastebinCa::Retrieve - a module to retrieve pastes from http://pastebin.ca/ website

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    my $paster = WWW::Pastebin::PastebinCa::Retrieve->new;

    $paster->retrieve('http://pastebin.ca/951898')
        or die $paster->error;

    print "Paste content is:\n$paster\n";

<div>
    </div></div>
</div>

# DESCRIPTION

The module provides interface to retrieve pastes from
[http://pastebin.ca/](http://pastebin.ca/) website via Perl.

# CONSTRUCTOR

## `new`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $paster = WWW::Pastebin::PastebinCa::Retrieve->new;

    my $paster = WWW::Pastebin::PastebinCa::Retrieve->new(
        timeout => 10,
    );

    my $paster = WWW::Pastebin::PastebinCa::Retrieve->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new juicy WWW::Pastebin::PastebinCa::Retrieve
object. Takes two arguments, both are _optional_. Possible arguments are
as follows:

### `timeout`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">
</div>

    ->new( timeout => 10 );

**Optional**. Specifies the `timeout` argument of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)'s
constructor, which is used for retrieving. **Defaults to:** `30` seconds.

### `ua`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png">
</div>

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

**Optional**. If the `timeout` argument is not enough for your needs
of mutilating the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object used for retrieving, feel free
to specify the `ua` argument which takes an [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object
as a value. **Note:** the `timeout` argument to the constructor will
not do anything if you specify the `ua` argument as well. **Defaults to:**
plain boring default [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object with `timeout` argument
set to whatever `WWW::Pastebin::PastebinCa::Retrieve`'s `timeout`
argument is set to as well as `agent` argument is set to mimic Firefox.

# METHODS

## `retrieve`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-hashref.png">
</div>

    my $results_ref = $paster->retrieve('http://pastebin.ca/951898')
        or die $paster->error;

    my $results_ref = $paster->retrieve('951898')
        or die $paster->error;

Instructs the object to retrieve a paste specified in the argument. Takes
one mandatory argument which can be either a full URI to the paste you
want to retrieve or just its ID.
On failure returns either `undef` or an empty list depending on the context
and the reason for the error will be available via `error()` method.
On success returns a hashref with the following keys/values:

    $VAR1 = {
          'language' => 'Raw',
          'content' => 'blah blah content of the paste',
          'post_date' => 'Friday, March 21st, 2008 at 1:05:19pm MDT',
          'name' => 'Unnamed',
          'desc' => 'Perl stuff'
    };

- language

        { 'language' => 'Raw' }

    The (computer) language of the paste.

- content

        { 'content' => 'select t.terr_id, max(t.start_date) as start_dat' }

    The content of the paste.

- post\_date

        { 'post_date' => 'Wednesday, March 5th, 2008 at 10:31:42pm MST' }

    The date when the paste was created

- name

        { 'name' => 'Mine' }

    The name of the poster or the title of the paste.

- desc

        { 'desc' => 'Perl stuff' }

    Contains description of the paste.

## `error`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    $paster->retrieve('951898')
        or die $paster->error;

On failure `retrieve()` returns either `undef` or an empty list depending
on the context and the reason for the error will be available via `error()`
method. Takes no arguments, returns an error message explaining the failure.

## `id`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $paste_id = $paster->id;

Must be called after a successful call to `retrieve()`. Takes no arguments,
returns a paste ID number of the last retrieved paste irrelevant of whether
an ID or a URI was given to `retrieve()`

## `uri`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $paste_uri = $paster->uri;

Must be called after a successful call to `retrieve()`. Takes no arguments,
returns a [URI](https://metacpan.org/pod/URI) object with the URI pointing to the last retrieved paste
irrelevant of whether an ID or a URI was given to `retrieve()`

## `results`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-hashref.png">
</div>

    my $last_results_ref = $paster->results;

Must be called after a successful call to `retrieve()`. Takes no arguments,
returns the exact same hashref the last call to `retrieve()` returned.
See `retrieve()` method for more information.

## `content`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $paste_content = $paster->content;

    print "Paste content is:\n$paster\n";

Must be called after a successful call to `retrieve()`. Takes no arguments,
returns the actual content of the paste. **Note:** this method is overloaded
for this module for interpolation. Thus you can simply interpolate the
object in a string to get the contents of the paste.

## `ua`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-subref.png">
</div>

    my $old_LWP_UA_obj = $paster->ua;

    $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'foos' );

Returns a currently used [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object used for retrieving
pastes. Takes one optional argument which must be an [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
object, and the object you specify will be used in any subsequent calls
to `retrieve()`.

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Retrieve](https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Retrieve)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Retrieve/issues](https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Retrieve/issues)

If you can't access GitHub, you can email your request
to `bug-www-pastebin-pastebinca-retrieve at rt.cpan.org`

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
