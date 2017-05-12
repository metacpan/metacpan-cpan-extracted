# NOTE TO MAINTAINERS: license boilerplate appears twice in this file

#  Copyright 2000-2004  The Apache Software Foundation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

package Apache::Request;

use strict;
use mod_perl 1.17_01;
use Apache::Table ();

{
    no strict;
    $VERSION = '1.34';
    @ISA = qw(Apache);
    __PACKAGE__->mod_perl::boot($VERSION);
}

#just prototype methods here, moving to xs later

sub instance {
    my $class = shift;
    my $r = shift;
    return unless defined $r;
    if (my $apreq = $r->pnotes('apreq')) {
        return $apreq;
    }

    my $new_req = $class->new($r, @_);
    $r->pnotes('apreq', $new_req);
    return $new_req;
}

1;
__END__

=head1 NAME

Apache::Request - Methods for dealing with client request data

=head1 SYNOPSIS

    use Apache::Request ();
    my $apr = Apache::Request->new($r);

=head1 DESCRIPTION

I<Apache::Request> is a subclass of the I<Apache> class, which adds methods
for parsing B<GET> requests and B<POST> requests where I<Content-type>
is one of I<application/x-www-form-urlencoded> or 
I<multipart/form-data>. See the libapreq(3) manpage for more details.

=head1 Apache::Request METHODS

The interface is designed to mimic CGI.pm 's routines for parsing
query parameters. The main differences are 

=over 4

=item * C<Apache::Request::new> takes an Apache object as (second) argument.


=item * The query parameters are stored as Apache::Table objects,
and are therefore parsed using case-insensitive keys.


=item * C<-attr =E<gt> $val> -type arguments are not supported.


=item * The query string is always parsed, even for POST requests.

=back

=head2 new

Create a new I<Apache::Request> object with an I<Apache> request_rec object:

    my $apr = Apache::Request->new($r);

All methods from the I<Apache> class are inherited.

The following attributes are optional:

=over 4

=item POST_MAX

Limit the size of POST data (in bytes).  I<Apache::Request::parse> will 
return an error code if the size is exceeded:

 my $apr = Apache::Request->new($r, POST_MAX => 1024);
 my $status = $apr->parse;

 if ($status) {
     my $errmsg = $apr->notes("error-notes");
     ...
     return $status;
 }

=item DISABLE_UPLOADS

Disable file uploads.  I<Apache::Request::parse> will return an
error code if a file upload is attempted:

 my $apr = Apache::Request->new($r, DISABLE_UPLOADS => 1);
 my $status = $apr->parse;

 if ($status) {
     my $errmsg = $apr->notes("error-notes");
     ...
     return $status;
 }

=item TEMP_DIR

Sets the directory where upload files are spooled.  On a *nix-like
that supports link(2), the TEMP_DIR should be located on the same
file system as the final destination file:

 my $apr = Apache::Request->new($r, TEMP_DIR => "/home/httpd/tmp");
 my $upload = $apr->upload('file');
 $upload->link("/home/user/myfile") || warn "link failed: $!";

Note: The standard C library function C<tempnam()> is used to define the
file to be used, and it may well prefer to look for some other temporary
directory, specified by an environment variable in the environment of the
user that Apache is running as, in preference to the one passed to it.
For example, Microsoft's C<tempnam()> implementation will look for a TMP
environment variable first; glibc's version looks for TMPDIR first. The
TEMP_DIR specified here is generally only used if the relevant environment
variable is not set, or the directory specified by it does not exist.
Refer to your system's C library documentation for the full details on your
platform.

=item HOOK_DATA

Extra configuration info passed to an upload hook.
See the description for the next item, I<UPLOAD_HOOK>.

=item UPLOAD_HOOK

Sets up a callback to run whenever file upload data is read. This
can be used to provide an upload progress meter during file uploads.
Apache will automatically continue writing the original data to
$upload->fh after the hook exits.

 my $transparent_hook = sub {
   my ($upload, $buf, $len, $hook_data) = @_;
   warn "$hook_data: got $len bytes for " . $upload->name;
 };

 my $apr = Apache::Request->new($r, 
                                HOOK_DATA => "Note",
                                UPLOAD_HOOK => $transparent_hook,
                               );
 $apr->parse;

=back

=head2 instance

The instance() class method allows Apache::Request to be a singleton.
This means that whenever you call Apache::Request->instance() within a
single request you always get the same Apache::Request object back.
This solves the problem with creating the Apache::Request object twice
within the same request - the symptoms being that the second
Apache::Request object will not contain the form parameters because
they have already been read and parsed.

  my $apr = Apache::Request->instance($r, DISABLE_UPLOADS => 1);

Note that C<instance()> call will take the same parameters as the above
call to C<new()>, however the parameters will only have an effect the
first time C<instance()> is called within a single request. Extra
parameters will be ignored on subsequent calls to C<instance()> within
the same request.

Subrequests receive a new Apache::Request object when they call
instance() - the parent request's Apache::Request object is not copied
into the subrequest.

Also note that it is unwise to use the C<parse()> method when using
C<instance()> because you may end up trying to call it twice, and
detecting errors where there are none.

=head2 parse

The I<parse> method does the actual work of parsing the request.
It is called for you by the accessor methods, so it is not required but
can be useful to provide a more user-friendly message should an error 
occur:

    my $r = shift;
    my $apr = Apache::Request->new($r); 

    my $status = $apr->parse; 
    unless ($status == OK) { 
	$apr->custom_response($status, $apr->notes("error-notes")); 
	return $status; 
    } 

=head2 param

