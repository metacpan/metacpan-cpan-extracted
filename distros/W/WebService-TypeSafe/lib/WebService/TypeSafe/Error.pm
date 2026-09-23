package WebService::TypeSafe::Error;

use strict;
use warnings;
use overload '""' => 'as_string', fallback => 1;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
sub as_string { return $_[0]->{message} // ref($_[0]) }
sub message { $_[0]->{message} }

package WebService::TypeSafe::APIError;
use parent -norequire, 'WebService::TypeSafe::Error';
sub status { $_[0]->{status} }
sub body { $_[0]->{body} }
sub headers { $_[0]->{headers} }
sub endpoint { $_[0]->{endpoint} }
sub request_id { $_[0]->{headers}{'x-typesafe-request-id'} }
sub retry_after_ms {
    my ($self) = @_;
    return $self->{headers}{'retry-after-ms'} if defined $self->{headers}{'retry-after-ms'};
    return 1000 * $self->{headers}{'retry-after'}
        if defined($self->{headers}{'retry-after'}) && $self->{headers}{'retry-after'} =~ /^\d+(?:\.\d+)?$/;
    return undef;
}

package WebService::TypeSafe::BadRequestError;
use parent -norequire, 'WebService::TypeSafe::APIError';
package WebService::TypeSafe::AuthenticationError;
use parent -norequire, 'WebService::TypeSafe::APIError';
package WebService::TypeSafe::PermissionDeniedError;
use parent -norequire, 'WebService::TypeSafe::APIError';
package WebService::TypeSafe::NotFoundError;
use parent -norequire, 'WebService::TypeSafe::APIError';
package WebService::TypeSafe::UnprocessableEntityError;
use parent -norequire, 'WebService::TypeSafe::APIError';
package WebService::TypeSafe::RateLimitError;
use parent -norequire, 'WebService::TypeSafe::APIError';
package WebService::TypeSafe::InternalServerError;
use parent -norequire, 'WebService::TypeSafe::APIError';
package WebService::TypeSafe::ConnectionError;
use parent -norequire, 'WebService::TypeSafe::Error';
package WebService::TypeSafe::TimeoutError;
use parent -norequire, 'WebService::TypeSafe::ConnectionError';
sub timeout { $_[0]->{timeout} }
package WebService::TypeSafe::ResponseValidationError;
use parent -norequire, 'WebService::TypeSafe::APIError';
sub field_path { $_[0]->{field_path} }

1;
