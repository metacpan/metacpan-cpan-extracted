package YATT::Lite::Util::CmdLine;
use strict;
use warnings qw(FATAL all NONFATAL misc);

BEGIN {require Exporter; *import = \&Exporter::import}

our @EXPORT = qw(parse_opts parse_params);
our @EXPORT_OK = (@EXPORT, qw(run process_result));

# posix style option.
sub parse_opts {
  my ($pack, $list, $result, $alias) = @_;
  my $wantarray = wantarray;
  unless (defined $result) {
    $result = $wantarray ? [] : {};
  }
  while (@$list and my ($n, $v) = $list->[0]
	 =~ m{^--$ | ^(?:--? ([\w:\-\.]+) (?: =(.*))?)$}xs) {
    shift @$list;
    last unless defined $n;
    $n = $alias->{$n} if $alias and $alias->{$n};
    $v = 1 unless defined $v;
    if (ref $result eq 'HASH') {
      $result->{$n} = $v;
    } else {
      push @$result, $n, $v;
    }
  }
  $wantarray && ref $result ne 'HASH' ? @$result : $result;
}

# 'Make' style parameter.
sub parse_params {
  my ($pack, $list, $hash) = @_;
  my $explicit;
  unless (defined $hash) {
    $hash = {}
  } else {
    $explicit++;
  }
  for (; @$list and $list->[0] =~ /^([^=]+)=(.*)/s; shift @$list) {
    $hash->{$1} = $2;
  }
  if (not $explicit and wantarray) {
    # return empty list if hash is empty
    %$hash ? $hash : ();
  } else {
    $hash
  }
}

sub run {
  my ($pack, $list, $alias) = @_;

  my @opts = parse_opts($pack, $list, $alias);
  my $app = do {
    if (ref $pack) {
      $pack->configure(@opts);
      $pack;
    } else {
      $pack->new(@opts);
    }
  };
  my $cmd = shift @$list || 'help';
  $app->configure(parse_opts($pack, \@_, $alias));

  if (my $sub = $app->can("cmd_$cmd")) {
    $sub->($app, @$list);
  } elsif ($sub = $app->can($cmd)) {
    process_result($sub->($app, @$list));
  } else {
    die "$0: Unknown subcommand '$cmd'\n"
  }
  if (my $sub = $app->can('DESTROY')) {
    $sub->($app);
  }
}

sub process_result {
  my (@res) = @_;
  if (not @res
      or @res == 1 and not $res[0]) {
    exit 1;
  } elsif (@res == 1 and defined $res[0] and $res[0] eq 1) {
    # nop
  } else {
    require YATT::Lite::Util;
    foreach my $res (@res) {
      unless (defined $res) {
	print "(undef)\n";
      } elsif (not ref $res) {
	print $res, "\n";
      } elsif (my $sub = $res->can('get_columns')) {
	my @kv = $sub->($res);
	my $cnt;
	while (my ($k, $v) = splice @kv, 0, 2) {
	  print "\t" if $cnt++;
	  print "$k=", YATT::Lite::Util::terse_dump($v);
	}
	print "\n";
      } else {
	print YATT::Lite::Util::terse_dump($res), "\n";
      }
    }
  }
}

1;
