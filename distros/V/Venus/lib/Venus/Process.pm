package Venus::Process;

use 5.018;

use strict;
use warnings;

use overload (
  '""' => 'explain',
  '~~' => 'explain',
  fallback => 1,
);

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Valuable';
with 'Venus::Role::Buildable';
with 'Venus::Role::Accessible';
with 'Venus::Role::Explainable';

require Config;
require Cwd;
require File::Spec;
require POSIX;

our $CWD = Cwd->getcwd;
our $MAPSIG = {%SIG};
our $PATH = $CWD;
our $PID = $$;
our $PPID;

# ATTRIBUTES

attr 'alarm';

# HOOKS

sub _alarm {
  CORE::alarm(shift);
}

sub _chdir {
  CORE::chdir(shift);
}

sub _exit {
  POSIX::_exit(shift);
}

sub _exitcode {
  $? >> 8;
}

sub _fork {
  CORE::fork();
}

sub _forkable {
  $Config::Config{d_pseudofork} ? 0 : 1;
}

sub _serve {
  true;
}

sub _kill {
  CORE::kill(@_);
}

sub _open {
  CORE::open(shift, shift, shift);
}

sub _ping {
  _kill(0, @_);
}

sub _setsid {
  POSIX::setsid();
}

sub _time {
  CORE::time();
}

sub _waitpid {
  CORE::waitpid(shift, shift);
}

# BUILD

sub build_self {
  my ($self, $data) = @_;

  $PID = $self->value if $self->value;

  return $self;
}

# METHODS

sub assertion {
  my ($self) = @_;

  my $assertion = $self->SUPER::assertion;

  $assertion->match('string')->format(sub{
    (ref $self || $self)->new($_)
  });

  return $assertion;
}

sub async {
  my ($self, $code, @args) = @_;

  require Venus::Path;

  my $path = $PATH;

  $PATH = Venus::Path->mktemp_dir->absolute->value;

  my $parent = $self->class->new;

  $parent->{directory} = $PATH;

  $parent->register;

  my $pid = $parent->work(sub{
    my ($process) = @_;

    $process->untrap;

    $process->{directory} = $PATH;

    $process->register;

    $process->watch($process->ppid);

    $process->ppid(undef);

    my $error;

    my $result = $process->try($code, @args)->error(\$error)->result;

    if (defined $error) {
      require Scalar::Util;
      require Venus::Error;
      $error = Venus::Error->new($error) if !Scalar::Util::blessed($error);
      $result = $error;
    }

    $process->sendall($result) if defined $result;

    return;
  });

  $parent->watch($pid);

  $parent->trap(int => sub {
    $parent->killall;
  });

  $parent->trap(term => sub {
    $parent->killall;
  });

  $PATH = $path;

  return $parent;
}

sub await {
  my ($self, $timeout) = @_;

  my $path = $PATH;

  $PATH = $self->{directory};

  my $result = [];

  if (defined $timeout) {
    if ($timeout == 0) {
      (my $error, @{$result}) = $self->catch('recvall');
    }
    else {
      (my $error, @{$result}) = $self->catch('poll', $timeout, 'recvall');
    }
  }
  else {
    do{@{$result} = $self->recvall} while !@{$result};
  }

  $self->check($_) for ($self->watchlist);

  $PATH = $path;

  return wantarray ? (@{$result}) : $result;
}

sub chdir {
  my ($self, $path) = @_;

  $path ||= $CWD;

  _chdir($path) or $self->error({
    throw => 'error_on_chdir',
    path => $path,
    pid => $PID,
    error => $!
  });

  return $self;
}

sub check {
  my ($self, $pid) = @_;

  my $result = _waitpid($pid, POSIX::WNOHANG());

  return wantarray ? ($result, _exitcode) : $result;
}

sub count {
  my ($self, $code, @args) = @_;

  $code ||= 'watchlist';

  my @result = $self->$code(@args);

  my $count = (@result == 1 && ref $result[0] eq 'ARRAY') ? @{$result[0]} : @result;

  return $count;
}

sub daemon {
  my ($self) = @_;

  if (my $process = $self->fork) {
    return $process->disengage->do('setsid');
  }
  else {
    return $self->exit;
  }
}

sub data {
  my ($self, @args) = @_;

  my @pids = @args ? @args : ($self->watchlist);

  return 0 if !@pids;

  my $result = 0;

  require Venus::Path;

  my $path = Venus::Path->new($PATH);

  $path = $path->child($self->exchange) if $self->exchange;

  for my $pid (@pids) {
    next if !(my $pdir = $path->child($self->recv_key($pid)))->exists;

    $result += 1 for CORE::glob($pdir->child('*.data')->absolute);
  }

  return $result;
}

sub decode {
  my ($self, $data) = @_;

  require Venus::Dump;

  return Venus::Dump->new->decode($data);
}

sub default {
  return $PID;
}

sub disengage {
  my ($self) = @_;

  $self->chdir(File::Spec->rootdir);

  $self->$_(File::Spec->devnull) for qw(stdin stdout stderr);

  return $self;
}

sub encode {
  my ($self, $data) = @_;

  require Venus::Dump;

  return Venus::Dump->new($data)->encode;
}

sub engage {
  my ($self) = @_;

  $self->chdir;

  $self->$_ for qw(stdin stdout stderr);

  return $self;
}

sub exchange {
  my ($self, $name) = @_;

  return $name ? ($self->{exchange} = $name) : $self->{exchange};
}

