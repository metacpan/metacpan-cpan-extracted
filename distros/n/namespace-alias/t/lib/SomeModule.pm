use strict;
use warnings;

package SomeModule;

sub call_alias {
    return MyAlias::foo;
}

sub call_alias_paren {
    return MyAlias::foo();
}

1;
