#! perl

use v5.10.0;

use Test2::V0;

sub pkg {
    state $template = '0000';
    my $package = 'custom::failures::x::alias::test' . ++$template;

    ( my $tmp = $package ) =~ s{::}{/}g;
    ++$INC{ $tmp . '.pm' };

    return $package;
}

require custom::failures::x::alias;

{ package Failure01;
    use custom::failures::x::alias 'error01', 'error02';
}

{ package Test01;

    sub doit {
        my $err = ::dies { Failure01::error01->throw };
        ::isa_ok( $err, 'Failure01::error01' );
    }

}

{ package Test02;

    sub doit {
        Failure01->import( 'error01' );
        my $err = ::dies { error01()->throw };
        ::isa_ok( $err, 'Failure01::error01' );
    }
}

subtest 'package import' => sub {
    Test01::doit;
    Test02::doit;
};

subtest 'default' => sub {
    my $base = pkg;
    custom::failures::x::alias->import( $base => ['error'] );

    my $failure = "${base}::error";

    subtest 'no imports' => sub {
        my $test = pkg;
        ok( lives { eval "package $test; use $base;" }, 'load' )
          or note $@;

        eval "package $test; ${failure}->throw";
        my $err = $@;
        isa_ok( $err, $failure );
    };

    subtest 'import "error"' => sub {
        my $test = pkg;
        ok( lives { eval "package $test; use $base 'error';" }, 'load' )
          or note $@;

        eval "package $test; error->throw";
        my $err = $@;
        isa_ok( $err, $failure );
    };

    subtest 'import ":all"' => sub {
        my $test = pkg;
        ok( lives { eval "package $test; use $base ':all';" }, 'load' )
          or note $@;

        eval "package $test; error->throw";
        my $err = $@;
        isa_ok( $err, $failure );
    };

};

subtest '-export' => sub {
    my $base = pkg;
    custom::failures::x::alias->import( $base => [ '-export', 'error'] );

    my $failure = "${base}::error";

    subtest 'no imports' => sub {
        my $test = pkg;
        ok( lives { eval "package $test; use $base;" }, 'load' )
          or note $@;

        eval "package $test; error->throw";
        my $err = $@;
        isa_ok( $err, $failure );
    };
};

subtest '-suffix' => sub {
    my $base = pkg;
    custom::failures::x::alias->import( $base => [ -suffix => '_failure', -export => 'error'] );

    my $failure = "${base}::error";

    subtest 'no imports' => sub {
        my $test = pkg;
        ok( lives { eval "package $test; use $base;" }, 'load' )
          or note $@;

        eval "package $test; error_failure->throw";
        my $err = $@;
        isa_ok( $err, $failure );
    };
};

subtest '-prefix' => sub {
    my $base = pkg;
    custom::failures::x::alias->import( $base => [ -prefix => 'failure_', -export => 'error'] );

    my $failure = "${base}::error";

    subtest 'no imports' => sub {
        my $test = pkg;
        ok( lives { eval "package $test; use $base;" }, 'load' )
          or note $@;

        eval "package $test; failure_error->throw";
        my $err = $@;
        isa_ok( $err, $failure );
    };
};

SKIP: {
    skip "Exporter::Tiny isn't installed"
      if !eval 'require Exporter::Tiny; 1';

    subtest 'Exporter::Tiny' => sub {
        my $base = pkg;
        custom::failures::x::alias->import(
            $base => [ -exporter => 'Exporter::Tiny', 'error' ] );
        my $failure = "${base}::error";

        subtest 'no imports' => sub {
            my $test = pkg;
            ok( lives { eval "package $test; use $base;" }, 'load' )
              or note $@;

            eval "package $test; ${failure}->throw";
            my $err = $@;
            isa_ok( $err, $failure );
        };

        subtest 'import "error"' => sub {
            my $test = pkg;
            ok( lives { eval "package $test; use $base 'error';" }, 'load' )
              or note $@;

            eval "package $test; error->throw";
            my $err = $@;
            isa_ok( $err, $failure );
        };

        subtest 'import "-all"' => sub {
            my $test = pkg;
            ok( lives { eval "package $test; use $base -all;" }, 'load' )
              or note $@;

            eval "package $test; error->throw";
            my $err = $@;
            isa_ok( $err, $failure );
        };
    };
}

done_testing;
