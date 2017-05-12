use VRML;

$vrml = new VRML(2);
$vrml
->begin
    ->touchsensor("VIDEO")
    ->cube(4,"red; name=MPG; tex=your.mpg")
->end
->route("VIDEO.touchTime","MPG.startTime")
->save;
