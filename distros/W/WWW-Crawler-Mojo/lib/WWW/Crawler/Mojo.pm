package WWW::Crawler::Mojo;
use strict;
use warnings;
use Mojo::Base 'Mojo::EventEmitter';
use WWW::Crawler::Mojo::Job;
use WWW::Crawler::Mojo::Queue::Memory;
use WWW::Crawler::Mojo::UserAgent;
use WWW::Crawler::Mojo::ScraperUtil qw{
  collect_urls_css html_handler_presets reduce_html_handlers resolve_href decoded_body};
use Mojo::Message::Request;
our $VERSION = '0.20';

has clock_speed       => 0.25;
has html_handlers     => sub { html_handler_presets() };
has max_conn          => 1;
has max_conn_per_host => 1;
has queue             => sub { WWW::Crawler::Mojo::Queue::Memory->new };
has 'shuffle';
has ua => sub { WWW::Crawler::Mojo::UserAgent->new };
has ua_name =>
  "www-crawler-mojo/$VERSION (+https://github.com/jamadam/www-crawler-mojo)";

sub crawl {
  my ($self) = @_;

  $self->init;

  die 'No job is given' unless ($self->queue->length);

  $self->emit('start');

  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

sub init {
  my ($self) = @_;

  $self->on('empty', sub { say "Queue is drained out."; $self->stop })
    unless $self->has_subscribers('empty');
  $self->on('error',
    sub { say "An error occured during crawling $_[0]: $_[1]" })
    unless $self->has_subscribers('error');
  $self->on('res', sub { $_[1]->() }) unless $self->has_subscribers('res');

  $self->ua->transactor->name($self->ua_name);
  $self->ua->max_redirects(5);

  $self->{_loop_ids} = [];

  my $id = Mojo::IOLoop->recurring(
    $self->clock_speed => sub {
      my $queue = $self->queue;

      if (!$queue->length) {
        $self->emit('empty') unless ($self->ua->active_conn);
        return;
      }
      return if $self->ua->active_conn >= $self->max_conn;
      return
        if $self->ua->active_host($queue->next->url)
        >= $self->max_conn_per_host;
      $self->process_job($queue->dequeue);
    }
  );

  push(@{$self->{_loop_ids}}, $id);

  if ($self->shuffle) {
    my $id = Mojo::IOLoop->recurring(
      $self->shuffle => sub {
        $self->queue->shuffle;
      }
    );

    push(@{$self->{_loop_ids}}, $id);
  }
}

sub process_job {
  my ($self, $job) = @_;

  my @args = ($job->method || 'get', $job->url);
  push(@args, form => $job->tx_params->to_hash) if $job->tx_params;
  my $tx = $self->ua->build_tx(@args);

  $self->emit('req', $job, $tx->req);

  $self->ua->start(
    $tx => sub {
      my ($ua, $tx) = @_;

      $job->redirect(_urls_redirect($tx));

      my $res = $tx->res;

      unless ($res->code) {
        my $msg = $res->error ? $res->error->{message} : 'Unknown error';
        $self->emit('error', $msg, $job);
        return;
      }

      $self->emit('res', sub { $self->scrape($res, $job, $_[0]) }, $job, $res);

      $job->close;
    }
  );
}

sub say_start {
  my $self = shift;

  print <<"EOF";
----------------------------------------
Crawling is starting with @{[ $self->queue->next->url ]}
Max Connection  : @{[ $self->max_conn ]}
User Agent      : @{[ $self->ua_name ]}
----------------------------------------
EOF
}

sub scrape {
  my ($self, $res, $job, $contexts) = @_;
  my @ret;

  return unless $res->headers->content_length && $res->body;

  my $base = $job->url;
  my $type = $res->headers->content_type;

  if ($type && $type =~ qr{^(text|application)/(html|xml|xhtml)}) {
    if ((my $base_tag = $res->dom->at('base[href]'))) {
      $base = resolve_href($base, $base_tag->attr('href'));
    }
    my $dom = Mojo::DOM->new(decoded_body($res));
    my $handlers = reduce_html_handlers($self->html_handlers, $contexts);
    for my $selector (sort keys %{$handlers}) {
      $dom->find($selector)->each(
        sub {
          my $dom = shift;
          for ($handlers->{$selector}->($dom)) {
            push(@ret, $self->_make_child($_, $dom, $job, $base)) if $_;
          }
        }
      );
    }
  }

  if ($type && $type =~ qr{text/css}) {
    for (collect_urls_css(decoded_body($res))) {
      push(@ret, $self->_make_child($_, $job->url, $job, $base));
    }
  }

  return @ret;
}

sub stop {
  my $self = shift;
  while (my $id = shift @{$self->{_loop_ids}}) {
    Mojo::IOLoop->remove($id);
  }
  Mojo::IOLoop->stop;
}

sub _make_child {
  my ($self, $url, $context, $job, $base) = @_;

  return unless $url;
  ($url, my $method, my $params) = @$url if (ref $url);

  my $resolved = resolve_href($base, $url);

  return unless ($resolved->scheme =~ qr{http|https|ftp|ws|wss});

  my $child
    = $job->child(url => $resolved, literal_uri => $url, context => $context);

  $child->method($method) if $method;

  if ($params) {
    if ($method eq 'GET') {
      $child->url->query->append($params);
    }
    else {
      $child->tx_params($params);
    }
  }

  return $child;
}

sub enqueue {
  my ($self, @jobs) = @_;
  $self->queue->enqueue(WWW::Crawler::Mojo::Job->upgrade($_)) for @jobs;
}

sub requeue {
  my ($self, @jobs) = @_;
  $self->queue->requeue(WWW::Crawler::Mojo::Job->upgrade($_)) for @jobs;
}

sub _urls_redirect {
  my $tx = shift;
  my @urls;
  @urls = _urls_redirect($tx->previous) if ($tx->previous);
  unshift(@urls, $tx->req->url->userinfo(undef));
  return @urls;
}

1;

=head1 NAME

WWW::Crawler::Mojo - A web crawling framework for Perl

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WWW::Crawler::Mojo;
    
    my $bot = WWW::Crawler::Mojo->new;
    
    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        
        $bot->enqueue($_) for $scrape->('#context');
    });
    
    $bot->enqueue('http://example.com/');
    $bot->crawl;

=head1 DESCRIPTION

L<WWW::Crawler::Mojo> is a web crawling framework for those who are familiar with
L<Mojo>::* APIs.

Althogh the module is only well tested for "focused crawl" at this point,
you can also use it for endless crawling by taking special care of memory usage.

=head1 ATTRIBUTES

L<WWW::Crawler::Mojo> inherits all attributes from L<Mojo::EventEmitter> and
implements the following new ones.

=head2 clock_speed

A number of main event loop interval in milliseconds. Defaults to 0.25.

    $bot->clock_speed(2);
    my $clock = $bot->clock_speed; # 2

=head2 html_handlers

Sets HTML handlers of scrapper. Defaults to
WWW::Crawler::Mojo::ScraperUtil::html_handler_presets.

  $bot->html_handlers( {
    'a[href]'   => sub { return $_[0]->{href} },
    'img[src]'  => sub { return $_[0]->{src} },
  } );

=head2 max_conn

An amount of max connections.

    $bot->max_conn(5);
    say $bot->max_conn; # 5

=head2 max_conn_per_host

An amount of max connections per host.

    $bot->max_conn_per_host(5);
    say $bot->max_conn_per_host; # 5

=head2 queue

L<WWW::Crawler::Mojo::Queue::Memory> object for default.

    $bot->queue(WWW::Crawler::Mojo::Queue::Memory->new);
    $bot->queue->enqueue($job);

=head2 shuffle

An interval in seconds to shuffle the job queue. It also evalutated as boolean
for disabling/enabling the feature. Defaults to undef, meaning disable.

    $bot->shuffle(5);
    say $bot->shuffle; # 5

