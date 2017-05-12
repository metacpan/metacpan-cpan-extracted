package My::Module3;

use base qw(Exporter);

our @EXPORT_OK = qw(foo);

use later 'My::Module4';

sub foo {
     return bleh();
}

1;
