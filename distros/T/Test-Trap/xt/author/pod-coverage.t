#!perl -T
# -*-mode:cperl-*-

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

{
  package MyPodCoverage;
  our @ISA = 'Pod::Coverage';
  my $package;
  sub _CvGV {
    my $self = shift;
    my $owner = $self->SUPER::_CvGV(@_);
    return $owner unless my $p = $self->{package}; # guard ...
    $owner =~ s/^\*Test::Trap::Builder/*$p/;       # evil!
    return $owner;
  }
  $INC{'MyPodCoverage.pm'} = 1; # pretend we're loaded :)
  # In newer Pod::Coverage, _CvGV above is not used, and no interface
  # is exposed to deal with this!  Bad Pod::Coverage!
  # All I can think of doing, is mess with B::GV::GvFLAGS instead:
  my $old = \&B::GV::GvFLAGS;
  my $imported_cv = eval { B::GVf_IMPORTED_CV() } || 0x80;
  no warnings 'redefine';
  *B::GV::GvFLAGS = sub {  # truly evil!
    my $r = $old->(@_);
    $r &= ~$imported_cv if $_[0]->FILE =~ m,/blib/lib/Test/Trap/Builder,;
    return $r;
  };
}

my $layer =
  qr/ ^ layer:
    (?: raw
      | die
      | exit
      | flow
      | stdout
      | stderr
      | warn
      | default
      | list
      | scalar
      | void
      | output
      | on_fail
      ) $
    /x;
my $accessor =
  qr/ (?: leaveby
	| exit
	| die
	| stdout
	| stderr
	| wantarray
	| return
	| warn
	| list
	| scalar
	| void
	)
    /x;
my $did = qr/ ^ did _ $accessor $ /x;
my $test =
  qr/ ^ $accessor _
    (?: ok
      | nok
      | is
      | isnt
      | isa_ok
      | like
      | unlike
      | cmp_ok
      | is_deeply
      ) $
    /x;
my $more =
  qr/ ^
    (?: Exception
      | Next
      | Prop
      | Run
      | Teardown
      | TestAccessor
      | TestFailure
      ) $
    /x;
all_pod_coverage_ok({ trustme => [$layer, $did, $test, $more],
		      coverage_class => 'MyPodCoverage',
		    });
