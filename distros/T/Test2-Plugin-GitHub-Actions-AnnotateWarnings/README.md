# NAME

Test2::Plugin::GitHub::Actions::AnnotateWarnings - Annotate warnings with GitHub Actions workflow command

# SYNOPSIS

Just use this module and run tests. Note that this plugin is enabled only in a GitHub Actions workflow.

    use Test2::Plugin::GitHub::Actions::AnnotateWarnings;

You can also specify a condition whether to annotate a warning or not.

    use Test2::Plugin::GitHub::Actions::AnnotateWarnings ignore_if => sub {
        my ($message, $file, $line) = @_;
        return $message =~ /ignore/;
    };

# DESCRIPTION

This plugin provides annotations to the line of warnings for GitHub Actions workflow.

# LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

utgwkk <utagawakiki@gmail.com>
