package My::Module4;

use base qw(Exporter);

our @EXPORT = qw(bleh);

use later 'My::Module5';

sub bleh {
    return ouap();
}

1;
