# DESCRIPTION

A CLI framework for CLI applications that use subcommands

# SYNOPSIS

    package main;
    require Your::App;
    Your::App->run();


    package Your::App;
    use Moo;
    extends 'YA::CLI';

    __PACKAGE__->meta->make_immutable;


    package Your::App::SubCommand;
    use Moo;
    use namespace::autoclean;
    with 'YA::CLI::ActionRole';

    # This is the action your sub command is selected on
    sub action { 'main' } # can also be an array in case you want aliases

    # This is the subaction your sub command is selected on. This is an
    # optional sub, you don't need to implement it
    sub subaction { 'thing' } # can also be an array in case you want aliases

    sub run {
        # Logic here
    }

    __PACKAGE__->meta->make_immutable;

# METHODS

## run

Runs the application

## default\_search\_path

Override the default search path, defaults to your Your::App namespace.

## default\_handler

Defaults to `main` for your default handler. If this handler cannot be found
ultimatly falls back to [YA::CLI::ErrorHandler](https://metacpan.org/pod/YA%3A%3ACLI%3A%3AErrorHandler) which deals with just `--help`
and `--man` commands.

## cli\_options

Define [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) options in your module that are used on top of the
default help and man.

# SEE ALSO

- [YA::CLI::ActionRole](https://metacpan.org/pod/YA%3A%3ACLI%3A%3AActionRole)
- [YA::CLI::ErrorHandler](https://metacpan.org/pod/YA%3A%3ACLI%3A%3AErrorHandler)
- [YA::CLI::Usage](https://metacpan.org/pod/YA%3A%3ACLI%3A%3AUsage)
