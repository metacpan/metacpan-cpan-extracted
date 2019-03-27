package WWW::Crawler::Mojo::Job;
use strict;
use warnings;
use utf8;
use Mojo::Base -base;
use Mojo::Util qw(md5_sum);

has 'closed';
has 'context';
has depth => 0;
has 'literal_uri';
has 'method';
has 'referrer';
has redirect_history => sub { [] };
has 'tx_params';
has 'url';

sub upgrade {
  my ($class, $job) = @_;

  if (!ref $job || ref $job ne __PACKAGE__) {
    my $url = !ref $job ? Mojo::URL->new($job) : $job;
    $job = $class->new(url => $url);
  }

  return $job;
}

sub clone {
  my $self = shift;
  return __PACKAGE__->new(%$self);
}

sub close {
  my $self = shift;
  $self->{closed}   = 1;
  $self->{referrer} = undef;
}

sub child {
  my $self = shift;
  return __PACKAGE__->new(@_, referrer => $self, depth => $self->depth + 1);
}

sub digest {
  my $self     = shift;
  my $md5_seed = $self->url->to_string . ($self->method || '');
  $md5_seed .= $self->tx_params->to_string if ($self->tx_params);
  return md5_sum($md5_seed);
}

sub redirect {
  my ($self, $last, @history) = @_;
  $self->url($last);
  $self->redirect_history(\@history);
}

sub original_url {
  my $self   = shift;
  my @histry = @{$self->redirect_history};
  return $self->url unless (@histry);
  return $histry[$#histry];
}

1;

=head1 NAME

WWW::Crawler::Mojo::Job - Single crawler job

=head1 SYNOPSIS

    my $job1 = WWW::Crawler::Mojo::Job->new;
    $job1->url('http://example.com/');
    my $job2 = $job1->child;

=head1 DESCRIPTION

This class represents a single crawler job.

=head1 ATTRIBUTES

=head2 context

Either L<Mojo::DOM> or L<Mojo::URL> instance that the job is referrered by.

    $job->context($dom);
    say $job->context;

=head2 closed

A flag indecates whether the job is closed or not.

    $job->closed(1);
    say $job->closed;

=head2 depth

The depth of the job in referrer series.

    my $job1 = WWW::Crawler::Mojo::Job->new;
    my $job2 = $job1->child;
    my $job3 = $job2->child;
    say $job1->depth; # 0
    say $job2->depth; # 1
    say $job3->depth; # 2

=head2 literal_uri

A L<Mojo::URL> instance of the literal URL that has appeared in the referrer
document.

    $job1->literal_uri('./index.html');
    say $job1->literal_uri; # './index.html'

=head2 referrer

A job instance that has referred the URL.

    $job1->referrer($job);
    my $job2 = $job1->referrer;

=head2 redirect_history

An array reference that contains URLs of redirect history.

    $job1->redirect_history([$url1, $url2, $url3]);
    my $history = $job1->redirect_history;

=head2 url

A L<Mojo::URL> instance of the resolved URL.

    $job1->url('http://example.com/');
    say $job1->url; # 'http://example.com/'

=head2 method

HTTP request method such as GET or POST.

    $job1->method('GET');
    say $job1->method; # GET

=head2 tx_params

A hash reference that contains params for L<Mojo::Transaction>.

    $job1->tx_params({foo => 'bar'});
    $params = $job1->tx_params;

=head1 METHODS

=head2 clone

Clones the job.

    my $job2 = $job1->clone;

=head2 close

Closes the job and cuts the referrer series.

    $job->close;

=head2 child

Instantiates a child job by parent job. The parent URL is set to child referrer.

    my $job1 = WWW::Crawler::Mojo::Job->new(url => 'http://example.com/1');
    my $job2 = $job1->child(url => 'http://example.com/2');
    say $job2->referrer->url # 'http://example.com/1'

=head2 digest

Generates digest string with C<url>, C<method>, C<tx_params> attributes.

    say $job->digest;

=head2 redirect

Replaces the resolved URL and history at once.

    my $job = WWW::Crawler::Mojo::Job->new;
    $job->url($url1);
    $job->redirect($url2, $url3);
    say $job->url # $url2
    say $job->redirect_history # [$url1, $url3]

=head2 original_url

Returns the original URL of redirected job. If redirected, returns last element
of C<redirect_histroy> attribute, otherwise returns C<url> attribute.

    $job1->redirect_history([$url1, $url2, $url3]);
    my $url4 = $job1->original_url; # $url4 is $url3

=head2 upgrade

Instanciates a job with string or a L<Mojo::URL> instance.

=head1 AUTHOR

Keita Sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Keita Sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
