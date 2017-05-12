# NAME

Test::Parse::Crontab::Simple - Simple Test Tool of Crontab by Parse::Crontab

# SYNOPSIS

    use strict;
    use warnings;
    
    use Test::More;
    use Parse::Crontab;
    use Test::Parse::Crontab::Simple;
    
    my $crontab = Parse::Crontab->new(file => './crontab.txt');
    
    ok $crontab->is_valid;
    
    match_ok $crontab;
    
    done_testing;

    <-------- crontab.txt ------------>
    */30 * * * * perl /path/to/cron_lib/some_worker1
    ###sample 2014-12-31 00:00:00

    0 23 * * * perl /path/to/cron_lib/some_worker2
    ###sample 2014-12-31 23:00:00

    0 15 * * * perl /path/to/cron_lib/some_worker3
    <--------------------------------->

# DESCRIPTION

Test::Parse::Crontab::Simple is Simple Test Tool of Crontab. It is using Parse::Crontab

If you write execution timing of crontab following below that declaration, test method validate it.
If sample is valid , test will pass.

Basically, you have to write sample as below format.
\###sample YYYY-MM-DD HH:ii:ss

# METHODS

## match\_ok

If you do not write sample, that declaration is not validated automatically.

## strict\_match\_ok

If you do not write sample, test will fail.

# DEPENDENCIES

[Parse::Crontab](https://metacpan.org/pod/Parse::Crontab)

# LICENSE

Copyright (C) masartz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

masartz <masartz@gmail.com>

# SEE ALSO

[Parse::Crontab](https://metacpan.org/pod/Parse::Crontab)
