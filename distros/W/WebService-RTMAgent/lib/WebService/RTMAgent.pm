use strict;
use warnings;
package WebService::RTMAgent;
# ABSTRACT: a user agent for the Remember The Milk API
$WebService::RTMAgent::VERSION = '0.602';
#pod =head1 SYNOPSIS
#pod
#pod  $ua = WebService::RTMAgent->new;
#pod  $ua->api_key($key_provided_by_rtm);
#pod  $ua->api_secret($secret_provided_by_rtm);
#pod  $ua->init;
#pod  $url = $ua->get_auth_url;  # then do something with the URL
#pod  $res = $ua->tasks_getList('filter=status:incomplete');
#pod
#pod  ...
#pod
#pod =head1 DESCRIPTION
#pod
#pod WebService::RTMAgent is a Perl implementation of the rememberthemilk.com API.
#pod
#pod =head2 Calling API methods
#pod
#pod All API methods documented at L<https://www.rememberthemilk.com/services/api/>
#pod can be called as methods, changing dots for underscores and optionnaly taking
#pod off the leading 'rtm': C<< $ua->auth_checkToken >>, C<< $ua->tasks_add >>, etc.
#pod
#pod Parameters should be given as a list of strings, e.g.:
#pod
#pod   $ua->tasks_complete(
#pod     "list_id=4231233",
#pod     "taskseries_id=124233",
#pod     "task_id=1234",
#pod   );
#pod
#pod Refer to the API documentation for each method's parameters.
#pod
#pod Return values are the XML response, parsed through L<XML::Simple>. Please refer
#pod to XML::Simple for more information (and Data::Dumper, to see what the values
#pod look like) and the sample B<rtm> script for examples.
#pod
#pod If the method call was not successful, C<undef> is returned, and an error
#pod message is set which can be accessed with the B<error> method:
#pod
#pod   $res = $ua->tasks_getList;
#pod   die $ua->error unless defined $res;
#pod
#pod Please note that at this stage, I am not very sure that this is the best way to implement the API. "It works for me," but:
#pod
#pod =for :list
#pod * Parameters may turn to hashes at some point
#pod * Output values may turn to something more abstract and useful,
#pod   as I gain experience with API usage.
#pod
#pod =head2 Authentication and authorisation
#pod
#pod Before using the API, you need to authenticate it. If you are going to be
#pod building a desktop application, you should get an API key and shared secret
#pod from the people at rememberthemilk.com (see
#pod L<https://groups.google.com/group/rememberthemilk-api/browse_thread/thread/dcb035f162d4dcc8>
#pod for rationale) and provide them to RTMAgent.pm with the C<api_key> and
#pod C<api_secret> methods.
#pod
#pod You then need to proceed through the authentication cycle: create a useragent,
#pod call the get_auth_url method and direct a Web browser to the URL it returns.
#pod There RememberTheMilk will present you with an authorisation page: you can
#pod authorise the API to access your account.
#pod
#pod At that stage, the API will get a token which identifies the API/user
#pod authorisation. B<RTMAgent> saves the token in a file, so you should never need
#pod to do the authentication again.
#pod
#pod =head2 Proxy and other strange things
#pod
#pod The object returned by B<new> is also a LWP::UserAgent. This means you can
#pod configure it the same way, in particular to cross proxy servers:
#pod
#pod   $ua = new WebService::RTMAgent;
#pod   $ua->api_key($key);
#pod   $ua->api_secret($secret);
#pod   $ua->proxy('http', 'https://proxy:8080');
#pod   $ua->init;
#pod   $list = $ua->tasks_getList;
#pod
#pod Incidentally, this is the reason why the C<init> method exists: C<init> needs
#pod to access the network, so its work cannot be done in C<new> as that would leave
#pod no opportunity to configure the LWP::UserAgent.
#pod
#pod =cut

use Carp;
use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;
use XML::Simple;

use parent 'LWP::UserAgent';

my $REST_endpoint = "https://api.rememberthemilk.com/services/rest/";
my $auth_endpoint = "https://api.rememberthemilk.com/services/auth/";

our $config_file = "$ENV{HOME}/.rtmagent";
our $config;  # reference to config hash

#pod =head1 PUBLIC METHODS
#pod
#pod =head2 $ua = WebService::RTMAgent->new;
#pod
#pod Creates a new agent.
#pod
#pod =cut

