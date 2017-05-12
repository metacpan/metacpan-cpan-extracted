use VRML::VRML2::Standard;

$vrml = new VRML::VRML2::Standard;
$vrml->WorldInfo("Pyramid","Created with VRML::VRML2::Standard by H. Palm")
->NavigationInfo("EXAMINE")
->Viewpoint("Home","0 0 5","0 0 -1 0")
->Shape(
    sub{$vrml->IndexedFaceSet(
	sub{$vrml->Coordinate("-1 -1 1","1 -1 1","1 -1 -1","-1 -1 -1","0 1 0")},
	["0, 3, 2, 1","0, 1, 4","1, 2, 4","2, 3, 4","3, 0, 4"],
	sub{$vrml->Color('1 0 0','0 1 0','0 0 1','1 1 0','0 1 1')}
	)
    },
    sub{$vrml->Appearance(
	sub{$vrml->Material(diffuseColor => "1 1 1")}
	)
    }
)
->save;
