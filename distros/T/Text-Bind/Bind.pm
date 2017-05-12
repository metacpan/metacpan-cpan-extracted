##---------------------------------------------------------------------------##
##  File:
##      @(#) Bind.pm 1.5 99/07/07 21:53:55
##  Author:
##      Earl Hood       earlhood@bigfoot.com
##  Description:
##	Class for supporting HTML template pages for perl CGI programs.
##	More explanation at end of source file.
##---------------------------------------------------------------------------##
##  Copyright (C) 1997-1999	Earl Hood, earlhood@bigfoot.com
##	All rights reserved.
##
##  This program is free software; you can redistribute it and/or
##  modify it under the same terms as Perl itself.
##---------------------------------------------------------------------------##

package Text::Bind;

use strict;
use vars '$VERSION';
$VERSION = '0.04';

##---------------------------------------------------------------------------##

use Carp;
use FileHandle;

###############################################################################
##	Public Class Methods
###############################################################################

##---------------------------------------------------------------------------##

sub new {
    my $this	= { };
    my $mod	= shift;	# Name of module
    my $file	= shift;	# Text input
    my $class	= ref($mod) || $mod;

    $this->{'file'} = $file;
    bless $this, $class;
    $this;
}

###############################################################################
##	Public Object Methods
###############################################################################

##---------------------------------------------------------------------------##

sub bind_site {
    my $this	= shift;
    my $site	= shift;	# Site name
    my $bind	= shift;	# Bind value to site

    $this->{'site'}{$site} = $bind;
    $this->{'args'}{$site} = [ @_ ];
}

##---------------------------------------------------------------------------##

