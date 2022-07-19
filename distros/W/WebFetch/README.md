# NAME

WebFetch - Perl module to download and save information from the Web

# SYNOPSIS

    use WebFetch;

# DESCRIPTION

The WebFetch module is a framework for downloading and saving
information from the web, and for saving or re-displaying it.
It provides a generalized interface for saving to a file
while keeping the previous version as a backup.
This is mainly intended for use in a cron-job to acquire
periodically-updated information.

WebFetch allows the user to specify a source and destination, and
the input and output formats.  It is possible to write new Perl modules
to the WebFetch API in order to add more input and output formats.

The currently-provided input formats are Atom, RSS, WebFetch "SiteNews" files
and raw Perl data structures.

The currently-provided output formats are RSS, WebFetch "SiteNews" files,
the Perl Template Toolkit, and export into a TWiki site.

Some modules which were specific to pre-RSS/Atom web syndication formats
have been deprecated.  Those modules can be found in the CPAN archive
in WebFetch 0.10.  Those modules are no longer compatible with changes
in the current WebFetch API.

# INSTALLATION

After unpacking and the module sources from the tar file, run

`perl Makefile.PL`

`make`

`make install`

Or from a CPAN shell you can simply type "`install WebFetch`"
and it will download, build and install it for you.

If you need help setting up a separate area to install the modules
(i.e. if you don't have write permission where perl keeps its modules)
then see the Perl FAQ.

To begin using the WebFetch modules, you will need to test your
fetch operations manually, put them into a crontab, and then
use server-side include (SSI) or a similar server configuration to 
include the files in a live web page.

## MANUALLY TESTING A FETCH OPERATION

Select a directory which will be the storage area for files created
by WebFetch.  This is an important administrative decision -
keep the volatile automatically-generated files in their own directory
so they'll be separated from manually-maintained files.

Choose the specific WebFetch-derived modules that do the work you want.
See their particular manual/web pages for details on command-line arguments.
Test run them first before committing to a crontab.

## SETTING UP CRONTAB ENTRIES

If needed, see the manual pages for crontab(1), crontab(5) and any
web sites or books on Unix system administration.

Since WebFetch command lines are usually very long, the user may prefer
to make one or more scripts as front-ends so crontab entries aren't so big.

Try not to run crontab entries too often - be aware if the site you're
accessing has any resource constraints, and how often their information
gets updated.  If they request users not to access a feed more often
than a certain interval, respect it.  (It isn't hard to find violators
in server logs.)  If in doubt, try every 30 minutes until more information
becomes available.

# WebFetch FUNCTIONS

The following function definitions assume **`$obj`** is a blessed
reference to a module that is derived from (inherits from) WebFetch.

- WebFetch::module\_register( $module, @capabilities );

    This function allows a Perl module to register itself with the WebFetch API
    as able to perform various capabilities.

    For subclasses of WebFetch, it can be called as a class method.
       `__PACKAGE__-&gt;module_register( @capabilities );`

    For the $module parameter, the Perl module should provide its own
    name, usually via the \_\_PACKAGE\_\_ string.

    The @capabilities array is any number of strings as needed to list the
    capabilities which the module performs for the WebFetch API.
    The currently-recognized capabilities are "cmdline", "input" and "output".
    "config", "filter", "save" and "storage" are reserved for future use.  The
    function will save all the capability names that the module provides, without
    checking whether any code will use it.

    For example, the WebFetch::Output::TT module registers itself like this:
       `__PACKAGE__-&gt;module_register( "cmdline", "output:tt" );`
    meaning that it defines additional command-line options, and it provides an
    output format handler for the "tt" format, the Perl Template Toolkit.

- fetch\_main

    This function is exported into the main package.
    For all modules which registered with an "input" capability for the requested
    file format at the time this is called, it will call the run() function on
    behalf of each of the packages.

- $obj = WebFetch::new( param => "value", \[...\] )

    Generally, the new function should be inherited and used from a derived
    class.  However, WebFetch provides an AUTOLOAD function which will catch
    wayward function calls from a subclass, and redirect it to the appropriate
    function in the calling class, if it exists.

    The AUTOLOAD feature is needed because, for example, when an object is
    instantiated in a WebFetch::Input::\* class, it will later be passed to
    a WebFetch::Output::\* class, whose data method functions can be accessed
    this way as if the WebFetch object had become a member of that class.

- $obj->init( ... )

    This is called from the `new` function that modules inherit from WebFetch.
    If subclasses override it, they should still call it before completion.
    It takes "name" => "value" pairs which are all placed verbatim as
    attributes in `$obj`.

- WebFetch::mod\_load ( $class )

    This specifies a WebFetch module (Perl class) which needs to be loaded.
    In case of an error, it throws an exception.

- WebFetch::run

    This function can be called by the `main::fetch_main` function
    provided by WebFetch or by another user function.
    This handles command-line processing for some standard options,
    calling the module-specific fetch function and WebFetch's $obj->save
    function to save the contents to one or more files.

    The command-line processing for some standard options are as follows:

    - --dir _directory_

        (required) the directory in which to write output files

    - --group _group_

        (optional) the group ID to set the output file(s) to

    - --mode _mode_

        (optional) the file mode (permissions) to set the output file(s) to

    - --save\_file _save-file-path_

        (optional) save a copy of the fetched info
        in the file named by this parameter.
        The contents of the file are determined by the `--dest_format` parameter.
        If `--dest_format` isn't defined but only one module has registered a
        file format for saving, then that will be used by default.

    - --quiet

        (optional) suppress printed warnings for HTTP errors
        _(applies only to modules which use the WebFetch::get() function)_
        in case they are not desired for cron outputs

    - --debug

        (optional) print verbose debugging outputs,
        only useful for developers adding new WebFetch-based modules
        or finding/reporting a bug in an existing module

    Modules derived from WebFetch may add their own command-line options
    that WebFetch::run() will use by defining a variable called
    **`@Options`** in the calling module,
    using the name/value pairs defined in Perl's Getopts::Long module.
    Derived modules can also add to the command-line usage error message by
    defining a variable called **`$Usage`** with a string of the additional
    parameters, as they should appear in the usage message.

- $obj->do\_actions

    _`do_actions` was added in WebFetch 0.10 as part of the
    WebFetch Embedding API._
    Upon entry to this function, $obj must contain the following attributes:

    - data

        is a reference to a hash containing the following three (required)
        keys:

        - fields

            is a reference to an array containing the names of the fetched data fields
            in the order they appear in the records of the _data_ array.
            This is necessary to define what each field is called
            because any kind of data can be fetched from the web.

        - wk\_names

            is a reference to a hash which maps from
            a key string with a "well-known" (to WebFetch) field type
            to a field name used in this table.
            The well-known names are defined as follows:

            - title

                a one-liner banner or title text
                (plain text, no HTML tags)

            - url

                URL or file path (as appropriate) to the news source

            - id

                unique identifier string for the entry

            - date

                a date stamp,
                which must be program-readable
                by Perl's Date::Calc module in the Parse\_Date() function
                in order to support timestamp-related comparisons
                and processing that some users have requested.
                If the date cannot be parsed by Date::Calc,
                either translate it when your module captures it,
                or do not define this "well-known" field
                because it wouldn't fit the definition.
                (plain text, no HTML tags)

            - summary

                a paragraph of summary text in HTML

            - comments

                number of comments/replies at the news site
                (plain text, no HTML tags)

            - author

                a name, handle or login name representing the author of the news item
                (plain text, no HTML tags)

            - category

                a word or short phrase representing the category, topic or department
                of the news item
                (plain text, no HTML tags)

            - location

                a location associated with the news item
                (plain text, no HTML tags)

            The field names for this table are defined in the _fields_ array.

            The hash only maps for the fields available in the table.
            If no field representing a given well-known name is present
            in the data fields,
            that well-known name key must not be defined in this hash.

        - records

            an array containing the data records.
            Each record is itself a reference to an array of strings which are
            the data fields.
            This is effectively a two-dimensional array or a table.

            Only one table-type set of data is permitted per fetch operation.
            If more are needed, they should be arranged as separate fetches
            with different parameters.

    - actions

        is a reference to a hash.
        The hash keys are names for handler functions.
        The WebFetch core provides internal handler functions called
        _fmt\_handler\_html_ (for HTML output), 
        _fmt\_handler\_xml_ (for XML output), 
        _fmt\_handler\_wf_ (for WebFetch::General format), 
        However, WebFetch modules may provide additional
        format handler functions of their own by prepending
        "fmt\_handler\_" to the key string used in the _actions_ array.

        The values are array references containing
        _"action specs"_,
        which are themselves arrays of parameters
        that will be passed to the handler functions
        for generating output in a specific format.
        There may be more than one entry for a given format if multiple outputs
        with different parameters are needed.

        The presence of values in this field mean that output is to be
        generated in the specified format.
        The presence of these would have been chosed by the WebFetch module that
        created them - possibly by default settings or by a command-line argument
        that directed a specific output format to be used.

        For each valid action spec,
        a separate "savable" (contents to be placed in a file)
        will be generated from the contents of the _data_ variable.

        The valid (but all optional) keys are

        - html

            the value must be a reference to an array which specifies all the
            HTML generation (html\_gen) operations that will take place upon the data.
            Each entry in the array is itself an array reference,
            containing the following parameters for a call to html\_gen():

            - filename

                a file name or path string
                (relative to the WebFetch output directory unless a full path is given)
                for output of HTML text.

            - params

                a hash reference containing optional name/value parameters for the
                HTML format handler.

                - filter\_func

                    (optional)
                    a reference to code that, given a reference to an entry in
                    @{$self->{data}{records}},
                    returns true (1) or false (0) for whether it will be included in the
                    HTML output.
                    By default, all records are included.

                - sort\_func

                    (optional)
                    a reference to code that, given references to two entries in
                    @{$self->{data}{records}},
                    returns the sort comparison value for the order they should be in.
                    By default, no sorting is done and all records (subject to filtering)
                    are accepted in order.

                - format\_func

                    (optional)
                    a refernce to code that, given a reference to an entry in
                    @{$self->{data}{records}},
                    stores a savable representation of the string.

        Additional valid keys may be created by modules that inherit from WebFetch
        by supplying a method/function named with "fmt\_handler\_" preceding the
        string used for the key.
        For example, for an "xyz" format, the handler function would be
        _fmt\_handler\_xyz_.
        The value (the "action spec") of the hash entry
        must be an array reference.
        Within that array are "action spec entries",
        each of which is a reference to an array containing the list of
        parameters that will be passed verbatim to the _fmt\_handler\_xyz_ function.

        When the format handler function returns, it is expected to have
        created entries in the $obj->{savables} array
        (even if they only contain error messages explaining a failure),
        which will be used by $obj->save() to save the files and print the
        error messages.

        For coding examples, use the _fmt\_handler\_\*_ functions in WebFetch.pm itself.

- $obj->fetch

    **This function must be provided by each derived module to perform the
    fetch operaton specific to that module.**
    It will be called from `new()` so you should not call it directly.
    Your fetch function should extract some data from somewhere
    and place of it in HTML or other meaningful form in the "savable" array.

    TODO: cleanup references to WebFetch 0.09 and 0.10 APIs.

    Upon entry to this function, $obj must contain the following attributes:

    - dir

        The name of the directory to save in.
        (If called from the command-line, this will already have been provided
        by the required `--dir` parameter.)

    - savable

        a reference to an array where the "savable" items will be placed by
        the $obj->fetch function.
        (You only need to provide an array reference -
        other WebFetch functions can write to it.)

        In WebFetch 0.10 and later,
        this parameter should no longer be supplied by the _fetch_ function
        (unless you wish to use 0.09 backward compatibility)
        because it is filled in by the _do\_actions_
        after the _fetch_ function is completed
        based on the _data_ and _actions_ variables
        that are set in the _fetch_ function.
        (See below.)

        Each entry of the savable array is a hash reference with the following
        attributes:

        - file

            file name to save in

        - content

            scalar w/ entire text or raw content to write to the file

        - group

            (optional) group setting to apply to file

        - mode

            (optional) file permissions to apply to file

        Contents of savable items may be generated directly by derived modules
        or with WebFetch's `html_gen`, `html_savable` or `raw_savable`
        functions.
        These functions will set the group and mode parameters from the
        object's own settings, which in turn could have originated from
        the WebFetch command-line if this was called that way.

    Note that the fetch functions requirements changed in WebFetch 0.10.
    The old requirement (0.09 and earlier) is supported for backward compatibility.

    _In WebFetch 0.09 and earlier_,
    upon exit from this function, the $obj->savable array must contain
    one entry for each file to be saved.
    More than one array entry means more than one file to save.
    The WebFetch infrastructure will save them, retaining backup copies
    and setting file modes as needed.

    _Beginning in WebFetch 0.10_, the "WebFetch embedding" capability was introduced.
    In order to do this, the captured data of the _fetch_ function 
    had to be externalized where other Perl routines could access it.  
    So the fetch function now only populates data structures
    (including code references necessary to process the data.)

    Upon exit from the function,
    the following variables must be set in `$obj`:

    - data

        is a reference to a hash which will be used by the _do\_actions_ function.
        (See above.)

    - actions

        is a reference to a hash which will be used by the _do\_actions_ function.
        (See above.)

- $obj->get

    This WebFetch utility function will get a URL and return a reference
    to a scalar with the retrieved contents.
    Upon entry to this function, `$obj` must contain the following attributes: 

    - source

        the URL to get

    - quiet

        a flag which, when set to a non-zero (true) value,
        suppresses printing of HTTP request errors on STDERR

- $obj->html\_savable( $filename, $content )

    _In WebFetch 0.10 and later, this should be used only in
    format handler functions.  See do\_actions() for details._

    This WebFetch utility function stores pre-generated HTML in a new entry in
    the $obj->{savable} array, for later writing to a file.
    It's basically a simple wrapper that puts HTML comments
    warning that it's machine-generated around the provided HTML text.
    This is generally a good idea so that neophyte webmasters
    (and you know there are a lot of them in the world :-)
    will see the warning before trying to manually modify
    your automatically-generated text.

    See $obj->fetch for details on the contents of the `savable` parameter

- $obj->raw\_savable( $filename, $content )

    _In WebFetch 0.10 and later, this should be used only in
    format handler functions.  See do\_actions() for details._

    This WebFetch utility function stores any raw content and a filename
    in the $obj->{savable} array,
    in preparation for writing to that file.
    (The actual save operation may also automatically include keeping
    backup files and setting the group and mode of the file.)

    See $obj->fetch for details on the contents of the `savable` parameter

- $obj->direct\_fetch\_savable( $filename, $source )

    _This should be used only in format handler functions.
    See do\_actions() for details._

    This adds a task for the save function to fetch a URL and save it
    verbatim in a file.  This can be used to download links contained
    in a news feed.

- $obj->no\_savables\_ok

    This can be used by an output function which handles its own intricate output
    operation (such as WebFetch::Output::TWiki).  If the savables array is empty,
    it would cause an error.  Using this function drops a note in it which
    basically says that's OK.

- $obj->save

    This WebFetch utility function goes through all the entries in the
    $obj->{savable} array and saves their contents,
    providing several services such as keeping backup copies, 
    and setting the group and mode of the file, if requested to do so.

    If you call a WebFetch-derived module from the command-line run()
    or fetch\_main() functions, this will already be done for you.
    Otherwise you will need to call it after populating the
    `savable` array with one entry per file to save.

    Upon entry to this function, `$obj` must contain the following attributes: 

    - dir

        directory to save files in

    - savable

        names and contents for files to save

    See $obj->fetch for details on the contents of the `savable` parameter

- AUTOLOAD functionality

    When a WebFetch input object is passed to an output class, operations
    on $self would not usually work.  WebFetch subclasses are considered to be
    cooperating with each other.  So WebFetch provides AUTOLOAD functionality
    to catch undefined function calls for its subclasses.  If the calling 
    class provides a function by the name that was attempted, then it will
    be redirected there.

## WRITING WebFetch-DERIVED MODULES

The easiest way to make a new WebFetch-derived module is to start
from the module closest to your fetch operation and modify it.
Make sure to change all of the following:

- fetch function

    The fetch function is the meat of the operation.
    Get the desired info from a local file or remote site and place the
    contents that need to be saved in the `savable` parameter.

- module name

    Be sure to catch and change them all.

- file names

    The code and documentation may refer to output files by name.

- module parameters

    Change the URL, number of links, etc as necessary.

- command-line parameters

    If you need to add command-line parameters, modify both the
    **`@Options`** and **`$Usage`** variables.
    Don't forget to add documentation for your command-line options
    and remove old documentation for any you removed.

    When adding documentation, if the existing formatting isn't enough
    for your changes, there's more information about
    Perl's
    POD ("plain old documentation")
    embedded documentation format at
    http://www.cpan.org/doc/manual/html/pod/perlpod.html

- authors

    Do not modify the names unless instructed to do so.
    The maintainers have discretion whether one's contributions are significant enough to qualify as a co-author.

Please consider contributing any useful changes back to the WebFetch
project at `maint@webfetch.org`.

# ACKNOWLEDGEMENTS

WebFetch was written by Ian Kluft
Send patches, bug reports, suggestions and questions to
`maint@webfetch.org`.

Some changes in versions 0.12-0.13 (Aug-Sep 2009) were made for and
sponsored by Twiki Inc (formerly TWiki.Net).

# LICENSE

WebFetch is Open Source software licensed under the GNU General Public License Version 3.
See [https://www.gnu.org/licenses/gpl-3.0-standalone.html](https://www.gnu.org/licenses/gpl-3.0-standalone.html).

# SEE ALSO

[WebFetch::Input::PerlStruct.html"](https://metacpan.org/pod/WebFetch%3A%3AInput%3A%3APerlStruct.html%22)WebFetch::Input::PerlStruct>,
[WebFetch::Input::SiteNews.html"](https://metacpan.org/pod/WebFetch%3A%3AInput%3A%3ASiteNews.html%22)WebFetch::Input::SiteNews>,
[WebFetch::Input::Atom.html"](https://metacpan.org/pod/WebFetch%3A%3AInput%3A%3AAtom.html%22)WebFetch::Input::Atom>,
[WebFetch::Input::RSS.html"](https://metacpan.org/pod/WebFetch%3A%3AInput%3A%3ARSS.html%22)WebFetch::Input::RSS>,
[WebFetch::Input::Dump.html"](https://metacpan.org/pod/WebFetch%3A%3AInput%3A%3ADump.html%22)WebFetch::Input::Dump>,
[WebFetch::Output::TT.html"](https://metacpan.org/pod/WebFetch%3A%3AOutput%3A%3ATT.html%22)WebFetch::Output::TT>,
[WebFetch::Output::Dump.html"](https://metacpan.org/pod/WebFetch%3A%3AOutput%3A%3ADump.html%22)WebFetch::Output::Dump>,
[https://github.com/ikluft/WebFetch](https://github.com/ikluft/WebFetch),
[http://www.perl.org/](http://www.perl.org/)
