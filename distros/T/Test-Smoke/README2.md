# NAME

configsmoke - Explain the options during configuration.

# VERSION

This is version: **0.094**

# SYNOPSIS

Software installed in `~/perl5coresmoke/smoke`

    $ cd ~/perl5coresmoke 
    $ mkdir etc
    $ cd etc
    $ ../smoke/tsconfigsmoke.pl -c <prefix>

or on MSWin32 (installed in `%HOMEDRIVE%%HOMEPATH%\perl5coresmoke\smoke`):

    %HOMEDRIVE%
    cd %HOMEPATH%\perl5coresmoke
    md etc
    cd etc
    ..\smoke\tsconfigsmoke.bat -c <prefix>

# OPTIONS

    --config|-c <prefix> Set the prefix for all related files

    --des                Use all default settings, no questions asked

    --help|-h            The short help for options
    --show-config        Show the current values for these options

# DESCRIPTION

_Welcome to the Perl5 core smoke suite._

**Test::Smoke** is the symbolic name for a set of scripts and modules
that try to run the perl core tests on as many configurations as possible
and combine the results into an easy to read report.

The main script is `tssmokeperl.pl`, and this uses a configuration file
that is created by this program (`tsconfigsmoke.pl`).  There is no default
configuration as some actions can be rather destructive, so you will need
to create your own configuration by running this program!

By default the configuration file created is called `smokecurrent_config`,
this can be changed by specifying the `-c <prefix>` switch at the command
line.

    $ perl ../smoke/configsmoke.pl -c mysmoke

will create `mysmoke_config` (in the current directory) as the configuration
file and use `mysmoke` as prefix for related files.

The configfile is written with [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper), so it is a bit of Perl that
will be put through `eval()` when read back for use.

After you are done configuring, a job command list (JCL) is written. For
MSWin32 this is called `<prefix>.cmd`, for VMS this is called `<prefix>.COM`, otherwise this is called `<prefix>.sh`.

All output (stdout, stderr) from `tssmokeperl.pl` and its sub-processes is
redirected to a logfile called `<prefix>.log` by the JCL.

This is a new version of the configure script, SOME THINGS ARE DIFFERENT!

You will be asked some questions in order to configure this smoke suite.
Please make sure to read the documentation "perldoc configsmoke"
in case you do not understand a question.

    * Values in angled-brackets (<>) are alternatives (none other allowed)
    * Values in square-brackets ([]) are default values (<Enter> confirms)
    * Use single space to clear a value
    * Answer '&-d' to continue with all default answers

## ddir

`ddir` is the destination directory. This is used to put the
source-tree in and build perl. If a source-tree appears to be there
you will need to confirm your choice.

## w32args

