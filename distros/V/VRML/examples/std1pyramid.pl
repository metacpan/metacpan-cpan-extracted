use VRML::VRML1::Standard;

$vrml = new VRML::VRML1::Standard;
$vrml
->DEF('Title')->Info("Pyramid")
->Info("Created with VRML::VRML1::Standard by H. Palm")
->PerspectiveCamera("0 0 5")
->Separator
->Material('diffuseColor' => ['1 0 0','0 1 0','0 0 1','1 1 0','0 1 1'])
->MaterialBinding('PER_FACE_INDEXED')
->Coordinate3("-1 -1 1","1 -1 1","1 -1 -1","-1 -1 -1","0 1 0")
->IndexedFaceSet(["0, 3, 2, 1","0, 1, 4","1, 2, 4","2, 3, 4","3, 0, 4"],[0..4])
->End
->save;
