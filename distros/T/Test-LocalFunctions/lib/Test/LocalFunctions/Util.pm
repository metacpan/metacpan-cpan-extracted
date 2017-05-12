package Test::LocalFunctions::Util;

use strict;
use warnings;
use Sub::Identify qw/stash_name/;
use Module::Load;

sub list_local_functions {
    my $module = shift;

    my @local_functions;

    no strict 'refs';
    load $module;
    my %package = %{"${module}::"};
    while ( my ( $key, $value ) = each %package ) {
        next unless $key =~ /^_/;
        next unless *{"${module}::${key}"}{CODE};
        next unless $module eq stash_name( $module->can($key) );
        push @local_functions, $key;
    }
    use strict 'refs';

    return @local_functions;
}

sub extract_module_name {
    my $file = shift;

    # e.g.
    #   If file name is `lib/Foo/Bar.pm` then module name will be `Foo::Bar`
    if ( $file =~ /\.pm/ ) {
        my $module = $file;
        $module =~ s!\A.*\blib/!!;
        $module =~ s!\.pm\Z!!;
        $module =~ s!/!::!g;
        return $module;
    }

    return $file;
}
1;
