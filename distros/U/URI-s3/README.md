# NAME

URI::s3 - s3 URI scheme

# SYNOPSIS

    use URI;

    my $uri = URI->new("s3://example-bucket/path/to/object");
    $uri->bucket; # example-bucket
    $uri->key;    # path/to/object

# DESCRIPTION

URI::s3 is an URI scheme handler for `s3://` protocol.

# SEE ALSO

[URI](https://metacpan.org/pod/URI)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
