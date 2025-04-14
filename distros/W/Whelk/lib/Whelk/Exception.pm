package Whelk::Exception;
$Whelk::Exception::VERSION = '1.04';
use Kelp::Base 'Kelp::Exception';

# hint (string) to send to the user. App won't create a log if hint is present.
attr -hint => undef;

1;

__END__

=pod

=head1 NAME

Whelk::Exception - Exceptions for your API

=head1 SYNOPSIS

	use Whelk::Exception;

	# will set the status and log the body as error. A stock error message will
	# be used in the response.
	Whelk::Exception->throw(400, body => 'weird request got rejected because of reasons');

	# no log will be created, but the hint will be returned in the API response
	Whelk::Exception->throw(403, hint => 'Access denied, not authorized');

	# fatal API error, will not return an API error page but rather regular
	# text / html error page
	Kelp::Exception->throw(500, body => 'Something went very, very wrong');

=head1 DESCRIPTION

Whelk::Exception is a tiny subclass of L<Kelp::Exception>. It introduces a
L</hint> attribute, which can be set to let the user know more about the error.
Much like Kelp exceptions, only 4XX and 5XX statuses are allowed.

Whelk will treat Whelk::Exception differently than Kelp::Exception. Whelk
exceptions will be treated as planned API events and returned in API format.
Kelp exceptions will be thrown again, letting the Kelp application handle them,
which will result in plaintext or html error pages.

=head1 ATTRIBUTES

=head2 hint

This is a hint for the API user. It must be a string and will be put into the
error response as-is. It will not be logged.

