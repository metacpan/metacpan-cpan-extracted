
package WebService::Rollbar::Notifier;

use strict;
use warnings;

our $VERSION = '1.002010'; # VERSION

use Carp;
use Scalar::Util qw/blessed/;
use Mojo::Base -base;
use Mojo::UserAgent;

# HTTPS for some reason fails on Solaris, based on smoker tests
my $API_URL = ($^O eq 'solaris'?'http':'https').'://api.rollbar.com/api/1/';

has _ua => sub { Mojo::UserAgent->new; };
has callback => sub {
    ## Null by default, but not undef, because undef for callback
    ## means we want to block
};

has environment => 'production';
has [ qw/access_token  code_version framework language server/ ];

sub critical { my $self = shift; $self->notify( 'critical', @_ ); }
sub error    { my $self = shift; $self->notify( 'error',    @_ ); }
sub warning  { my $self = shift; $self->notify( 'warning',  @_ ); }
sub info     { my $self = shift; $self->notify( 'info',     @_ ); }
sub debug    { my $self = shift; $self->notify( 'debug',    @_ ); }

sub _parse_message_param {
    my $message = shift;

    if (ref($message) eq 'ARRAY') {
        return ($message->[0], $message->[1]||{});
    } else {
        return ($message, {} );
    }
}
sub report_message {
    my ($self) = shift;
    my ($message, $request_params) = @_;

    my ($body, $custom) = _parse_message_param($message);

    return $self->_post(
        {
            message => {
                body    => $body,
                %{ $custom },
            },
        },
        $request_params,
    );
}

sub notify {
    my $self = shift;
    my ( $severity, $message, $custom ) = @_;

    return $self->report_message( [$message, $custom], {level => $severity} );
}


my @frame_optional_fields =
    qw/lineno colno method code context argspec varargspec keywordspec locals /
;

sub _parse_exception_params {
    my @params = @_;

    my $request_params =
        ref $params[-1] eq 'HASH'
            ? pop @params
            : {}
    ;
    my $frames = _extract_frames(pop @params);

    my ($class, $message, $description) = @params;

    return (
        {
            class       => $class,
            (defined $message     ? (message => $message) : ()),
            (defined $description ? (description => $description) : ()),
        },
        $frames,
        $request_params,
    );
}
sub _devel_stacktrace_frame_to_rollbar {
    my $frame = shift;
    return {
        filename    => $frame->filename,
        lineno      => $frame->line,
        method      => $frame->subroutine,
        # code
        # context {}
        # varargspec: args
        # locals: { args => ... }
    }
}
sub _extract_frames {
    my $trace = shift;

    if ( ref($trace) eq 'ARRAY' ) {
        # Assume rollbar-ready frames
        return $trace;
    }
    if ( blessed($trace) and $trace->isa("Devel::StackTrace") ) {
        return [
            map { _devel_stacktrace_frame_to_rollbar( $_ ) }
                $trace->frames
        ];
    }

    return ();
}

sub report_trace {
    my $self = shift;

    my ($exception_data, $frames, $request_params) = _parse_exception_params(@_);

    return $self->_post(
        {
            trace => {
                exception   => $exception_data,
                frames      => $frames,
            }
        },
        $request_params,
    );
}

sub _post {
    my $self = shift;
    my ( $body, $request_optionals ) = @_;

    my @instance_optionals = (
        map +( defined $self->$_ ? ( $_ => $self->$_ ) : () ),
            qw/code_version framework language server/
    );
    my @request_optionals = (
        map +( exists $request_optionals->{$_} ? ( $_ => $request_optionals->{$_} ) : () ),
            qw/level context request person server client custom fingerprint uuid title/
    );

    my $response = $self->_ua->post(
        $API_URL . 'item/',
        json => {
            access_token => $self->access_token,
            data => {
                environment => $self->environment,

                body => $body,

                platform  => $^O,
                timestamp => time(),

                @instance_optionals,

                context => scalar( caller 3 ),

                @request_optionals,

                notifier => {
                    name => 'WebService::Rollbar::Notifier',
                    version => $VERSION,
                },

            },
        },

        ( $self->callback ? $self->callback : () ),
    );

    return $self->callback ? (1) : $response;
}


'
"Most of you are familiar with the virtues of a programmer.
 There are three, of course: laziness, impatience, and hubris."
                                                -- Larry Wall
';

__END__

=encoding utf8

=for stopwords Znet Zoffix subref www.rollbar.com.

=head1 NAME

WebService::Rollbar::Notifier - send messages to www.rollbar.com service

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use WebService::Rollbar::Notifier;

    my $roll = WebService::Rollbar::Notifier->new(
        access_token => 'YOUR_post_server_item_ACCESS_TOKEN',
    );

    $roll->debug("Testing example stuff!",
        # this is some optional, abitrary data we're sending
        { foo => 'bar',
            caller => scalar(caller()),
            meow => {
                mew => {
                    bars => [qw/1 2 3 4 5 /],
                },
        },
    });

=for html  </div></div>

=head1 DESCRIPTION

This Perl module allows for blocking and non-blocking
way to send messages to L<www.rollbar.com|http://www.rollbar.com> service.

=head1 HTTPS ON SOLARIS

Note, this module will use HTTPS on anything but Solaris, where it will switch
to use plain HTTP. Based on CPAN Testers, the module fails with HTTPS there,
but since I don't have a Solaris box, I did not bother investigating this
fully. Patches are more than welcome.

=head1 METHODS

=head2 C<< ->new() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $roll = WebService::Rollbar::Notifier->new(
        access_token => 'YOUR_post_server_item_ACCESS_TOKEN',

        # all these are optional; defaults shown:
        environment     => 'production',
        code_version    => undef,
        framework       => undef,
        server          => undef,
        callback        => sub {},
    );

Creates and returns new C<WebService::Rollbar::Notifier> object.
Takes arguments as key/value pairs:

=head3 C<access_token>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

    my $roll = WebService::Rollbar::Notifier->new(
        access_token => 'YOUR_post_server_item_ACCESS_TOKEN',
    );

B<Mandatory>. This is your C<post_server_item>
project access token.

=head3 C<environment>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

    my $roll = WebService::Rollbar::Notifier->new(
        ...
        environment     => 'production',
    );

B<Optional>. Takes a string B<up to 255 characters long>. Specifies
the environment we're messaging from. B<Defaults to> C<production>.

=head3 C<code_version>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

    my $roll = WebService::Rollbar::Notifier->new(
        ...
        code_version    => undef,
    );

B<Optional>. B<By default> is not specified.
Takes a string up to B<40 characters long>. Describes the version
of the application code. Rollbar understands these formats:
semantic version (e.g. C<2.1.12>), integer (e.g. C<45>),
git SHA (e.g. C<3da541559918a808c2402bba5012f6c60b27661c>).

=head3 C<framework>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

    my $roll = WebService::Rollbar::Notifier->new(
        ...
        framework    => undef,
    );

B<Optional>. B<By default> is not specified.
The name of the framework your code uses

=head3 C<server>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-hashref.png">

    my $roll = WebService::Rollbar::Notifier->new(
        ...
        server    => {
            # Rollbar claims to understand following keys:
            host    => "server_name",
            root    => "/path/to/app/root/dir",
            branch  => "branch_name",
            code_version => "b6437f45b7bbbb15f5eddc2eace4c71a8625da8c",
        }
    );

B<Optional>. B<By default> is not specified.
Takes a hashref, which is used as "server" part of every Rollbar request made
by this notifier instance. See L<https://rollbar.com/docs/api/items_post/> for
detailed description of supported fields.

=head3 C<callback>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-subref.png">

    # do nothing in the callback; this is default
    my $roll = WebService::Rollbar::Notifier->new(
        ...
        callback => sub {},
    );

    # perform a blocking call
    my $roll = WebService::Rollbar::Notifier->new(
        ...
        callback => undef,
    );

    # non-blocking; do something usefull in the callback
    my $roll = WebService::Rollbar::Notifier->new(
        ...
        callback => sub {
            my ( $ua, $tx ) = @_;
            say $tx->res->body;
        },
    );

B<Optional>. B<Takes> C<undef> or a subref as a value.
B<Defaults to> a null subref. If set to C<undef>, notifications to
L<www.rollbar.com|http://www.rollbar.com> will be
blocking, otherwise non-blocking, with
the C<callback> subref called after a request completes. The subref
will receive in its C<@_> the L<Mojo::UserAgent> object that
performed the call and L<Mojo::Transaction::HTTP> object with the
response.

=head2 C<< -E<gt>notify() >>

    $roll->notify('debug', "Message to send", {
        any      => 'custom',
        optional => 'data',
        to       => [qw/send goes here/],
    });

    # if we're doing blocking calls, then return value will be
    # the response JSON

    use Data::Dumper;;
    $roll->callback(undef);
    my $response = $roll->notify('debug', "Message to send");
    say Dumper( $response->res->json );

Takes two mandatory and one optional arguments. Always returns
true value if we're making non-blocking calls (see
C<callback> argument to constructor). Otherwise, returns the response
as L<Mojo::Transaction::HTTP> object. The arguments are:

=head3 First argument

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

    $roll->notify('debug', ...

B<Mandatory>. Specifies the type of message to send. Valid values
are C<critical>, C<error>, C<warning>, C<info>, and C<debug>.
The module provides shorthand methods with those names to call
C<notify>.

=head3 Second argument

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

    $roll->notify(..., "Message to send",

B<Mandatory>. Takes a string
that specifies the message to send to L<www.rollbar.com|http://www.rollbar.com>.

=head3 Third argument

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-hashref.png">

    $roll->notify(
        ...,
        ..., {
        any      => 'custom',
        optional => 'data',
        to       => [qw/send goes here/],
    });

B<Optional>. Takes a hashref that will be converted to JSON and
sent along with the notification's message.

=head2 C<< ->critical() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">

    $roll->critical( ... );

    # same as

    $roll->notify( 'critical', ... );

=head2 C<< ->error() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">

    $roll->error( ... );

    # same as

    $roll->notify( 'error', ... );

=head2 C<< ->warning() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">

    $roll->warning( ... );

    # same as

    $roll->notify( 'warning', ... );

=head2 C<< ->info() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">

    $roll->info( ... );

    # same as

    $roll->notify( 'info', ... );

=head2 C<< ->debug() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">

    $roll->debug( ... );

    # same as

    $roll->notify( 'debug', ... );

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-experimental.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Methods listed below are experimental and might change in future!

=head2 C<< ->report_message($message, $additional_parameters) >>

Sends "message" type event to Rollbar.

    $roll->report_message("Message to send");

Parameters:

=head3 $message

B<Mandatory>. Specifies message text to be sent.

In addition to text your message can contain additional custom metadata fields.
In this case C<$message> must be an arrayref, where first element is message
text and second is hashref with metadata.

    $roll->report_message(["Message to send", { some_key => "value" });

=head3 $additional_parameters

B<Optional>. Takes a hashref which may contain any additional top-level fields
that you want to send with your message. Full list of fields supported by
Rollbar is available at L<https://rollbar.com/docs/api/items_post/>.

Notable useful field is C<level> which can be used to set severity of your
message. Default level is "error". See ->notify() for list of supported levels.
Other example fields supported by Rollbar include: context, request, person, server.

    $roll->report_message("Message to send", { context => "controller#action" });

=head2 C<< ->report_trace($exception_class,..., $frames, $additional_parameters >>

Reports "trace" type event to Rollbar, which is basically an exception.

=head3 $exception_class

B<Mandatory>. This is exception class name (string).

It can be followed by 0 to 2 additional scalar parameters, which are
interpreted as exception message and exception description accordingly.

    $roll->report_trace("MyException", $frames);
    $roll->report_trace("MyException", "Total failure in module X", $frames);
    $roll->report_trace("MyException", "Total failure in module X", "Description", $frames);

=head3 $frames

B<Mandatory>. Contains frames from stacktrace. It can be either
L<Devel::StackTrace> object (in which case we extract frames from this object) or
arrayref with frames in Rollbar format (described in
L<https://rollbar.com/docs/api/items_post/>)

=head3 $additional_parameters

B<Optional>. See L</$additional_parameters> for details. Note that for
exceptions default level is "error".

=for html  </div></div>

=head1 ACCESSORS/MODIFIERS

=head2 C<< ->access_token() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    say 'Access token is ' . $roll->access_token;
    $roll->access_token('YOUR_post_server_item_ACCESS_TOKEN');

Getter/setter for C<access_token> argument to C<< ->new() >>.

=head2 C<< ->code_version() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    say 'Code version is ' . $roll->code_version;
    $roll->code_version('1.42');

Getter/setter for C<code_version> argument to C<< ->new() >>.

=head2 C<< ->environment() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    say 'Current environment is ' . $roll->environment;
    $roll->environment('1.42');

Getter/setter for C<environment> argument to C<< ->new() >>.

=head2 C<< ->callback() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-subref.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-subref.png">

    $roll->callback->(); # call current callback
    $roll->callback( sub { say "Foo!"; } );

Getter/setter for C<callback> argument to C<< ->new() >>.


=head1 SEE ALSO

Rollbar API docs: L<https://rollbar.com/docs/api/items_post/>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/WebService-Rollbar-Notifier>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/WebService-Rollbar-Notifier/issues>

If you can't access GitHub, you can email your request
to C<bug-webservice-rollbar-notifier at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
