use strict; use warnings;
package lexicals;
our $VERSION = '0.35';

use PadWalker;

use base 'Exporter';
our @EXPORT = qw(lexicals);

sub lexicals {
    my $hash = PadWalker::peek_my(1);
    return +{
        map {
            my $v = $hash->{$_};
            $v = $$v if ref($v) =~ m'^(SCALAR|REF)$';
            s/^[\$\@\%\*]//;
            ($_, $v);
        } reverse sort keys %$hash
    };
}

1;
