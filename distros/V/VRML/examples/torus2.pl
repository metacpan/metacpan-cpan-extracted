use VRML;

$vrml = new VRML(2);
$vrml
->viewpoint_set(undef,20)
#->torus("3 0.5 45 180","red",{r1_step => 15, r2_step => 20, beginCap => 'TRUE', endCap => 'TRUE'}, {solid => FALSE})
->at("r=1 0 0 90")
	->torus("5 0.5 0 90 10","green; tr=0.5",1,0)
	->cylinder("5 1","red; tr=0.5")
->back
->save;
