# NAME

WorldCat::API - Moo bindings for the OCLC WorldCat API

# VERSION

version 1.002

# SYNOPSIS

```perl
my $api = WorldCat::API->new(
  institution_id => "...",
  principle_id => "...",
  principle_id_namespace => "...",
  secret => "...",
  wskey => "...",
);

my $marc_record = $api->find_by_oclc_number("123") or die "Not Found!";
```

## CONFIGURATION

Defaults are set via envrionment variables of the form "WORLDCAT\_API\_${ALL\_CAPS\_ATTR\_NAME}". An easy way to set defaults (e.g. for testing) is to add them to a .env at the root of the project:

```
$ cat <<EOF > .env
WORLDCAT_API_INSTITUTION_ID="..."
WORLDCAT_API_PRINCIPLE_ID="..."
WORLDCAT_API_PRINCIPLE_ID_NAMESPACE="..."
WORLDCAT_API_SECRET="..."
WORLDCAT_API_WSKEY="..."
EOF
```

## DOCKER

The included Dockerfile makes it easy to develop, test, and release using Dist::Zilla. Just build the container:

```
$ docker build -t worldcatapi .
```

dzil functions as the container's entrypoint, which makes it easy to build the project:

```
$ docker run --volume="$PWD:/app" --env-file=.env worldcatapi build
$ docker run --volume="$PWD:/app" --env-file=.env worldcatapi test
$ docker run --volume="$PWD:/app" --env-file=.env worldcatapi clean
```

Release and development are interactive processes. You can use Docker for that, too, by opening a persistent shell in the container:

```
$ docker run -it --volume="$PWD:/app" --entrypoint=/bin/bash worldcatapi
```

# AUTHOR

Daniel Schmidt <danschmidt5189@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Daniel Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
