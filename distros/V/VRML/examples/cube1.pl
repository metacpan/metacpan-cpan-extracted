use VRML;

$vrml = new VRML(1);
$vrml
->transform_begin("0 0 -1", "r=0 0 1 45")
  ->cube(4,"green")
->transform_end
->save;
