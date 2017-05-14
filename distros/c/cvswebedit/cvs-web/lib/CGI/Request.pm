#!/usr/local/bin/perl -w

package CGI::Request;

require 5.001;

use CGI::Carp;
use Exporter;
use URI::Escape qw(uri_escape uri_unescape);
use CGI::BasePlus;

@ISA = qw(Exporter);

$Revision = '$Id: Request.pm,v 2.75 1996/2/15 04:54:10 lstein Exp $';
($VERSION = $Revision) =~ s/.*(\d+\.\d+).*/$1/;
my $Debug = 0; 	# enable debugging to STDERR (see CGI::Base::LogFile)


=head1 NAME

CGI::Request - Parse client request via a CGI interface


=head1 SYNOPSIS

	

    use CGI::Request;
	
    # Simple interface: (combines SendHeaders, new and import_names)
	
    $req = GetRequest($pkg);
	
    print FmtRequest();            # same as: print $req->as_string
	
	
    # Full Interface:
	
    $req = new CGI::Request;       # fetch and parse request
	
    $field_value = $req->param('FieldName');
    @selected    = $req->param('SelectMultiField');
    @keywords    = $req->keywords; # from ISINDEX
	
    print $req->as_string;         # format Form and CGI variables
	
    # import form fields into a package as perl variables!
    $req->import_names('R');
    print "$R::FieldName";
    print "@R::SelectMultiField";
	
    @value = $req->param_or($fieldname, $default_return_value);

    # Access to CGI interface (see CGI::Base)

    $cgi_obj = $req->cgi;
    $cgi_var = $req->cgi->var("REMOTE_ADDR");
	
	
    # Other Functions:
	
    CGI::Request::Interface($cgi);  # specify alternative CGI
	
    CGI::Request::Debug($level);    # log to STDERR (see CGI::Base)
	
	
    # Cgi-lib compatibility functions
    # use CGI::Request qw(:DEFAULT :cgi-lib); to import them
	
    &ReadParse(*input);
    &MethGet;
    &PrintHeader;
    &PrintVariables(%input);
	

=head1 DESCRIPTION

This module implements the CGI::Request object. This object represents
a single query / request / submission from a WWW user. The CGI::Request
class understands the concept of HTML forms and fields, specifically
how to parse a CGI QUERY_STRING.

=head2 SMALLEST EXAMPLE

This is the smallest useful CGI::Request script:

    use CGI::Request;
    GetRequest();
    print FmtRequest();


=head2 SIMPLE EXAMPLE

This example demonstrates a simple ISINDEX based query, importing results
into a package namespace and escaping of text:

    #!/usr/local/bin/perl  # add -T to test tainted behaviour

    use CGI::Base;
    use CGI::Request;

    GetRequest('R');       # get and import request into R::...

    # Just to make life more interesting add an ISINDEX.
    # Try entering: "aa bb+cc dd=ee ff&gg hh<P>ii"
    print "<ISINDEX>\r\n";

    print "<B>You entered:</B> ", # print results safely
          join(', ', CGI::Base::html_escape(@R::KEYWORDS))."\r\n";

    print FmtRequest();    # show formatted version of request


=head2 CGI

A CGI::Request object contains a reference to a CGI::Base object
(or an object derived from CGI::Base). It uses the services of
that object to get the raw request information.

Note that CGI::Request does not inherit from CGI::Base it just uses
an instance of a CGI::Base object.

See the cgi method description for more information.

=head2 FEATURES

Is object oriented and sub-classable.

Can export form field names as normal perl variables.

Integrates with CGI::MiniSvr.


=head2 RECENT CHANGES

=over

=item 2.75

Fixed bug in import_names().  Now works properly with both
scalar and array elements.

=item 2.4 through 2.74

Minor changes to accomodate Forms interface. 

=item 2.1 thru 2.3

Minor enhancements to documentation and debugging. Added notes about
relationship with CGI and how to access CGI variables.

=item 2.0

Updates for changed CGI:Base export tags. No longer setting
@CGI::Request::QUERY_STRING. Added param_or() method.

The module file can be run as a cgi script to execute a demo/test. You
may need to chmod +x this file and teach your httpd that it can execute
*.pm files (or create a copy/symlink with another name).

=item 1.8

