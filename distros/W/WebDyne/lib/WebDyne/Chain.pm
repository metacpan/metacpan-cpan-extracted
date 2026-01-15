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
package WebDyne::Chain;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#   WebDyne Modules.
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Chain::Constant;
use WebDyne::Util;


#  Other modules
#
use Data::Dumper;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='2.070';


#  Debug using WebDyne debug handler
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  Shortcut error handler, save using ISA;
#
require WebDyne::Err;
*err_html=\&WebDyne::Err::err_html || *err_html;


#  Package wide hash ref for data storage
#
my %Package;


#  Make all errors non-fatal
#
errnofatal(1);


#  And done
#
1;


#------------------------------------------------------------------------------


#  Packace init, attempt to load optional Time::HiRes module
#
BEGIN {
    eval {require Time::HiRes;    Time::HiRes->import('time')};
    eval {require Devel::Confess; Devel::Confess->import(qw(no_warnings))};
}


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my ($class, @import)=@_;
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->()                             || return;
    $self->set_handler($class);
    my $meta_hr=$self->meta();
    push @{$meta_hr->{'webdynechain'}}, @import;


}


sub handler : method {


    #  Get class, request object
    #
    my ($self, $r, $param_hr)=@_;
    my $class=ref($self) || do {


        #  Need new self ref
        #
        my %self=(

            _time => time(),
            _r    => $r,
            %{delete $self->{'_self'}},

        );
        $self=bless \%self, $self;
        ref($self);


    };


    #  Setup error handlers
    #
    local $SIG{__DIE__}=sub  {return $self->err_html(@_)};
    local $SIG{__WARN__}=sub {return $self->err_html(@_)}
        if $WEBDYNE_WARNINGS_FATAL;


    #  Debug
    #
    debug(
        "in WebDyne::Chain::handler, class $class, r $r, self $self, param_hr %s",
        Dumper($param_hr));


    #  Log URI
    #
    debug("URI %s", $r->uri());


    #  Get string of modules to chain
    #
    my @module;
    if (my $module_ar=$param_hr->{'meta'}{'webdynechain'}) {
        debug("using module_ar $module_ar %s from meta", Dumper($module_ar));
        @module=@{$module_ar};
    }
    elsif (my $module=$r->dir_config('WebDyneChain')) {
        debug("using module $module dir_config");
        @module=split(/\s+/, $module);
    }
    else {
        debug('could not find any module chain info');
    }
    debug('module: %s', Dumper(\@module));



    #  WebDyne::Chain must be the first handler in line, Webdyne the last
    #
    unshift @module, __PACKAGE__ unless ($module[0] eq +__PACKAGE__);
    push @module, 'WebDyne' unless ($module[$#module] eq 'WebDyne');
    debug('final module chain %s', join('*', @module));


    #  Store current chain
    #
    $Package{'_chain_ar'}=\@module;


    #  If only two modules (WebDyne::Chain, WebDyne) something is wrong
    #
    if (@module == 2) {
        return
            $self->err_html('unable to determine module chain - have you set WebDyneChain var ?');
    }


    #  Get location. Used to use r->location, now use module array to generate pseudo
    #  location data;
    #
    my $location=join(undef, @module);
    debug("location $location");
    unless ($Package{'_chain_loaded_hr'}{$location}++) {
        debug("modules not loaded, doing now");
        local $SIG{'__DIE__'};
        foreach my $package (@module) {
            eval("require $package") ||
                return $self->err_html("unable to load package $package, " . lcfirst($@));
            debug("loaded $package");
        }
    }


    #  If location not same as last time we were run, then unload chain
    #
    if ((my $location_current=$Package{'_location_current'}) ne $location) {


        #  Need to unload cached code refs
        #
        debug("location_current '$location_current' is ne this location ('$location'). restoring cr's");
        &ISA_restore();


        #  Update location
        #
        $Package{'_location_current'}=$location;


        #  If code ref's cached, load up now
        #
        if (my $chain_hr=$Package{'_chain_hr'}{$location}) {


            #  Debug
            #
            debug("found cached code ref's for location $location loading");


            #  Yes found, load up
            #
            while (my ($method, $cr)=each %{$chain_hr}) {


                #  Debug
                #
                debug("loading cr $cr for method $method");


                #  Install code ref
                #
                *{$method}=$cr;

            }


            #  Update current pointer
            #
            $Package{'_chain_current_hr'}=$chain_hr;


        }
    }
    else {

        debug('location chain same as last request, caching');

    }


    #  Debug
    #
    debug('module array %s', Dumper(\@module));


    #  All done, pass onto next handler in chain. NOTE no error handler (eg || $self->err_html). It is
    #  not our job to check for errors here, we should just pass back whatever the next handler does.
    #
    return $self->SUPER::handler($r, @_[2..$#_]);


    #  Only get here if error handler invoked
    #
    RENDER_ERROR:
    return $self->err_html();


    #  Only get here if subrequest invoked.
    HANDLER_COMPLETE:
    return $MP2 ? &Apache::OK : HTTP_OK;


}


sub ISA_restore {


    #  Get cuurent chain hash
    #
    my $chain_hr=delete $Package{'_chain_current_hr'};
    debug('in ISA_restore, chain %s', Dumper($chain_hr));


    #  Go through each module, restoring
    #
    foreach my $method (keys %{$chain_hr}) {


        #  Free up
        #
        debug("free $method");
        undef *{$method};


    }


}


sub DESTROY {


    #  Get chain array ref
    #
    my $self=shift();
    my $chain_ar=$Package{'_chain_ar'};
    debug("self $self, going through DESTROY chain %s", Dumper($chain_ar));


    #  Handle destroys specially, mini version of AUTOLOAD code below
    #
    foreach my $i (1..$#{$chain_ar}) {
        my $package_chain=$chain_ar->[$i];
        debug("looking for DESTROY $package_chain");
        if (my $cr=UNIVERSAL::can($package_chain, 'DESTROY')) {
            debug("DESTROY hit on $package_chain");
            $cr->($self);
        }
    }


    #  Destroy object
    #
    %{$self}=();
    undef $self;


}


sub UNIVERSAL::AUTOLOAD {


    #  Get self ref, calling class, autoloaded method
    #
    my $self=$_[0];
    my $autoload=$UNIVERSAL::AUTOLOAD || return;


    #  Do not handle DESTROY's
    #
    return if $autoload=~/::DESTROY$/;


    #  Debug
    #
    debug(
        "in UNIVERSAL::AUTOLOAD, self $self, autoload $autoload, caller %s",
        Dumper([(caller(1))[0..3]]));


    #  Get apache request ref, location. If not present means called by non-WebDyne class, not supported
    #
    my $r; {
        local $SIG{'__DIE__'}=undef;

        #unless (eval{ ref($self) && ($r=$self->{'_r'}) }) {
        unless (eval {ref($self) && ($r=$self->{'_r'})} || UNIVERSAL::can($self, $autoload)) {
                err ("call to run %s UNIVERSAL::AUTOLOAD for non chained method '$autoload', self ref '$self'.", +__PACKAGE__);
            goto RENDER_ERROR;
        }
    }


    #  Get method user was looking for, keep full package name.
    #
    my ($package_autoload, $method_autoload)=($autoload=~/(.*)::(.*?)$/);
    debug("package_autoload $package_autoload, method_autoload $method_autoload");


    #  And chain for this location
    #
    my $chain_ar=$Package{'_chain_ar'};
    my $location=join(undef, @{$chain_ar});
    debug('going through chain %s', Dumper($chain_ar));


    #  Caller information
    #
    my $subroutine_caller=(caller(1))[3];
    my $subroutine_caller_cr=\&{"$subroutine_caller"};
    my ($package_caller, $method_caller)=($subroutine_caller=~/(.*)::(.*?)$/);
    debug("package_caller $package_caller, method_caller $method_caller");


    #  If SUPER method trawl through chain to find the package it was called from, make sure we start
    #  from there in iteration code below
    #
    my $i=0;
    if ($autoload=~/\QSUPER::$method_autoload\E$/) {
        debug("SUPER method");
        for (1; $i < @{$chain_ar}; $i++) {
            if (UNIVERSAL::can($chain_ar->[$i], $method_caller) eq $subroutine_caller_cr) {
                $i++;
                last;
            }
            else {
                debug("miss on package $chain_ar->[$i], $_ ne $subroutine_caller_cr");
            }
        }
        debug("loop finished, i $i, chain_ar %s", $#{$chain_ar});
    }


    #  Iterate through the chain (in order) looking for the method
    #
    foreach $i ($i..$#{$chain_ar}) {


        #  Can this package in the chain support the calling method ?
        #
        debug("look for $method_autoload in package $chain_ar->[$i]");
        if (my $cr=UNIVERSAL::can($chain_ar->[$i], $method_autoload)) {


            #  Yes. Check for loops
            #
            if ($cr eq $subroutine_caller_cr) {
                    err (
                    "detected AUTOLOAD loop for method '$method_autoload' " .
                    "package $package_caller. Current chain: %s", join(', ', @{$chain_ar}));
                goto RENDER_ERROR;
            }


            #  Update
            #
            debug('hit');
            *{$autoload}=$cr;


            #  And keep a record
            #
            $Package{'_chain_hr'}{$location}{$autoload}=$cr;
            $Package{'_chain_current_hr'} ||= $Package{'_chain_hr'}{$location};


            #  And dispatch. The commented out code is good for debugging internal
            #  server errors, esp if comment out *{$autoload} above and turn on
            #  debugging
            #
            goto &{$cr};

        }
        else {


            #  Debug
            #
            debug("unable to find method $method_autoload in package $chain_ar->[$i]");

        }

    }


    #  Last resort - look back through call chain
    #
    debug("checking back through callstack for method $method_autoload");
    my %chain=map {$_ => 1} @{$chain_ar};
    my @caller;
    for ($i=0; my $caller=(caller($i))[0]; $i++) {
        next if $chain{$caller}++;    #already looked there
        push @caller, $caller;
        if (my $cr=UNIVERSAL::can($caller, $method_autoload)) {
            if ($cr eq $subroutine_caller_cr) {
                    err (
                    "detected AUTOLOAD loop for method '$method_autoload' " .
                    "package $package_caller. Current chain: %s", join(', ', @{$chain_ar}));
                goto RENDER_ERROR;
            }
            if ($WEBDYNE_AUTOLOAD_POLLUTE) {
                *{$autoload}=$cr;
                $Package{'_chain_hr'}{$location}{$autoload}=$cr;
            }
            goto &{$cr}
        }
    }


    #  Return err
    #
    err ("method '$method_autoload' not found in call chain: %s", join(',', @caller));
    goto RENDER_ERROR;

}
1;

__END__

=pod

=head1 WebDyne::Chain.pm(3pm)

=head1 NAME

WebDyne::Chain - WebDyne chaining module, allows extension of base WebDyne handler pipeline with additional modules.

=head1 SYNOPSIS

SYNOPSIS

    #  Basic usage. Save as file named chain.psp:
    #
    <start_html>
    Server local time is: <? localtime ?>
    __PERL__
    use WebDyne::Chain qw(WebDyne::Session)

    #  Render with wdrender. Note the session variable
    #
    $ wdrender --header ./chain.psp
    Status: 200
    X-Frame-Options: SAMEORIGIN
    Pragma: no-cache
    Cache-Control: no-cache, no-store, must-revalidate
    Expires: 0
    Content-Type: text/html; charset=UTF-8
    Set-cookie: session=3653dbc88d665db9a4bfabf27a01310c; path=/
    X-Content-Type-Options: nosniff
    Content-Length: 242
    
    <!DOCTYPE html><html lang="en"><head><title>Untitled Document</title><meta charset="UTF-8"><meta content="width=device-width, initial-scale=1.0" name="viewport"></head>
    <body><p>Server local time is: Sun Dec  7 21:56:17 2025</p></body></html>

    # Or extend manually from command line for testing. Does not require use of WebDyne::Chain
    # in page.
    #
    $ WebDyneChain=WebDyne::Session wdrender --header --handler WebDyne::Chain time.psp 

=head1 DESCRIPTION

WebDyne::Chain allows chaining of modules within the WebDyne pipeline. This allows custom modules to insert themselves into the server handler pipeline, whereby they can make changes to the input or output of WebDyne pages. Common uses may include:

=over

=item * Setting or getting session tracking data

=item * Checking for authentication status and redirecting if not valid

=item * Rewriting input URL's or parameters, or rewriting output HTML

=item * Tracking user state from a database connection

=back

WebDyne includes two example Chain modules in the base package:

=over

=item * B<<< WebDyne::Session >>>

Sets/gets a session cookie in the headers

=item * B<<< WebDyne::Filter >>>

Rewrite Request or Response headers, HTML content

=back

=head1 USAGE

WebDyne::Chain allows nomination of modules to chain in a psp page via the import method when using the module. At it's simplest you can import just the modules you want.

    <start_html>
    Server local time is <? localtime ?>
    __PERL__
    use WebDyne::Chain qw(WebDyne::Session WebDyne::State);
    1;

WebDyne::Chain will automatically add any methods made available by the chained modules into the page, e.g.

    <start_html>
    Session ID is: <? shift()->session_id() ?>
    __PERL__
    #  WebDyne::Session exposes the session_id() method used above
    #
    use WebDyne::Chain qw(WebDyne::Session);

In reality most modules that can be loaded by WebDyne::Chain will work when loaded standalone, e.g. the code below is the equivalent to loading WebDyne::Session via WebDyne::Chain:

    <start_html>
    Session ID is: <? shift()->session_id() ?>
    __PERL__
    #  Will autoload WebDyne::Chain and add itself into the handler pipeline
    #
    use WebDyne::Session;

=head1 METHODS

WebDyne::Chain does not expose any public methods

=head1 OPTIONS

WebDyne::Chain does not expose any options other than the names of modules to add to the handler chain via the import() method on module use - as seen in the Usage section above.

=head1 AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut