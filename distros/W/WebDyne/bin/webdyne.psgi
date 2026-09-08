#!/usr/bin/env perl
#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#  Pragma
#
use strict;
use vars   qw($VERSION);
use warnings;
no warnings qw(once);


#  External modules
#
use Cwd qw(fastcwd);
use Data::Dumper;
use File::Basename;
use File::Spec;


#  Local customisation
#
local $Data::Dumper::Indent=1;
local $Data::Dumper::Sortkeys=1;


#  PSGI modules we need
#
use WebDyne::PSGI;
use WebDyne::Constant;
use WebDyne::PSGI::Constant;


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='3.028';


#  Check for supporting modules
#
BEGIN {
    my @missing;
    for my $module (qw(Plack)) {
        eval "require $module; 1" or push @missing, $module;
    }
    if (@missing) {
        printf STDERR ("Please install missing CPAN modules: %s \n", join(', ', @missing));
        exit 1;
    }
    
}


#  Called from command line ?
#
if (!caller || exists $ENV{PAR_TEMP}) {


    #  Yes. Get options
    #
    my %opt=(
        test    => 0,
        static  => 1,
        conf    => 1,
        index   => defined($ENV{'DOCUMENT_DEFAULT'}) ? $ENV{'DOCUMENT_DEFAULT'} : 0,
        %{do(glob(sprintf('~/.%s.opt', basename(__FILE__)))) || {}}
    );
    if (delete $opt{'no_index'}) {
        $opt{'index'}=0;
    }


    #  Process
    #
    require Getopt::Long;
    Getopt::Long::Configure('pass_through');
    @ARGV=grep {
        if ($_ eq '--no-index') {
            $opt{'index'}=0;
            0;
        }
        elsif (/^--index=(.*)$/) {
            $opt{'index'}=$1;
            0;
        }
        else {
            1;
        }
    } @ARGV;
    Getopt::Long::GetOptions(
        \%opt,
        my @opt=(
        'test!',
        'static!',
        'index!' => sub {
            my ($name, $value)=@_;
            $opt{'index'}=$value ? 1 : 0;
        },
        'no_index' => sub {
            $opt{'index'}=0
        },
        'view_source|view-source!',
        'root|docroot|doc_root|doc-root|document_root|document-root:s',
        'env|E=s',
        'argv:s',
        'dump_opt|dump-opt|opt'
        )
    );
    map {$opt{"no_${_}"} = $opt{$_} ? 0 : 1} map { /^([^|!:=+]+)/ } grep {!ref($_) && /\!$/} @opt;
    
    
    #  Last argument is root directory
    #
    if (@ARGV && $ARGV[-1] !~ /^--?/) {
        $opt{'root'} = pop @ARGV;
    }
    else {
        $opt{'root'} ||=($ENV{'DOCUMENT_ROOT'} ||  fastcwd());
    }


    #  Dump options for debugging
    #
    &view_source_apply(\%opt);
    die Dumper(\%opt) if $opt{'dump_opt'};
    
    
    #  Startup
    #
    exit &startup(\%opt, split(/\s+/, $opt{'argv'} || ''), @ARGV);

}
else {

    # No - called from psgi_server or starman. Need document root and doc default from 
    # env or var
    #
    my %opt=(
        root    => $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT || fastcwd(),
        index   => defined($ENV{'DOCUMENT_DEFAULT'})
            ? $ENV{'DOCUMENT_DEFAULT'}
            : defined($DOCUMENT_DEFAULT)
                ? $DOCUMENT_DEFAULT
                : 0,
        static  => 1,
        conf    => 1
    );
    return &build(\%opt);
    
}



#==================================================================================================


sub build {


    #  WebDyne::PSGI owns local config loading and middleware wrapping.
    #
    my $opt_hr=shift();
    return WebDyne::PSGI->new(%{$opt_hr})->to_app();

}


