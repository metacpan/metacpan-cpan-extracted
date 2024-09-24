package Webservice::KeyVal::API;

use v5.10;
use strict;
use warnings;
use URI::Escape qw/uri_escape/;

our $VERSION = '0.9.9';

use HTTP::Tiny;
use JSON            qw/decode_json/;
use Util::H2O::More qw/baptise ddd HTTPTiny2h2o h2o/;

use constant {
    BASEURL => "https://api.keyval.org",
};

sub new {
    my $pkg  = shift;
    my $self = baptise { ua => HTTP::Tiny->new }, $pkg;
    return $self;
}

sub set($$) {
    my $self = shift;

    my ($key, $val) = @_; # looking for, "key => val"

    $key  = ($key) ? uri_escape $key : "-";
    $val  = uri_escape $val;

    my $URL  = sprintf "%s/set/%s/%s", BASEURL, $key, $val; # provides a unique key name

    my $resp =  HTTPTiny2h2o $self->ua->get($URL);

    # checks HTTP::Tiny's HTTP status field - though this API appears to
    # not implement meaningful statuses (all returned are 200 OK)
    if (not $resp->success) {
      die $resp;
    }

    if ($resp->content->status ne "SUCCESS") {
      die sprintf("Key: '%s', Error: '%s'\n", $key, $resp->content->status);
    }

    return $resp->content;
}

sub get($) {
    my ($self, $key) = @_;

    $key = uri_escape $key;

    my $URL    = sprintf "%s/get/%s", BASEURL, $key;

    my $resp =  HTTPTiny2h2o $self->ua->get($URL);

    # checks HTTP::Tiny's HTTP status field - though this API appears to
    # not implement meaningful statuses (all returned are 200 OK)
    if (not $resp->success) {
      die $resp;
    }

    if ($resp->content->status ne "SUCCESS") {
      die sprintf("Key: '%s', Error: '%s'\n", $key, $resp->content->status);
    }

    return $resp->content;
}

1;

__END__

=head1 NAME

Webserver::KeyVal::API - Perl API client for the C<KeyVal> service, L<https://keyval.org/>.

This module provides the client, C<kv>, that is available via C<PATH> after install.

=head1 SYNOPSIS

  #!/usr/bin/env perl
      
  use strict;
  use warnings;
  
  my $key = shift @ARGV;
  
  use Webservice::KeyVal::API qw//;
  my $client     = Webservice::KeyVal::API->new;
  my $val        = "foo";
  my $resp       = $client->set($key => $val);    # can die
  printf "%s %s\n", $resp->key, $resp->val;
  
  # ... later get the value back,
  $resp = $client->get($key);                     # can die
  printf "%s %s\n", $resp->key, $resp->val;

=head2 C<kv> Commandline Client

After installing this module, simply run the command C<kv> without any argum
ents to get a URL for a random dog image. See below for all subcommands.

  shell> kv -k mykey -v "this is a value..."  # note: key and value are limited to 101 charactersR
  mykey this is a value...                    # key and value are echo'd out to STDIN
  
  # -k is optional, the webservice provides a unique GUID
  
  shell> kv set -v "this is a value..."
  f7b1d193-16db-4ef6-a447-32ee0734c46f this is a value...

  # value can be piped in via "-v -"

  shell> echo "this is a value..." | kv set -v -
  16aa9ec9-faa1-479e-a575-386809ff883b this is a value...

  # you can do fun shell tricks like this, to get the key you just set

  shell> kv get -k $(kv set -v foobar | awk '{print $1}')
  21348201-cf45-4dfb-a92e-e6ccf04ba395 foobar

=head1 DESCRIPTION

This is the Perl API for the C<KeyVal>, profiled at L<https://www.freepublicapis.com/keyval-api>. 

Contributed as part of the B<FreePublicPerlAPIs> Project described at,
L<https://github.com/oodler577/FreePublicPerlAPIs>.

This fun module is to demonstrate how to use L<Util::H2O::More> and
L<Dispatch::Fu> to make creating easily make API SaaS modules and
clients in a clean and idiomatic way. These kind of APIs tracked at
L<https://www.freepublicapis.com/> are really nice for fun and practice
because they don't require dealing with API keys in the vast majority of cases.

This module is the first one written using L<Util::H2O::More>'s C<HTTPTiny2h2o>
method that looks for C<JSON> in the C<content> key returned via L<HTTP::Tiny>'s
response C<HASH>.

=head1 METHODS

=over 4

=item C<new>

Instantiates object reference. No parameters are accepted.

=item C<set KEY => VAL>

This call will set the C<KEY> to the value of C<VAL> at the KeyVal webservice for
later retreival.

C<KEY> may also be undef, and in fact this is recommended since the service doesn't
seem to delete keys and there is no way to update them.

It is perfectly valid to do the following:

  use Webservice::KeyVal qw//;
  my $client     = Webservice::KeyVal::API->new; 
  my $val        = "foo";
  my $resp       = $client->set(undef => $val);

The webservice will return a guaranteed unique GUID as a key, and you may use this
after to get the value back. If there is an upstream key conflict, then the webservice
returns an C<-KEY-ALREADY-EXISTS-> error. This methods will C<die> if that happens.

It is not documentated, but has been determined empirically that the maximum length
for both keys and values is 101 characters. If a key or value is sent that is longer
than this length, the webservice will return a C<-KEY-OR-VALUE-TOO-LONG-> error.

Also note, the webservice always returns an HTTP status of C<200 OK>, the C<status>
field of the returned JSON must be checked to determine if the was a failure. This
module checks for anything other than C<status => "SUCCESS"> and will C<die> if this
condition is detected.

=item C<get>

=back

=head1 C<kv> OPTIONS

=over 4

=item C<< set -v 'value ...' [-k KEY] >>

C<-v> is required, but can take a special value of a single dash, C<->; this will tell
the client to read in the value via C<< <STDIN> >>. See the example in the L<SYNOPSIS>.

  shell>kv -k mykey -v "some value"
  mykey some value

C<-k> is optional, and it is actually recommend that this not be sent so that the webservice
can accept the value and return back a unique GUID that you use to later retreived the
value.

  shell> echo "this is a value..." | kv set -v -
  16aa9ec9-faa1-479e-a575-386809ff883b this is a value...

Keys and values are restricted to a length of 101 characters. Values can also not be
deleted or updated, per the KeyVal API specification.

=item C<< get -k KEY] >>

C<-k> is required and specifies a valid key. The webservice will return the value of
this key, and this client will print it out for you to use.

=back

=head2 Internal Methods

There are no internal methods to speak of.

=head1 NOTES ABOUT THE API

Through the development of this module and associated commandline utility, C<kv>, it
has been noted that:

=over 4

=item HTTP Status

the API always returns C<200 OK> to check if the call succeeded or failed, one
must check the C<status> field.

=item Length limits

keys and values are limited to 101 characters each

=item Don't specify key names

it is almost always to just send the value and not specify a key, the chances
of collision with existing keys is high; better to let the webservice give you the
GUID it can return; this will always be ok unless the value sent is greater than 101
characters

=back

=head1 ENVIRONMENT

Nothing special required.

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

=head1 BUGS

Please report.

=head1 LICENSE AND COPYRIGHT

Same as Perl/perl.