sub new {
    my $class = shift;
    Carp::confess("tried to call ->new on an instance") if ref $class;
    my $self  = $class->SUPER::new(@_);
    $self->verbose('');
    return bless $self, $class;
}

#pod =head2 $ua->api_key($key);
#pod
#pod =head2 $ua->api_secret($secret);
#pod
#pod Set the API key and secret. These are obtained from the people are
#pod RememberTheMilk.com.
#pod
#pod =head2 $ua->verbose('netin netout');
#pod
#pod Sets what type of traces the module should print. You can use 'netout' to print
#pod all the outgoing messages, 'netin' to print all the incoming messages.
#pod
#pod =head2 $err = $ua->error;
#pod
#pod Get a message describing the last error that happened.
#pod
#pod =cut

# Create accessors
BEGIN {
    my $subs;
    foreach my $data ( qw/error verbose api_secret api_key/ ) {
        $subs .= qq{
            sub $data {
                \$_[0]->{rtma_$data} =  
                    defined \$_[1] ? \$_[1] : \$_[0]->{rtma_$data};
            }
        }
    }
    eval $subs;
}

#pod =head2 $ua->init;
#pod
#pod Performs authentication with RTM and various other book-keeping
#pod initialisations.
#pod
#pod =cut

sub init {
    my ($self) = @_;

    if (-e $config_file) {
        die "$config_file: can't read or write\n"
          unless -r $config_file and -w $config_file;

        my $ok = eval {
          $config = XMLin($config_file, KeyAttr=>'', ForceArray => ['undo']);
          1;
        };
        croak "$config_file: Invalid XML file" unless $ok;
    }

    # Check Token
    if ($config->{token}) {
        my $res = $self->auth_checkToken;
        if (not defined $res) {
            delete $config->{frob};
            delete $config->{token};
            croak $self->error;
        }
    }

    # If we have a frob and no token, we're half-way through
    # authentication -- finish it
    if ($config->{frob} and not $config->{token}) {
        warn "frobbed -- getting token\n";
        my $res = $self->auth_getToken("frob=$config->{frob}");
        die $self->error."(Maybe you need to erase $config_file)\n"
          unless defined $res;
        $config->{token} = $res->{auth}->[0]->{token}->[0];
        warn "token $config->{token}\n";
    }

    # If we have no timeline, get one
    unless ($config->{timeline}) {
        my $res = $self->timelines_create();
        $config->{timeline} = $res->{timeline}->[0];
        $config->{undo} = [];
    }
}

#pod =head2 $ua->get_auth_url;
#pod
#pod Performs the beginning of the authentication: this returns a URL to which
#pod the user must then go to allow RTMAgent to access his or her account.
#pod
#pod This mecanism is slightly contrieved and designed so that users do not have
#pod to give their username and password to third party software (like this one).
#pod
#pod =cut

sub get_auth_url {
    my ($self) = @_;

    my $res = $self->auth_getFrob();

    my $frob = $res->{'frob'}->[0];

    my @params;
    push @params, "api_key=".$self->api_key, "perms=delete", "frob=$frob";
    push @params, "api_sig=".($self->sign(@params));

    my $url = "$auth_endpoint?". (join '&', @params);

    # save frob for later
    $config->{'frob'} = $frob;

    return $url;
}

#pod =head2 @undo = $ua->get_undoable;
#pod
#pod Returns the transactions which we know how to undo (unless data has been lost,
#pod that's all the undo-able transaction that go with the timeline that is saved in
#pod the state file).
#pod
#pod The value returned is a list of { id, op, [ params ] } with id the transaction
#pod id, op the API method that was called, and params the API parameters that were
#pod called.
#pod
#pod =cut

sub get_undoable {
    my ($self) = @_;

    return $config->{undo};
}

#pod =head2 $ua->clear_undo(3);
#pod
#pod Removes an undo entry.
#pod
#pod =cut

sub clear_undo {
    my ($self, $index) = @_;

    splice @{$config->{undo}}, $index, 1;
}

#pod =head1 PRIVATE METHODS
#pod
#pod Don't use those and we'll stay friends.
#pod
#pod =head2 $ua->sign(@params);
#pod
#pod Returns the md5 signature for signing parameters. See RTM Web site for details.
#pod This should only be useful for the module, don't use it.
#pod
#pod =cut