GetRequest now call SendHeaders (in CGI::Base) for you. This works
*much* better than the old 'print PrintHeaders;'. PrintHeaders is no
longer exported by default. as_string now uses the new html_escape
method (in CGI::Base) to safely format strings with embedded html.
Debugging now defaults to off. New Debug function added. Image map
coords are automatically recognised and stored as parameters X and Y.
Added a sequence number mechanism to assist debugging MiniSvr
applications (does not impact/cost anything for non minisvr apps).

=item 1.7

Default package for import_names() removed, you must supply a package
name. GetRequest() won't call import_names unless a package name has
been given, thus GetRequest no longer defaults to importing names.
Added as_string() method (which automatically calls cgi->as_string).
param() will croak if called in a scalar context for a multi-values
field.

=back

=head2 FUTURE DEVELOPMENTS

None of this is perfect. All suggestions welcome.

Note that this module is *not* the place to put code which generates
HTML.  We'll need separate modules for that (which are being developed).


=head2 AUTHOR, COPYRIGHT and ACKNOWLEDGEMENTS

This code is Copyright (C) Tim Bunce 1995. All rights reserved.  This
code is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The cgi-lib functions are based on cgi-lib.pl version 1.7 which is
Copyright 1994 Steven E. Brenner.

IN NO EVENT SHALL THE AUTHORS BE LIABLE TO ANY PARTY FOR DIRECT,
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT
LIMITED TO, LOST PROFITS) EVEN IF THE AUTHORS HAVE BEEN ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

=head2 SEE ALSO

CGI::Base, URI::Escape

=head2 SUPPORT

Please use comp.infosystems.www.* and comp.lang.perl.misc for support.
Please do _NOT_ contact the author directly. I'm sorry but I just don't
have the time.

=cut


@EXPORT = qw(
    GetRequest FmtRequest
);
@EXPORT_OK = qw(
    Interface
    MethGet ReadParse PrintHeader PrintVariables PrintVariablesShort
);
%EXPORT_TAGS = (
    # export cgi-lib compatibility functions if requested
    'cgi-lib' => [qw(MethGet ReadParse PrintHeader
		    PrintVariables PrintVariablesShort)]
);

my $DefaultInterface = undef;
my $LastRequest      = undef;
my $SequenceNumber   = 0;

# Define some special 'parameter' names which we may use internally.
# These must never match any possible/praticla form field names.
# My convention is a leading tilde (~) and trailing space.
my $SequenceNumberKey = "~SequenceNumber ";

use strict;


####################################################################

=head1 FUNCTIONS

=head2 GetRequest

	 

    GetRequest();
    GetRequest($package_name);
    $req = GetRequest(...);

GetRequest is the main entry point for simple (non-object oriented) use
of the CGI::Request module. It combines output (and flushing) of the
standard Content-Type header, request processing and optional importing
of the resulting values into a package (see import_names).

This function also enables autoflush on stdout. This has a slight
efficiency cost but huge benefits in reduced frustration by novice
users wondering why, for example, the output of system("foo") appears
before their own output.

See C<new CGI::Request> for more details.

=cut

sub GetRequest {
    my($pkg, $timeout) = @_;
    CGI::Base::SendHeaders();			# flush Content-Type header
    $timeout = 0 unless $timeout;	# avoid undef warnings
    $| = 1;
    my $req = CGI::Request->new(undef, $timeout) || return undef;
    $req->import_names($pkg) if $pkg;
    $req;
}



=head2 FmtRequest

	 

    print FmtRequest();

Return a HTML string which describes the last (current) client request
parameters and the current raw CGI parameters.  Designed to be used for
debugging purposes.

=cut

sub FmtRequest {
    $LastRequest->as_string;
}


=head2 Interface

	 

    $cgi = Interface();

Return the default CGI interface object. Rarely used by applications.

If no interface has been defined yet it will automatically create a new
CGI::Base object, set that as the default interface and return it. This
is the mechanism by which simple applications get to use the CGI::Base
interface without knowing anything about it.

This function can also be use to define a new default interface (such
as CGI::MiniSvr) by passing a reference to a CGI::Base object or a
object derived from CGI::Base.

=cut

sub Interface {	# get or set default interface
    if (@_) {
	$DefaultInterface = shift;
    } elsif (!$DefaultInterface) {
	$DefaultInterface = new CGI::BasePlus;
    }
    return $DefaultInterface;
}


