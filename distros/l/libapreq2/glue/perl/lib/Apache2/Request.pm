package Apache2::Request;
use APR::Request::Param;
use APR::Request::Apache2;
use Apache2::RequestRec;
push our @ISA, qw/Apache2::RequestRec APR::Request::Apache2/;
our $VERSION = "2.15";

my %old_limits = (
    post_max => "read_limit",
    max_body => "read_limit",
);

sub new {
    my $class = shift;
    my $req = $class->APR::Request::Apache2::handle(shift);
    my %attrs = @_;

    while (my ($k, $v) = each %attrs) {
        $k =~ s/^-//;
        my $method = $old_limits{lc($k)} || lc $k;
        $req->$method($v);
    }
    return $req;
}

sub hook_data {die "hook_data not implemented"}

sub disable_uploads {
    my ($req, $toggle) = @_;
    $req->SUPER::disable_uploads if $toggle;
}

1;

__END__

=head1 NAME

Apache2::Request - Methods for dealing with client request data




=head1 SYNOPSIS


    use Apache2::Request;
    $req = Apache2::Request->new($r);
    @foo = $req->param("foo");
    $bar = $req->args("bar");




=head1 DESCRIPTION

The Apache2::Request module provides methods for parsing GET and POST parameters
encoded with either I<application/x-www-form-urlencoded> or I<multipart/form-data>.
Although Apache2::Request provides a few new APIs for accessing the parsed data,
it remains largely backwards-compatible with the original 1.X API.  See the
L<PORTING from 1.X> section below for a list of known issues.

This manpage documents the Apache2::Request package.




=head1 Apache2::Request

The interface is designed to mimic the CGI.pm routines for parsing
query parameters. The main differences are

=over 4

=item * C<Apache2::Request::new> takes an environment-specific
        object C<$r> as (second) argument.  Newer versions of CGI.pm also accept
        this syntax within modperl.

=item * The query parameters are stored in APR::Table derived objects, and
        are therefore retrieved from the table by using case-insensitive keys.

=item * The query string is always parsed immediately, even for POST requests.

=back




=head2 new

    Apache2::Request->new($r, %args)

Creates a new Apache2::Request object.


    my $req = Apache2::Request->new($r, POST_MAX => "1M");


With mod_perl2, the environment object $r must be an Apache2::RequestRec
object.  In that case, all methods from Apache2::RequestRec are inherited.
In the (default) CGI environment, $r must be an APR::Pool object.

The following args are optional:

=over 4


=item * C<POST_MAX>, C<MAX_BODY>

Limit the size of POST data (in bytes).


=item * C<DISABLE_UPLOADS>

Disable file uploads.


=item * C<TEMP_DIR>

Sets the directory where upload files are spooled.  On a *nix-like
that supports I<link(2)>, the TEMP_DIR should be located on the same
file system as the final destination file:

 use Apache2::Upload;
 my $req = Apache2::Request->new($r, TEMP_DIR => "/home/httpd/tmp");
 my $upload = $req->upload('file');
 $upload->link("/home/user/myfile");

For more details on C<link>, see L<Apache2::Upload>.


=item * C<HOOK_DATA>

Extra configuration info passed as the fourth argument
to an upload hook.  See the description for the next item,
C<UPLOAD_HOOK>.


=item * C<UPLOAD_HOOK>

Sets up a callback to run whenever file upload data is read. This
can be used to provide an upload progress meter during file uploads.
Apache will automatically continue writing the original data to
$upload->fh after the hook exits.

  my $transparent_hook = sub {
    my ($upload, $data, $data_len, $hook_data) = @_;
    warn "$hook_data: got $data_len bytes for " . $upload->name;
  };

  my $req = Apache2::Request->new($r,
                                  HOOK_DATA => "Note",
                                  UPLOAD_HOOK => $transparent_hook,
                                 );

=back




=head2 instance

    Apache2::Request->instance($r)

The default (and only) behavior of I<Apache2::Request> is to intelligently
cache B<POST> data for the duration of the request.  Thus there is no longer
the need for a separate C<instance()> method as existed in I<Apache2::Request>
for Apache 1.3 - all B<POST> data is always available from each and every
I<Apache2::Request> object created during the request's lifetime.

However an C<instance()> method is aliased to C<new()> in this release
to ease the pain of porting from 1.X to 2.X.




=head2 param

    $req->param()
    $req->param($name)

Get the request parameters (using case-insensitive keys) by
mimicing the OO interface of C<CGI::param>.


    # similar to CGI.pm

    my $foo_value   = $req->param('foo');
    my @foo_values  = $req->param('foo');
    my @param_names = $req->param;

    # the following differ slightly from CGI.pm

    # returns ref to APR::Request::Param::Table object representing
    # all (args + body) params
    my $table = $req->param;
    @table_keys = keys %$table;


In list context, or when invoked with no arguments as
C<< $req->param() >>, C<param> induces libapreq2 to read
and parse all remaining data in the request body.
However, C<< scalar $req->param("foo") >> is lazy: libapreq2
will only read and parse more data if

    1) no "foo" param appears in the query string arguments, AND
    2) no "foo" param appears in the previously parsed POST data.

In this circumstance libapreq2 will read and parse additional
blocks of the incoming request body until either

    1) it has found the the "foo" param, or
    2) parsing is completed.