sub view_source_apply {


    #  Source viewing is an extra opt-in on top of built-in index handling.
    #
    my $opt_hr=shift();
    if ($opt_hr->{'index'} && $opt_hr->{'view_source'}) {
        $ENV{'WEBDYNE_INDEX_SOURCE_ENABLE'}=1;
        $WebDyne::WEBDYNE_INDEX_SOURCE_ENABLE=1;
        $WebDyne::Constant::Constant{'WEBDYNE_INDEX_SOURCE_ENABLE'}=1;
    }
    else {
        $opt_hr->{'view_source'}=0;
    }
    return \undef;

}


sub startup {


    #  Get WebDyne::PSGI options and Plack::Runner args
    #
    my ($opt_hr, @argv)=@_;
    
    
    #  Running from command line without being stared by plackup or starman
    #
    require Plack::Runner;
    my $plack_or=Plack::Runner->new();
    
    
    #  Environment/mode. The wrapper consumes -E/--env so that values can
    #  also come from ~/.webdyne.psgi.opt, then passes it on to the runner.
    #
    if (defined($opt_hr->{'env'})) {
        die "--env must be development, production, or none\n"
            unless $opt_hr->{'env'} =~ /^(?:development|production|none)$/;
        $ENV{'PLACK_ENV'}=$opt_hr->{'env'};
        push (@argv, ('--env', $opt_hr->{'env'}))
            unless grep { $_ eq '-E' || $_ eq '--env' || /^--env=/ } @argv;
    }
    

    #  Mac conflicts with Plack default port of 5000 - choose 5001
    #
    if (($^O eq 'darwin') && !(grep { /--port/ } @argv)) {
        $plack_or->parse_options('--port', '5001', @argv)
    }
    else {
        $plack_or->parse_options(map {split(/\s+/)} @argv);
    }
    

    #  Get app code ref from WebDyne::PSGI
    #
    my $app_cr=&build($opt_hr);

    
    #  Run it
    #
    #*PAGI::Runner::load_app=sub { return $app_cr };
    exit $plack_or->run($app_cr);

}


__END__

=begin markdown

# webdyne.psgi #

# NAME #

webdyne.psgi - PSGI application runner for WebDyne

# SYNOPSIS

`webdyne.psgi [--option] <document_root>`

`webdyne.psgi --port 8080 /var/www/html` 

`webdyne.psgi --test`

# DESCRIPTION

`webdyne.psgi` builds a `WebDyne::PSGI` application, applies configured Plack middleware, loads local WebDyne constants for the selected root, and runs the app through `Plack::Runner`.

# OPTIONS

`webdyne.psgi` parses a small set of wrapper options itself and passes remaining command line options through to `Plack::Runner`.

Wrapper defaults can be preloaded from `~/.webdyne.psgi.opt` by creating an anonymous hash of option names and values.

Wrapper options handled by `webdyne.psgi` itself:

* **--test**

    Use WebDyne's internal test page as the root.

* **--static**

    Enable or disable PSGI static-file middleware.

* **--index**

    Enable directory index handling. With no value, `--index` uses WebDyne's built-in dynamic index page. Index handling is disabled by default.

* **--index=FILE**

    Use `FILE` as the default document for directory requests instead of the built-in dynamic index page. Use the equals form so the document root argument is not consumed as the index value.

* **--view-source**

    Enable the built-in index page source viewer. This only takes effect when `--index` also enables WebDyne's built-in dynamic index page.

* **--no-index**

    Disable wrapper-managed index handling. This is the default unless `DOCUMENT_DEFAULT`, `~/.webdyne.psgi.opt`, or `--index` enables it.

* **--root**

    Set the document root. If omitted, the final non-option command line argument is used. If neither is supplied, `DOCUMENT_ROOT` or the current working directory is used.

* **--env**

    Set the PSGI/Plack environment mode to `development`, `production`, or `none`. The wrapper sets `PLACK_ENV` and forwards the mode to `Plack::Runner`.

