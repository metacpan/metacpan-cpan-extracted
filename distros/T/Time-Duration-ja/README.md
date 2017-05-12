# NAME

Time::Duration::ja - describe Time duration in Japanese

# SYNOPSIS

    use Time::Duration::ja;

    my $duration = duration(time() - $start_time);

# DESCRIPTION

Time::Duration::ja is a localized version of Time::Duration.

# UNICODE

All the functions defined in Time::Duration::ja returns string as
Unicode flagged. You should use [Encode](https://metacpan.org/pod/Encode) or [encoding](https://metacpan.org/pod/encoding) to convert to
your native encodings.

# AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

Most of the code are taken from Time::Duration::sv by Arthur Bergman and Time::Duration by Sean M. Burke.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Time::Duration](https://metacpan.org/pod/Time::Duration)
