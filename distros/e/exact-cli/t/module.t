use Test2::V0;
use exact -cli, -noautoclean;

ok(
    main->can($_),
    "can $_",
) for ( qw( options pod2usage readmode singleton podhelp ) );

done_testing;