sub exit {
  my ($self, $code) = @_;

  return _exit($code // 0);
}

sub explain {
  my ($self) = @_;

  return $self->get;
}

sub followers {
  my ($self) = @_;

  my $leader = $self->leader;

  my $result = [sort grep {$_ != $leader} $self->others_active, $self->pid];

  return wantarray ? @{$result} : $result;
}

sub fork {
  my ($self, $code, @args) = @_;

  if (not(_forkable())) {
    $self->error({throw => 'error_on_fork_support', pid => $PID});
  }
  if (defined(my $pid = _fork())) {
    if ($pid) {
      $self->watch($pid);
      return wantarray ? (undef, $pid) : undef;
    }

    $PPID = $PID;
    $PID = $$;
    my $process = $self->class->new;
    my $orig_seed = srand;
    my $self_seed = substr(((time ^ $$) ** 2), 0, length($orig_seed));
    srand $self_seed;

    _alarm($self->alarm) if defined $self->alarm;

    if ($code) {
      local $_ = $process;
      $process->$code(@args);
    }

    return wantarray ? ($process, $PID) : $process;
  }
  else {
    $self->error({throw => 'error_on_fork_process', error => $!, pid => $PID});
  }
}

sub forks {
  my ($self, $count, $code, @args) = @_;

  my $pid;
  my @pids;
  my $process;

  for (my $i = 1; $i <= ($count || 0); $i++) {
    ($process, $pid) = $self->fork($code, @args, $i);
    if (!$process) {
      push @pids, $pid;
    }
    if ($process) {
      last;
    }
  }

  return wantarray ? ($process ? ($process, []) : ($process, [@pids]) ) : $process;
}

sub future {
  my ($self, $code, @args) = @_;

  my $async = $self->async($code, @args);

  require Venus::Future;

  my $retry = 0;

  my $future = Venus::Future->new(sub{
    my ($resolve, $reject) = @_;
    my ($result) = $async->try('await', 0)->error(\my $error)->result;
    if (defined $error) {
      return $reject->result($error);
    }
    if (defined $result) {
      if (UNIVERSAL::isa($result, 'Venus::Error')) {
        return $reject->result($result);
      }
      else {
        return $resolve->result($result);
      }
    }
    if ($retry++ > 1 && !$async->ping($async->watchlist)) {
      return $reject->result($async->catch('error', {
        throw => 'error_on_ping',
        pid => ($async->watchlist)[0]
      }));
    }
  });

  return $future;
}

sub is_dyadic {
  my ($self) = @_;

  my $directory = $self->{directory};

  my $path = $PATH;

  my $temporary = $PATH = $directory if $directory;

  my $is_dyadic = $directory && ($temporary) && $self->is_registered && ($self->count == 1) ? true : false;

  $PATH = $path;

  return $is_dyadic;
}

sub is_leader {
  my ($self) = @_;

  return $self->leader == $self->pid ? true : false;
}

sub is_follower {
  my ($self) = @_;

  return $self->is_leader ? false : true;
}

sub is_registered {
  my ($self) = @_;

  return (grep {$_ == $self->pid} $self->registrants) ? true : false;
}

sub is_unregistered {
  my ($self) = @_;

  return $self->is_registered ? false : true;
}

sub join {
  my ($self, $name) = @_;

  $self->exchange($name) if $name;

  $self->register;

  @{$self->watchlist} = ();

  return $self;
}

sub kill {
  my ($self, $name, @pids) = @_;

  return _kill(uc($name), @pids);
}

sub killall {
  my ($self, $name, @pids) = @_;

  $name ||= 'INT';

  my $result = [map $self->kill($name, $_), (@pids ? @pids : $self->watchlist)];

  return wantarray ? @{$result} : $result;
}

sub leader {
  my ($self) = @_;

  my $leader = (sort $self->others_active, $self->pid)[0];

  return $leader;
}

sub leave {
  my ($self, $name) = @_;

  $self->unregister;

  delete $self->{exchange};
  delete $self->{watchlist};

  return $self;
}

sub limit {
  my ($self, $count) = @_;

  if ($self->count >= $count) {
    $self->prune while $self->count >= $count;
    return true;
  }
  else {
    return false;
  }
}

sub others {
  my ($self) = @_;

  my $pid = $self->pid;

  my $result = [grep {$_ != $pid} $self->registrants];

  return wantarray ? @{$result} : $result;
}

sub others_active {
  my ($self) = @_;

  my $pid = $self->pid;

  my $result = [grep $self->ping($_), $self->others];

  return wantarray ? @{$result} : $result;
}

sub others_inactive {
  my ($self) = @_;

  my $pid = $self->pid;

  my $result = [grep !$self->ping($_), $self->others];

  return wantarray ? @{$result} : $result;
}

sub pid {
  my ($self, @data) = @_;

  return $self->value if !@data;

  return $self->value((($PID) = @data));
}

sub pids {
  my ($self) = @_;

  my $result = [$self->pid, $self->watchlist];

  return wantarray ? @{$result} : $result;
}

sub ppid {
  my ($self, @data) = @_;

  my $pid = @data ? (($PPID) = @data) : $PPID;

  return $pid;
}

sub ping {
  my ($self, @pids) = @_;

  return _ping(@pids);
}

sub poll {
  my ($self, $timeout, $code, @args) = @_;

  if (!$code) {
    $code = 'recvall';
  }

  if (!$timeout) {
    $timeout = 0;
  }

  my $result = [];

  my $time = _time();
  my $then = $time + $timeout;
  my $seen = 0;

  while (time <= $then) {
    last if $seen = (@{$result} = grep defined, $self->$code(@args));
  }

  if (!$seen) {
    $self->error({
      throw => 'error_on_timeout_poll',
      timeout => $timeout,
      code => $code
    });
  }

  return wantarray ? @{$result} : $result;
}

sub pool {
  my ($self, $count, $timeout) = @_;

  if (!$count) {
    $count = 1;
  }

  if (!$timeout) {
    $timeout = 0;
  }

  my @pids;
  my $time = _time();
  my $then = $time + $timeout;
  my $seen = 0;

  while (time <= $then) {
    last if ($seen = (@pids = $self->others_active)) >= $count;
  }

  if ($seen < $count) {
    $self->error({
      throw => 'error_on_timeout_pool',
      timeout => $timeout,
      pool_size => $count
    });
  }

  @{$self->watchlist} = @pids;

  return $self;
}

sub prune {
  my ($self) = @_;

  $self->unwatch($self->stopped);

  return $self;
}

sub read {
  my ($self, $key) = @_;

  require Venus::Path;

  my $path = Venus::Path->new($PATH);

  $path = $path->child($self->exchange) if $self->exchange;

  $path = $path->child($key);

  $path->catch('mkdirs') if !$path->exists;

  my $file = (CORE::glob($path->child('*.data')->absolute))[0];

  return undef if !$file;

  $path = Venus::Path->new($file);

  my $data = $path->read;

  $path->unlink;

  return $data;
}

sub recall {
  my ($self, $pid) = @_;

  ($pid) = grep {$_ == $pid} $self->others_inactive if $pid;

  return undef if !$pid;

  my $key = $self->send_key($pid);

  my $string = $self->read($key);

  return undef if !defined $string;

  my $data = $self->decode($string);

  return $data;
}

sub recallall {
  my ($self) = @_;

  my $result = [];

  for my $pid (grep defined, $self->ppid, $self->watchlist) {
    my $data = $self->recall($pid);
    push @{$result}, $data if defined $data;
  }

  return wantarray ? @{$result} : $result;
}

sub recv {
  my ($self, $pid) = @_;

  return undef if !$pid;

  my $key = $self->recv_key($pid);

  my $string = $self->read($key);

  return undef if !defined $string;

  my $data = $self->decode($string);

  return $data;
}

sub recvall {
  my ($self) = @_;

  my $result = [];

  for my $pid (grep defined, $self->ppid, $self->watchlist) {
    my $data = $self->recv($pid);
    push @{$result}, $data if defined $data;
  }

  return wantarray ? @{$result} : $result;
}

sub recv_key {
  my ($self, $pid) = @_;

  return CORE::join '.', $pid, $self->pid;
}

sub register {
  my ($self) = @_;

  require Venus::Path;

  my $path = Venus::Path->new($PATH);

  $path = $path->child($self->exchange) if $self->exchange;

  my $key = $self->send_key($self->pid);

  $path = $path->child($key);

  $path->catch('mkdirs') if !$path->exists;

  return $self;
}

sub registrants {
  my ($self) = @_;

  require Venus::Path;

  my $path = Venus::Path->new($PATH);

  $path = $path->child($self->exchange) if $self->exchange;

  my $result = [
    map /(\d+)$/, grep /(\d+)\.\1$/, CORE::glob($path->child('*.*')->absolute)
  ];

  return wantarray ? @{$result} : $result;
}

sub restart {
  my ($self, $code) = @_;

  my $result = [];

  $self->status(sub {
    push @{$result}, $code->(@_) if ($_[1] == -1) || ($_[1] == $_[0])
  });

  return wantarray ? @{$result} : $result;
}

sub send {
  my ($self, $pid, $data) = @_;

  return $self if !$pid;

  my $string = $self->encode($data);

  my $key = $self->send_key($pid);

  $self->write($key, $string);

  return $self;
}

sub sendall {
  my ($self, $data) = @_;

  for my $pid (grep defined, $self->ppid, $self->watchlist) {
    $self->send($pid, $data);
  }

  return $self;
}

sub send_key {
  my ($self, $pid) = @_;

  return CORE::join '.', $self->pid, $pid;
}

sub serve {
  my ($self, $count, $code) = @_;

  do {$self->work($code) until $self->limit($count)} while _serve;

  return $self;
}

sub setsid {
  my ($self) = @_;

  return _setsid != -1
    || $self->error({throw => 'error_on_setid', pid => $PID, error => $!});
}

sub started {
  my ($self) = @_;

  my $result = [];

  $self->status(sub {
    push @{$result}, $_[0] if $_[1] > -1 && $_[1] != $_[0]
  });

  return wantarray ? @{$result} : $result;
}

sub status {
  my ($self, $code) = @_;

  my $result = [];
  my $watchlist = $self->watchlist;

  for my $pid (@{$watchlist}) {
    local $_ = $pid;
    push @{$result}, $code->($pid, $self->check($pid));
  }

  return wantarray ? @{$result} : $result;
}

sub stderr {
  my ($self, $path) = @_;

  state $STDERR;

  if (!$STDERR) {
    _open($STDERR, '>&', \*STDERR);
  }
  if (!$path) {
    _open(\*STDERR, '>&', $STDERR);
  }
  else {
    _open(\*STDERR, '>&', IO::File->new($path, 'w')) or $self->error({
      throw => 'error_on_stderr',
      path => $path,
      pid => $PID,
      error => $!
    });
  }

  return $self;
}

sub stdin {
  my ($self, $path) = @_;

  state $STDIN;

  if (!$STDIN) {
    _open($STDIN, '<&', \*STDIN);
  }
  if (!$path) {
    _open(\*STDIN, '<&', $STDIN);
  }
  else {
    _open(\*STDIN, '<&', IO::File->new($path, 'r')) or $self->error({
      throw => 'error_on_stdin',
      path => $path,
      pid => $PID,
      error => $!
    });
  }

  return $self;
}

sub stdout {
  my ($self, $path) = @_;

  state $STDOUT;

  if (!$STDOUT) {
    _open($STDOUT, '>&', \*STDOUT);
  }
  if (!$path) {
    _open(\*STDOUT, '>&', $STDOUT);
  }
  else {
    _open(\*STDOUT, '>&', IO::File->new($path, 'w')) or $self->error({
      throw => 'error_on_stdout',
      path => $path,
      pid => $PID,
      error => $!
    });
  }

  return $self;
}

sub stopped {
  my ($self) = @_;

  my $result = [];

  $self->status(sub {
    push @{$result}, $_[0] if ($_[1] == -1) || ($_[1] == $_[0])
  });

  return wantarray ? @{$result} : $result;
}

sub sync {
  my ($self, $count, $timeout) = @_;

  if (!$count) {
    $count = 1;
  }

  if (!$timeout) {
    $timeout = 0;
  }

  my $time = _time();
  my $then = $time + $timeout;
  my $msgs = 0;

  while (time <= $then) {
    last if ($msgs = (scalar grep $self->data($_), $self->pool->watchlist)) >= $count;
  }

  if ($msgs < $count) {
    $self->error({
      throw => 'error_on_timeout_sync',
      timeout => $timeout,
      pool_size => $count
    });
  }

  return $self;
}

sub trap {
  my ($self, $name, $expr) = @_;

  $SIG{uc($name)} = !ref($expr) ? uc($expr) : sub {
    local($!, $?);
    return $self->$expr->(uc($name), @_) if ref $expr eq 'CODE';
  };

  return $self;
}

sub wait {
  my ($self, $pid) = @_;

  my $result = _waitpid($pid, 0);

  return wantarray ? ($result, _exitcode) : $result;
}

sub waitall {
  my ($self, @pids) = @_;

  my $result = [map [$self->wait($_)], @pids ? @pids : $self->watchlist];

  return wantarray ? @{$result} : $result;
}

sub watch {
  my ($self, @args) = @_;

  my $watchlist = $self->watchlist;

  my %seen; @{$watchlist} = grep !$seen{$_}++, @{$watchlist}, @args;

  return wantarray ? @{$watchlist} : $watchlist;
}

sub watchlist {
  my ($self) = @_;

  my $watchlist = $self->{watchlist} ||= [];

  return wantarray ? @{$watchlist} : $watchlist;
}

sub work {
  my ($self, $code, @args) = @_;

  my @returned = $self->fork(sub{
    my ($process) = @_;
    local $_ = $process;
    $process->$code(@args);
    $process->exit;
  });

  return $returned[-1];
}

sub works {
  my ($self, $count, $code, @args) = @_;

  my $result = [];

  for (my $i = 1; $i <= ($count || 0); $i++) {
    push @{$result}, scalar($self->work($code, @args));
  }

  return wantarray ? @{$result} : $result;
}

sub write {
  my ($self, $key, $data) = @_;

  require Venus::Path;

  my $path = Venus::Path->new($PATH);

  $path = $path->child($self->exchange) if $self->exchange;

  $path = $path->child($key);

  $path->catch('mkdirs') if !$path->exists;

  state $atom = 0;
  state $time = time;

  ($atom = ($time == time) ? $atom + 1 : 1);

  $path = $path->child(CORE::join '.', time, $atom, 'data');

  $time = time;

  $path->write($data);

  return $self;
}

sub unregister {
  my ($self) = @_;

  require Venus::Path;

  my $path = Venus::Path->new($PATH);

  $path = $path->child($self->exchange) if $self->exchange;

  my $key = $self->recv_key($self->pid);

  $path = $path->child($key);

  $path->rmdirs if $path->exists;

  return $self;
}

sub untrap {
  my ($self, $name) = @_;

  if ($name) {
    $SIG{uc($name)} = $$MAPSIG{uc($name)};
  }
  else {
    %SIG = %$MAPSIG;
  }

  return $self;
}

sub unwatch {
  my ($self, @args) = @_;

  my $watchlist = $self->watchlist;

  my %seen = map +($_, 1), @args;

  @{$watchlist} = grep !$seen{$_}++, @{$watchlist}, @args;

  return wantarray ? @{$watchlist} : $watchlist;
}

# DESTROY

sub DESTROY {
  my ($self, @data) = @_;

  $self->SUPER::DESTROY(@data);

  if ($self->is_dyadic && !$self->others) {
    $self->unregister;
    require Venus::Path; Venus::Path->new($self->{directory})->rmdirs;
  }

  return $self;
}

# ERRORS

sub error_on_chdir {
  my ($self, $data) = @_;

  my $message = 'Can\'t chdir "{{path}}": {{error}}';

  my $stash = {
    error => $data->{error},
    path => $data->{path},
    pid => $data->{pid},
  };

  my $result = {
    name => 'on.chdir',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_fork_process {
  my ($self, $data) = @_;

  my $message = 'Can\'t fork process {{pid}}: {{error}}';

  my $stash = {
    error => $data->{error},
    pid => $data->{pid},
  };

  my $result = {
    name => 'on.fork.process',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_fork_support {
  my ($self, $data) = @_;

  my $message = 'Can\'t fork process {{pid}}: Fork emulation not supported';

  my $stash = {
    pid => $data->{pid},
  };

  my $result = {
    name => 'on.fork.support',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_ping {
  my ($self, $data) = @_;

  my $message = 'Process {{pid}} not responding to ping';

  my $stash = {
    pid => $data->{pid},
  };

  my $result = {
    name => 'on.ping',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_setid {
  my ($self, $data) = @_;

  my $message = 'Can\'t start a new session: {{error}}';

  my $stash = {
    error => $data->{error},
    pid => $data->{pid},
  };

  my $result = {
    name => 'on.setid',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_stderr {
  my ($self, $data) = @_;

  my $message = 'Can\'t redirect STDERR to "{{path}}": {{error}}';

  my $stash = {
    error => $data->{error},
    path => $data->{path},
    pid => $data->{pid},
  };

  my $result = {
    name => 'on.stderr',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_stdin {
  my ($self, $data) = @_;

  my $message = 'Can\'t redirect STDIN to "{{path}}": {{error}}';

  my $stash = {
    error => $data->{error},
    path => $data->{path},
    pid => $data->{pid},
  };

  my $result = {
    name => 'on.stdin',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_stdout {
  my ($self, $data) = @_;

  my $message = 'Can\'t redirect STDOUT to "{{path}}": {{error}}';

  my $stash = {
    error => $data->{error},
    path => $data->{path},
    pid => $data->{pid},
  };

  my $result = {
    name => 'on.stdout',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_timeout_poll {
  my ($self, $data) = @_;

  my $message = CORE::join ' ', 'Timed out after {{timeout}} seconds',
    'in process {{pid}} while polling {{name}}';

  my $stash = {
    code => $data->{code},
    exchange => $self->exchange,
    name => (ref $data->{code} eq 'CODE' ? '__ANON__' : $data->{code}),
    pid => $self->pid,
    timeout => $data->{timeout},
  };

  my $result = {
    name => 'on.timeout.poll',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_timeout_pool {
  my ($self, $data) = @_;

  my $message = CORE::join ' ', 'Timed out after {{timeout}} seconds',
    'in process {{pid}} while pooling';

  my $stash = {
    pool_size => $data->{pool_size},
    exchange => $self->exchange,
    pid => $self->pid,
    timeout => $data->{timeout},
  };

  my $result = {
    name => 'on.timeout.pool',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

sub error_on_timeout_sync {
  my ($self, $data) = @_;

  my $message = CORE::join ' ', 'Timed out after {{timeout}} seconds',
    'in process {{pid}} while syncing';

  my $stash = {
    pool_size => $data->{pool_size},
    exchange => $self->exchange,
    pid => $self->pid,
    timeout => $data->{timeout},
  };

  my $result = {
    name => 'on.timeout.sync',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

1;



=head1 NAME

Venus::Process - Process Class

=cut

=head1 ABSTRACT

Process Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $process = $parent->fork;

  if ($process) {
    # do something in child process ...
    $process->exit;
  }
  else {
    # do something in parent process ...
    $parent->wait(-1);
  }

  # $parent->exit;

=cut

=head1 DESCRIPTION

This package provides methods for handling and forking processes.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 alarm

  alarm(number $seconds) (number)

The alarm attribute is used in calls to L<alarm> when the process is forked,
installing an alarm in the forked process if set.

I<Since C<2.40>>

=over 4

=item alarm example 1

  # given: synopsis

  package main;

  my $alarm = $parent->alarm;

  # undef

=back

=over 4

=item alarm example 2

  # given: synopsis

  package main;

  my $alarm = $parent->alarm(10);

  # 10

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Accessible>

L<Venus::Role::Buildable>

L<Venus::Role::Explainable>

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 async

  async(coderef $code, any @args) (Venus::Process)

The async method creates a new L<Venus::Process> object and asynchronously runs
the callback provided via the L</work> method. Both process objects are
configured to be are dyadic, i.e. representing an exclusing bi-directoral
relationship. Additionally, the callback return value will be automatically
made available via the L</await> method unless it's undefined. This method
returns the newly created L<"dyadic"|/is_dyadic> process object.

I<Since C<3.40>>

=over 4

=item async example 1

  # given: synopsis;

  my $async = $parent->async(sub{
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 await

  await(number $timeout) (arrayref)

The await method expects to operate on a L<"dyadic"|/is_dyadic> process object
and blocks the execution of the current process until a value is received from
its couterpart. If a timeout is provided, execution will be blocked until a
value is received or the wait time expires. If a timeout of C<0> is provided,
execution will not be blocked. If no timeout is provided at all, execution will
block indefinitely.

I<Since C<3.40>>

=over 4

=item await example 1

  # given: synopsis;

  my $async = $parent->async(sub{
    ($process) = @_;
    # in forked process ...
    return 'done';
  });

  my $await = $async->await;

  # ['done']

=back

=over 4

=item await example 2

  # given: synopsis;

  my $async = $parent->async(sub{
    ($process) = @_;
    # in forked process ...
    return {status => 'done'};
  });

  my $await = $async->await;

  # [{status => 'done'}]

=back

=over 4

=item await example 3

  # given: synopsis;

  my $async = $parent->async(sub{
    ($process) = @_;
    # in forked process ...
    return 'done';
  });

  my ($await) = $async->await;

  # 'done'

=back

=over 4

=item await example 4

  # given: synopsis;

  my $async = $parent->async(sub{
    ($process) = @_;
    # in forked process ...
    return {status => 'done'};
  });

  my ($await) = $async->await;

  # {status => 'done'}

=back

=over 4

=item await example 5

  # given: synopsis;

  my $async = $parent->async(sub{
    ($process) = @_;
    # in forked process ...
    $process->sendall('send 1');
    $process->sendall('send 2');
    $process->sendall('send 3');
    return;
  });

  my $await;

  my $results = [];

  push @$results, $async->await;

  # 'send 1'

  push @$results, $async->await;

  # 'send 2'

  push @$results, $async->await;

  # 'send 3'

  $results;

  # ['send 1', 'send 2', 'send 3']

=back

=cut

=head2 chdir

  chdir(string $path) (Venus::Process)

The chdir method changes the working directory the current process is operating
within.

I<Since C<0.06>>

=over 4

=item chdir example 1

  # given: synopsis;

  $parent = $parent->chdir;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item chdir example 2

  # given: synopsis;

  $parent = $parent->chdir('/tmp');

  # bless({...}, 'Venus::Process')

=back

=over 4

=item chdir example 3

  # given: synopsis;

  $parent = $parent->chdir('/xyz');

  # Exception! (isa Venus::Process::Error) (see error_on_chdir)

=back

=cut

=head2 check

  check(number $pid) (number, number)

The check method does a non-blocking L<perlfunc/waitpid> operation and returns
the wait status. In list context, returns the specified process' exit code (if
terminated).

I<Since C<0.06>>

=over 4

=item check example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($process, $pid) = $parent->fork;

  if ($process) {
    # in forked process ...
    $process->exit;
  }

  my $check = $parent->check($pid);

  # 0

=back

=over 4

=item check example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($process, $pid) = $parent->fork;

  if ($process) {
    # in forked process ...
    $process->exit;
  }

  my ($check, $status) = $parent->check('00000');

  # (-1, -1)

=back

=over 4

=item check example 3

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($process, $pid) = $parent->fork(sub{ $_->exit(1) });

  if ($process) {
    # in forked process ...
    $process->exit;
  }

  my ($check, $status) = $parent->check($pid);

  # ($pid, 1)

=back

=cut

=head2 count

  count(string | coderef $code, any @args) (number)

The count method dispatches to the method specified (or the L</watchlist> if
not specified) and returns a count of the items returned from the dispatched
call.

I<Since C<2.40>>

=over 4

=item count example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $count = $parent->count;

  # 0

=back

=over 4

=item count example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($pid) = $parent->watch(1001);

  my $count = $parent->count;

  # 1

=back

=over 4

=item count example 3

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($pid) = $parent->watch(1001);

  my $count = $parent->count('watchlist');

  # 1

=back

=cut

=head2 daemon

  daemon() (Venus::Process)

The daemon method detaches the process from controlling terminal and runs it in
the background as system daemon. This method internally calls L</disengage> and
L</setsid> and attempts to change the working directory to the root directory.

I<Since C<0.06>>

=over 4

=item daemon example 1

  # given: synopsis;

  my $daemon = $parent->daemon; # exits parent immediately

  # in forked process ...

  # $daemon->exit;

=back

=cut

=head2 data

  data(number @pids) (number)

The data method returns the number of messages sent to the current process,
from the PID or PIDs provided (if any). If no PID list is provided, the count
returned is based on the PIDs returned from L</watchlist>.

I<Since C<2.91>>

=over 4

=item data example 1

  # given: synopsis

  package main;

  my $data = $parent->data;

  # 0

=back

=over 4

=item data example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->join('procs');

  # in process 2

  my $process_2 = Venus::Process->new(12346)->join('procs');

  # in process 3

  my $process_3 = Venus::Process->new(12347)->join('procs');

  # in process 1

  $process_1->pool(2)->sendall({
    from => $process_1->pid, said => 'hello',
  });

  # in process 2

  $process_2->pool(2)->sendall({
    from => $process_2->pid, said => 'hello',
  });

  # $process_2->data;

  # 2

  # in process 3

  $process_3->pool(2)->sendall({
    from => $process_3->pid, said => 'hello',
  });

  # $process_3->data;

  # 2

  # in process 1

  my $data = $process_1->data;

  # 2

=back

=over 4

=item data example 3

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->join('procs');

  # in process 2

  my $process_2 = Venus::Process->new(12346)->join('procs');

  # in process 3

  my $process_3 = Venus::Process->new(12347)->join('procs');

  # in process 1

  $process_1->pool(2)->sendall({
    from => $process_1->pid, said => 'hello',
  });

  # in process 2

  $process_2->pool(2)->sendall({
    from => $process_2->pid, said => 'hello',
  });

  # $process_2->data;

  # 2

  # in process 3

  $process_3->pool(2)->sendall({
    from => $process_3->pid, said => 'hello',
  });

  # $process_3->data;

  # 2

  # in process 1

  $process_1->recvall;

  my $data = $process_1->data;

  # 0

=back

=cut

=head2 decode

  decode(string $data) (any)

The decode method accepts a string representation of a Perl value and returns
the Perl value.

I<Since C<2.91>>

=over 4

=item decode example 1

  # given: synopsis

  package main;

  my $decode = $parent->decode("{ok=>1}");

  # { ok => 1 }

=back

=cut

=head2 disengage

  disengage() (Venus::Process)

The disengage method limits the interactivity of the process by changing the
working directory to the root directory and redirecting its standard file
descriptors from and to C</dev/null>, or the OS' equivalent. These state
changes can be undone by calling the L</engage> method.

I<Since C<0.06>>

=over 4

=item disengage example 1

  # given: synopsis;

  $parent = $parent->disengage;

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 encode

  encode(any $data) (string)

The encode method accepts a Perl value and returns a string representation of
that Perl value.

I<Since C<2.91>>

=over 4

=item encode example 1

  # given: synopsis

  package main;

  my $encode = $parent->encode({ok=>1});

  # "{ok=>1}"

=back

=cut

=head2 engage

  engage() (Venus::Process)

The engage method ensures the interactivity of the process by changing the
working directory to the directory used to launch the process, and by
redirecting/returning its standard file descriptors from and to their defaults.
This method effectively does the opposite of the L</disengage> method.

I<Since C<0.06>>

=over 4

=item engage example 1

  # given: synopsis;

  $parent = $parent->engage;

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 exchange

  exchange(string $name) (any)

The exchange method gets and/or sets the name of the data exchange. The
exchange is the ontext in which processes can register and cooperate. Process
can cooperate in different exchanges (or contexts) and messages sent to a
process in one context are not available to be retrieved will operating in
another exchange (or context).

I<Since C<2.91>>

=over 4

=item exchange example 1

  # given: synopsis

  package main;

  my $exchange = $parent->exchange;

  # undef

=back

=over 4

=item exchange example 2

  # given: synopsis

  package main;

  my $exchange = $parent->exchange('procs');

  # "procs"

=back

=over 4

=item exchange example 3

  # given: synopsis

  package main;

  my $exchange = $parent->exchange('procs');

  # "procs"

  $exchange = $parent->exchange;

  # "procs"

=back

=cut

=head2 exit

  exit(number $status) (number)

The exit method exits the program immediately.

I<Since C<0.06>>

=over 4

=item exit example 1

  # given: synopsis;

  my $exit = $parent->exit;

  # 0

=back

=over 4

=item exit example 2

  # given: synopsis;

  my $exit = $parent->exit(1);

  # 1

=back

=cut

=head2 followers

  followers() (arrayref)

The followers method returns the list of PIDs registered under the current
L</exchange> who are not the L</leader>.

I<Since C<2.91>>

=over 4

=item followers example 1

  # given: synopsis

  package main;

  my $followers = $parent->followers;

  # []

=back

=over 4

=item followers example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  my $followers = $process_1->followers;

  # [12346, 12347]

=back

=cut

=head2 fork

  fork(string | coderef $code, any @args) (Venus::Process, number)

The fork method calls the system L<perlfunc/fork> function and creates a new
process running the same program at the same point (or call site). This method
returns a new L<Venus::Process> object representing the child process (from
within the execution of the child process (or fork)), and returns C<undef> to
the parent (or originating) process. In list context, this method returns both
the process and I<PID> (or process ID) of the child process. If a callback or
argument is provided it will be executed in the child process.

I<Since C<0.06>>

=over 4

=item fork example 1

  # given: synopsis;

  $process = $parent->fork;

  # if ($process) {
  #   # in forked process ...
  #   $process->exit;
  # }
  # else {
  #   # in parent process ...
  #   $parent->wait(-1);
  # }

  # in child process

  # bless({...}, 'Venus::Process')

=back

=over 4

=item fork example 2

  # given: synopsis;

  my $pid;

  ($process, $pid) = $parent->fork;

  # if ($process) {
  #   # in forked process ...
  #   $process->exit;
  # }
  # else {
  #   # in parent process ...
  #   $parent->wait($pid);
  # }

  # in parent process

  # (undef, $pid)

=back

=over 4

=item fork example 3

  # given: synopsis;

  my $pid;

  ($process, $pid) = $parent->fork(sub{
    $$_{started} = time;
  });

  # if ($process) {
  #   # in forked process ...
  #   $process->exit;
  # }
  # else {
  #   # in parent process ...
  #   $parent->wait($pid);
  # }

  # in parent process

  # (undef, $pid)

=back

=over 4

=item fork example 4

  # given: synopsis;

  $process = $parent->fork(sub{});

  # simulate fork failure

  # no forking attempted if NOT supported

  # Exception! (isa Venus::Process:Error) (see error_on_fork_support)

=back

=over 4

=item fork example 5

  # given: synopsis

  $process = $parent->do('alarm', 10)->fork;

  # if ($process) {
  #   # in forked process with alarm installed ...
  #   $process->exit;
  # }
  # else {
  #   # in parent process ...
  #   $parent->wait(-1);
  # }

  # in child process

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 forks

  forks(string | coderef $code, any @args) (Venus::Process, within[arrayref, number])

The forks method creates multiple forks by calling the L</fork> method C<n>
times, based on the count specified. As with the L</fork> method, this method
returns a new L<Venus::Process> object representing the child process (from
within the execution of the child process (or fork)), and returns C<undef> to
the parent (or originating) process. In list context, this method returns both
the process and an arrayref of I<PID> values (or process IDs) for each of the
child processes created. If a callback or argument is provided it will be
executed in each child process.

I<Since C<0.06>>

=over 4

=item forks example 1

  # given: synopsis;

  $process = $parent->forks(5);

  # if ($process) {
  #   # do something in (each) forked process ...
  #   $process->exit;
  # }
  # else {
  #   # do something in parent process ...
  #   $parent->wait(-1);
  # }

  # bless({...}, 'Venus::Process')

=back

=over 4

=item forks example 2

  # given: synopsis;

  my $pids;

  ($process, $pids) = $parent->forks(5);

  # if ($process) {
  #   # do something in (each) forked process ...
  #   $process->exit;
  # }
  # else {
  #   # do something in parent process ...
  #   $parent->wait($_) for @$pids;
  # }

  # in parent process

  # (undef, $pids)

=back

=over 4

=item forks example 3

  # given: synopsis;

  my $pids;

  ($process, $pids) = $parent->forks(5, sub{
    my ($fork, $pid, $iteration) = @_;
    # $iteration is the fork iteration index
    $fork->exit;
  });

  # if ($process) {
  #   # do something in (each) forked process ...
  #   $process->exit;
  # }
  # else {
  #   # do something in parent process ...
  #   $parent->wait($_) for @$pids;
  # }

  # in child process

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 future

  future(coderef $code, any @args) (Venus::Future)

The future method creates a new object via L</async> which runs the callback
asynchronously and returns a L<Venus::Future> object with a promise which
eventually resolves to the value emitted or error raised.

I<Since C<3.55>>

=over 4

=item future example 1

  # given: synopsis;

  my $future = $parent->future(sub{
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  # bless({...}, 'Venus::Future')

=back

=over 4

=item future example 2

  # given: synopsis;

  my $future = $parent->future(sub{
    ($process) = @_;
    # in forked process ...
    return 'done';
  });

  # $future->fulfill;

  # true

  # $future->value;

  # 'done'

=back

=over 4

=item future example 3

  # given: synopsis;

  my $future = $parent->future(sub{
    ($process) = @_;
    # in forked process ...
    return {status => 'done'};
  });

  # $future->fulfill;

  # true

  # $future->value

  # {status => 'done'}

=back

=over 4

=item future example 4

  # given: synopsis;

  my $future = $parent->future(sub{
    ($process) = @_;
    # in forked process ...
    return ['done'];
  });

  # $future->fulfill;

  # true

  # my ($await) = $future->value;

  # ['done']

=back

=over 4

=item future example 5

  # given: synopsis;

  my $future = $parent->future(sub{
    ($process) = @_;
    # in forked process ...
    $process->sendall(['send 1', 'send 2', 'send 3']);
    $process->sendall(['send 4']);
    $process->sendall(['send 5']);
    return;
  });

  # $future->fulfill;

  # true

  # my ($await) = $future->value;

  # ['send 1', 'send 2', 'send 3']

=back

=cut

=head2 is_dyadic

  is_dyadic() (boolean)

The is_dyadic method returns true is the process is configured to exclusively
communicate with one other process, otherwise returns false.

I<Since C<3.40>>

=over 4

=item is_dyadic example 1

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  my $is_dyadic = $process->is_dyadic;

  # false

=back

=over 4

=item is_dyadic example 2

  package main;

  use Venus::Process;

  my $process = Venus::Process->new->async(sub{
    return 'done';
  });

  my $is_dyadic = $process->is_dyadic;

  # true

=back

=cut

=head2 is_follower

  is_follower() (boolean)

The is_follower method returns true if the process is not the L</leader>, otherwise
returns false.

I<Since C<2.91>>

=over 4

=item is_follower example 1

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  my $is_follower = $process->is_follower;

  # false

=back

=over 4

=item is_follower example 2

  package main;

  use Venus::Process;

  my $process_1 = Venus::Process->new(12345)->register;
  my $process_2 = Venus::Process->new(12346)->register;
  my $process_3 = Venus::Process->new(12347)->register;

  my $is_follower = $process_1->is_follower;

  # false

  # my $is_follower = $process_2->is_follower;

  # true

  # my $is_follower = $process_3->is_follower;

  # true

=back

=over 4

=item is_follower example 3

  package main;

  use Venus::Process;

  my $process_1 = Venus::Process->new(12345)->register;
  my $process_2 = Venus::Process->new(12346)->register;
  my $process_3 = Venus::Process->new(12347)->register;

  # my $is_follower = $process_1->is_follower;

  # false

  my $is_follower = $process_2->is_follower;

  # true

  # my $is_follower = $process_3->is_follower;

  # true

=back

=cut

=head2 is_leader

  is_leader() (boolean)

The is_leader method returns true if the process is the L</leader>, otherwise
returns false.

I<Since C<2.91>>

=over 4

=item is_leader example 1

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  my $is_leader = $process->is_leader;

  # true

=back

=over 4

=item is_leader example 2

  package main;

  use Venus::Process;

  my $process_1 = Venus::Process->new(12345)->register;
  my $process_2 = Venus::Process->new(12346)->register;
  my $process_3 = Venus::Process->new(12347)->register;

  my $is_leader = $process_1->is_leader;

  # true

  # my $is_leader = $process_2->is_leader;

  # false

  # my $is_leader = $process_3->is_leader;

  # false

=back

=over 4

=item is_leader example 3

  package main;

  use Venus::Process;

  my $process_1 = Venus::Process->new(12345)->register;
  my $process_2 = Venus::Process->new(12346)->register;
  my $process_3 = Venus::Process->new(12347)->register;

  # my $is_leader = $process_1->is_leader;

  # true

  my $is_leader = $process_2->is_leader;

  # false

  # my $is_leader = $process_3->is_leader;

  # false

=back

=cut

=head2 is_registered

  is_registered() (boolean)

The is_registered method returns true if the process has registered using the
L</register> method, otherwise returns false.

I<Since C<2.91>>

=over 4

=item is_registered example 1

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  my $is_registered = $process->is_registered;

  # false

=back

=over 4

=item is_registered example 2

  package main;

  use Venus::Process;

  my $process = Venus::Process->new(12345)->register;

  my $is_registered = $process->is_registered;

  # true

=back

=cut

=head2 is_unregistered

  is_unregistered() (boolean)

The is_unregistered method returns true if the process has unregistered using
the L</unregister> method, or had never registered at all, otherwise returns
false.

I<Since C<2.91>>

=over 4

=item is_unregistered example 1

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  my $is_unregistered = $process->is_unregistered;

  # true

=back

=over 4

=item is_unregistered example 2

  package main;

  use Venus::Process;

  my $process = Venus::Process->new(12345);

  my $is_unregistered = $process->is_unregistered;

  # true

=back

=over 4

=item is_unregistered example 3

  package main;

  use Venus::Process;

  my $process = Venus::Process->new(12345)->register;

  my $is_unregistered = $process->is_unregistered;

  # false

=back

=cut

=head2 join

  join(string $name) (Venus::Process)

The join method sets the L</exchange>, registers the process with the exchange
using L</register>, and clears the L</watchlist>, then returns the invocant.

I<Since C<2.91>>

=over 4

=item join example 1

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  $process = $process->join;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item join example 2

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  $process = $process->join('procs');

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 kill

  kill(string $signal, number @pids) (number)

The kill method calls the system L<perlfunc/kill> function which sends a signal
to a list of processes and returns truthy or falsy. B<Note:> A truthy result
doesn't necessarily mean all processes were successfully signalled.

I<Since C<0.06>>

=over 4

=item kill example 1

  # given: synopsis;

  if ($process = $parent->fork) {
    # in forked process ...
    $process->exit;
  }

  my $kill = $parent->kill('term', int $process);

  # 1

=back

=cut

=head2 killall

  killall(string $name, number @pids) (arrayref)

The killall method accepts a list of PIDs (or uses the L</watchlist> if not
provided) and returns the result of calling the L</kill> method for each PID.
Returns a list in list context.

I<Since C<2.40>>

=over 4

=item killall example 1

  # given: synopsis

  package main;

  if ($process = $parent->fork) {
    # in forked process ...
    $process->exit;
  }

  my $killall = $parent->killall('term');

  # [1]

=back

=over 4

=item killall example 2

  # given: synopsis

  package main;

  if ($process = $parent->fork) {
    # in forked process ...
    $process->exit;
  }

  my $killall = $parent->killall('term', 1001..1004);

  # [1, 1, 1, 1]

=back

=cut

=head2 leader

  leader() (number)

The leader method uses a simple leader election algorithm to determine the
process leader and returns the PID for that process. The leader is always the
lowest value active PID (i.e. that responds to L</ping>).

I<Since C<2.91>>

=over 4

=item leader example 1

  # given: synopsis

  package main;

  my $leader = $parent->leader;

  # 12345

=back

=over 4

=item leader example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  my $leader = $process_3->leader;

  # 12345

=back

=over 4

=item leader example 3

  # given: synopsis

  package main;

  my $leader = $parent->register->leader;

  # 12345

=back

=cut

=head2 leave

  leave(string $name) (Venus::Process)

The leave method sets the L</exchange> to undefined, unregisters the process
using L</unregister>, and clears the L</watchlist>, then returns the invocant.

I<Since C<2.91>>

=over 4

=item leave example 1

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  $process = $process->leave;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item leave example 2

  package main;

  use Venus::Process;

  my $process = Venus::Process->new;

  $process = $process->leave('procs');

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 limit

  limit(number $count) (boolean)

The limit method blocks the execution of the current process until the number
of processes in the L</watchlist> falls bellow the count specified. The method
returns true once execution continues if execution was blocked, and false if
the limit has yet to be reached.

I<Since C<3.40>>

=over 4

=item limit example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->work(sub {
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  my $limit = $parent->limit(2);

  # false

=back

=over 4

=item limit example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->works(2, sub {
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  my $limit = $parent->limit(2);

  # true

=back

=cut

=head2 others

  others() (arrayref)

The others method returns all L</registrants> other than the current process,
i.e. all other registered process PIDs whether active or inactive.

I<Since C<2.91>>

=over 4

=item others example 1

  # given: synopsis

  package main;

  my $others = $parent->others;

  # []

=back

=over 4

=item others example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  my $others = $process_1->others;

  # [12346, 12347]

=back

=cut

=head2 others_active

  others_active() (arrayref)

The others_active method returns all L</registrants> other than the current
process which are active, i.e. all other registered process PIDs that responds
to L</ping>.

I<Since C<2.91>>

=over 4

=item others_active example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  my $others_active = $process_1->others_active;

  # [12346, 12347]

=back

=cut

=head2 others_inactive

  others_inactive() (arrayref)

The others_inactive method returns all L</registrants> other than the current
process which are inactive, i.e. all other registered process PIDs that do not
respond to L</ping>.

I<Since C<2.91>>

=over 4

=item others_inactive example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1 (assuming all processes exited)

  my $others_inactive = $process_1->others_inactive;

  # [12346, 12347]

=back

=cut

=head2 pid

  pid() (number)

The pid method returns the PID of the current process.

I<Since C<2.40>>

=over 4

=item pid example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $pid = $parent->pid;

  # 00000

=back

=cut

=head2 pids

  pids() (arrayref)

The pids method returns the PID of the current process, and the PIDs of any
child processes.

I<Since C<2.40>>

=over 4

=item pids example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $pids = $parent->pids;

  # [00000]

=back

=over 4

=item pids example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(1001..1004);

  my $pids = $parent->pids;

  # [00000, 1001..1004]

=back

=cut

=head2 ping

  ping(number @pids) (number)

The ping method returns truthy if the process of the PID provided is active. If
multiple PIDs are provided, this method will return the count of active PIDs.

I<Since C<2.01>>

=over 4

=item ping example 1

  # given: synopsis;

  if ($process = $parent->fork) {
    # in forked process ...
    $process->exit;
  }

  my $ping = $parent->ping(int $process);

  # 1

=back

=cut

=head2 poll

  poll(number $timeout, string | coderef $code, any @args) (arrayref)

The poll method continuously calls the named method or coderef and returns the
result that's not undefined, or throws an exception on timeout. If no method
name is provided this method will default to calling L</recvall>.

I<Since C<2.91>>

=over 4

=item poll example 1

  # given: synopsis

  package main;

  my $poll = $parent->poll(0, 'ping', $parent->pid);

  # [1]

=back

=over 4

=item poll example 2

  # given: synopsis

  package main;

  my $poll = $parent->poll(5, 'ping', $parent->pid);

  # [1]

=back

=over 4

=item poll example 3

  # given: synopsis

  package main;

  my $poll = $parent->poll(0, 'recv', $parent->pid);

  # Exception! (isa Venus::Process::Error) (see error_on_timeout_poll)

=back

=over 4

=item poll example 4

  # given: synopsis

  package main;

  my $poll = $parent->poll(5, sub {
    int(rand(2)) ? "" : ()
  });

  # [""]

=back

=cut

=head2 pool

  pool(number $count, number $timeout) (Venus::Process)

The pool method blocks the execution of the current process until the number of
L</other> processes are registered and pingable. This method returns the
invocant when successful, or throws an exception if the operation timed out.

I<Since C<2.91>>

=over 4

=item pool example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 1

  $process_1 = $process_1->pool;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item pool example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  $process_1 = $process_1->pool(2);

  # bless({...}, 'Venus::Process')

=back

=over 4

=item pool example 3

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  $process_1 = $process_1->pool(3, 0);

  # Exception! (isa Venus::Process::Error) (see error_on_timeout_pool)

=back

=cut

=head2 ppid

  ppid() (number)

The ppid method returns the PID of the parent process (i.e. the process which
forked the current process, if any).

I<Since C<2.91>>

=over 4

=item ppid example 1

  # given: synopsis;

  my $ppid = $parent->ppid;

  # undef

=back

=over 4

=item ppid example 2

  # given: synopsis;

  $process = $parent->fork;

  # in child process

  my $ppid = $process->ppid;

  # 00000

=back

=cut

=head2 prune

  prune() (Venus::Process)

The prune method removes all stopped processes and returns the invocant.

I<Since C<2.40>>

=over 4

=item prune example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(1001);

  $parent = $parent->prune;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item prune example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $process = $parent->fork;

  if ($process) {
    # in forked process ...
    $process->exit;
  }

  $parent = $parent->prune;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item prune example 3

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->work(sub {
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  $parent = $parent->prune;

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 recall

  recall(number $pid) (any)

The recall method returns the earliest message, sent by the current process to
the process specified by the PID provided, which is no longer active (i.e.
responding to L</ping>).

I<Since C<2.91>>

=over 4

=item recall example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 1

  $process_1->send($process_2->pid, {from => $process_1->pid});

  # in process 1 (process 2)

  my $recall = $process_1->recall($process_2->pid);

  # {from => 12345}

=back

=cut

=head2 recallall

  recallall() (arrayref)

The recallall method performs a L</recall> on the parent process (if any) via
L</ppid> and any process listed in the L</watchlist>, and returns the results.

I<Since C<2.91>>

=over 4

=item recallall example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  $process_1->send($process_2->pid, {from => $process_1->pid});

  $process_1->send($process_3->pid, {from => $process_1->pid});

  $process_1->watch($process_2->pid, $process_3->pid);

  # in process 1 (process 2 and 3 died)

  my $recallall = $process_1->recallall;

  # [{from => 12345}, {from => 12345}]

=back

=cut

=head2 recv

  recv(number $pid) (any)

The recv method returns the earliest message found from the process specified
by the PID provided.

I<Since C<2.91>>

=over 4

=item recv example 1

  # given: synopsis

  package main;

  my $recv = $parent->recv;

  # undef

=back

=over 4

=item recv example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345);

  # in process 2

  my $process_2 = Venus::Process->new(12346);

  # in process 1

  my $recv = $process_1->recv($process_2->pid);

  # undef

  # in process 2

  $process_2->send($process_1->pid, {from => $process_2->pid, said => 'hello'});

  # in process 1

  $recv = $process_1->recv($process_2->pid);

  # {from => 12346, said => 'hello'}

=back

=cut

=head2 recvall

  recvall() (arrayref)

The recvall method performs a L</recv> on the parent process (if any) via
L</ppid> and any process listed in the L</watchlist>, and returns the results.

I<Since C<2.91>>

=over 4

=item recvall example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  $process_2->send($process_1->pid, {from => $process_2->pid});

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  $process_3->send($process_1->pid, {from => $process_3->pid});

  # in process 1

  my $recvall = $process_1->pool(2)->recvall;

  # [{from => 12346}, {from => 12347}]

=back

=over 4

=item recvall example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  $process_2->send($process_1->pid, {from => $process_2->pid});

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  $process_3->send($process_1->pid, {from => $process_3->pid});

  # in process 1

  my $recvall = $process_1->pool(2)->recvall;

  # [{from => 12346}, {from => 12347}]

  # in process 2

  $process_2->send($process_1->pid, {from => $process_2->pid});

  # in process 1

  $recvall = $process_1->recvall;

  # [{from => 12346}]

=back

=cut

=head2 register

  register() (Venus::Process)

The register method declares that the process is willing to cooperate with
others (e.g. L</send> nad L</recv> messages), in a way that's discoverable by
other processes, and returns the invocant.

I<Since C<2.91>>

=over 4

=item register example 1

  # given: synopsis

  package main;

  my $register = $parent->register;

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 registrants

  registrants() (arrayref)

The registrants method returns the PIDs for all the processes that registered
using the L</register> method whether they're currently active or not.

I<Since C<2.91>>

=over 4

=item registrants example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  my $registrants = $process_1->registrants;

  # [12345, 12346, 12347]

=back

=cut

=head2 restart

  restart(coderef $callback) (arrayref)

The restart method executes the callback provided for each PID returned by the
L</stopped> method, passing the pid and the results of L</check> to the
callback as arguments, and returns the result of each call as an arrayref. In
list context, this method returns a list.

I<Since C<2.40>>

=over 4

=item restart example 1

  # given: synopsis

  package main;

  $parent->watch(1001);

  my $restart = $parent->restart(sub {
    my ($pid, $check, $exit) = @_;

    # redeploy stopped process

    return [$pid, $check, $exit];
  });

  # [[1001, 1001, 255]]

=back

=cut

=head2 send

  send(number $pid, any $data) (Venus::Process)

The send method makes the data provided available to the process specified by
the PID provided.

I<Since C<2.91>>

=over 4

=item send example 1

  # given: synopsis

  package main;

  my $send = $parent->send;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item send example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345);

  # in process 2

  my $process_2 = Venus::Process->new(12346);

  # in process 1

  $process_1 = $process_1->send($process_2->pid, {
    from => $process_1->pid, said => 'hello',
  });

  # bless({...}, 'Venus::Process')

  # in process 2

  # $process_2->recv($process_1->pid);

  # {from => 12345, said => 'hello'}

=back

=cut

=head2 sendall

  sendall(any $data) (Venus::Process)

The sendall method performs a L</send> on the parent process (if any) via
L</ppid> and any process listed in the L</watchlist>, and returns the invocant.

I<Since C<2.91>>

=over 4

=item sendall example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  # in process 1

  $process_1 = $process_1->pool(2)->sendall({
    from => $process_1->pid, said => 'hello',
  });

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 serve

  serve(number $count, coderef $callback) (Venus::Process)

The serve method executes the callback using L</work> until L</limit> blocks
the execution of the current process, indefinitely. It has the effect of
serving the callback and maintaining the desired number of forks until killed
or gracefully shutdown.

I<Since C<3.40>>

=over 4

=item serve example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->serve(2, sub {
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  # ...

  # bless({...}, "Venus::Process")

=back

=over 4

=item serve example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->serve(10, sub {
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  # ...

  # bless({...}, "Venus::Process")

=back

=cut

=head2 setsid

  setsid() (number)

The setsid method calls the L<POSIX/setsid> function and sets the process group
identifier of the current process.

I<Since C<0.06>>

=over 4

=item setsid example 1

  # given: synopsis;

  my $setsid = $parent->setsid;

  # 1

=back

=over 4

=item setsid example 2

  # given: synopsis;

  my $setsid = $parent->setsid;

  # Exception! (isa Venus::Process::Error) (see error_on_setid)

=back

=cut

=head2 started

  started() (arrayref)

The started method returns a list of PIDs whose processes have been started and
which have not terminated. Returns a list in list context.

I<Since C<2.40>>

=over 4

=item started example 1

  # given: synopsis

  package main;

  my $started = $parent->started;

  # child not terminated

  # [...]

=back

=over 4

=item started example 2

  # given: synopsis

  package main;

  my $started = $parent->started;

  # child terminated

  # []

=back

=cut

=head2 status

  status(coderef $callback) (arrayref)

The status method executes the callback provided for each PID in the
L</watchlist>, passing the pid and the results of L</check> to the callback as
arguments, and returns the result of each call as an arrayref. In list context,
this method returns a list.

I<Since C<2.40>>

=over 4

=item status example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(12346);

  my $status = $parent->status(sub {
    my ($pid, $check, $exit) = @_;

    # assuming PID 12346 is still running (not terminated)
    return [$pid, $check, $exit];
  });

  # [[12346, 0, -1]]

=back

=over 4

=item status example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(12346);

  my $status = $parent->status(sub {
    my ($pid, $check, $exit) = @_;

    # assuming process 12346 terminated with exit code 255
    return [$pid, $check, $exit];
  });

  # [[12346, 12346, 255]]

=back

=over 4

=item status example 3

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(12346);

  my @status = $parent->status(sub {
    my ($pid, $check, $exit) = @_;

    # assuming process 12346 terminated with exit code 255
    return [$pid, $check, $exit];
  });

  # ([12346, 12346, 255])

=back

=cut

=head2 stderr

  stderr(string $path) (Venus::Process)

The stderr method redirects C<STDERR> to the path provided, typically
C</dev/null> or some equivalent. If called with no arguments C<STDERR> will be
restored to its default.

I<Since C<0.06>>

=over 4

=item stderr example 1

  # given: synopsis;

  $parent = $parent->stderr;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item stderr example 2

  # given: synopsis;

  $parent = $parent->stderr('/nowhere');

  # Exception! (isa Venus::Process:Error) (see error_on_stderr)

=back

=cut

=head2 stdin

  stdin(string $path) (Venus::Process)

The stdin method redirects C<STDIN> to the path provided, typically
C</dev/null> or some equivalent. If called with no arguments C<STDIN> will be
restored to its default.

I<Since C<0.06>>

=over 4

=item stdin example 1

  # given: synopsis;

  $parent = $parent->stdin;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item stdin example 2

  # given: synopsis;

  $parent = $parent->stdin('/nowhere');

  # Exception! (isa Venus::Process::Error) (see error_on_stdin)

=back

=cut

=head2 stdout

  stdout(string $path) (Venus::Process)

The stdout method redirects C<STDOUT> to the path provided, typically
C</dev/null> or some equivalent. If called with no arguments C<STDOUT> will be
restored to its default.

I<Since C<0.06>>

=over 4

=item stdout example 1

  # given: synopsis;

  $parent = $parent->stdout;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item stdout example 2

  # given: synopsis;

  $parent = $parent->stdout('/nowhere');

  # Exception! Venus::Process::Error (error_on_stdout)

=back

=cut

=head2 stopped

  stopped() (arrayref)

The stopped method returns a list of PIDs whose processes have terminated.
Returns a list in list context.

I<Since C<2.40>>

=over 4

=item stopped example 1

  # given: synopsis

  package main;

  my $stopped = $parent->stopped;

  # child terminated

  # [...]

=back

=over 4

=item stopped example 2

  # given: synopsis

  package main;

  my $stopped = $parent->stopped;

  # child not terminated

  # []

=back

=cut

=head2 sync

  sync(number $count, number $timeout) (Venus::Process)

The sync method blocks the execution of the current process until the number of
L</other> processes are registered, pingable, and have each sent at-least one
message to the current process. This method returns the invocant when
successful, or throws an exception if the operation timed out.

I<Since C<2.91>>

=over 4

=item sync example 1

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  $process_2->send($process_1->pid, {from => $process_2->pid, said => "hello"});

  # in process 1

  $process_1 = $process_1->sync;

  # bless({...}, 'Venus::Process')

=back

=over 4

=item sync example 2

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  $process_2->send($process_1->pid, {from => $process_2->pid, said => "hello"});

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  $process_3->send($process_1->pid, {from => $process_3->pid, said => "hello"});

  # in process 1

  $process_1 = $process_1->sync(2);

  # bless({...}, 'Venus::Process')

=back

=over 4

=item sync example 3

  # given: synopsis

  package main;

  # in process 1

  my $process_1 = Venus::Process->new(12345)->register;

  # in process 2

  my $process_2 = Venus::Process->new(12346)->register;

  $process_2->send($process_1->pid, {from => $process_2->pid, said => "hello"});

  # in process 3

  my $process_3 = Venus::Process->new(12347)->register;

  $process_3->send($process_1->pid, {from => $process_3->pid, said => "hello"});

  # in process 1

  $process_1 = $process_1->sync(3, 0);

  # Exception! (isa Venus::Process::Error) (see error_on_timeout_sync)

=back

=cut

=head2 trap

  trap(string $name, string | coderef $expr) (Venus::Process)

The trap method registers a process signal trap (or callback) which will be
invoked whenever the current process receives that matching signal. The signal
traps are globally installed and will overwrite any preexisting behavior.
Signal traps are inherited by child processes (or forks) but can be overwritten
using this method, or reverted to the default behavior by using the L</untrap>
method.

I<Since C<0.06>>

=over 4

=item trap example 1

  # given: synopsis;

  $parent = $parent->trap(term => sub{
    die 'Something failed!';
  });

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 unregister

  unregister() (Venus::Process)

The unregister method declares that the process is no longer willing to
cooperate with others (e.g. L</send> nad L</recv> messages), and will no longer
be discoverable by other processes, and returns the invocant.

I<Since C<2.91>>

=over 4

=item unregister example 1

  # given: synopsis

  package main;

  my $unregister = $parent->unregister;

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 untrap

  untrap(string $name) (Venus::Process)

The untrap method restores the process signal trap specified to its default
behavior. If called with no arguments, it restores all signal traps overwriting
any user-defined signal traps in the current process.

I<Since C<0.06>>

=over 4

=item untrap example 1

  # given: synopsis;

  $parent->trap(chld => 'ignore')->trap(term => sub{
    die 'Something failed!';
  });

  $parent = $parent->untrap('term');

  # bless({...}, 'Venus::Process')

=back

=over 4

=item untrap example 2

  # given: synopsis;

  $parent->trap(chld => 'ignore')->trap(term => sub{
    die 'Something failed!';
  });

  $parent = $parent->untrap;

  # bless({...}, 'Venus::Process')

=back

=cut

=head2 unwatch

  unwatch(number @pids) (arrayref)

The unwatch method removes the PIDs provided from the watchlist and returns the
list of PIDs remaining to be watched. In list context returns a list.

I<Since C<2.40>>

=over 4

=item unwatch example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $unwatch = $parent->unwatch;

  # []

=back

=over 4

=item unwatch example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(1001..1004);

  my $unwatch = $parent->unwatch(1001);

  # [1002..1004]

=back

=over 4

=item unwatch example 3

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(1001..1004);

  my $unwatch = $parent->unwatch(1002, 1004);

  # [1001, 1003]

=back

=cut

=head2 wait

  wait(number $pid) (number, number)

The wait method does a blocking L<perlfunc/waitpid> operation and returns the
wait status. In list context, returns the specified process' exit code (if
terminated).

I<Since C<0.06>>

=over 4

=item wait example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($process, $pid) = $parent->fork;

  if ($process) {
    # in forked process ...
    $process->exit;
  }

  my $wait = $parent->wait($pid);

  # 0

=back

=over 4

=item wait example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($process, $pid) = $parent->fork;

  if ($process) {
    # in forked process ...
    $process->exit;
  }

  my ($wait, $status) = $parent->wait('00000');

  # (-1, -1)

=back

=over 4

=item wait example 3

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($process, $pid) = $parent->fork(sub{ $_->exit(1) });

  if ($process) {
    # in forked process ...
    $process->exit;
  }

  my ($wait, $status) = $parent->wait($pid);

  # ($pid, 1)

=back

=cut

=head2 waitall

  waitall(number @pids) (arrayref)

The waitall method does a blocking L</wait> call for all processes based on the
PIDs provided (or the PIDs returned by L</watchlist> if not provided) and
returns an arrayref of results from calling L</wait> on each PID. Returns a
list in list context.

I<Since C<2.40>>

=over 4

=item waitall example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $waitall = $parent->waitall;

  # []

=back

=over 4

=item waitall example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $waitall = $parent->waitall(1001);

  # [[1001, 0]]

=back

=over 4

=item waitall example 3

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my ($process, $pid) = $parent->fork;

  if ($process) {
    # in forked process ...
    $process->exit;
  }

  my $waitall = $parent->waitall;

  # [[$pid, 0]]

=back

=cut

=head2 watch

  watch(number @pids) (arrayref)

The watch method records PIDs to be watched, e.g. using the L</status> method
and returns all PIDs being watched. Returns a list in list context.

I<Since C<2.40>>

=over 4

=item watch example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $watch = $parent->watch;

  # []

=back

=over 4

=item watch example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $watch = $parent->watch(1001..1004);

  # [1001..1004]

=back

=over 4

=item watch example 3

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $watch = $parent->watch(1001..1004, 1001..1004);

  # [1001..1004]

=back

=over 4

=item watch example 4

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(1001..1004);

  my $watch = $parent->watch;

  # [1001..1004]

=back

=over 4

=item watch example 5

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my @watch = $parent->watch(1001..1004);

  # (1001..1004)

=back

=cut

=head2 watchlist

  watchlist() (arrayref)

The watchlist method returns the recorded PIDs. Returns a list in list context.

I<Since C<2.40>>

=over 4

=item watchlist example 1

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  my $watchlist = $parent->watchlist;

  # []

=back

=over 4

=item watchlist example 2

  package main;

  use Venus::Process;

  my $parent = Venus::Process->new;

  $parent->watch(1001..1004);

  my $watchlist = $parent->watchlist;

  # [1001..1004]

=back

=cut

=head2 work

  work(string | coderef $code, any @args) (number)

The work method forks the current process, runs the callback provided in the
child process, and immediately exits after. This method returns the I<PID> of
the child process. It is recommended to install an L<perlfunc/alarm> in the
child process (i.e. callback) to avoid creating zombie processes in situations
where the parent process might exit before the child process is done working.

I<Since C<0.06>>

=over 4

=item work example 1

  # given: synopsis;

  my $pid = $parent->work(sub{
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  # $pid

=back

=cut

=head2 works

  works(number $count, coderef $callback, any @args) (arrayref)

The works method creates multiple forks by calling the L</work> method C<n>
times, based on the count specified. The works method runs the callback
provided in the child process, and immediately exits after with an exit code of
C<0> by default. This method returns the I<PIDs> of the child processes. It is
recommended to install an L<perlfunc/alarm> in the child process (i.e.
callback) to avoid creating zombie processes in situations where the parent
process might exit before the child process is done working.

I<Since C<2.40>>

=over 4

=item works example 1

  # given: synopsis;

  my $pids = $parent->works(5, sub{
    my ($process) = @_;
    # in forked process ...
    $process->exit;
  });

  # $pids

=back

=cut

=head1 ERRORS

This package may raise the following errors:

=cut

=over 4

=item error: C<error_on_chdir>

This package may raise an error_on_chdir exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_chdir',
    error => $!,
    path => '/nowhere',
    pid => 123,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_chdir"

  # my $message = $error->render;

  # "Can't chdir \"$path\": $!"

  # my $path = $error->stash('path');

  # "/nowhere"

  # my $pid = $error->stash('pid');

  # 123

=back

=over 4

=item error: C<error_on_fork_process>

This package may raise an error_on_fork_process exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_fork_process',
    error => $!,
    pid => 123,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_fork_process"

  # my $message = $error->render;

  # "Can't fork process $pid: $!"

  # my $pid = $error->stash('pid');

  # "123"

=back

=over 4

=item error: C<error_on_fork_support>

This package may raise an error_on_fork_support exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_fork_support',
    pid => 123,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_fork_support"

  # my $message = $error->render;

  # "Can't fork process $pid: Fork emulation not supported"

  # my $pid = $error->stash('pid');

  # 123

=back

=over 4

=item error: C<error_on_ping>

This package may raise an error_on_ping exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_ping',
    pid => 123,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_ping"

  # my $message = $error->render;

  # "Process 123 not responding to ping"

  # my $pid = $error->stash('pid');

  # "123"

=back

=over 4

=item error: C<error_on_setid>

This package may raise an error_on_setid exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_setid',
    error => $!,
    pid => 123,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_setid"

  # my $message = $error->render;

  # "Can't start a new session: $!"

  # my $pid = $error->stash('pid');

  # 123

=back

=over 4

=item error: C<error_on_stderr>

This package may raise an error_on_stderr exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_stderr',
    error => $!,
    path => "/nowhere",
    pid => 123,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_stderr"

  # my $message = $error->render;

  # "Can't redirect STDERR to \"/nowhere\": $!"

  # my $path = $error->stash('path');

  # "/nowhere"

  # my $pid = $error->stash('pid');

  # 123

=back

=over 4

=item error: C<error_on_stdin>

This package may raise an error_on_stdin exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_stdin',
    error => $!,
    path => "/nowhere",
    pid => 123,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_stdin"

  # my $message = $error->render;

  # "Can't redirect STDIN to \"$path\": $!"

  # my $path = $error->stash('path');

  # "/nowhere"

  # my $pid = $error->stash('pid');

  # 123

=back

=over 4

=item error: C<error_on_stdout>

This package may raise an error_on_stdout exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_stdout',
    error => $!,
    path => "/nowhere",
    pid => 123,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_stdout"

  # my $message = $error->render;

  # "Can't redirect STDOUT to \"$path\": $!"

  # my $path = $error->stash('path');

  # "/nowhere"

  # my $pid = $error->stash('pid');

  # 123

=back

=over 4

=item error: C<error_on_timeout_poll>

This package may raise an error_on_timeout_poll exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_timeout_poll',
    code => sub{},
    timeout => 0,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_timeout_poll"

  # my $message = $error->render;

  # "Timed out after 0 seconds in process 12345 while polling __ANON__"

  # my $code = $error->stash('code');

  # sub{}

  # my $exchange = $error->stash('exchange');

  # undef

  # my $pid = $error->stash('pid');

  # 12345

  # my $timeout = $error->stash('timeout');

  # 0

=back

=over 4

=item error: C<error_on_timeout_pool>

This package may raise an error_on_timeout_pool exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_timeout_pool',
    pool_size => 2,
    timeout => 0,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_timeout_pool"

  # my $message = $error->render;

  # "Timed out after 0 seconds in process 12345 while pooling"

  # my $exchange = $error->stash('exchange');

  # undef

  # my $pid = $error->stash('pid');

  # 12345

  # my $pool_size = $error->stash('pool_size');

  # 2

  # my $timeout = $error->stash('timeout');

  # 0

=back

=over 4

=item error: C<error_on_timeout_sync>

This package may raise an error_on_timeout_sync exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_timeout_sync',
    pool_size => 2,
    timeout => 0,
  };

  my $error = $parent->catch('error', $input);

  # my $name = $error->name;

  # "on_timeout_sync"

  # my $message = $error->render;

  # "Timed out after 0 seconds in process 12345 while syncing"

  # my $exchange = $error->stash('exchange');

  # undef

  # my $pid = $error->stash('pid');

  # 12345

  # my $pool_size = $error->stash('pool_size');

  # 2

  # my $timeout = $error->stash('timeout');

  # 0

=back

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  # given: synopsis;

  my $result = "$parent";

  # $pid

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  # given: synopsis;

  my $result = $parent ~~ /^\d+$/;

  # 1

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut