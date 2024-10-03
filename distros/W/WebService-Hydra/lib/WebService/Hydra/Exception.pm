package WebService::Hydra::Exception;

use strict;
use warnings;

use Object::Pad;

class WebService::Hydra::Exception;

use Module::Load;
use JSON::MaybeUTF8 qw(encode_json_text);
use Log::Any        qw($log);

our $VERSION = '0.002'; ## VERSION

=head1 NAME

WebService::Hydra::Exception - Base class for all Hydra Exceptions, loading all possible exception types.

=head1 DESCRIPTION

The base class cannot be instantiated directly, and it dynamically loads all exception types within WebService::Hydra::Exception::* namespace.

=cut

use Scalar::Util qw(blessed);

# Field definitions commonly inherited by all subclasses
field $message :param :reader = '';
field $category :param :reader = '';
field $details :param :reader = [];

BUILD {
    die ref($self) . " is a base class and cannot be instantiated directly." if ref($self) eq __PACKAGE__;
}

=head1 Methods

=head2 throw

Instantiates a new exception and throws it (using L<perlfunc/die>).

=cut

sub throw {
    my ($class, @args) = @_;
    die "$class is a base class and cannot be thrown directly." if (blessed($class) || $class) eq __PACKAGE__;
    my $self = blessed($class) ? $class : $class->new(@args);
    die $self;
}

=head2 as_string

Returns a string representation of the exception.

=cut

method as_string {
    my $string     = blessed($self);
    my @substrings = ();
    push @substrings, "Category=$category"                    if $category;
    push @substrings, "Message=$message"                      if $message;
    push @substrings, "Details=" . encode_json_text($details) if @$details;
    $string .= "(" . join(", ", @substrings) . ")" if @substrings;
    return $string;
}

=head2 as_json

Returns a JSON string representation of the exception.

=cut

method as_json {
    my $data = {
        Exception => blessed($self),
        Category  => $self->category,
        Message   => $self->message,
        Details   => $self->details,
    };
    return encode_json_text($data);
}

=head2 log

Logs the exception using Log::Any and increments a stats counter.

=cut

method log {
    $log->errorf("Exception: %s", $self->as_string);
    my $stats_name = blessed($self);
    $stats_name =~ s/::/./g;
}

# Exception class names explicitly listed
my @all_exceptions = qw(
    HydraServiceUnreachable
    FeatureUnavailable
    HydraRequestError
    InvalidLoginChallenge
    InvalidLogoutChallenge
    InvalidLoginRequest
    TokenExchangeFailed
    InvalidIdToken
    InvalidConsentChallenge
    InternalServerError
    RevokeLoginSessionsFailed
    InvalidToken
    InvalidClaims
);

=head2 import

The import method dynamically loads specific exceptions, or all by default.

=cut

sub import {
    my ($class, @exceptions) = @_;

    # If no specific exceptions are given, load all exceptions
    @exceptions = @exceptions ? @exceptions : @all_exceptions;

    for my $exception (@exceptions) {
        # Construct the module name: WebService::Hydra::Exception::ExceptionName
        my $module_name = "WebService::Hydra::Exception::$exception";

        eval {
            load $module_name;    # Load the exception module
            1;
        } or warn "Failed to load module $module_name: $@";
    }
}

1;
