# exported-constants
A Perl module for constants modules

## SYNOPSIS

    package MyProg::Constants;

    use exported::constants
        USER_TYPE_USER => 'U',
        USER_TYPE_APPLICATION => 'A',
        USER_TYPE_ROBOT => 'B',
    ;

    package MyProg::App;

    use MyProg::Constants;

    my @real_users = $users->search({ user_type => USER_TYPE_USER, });

## DESCRIPTION

This is a boilerplate-removal module for creating modules of just constants in your program.
This is useful if you have a lot of magic numbers you want to eliminate,
especially things that show up in database schemas or APIs that you want to re-use across multiple modules.

It's pretty simple to use;
just say

    use exported::constants
        CONSTANT1 => $value1,
        CONSTANT2 => $value2,
    ;

and your package is automatically an exporter,
and automatically exports (by default) all the constants listed.
