#
# This file is part of Tk-ObjScanner
#
# This software is copyright (c) 2014 by Dominique Dumont.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# ObjScanner - data and object scanner

use Tk ;
use Tk::ObjScanner ;

use vars qw/$TOP/;

my $data = 
  { 
   'scalar: key1'    => 'value1',
   'ref array:'            => [qw/a b sdf/, {'v1' => '1', 'v2' => 2},'dfg'],
   'ref hash: key2'  => {
                         'sub key1' => 'sv1',
                         'sub key2' => 'sv2'
                        },
   'ref hash: piped|key'   => {a => 1 , b => 2},
   'pseudo hash'           => [{a => 1, b => 2}, 3, 4],
   'scalar: long'          => 'very long line'.'.' x 80 ,
   'scalar: is undef'      => undef,
   'scalar: some text'     => "some \n dummy\n Text\n",
   'ref blessed hash: tk widget' => $MW,
   'ref const'          => \12345,
   'ref scalar'         => \$scl,
   'ref ref tk widget'  => \$MW, # ref to ref
   'ref code'                => sub { my $x = shift; sin($x) + cos(2*$x) }
  } ;

sub objscan {
    my($demo) = @_;
    $TOP = $MW->WidgetDemo
      (
       -name => $demo,
       -text => 'ObjScanner - data and object scanner.',
       -geometry_manager => 'grid',
       -title => 'Data or Object Scanner',
       -iconname => 'ObjScannerDemo'
      ) ;
    
    $TOP->ObjScanner
      (
       caller 		 => $data,
       title 		 => 'demo scanner',
       destroyable       => 0
      ) ->grid ;
    
    $TOP->Label(-text => 'Click "See Code".')->grid;
}
__END__


  }


my $toto ;
my $mw = MainWindow-> new ;
$mw->geometry('+10+10');

my $w_menu = $mw->Frame(-relief => 'raised', -borderwidth => 2);
$w_menu->pack(-fill => 'x');

my $f = $w_menu->Menubutton(-text => 'File', -underline => 0)
  -> pack(side => 'left' );
$f->command(-label => 'Quit',  -command => sub{$mw->destroy;} );

print "creating dummy object \n" if $trace ;

my $dummy = new toto ($mw);

print "ok ",$idx++,"\n";

print "Creating obj scanner\n" if $trace ;
my $s = $mw -> ObjScanner
  (
  );
$s  -> pack(expand => 1, fill => 'both') ;

print "ok ",$idx++,"\n";

$mw->idletasks;

sub scan
  {
    my $topName = shift ;
    $s->yview($topName) ;
    $mw->after(200); # sleep 300ms

    foreach my $c ($s->infoChildren($topName))
      {
        my $item = $s->info('data', $c);
        $s->displaySubItem($c,$item);
        scan($c);
      }
    $mw->idletasks;
  }

if ($trace)
  {
    MainLoop ; # Tk's
  }
else
  {
    scan('root');
  }

print "ok ",$idx++,"\n";

