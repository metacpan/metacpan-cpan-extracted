use Test::Most;

BEGIN {
    use_ok( 'exact', 'cli', 'noautoclean' );
}

ok(
    main->can($_),
    "can $_",
) for ( qw( options pod2usage readmode singleton podhelp ) );

done_testing();
