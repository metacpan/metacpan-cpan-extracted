#<<<
use strict; use warnings;
#>>>

package Time::Out::Exception;

# https://stackoverflow.com/questions/23407085/why-does-eq-not-work-when-one-argument-has-overloaded-stringification
use overload '""' => sub { 'timeout' }, fallback => 1;

our $VERSION = '0.24';

sub new { shift; bless { @_ }, __PACKAGE__ }

1;
