use VRML::VRML1::Standard;

$vrml = new VRML::VRML1::Standard;
$vrml->Separator('Demo Cube')
->Cube(5,3,2)
->End
->save;
