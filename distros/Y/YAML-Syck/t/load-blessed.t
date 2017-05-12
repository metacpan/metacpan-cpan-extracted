use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML tests => 11;

ok( YAML::Syck->VERSION );

my @tests = (
    {
        msg    => 'scalar',
        object => sub {
            my $str = "Hello";
            return \$str;
        },
        loadblessed_enabled  => 'SCALAR',
        loadblessed_disabled => 'SCALAR',
    },

    {
        msg    => 'scalar blessed as object',
        object => sub {
            my $str = "Hello";
            return bless \$str, "OBJ_STR";
        },
        loadblessed_enabled  => 'OBJ_STR',
        loadblessed_disabled => 'SCALAR',
    },
    {
        msg    => 'array ref blessed as object',
        object => sub {
            my $ar = [ 'hello', 'world' ];
            return bless $ar, "OBJ_ARRAY";
        },
        loadblessed_enabled  => 'OBJ_ARRAY',
        loadblessed_disabled => 'ARRAY',
    },
    {
        msg    => 'regexp blessed as object',
        object => sub {
            my $regex = qr(xxyy);
            return bless $regex, "MY_REGEXP";
        },
        loadblessed_enabled  => 'MY_REGEXP',
        loadblessed_disabled => 'Regexp',
        perl_version         => 5.008
    },
    {
        msg    => 'code blessed as object',
        object => sub {
            my $code = sub { return localtime() };
            return bless $code, "MY_CODE";
        },
        loadblessed_enabled  => 'MY_CODE',
        loadblessed_disabled => 'CODE',
    }
);

foreach my $t (@tests) {
  SKIP: {
        Test::More::skip "only for perl >= $t->{perl_version}", 2
          if $t->{perl_version} && $] < $t->{perl_version};

        $YAML::Syck::LoadBlessed = 1;
        is ref Load( Dump( $t->{object}->() ) ) => $t->{loadblessed_enabled}, "$t->{msg} [ LoadBlessed = 1 ]";

        $YAML::Syck::LoadBlessed = 0;
        is ref Load( Dump( $t->{object}->() ) ) => $t->{loadblessed_disabled}, "$t->{msg} [ LoadBlessed = 0 ]";
    }
}

exit;