* **--argv**

    Supply additional arguments that the wrapper prepends to the remaining command line arguments before invoking `Plack::Runner`.

* **--dump_opt**

    Dump the processed option hash and exit.

Remaining command line options are handled by `Plack::Runner` and are the same as described in the [plackup(1)](man:plackup(1)) man page. Refer to that page for full options but some common options are:

* **--host**

    Which host interface to bind to

* **--port**

    Which port to bind to

* **--server**

    Which server to use, e.g. Starman

* **--reload**

    Reload if libraries or other files change

* **-I**

    Same as perl -I for library include paths

* **-M**

    Same as perl -M for loading modules before the script starts

On macOS, if no `--port` option is passed through to `Plack::Runner`, the wrapper uses port `5001` to avoid conflicts with Plack's default port. Other platforms use the normal Plack default unless a port is supplied.


# EXAMPLES

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. With default settings, wrapper-managed index handling is disabled.

`webdyne.psgi /var/www/html`

Enable WebDyne's built-in dynamic index page for local development/debugging

`webdyne.psgi --index /var/www/html`

Enable the built-in index page source viewer as an additional local development/debugging aid

`webdyne.psgi --index --view-source /var/www/html`

Use `home.psp` as the default document for directory requests

`webdyne.psgi --index=home.psp /var/www/html`

Persist index handling for local development by adding it to `~/.webdyne.psgi.opt`

```perl
{
    index => 1,
}
```

Start in production mode

`webdyne.psgi --env production /var/www/html`

Start with the Starman server

`webdyne.psgi --no-default-middleware --server Starman /home/aspeer/public_html`

Start with the internal test page

`webdyne.psgi --test`

# ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne PSGI stack. In addition to `Plack::Runner` options, it uses WebDyne configuration and environment handling.

* **DOCUMENT_ROOT**

    Supplies the document root when neither `--root` nor a final non-option document root argument is provided.

* **DOCUMENT_DEFAULT**

    Supplies the default `index` value before `~/.webdyne.psgi.opt` and command-line options are applied. If unset, wrapper-managed index handling is disabled by default. Explicit CLI index options override the environment, and `~/.webdyne.psgi.opt` also overrides the environment. When the script is loaded by `plackup` or `starman` instead of run directly, the PSGI constant layer default is `app.psp` unless the wrapper supplies another value.

* **PLACK_ENV**

    Supplies the PSGI/Plack environment mode when `--env` is not provided.

* **WEBDYNE_***

    Supplies the relevant WebDyne settings used by the PSGI modules.

When the PSGI app is built, the wrapper also reads local WebDyne configuration from `DOCUMENT_ROOT/.webdyne.conf.pl`. This applies both when `webdyne.psgi` is launched directly and when it is loaded by an external PSGI server such as `plackup` or `starman`.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 webdyne.psgi


=head1 NAME

webdyne.psgi - PSGI application runner for WebDyne


=head1 SYNOPSIS

C<<< webdyne.psgi [--option] <document_root> >>>

C<webdyne.psgi --port 8080 /var/www/html> 

C<webdyne.psgi --test>


=head1 DESCRIPTION

C<webdyne.psgi> builds a C<WebDyne::PSGI> application, applies configured Plack middleware, loads local WebDyne constants for the selected root, and runs the app through C<Plack::Runner>.


=head1 OPTIONS

C<webdyne.psgi> parses a small set of wrapper options itself and passes remaining command line options through to C<Plack::Runner>.

Wrapper defaults can be preloaded from C<~/.webdyne.psgi.opt> by creating an anonymous hash of option names and values.

Wrapper options handled by C<webdyne.psgi> itself:

=over

=item *

B<--test>

Use WebDyne's internal test page as the root.



=item *

B<--static>

Enable or disable PSGI static-file middleware.



=item *

B<--index>

Enable directory index handling. With no value, C<--index> uses WebDyne's built-in dynamic index page. Index handling is disabled by default.



