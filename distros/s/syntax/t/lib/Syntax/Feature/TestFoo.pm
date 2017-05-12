use strict;
use warnings;

package Syntax::Feature::TestFoo;

our %CALL;

sub uninstall {
    my ($class, %args) = @_;

    $CALL{uninstall}++;
    return 1;
}

sub install {
    my ($class, %args) = @_;

    my $target  = $args{into};
    my $options = $args{options};

    no strict 'refs';
    *{ "${target}::foo" } = sub { $options };

    $CALL{install}++;
    return 1;
}

1;
