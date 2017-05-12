# NAME

Test::UsedModules - Detects needless modules which are being used in your module



# VERSION

This document describes Test::UsedModules version 0.03



# SYNOPSIS

    # check all of modules that are listed in MANIFEST
    use Test::More;
    use Test::UsedModules;
    all_used_modules_ok();
    done_testing;

    # you can also specify individual file
    use Test::More;
    use Test::UsedModules;
    used_modules_ok('/path/to/your/module_or_script');
    done_testing;



# DESCRIPTION

Test::UsedModules finds needless modules which are being used in your module to clean up the source code.
Used modules (it means modules are used by 'use', 'require' or 'load (from Module::Load)' in target) will be checked by this module.



# METHODS

- all\_used\_modules\_ok

    This is a test function which finds needless used modules from modules that are listed in MANIFEST file.

- used\_modules\_ok

    This is a test function which finds needless used modules from specified source code.
    This function requires an argument which is the path to source file.

# DEPENDENCIES

- PPI (version 1.215 or later)
- Test::Builder::Module (version 0.98 or later)

# KNOWN PROBLEMS

- Cannot detects rightly when target module applies monkey patch.

    e.g. [HTTP::Message::PSGI](http://search.cpan.org/perldoc?HTTP::Message::PSGI)

    It applies monkey patch to [HTTP::Request](http://search.cpan.org/perldoc?HTTP::Request) and [HTTP::Response](http://search.cpan.org/perldoc?HTTP::Response).

- Cannot detects when target module is used by \`Module::Load::load\` and module name is substituted in variable.

    e.g.

        use Module::Load;
        my $module = 'Foo::Bar';
        load $module;

    in this case, Test::UsedModules will not notify even if Foo::Bar has never been used.

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



# AUTHOR

moznion <moznion@gmail.com>