Get or set request parameters (using case-insensitive keys) by
mimicing the OO interface of C<CGI::param>.  Unlike the CGI.pm version,
Apache::Request's param method is I<very> fast- it's now quicker than even
mod_perl's native Apache->args method.  However, CGI.pm's
C<-attr =E<gt> $val> type arguments are not supported.

    # similar to CGI.pm

    my $value = $apr->param('foo');
    my @values = $apr->param('foo');
    my @params = $apr->param;

    # the following differ slightly from CGI.pm

    # assigns multiple values to 'foo'
    $apr->param('foo' => [qw(one two three)]);

    # returns ref to underlying apache table object
    my $table = $apr->param; # identical to $apr->parms - see below

=head2 parms

Get or set the underlying apache parameter table of the I<Apache::Request>
object.  When invoked without arguments, C<parms> returns a reference
to an I<Apache::Table> object that is tied to the Apache::Request
object's parameter table.  If called with an Apache::Table reference
as as argument, the Apache::Request object's parameter table is
replaced by the argument's table.

   # $apache_table references an Apache::Table object
   $apr->parms($apache_table); # sets $apr's parameter table

   # returns ref to Apache::Table object provided by $apache_table
   my $table = $apr->parms;

=head2 upload

Returns a single I<Apache::Upload> object in a scalar context or
all I<Apache::Upload> objects in a list context: 

    my $upload = $apr->upload;
    my $fh = $upload->fh;
    my $lines = 0; 
    while(<$fh>) { 
        ++$lines; 
        ...
    } 

An optional name parameter can be passed to return the I<Apache::Upload>
object associated with the given name:

    my $upload = $apr->upload($name);

=head1 SUBCLASSING Apache::Request

The Apache::Request class cannot be subclassed directly because its constructor
method does not bless new objects into the invocant class. Instead, it always
blesses them into the Apache::Request class itself.

However, there are two main ways around this.

One way is to have a constructor method in your subclass that invokes the
superclass constructor method and then re-blesses the new object into itself
before returning it:

	package MySubClass;
	use Apache::Request;
	our @ISA = qw(Apache::Request);
	sub new {
		my($class, @args) = @_;
		return bless $class->SUPER::new(@args), $class;
	}

The other way is to aggregate and delegate: store an Apache::Request object in
each instance of your subclass, and delegate any Apache::Request methods that
you are not overriding to it:

	package MySubClass;
	use Apache::Request;
	sub new {
		my($class, @args) = @_;
		return bless { r => Apache::Request->new(@args) }, $class;
	}
	sub AUTOLOAD {
		my $proto = shift;
		return unless ref $proto;
		our $AUTOLOAD;
		my $name = $AUTOLOAD;
		$name =~ s/^.*:://;
		return $proto->{r}->$name(@_);
	}

A fancier AUTOLOAD() subroutine could be written to handle class methods too if
required, but we leave that as an exercise for the reader because in fact the
Apache::Request class provides some magic that makes the aggregate/delegate
solution much easier.

If the instances of your subclass are hash references then you can actually
inherit from Apache::Request as long as the Apache::Request object is stored in
an attribute called "r" or "_r". (The Apache::Request class effectively does the
delegation for you automagically, as long as it knows where to find the
Apache::Request object to delegate to.)

Thus, the second example above can be simplified as:

	package MySubClass;
	use Apache::Request;
	our @ISA = qw(Apache::Request);
	sub new {
		my($class, @args) = @_;
		return bless { r => Apache::Request->new(@args) }, $class;
	}

=head1 Apache::Upload METHODS

=head2 name

The name of the filefield parameter:

    my $name = $upload->name;

=head2 filename

The filename of the uploaded file:

    my $filename = $upload->filename;

=head2 fh

The filehandle pointing to the uploaded file:

    my $fh = $upload->fh;
    while (<$fh>) {
	...
    }

=head2 size

The size of the file in bytes:

    my $size = $upload->size;

=head2 info

The additional header information for the uploaded file.
Returns a hash reference tied to the I<Apache::Table> class.
An optional I<key> argument can be passed to return the value of 
a given header rather than a hash reference.  Examples:

    my $info = $upload->info;
    while (my($key, $val) = each %$info) {
	...
    }

    my $val = $upload->info("Content-type");

=head2 type

Returns the I<Content-Type> for the given I<Apache::Upload> object:

    my $type = $upload->type;
    #same as
    my $type = $upload->info("Content-Type");

=head2 next

Upload objects are implemented as a linked list by libapreq; the
I<next> method provides an alternative to using the I<Apache::Request>
I<upload> method in a list context:

    for (my $upload = $apr->upload; $upload; $upload = $upload->next) {
	...
    }

    #functionally the same as:

    for my $upload ($apr->upload) {
	...
    }

=head2 tempname

Provides the name of the spool file. This method is reserved for
debugging purposes, and is possibly subject to change in a future
version of Apache::Request.

=head2 link

To avoid recopying the spool file on a *nix-like system,
I<link> will create a hard link to it:

  my $upload = $apr->upload('file');
  $upload->link("/path/to/newfile") or
      die sprintf "link from '%s' failed: $!", $upload->tempname;

Typically the new name must lie on the same file system as the
spool file. Check your system's link(2) manpage for details.

=head1 SEE ALSO

libapreq(3), Apache::Table(3)

=head1 AUTHOR

libapreq developers can be reached at apreq-dev (about) httpd.apache.org

=head1 CREDITS

This interface is based on the original pure Perl version by Lincoln Stein.

=head1 LICENSE

   Copyright 2000-2004  The Apache Software Foundation

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.


