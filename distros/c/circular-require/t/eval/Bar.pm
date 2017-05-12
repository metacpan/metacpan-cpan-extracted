package Bar;
sub import {
    eval "require Baz";
    die $@ unless $@ =~ /\(eval /;
}
1;
