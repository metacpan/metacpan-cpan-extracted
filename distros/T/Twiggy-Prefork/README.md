# NAME

Twiggy::Prefork - Preforking AnyEvent HTTP server for PSGI

# SYNOPSIS

    $ plackup -s Twiggy::Prefork -a app.psgi
    

# DESCRIPTION

Twiggy::Prefork is Preforking AnyEvent HTTP server for PSGI based on Twiggy. This server supports,

- Min/Max Request Per Child

    supports Min/Max Request Per Child feature. 

- Superdaemon aware

    Supports [Server::Starter](http://search.cpan.org/perldoc?Server::Starter) for hot deploy and
    graceful restarts.

    To use it, instead of the usual:

        plackup --server Twiggy::Prefork --port 8111 app.psgi

    install [Server::Starter](http://search.cpan.org/perldoc?Server::Starter) and use:

        start_server --port 8111 plackup --server Twiggy::Prefork app.psgi

# OPTIONS

- max\_workers

    number of worker processes (default: 10)

- max\_reqs\_per\_child

    max. number of requests to be handled before a worker process exits. If passed 0, child process is not existed by number of requests (default: 100).

- min\_reqs\_per\_child

    if set, randomizes the number of requests handled by a single worker process between the value and that supplied by --max-reqs-per-child (default: none)

# PSGI extensions

- psgix.exit\_guard

    AnyEvent::CondVar object. You can make graceful stop mechanism with this variable.

        use Coro;
        use AnyEvent;

        my $channel = Coro::Channel->new(100);

        async {
          while(1){
            my $q = $channel->get;
            # works..
            $q[0]->end;
          }
        };

        #psgi app
        sub {
          my $env = shift;
          my $cv = AE::cv;
          async {
            $env->{psgix.exit_guard}->begin; 
            $channel->put([$env->{psgix.exit_guard}]);
            $cv->send;
          };
          return sub {
            my $start_response = shift;
            $cv->cb(sub {
              $start_response->([200,['Content-Type'=>'text/plain'],['OK']]);
            });
          }
        }

    Block Twiggy::Prefork worker process exiting until your jobs done.

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

Shigeki Morimoto

# SEE ALSO

[Twiggy](http://search.cpan.org/perldoc?Twiggy), [Parallel::Prefork](http://search.cpan.org/perldoc?Parallel::Prefork)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
