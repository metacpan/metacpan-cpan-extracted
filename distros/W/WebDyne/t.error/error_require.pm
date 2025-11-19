package error_require;
sub error_die {
    die('bang ! die within external require captured, good.');
}
sub error_die_eval {
    eval { die('eval bang !') };
    return \'survived eval {die()}, good.'
}
1;