#!/usr/bin/perl

use strict;
use warnings;
use Devel::StackTrace;

# Basic WWW::Shopify exception class;
package WWW::Shopify::Exception;
use overload 
	'fallback' => 1,
	'""' => sub { 
		my ($exception) = @_;
		if ($exception->error && ref($exception->error) && ref($exception->error) eq "HTTP::Response") {
			my $code = $exception->error->code;
			my $message = $exception->error->message ? $exception->error->message : "N/A";
			my $content = $exception->error->decoded_content ? $exception->error->decoded_content : "N/A";
			return "Error: HTTP $code : $message\n$content\n" . $exception->stack;
		}
		return "Error: " . $exception->error . "\n" . $exception->stack;
	};
# Generic constructor; class is blessed with the package that new specifies, and contains a hash specified inside the parentheses of a new call.
# Example: new WWW::Shopify::Exception('try' => 'catch'); $_[0] is 'WWW::Shopify::Exception', $_[1] is {'try' => 'catch'}.
# The object will be of type WWW::Shopify::Exception, and have the contents of {'try' => 'catch'}.
sub new { return bless {'error' => $_[1] ? $_[1] : $_[0]->default_error, 'stack' => Devel::StackTrace->new, extra => $_[2]}, $_[0]; }
sub extra { return $_[0]->{extra}; }
sub error { return $_[0]->{error}; }
sub stack { return $_[0]->{stack}; }
sub default_error { return "Unknown exception occured."; }

# Thrown when a URL request exceeds the Shopify API call limit.
package WWW::Shopify::Exception::CallLimit;
use parent 'WWW::Shopify::Exception';
sub default_error { return "Call limit reached."; }

package WWW::Shopify::Exception::InvalidKey;
use parent 'WWW::Shopify::Exception';
sub default_error { return "Invalid API key."; }

package WWW::Shopify::Exception::NotFound;
use parent 'WWW::Shopify::Exception';
sub default_error { return "Asset not found."; }

package WWW::Shopify::Exception::DBError;
use parent 'WWW::Shopify::Exception';
sub default_error { return "Database error."; }

1;
