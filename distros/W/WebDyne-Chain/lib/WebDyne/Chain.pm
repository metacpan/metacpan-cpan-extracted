#
#
#  Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>.
#  All rights reserved.
#
#  This file is part of WebDyne::Chain.
#
#  WebDyne::Chain is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
package WebDyne::Chain;


#  Compiler Pragma
#
sub BEGIN	{ $^W=0 };
use strict	qw(vars);
use vars	qw($VERSION);
use warnings;
no  warnings	qw(uninitialized);


#  Webmod, WebDyne Modules.
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Chain::Constant;
use WebDyne::Base;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.050';


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


sub handler : method {


    #  Get class, request object
    #
    my ($self, $r, $param_hr)=@_;
    my $class=ref($self) || do {


	#  Need new self ref
	#
	my %self=(

	    _time	    =>  time(),
	    _r		    =>	$r,
	    %{delete $self->{'_self'}},

	   );
	$self=bless \%self, $self;
	ref($self);


    };


    #  Setup error handlers
    #
    local $SIG{__DIE__} =sub { return $self->err_html(@_) };
    local $SIG{__WARN__}=sub { return $self->err_html(@_) } if $WEBDYNE_WARNINGS_FATAL;


    #  Debug
    #
    debug("in WebDyne::Chain::handler, class $class, r $r, self $self, param_hr %s",
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


    #  WebDyne::Chain must be the first handler in line, Webdyne the last
    #
    unshift @module, __PACKAGE__ unless ($module[0] eq +__PACKAGE__);
    push    @module, 'WebDyne'   unless ($module[$#module] eq 'WebDyne');
    debug('final module chain %s', join('*', @module));


    #  Store current chain
    #
    $Package{'_chain_ar'}=\@module;


    #  If only two modules (WebDyne::Chain, WebDyne) something is wrong
    #
    if (@module==2) {
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
		return $self->err_html("unable to load package $package, ".lcfirst($@));
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
	    while (my($method,$cr)=each %{$chain_hr}) {


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
    return &Apache::OK;


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
    foreach my $i (1 .. $#{$chain_ar}) {
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
    debug("in UNIVERSAL::AUTOLOAD, self $self, autoload $autoload, caller %s",
	  Dumper([(caller(1))[0..3]]));


    #  Get apache request ref, location. If not present means called by non-WebDyne class, not supported
    #
    my $r; {
	local $SIG{'__DIE__'}=undef;
	unless (eval{ ref($self) && ($r=$self->{'_r'}) }) {
	    err("call to run %s UNIVERSAL::AUTOLOAD for non chained method '$autoload', self ref '$self'.", +__PACKAGE__);
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
    foreach $i ($i .. $#{$chain_ar}) {


	#  Can this package in the chain support the calling method ?
	#
	debug("look for $method_autoload in package $chain_ar->[$i]");
	if (my $cr=UNIVERSAL::can($chain_ar->[$i], $method_autoload)) {


	    #  Yes. Check for loops
	    #
	    if ($cr eq $subroutine_caller_cr) {
		err("detected AUTOLOAD loop for method '$method_autoload' ".
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
    my %chain=map { $_=> 1} @{$chain_ar};
    my @caller;
    for ($i=0; my $caller=(caller($i))[0]; $i++) {
	next if $chain{$caller}++; #already looked there 
	push @caller, $caller;
	if (my $cr=UNIVERSAL::can($caller, $method_autoload)) {
 	    if ($cr eq $subroutine_caller_cr) {
 		err("detected AUTOLOAD loop for method '$method_autoload' ".
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
    err("method '$method_autoload' not found in call chain: %s", join(',', @caller));
    goto RENDER_ERROR;

}

__END__

=head1 Name

WebDyne::Chain - WebDyne chaining module, allows extension of base WebDyne class

=head1 Description

WebDyne::Chain is a module that allows extension of the base WebDyne class with other modules, such as WebDyne::Session,
WebDyne::Template etc..

=head1 Documentation

Information on configuration and usage is availeble from the WebDyne site, http://webdyne.org/ - or from a snapshot of
current documentation in PDF format available in the WebDyne source /doc directory.

=head1 Copyright and License

Webdyne::Chain is Copyright (C) 2006-2010 Andrew Speer. WebDyne::Chain is dual licensed. It is released as free software
released under the Gnu Public License (GPL), but is also available for commercial use under a proprietary license -
please contact the author for further information.

WebDyne::Chain is written in Perl and uses modules from CPAN (the Comprehensive Perl Archive Network). CPAN modules are
Copyright (C) the owner/author, and are available in source from CPAN directly. All CPAN modules used are covered by the
Perl Artistic License.

=head1 Author

Andrew Speer, andrew@webdyne.org

=head1 Bugs

Please report any bugs or feature requests to "bug-webdyne-chain at rt.cpan.org", or via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebDyne-Chain


