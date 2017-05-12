use t::boilerplate;

use Test::More;
use Test::Requires { Moo => 1.002 };
use English      qw( -no_match_vars );
use Unexpected;

{  package MyNESS;

   use Moo;
   use Unexpected::Types qw( NonEmptySimpleStr );

   has 'test_ness'  => is => 'ro', isa => NonEmptySimpleStr, default => sub {};

   $INC{ 'MyNESS.pm' } = __FILE__;
}

my $myness; eval { $myness = MyNESS->new };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non empty simple str - undef';

eval { $myness = MyNESS->new( test_ness => '' ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non empty simple str - null';

eval { $myness = MyNESS->new( test_ness => "\n" ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non empty simple str - newline';

eval { $myness = MyNESS->new( test_ness => 'x' ) };

is $EVAL_ERROR, q(), 'Non empty simple str - passes';

{  package MyNZPI;

   use Moo;
   use Unexpected::Types qw( NonZeroPositiveInt );

   has 'test_nzpi'  => is => 'ro', isa => NonZeroPositiveInt, default => sub {};

   $INC{ 'MyNZPI.pm' } = __FILE__;
}

my $mynzpi; eval { $mynzpi = MyNZPI->new };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non zero positive int - undef';

eval { $mynzpi = MyNZPI->new( test_nzpi => '' ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non zero positive int - null';

eval { $mynzpi = MyNZPI->new( test_nzpi => "0" ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non zero positive int - zero';

eval { $mynzpi = MyNZPI->new( test_nzpi => "-1" ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non zero positive int - negative';

eval { $mynzpi = MyNZPI->new( test_nzpi => '1' ) };

is $EVAL_ERROR, q(), 'Non zero positive int - passes';

{  package MyNZPN;

   use Moo;
   use Unexpected::Types qw( NonZeroPositiveNum );

   has 'test_nzpn'  => is => 'ro', isa => NonZeroPositiveNum, default => sub {};

   $INC{ 'MyNZPN.pm' } = __FILE__;
}

my $mynzpn; eval { $mynzpn = MyNZPN->new };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non zero positive num - undef';

eval { $mynzpi = MyNZPN->new( test_nzpn => '' ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non zero positive num - null';

eval { $mynzpi = MyNZPN->new( test_nzpn => "0" ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non zero positive num - zero';

eval { $mynzpi = MyNZPN->new( test_nzpn => "-1" ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non zero positive num - negative';

eval { $mynzpi = MyNZPN->new( test_nzpn => '0.1' ) };

is $EVAL_ERROR, q(), 'Non zero positive num - passes';

{  package MyNNSS;

   use Moo;
   use Unexpected::Types qw( NonNumericSimpleStr );

   has 'test_nnss'  => is => 'ro', isa => NonNumericSimpleStr,
   default          => sub {};

   $INC{ 'MyNNSS.pm' } = __FILE__;
}

my $mynnss; eval { $mynnss = MyNNSS->new };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non numeric simple str - undef';

eval { $mynnss = MyNNSS->new( test_nnss => 1 ) };

like $EVAL_ERROR, qr{ not \s+ a \s+ non }mx, 'Non numeric simple str - numeric';

eval { $mynnss = MyNNSS->new( test_nnss => '' ) };

is $EVAL_ERROR, q(), 'Non numeric simple str - null passes';

eval { $mynnss = MyNNSS->new( test_nnss => 'fred' ) };

is $EVAL_ERROR, q(), 'Non numeric simple str - string passes';

{  package MyLoadableClass;

   use Moo;
   use Unexpected::Types qw( LoadableClass );

   has 'test_class' => is => 'ro', isa => LoadableClass,
      coerce        => LoadableClass->coercion;

   $INC{ 'MyLoadableClass.pm' } = __FILE__;
}

my $mylc  = MyLoadableClass->new( test_class => 'Unexpected' );
my $trace = $mylc->test_class->new;

ok $trace->can( 'frames' ), 'Loadable class';

eval { MyLoadableClass->new( test_class => 'Not::Bloody::Likely' ) };

my $e = Unexpected->caught;

like $e, qr{ not \s+ a \s+ loadable }mx, 'Unloadable class';

eval { MyLoadableClass->new( test_class => '------' ) };

$e = Unexpected->caught;

like $e, qr{ not \s+ a \s+ loadable }mx, 'Invalid class name';

{  package ReqFac;

   use Moo;

   $INC{ 'ReqFac.pm' } = __FILE__;
}

{  package MyReq;

   use Moo;
   use Unexpected::Types qw( RequestFactory );

   has 'req'  => is => 'ro', isa => RequestFactory,
      builder => sub { ReqFac->new };

   $INC{ 'MyReq.pm' } = __FILE__;
}

my $myreq; eval { $myreq = MyReq->new };

like $EVAL_ERROR, qr{ \Qnew_from_simple_request\E }mx,
   'RequestFactory - missing method';

{  package MyTracer;

   use Moo;
   use Unexpected::Types qw( Tracer );

   has 'test_tracer'  => is => 'ro', isa => Tracer, default => sub {};

   $INC{ 'MyTracer.pm' } = __FILE__;
}

my $mytracer; eval { $mytracer = MyTracer->new };

like $EVAL_ERROR, qr{ not \s+ an \s+ object }mx, 'Tracer - undef';

eval { $mytracer = MyTracer->new( test_tracer => 'Unexpected' ) };

like $EVAL_ERROR, qr{ not \s+ an \s+ object }mx, 'Tracer - not an object ref';

{  package NoFrames;

   use strict;
   use warnings;

   sub new { bless {}, __PACKAGE__ }

   $INC{ 'NoFrames.pm' } = __FILE__;
}

my $noframes = NoFrames->new;

eval { $mytracer = MyTracer->new( test_tracer => $noframes ) };

like $EVAL_ERROR, qr{ missing \s+ a \s+ frames }mx, 'Tracer - missing method';

eval { $mytracer = MyTracer->new( test_tracer => $trace ) };

is $EVAL_ERROR, q(), 'Tracer - passes';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
