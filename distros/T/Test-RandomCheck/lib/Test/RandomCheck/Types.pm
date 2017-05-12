package Test::RandomCheck::Types;
use strict;
use warnings;
use UNIVERSAL::require;
use Class::Accessor::Lite (new => 1);
use Test::RandomCheck::PRNG;

sub arbitrary { die "You should implement " . (ref $_[0]) . "::arbitrary" }
sub memoize_key { die "You should implement " . (ref $_[0]) . "::memoize_key" }

sub sample {
    my $self = shift;
    my $rand = Test::RandomCheck::PRNG->new;
    map { [$self->arbitrary->pick($rand, $_)] } 0 .. 19;
}

sub import {
    my ($class) = @_;
    return if $class ne __PACKAGE__; # Only export when Types used directly

    # Load all subclasses
    (my $relative_path = __PACKAGE__ . '.pm') =~ s!::!/!g;
    (my $dir = $INC{$relative_path}) =~ s/\.pm$//;
    opendir my $h, $dir or die "Can't open $dir: $!";
    while (my $name = readdir $h) {
        $name =~ /^(.+)\.pm$/ or next;
        (__PACKAGE__ . "::$1")->require or die $@;
    }
}

1;
