#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Wasm::Wasm3;

use File::Slurper;

use FindBin;

my $wasm = Wasm::Wasm3->new();

my $wasm_bin = File::Slurper::read_binary("$FindBin::Bin/assets/perl_wasm_perl.wasm");

my $mod = $wasm->parse_module($wasm_bin);
my $rt = $wasm->create_runtime(1024)->load_module($mod);

{
    my @ins = $rt->get_function_arguments('giveback');
    is_deeply(
        \@ins,
        [
            Wasm::Wasm3::TYPE_I32,
            Wasm::Wasm3::TYPE_I64,
            Wasm::Wasm3::TYPE_F32,
            Wasm::Wasm3::TYPE_F64,
        ],
        'func arg types',
    );

    my @outs = $rt->get_function_returns('giveback');
    is_deeply(
        \@outs,
        [
            Wasm::Wasm3::TYPE_F64,
            Wasm::Wasm3::TYPE_F32,
            Wasm::Wasm3::TYPE_I64,
            Wasm::Wasm3::TYPE_I32,
        ],
        'func return types',
    );

    my @args = (123, 234, 1.23, 2.34);
    my @got = $rt->call(giveback => @args);

    cmp_deeply(
        \@got,
        [map { num($_, 0.001) } reverse @args],
        'all types: Perl->WASM->Perl',
    );
}

{
    is( $mod->get_global('global-const-i32'), 32, 'i32 const export' );
    is( $mod->get_global('global-const-i64'), 64, 'i64 const export' );
    cmp_deeply( $mod->get_global('global-const-f32'), num(3.2, 0.01), 'f32 const export' );
    cmp_deeply( $mod->get_global('global-const-f64'), num(6.4, 0.01), 'f64 const export' );

    for my $type ( qw(i32 i64 f32 f64) ) {
        TODO: {
            local $TODO = 'wasm3 bug: https://github.com/wasm3/wasm3/issues/319';

            eval { $mod->set_global("global-const-$type", 123) };
            my $err = $@;
            ok( $err, "Failure when setting a constant $type global" );
        }

        my $mut_name = "global-mut-$type";

        is( $mod->get_global($mut_name), 0, "initial get: mutable $type" );

        # Under Devel::Cover if you pass a bless()ed object to is()
        # a reference is retained artificially. This causes a memory leak,
        # and for XS modules it actually seems to cause memory corruption.
        #
        my $set_return = $mod->set_global($mut_name, 123);
        is( "$set_return", "$mod", 'set_global() returns $self' );

        is( $mod->get_global($mut_name), 123, "get after set: mutable $type" );
    }
}

{
    my @params_to_perl;
    $mod->link_function( qw(my func), 'F(ii)', sub {
        @params_to_perl = @_;
        return 2.345;
    } );

    my $value = $rt->call('callfunc');

    is_deeply( \@params_to_perl, [0, 2], 'params WASM -> Perl callback' );

    cmp_deeply( $value, num(2.345, 0.01), 'expected value from WASM -> Perl caller' );
}

{
    my $mod = $wasm->parse_module($wasm_bin);
    my $rt = $wasm->create_runtime(1024)->load_module($mod);
    my $err = 'nonono';
    $mod->link_function( qw(my func), 'F(ii)', sub { die $err } );
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    eval { diag explain [ $rt->call('callfunc') ] };
    my $exc = $@;
    like( $exc, qr<perl>i, 'error thrown if Perl callback throws' );
    cmp_deeply(
        \@w,
        [ re( qr<nonono> ) ],
        'expected warning',
    );
}

{
    my $mod = $wasm->parse_module($wasm_bin);
    my $rt = $wasm->create_runtime(1024)->load_module($mod);

    my @got;
    $mod->link_function( qw(my func-all-args-no-rets), 'v(iIfF)', sub { @got = @_; () } );
    $rt->call('call-all-args-no-rets');
    cmp_deeply(
        \@got,
        [map { num($_, 0.001) } 123, 234, 3.45, 4.56],
        'WASM -> SVs into callback',
    );

    $mod->link_function( qw(my func-no-args-all-rets), 'iIfF(v)', sub { ( 99, 999, 9.9, 99.9 ) } );

    @got = $rt->call('call-no-args-all-rets');
    cmp_deeply(
        \@got,
        [map { num($_, 0.001) } 99, 999, 9.9, 99.9],
        'WASM -> SVs to Perl caller',
    );
}

done_testing;

1;
