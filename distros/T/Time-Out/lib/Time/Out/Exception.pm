use strict;
use warnings;

package Time::Out::Exception;

# https://stackoverflow.com/questions/23407085/why-does-eq-not-work-when-one-argument-has-overloaded-stringification
use overload '""' => sub { 'timeout' }, fallback => 1;

# keeping the following $VERSION declaration on a single line is important
#<<<
use version 0.9915; our $VERSION = version->declare( '1.0.0' );
#>>>

sub new { shift; bless { @_ }, __PACKAGE__ }

1;
