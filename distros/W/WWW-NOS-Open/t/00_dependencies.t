use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg =
'Author test. Set the environment variable AUTHOR_TESTING to enable this test.';
    plan( skip_all => $msg );
}

eval "use Test::Dependencies exclude => [qw/ WWW::NOS /], style => q{heavy}";
plan skip_all => "Test::Dependencies required for testing dependencies" if $@;

TODO: {
    todo_skip q{Test::Dependencies can't do WWW::NOS::Open}, 1
      if 1;    #!-f q{META.yml};
    ok_dependencies();
}
