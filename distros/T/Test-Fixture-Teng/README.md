# NAME

Test::Fixture::Teng - load fixture data to storage for Teng

# SYNOPSIS

    # in your t/*.t
    use Test::Fixture::Teng;
    my $data = construct_fixture(
      db      => Your::Teng::Class,
      fixture => 'fixture.yaml',
    );

    # in your fixture.yaml
    - table: entry
      name: entry1
      data:
        id: 1
        title: my policy
        body: shut the f*ck up and write some code
        timestamp: 2008-01-01 11:22:44
    - table: entry
      name: entry2
      data:
        id: 2
        title: please join
        body: #coderepos-en@freenode.
        timestamp: 2008-02-23 23:22:58

# DESCRIPTION

Test::Fixture::Teng is fixture data loader for Teng.

# METHODS

## construct\_fixture

    my $data = construct_fixture(
        db      => Your::Teng::Class,
        fixture => 'fixture.yaml',
    );

construct your fixture.

# AUTHOR

Masahiro Iuchi &lt;masahiro.iuchi \_at\_ gmail \_dot\_ com>

# SEE ALSO

[Teng](https://metacpan.org/pod/Teng), [Kwalify](https://metacpan.org/pod/Kwalify)

# THANKS

Mostly copied from [Test::Fixture::DBIxSkinny](https://metacpan.org/pod/Test%3A%3AFixture%3A%3ADBIxSkinny)

# REPOSITORY

    git clone git://github.com/masiuchi/p5-test-fixture-teng.git

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
