package WWW::SFDC;
# ABSTRACT: Wrappers around the Salesforce.com APIs.

use strict;
use warnings;
use 5.12.0;

our $VERSION = '0.37'; # VERSION

use Data::Dumper;
use Log::Log4perl ':easy';
use Method::Signatures;
use WWW::SFDC::CallResult;

use Moo;


has 'apiVersion',
  is => 'ro',
  isa => sub {
    LOGDIE "The API version ($_[0]) must be >= 31."
      unless $_[0] and $_[0] >= 31
  },
  default => '33.0';


has 'loginResult',
  is => 'rw',
  lazy => 1,
  builder => '_login';


has 'password',
  is => 'ro',
  required => 1;


has 'pollInterval',
  is => 'rw',
  default => 15;


has 'attempts',
  is => 'rw',
  default => 3;


has 'url',
  is => 'ro',
  default => "https://test.salesforce.com",
  isa => sub { $_[0] and $_[0] =~ s/\/$// or 1; }; #remove trailing slash


has 'username',
  is => 'ro',
  required => 1;

INIT: {
  # Import each API module by reflection. This enables calling them using
  # $session->$API->$method, but it means that when packing you must
  # manually add the right modules, since there aren't 'compile'-time
  # static C<use> statements.
  for my $module (qw'
    Apex Constants Metadata Partner Tooling
  '){
    has $module,
      is => 'ro',
      lazy => 1,
      default => sub {
        my $self = shift;
        require "WWW/SFDC/$module.pm"; ## no critic
        "WWW::SFDC::$module"->new(session => $self);
      };
  }
}

method _login {

  INFO "Logging in...\t";

  my $request = SOAP::Lite
    ->proxy(
      $self->url()."/services/Soap/u/".$self->apiVersion()
    )
    ->readable(1)
    ->ns("urn:partner.soap.sforce.com","urn")
    ->call(
      'login',
      SOAP::Data->name("username")->value($self->username),
      SOAP::Data->name("password")->value($self->password)
    );

  TRACE "Request: " . Dumper $request;
  WWW::SFDC::CallException->throw(
    message => "Login failed: " . $request->faultstring,
    request => $request
  ) if $request->fault;

  return $request->result();
}


method _doCall ($attempts, $URL, $NS, $method, @params) {

  # This is the utility method behind call(). It orchestrates the actual
  # SOAP::Lite call with the correct parameters and detects connection vs
  # SOAP errors.

  INFO "Starting $method request";
  if (
    my $result = eval {
      # SOAP::Lite dies when there's a connection error; if there's an API
      # error it lives but $result->fault is set. This allows us to detect
      # network errors and retry.
      SOAP::Lite
        ->proxy($URL)
        ->readable(1)
        ->default_ns($NS)
        ->call(
          $method,
          @params,
          SOAP::Header->name("SessionHeader" => {
            "sessionId" => $self->loginResult->{"sessionId"}
          })->uri($NS)
        );
    }
  ) {
    return $result;

  } elsif ($attempts) {
    # Looping by recursion makes it easier to write this bit.
    INFO "$method failed: $@";
    INFO "Retrying ($attempts attempts remaining)";
    return $self->_doCall($attempts-1, $URL, $NS, $method, @params);

  } else {
    WWW::SFDC::CallException->throw(
      message => "$method failed: " . $@
    );
  }
}

method call (@_) {
  my $result;

  until (
    # CallResult is falsy when the call failed
    $result = $self->_doCall($self->attempts, @_)
  ) {
    TRACE "Operation request " => Dumper $result;

    if ($result->faultstring =~ /INVALID_SESSION_ID/) {
      $self->loginResult($self->_login());
    } else {
      WWW::SFDC::CallException->throw(
        message => "$_[2] failed: " . $result->faultstring,
        request => $result
      );
    }
  }

  return WWW::SFDC::CallResult->new(request => $result);
};


method isSandbox {
  return $self->loginResult->{sandbox} eq  "true";
}

1;


package WWW::SFDC::CallException;
# CallException allows sensible handling of API errors;
# L<WWW::SFDC::Role::Exception> provides overloaded stringification so that
# when you C<die $exception;> there's a sensible error message, but you can
# still examine the request and response in a consumer library.

use strict;
use warnings;
use Moo;
with 'WWW::SFDC::Role::Exception';

has 'request',
  is => 'ro';

1;

__END__

=pod

=head1 NAME

WWW::SFDC - Wrappers around the Salesforce.com APIs.

=head1 VERSION

version 0.37

=head1 SYNOPSIS

    use WWW::SFDC;

    # Create session object. This will cache your credentials for use in
    # all subsequent API calls.
    my $session = WWW::SFDC->new(
      username => $username,
      password => $password,
      url => url,
      apiVersion => apiversion
    );

    # Access API calls by specifying which API you're calling and the
    # method you want to use, for instance:
    $session->Apex->executeAnonymous('system.debug(1);');
    $session->Partner->query('SELECT Id FROM Account LIMIT 10');

=head1 OVERVIEW

WWW::SFDC provides a set of packages which you can use to build useful
interactions with Salesforce.com's many APIs. Initially it was intended for
the construction of powerful and flexible deployment tools.

The idea is to provide a 'do what I mean' interface which allows the full
power of all of the SOAP APIs whilst abstracting away the details of status
checking and extracting results.

=head2 Contents

=over 4

=item WWW::SFDC

Provides the lowest-level interaction with SOAP::Lite. Handles the SessionID
and renews it when necessary.

You should not need to interact with WWW::SFDC itself beyond constructing and
calling API modules - the methods in this class are in general plumbing.

=item L<WWW::SFDC::Constants>

Retrieves and caches the metadata objects as returned by DescribeMetadata for
use when trying to interact with the filesystem etc.

=item L<WWW::SFDC::Manifest>

Stores and manipulates lists of metadata for retrieving and deploying to and
from Salesforce.com.

=item L<WWW::SFDC::Metadata>

Wraps the Metadata API.

=item L<WWW::SFDC::Partner>

Wraps the Partner API.

=item L<WWW::SFDC::Tooling>

Wraps the Tooling API.

=item L<WWW::SFDC::Zip>

Provides utilities for creating and extracting base-64 encoded zip files for
Salesforce.com retrievals and deployments.

=back

=head1 ATTRIBUTES

=head2 apiVersion

The API version with which to call Salesforce.com. Must be over 30, since the
metadata API interface changed quite a lot in 31. Defaults to 33.

=head2 loginResult

The result of the login call. API modules use this to populate the correct
endpoint URL.

=head2 password

Used to authenticate with Salesforce.com. Unless you have a whitelisted IP
address, this needs to include your security token.

=head2 pollInterval

How long (in seconds) WWW::SFDC should wait between retries, and how often it
should poll for updates on asynchronous jobs. Defaults to 15 seconds.

=head2 attempts

How many times WWW::SFDC should retry when encountering connection issues.
Defaults to 3. It's a good idea to have this value above 0, since SFDC
occasionally returns 500 errors when under heavy load.

=head2 url

The URL to use when logging into Salesforce. Defaults to
L<https://test.salesforce.com> - set this to L<https://login.salesforce.com> or
to a specific instance as appropriate.

=head2 username

Used for authentication against SFDC.

=head1 METHODS

=head2 call($URL, $NameSpace, $method, @parameters)

Executes a Salesforce.com API call. This will retry C<$self->attempts> times in
the event of a connection error, and if the session is invalid it will refresh
the session ID by issuing a new login request.

Returns a L<WWW::SFDC::CallResult> and throws a L<WWW::SFDC::CallException>.

=head2 isSandbox

Returns 1 if the org associated with the given credentials are a sandbox. Use to
decide whether to sanitise metadata or similar.

=head1 EXPERIMENTAL

This module is quite unstable, as it's early in its development cycle. I'm
trying to avoid breaking too much, but until it hits 1.0, there is a risk of
breakage.

There are also lots of unimplemented API calls in some of the libraries. This
is because I don't currently have a use-case for them so it's not clear what
the return types or testing mechanisms should be. Pull requests are welcome!

=head1 METADATA API EXAMPLES

=head2 Retrieval of metadata

The following provides a starting point for a simple retrieval tool. Notice
that after the initial setup of WWW::SFDC the login credentials are cached. In
this example, you'd use _retrieveTimeMetadataChanges to remove files you
didn't want to track, change sandbox outbound message endpoints to production,
or similar.

Notice that I've tried to keep the manifest interface as fluent as possible -
every method which doesn't have an obvious return value returns $self.

    package ExampleRetrieval;

    use WWW::SFDC;
    use WWW::SFDC::Manifest;
    use WWW::SFDC::Zip qw'unzip';

    my ($password, $username, $url, $apiVersion, $package);

    sub _retrieveTimeMetadataChanges {
      my ($path, $content) = @_;
      return $content;
    }

    my $client = WWW::SFDC->new(
      password  => $password,
      username  => $username,
      url       => $url
    );

    my $manifest = WWW::SFDC::Manifest->new(
            constants => $client->Constants,
            apiVersion => $apiVersion
      )
      ->readFromFile($package)
      ->add(
        $session->Metadata->listMetadata(
            {type => 'Document', folder => 'Apps'},
            {type => 'Document', folder => 'Developer_Documents'},
            {type => 'EmailTemplate', folder => 'Asset'},
            {type => 'ApexClass'}
          )
      );

    unzip
      'src/',
      $session->Metadata->retrieveMetadata($manifest->manifest()),
      \&_retrieveTimeMetadataChanges;

=head2 Deployment

Here's a similar example for deployments. You'll want to construct
@filesToDeploy and $deployOptions context-sensitively!

    package ExampleDeployment;

    use WWW::SFDC;
    use WWW::SFDC::Manifest;
    use WWW::SFDC::Zip qw'makezip';


    my $client = WWW::SFDC->new(
      password  => $password,
      username  => $username,
      url       => $url
    );

    my $manifest = WWW::SFDC::Manifest
      ->new(constants => $client->Constants)
      ->addList(@filesToDeploy)
      ->writeToFile('src/package.xml');

    my $zip = makezip
      'src',
      $manifest->getFileList(),
      'package.xml';

    my $deployOptions = {
       singlePackage => 'true',
       rollbackOnError => 'true',
       checkOnly => 'true'
    };

    $client->Metadata->deployMetadata($zip, $deployOptions);

=head1 PARTNER API EXAMPLE

To unsanitise some users' email address and change their profiles
on a new sandbox, you might do something like this:

    package ExampleUserSanitisation;

    use WWW::SFDC;
    use List::Util qw'first';

    my $client = WWW::SFDC->new(
      username => $username,
      password => $password,
      url => $url
    );

    my @users = (
      {
        User => 'alexander.brett',
        Email => 'alex@example.com',
        Profile => $profileId
      }, {
        User => 'another.user',
        Email => 'a.n.other@example.com',
        Profile => $profileId
      },
    );

    $client->Partner->update(
      map {
        my $row = $_;
        my $original = first {$row->{Username} =~ /$$_{User}/} @users;
        +{
           Id => $row->{Id},
           ProfileId => $original->{Profile},
           Email => $original->{Email},
        }
      } $client->Partner->query(
          "SELECT Id, Username FROM User WHERE "
          . (
            join " OR ",
              map {"Username LIKE '%$_%'"} map {$_->{User}} @inputUsers
          )
        )
    );

=head1 SEE ALSO

=head2 L<App::SFDC>

App::SFDC uses WWW::SFDC to provide a command-line application for interacting
with Salesforce.com

=head2 ALTERNATIVES

Both of these modules offer more straightforward, comprehensive and mature
wrappers around the Partner API than this module does at the moment. If all of
your requirements can be fulfilled by that, you may be better off using them.

This module is designed for use in deployment applications, or when you want
to juggle multiple APIs to provide complicated functionality.

=over 4

=item L<WWW::Salesforce>

=item L<Salesforce>

=back

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/sophos/WWW-SFDC/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::SFDC
    perldoc WWW::SFDC::Metadata
    ...

You can also look for information at L<https://github.com/sophos/WWW-SFDC>

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