=head2 Debug

	 

    $old_level = CGI::Request::Debug();
    $old_level = CGI::Request::Debug($new_level);

Set debug level for the CGI::Request module. Debugging info is logged
to STDERR (see CGI::Base for examples of how to redirect STDERR).

=cut

sub Debug {
    my($level) = @_;
    my $prev = $Debug;
    if (defined $level) {
	$Debug = $level;
	print STDERR "CGI::Request::Debug($level)\n";
    }
    $prev;
}


# -------------------------------------------------------------------

=head1 METHODS

=head2 new

	 

    $req = new CGI::Request;
    $req = new CGI::Request $cgi_interface;
    $req = new CGI::Request $cgi_interface, $timeout_in_seconds;

CGI::Request object constructor. Only the first form listed above
should be used by most applications.

Note that, unlike GetRequest, new CGI::Request does not call
SendHeaders for you. You have the freedom to control how you send your
headers and what headers to send.

The returned $req CGI::Request object stores the request parameter
values. Parameters can be retrieved using the C<param> method.

Index keywords (ISINDEX) are automatically recognised, parsed and
stored as values of the 'KEYWORDS' parameter. The C<keywords> method
provides an easy way to retrieve the list of keywords.

Image Map (ISMAP) coordinates are automatically recognised, parsed and
stored as parameters 'X' and 'Y'.

=cut

sub new {
    my($class, $cgi, $timeout) = @_;
    $timeout = 0 unless $timeout;	# avoid warnings
    my %in;

    $cgi = Interface() unless $cgi;	# defaults to CGI::BasePlus

    # Read a request into the standard variables and perform basic
    # parsing of the metadata (but not the QUERY_STRING):
    $cgi->get($timeout) or return undef;	# timeout

    my $self = bless \%in, $class;

    $self->cgi($cgi); # stash CGI interface ref into request object

    $self->extract_values($CGI::Base::QUERY_STRING);

    if (++$SequenceNumber > 1) {
	$self->param($SequenceNumberKey, $SequenceNumber);
    }

    $LastRequest = $self;
    $self;
}


=head2 as_string

	 

    print $req->as_string;

Return an HTML string containing all the query parameters and CGI
parameters neatly and safely formatted. Very useful for debugging.

=cut

sub as_string {
    my($self) = @_;
    my $txt = $self->_fmt_params("%s = '%s'\r\n");
    my $seq = $self->param($SequenceNumberKey);
    $seq = ($seq) ? " Number $seq" : '';
    join('', "<BR><HR><B>Request$seq Parameters:</B> ",
	    "(CGI::Request version $CGI::Request::VERSION)<BR>",
	    "<PRE>\n$txt\n</PRE>\n",
	    Interface()->as_string,
	);
}


=head2 extract_values

	 

    $req->extract_values($QUERY_STRING)

This method extracts parameter name/value pairs from a string
(typically QUERY_STRING) and stores them in the objects hash.  Not
normally called by applications, new() calls it automatically.

The parameter names and values are individually unescaped using the
uri_unescape() function in the URI::URL module.

For ISINDEX keyword search requests (QUERY_STRING contains no '=' or
'&') the string is split on /+/ and the keywords are then individually
unescaped and stored.  Either the keywords() method (or param('KEYWORDS'))
can be used to recover the values.

=cut

sub extract_values {
    my($self, $query) = @_;
    print STDERR "Extracting values from '$query'\n" if $Debug>=2;

    return () unless defined $query;

    my(@parts, $key, $val);
    my $cgi = $self->cgi;

    if ($query =~ m/=/ or $query =~ m/&/) {

	$query =~ tr/+/ /;	# RFC1630
	@parts = split(/&/, $query);

	foreach (@parts) { # Extract into key and value.
	    ($key, $val) = m/^(.*?)=(.*)/;
	    $val = (defined $val) ? uri_unescape($val) : '';
	    $key = uri_unescape($key);

	    print STDERR "Value: '$key' = '$val'\n" if $Debug>=2;

	    # Store as a list of values. Push new value on the end.
	    $self->_add_parameter($key);
	    push(@{$self->{$key}},$val);
	}

    } else {	# no '=' or '&' implies ISINDEX so split on +'s

	@parts = split(/\+/, $query);
	grep { $_ = uri_unescape($_) } @parts;
	$self->param('KEYWORDS', @parts);

	# spot image maps and extract X and Y coords
	if (@parts == 1 and $parts[0] =~ m/^(\d+),(\d+)$/) {
	    $self->param('X', $1);
	    $self->param('Y', $2);
	}
	print STDERR "Keywords: @parts\n" if $Debug>=2;
    }

    @parts;
}


