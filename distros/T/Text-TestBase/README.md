# NAME

Text::TestBase - Parser for Test::Base format

# SYNOPSIS

    use Text::TestBase;

    my $parser = Text::TestBase->new();
    $parser->parse(<<'...');
    === hogehoge
    --- input: yyy
    --- got: xxx
    ...

# DESCRIPTION

Text::TestBase is a parser for Test::Base format.

# MOTIVATION

I love Test::Base. But it's bit too magical. It uses Spiffy, and it depends to YAML.
Test::Base breaks my distribution sometime. I need more simple implementation for Test::Base format.

# METHODS

- `my $parser = Text::TestBase->new();`

    Create new parser instance.

- `$parser->parse($src: Str): List of Text::TestBase::Block`

    Parse $src and get a list of [Text::TestBase::Block](https://metacpan.org/pod/Text::TestBase::Block)

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

Most of the code was taken from [Test::Base](https://metacpan.org/pod/Test::Base), of course.

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
