package Test::LocalFunctions::Receptor;

use strict;
use warnings;
use ExtUtils::Manifest qw/maniread/;

sub all_local_functions_ok {
    my ( $backend, $args ) = @_;

    my $builder = $backend->builder;
    my @libs = _list_modules_in_manifest($builder, $args->{ignore_modules});

    $builder->plan( tests => scalar @libs );

    my $fail = 0;
    for my $lib (@libs) {
        _test_local_functions( $backend, $builder, $lib, $args ) or $fail++;
    }
    return $fail == 0;
}

sub local_functions_ok {
    my ( $backend, $lib, $args ) = @_;
    return _test_local_functions( $backend, $backend->builder, $lib, $args );
}

sub _test_local_functions {
    my ( $caller, $builder, $file, $args ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $pid; $pid = fork or do {
        defined $pid ? exit $caller->is_in_use( $builder, $file, $args )
                     : die "failed forking: $!"
    };
    wait;
    return $builder->ok( $? == 0, $file );
}

sub _list_modules_in_manifest {
    my ( $builder, $ignores ) = @_;

    if ( not -f $ExtUtils::Manifest::MANIFEST ) {
        $builder->plan( skip_all => "$ExtUtils::Manifest::MANIFEST doesn't exist" );
    }
    my $manifest = maniread();
    my @libs = grep { m!\Alib/.*\.pm\Z! } keys %{$manifest};

    for my $ignore (@$ignores) {
        $ignore =~ s!::!/!g;
        $ignore =~ /\.pm\Z/;
        $ignore .= '.pm' if $& ne '.pm';
        $ignore =~ m!\Alib/!;
        $ignore = "lib/$ignore" if $& ne 'lib/';
        @libs = grep { $_ ne $ignore } @libs;
    }
    return @libs;
}
1;
