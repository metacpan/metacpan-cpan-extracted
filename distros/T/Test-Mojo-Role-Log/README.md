# NAME

Test::Mojo::Role::Log - test mojo log messages

# SYNOPSIS

```perl
use Test::Mojo;

my $t = Test::Mojo->with_roles('+Log')->new('MyApp');

$t->get_ok('/gugus')
   ->log_like(qr{GET "/gugus"})
   ->log_debug_like(qr{GET "/gugus"})
   ->log_info_unlike(qr{GET "/gugus"})
   ->log_debug_like(qr{200 OK.+s.+/s})

done_testing();

```

# DESCRIPTION

The [Test::Mojo::Role::Log](https://metacpan.org/pod/Test%3A%3AMojo%3A%3ARole%3A%3ALog) role enhances [Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo) with additional methods to check log output.

# ATTRIBUTES

## logCache

Points to an array with all the log messages issued since the last request.

# METHODS

The role [Test::Mojo::Role::Log](https://metacpan.org/pod/Test%3A%3AMojo%3A%3ARole%3A%3ALog) adds following new methods to [Test::Mojo](https://metacpan.org/pod/Test%3A%3AMojo) ones.

## log\_like($rx,$desc)

```
 $t->get_ok('/hello')
   ->log_like(undef,qr{/hello not found},"Request got logged")

```

Check if the given log message has been issued. All the log messages issued since the start of the current request will get checked.
If $logLevel is set to undef the logLevel does not get checked.

## log\_debug\_like($rx,$desc)

Find a debug level log message matching the given $rx.

## log\_info\_like($rx,$desc)

Find a info level log message matching the given $rx.

## log\_warn\_like($rx,$desc)

Find a warn level log message matching the given $rx.

## log\_error\_like($rx,$desc)

Find a error level log message matching the given $rx.

## log\_fatal\_like($rx,$desc)

Find a fatal level log message matching the given $rx.

## \*\_unlike

For each of the methods above there is ac coresponding
&#x3d;head1 AUTHOR

Tobias Oetiker <tobi@oetiker.ch>

# COPYRIGHT

Copyright 2020, OETIKER+PARTNER AG

# LICENSE

Perl Artistic License
