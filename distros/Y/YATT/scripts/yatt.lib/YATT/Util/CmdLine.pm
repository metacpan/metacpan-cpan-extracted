package YATT::Util::CmdLine;
use strict;
use warnings qw(FATAL all NONFATAL misc);

BEGIN {require Exporter; *import = \&Exporter::import}

our @EXPORT_OK = qw(parse_opts parse_params);
our @EXPORT = @EXPORT_OK;

# posix style option.
sub parse_opts {
  my ($pack, $list, $result) = @_;
  my $wantarray = wantarray;
  unless (defined $result) {
    $result = $wantarray ? [] : {};
  }
  while (@$list
	 and my ($n, $v) = $list->[0] =~ /^--(?:([\w\.\-]+)(?:=(.*))?)?/) {
    shift @$list;
    last unless defined $n;
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
  for (; @$list and $list->[0] =~ /^([^=]+)=(.*)/; shift @$list) {
    $hash->{$1} = $2;
  }
  if (not $explicit and wantarray) {
    # return empty list if hash is empty
    %$hash ? $hash : ();
  } else {
    $hash
  }
}

1;