Observe that C<< scalar $req->param("foo") >> will not raise
an exception if it can locate "foo" in the existing body or
args tables, even if the query-string parser or the body parser
has failed.  In all other circumstances C<param> will throw an
Apache2::Request::Error object into $@ should either parser fail.

    $req->args_status(1); # set error state for query-string parser
    ok $req->param_status == 1;

    $foo = $req->param("foo");
    ok $foo == 1;
    eval { @foo = $req->param("foo") };
    ok $@->isa("Apache2::Request::Error");
    undef $@;
    eval { my $not_found = $req->param("non-existent-param") };
    ok $@->isa("Apache2::Request::Error");

    $req->args_status(0); # reset query-string parser state to "success"


Note: modifications to the C<< scalar $req->param() >> table only
affect the returned table object (the underlying C apr_table_t is
I<generated> from the parse data by apreq_params()).  Modifications
do not affect the actual request data, and will not be seen by other
libapreq2 applications.




=head2 parms, params

The functionality of these functions is assumed by C<param>,
so they are no longer necessary.  Aliases to C<param> are
provided in this release for backwards compatibility,
however they are deprecated and may be removed from a future
release.




=head2 body

    $req->body()
    $req->body($name)

Returns an I<APR::Request::Param::Table> object containing the POST data
parameters of the I<Apache2::Request> object.

    my $body = $req->body;

An optional name parameter can be passed to return the POST data
parameter associated with the given name:

    my $foo_body = $req->body("foo");

More generally, C<body()> follows the same pattern as C<param()>
with respect to its return values and argument list.  The main difference
is that modifications to the C<< scalar $req->body() >> table affect
the underlying apr_table_t attribute in apreq_request_t, so their impact
will be noticed by all libapreq2 applications during this request.




=head2 upload

    $req->upload()
    $req->upload($name)

Requires C<Apache2::Upload>.  With no arguments, this method
returns an I<APR::Request::Param::Table> object in scalar context,
or the names of all I<Apache2::Upload> objects in list context.

An optional name parameter can be passed to return the I<Apache2::Upload>
object associated with the given name:

    my $upload = $req->upload($name);

More generally, C<upload()> follows the same pattern as C<param()>
with respect to its return values and argument list.  The main difference
is that its returned values are Apache2::Upload object refs, not
simple scalars.

Note: modifications to the C<< scalar $req->upload() >> table only
affect the returned table object (the underlying C apr_table_t is
I<generated> by apreq_uploads()).  They do not affect the actual request
data, and will not be seen by other libapreq2 applications.




=head2 args_status

    $req->args_status()

Get the I<APR> status code of the query-string parser.
APR_SUCCESS on success, error otherwise.




=head2 body_status

    $req->body_status()

Get the current I<APR> status code of the parsed POST data.
APR_SUCCESS when parser has completed, APR_INCOMPLETE if parser
has more data to parse, APR_EINIT if no post data has been parsed,
error otherwise.




=head2 param_status

    $req->param_status()

In scalar context, this returns C<args_status> if there was
an error during the query-string parse, otherwise this returns
C<body_status>, ie

    $req->args_status || $req->body_status

In list context C<param_status> returns the list
C<(args_status, body_status)>.




=head2 parse

    $req->parse()

Forces the request to be parsed immediately.  In void context,
this will throw an APR::Request::Error should the either the
query-string or body parser fail. In all other contexts it will
return the two parsers' combined I<APR> status code

    $req->body_status || $req->args_status

However C<parse> should be avoided in most normal situations.  For example,
in a mod_perl content handler it is more efficient to write

    sub handler {
        my $r = shift;
        my $req = Apache2::Request->new($r);
        $r->discard_request_body;   # efficiently parses the request body
        my $parser_status = $req->body_status;

        #...
    }

Calling C<< $r->discard_request_body >> outside the content handler
is generally a mistake, so use C<< $req->parse >> there, but
B<only as a last resort>.  The Apache2::Request API is B<designed>
around a lazy-parsing scheme, so calling C<parse> should not
affect the behavior of any other methods.




=head1 SUBCLASSING Apache2::Request

If the instances of your subclass are hash references then you can actually
inherit from Apache2::Request as long as the Apache2::Request object is stored in
an attribute called "r" or "_r". (The Apache2::Request class effectively does the
delegation for you automagically, as long as it knows where to find the
Apache2::Request object to delegate to.)  For example:

	package MySubClass;
	use Apache2::Request;
	our @ISA = qw(Apache2::Request);
	sub new {
		my($class, @args) = @_;
		return bless { r => Apache2::Request->new(@args) }, $class;
	}




=head1 PORTING from 1.X

This is the complete list of changes to existing methods
from Apache2::Request 1.X.  These issues need to be
addressed when porting 1.X apps to the new 2.X API.


=over 4

=item * Apache2::Upload is now a separate module.  Applications
        requiring the upload API must C<use Apache2::Upload> in 2.X.
        This is easily addressed by preloading the modules during
        server startup.

=item * You can no longer add (or set or delete) parameters in the
        C<< scalar $req->param >>, C<< scalar $req->args >> or
        C<< scalar $req->body >> tables.  Nor can you add (or set or delete)
        cookies in the C<< scalar $req->jar >> table.

=item * C<instance()> is now identical to C<new()>, and is now deprecated.  It
        may be removed from a future 2.X release.

=item * C<param> includes the functionality of C<parms()> and C<params()>, so
        they are now deprecated and may be removed from a future 2.X release.

=item * C<param> called in a list context no longer returns a unique list of
        paramaters.  The returned list contains multiple instances of the 
        parameter name for multivalued fields.

=back




=head1 SEE ALSO

L<APR::Request::Param>, L<APR::Request::Error>, L<Apache2::Upload>,
L<Apache2::Cookie>, APR::Table(3).




=head1 COPYRIGHT

  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
