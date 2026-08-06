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
use Plack::Builder;
use WebDyne::PSGI;
use WebDyne::Constant;
use WebDyne::PSGI::Constant;


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='3.009';


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
        index   => defined($ENV{'DOCUMENT_DEFAULT'}) ? $ENV{'DOCUMENT_DEFAULT'} : 1,
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
        'root|docroot|doc_root|doc-root|document_root|document-root:s',
        'env|E=s',
        'argv:s',
        'dump_opt|dump-opt|opt'
        )
    );
    map {$opt{"no_${_}"} = !($opt{$_})} map { /^([^|!:=+]+)/ } grep {!ref($_) && /\!$/} @opt;
    
    
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
        index   => $ENV{'DOCUMENT_DEFAULT'} || $DOCUMENT_DEFAULT
    );
    return &build(\%opt);
    
}



#==================================================================================================


sub build {


    #  Build app code ref, options passed for builder
    #
    my $opt_hr=shift();


    #  Read in local webdyne.conf.pl before middleware and app setup so
    #  wrapper and external server loading use the same root config.
    #
    &local_constant_load($opt_hr->{'root'});


    my $builder_or=Plack::Builder->new();
    
    
    #  Adjust static service config var based on opts if
    #  they exist
    #
    if (exists($opt_hr->{'static'})) {
        $WEBDYNE_PSGI_STATIC=$opt_hr->{'static'};
    }
    
    
    #  Add in any middleware in config file
    #
    foreach my $middleware_ar (@{$WEBDYNE_PSGI_MIDDLEWARE}) {
        my ($middleware, $middleware_opt_hr)=@{$middleware_ar};
        
        #  Skip static if not wanted
        #
        if ($middleware eq 'Static') {
            next unless $WEBDYNE_PSGI_STATIC;
        }
        
        
        #  And code refs are run and given opt as first param
        #
        if (ref($middleware_opt_hr) eq 'CODE') {
            $middleware_opt_hr=$middleware_opt_hr->($opt_hr);
        }
        
        
        #  Now add it
        #
        $builder_or->add_middleware($middleware, %{$middleware_opt_hr});
    }
    

    #  Read in local webdyne.conf.pl
    #
    #&local_constant_load($opt_hr->{'root'});


    #  Finally return as app code ref
    #
    return $builder_or->to_app(
        WebDyne::PSGI->new(%{$opt_hr})->to_app())

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


sub local_constant_load {


    #  Read in local webdyne.conf.pl
    #
    my $root_dn=shift();
    
    
    #  If root_dn is a file get dir name
    #
    if (-f $root_dn) {
        $root_dn=(File::Spec->splitpath($root_dn))[1];
    }
    WebDyne::Constant->import(File::Spec->catfile($root_dn, sprintf('.%s', $WEBDYNE_CONF_FN)));

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

    Enable or disable directory index handling. With the default enabled setting, `--index` uses WebDyne's built-in dynamic index page.

* **--index=FILE**

    Use `FILE` as the default document for directory requests instead of the built-in dynamic index page. Use the equals form so the document root argument is not consumed as the index value.

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

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. With default settings, index handling is enabled and the wrapper uses WebDyne's built-in dynamic index page.

`webdyne.psgi /var/www/html`

Disable wrapper-managed index handling and rely on the PSGI request layer's default document behaviour instead

`webdyne.psgi --no-index /var/www/html`

Use `home.psp` as the default document for directory requests

`webdyne.psgi --index=home.psp /var/www/html`

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

    Supplies the default `index` value before `~/.webdyne.psgi.opt` and command-line options are applied. This means explicit CLI index options override the environment, and `~/.webdyne.psgi.opt` also overrides the environment. When the script is loaded by `plackup` or `starman` instead of run directly, the PSGI constant layer default is `app.psp`.

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

Enable or disable directory index handling. With the default enabled setting, C<--index> uses WebDyne's built-in dynamic index page.



=item *

B<--index=FILE>

Use C<FILE> as the default document for directory requests instead of the built-in dynamic index page. Use the equals form so the document root argument is not consumed as the index value.



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

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. With default settings, index handling is enabled and the wrapper uses WebDyne's built-in dynamic index page.

C<webdyne.psgi /var/www/html>

Disable wrapper-managed index handling and rely on the PSGI request layer's default document behaviour instead

C<webdyne.psgi --no-index /var/www/html>

Use C<home.psp> as the default document for directory requests

C<webdyne.psgi --index=home.psp /var/www/html>

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

Supplies the default C<index> value before C<~/.webdyne.psgi.opt> and command-line options are applied. This means explicit CLI index options override the environment, and C<~/.webdyne.psgi.opt> also overrides the environment. When the script is loaded by C<plackup> or C<starman> instead of run directly, the PSGI constant layer default is C<app.psp>.



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
