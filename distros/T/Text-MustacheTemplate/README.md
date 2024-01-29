[![Actions Status](https://github.com/karupanerura/Text-MustacheTemplate/actions/workflows/test.yml/badge.svg)](https://github.com/karupanerura/Text-MustacheTemplate/actions)
# NAME

Text::MustacheTemplate - mustache template engine

# SYNOPSIS

    use Text::MustacheTemplate;
    # local $Text::MustacheTemplate::OPEN_DELIMITER = '<%';
    # local $Text::MustacheTemplate::CLOSE_DELIMITER = '%>';

    my $rendered = Text::MustacheTemplate->render('* {{variable}}', { variable => 'foo' }); # => "* foo"

    my $template = Text::MustacheTemplate->parse('* {{variable}}');
    $rendered = $template->({ variable => 'foo' }); # => "* foo"
    $rendered = $template->({ variable => 'bar' }); # => "* bar"

# DESCRIPTION

Text::MustacheTemplate is [mustache](https://mustache.github.io/) template engine written in Pure Perl.

All features of Mustache Template are implemented. (e.g. inheritance, lambda, etc..)
And it is passed all [mustache/spec](https://github.com/mustache/spec) test cases.

# METHODS

- parse

    Parses the template text. Returns a subroutine reference.
    The subroutine receives one argument and processes the parsed template using the context variable specified in the argument.

        my $template = Text::MustacheTemplate->parse('* {{variable}}');
        $rendered = $template->({ variable => 'foo' }); # => "* foo"

    This method is suitable for rendering the same template multiple times.

- render

    Render the template text using the context.
    It returns a rendered text. 

        my $rendered_text = Text::MustacheTemplate->render($template_text, $context);

    This method is suitable when the same template is rarely used.

# VARIABLES

Text::MustacheTemplate changes its behavior according to the following variables.
By using `local`, this change can be localized.

- $OPEN\_DELIMITER

    This is the delimiter that opens the tag.
    The default value is `"{{"`.

- $CLOSE\_DELIMITER

    This is the delimiter that closes the tag.
    The default value is `"}}"`.

- %REFERENCES

    This is references to other parsed templates.
    It's used by inheritance or partial template feature.

- $LAMBDA\_TEMPLATE\_RENDERING

    When this flag is truthy, lambda template rendering is enabled.
    The default value is falsey.

# BENCHMARK

Result of `author/benchmark.pl`:

    =============================
    parse
    =============================
    Benchmark: running Template::Mustache, Text::MustacheTemplate for at least 10 CPU seconds...
    Template::Mustache: 11 wallclock secs (10.44 usr +  0.07 sys = 10.51 CPU) @ 748.33/s (n=7865)
    Text::MustacheTemplate: 10 wallclock secs (10.51 usr +  0.01 sys = 10.52 CPU) @ 10028.52/s (n=105500)
                              Rate     Template::Mustache Text::MustacheTemplate
    Template::Mustache       748/s                     --                   -93%
    Text::MustacheTemplate 10029/s                  1240%                     --
    =============================
    render
    =============================
    Benchmark: running Template::Mustache, Text::MustacheTemplate for at least 10 CPU seconds...
    Template::Mustache: 10 wallclock secs (10.49 usr +  0.02 sys = 10.51 CPU) @ 730.73/s (n=7680)
    Text::MustacheTemplate: 11 wallclock secs (10.60 usr +  0.02 sys = 10.62 CPU) @ 32508.29/s (n=345238)
                              Rate     Template::Mustache Text::MustacheTemplate
    Template::Mustache       731/s                     --                   -98%
    Text::MustacheTemplate 32508/s                  4349%                     --
    =============================
    render (contextual optimization)
    =============================
    Benchmark: running disabled for at least 10 CPU seconds...
      disabled: 11 wallclock secs (10.50 usr +  0.02 sys = 10.52 CPU) @ 9471.20/s (n=99637)
                Rate disabled  enabled
    disabled  9471/s       --     -71%
    enabled  32508/s     243%       --
    =============================
    render(cached)
    =============================
    Benchmark: running Template::Mustache, Text::MustacheTemplate for at least 10 CPU seconds...
    Template::Mustache: 11 wallclock secs (10.49 usr +  0.01 sys = 10.50 CPU) @ 48871.81/s (n=513154)
    Text::MustacheTemplate: 10 wallclock secs (10.57 usr +  0.01 sys = 10.58 CPU) @ 232286.39/s (n=2457590)
                               Rate     Template::Mustache Text::MustacheTemplate
    Template::Mustache      48872/s                     --                   -79%
    Text::MustacheTemplate 232286/s                   375%                     --

# SEE ALSO

[Template::Mustache](https://metacpan.org/pod/Template%3A%3AMustache) [Mustache::Simple](https://metacpan.org/pod/Mustache%3A%3ASimple)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
