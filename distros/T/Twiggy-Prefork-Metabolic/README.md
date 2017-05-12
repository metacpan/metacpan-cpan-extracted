[![Build Status](https://travis-ci.org/tarao/perl5-Twiggy-Prefork-Metabolic.svg?branch=master)](https://travis-ci.org/tarao/perl5-Twiggy-Prefork-Metabolic)
# NAME

`Twiggy::Prefork::Metabolic` - Metabolic preforking AnyEvent HTTP server for PSGI

# SYNOPSIS

    $ plackup -s Twiggy::Prefork::Metabolic -a app.psgi

# DESCRIPTION

`Twiggy::Prefork::Metabolic` behaves the same as [Twiggy::Prefork](https://metacpan.org/pod/Twiggy::Prefork)
except that a child process (a worker) won't stop listening after
reaching `max_reqs_per_child` until all accepted requests finished.
In other words, the child process never refuses a new connection
arrived before restart.

`Twiggy::Prefork::Metabolic` infinitely accepts new requests as
`Twiggy` does without getting stuck even if there are more requests
than `max_workers` x `max_reqs_per_child`.  This is like
`Twiggy::Prefork` with `--max-reqs-per-child=0`.  It also restarts
child processes as `Twiggy::Prefork` does if the process has idle
time after reaching `max_reqs_per_child`.

# SEE ALSO

[Twiggy::Prefork](https://metacpan.org/pod/Twiggy::Prefork)

# LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

INA Lintaro <tarao.gnn@gmail.com>
