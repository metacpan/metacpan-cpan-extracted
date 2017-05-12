use VRML::VRML1::Standard;

$vrml = new VRML::VRML1::Standard;
$vrml
->PerspectiveCamera("0 0 5")
->Separator('Coordinate3 and IndexFaceSet')
->Material('diffuseColor' => ['1 1 1','1 1 0','1 0 0','0 0 1'])
->MaterialBinding('PER_VERTEX_INDEXED')
->Coordinate3("-1 1 0","1 1 0","1 -1 0","-1 -1 0")
->IndexedFaceSet(["1, 0, 3, 1","1, 2, 3, 1"],["2, 1, 0, 3"])
->End
->save;
