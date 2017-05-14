use Devel::TraceFuncs qw(trace debug);

sub foo {
  trace(my $f);

  debug "hi";
}

trace(my $f);

foo(1, 2);
debug "there";