For MSWin32 we need some extra information that is passed to
[Test::Smoke::Smoker](https://metacpan.org/pod/Test%3A%3ASmoke%3A%3ASmoker) in order to compensate for the lack of
**Configure**.

Items involved:

- **w32cc**: This is the `CCTYPE` (_GCC|MSVC|BORLAND_)
- **w32make**: This is the `make` program (_gmake|nmake_)
- **w32args**: Arrayref with:
    - **--win32-cctype**, `w32cc`
    - **--win32-maker**, `w32make`
    - `osvers=$osvers`
    - `ccversarg`

See also ["Configure\_win32( )" in Test::Smoke::Util](https://metacpan.org/pod/Test%3A%3ASmoke%3A%3AUtil#Configure_win32) and [tsw32configure.pl](https://metacpan.org/pod/tsw32configure.pl)

## sync\_type

We have dropped support for the sync\_types: **snapshot** and **hardlink**.

`sync_type` can be one of three:

- **git** (preferred)

    This will use the `git` program to clone the master perl-source from GitHub
    into **gitdir** (the master can be changed **gitorigin**). For the actual smoking, yet
    another clone into **ddir** is used.

    Items involved:

    - **gitbin**: Absolute location of the `git` program.
    - **gitorigin**: The origin of the Perl5 source tree
    (_https://github.com/Perl/perl5.git_).
    - **gitdir**: Absolute location for the main clone of **gitorigin**
    (_perl-from-git_).
    - **gitdfbranch**: The branch in the repository to smoke (_blead_).
    - **gitbranchfile**: Absolute location of the file that can hold the name of the
    branch to actually smoke (_&lt;prefix>.gitbranch_).

- **rsync**

    This will use the `rsync` program to sync up with the repository.
    `tsconfigsmoke.pl` checks to see if it can find **rsync** in your path.

    The default switches (**opts**) passed to **rsync** are: **-az --delete**

    Items involved:

    - **rsync**: Absolute location of the `rsync` program.
    - **opts**: Options to pass to **rsync** (_-az --delete_).
    - **source**: Hostname:port/directory of the source
    (_rsync://dromedary.p5h.org:5872/perl-current/_)

- copy

    This will use **File::Copy** and **File::Find** to just copy from a
    local source directory (**cdir**).

    Items involved:

    - **cdir**: Absolute location of the source tree on the local system.

See also [Test::Smoke::Syncer](https://metacpan.org/pod/Test%3A%3ASmoke%3A%3ASyncer)

## make finetuning

Two different config options to accomodate the same thing:
_parallel build_ and _serial testing_

- **makeopt**: used by Test::Smoke::Smoker::\_make()
- **testmake**: Use a different binary for "make \_test"

## harnessonly

`harnessonly` indicates that `make test` is replaced by `make
test_harness`.

## harness3opts

`harness3opts` are passed to `HARNESS_OPTIONS` for the `make
test_harness` step.

## force\_c\_locale

`force_c_locale` is passed as a switch to `tsrunsmoke.pl` to indicate that
`$ENV{LC_ALL}` should be forced to "C" during **make test**.

## defaultenv

`defaultenv`, when set will make `tsrunsmoke.pl` remove $ENV{PERLIO} and
only do a single pass `make test`.

## perlio\_only

`perlio_only`, when set wil not run the tests with `$ENV{PERLIO}=stdio`
and only with `$ENV{PERLIO}=perlio` (and with locale-setting if set).

## locale

`locale` and its value are passed to `tsrunsmoke.pl` and its value is passed
to `tsreporter.pl`. `tsrunsmoke.pl` will do an extra pass of **make test** with
`$ENV{LC_ALL}` set to that locale (and `$ENV{PERL_UNICODE}="";`,
`$ENV{PERLIO}=perlio`). This feature should only be used with
UTF8 locales, that is why this is checked (by regex only).

**If you know of a way to get the utf8 locales on your system, which is
not covered here, please let me know!**

## skip\_tests

This is a MANIFEST-like file with the paths to tests that should be
skipped for this smoke.

The process involves on the fly modification of `MANIFEST` for tests
in `lib/` and `ext/` and renaming of core-tests in `t/`.

## smokedb\_url

Instead of flooding a mailing list, reposts should be sent to the Perl5CoreSmokeDB.
The option to mail yourself a copy of the report still exists. The Perl5CoreSmokeDB
however offers a central point of view to the smoke results.

Items involved:

- **smokedb\_url**: Where to post the report (_https://perl5.test-smoke.org/report_).
- **send\_log**: Can be one of _always|on\_fail|never_ (_on\_fail_).
- **send\_out**: Can be one of _always|on\_fail|never_ (_never_).

## mail

The (boolean) option `mail` is used to see if the report is send via mail.

Items involved:

- **mail\_type**: Can be one of:
_sendmail|mail|mailx|sendemail|Mail::Sendmail|MIME::Lite_ depending on which
of these is available.

    See [Test::Smoke::Mailer](https://metacpan.org/pod/Test%3A%3ASmoke%3A%3AMailer).

- **to**: Email address to send the report to.
- **cc**: Email address to send a carbon copy of the report to.
- **bcc**: Email address to send a blind carbon copy of the report to.
- **ccp5p\_onfail**: Boolean to indicate if this report should be send to the
perl5porters mailing list, please don't do that (unless they ask for it).
- **mailbin**: Absolute location of the `mail` program is set as **mailt\_ype**.
- **mailxbin**: Absolute location of the `mailx` program if set as **mail\_type**.
    - **swcc**: `mailx` command line switch for the CC email address (_-c_).
    - **swbcc**: `mailx` command line switch for the BCC email address (_-b_).
- **sendemailbin**: Absolute location of the `sendemail` program if set as **mail\_type**.
    - **from**: Email address to use in FROM.
    - **mserver**: The hostname of the SMTP server to use (_localhost_).
    - **msport**: The port on that host the SMTP servers uses (_25_).
    - **msuser**: The username for authenticating with the SMTP server.
    - **mspass**: The password for authenticating with the SMTP server.
- **sendmailbin**: Absolute location of the `sendmail` program if set as **mail\_type**.

    Extra options: **from**

- mail\_type: Mail::Sendmail

    Extra options: **from|mserver|msport**

- mail\_type: MIME::Lite

    Extra options: **from|mserver|msport|msuser|mspass**

## Various files/directories

This section only handles the **adir** option interactively, but more options are set.

- **adir**: Absolute location to use as a base for the archive of reports and
other files, leave empty for no archiving. We archive **outfile**, **rptfile**,
**jsnfile** and **logfile**.
- **outfile**: The file that holds all information to create the report (_mktest.out_).
- **rptfile**: The report that is generated at the end of the run (_mktest.rpt_).
- **jsnfile**: The json that will be send to the Perl5CoreSmokeDB (_mktest.jsn_).
- **lfile**: Absolute location of the logfile (_&lt;prefix>.log_).

## hostname

By default we use the hostname reported by [System::Info](https://metacpan.org/pod/System%3A%3AInfo), but this can be changed here.

## un\_file

One can add a usernote to the report, this usernote is kept in a file (_&lt;prefix>.usernote_).

If the file does not exist, it will be created.

## un\_position

This is the position (_top|bottom_) where the usernote is inserted into the
report (_bottom_).

## cronbin

On unix-like systems we will check for the `crontab` program, on MSWin32 we
will check for either the `schtasks.exe` or `at.exe` program.

- **crontab**

    For `crontab` we read the current entries and if we find ourselfs (the JCL) we
    will comment that line out and add a new line.

- **schtasks.exe**

    For `schtasks` we query the scheduler to see if our TaskName is already in the
    schedule and if so we will add the `/F` command line switch to override the
    current entry.

    One can find the scheduled task by name: _P5Smoke-&lt;prefix>_ or a general
    `schtasks /query | find "P5Smoke-"`

- **at.exe**

    Microsoft has removed `at.exe` from Windows 10+ so we can no longer really
    maintain this feature and `schtasks.exe` is preferred.

## crontime

This is a `HH::MM` formated time.

## v

This option indicates the verbosity towards the logfile (**lfile**) and can be
set to: _0|1|2_, the default is _1_.

## smartsmoke

`smartsmoke` indicates that the smoke need not happen if the patchlevel (git
commit sha) is the same after syncing the source-tree.

## killtime

When `$Config{d_alarm}` is found we can use `alarm()` to abort
long running smokes. Leave this value empty to keep the old behaviour.

     07:30 => F<tssmokeperl.pl> is aborted at 7:30 localtime
    +23:45 => F<tssmokeperl.pl> is aborted after 23 hours and 45 minutes

Thank you Jarkko for donating this suggestion.

## umask

`umask` will be set in the shell-script that starts the smoke.

## renice

`renice` will add a line in the shell-script that starts the smoke.

## PERL5LIB

If you have a value for PERL5LIB set in the config environment, you
could have it transferred to the JCL. Do not bother
asking if it is not there.

## PERL5OPT

If you have a value for PERL5OPT set in the config environment, you
could have it transferred tho the JCL. Do not bother
asking if it is not there.

## cfg

`cfg` is the path to the file that holds the build-configurations.
There are several build-cfg files provided with the distribution:

- `perlcurrent.cfg`: for the blead-branch on unixy systems
- `w32current.cfg`: for the blead-branch on MSWin32
- `vmsperl.cfg`: for the blead-branch on OpenVMS

One of these files is used as the default build configurations file, depending
on the OS one is on.

# COMMAND LINE OPTIONS `Makefile.PL`

## --site-lib

This will leave the `PREFIX` and `INSTALLSITESCRIPT` as-is and install as a
regular Perl module.

# ENVIRONMENT VARIABLES

These change the behaviour of `Makefile.PL`:

## SMOKE\_INST\_DIR

Sets `PREFIX` and `INSTALLSITESCRIPT` to this directory

## SMOKE\_INST\_SITE\_LIB

When true, will leave `PREFIX` and `INSTALLSITESCRIPT` as is, and install as
a regular Perl module. No questions asked

## PERL\_MM\_OPT

This may contain `INSTALL_BASE=` that needs to be honoured.

## AUTOMATED\_TESTING

When true, will not ask for the installation dir and use whatever default is in
place.

# COPYRIGHT

© MMII - MMXXIII Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

- [http://www.perl.com/perl/misc/Artistic.html](http://www.perl.com/perl/misc/Artistic.html)
- [http://www.gnu.org/copyleft/gpl.html](http://www.gnu.org/copyleft/gpl.html)

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
