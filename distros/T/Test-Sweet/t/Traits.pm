use MooseX::Declare;

role Test::Sweet::Meta::Test::Trait::TestLives {
    use Test::More;
    around run(@args) {
        my $ok = 0;
        eval {
            $self->$orig(@args);
            $ok = 1;
        };

        ok $ok, 'test lived';
    }
}

role BuiltOK {
    has 'built' => (
        is      => 'rw',
        isa     => 'Bool',
        default => 0,
    );

    after BUILD {
        $self->built(1);
    }

    after run(@args){
        Test::More::ok $self->built, 'BUILD was called';
    }
}

class t::Traits  {
    use Test::Sweet;

    test right_args {
        isa_ok $self, 't::Traits';
        isa_ok $test, 'Test::Sweet::Meta::Test';
    }

    test test_lives (TestLives) {
        ok 1, 'foo';
    }

    test built_ok (+BuiltOK) {}

}

