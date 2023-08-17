use strict; use warnings;
package immutable::tied;

use Exporter 'import';
use Carp 'croak';

our @EXPORT = qw(
    err
);

sub err {
    (my $package = (caller(1))[3]) =~ s/(.*)::tied::.*/$1/;
    if (@_) {
        my ($action, $try) = @_;
        croak <<"...";
Not valid to $action an $package object.
Try '$try' which returns a new $package.
...

    } else {
        (my $name = (caller(1))[3]) =~ s/.*:://;
        croak <<"...";
Invalid usage of $package object caused a call to '$name'.
Try using the appropriate method call instead.
...
    }
}

1;
