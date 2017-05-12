# NAME

Test::Requires - Checks to see if the module can be loaded

# SYNOPSIS

    # in your Makefile.PL
    use inc::Module::Install;
    test_requires 'Test::Requires';

    # in your test
    use Test::More tests => 10;
    use Test::Requires {
        'HTTP::MobileAttribute' => 0.01, # skip all if HTTP::MobileAttribute doesn't installed
    };
    isa_ok HTTP::MobileAttribute->new, 'HTTP::MobileAttribute::NonMobile';

    # or
    use Test::More tests => 10;
    use Test::Requires qw( 
        HTTP::MobileAttribute
    );
    isa_ok HTTP::MobileAttribute->new, 'HTTP::MobileAttribute::NonMobile';

    # or
    use Test::More tests => 10;
    use Test::Requires;
    test_requires 'Some::Optional::Test::Required::Modules';
    isa_ok HTTP::MobileAttribute->new, 'HTTP::MobileAttribute::NonMobile';

# DESCRIPTION

Test::Requires checks to see if the module can be loaded.

If this fails rather than failing tests this **skips all tests**.

Test::Requires can also be used to require a minimum version of Perl:

    use Test::Requires "5.010";  # quoting is necessary!!
    
    # or
    use Test::Requires "v5.10";

# AUTHOR

Tokuhiro Matsuno <tokuhirom @\*(#RJKLFHFSDLJF gmail.com>

# THANKS TO

    kazuho++ # some tricky stuff
    miyagawa++ # original code from t/TestPlagger.pm
    tomyhero++ # reported issue related older test::builder
    tobyink++ # documented that Test::Requires "5.010" works

# ENVIRONMENT

If the `RELEASE_TESTING` environment variable is true, then instead
of skipping tests, Test::Requires bails out.

# SEE ALSO

["TestPlagger.pm" in t](https://metacpan.org/pod/t#TestPlagger.pm)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