=head2 keywords

	 

    @words = $req->keywords

Return the keywords associated with an ISINDEX query.

=cut

sub keywords {
    shift->param('KEYWORDS');
}


=head2 params

	 

    @names = $req->params

Return a list of all known parameter names in the order in which they're defined

=cut

sub params {
    my($self) = @_;
    return () unless $self->{'.parameters'};
    return () unless @{$self->{'.parameters'}};
    return @{$self->{'.parameters'}};
}

=head2 param

	 

    $value  = $req->param('field_name1');
    @values = $req->param('field_name2');	# e.g. select multiple
    $req->param('field_name3', $new_value);
    $req->param('field_name4', @new_values);

Returns the value(s) of a named parameter. Returns an empty
list/undef if the parameter name is not known. Returns '' for a
parameter which had no value.

If invoked in a list context param returns the list of values in
the same order they were returned by the client (typically from
a select multiple form field).

Warning: If invoked in a scalar context and the parameter has more than
one value the param method will die. This catches badly constructed
forms where a field may have been copied but its name left unchanged.

If more than one argument is provided, the second and subsequent
arguments are used to set the value of the parameter. The previous
values, if any, are returned. Note that setting a new value has no
external effect and is only included for completeness.

Note that param does not return CGI variables (REMOTE_ADDR etc) since
those are CGI variables and not form parameters. To access CGI
variables see the cgi method in this module and the CGI::Base module
documentation.

=cut

sub param {
    my($self,$name,@values) = @_;
    return $self->params unless $name;

    # If values is provided, then we set it.
    if (@values) {
	$self->_add_parameter($name);
	$self->{$name}=[@values];
    }

    return () unless $self->{$name};
    return wantarray ? @{$self->{$name}} : $self->{$name}->[0];
}

=head2 delete

    $req->delete('field_name1');

Remove the specified field name from the parameter list

=cut

sub delete {
    my($self,$name) = @_;
    delete $self->{$name};
    @{$self->{'.parameters'}}=grep($_ ne $name,$self->param());
    return wantarray ? () : undef;
}

=head2 param_or

    $value  = $req->param_or('field_name1', $default);
    @values = $req->param_or('field_name2', @defaults);

If the current request was a query (QUERY_STRING defined) then this
method is identical to the param method with only one argument.

If the current request was not a query (QUERY_STRING undefined) then
this method simply returns its second and subsequent parameters.

The method is designed to be used as a form building utility.

=cut

sub param_or {
    my($self, $name, @values) = @_;
    return $self->param($name) if $CGI::Base::QUERY_STRING;
    @values;
}


=head2 import_names

	 

    $req->import_names('R')

Convert all request parameters into perl variables in a specified
package. This avoids the need to use $req->param('name'), you can
simply sat $R::name ('R' is the recommended package names).

Note: This is a convenience function for simple CGI scripts. It should
B<not> be used with the MiniSvr since there is no way to reset or
unimport the values from one request before importing the values of the
next.

=cut

