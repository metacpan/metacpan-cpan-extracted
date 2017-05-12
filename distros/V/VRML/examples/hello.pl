use VRML;

$vrml = new VRML(2);
$vrml
->at("0 2 2")->billtext("Hello World","yellow","","MIDDLE")->back
->save;
