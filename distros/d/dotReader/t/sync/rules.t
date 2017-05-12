#!/usr/bin/perl

use strict;
use warnings;

my @expect;
BEGIN {
  my $table = 't/sync/table.rules.tsv';
  open(my $fh, '<', $table) or die "$table $!";
  @expect = grep({$_ and $_ !~ m/^#/} map({chomp;$_} <$fh>));
}

use inc::testplan(1,
  + 2 # use_ok
  + 14 + 1 # check_srev
  + 2 # errors
  + 3 # remote_delete
  + scalar(@expect) + 1 # data-driven
);

BEGIN {
  use_ok('dtRdr::Annotation::SyncRules') or die;
  use_ok('dtRdr::Annotation::IOBlob') or die;
}

# handy bits:
my $C = 'dtRdr::Annotation::SyncRules';
my $OBlob = sub {
  my $anno = dtRdr::Annotation::IOBlob->outgoing(
    book => '.',
    type => 'dtRdr::Note',
    @_
  );
  # should default some of the public props?
  return($anno);
};

{ # check_srev
  my @comb = (
    [0, 0, 0, 'SKIP'],
    [1, 1, 1, 'SKIP'],
    [0, 0, 2, 'FRESHEN'],
    [1, 1, 2, 'FRESHEN'],
    [1, 1, 8, 'FRESHEN'],
    [2, 1, 1, 'PUT'],
    [1, 0, 0, 'PUT'],
    [2, 1, 2, 'CONFLICT'],
    [2, 1, 3, 'CONFLICT'],
    [3, 1, 2, 'CONFLICT'],
    [0, undef, 0, 'CONFLICT'],
    [1, undef, 1, 'CONFLICT'],
    [2, undef, 1, 'CONFLICT'],
    [1, undef, 2, 'CONFLICT'],
    #[1, 2, 2, 'DEAD'], # XXX must be pre-checked?
  );
  foreach my $c (@comb) {
    my $name = join(",", map({defined($_) ? $_ : '~'} @$c[0..2])) .
      ' => ' . $c->[3];
    is($C->check_srev(@$c[0..2]), $c->[3], $name);
  }
  eval { $C->check_srev(); };
  ok($@, 'error on undef');
}

{ # check the builtin error handler
  my $r = dtRdr::Annotation::SyncRules->new();
  eval {$r->error('foo')};
  my $err = $@;
  ok($err);
  like($err, qr/^foo at /, 'builtin error handler');
}

{
  my $d1 = $OBlob->(
    id       => 'wibble',
    revision => 1,
    public => {
      rev => 1,
      server => 'foo',
    },
  );
  my $d2 = $OBlob->(
    id       => 'wobble',
    revision => 1,
    public => {
      rev => 1,
      server => 'foo',
    },
  );
  my $r = dtRdr::Annotation::SyncRules->new(
    current  => [],
    deleted  => [$d1, $d2],
    manifest => {
      wibble   => 1,
      wobble   => 1,
    },
    error    => sub {
      my ($anno, @message) = @_;
      return('ERROR', $anno);
    },
  )->init;
  my $count = 0;
  while(my @ans = $r->next) {
    $count++;
    my ($action, $obj) = @ans;
    is($action, 'REMOTE_DELETE', 'REMOTE_DELETE');
  }
  ok($count == 2, 'completed') or
    diag('looks like we lost track of ' . (2 - $count) . ' answers');
}

########################################################################
my @deleted;
my @current;
my %todo;
my %srev;
my %index;
my %expect;
########################################################################
# setup
{
  my $id = 0;
  foreach my $row (@expect) {
    if($row =~ s/(?:^%\s*)|(?:\s+TODO$)//) {
      $todo{$id} = 1;
    }
    my ($rev, $prev, $srev, $own, $del, $exp) = split(/ *\t */, $row);
    for($own, $rev, $prev, $srev, $del) {
      s/\~//;
      length($_) or $_ = undef;
    }

    $srev{$id} = $srev if(defined($srev));
    $expect{$id} = $exp;

    my $anno = $OBlob->(
      id       => $id,
      revision => $rev,
      public   => {
        owner => $own,
        rev   => $prev,
      }
    );
    $index{$id} = $anno;
    if($del) {
      $anno->{deleted} = 1;
      push(@deleted, $anno);
    }
    else {
      push(@current, $anno) if(defined($rev));
    }
    
    $id++;
  }
} # end setup

{
  my $r = dtRdr::Annotation::SyncRules->new(
    current  => [@current],
    deleted  => [@deleted],
    manifest => {%srev},
    error    => sub {
      my ($anno, @message) = @_;
      return('DIED.' . $message[0], $anno);
    },
  )->init;
  my $count = 0;
  my $wrap = sub {
    my @ans = eval {$r->next};
    $@ and return('>ERROR<', $@);
    return(@ans);
  };
  while(my @ans = $wrap->()) {
    $count++;
    my ($action, $obj) = @ans;
    if($action eq '>ERROR<') {
      diag(join(' ', @ans));
      ok(0, 'unknown');
      next;
    }
    my $id = eval{$obj->id};
    $@ and ($id = $obj);
    # These come out in whatever order so we append the line-number from
    # the input data.
    my $num = $id + 2;
    local $TODO = $todo{$id} ? ('from input line ' . $num) : undef;
    is($action, uc($expect{$id}), "expect $num");
  }
  my $w = scalar(@expect);
  ok($count == $w, 'completed') or
    diag('looks like we lost track of ' . ($w - $count) . ' answers');
}

# vim:ts=2:sw=2:et:sta:syntax=perl
