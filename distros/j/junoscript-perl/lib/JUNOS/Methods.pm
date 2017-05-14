#
# $Id: Methods.pm,v 1.22 2004/01/09 19:03:35 rjohnst Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2004, Juniper Networks, Inc.  
# All rights reserved.  
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#


package JUNOS::Methods;

use File::Basename;
use strict;
use vars qw(@EXPORT_OK $AUTOLOAD
	    $NO_ARGS $TOGGLE $TOGGLE_NO $STRING $DOM $ATTRIBUTE %methods);

require Carp;
require Exporter;
@EXPORT_OK = qw($NO_ARGS $TOGGLE $TOGGLE_NO $STRING $DOM $ATTRIBUTE %methods);

use JUNOS::Trace;

$NO_ARGS = bless {}, "NO_ARGS";
$TOGGLE = bless { 1 => 1 }, "TOGGLE";
$TOGGLE_NO = bless {}, "TOGGLE";
$STRING = bless {}, "STRING";
$DOM = bless {}, "DOM";
$ATTRIBUTE = bless {}, "ATTRIBUTE";

# These are hardcoded methods
%methods = (
    lock_configuration => {
	rollback => $ATTRIBUTE
    },
    open_configuration => $NO_ARGS,
    get_configuration => { 
	configuration => $DOM,
	format => $ATTRIBUTE,
	inherit => $ATTRIBUTE,
	database => $ATTRIBUTE,
    },
    load_configuration => {
	action => $ATTRIBUTE,
	format => $ATTRIBUTE,
	rollback => $ATTRIBUTE,
	url => $ATTRIBUTE,
	configuration => $DOM
    },
    commit_configuration => {
	check => $TOGGLE,
	confirmed => $TOGGLE,
	"confirm-timeout" => $STRING
    },
    close_configuration => $NO_ARGS,
    unlock_configuration => $NO_ARGS,

    get_xnm_information => {
	type => $STRING,
	namespace => $STRING
    },

    get_database_status_information => $NO_ARGS,
);

#
# add_methods: extra cheesy hack to add two hashes without doing any real work
#
sub add_methods { @_; }

sub init_methods
{
    my($name, $args);

    %methods = add_methods(%methods, @_);
}

sub invoke_method
{
    my ($self, $fn, %args) = @_;
    my $bindings = $methods{ $fn };
    my $output = "";
    my $tag = "";
    my $attrs = "";
    trace("Methods", "$fn --> ", join("...", @_), "\n");

    foreach my $field (keys(%args)) {
	my $type = $bindings->{ $field };
	my $value = $args{ $field };

	($tag = $field) =~ s/_/-/g;

	if (ref($type) eq "TOGGLE" || ref($value) eq "TOGGLE") {
	    if ($value ne "0") {
		$output .= "    <$tag/>\n";
	    }

	} elsif (ref($value) eq "TOGGLE_NO") {
	    if ($value eq "0") {
		$output .= "    <no-$tag/>\n";
	    } else {
		$output .= "    <$tag/>\n";
	    }

	} elsif (ref($type) eq "STRING") {
	    $output .= "    <${tag}>${value}</${tag}>\n";

	} elsif ($type =~ /(\d)+\.\.(\d)+/) {
	    $output .= "    <${tag}>${value}</${tag}>\n";

	} elsif (ref($type) eq "DOM") {
	    $output .= $value->toString;
	    $output .= "\n";

	} elsif (ref($type) eq "ATTRIBUTE") {
	    $attrs .= " ${tag}=\"${value}\"\n";

	} elsif (ref($value)) {
	    $output .= $value->toString;
	    $output .= "\n";

	} else {
	    $output .= "    <${tag}>${value}</${tag}>\n";
	}
    }

    ($tag = $fn) =~ s/_/-/g;

    if ($output) {
	$output = "<rpc>\n  <${tag}${attrs}>\n${output}  </${tag}>\n</rpc>\n";
    } else {
	$output = "<rpc>\n  <${tag}${attrs}/>\n</rpc>\n";
    }

    $self->request($output);
}

sub AUTOLOAD
{
    my $name = substr($AUTOLOAD, rindex($AUTOLOAD, "::") + 2);
    unless ($methods{$name}) {
	Carp::croak("undefined function: $AUTOLOAD");
    }

    eval "sub $AUTOLOAD { invoke_method(shift, \"$name\", \@_); };";

#    *$AUTOLOAD = sub { invoke_method($name, @_); };
    goto &$AUTOLOAD;
}

##
# Load up methods via version
##
sub init
{
    my($version) = shift;
    my $current_dir;

    foreach my $dir (@INC) {
	if (-f "$dir/JUNOS/Methods.pm") {
	    $current_dir = $dir;
	    last;
	}
    }

    my $methods_dir = "$current_dir/JUNOS/$version";
    my @files = <$methods_dir/*_methods.pl>;

    for my $f (@files) {
        my $name = fileparse($f, '.pl');
        require $f;
	# use strict doesn't allow usage of bareword so have to
 	# use this block as a way around it.  Can't even hide
	# this inside init_methods because the init_methods
	# subroutine  doesn't see the hashtables in its scope.
	no strict 'refs';
        init_methods(%$name);
    }
}

1;
        
__END__

=head1 NAME

JUNOS::Methods - Implements the superclass for JUNOS::Device

=head1 SYNOPSIS

This class is is used internally to provide the junoscript xml commands to
JUNOS::Device.

=head1 DESCRIPTION

This class implements the <JUNOScript Command> methods inherited by 
JUNOS::Device.

=head1 CONSTRUCTOR

Build the hash tables for the AUTOLOAD subroutine to accept 
<JUNOScript Command> method invocation.  The list of JUNOScript commands
are read from the jroute_methods.pl and jkernel_methods.pl files.

=head1 SEE ALSO

    JUNOS::Device

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.
All rights reserved.
