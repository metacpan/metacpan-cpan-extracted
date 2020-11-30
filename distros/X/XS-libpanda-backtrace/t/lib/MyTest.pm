package MyTest;
use 5.012;
use Test::Catch;
use XS::libpanda::backtrace;
use Test::More;

XS::Loader::load('MyTest');

sub import {
    my ($class) = @_;

    my $caller = caller();
    foreach my $sym_name (qw/done_testing/) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = \&{$sym_name};
    }
}

#chdir 'libunievent';

1;
