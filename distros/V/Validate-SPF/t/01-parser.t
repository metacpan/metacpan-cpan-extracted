use Test::Spec;

my $module = 'Validate::SPF::Parser';

describe $module => sub {
    before all => sub {
        use_ok( $module );
    };

    it "should create instance without errors" => sub {
        new_ok( $module );
    };
};

runtests unless caller;