=head2 ua

A L<WWW::Crawler::Mojo::UserAgent> instance.

    my $ua = $bot->ua;
    $bot->ua(WWW::Crawler::Mojo::UserAgent->new);

=head2 ua_name

Name of crawler for User-Agent header.

    $bot->ua_name('my-bot/0.01 (+https://example.com/)');
    say $bot->ua_name; # 'my-bot/0.01 (+https://example.com/)'

=head1 EVENTS

L<WWW::Crawler::Mojo> inherits all events from L<Mojo::EventEmitter> and
implements the following new ones.

=head2 req

Emitted right before crawler perform request to servers. The callback takes 3
arguments.

    $bot->on(req => sub {
        my ($bot, $job, $req) = @_;

        # DO NOTHING
    });

=head2 res

Emitted when crawler got response from server. The callback takes 4 arguments.

    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        if (...) {
            $bot->enqueue($_) for $scrape->();
        } else {
            # DO NOTHING
        }
    });

=head3 $bot

L<WWW::Crawler::Mojo> instance.

=head3 $scrape

Scraper code reference for current document. The code takes optional argument
CSS selector for context and returns new jobs.

    for my $job ($scrape->($context)) {
        $bot->enqueue($job)
    }

Optionally you can specify a scraping target container in CSS selector.

    @jobs = $scrape->('#container');
    @jobs = $scrape->(['#container1', '#container2']);

=head3 $job

L<WWW::Crawler::Mojo::Job> instance.

=head3 $res

L<Mojo::Message::Response> instance.

=head2 empty

Emitted when queue length gets zero.

    $bot->on(empty => sub {
        my ($bot) = @_;
        say "Queue is drained out.";
    });

=head2 error

Emitted when user agent returns no status code for request. Possibly caused by
network errors or un-responsible servers.

    $bot->on(error => sub {
        my ($bot, $error, $job) = @_;
        say "error: $_[1]";
        if (...) { # until failur occures 3 times
            $bot->requeue($job);
        }
    });

Note that server errors such as 404 or 500 cannot be catched with the event.
Consider res event for the use case instead of this.

=head2 start

Emitted right before crawl is started.

    $bot->on(start => sub {
        my $self = shift;
        ...
    });

=head1 METHODS

L<WWW::Crawler::Mojo> inherits all methods from L<Mojo::EventEmitter> and
implements the following new ones.

=head2 crawl

Starts crawling loop.

    $bot->crawl;

=head2 init

Initializes crawler settings.

    $bot->init;

=head2 process_job

Processes a job.

    $bot->process_job;

=head2 say_start

Displays starting messages to STDOUT

    $bot->say_start;

=head2 scrape

Parses and discovers links in a web page and CSS. This performs scraping.
With the optional 4th argument, you can specify a CSS selector to container
you would collect URLs within.

    $bot->scrape($res, $job, );
    $bot->scrape($res, $job, $selector);
    $bot->scrape($res, $job, [$selector1, $selector2]);

=head2 stop

Stop crawling.

    $bot->stop;

=head2 enqueue

Appends one or more URLs or L<WWW::Crawler::Mojo::Job> objects.

    $bot->enqueue('http://example.com/index1.html');

OR

    $bot->enqueue($job1, $job2);

OR

    $bot->enqueue(
        'http://example.com/index1.html',
        'http://example.com/index2.html',
        'http://example.com/index3.html',
    );

=head2 requeue

Appends one or more URLs or jobs for re-try. This accepts same arguments as
enqueue method.

    $self->on(error => sub {
        my ($self, $msg, $job) = @_;
        if (...) { # until failur occures 3 times
            $bot->requeue($job);
        }
    });

=head2 collect_urls_html

Collects URLs out of HTML.

    $bot->collect_urls_html($dom, sub {
        my ($uri, $dom) = @_;
    });

=head1 EXAMPLE

L<https://github.com/jamadam/WWW-Flatten>

=head1 AUTHOR

Keita Sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) jamadam

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
