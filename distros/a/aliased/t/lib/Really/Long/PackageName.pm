package Really::Long::PackageName;

sub import {
    my ($class, @methods) = @_;
    my $caller = caller(0);
    foreach my $method (@methods) {
        *{"${caller}::$method"} = sub { $method }
    }
}

1;
