# NAME

WWW::PAUSE::CleanUpHomeDir - the module to clean up old dists from your PAUSE home directory

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use strict;
    use warnings;

    use WWW::PAUSE::CleanUpHomeDir;

    my $pause = WWW::PAUSE::CleanUpHomeDir->new( 'PAUSE_ID', 'PASSWORD' );

    $pause->fetch_list
        or die $pause->error;

    my @old_files = $pause->list_old;
    die "No old files were found\n"
        unless @old_files;

    print @old_files . " old files were found:\n" .
            join "\n", @old_files, '';

    print "\nEnter dist names you want to delete or just hit ENTER to delete"
            . " delete all of them\n";

    my @to_delete = split ' ', <STDIN>;
    my $deleted_ref = $pause->clean_up(\@to_delete)
        or die $pause->error;

    print "Deleted:\n" . join "\n", @$deleted_ref, '';

    print "\nWould you like to undelete any of these files? "
            . "If not, just hit ENTER\n";

    my @to_undelete = split ' ', <STDIN>;
    die "Terminating..\n"
        unless @to_undelete;

    $pause->undelete(\@to_undelete)
        or die $pause->error;

    print "Success..\n";

<div>
    </div></div>
</div>

# DESCRIPTION

The module provides means to clean up your PAUSE home directory from
old distributions with ability to undelete files if you so prefer.

# WARNING

The module was tested for me and it works for me. The test suite does
not include live tests to determine if it actually deletes anything.
Depending on the versioning system you are using for your files it might
not work for you. I recommend that you double check (at least on first runs)
if the right files were deleted.

# CONSTRUCTOR

## new

    my $pause = WWW::PAUSE::CleanUpHomeDir->new(
        'PAUSE_ID',
        'PAUSE_password',
        use_http => 1, # optional; by default uses HTTPS
        timeout => 10, # optional; default is 30
    );

Constructs and returns a fresh WWW::PAUSE::CleanUpHomeDir object. Takes
two mandatory and one optional arguments. Optional argument is passed
as a key/value pair. The first argument is your PAUSE author ID, the
second argument is your PAUSE password.

### `use_http`

    my $pause = WWW::PAUSE::CleanUpHomeDir->new(
        'PAUSE_ID',
        'PAUSE_password',
        use_http => 1, # optional; by default uses HTTPS
    );

**Optional**. As of version 0.003, this module will use HTTPS protocol
when dealing with PAUSE. If you want to go back to using plain HTTP,
set `use_http` argument to a true value. **By default:** not specified
(i.e. will use HTTPS).

### `timeout`

    my $pause = WWW::PAUSE::CleanUpHomeDir->new(
        'PAUSE_ID',
        'PAUSE_password',
        timeout => 10, # optional; default is 30
    );

**Optional**. Specifies the `timeout` (in seconds) for dealing with PAUSE
and it will **default to** `30` if not specified.

# METHODS

## fetch\_list

    my $list_of_your_files_ref = $pause->fetch_list
        or die $pause->error;


    $VAR1 = {
        'Net-OBEX-Packet-Request-0.002.readme' => {
            'status' => 'Scheduled for deletion (due at Fri, 21 Mar 2008 02:42:37 GMT)',
            'size' => '871'
        },
        'Net-OBEX-Response-0.002.tar.gz' => {
            'status' => 'Sun, 02 Mar 2008 15:56:19 GMT',
            'size' => '7618'
        },
        'Net-OBEX-Response-0.002.readme' => {
            'status' => 'Sun, 02 Mar 2008 15:55:08 GMT',
            'size' => '834'
        },
    }

Takes no arguments. On failure returns either `undef` or an empty list
depending on the context and the reason for failure will be available via
`error()` method.
On success returns a hashref with keys being the files in your PAUSE home
dir and values being 2-key hashrefs with keys being `size` and `status`.
The `size` is the size of that particular file. The `status` will contain
the time of creation or _Scheduled for deletion..._  if the
file is scheduled for deletion.

## last\_list

    my $last_list_ref = $pause->last_list;

Must be called after a successful call to `fetch_list()` method.
Takes no arguments, returns the same hashref as last call to `fetch_list()`
returned.

## list\_scheduled

    my $scheduled_for_deletion_ref = $pause->list_scheduled
        or die $pause->error;

    my @scheduled_for_deletion = $pause->list_scheduled
        or die $pause->error;