sub import_names {
    my($self, $pkg) = @_;
    croak "Can't import_names into '$pkg'\n"
	    if !$pkg or $pkg eq 'main';
    no strict qw(refs);
    my(@value, $var,$param);
    foreach $param ($self->param) {
	# protect against silly names
	$param=~tr/a-zA-Z0-9_/_/c;
	$var = "${pkg}::$param";
	@value = $self->param($param);
	@{$var} = @value;
	${$var} = $value[$#value];
    }
}


=head2 cgi

	 

    $cgi = $req->cgi;

This method returns the current CGI::Request default CGI interface
object.  It is primarily intended as a handy shortcut for accessing
CGI::Base methods: $req->cgi->done(), $req->cgi->var("REMOTE_ADDR");

=cut

sub cgi {	# Handy method for $req->cgi->method(...)
    $DefaultInterface;
}


# _fmt_params()  --  build string from sprintf'd hash key/value pairs

sub _fmt_params {
    my($self, $fmt) = @_;
    my(@h, $key, $val, $out);
    foreach $key (sort $self->params) {
	foreach $val ($self->param($key)) {
	    push(@h, CGI::Base::html_escape(sprintf($fmt, $key, $val)));
	}
    }
    return join('', @h);
}



###################################################################
#
# cgi-lib compatibility functions - not recommended for new scripts

# Bootstrap the initial query fetch
sub cgi_lib_req {
    return $CGI::Request::cgi_lib_req if $CGI::Request::cgi_lib_req;
    $CGI::Request::cgi_lib_req = new CGI::Request;
}


sub MethGet {
    cgi_lib_req();
    return ($CGI::Base::REQUEST_METHOD eq "GET");
}

# ReadParse
# Reads in GET or POST data, converts it to unescaped text, and puts
# one key=value in each member of the list "@in". Also creates key/value
# pairs in %in, using '\0' to separate multiple selections.
# If a variable-glob parameter (e.g., *cgi_input) is passed to ReadParse,
# information is stored there, rather than in $in, @in, and %in.

sub ReadParse {
    local(*in) = @_ if @_;
    local(*in) = *{'main::in'} unless @_;
    my $req = cgi_lib_req();
    no strict qw(vars);
    %in = ();
    my($key, $val);
    foreach $key ($req->params) {
	$val = $req->{$key};
	$in{$key} = join("\0", @$val);
    }
    return 1;
}

# PrintHeader
# Returns the magic line which tells WWW that we're an HTML document

sub PrintHeader {	# Use SendHeaders() instead
    return "Content-Type: text/html\r\n\r\n"; # note special blank line
}


# PrintVariables
# Nicely formats variables in an associative array passed as a parameter
# And returns the HTML string.

sub PrintVariables {	# Use as_string instead
    my(%vars) = @_;
    my(@h) = ("<DL COMPACT>");
    push(@h, _fmt_cgilib(\%vars, '<DT><B>%s</B><DD><I>%s</I><BR>'));
    push(@h, "</DL>");
    join('', @h);
}

# PrintVariablesShort
# Nicely formats variables in an associative array passed as a parameter
# Using one line per pair (unless value is multiline)
# And returns the HTML string.

sub PrintVariablesShort {	# Use as_string instead
    my(%vars) = @_;
    return _fmt_cgilib(\%vars, "<B>%s</B> is <I>%s</I><BR>");
}

sub _fmt_cgilib {
    my($hashref, $fmt) = @_;
    my($output, $key, $out) = ("");
    foreach $key (sort keys(%$hashref)) {
	my $val = $hashref->{$key};
	foreach (split("\0", $val)) {
	    s/\n/<BR>/mg;
	    $output .= sprintf($fmt, $key, $_);
	}
    }
    return $output;
}

# -------------- really private subroutines -----------------
sub _parse_keywordlist {
    my($self,$tosplit) = @_;
    $tosplit = &uri_unescape($tosplit); # unescape the keywords
    $tosplit=~tr/+/ /;		# pluses to spaces
    my(@keywords) = split(/\s+/,$tosplit);
    return @keywords;
}

sub _parse_params {
    my($self,$tosplit) = @_;
    my(@pairs) = split('&',$tosplit);
    my($param,$value);
    foreach (@pairs) {
	($param,$value) = split('=');
	$param = uri_unescape($param);
	$value = uri_unescape($value);
	$self->add_parameter($param);
	push (@{$self->{$param}},$value);
    }
}

sub _add_parameter {
    my($self,$param)=@_;
    push (@{$self->{'.parameters'}},$param) 
	unless defined($self->{$param});
}

{ # Execute simple test if run as a script
  package main; no strict;
  eval join('',<main::DATA>) || die "$@ $main::DATA" unless caller();
}

1;

__END__

import CGI::Base;
import CGI::Request;

CGI::Base::Debug(2)	if -t STDIN;
CGI::Request::Debug(2)	if -t STDIN;

GetRequest('R');

print "<ISINDEX>\r\n"; # try: "aa bb+cc dd=ee ff&gg"

print "<B>You entered:</B> ",
          join(', ', CGI::Base::html_escape(@R::KEYWORDS))."\r\n"; 

print FmtRequest();

