package
    forks::shared::attributes; #hide from PAUSE
$VERSION = '0.36';

use Attribute::Handlers;

# Required for perl < 5.8.0; 5.8+ corrects bug in attribute handling that
# allowed internal 'shared' attribute to "slip" through and be passed to the
# Attribute::Handler.

package 
    UNIVERSAL; #hide from PAUSE

# Overload 'shared' attribute (required due to a bug in attributes < 0.7)

sub shared : ATTR(VAR) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    $data = [ $data ] unless ref $data eq 'ARRAY';
    threads::shared::_share( $referent );
}

# Declare special attribute name to suppress warning: "Declaration of shared
# attribute in package UNIVERSAL may clash with future reserved word"

sub Forks_shared : ATTR(VAR) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    $data = [ $data ] unless ref $data eq 'ARRAY';
    threads::shared::_share( $referent );
}

1;