Takes no arguments. If called prior to the call to `fetch_list()` will do
so automatically and if that fails will return either undef or an empty list
(depending on the context) and the reason for the failure will be available
via `error()` method.

In scalar context returns a hashref of all the files
which are scheduled for deletion. The format of that hashref is the same
as the return value of `fetch_list()` method (with the exception that
all `status` keys will contain _Scheduled for deletion.._). In list
context returns a sorted list of filenames which are scheduled for deletion.
In other words calling `list_scheduled()` in list context is the same
as doing `@scheduled = sort keys %{ scalar $pause->list_scheduled }`

## list\_old

    my $old_dists_ref = $pause->list_old
        or die $pause->error;

    my @old_dists = $pause->list_old
        or die $pause->error;

Takes no arguments. If called prior to the call to `fetch_list()` will do
so automatically and if that fails will return either undef or an empty list
(depending on the context) and the reason for the failure will be available
via `error()` method.

In list context returns a sorted list of **distributions** for
which the module sees newer versions. In scalar context returns a hashref
with keys being distribution names and values being the extensions of the
archive containing the distribution.

## clean\_up

    my $deleted_files_ref = $pause->clean_up
        or die $pause->error;

    my $deleted_files_ref = $pause->clean_up( [ qw(Dist1 Dist2 etc) ] )
        or die $pause->error;

Instructs the object to delete any distributions for which never versions
were found. In other words will delete distributions which `list_old()`
returns. On failure will return either `undef` or an empty list (depending
on the context) and the reason for failure will be available via `error()`
method. On success returns an arrayref of deleted **files** (archive
containing distribution, `.meta` files and `.readme` file). Takes one
optional argument which must be an arrayref containing names of
**distributions** to delete, if not specified will delete all distributions
for which never versions are available. **Note:** a call to this method
will reset the list stored in `last_list()`, it will be set to `undef`.
**Note 2:** if either the distribution you specified does no exist
(in your PAUSE home dir) or `.meta` or `.readme` files do not exist
the call will cause [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) to croak on you.

## deleted\_list

    my $last_deleted_files_ref = $pause->deleted_list;

Must be called after a successful call to `clean_up()`.
Takes no arguments, returns the same return value last call to `clean_up()`
returned.

## undelete

    my $undeleted_list_ref = $pause->undelete
        or die $pause->error;

    my $undeleted_list_ref = $pause->undelete( [ qw(Foo.tar.gz Foo.meta Foo.readme) ] )
        or die $pause->error;

Instructs the object to undelete certain files. On failure will return
either `undef` or an empty list (depending on the context) and the
reason for failure will be available via `error()` method. On success
returns an arrayref of files which were undeleted. Takes one optional
argument which must be an arrayref of files to undelete, if the argument
is not specified will use list stored in `deleted_list()`.
**Note:** a successful call to this method will reset list stored in
`deleted_list()`
but will **NOT** reset list stored in `last_list()`, which will be incorrect
after undeletion (well, only the `status` keys will present incorrect
status of the files).
**Note 2:** if either the file you specified does no exist
(in your PAUSE home dir) or files stored in `deleted_list()` do not exist
(later is unlikely) the call will cause [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) to croak on you.

## error

    my $last_error = $pause->error;

Takes no arguments, returns last error (if any) which occurred during
the calls to other methods.

# EXAMPLES

The `examples` directory of this distribution contains a script which
can be used for cleaning up your PAUSE home directory.

# SEE ALSO

[http://pause.perl.org](http://pause.perl.org)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WWW-PAUSE-CleanUpHomeDir](https://github.com/zoffixznet/WWW-PAUSE-CleanUpHomeDir)

<div>
    </div></div>
</div>

# BUGS AND CAVEATS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

I have only one PAUSE account which is inadequate for proper testing.
Double check the results to make sure the module works properly for you
when first using it.

To report bugs or request features, please use
[https://github.com/zoffixznet/WWW-PAUSE-CleanUpHomeDir/issues](https://github.com/zoffixznet/WWW-PAUSE-CleanUpHomeDir/issues)

If you can't access GitHub, you can email your request
to `bug-www-pause-cleanuphomedir at rt.cpan.org`

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

# CONTRIBUTORS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

- **Steven 'SHARYANTO' Haryanto** -- submitted a patch for correct version sorting
- **Olivier 'DOLMEN' Mengué** -- submitted bug report requesting HTTPS support

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
