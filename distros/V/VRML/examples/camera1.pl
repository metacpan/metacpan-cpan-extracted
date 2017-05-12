use VRML;

$vrml = new VRML (1);
$vrml->browser("Cosmo Player 2.0","Netscape")
->begin
->viewpoint_begin(1)
  ->viewpoint_set(undef,5)
  ->viewpoint("#Red","0 0 -5","0 1 0 180")
->viewpoint_end
->anchor_begin("#Red","To Red Side")
  ->pyramid('1 1 1','blue,green,red,yellow,white')
->anchor_end
->end
->save;