sub read_text {
    my $this	= shift;
    my $outfh	= shift(@_) || \*STDOUT;	# Output stream (optional)
    my $file	= shift(@_) || $this->{'file'};	# File to read (optional)

    # Open file.  If unable, generate error message and return zero status.
    my($fh);
    if (ref $file) {
	$fh = $file;
    } else {
	$fh = new FileHandle $file;
	if (not defined $fh) {
	    carp qq|Unable to open "$file": $!|;
	    return 0;
	}
    }

    # Parse file
    my(@list);
    my($buf, $notone);

    local($_);
    while (<$fh>) {
	@list = split(/##PL_(?i)beginloop##/o, $_, 2);
	if (@list < 2) {
	    $this->_eval_bindings($outfh, $list[0]);
	    next;
	}
	$notone = 0;
	$this->_eval_bindings($outfh, shift(@list));
	$_ = shift(@list);  $buf = "";
	while (!/##PL_(?i)endloop##/) {
	    $buf .= $_;
	    last  unless defined($_ = <$fh>);
	    $notone = 1;
	}
	@list = split(/##PL_(?i)endloop##/o, $_, 2);
	if ($notone) {
	    $buf .= shift(@list);
	} else {
	    $buf = shift(@list);
	}
	1 while $this->_eval_bindings($outfh, $buf);
	$this->_eval_bindings($outfh, shift(@list))  if defined $list[0];

    } # End while (<$fh>)

    1;
}

###############################################################################
##	Private Functions
###############################################################################

sub _eval_bindings {
    my $this	= shift;
    my $outfh	= shift;
    my $text	= shift;

    return 0  unless defined($outfh) && defined($text);

    # Split on data site markup
    my @list = split(/##PL_([^#]+)##/, $text);

    # First item of list is regular data, so just output.
    my $data = shift(@list);
    print $outfh $data  if defined($data);

    # If other items are still in the list, then there are data
    # sites to resolve.
    my($site, $name, $value, $bind, $status, $tmp);
    my $retval = 0;

    LINE: while (@list) {
	$site = shift @list;
	$data = shift @list;
	if ($site =~ /^(\w+)\s*=\s*(.+)/) {
	    ($name, $value) = (lc $1, $2);
	} else {
	    next LINE;
	}

	# Check on type of data site
	SITE: {

	    # File site: open file and include contents where data
	    # site is located.  Filename could also include trailing
	    # pipe to allow a program to be invoked.
	    if ($name eq "file") {
		my $incfh = new FileHandle $value;
		if (defined $incfh) {
		    while (<$incfh>) {
			print $outfh $_;
		    }
		}
		undef $incfh;	# closes file
		last SITE;
	    }

	    # Named site: check if binding registered for value of
	    # site.  If so, execute binding.
	    if ($name eq "site") {
		$value =~ s/\s//g;	# strip any whitespace
		$bind = $this->{site}{$value};

		if (defined $bind) {
		    BIND: {
			# Function: Call if defined.  If not, silently
			# ignore.
			if (ref($bind) eq 'CODE') {
			    $retval = &$bind($this, $outfh, $value,
				             @{$this->{args}{$value}})
				if defined &$bind;
			    last BIND;
			}

			# Array: shift through the items in the array
			if (ref($bind) eq 'ARRAY') {
			    $tmp = shift(@{$bind});
			    $retval = scalar(@{$bind})  unless $retval;
			    last BIND  unless defined $tmp;
			    ARRAY: {
				if (ref($tmp) eq 'CODE') {
				    &$tmp($this, $outfh, $value,
					  @{$this->{args}{$value}})
					if defined &$tmp;
				    last ARRAY;
				}
				if (ref($tmp) && $tmp =~ /GLOB/) {
				    local $_; while (<$tmp>) {
					print $outfh $_;
				    }
				    last ARRAY;
				}
				if (ref($tmp)) {
				    $tmp->fill_site($this, $outfh, $site,
						    @{$this->{args}{$value}});
				    last ARRAY;
				}
				print $outfh $tmp;
				last ARRAY;
			    }
			    last BIND;
			}

			# Filehandle: Have to use regex to check
			# for filehandle in case a filehandle class
			# is in use.
			if (ref($bind) && $bind =~ /GLOB/) {
			    local $_;
			    while (<$bind>) {
				print $outfh $_;
			    }
			    last BIND;
			}

			# Object: Call the method that the object
			# should define to work with this class.  We
			# only check if $bind is a reference.  Other
			# relevant reference types are checked above.
			if (ref($bind)) {
			    $retval = $bind->fill_site($this, $outfh, $site,
					           @{$this->{args}{$value}});
			    last BIND;
			}

			# String: Fallback case; just output string
			print $outfh $bind;
			last BIND;

		    } # End BIND
		}
		last SITE;
	    }

	} # End SITE

    } continue {
	print $outfh $data  if defined($data);

    } # End while (@list)

    $retval;
}

##---------------------------------------------------------------------------##
1;

__END__

=head1 NAME

Text::Bind - Bind Perl structures to text files

=head1 SYNOPSIS

    use Text::Bind;

    # Create a new object
    $text = new Text::Bind;              	# or
    $text = new Text::Bind "page.html"		# or
    $text = new Text::Bind \*IN;

    # Bind a string value to a data site
    $text->bind_site("astring", "Hello World!");

    # Bind a function to a data site
    $text->bind_site("form", \&generate_form);

    # Bind a filehandle to a data site
    $text->bind_site("filehandle", \*FILE);

    # Bind an object to a data site
    $some_object = new SomeClass;
    $text->bind_site("object", $some_object);

    # Read text
    $text->read_text(\*OUT, "page.html");	# or
    $text->read_text(\*OUT, \*IN);		# or
    $text->read_text(\*OUT);   			# or
    $text->read_text;

=head1 DESCRIPTION

B<Text::Bind> allows you to bind Perl structures (strings, routines,
filehandles, objects) to specific locations (called I<data sites>)
in text files.

The main purpose of this module is to support HTML templates for
CGI programs.  Therefore, HTML pages design can be kept separate
from CGI code.  However, the class is general enough to be used
in other contexts than CGI application development.  For example,
it could be used to do form letters.

To create a new object, do one of the following:

    $text = new Text::Bind;
    $text = new Text::Bind $filename;
    $text = new Text::Bind \*FILE;

If no argument is given during object instantiation, then the
input must be specified during the B<read_text> method.  Otherwise,
a filename or a filehandle can be listed to specify the input
source of the text data.

To have the data processed, use the B<read_text> method in one
of the following ways:

    $text->read_text;
    $text->read_text(\*OUT);
    $text->read_text(\*OUT, $filename);
    $text->read_text(\*OUT, \*FILE);

When called with no arguments, input is read from what is specified
during object instantiation, and output goes to STDOUT.  If arguments
are specified, the first argument is the output filehandle.  If undefined,
STDOUT is used.  The second argument is the filename or the filehandle
of the input.  If not defined, input is read from what is specified
during object instantiation.

The syntax for specifying data sites in the input and how to
bind Perl structures to those sites is covered in the following
sections.

=head1 Data Site Syntax

To define a data site, the syntax is as follows:

    ##PL_name=value##

where the components mean the following:

=over 4

=item C<##PL_>

Start of a data site.

=item I<name>

Type name of the site, possible values:

=over 4

=item C<site>

Specifies a labeled data site where the data for the site determined
thru the bind_site method.

=item C<file>

Specifies the name of file that defines the contents of the data site.
Works in a similiar manner as HTTP server-side file include directive.
If a trailing pipe is included in the value, then the value is treated
as program to invoke, and the output of the program is used to fill
the site.

=item C<beginloop>

The start of a repeatable loop.  Text following, and up to the end-of-loop
data site, is treated as a repeatable segment.
See L<"Data Site Loops"> for more information.

=item C<endloop>

The end point of a repeatable loop.
See L<"Data Site Loops"> for more information.

=back

The name is case insensitive.

=item C<=>

Separator of name and value.

=item I<value>

String value associated with name.  Value is case
sensitive.

=item C<##>

End of data site.

=back

Data sites that do not have a binding during processing of text input
are expanded to the empty string.

Duplicate sites can occur.  The binding will be reexecuted each time
the site occurs.

=head2 Example data sites

A data site for an HTML form:

    <html>
    <body>
    ##PL_site=inputform##
    </body>
    </html>

The call to bind_site may look like:

    $text->bind_site("inputform", \&create_form)

The following shows how a file can bound to a site:

    <html>
    <body>
    ...
    <hr>
    ##PL_file=copyright.html##
    </body>
    </html>

The contents of C<copyright.html> will replace the site definition.

The following shows how the output of a program can be included:

    ##PL_file=/bin/ls -l |##

=head1 Data Site Bindings via bind_site Method

The B<bind_site> method takes 2 arguments, the name of the site to bind
to and a value to define the value of the site during the read_text
method.  Example:

    $text->bind_site($name, $bind);

The $name of the data site corresponds to the value of a
##PL_site=value## data site.

The bind value can be one of the following Perl data structures:

=over 4

=item scalar string

The data site is replaced with the value of the scalar
string.

=item function

A reference to a function.  The function is invoked as
follows:

    &func($textobj, $outfh, $site_name);

Where, $textobj is the Text::Bind object.  $outfh is the output
filehandle.  The function uses $outfh to output the data that should
go in the location of the data site.  For example:

    print $outfh "... data here ...";

$site_name is the name of the site the function is being called for.

Since the Text::Bind object is passed to the function, the function
can change bindings.  Any changes will affect any data sites following
the site being processed.

Additional arguments can be passed to the bind_site method when
binding a function.  For example:

    $text->bind_site($site_name, \&func, $arg1, $arg2);

A copy of those arguments will be passed as extra arguments when
the function is invoked.  Continuing with the previous example, the
function would be called as follows:

    &func($page_obj, $outfh, $site_name, $arg1, $arg2);

Since the function may only exist for the purpose of filling the
contents of a site, an anonymous function can be passed instead
of a named function.  For example:

    $text->bind_site($site_name, sub {
	my($txtobj, $fh, $site) = @_;

	## ... code here ...
    });

Note, the return value of the function is used within in data site
loops.
See L<"Data Site Loops"> for more information.

=item filehandle

A reference to a filehandle (technically a reference to a glob of
a filehandle).  The filehandle is read until EOF and any data read
goes in the location of the site.

=item object

An object reference.  Text::Bind will attempt to call the method
I<fill_site> of the object.  Therefore, the object must have defined
a method called fill_site, or a runtime error will occur.

The method is invoked with the same arguments as in a function binding:

    $object->fill_site($page_obj, $outfh, $site_name);

Any additional arguments passed during the bind_site call will be
passed to the registered object's fill_site method like in function
bindings:

    $object->fill_site($page_obj, $outfh, $site_name,
		       $arg1, $arg2, ..., $argN);

Note, the return value of the I<fill_site> method
is used within in data site loops.
See L<"Data Site Loops"> for more information.

=item array

Actually, a reference to an array.  The values of the array are
iterated over each time the data site is evaluated.  The items in the
array can be scalar strings, functions, filehandles, or objects, as
defined above.

Binding an array to a site is most applicable for loops created by
C<##PL_beginloop##>.  See L<"Data Site Loops"> for more
information.

=back

=head1 Data Site Loops

Occasionally, there is a need to have a block of text be repeatable.
For example, lets take the following text data:

    ##PL_beginloop##Item = ##PL_site=listvalue##
    ##PL_endloop##

And the following bindings:

    $text->bind_site('listvalue', [ 1, 2, 3, 4 ]);

Will generated the following output:

    Item = 1
    Item = 2
    Item = 3
    Item = 4

The text between the begin and end data sites is repeated until
the evaluation of B<ALL> data sites within the loop generate no more
data.

Within a loop, types of data sites are treated as follows:

=over 4

=item scalar string

Will always be printed.  However, a scalar string data site will
always be treated to have no more data when determine end of loop
condition.

=item function or object

Will always be invoked.  However, the return value is check to
determine if the last value has been generated for the data site.
A return value of false tells C<Text::Bind> that no more data exists
for this site.

WARNING: If the loop contains multiple data sites, it is possible
that a function, or object method, will be called again if the other
sites have not signified an end of data condition.  Hence, the
function/method should still return a false value for the duraction of
the loop.

=item filehandle

Will always be printed.  However, a filehandle data site will
always be treated to have no more data when determine end of loop
condition.  Also, since the EOF condition will be set after
the first evaluation of the data site, subsequent evaluation will
generate no data unless something resets the filehandle.

=item array

The items of the array are iterated over until end of the array is
reached.  Once the last item is reached, the end of data condition
is set for the site.

=back

=head2 Loop Examples

A good example of loops is when populating an HTML table with
data:

    <table>
    ##PL_beginloop##
    <tr>
    <td>##PL_site=lastname##</td>
    <td>##PL_site=firstname##</td>
    <td>##PL_site=street##</td>
    <td>##PL_site=city##</td>
    <td>##PL_site=state##</td>
    <td>##PL_site=zip##</td>
    </tr>
    ##PL_endloop##


=head1 LIMITATIONS

=over 4

=item *

Data site loops cannot be nested.

=item *

Multiple data site loops cannot exist on a single line.

=back

=head1 AUTHOR

Earl Hood, earlhood@bigfoot.com

http://www.oac.uci.edu/indiv/ehood

=cut