=item *

B<--index=FILE>

Use C<FILE> as the default document for directory requests instead of the built-in dynamic index page. Use the equals form so the document root argument is not consumed as the index value.



=item *

B<--view-source>

Enable the built-in index page source viewer. This only takes effect when C<--index> also enables WebDyne's built-in dynamic index page.



=item *

B<--no-index>

Disable wrapper-managed index handling. This is the default unless C<DOCUMENT_DEFAULT>, C<~/.webdyne.psgi.opt>, or C<--index> enables it.



=item *

B<--root>

Set the document root. If omitted, the final non-option command line argument is used. If neither is supplied, C<DOCUMENT_ROOT> or the current working directory is used.



=item *

B<--env>

Set the PSGI/Plack environment mode to C<development>, C<production>, or C<none>. The wrapper sets C<PLACK_ENV> and forwards the mode to C<Plack::Runner>.



=item *

B<--argv>

Supply additional arguments that the wrapper prepends to the remaining command line arguments before invoking C<Plack::Runner>.



=item *

B<--dump_opt>

Dump the processed option hash and exit.



=back

Remaining command line options are handled by C<Plack::Runner> and are the same as described in the L<plackup(1)|man:plackup(1)> man page. Refer to that page for full options but some common options are:

=over

=item *

B<--host>

Which host interface to bind to



=item *

B<--port>

Which port to bind to



=item *

B<--server>

Which server to use, e.g. Starman



=item *

B<--reload>

Reload if libraries or other files change



=item *

B<-I>

Same as perl -I for library include paths



=item *

B<-M>

Same as perl -M for loading modules before the script starts



=back

On macOS, if no C<--port> option is passed through to C<Plack::Runner>, the wrapper uses port C<5001> to avoid conflicts with Plack's default port. Other platforms use the normal Plack default unless a port is supplied.


=head1 EXAMPLES

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. With default settings, wrapper-managed index handling is disabled.

C<webdyne.psgi /var/www/html>

Enable WebDyne's built-in dynamic index page for local development/debugging

C<webdyne.psgi --index /var/www/html>

Enable the built-in index page source viewer as an additional local development/debugging aid

C<webdyne.psgi --index --view-source /var/www/html>

Use C<home.psp> as the default document for directory requests

C<webdyne.psgi --index=home.psp /var/www/html>

Persist index handling for local development by adding it to C<~/.webdyne.psgi.opt>


 {
     index => 1,
 }
Start in production mode

C<webdyne.psgi --env production /var/www/html>

Start with the Starman server

C<webdyne.psgi --no-default-middleware --server Starman /home/aspeer/public_html>

Start with the internal test page

C<webdyne.psgi --test>


=head1 ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne PSGI stack. In addition to C<Plack::Runner> options, it uses WebDyne configuration and environment handling.

=over

=item *

B<DOCUMENT_ROOT>

Supplies the document root when neither C<--root> nor a final non-option document root argument is provided.



=item *

B<DOCUMENT_DEFAULT>

Supplies the default C<index> value before C<~/.webdyne.psgi.opt> and command-line options are applied. If unset, wrapper-managed index handling is disabled by default. Explicit CLI index options override the environment, and C<~/.webdyne.psgi.opt> also overrides the environment. When the script is loaded by C<plackup> or C<starman> instead of run directly, the PSGI constant layer default is C<app.psp> unless the wrapper supplies another value.



=item *

B<PLACK_ENV>

Supplies the PSGI/Plack environment mode when C<--env> is not provided.



=item *

B<WEBDYNE_>*

Supplies the relevant WebDyne settings used by the PSGI modules.



=back

When the PSGI app is built, the wrapper also reads local WebDyne configuration from C<DOCUMENT_ROOT/.webdyne.conf.pl>. This applies both when C<webdyne.psgi> is launched directly and when it is loaded by an external PSGI server such as C<plackup> or C<starman>.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