sub sign {
    my ($self, @params) = @_;

    my $sign_str = join '', sort @params;
    $sign_str =~ s/=//g;

    return md5_hex($self->api_secret."$sign_str");
}

#pod =head2 $ua->rtm_request("rtm.tasks.getList", "list_id=234", "taskseries_id=2"..)
#pod
#pod Signs the parameters, performs the request, returns a parsed XML::Simple
#pod object.
#pod
#pod =cut

sub rtm_request {
    my ($self, $request, @params) = @_;

    unshift @params, "method=$request";
    push @params, "api_key=".$self->api_key;
    push @params, "auth_token=$config->{token}" if exists $config->{token};
    push @params, "timeline=$config->{timeline}" if exists $config->{timeline};
    my $sig = $self->sign(@params);
    my $param = join '&', @params;

    my $req = HTTP::Request->new( POST => $REST_endpoint);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("$param&api_sig=$sig");
    warn("request:\n".$req->as_string."\n\n") if $self->verbose =~ /netout/;

    my $res = $self->request($req);
    die $res->status_line unless $res->is_success;

    warn("response:\n".$res->as_string."\n\n") if $self->verbose =~ /netin/;
    return XMLin($res->content, KeyAttr=>'', ForceArray=>1);
}

# AUTOLOAD gets calls to undefined functions
# we add 'rtm' and change underscores to dots, to change perl function
# names to RTM API: tasks_getList => rtm.tasks.getList
# arguments are as strings:
# $useragent->tasks_complete("list_id=$a", "taskseries_id=$b" ...);
our $AUTOLOAD;
sub AUTOLOAD {
    my $function = $AUTOLOAD;

    my $self = shift;

    $function =~ s/^.*:://; # Remove class name
    $function =~ s/_/./g;   # Change underscores to dots (auth_getFrob => auth.getFrob)
    $function =~ s/^/rtm./ unless $function =~ /^rtm./; # prepends rtm if needed
    my $res = $self->rtm_request($function, @_);

    # Treat errors
    if (exists $res->{'err'}) {
        croak ("$function does not exist\n") if $res->{'err'}->[0]->{'code'} == 112;
        $self->error("$res->{'err'}->[0]->{'code'}: $res->{'err'}->[0]->{'msg'}\n");
        return undef;
    }

    # If action is undo-able, store transaction ID
    if (exists $res->{transaction} and
        exists $res->{transaction}->[0]->{undoable}) {
        push @{$config->{undo}}, {
                'id' => $res->{transaction}->[0]->{id},
                'op' => $function,
                'params' => \@_,
            };
    }
    return $res;
}


# When destroying the object, save the config file
# (careful, this all means we can only have one instance running...)
sub DESTROY {
    return unless defined $config;
    open my $f, "> $config_file";
    print $f XMLout($config, NoAttr=>1, RootName=>'RTMAgent');
}

#pod =head1 FILES
#pod
#pod =for :list
#pod = F<~/.rtmagent>
#pod XML file containing runtime data: frob, timeline, authentication token. This
#pod file is overwritten on exit, which means you should only have one instance of
#pod RTMAgent (this should be corrected in a future version).
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * C<< L<rtm|https://www.rutschle.net/rtm> >>, example command-line script.
#pod * L<LWP::UsrAgent>
#pod * L<XML::Simple>
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::RTMAgent - a user agent for the Remember The Milk API

=head1 VERSION

version 0.602

=head1 SYNOPSIS

 $ua = WebService::RTMAgent->new;
 $ua->api_key($key_provided_by_rtm);
 $ua->api_secret($secret_provided_by_rtm);
 $ua->init;
 $url = $ua->get_auth_url;  # then do something with the URL
 $res = $ua->tasks_getList('filter=status:incomplete');

 ...

=head1 DESCRIPTION

WebService::RTMAgent is a Perl implementation of the rememberthemilk.com API.

=head2 Calling API methods

All API methods documented at L<https://www.rememberthemilk.com/services/api/>
can be called as methods, changing dots for underscores and optionnaly taking
off the leading 'rtm': C<< $ua->auth_checkToken >>, C<< $ua->tasks_add >>, etc.

Parameters should be given as a list of strings, e.g.:

  $ua->tasks_complete(
    "list_id=4231233",
    "taskseries_id=124233",
    "task_id=1234",
  );

