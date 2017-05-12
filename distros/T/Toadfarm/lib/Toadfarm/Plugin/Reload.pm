package Toadfarm::Plugin::Reload;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util;

our $GIT = $ENV{GIT_EXE} || 'git';

$ENV{TOADFARM_GITHUB_DELAY} ||= 2;

sub register {
  my ($self, $app, $config) = @_;
  my $t0 = localtime;

  $self->{log} = $app->log;
  $self->_valid_config($config) or return;

  $app->routes->any($config->{path})->to(
    cb => sub {
      my $c       = shift;
      my $payload = $c->req->body;
      my $status  = "Started: $t0\n\n";
      my $args;

      if ($payload) {
        $args = decode_json(Mojo::Util::encode('UTF-8', $payload));
        $status = $self->_fork_and_reload($args) ? "ok\n" : "nok\n";
      }
      else {
        for my $config (@{$self->{repositories}}) {
          $status .= "--- $config->{name}/$config->{branch}\n";
          eval {
            $self->_run(
              {GIT_DIR => "$config->{path}/.git"}, $GIT => log => -3 => '--format=%s',
              sub { $status .= "$_[0]\n" },
            );
            $status .= "\n";
          } or do {
            $self->{log}->error($@);
          };
        }
      }

      $c->render(text => $status, format => 'text');
    }
  );
}

sub _fork_and_reload {
  my ($self, $payload) = @_;
  my $manager_pid = getppid;
  my $branch      = $payload->{ref};
  my $name        = $payload->{repository}{name};
  my $sha1        = $payload->{head_commit}{id};
  my $refreshed   = 0;
  my $pid;

  unless ($branch and $name and $sha1) {
    $self->{log}->warn("Skip reload on bad payload: " . encode_json($payload));
    return;
  }

  $SIG{CHLD} = 'IGNORE';
  $pid = fork;

  return 1 if $pid;
  return 0 if !defined $pid;

  # child process
  $branch =~ s!refs/heads/!!;

  # maybe i need to wait for github?
  sleep $ENV{TOADFARM_GITHUB_DELAY} if $ENV{TOADFARM_GITHUB_DELAY};

  for my $config (@{$self->{repositories}}) {
    $config->{name} eq $name     or next;
    $config->{branch} eq $branch or next;

    eval {
      $self->{log}->info("Reloading repo $name, branch $branch");
      $self->_refresh_repo($config, $sha1);
      ++$refreshed;
    } or do {
      $self->{log}->error($@);
    };
  }

  if ($refreshed) {
    $self->_run(kill => -USR2 => $manager_pid);
  }
  else {
    $self->{log}->warn("Skip reload on name=$name and branch=$branch");
  }

  exit 0;
}

sub _refresh_repo {
  my ($self, $config, $sha1) = @_;
  my $log = $self->{log};

  chdir $config->{path} or die "chdir $config->{path}: $!";
  $self->_run($GIT => fetch => $config->{remote});
  $self->_run(
    $GIT => log => '--format=%H',
    '-n1',
    "$config->{remote}/$config->{branch}",
    sub {
      return $self->{log}->error("Invalid commit: $_[0] ne $sha1") unless $_[0] eq $sha1;
      $self->_run($GIT => checkout => -f => -B => toadfarm_reload_branch => "$config->{remote}/$config->{branch}");
    }
  );
}

sub _run {
  my ($self, @cmd) = @_;
  my $env = ref $cmd[0] eq 'HASH' ? shift @cmd : {};
  my $cb = ref $cmd[-1] eq 'CODE' ? pop @cmd : sub { $self->{log}->info("<<< $_[0]") };
  my @res;

  local %ENV = %ENV;
  $ENV{$_} = $env->{$_} for keys %$env;
  $env = join ', ', map {"$_=$env->{$_}"} sort keys %$env;
  $env = "[$env] " if $env;

  # TODO:
  $self->{log}->debug("${env}run(@cmd)");
  open my $CMD, '-|', @cmd or die "@cmd: $!";
  while (<$CMD>) {
    chomp;
    push @res, $cb->($_);
  }
}

sub _valid_config {
  my ($self, $config) = @_;
  my $repositories = $config->{repositories};

  if (!$config->{path}) {
    $self->{log}->error('Abort loading Reload: "path" missing in config');
    return;
  }
  if (ref $repositories eq 'HASH') {
    $repositories = [
      map {
        $repositories->{$_}{name} = $_;
        $repositories->{$_};
      } keys %$repositories
    ];
  }
  if (ref $repositories ne 'ARRAY' or !@$repositories) {
    $self->{log}->error('Abort loading Reload: "repositories" missing in config');
    return;
  }

  for my $config (@$repositories) {
    $config->{remote} ||= 'origin';
    for my $key (qw(path branch)) {
      next if $config->{$key};
      $self->{log}->error(qq[Abort loading Reload: "repositories -> $config->{name} -> $key" missing in config]);
      return;
    }
  }

  $self->{repositories} = $repositories;
}

1;

=encoding utf8

=head1 NAME

Toadfarm::Plugin::Reload - Reload toadfarm with new code

=head1 DESCRIPTION

This L<Mojolicious> plugin allows the L</Toadfarm> server to restart when a
resource is hit with a special JSON payload. The payload needs to be compatible
with the L<post-receive-hook|https://help.github.com/articles/post-receive-hooks>
github use.

=head1 SETUP

=over 4

=item *

You need to set up a post receive hook on github to make this reloader work.
Go to "https://github.com/YOUR-USERNAME/YOUR-REPO/settings/hooks" to set it up.

=item *

The WebHook URL (e.g. http://yourserver.com/some/private/path), should not
trigger any mounted apps. This can be achieved by simply using an IP address
instead of a hostname or by exempting the GitHub-Hookshot User-Agent from the
mount configuration:

  mount 'My::App' => {
    "Host" => qr{^(www.)?yourserver.com$},
    "User-Agent" => qr{^(?:(?!GitHub-Hookshot).)*$},
  };

=back

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use Toadfarm -init;

  # mount applications, set up logging, ...

  plugin "Toadfarm::Plugin::Reload" => {
    path         => "/some/private/path",
    repositories => [
      {
        name   => "cool-repo",
        branch => "some-branch",
        path   => "/path/to/cool-repo",
        remote => "whatever",           # default="origin"
      },
    ],
  };

  start;

Configuration details:

=over 4

=item * path

This should be the path part of the URL to POST data to reload the server.
Make this something semi-secret to avoid random public requests:

  perl -le'print join "/", "", "reload", (time.$$.rand(9999999)) =~ /(\w\w)/g'

=item * repositories

This should contain a mapping between github repository names and local settings:

=over 4

=item * branch

The name of the branch on github that you push production code to.

Tip: Instead of using "master", you might want to use "production" or "release"
instead. The reason for this is that it will prevent the server from reloading
each time you push to "master":

  # Work
  $ git push origin master
  $ git push origin master
  $ git push origin master
  # Make a new release
  $ git tag 0.31
  $ git push origin release
  # This plugin will cause hypnotoad to hot deploy

Note: The local branch will have the name "toadfarm_reload_branch". The reason
for this is to avoid killing commits done manually in the local branch. This
is of course a very bad workflow, and should be avoided.

=item * path

This is the path on disk to the local git repo.

=back

=back

=head1 METHODS

=head2 register

  $self->register($app, \%config);

See L</SYNOPSIS> for C<%config> parameters.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
