
use Test::Without::Module;
use Test::More tests => 5;

sub tryload {
  my $module = shift;
  my $failed = !eval "require $module; 1";
  my $error = $@;
  $error =~ s/(\(\@INC contains: ).*\)/$1...)/;
  $error =~ s/\n+\z//;
  my $inc_status =     !exists $INC{"$module.pm"} ? 'missing'
    : !defined $INC{"$module.pm"} ? 'undef'
    : !$INC{"$module.pm"} ? 'false'
    : '"'.$INC{"$module.pm"}.'"'
    ;
  return $failed, $error, $inc_status;
}

my ($failed,$error,$inc) = tryload( 'Nonexisting::Module' );
is $failed, 1, "Self-test, a non-existing module fails to load";
like $error, qr!^Can't locate Nonexisting/Module.pm in \@INC( \(you may need to install the Nonexisting::Module module\))? \(\@INC !,
    'Self-test, error message shows @INC';
#diag $error;

# Now, hide a module that has not been loaded:
ok !$INC{'IO/Socket.pm'}, "Module 'IO/Socket.pm' has not been loaded yet";
Test::Without::Module->import('IO::Socket');

($failed,$error,$inc) = tryload( 'IO::Socket' );
is $failed, 1, "a non-existing module fails to load";
like $error, qr!Can't locate IO/Socket.pm in \@INC( \(you may need to install the IO::Socket module\))? \(\@INC !, 'error message for hidden module shows @INC';
#diag $error;
