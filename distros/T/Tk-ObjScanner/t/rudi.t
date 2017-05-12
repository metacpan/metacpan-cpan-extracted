
use strict;
use warnings FATAL => qw(all);
###
### variant of test.pl for Tk:ObjScanner, with additional test cases
### by R Farkas rudif@lecroy.com 27 Jun 1999
###

use Test::More ;
use Tk ;
use ExtUtils::testlib ;
BEGIN { use_ok ('Tk::ObjScanner') ; };


my $trace = shift || 0 ;


package toto ;

use FileHandle;
use Benchmark;
use Math::BigInt;

sub new {
     my $type = shift;
     # add recursive data only if interactive test
     my $tkstuff = $trace ? shift : "may be another time ..." ;

     my $scl = 'my scalar var';

    my $self = { 'scalar: key1'    => 'value1',
                 'ref array:'            => [qw/a b sdf/, {'v1' => '1', 'v2' =>
2},'dfg'],
                 'ref hash: key2'  => {
                                         'sub key1' => 'sv1',
                                         'sub key2' => 'sv2'
                                              },
                 'ref hash: piped|key'   => {a => 1 , b => 2},
                 'scalar: long'          => 'very long line'.'.' x 80 ,
                 'scalar: is undef'      => undef,
                 'scalar: some text'     => "some \n dummy\n Text\n",
                 'ref blessed hash: tk widget' => $tkstuff,

                    'ref const'          => \12345,
                    'ref scalar'         => \$scl,
                    'ref ref tk widget'  => \$tkstuff,            # ref to ref (assumes $tkstuff is a ref)
                    'ref code'                => sub { my $x = shift; sin($x) +
cos(2*$x) },
                    'ref blessed glob'   => new FileHandle,
                    'ref blessed array' => new Benchmark,
                    'ref blessed scalar' => new Math::BigInt '123 456 789 123
456 789',

             } ;

    bless $self,$type;
  }

package main;

SKIP: {
    my $toto ;
    my $mw = eval { MainWindow-> new ; };

    # cannot create Tk window
    if (not $mw) {
        skip "Cannot create Tk window", 1 ;
        done_testing ;
        exit;
    }

$mw->geometry('+10+10');

my $w_menu = $mw->Frame(-relief => 'raised', -borderwidth => 2);
$w_menu->pack(-fill => 'x');

my $f = $w_menu->Menubutton(-text => 'File', -underline => 0)
  -> pack(-side => 'left' );
$f->command(-label => 'Quit',  -command => sub{$mw->destroy;} );


my $dummy = new toto ($mw);
    ok($dummy, "created dummy object");

my $s = $mw -> ObjScanner
  (
   'caller' => $dummy,
   title => 'test scanner'
  );
$s  -> pack(-expand => 1, -fill => 'both') ;
    ok($s, "Created obj scanner");

$mw->idletasks;

sub scan {
    my $topName = shift ;
        ok(1, "view $topName");
    $s->yview($topName) ;
    $mw->after(200); # sleep 300ms

    foreach my $c ($s->infoChildren($topName)) {
        $s->displaySubItem($c);
        scan($c);
      }
    $mw->idletasks;
  }

if ($trace) {
    MainLoop ; # Tk's
  }
else {
    scan('root');
  }

}

done_testing;