Refer to the API documentation for each method's parameters.

Return values are the XML response, parsed through L<XML::Simple>. Please refer
to XML::Simple for more information (and Data::Dumper, to see what the values
look like) and the sample B<rtm> script for examples.

If the method call was not successful, C<undef> is returned, and an error
message is set which can be accessed with the B<error> method:

  $res = $ua->tasks_getList;
  die $ua->error unless defined $res;

Please note that at this stage, I am not very sure that this is the best way to implement the API. "It works for me," but:

=over 4

=item *

Parameters may turn to hashes at some point

=item *

Output values may turn to something more abstract and useful, as I gain experience with API usage.

=back

=head2 Authentication and authorisation

Before using the API, you need to authenticate it. If you are going to be
building a desktop application, you should get an API key and shared secret
from the people at rememberthemilk.com (see
L<https://groups.google.com/group/rememberthemilk-api/browse_thread/thread/dcb035f162d4dcc8>
for rationale) and provide them to RTMAgent.pm with the C<api_key> and
C<api_secret> methods.

You then need to proceed through the authentication cycle: create a useragent,
call the get_auth_url method and direct a Web browser to the URL it returns.
There RememberTheMilk will present you with an authorisation page: you can
authorise the API to access your account.

At that stage, the API will get a token which identifies the API/user
authorisation. B<RTMAgent> saves the token in a file, so you should never need
to do the authentication again.

=head2 Proxy and other strange things

The object returned by B<new> is also a LWP::UserAgent. This means you can
configure it the same way, in particular to cross proxy servers:

  $ua = new WebService::RTMAgent;
  $ua->api_key($key);
  $ua->api_secret($secret);
  $ua->proxy('http', 'https://proxy:8080');
  $ua->init;
  $list = $ua->tasks_getList;

Incidentally, this is the reason why the C<init> method exists: C<init> needs
to access the network, so its work cannot be done in C<new> as that would leave
no opportunity to configure the LWP::UserAgent.

=head1 PUBLIC METHODS

=head2 $ua = WebService::RTMAgent->new;

Creates a new agent.

=head2 $ua->api_key($key);

=head2 $ua->api_secret($secret);

Set the API key and secret. These are obtained from the people are
RememberTheMilk.com.

=head2 $ua->verbose('netin netout');

Sets what type of traces the module should print. You can use 'netout' to print
all the outgoing messages, 'netin' to print all the incoming messages.

=head2 $err = $ua->error;

Get a message describing the last error that happened.

=head2 $ua->init;

Performs authentication with RTM and various other book-keeping
initialisations.

=head2 $ua->get_auth_url;

Performs the beginning of the authentication: this returns a URL to which
the user must then go to allow RTMAgent to access his or her account.

This mecanism is slightly contrieved and designed so that users do not have
to give their username and password to third party software (like this one).

=head2 @undo = $ua->get_undoable;

Returns the transactions which we know how to undo (unless data has been lost,
that's all the undo-able transaction that go with the timeline that is saved in
the state file).

The value returned is a list of { id, op, [ params ] } with id the transaction
id, op the API method that was called, and params the API parameters that were
called.

=head2 $ua->clear_undo(3);

Removes an undo entry.

=head1 PRIVATE METHODS

Don't use those and we'll stay friends.

=head2 $ua->sign(@params);

Returns the md5 signature for signing parameters. See RTM Web site for details.
This should only be useful for the module, don't use it.

=head2 $ua->rtm_request("rtm.tasks.getList", "list_id=234", "taskseries_id=2"..)

Signs the parameters, performs the request, returns a parsed XML::Simple
object.

=head1 FILES

=over 4

=item F<~/.rtmagent>

XML file containing runtime data: frob, timeline, authentication token. This
file is overwritten on exit, which means you should only have one instance of
RTMAgent (this should be corrected in a future version).

=back

=head1 SEE ALSO

=over 4

=item *

C<< L<rtm|https://www.rutschle.net/rtm> >>, example command-line script.

=item *

L<LWP::UsrAgent>

=item *

L<XML::Simple>

=back

=head1 AUTHOR

Yves Rutschle

=head1 CONTRIBUTORS

=for stopwords Ed Santiago Ricardo Signes Yves Rutschle

=over 4

=item *

Ed Santiago <ed@edsantiago.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Yves Rutschle <CENSORED>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Yves Rutschle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
