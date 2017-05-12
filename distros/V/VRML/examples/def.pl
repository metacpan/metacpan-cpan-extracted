use VRML;

$vrml = new VRML(1);
$vrml
->begin
->  viewpoint_begin()
->    viewpoint_set("1.5 3 0",15)
->  viewpoint_end
->  def("blue_cube")->cube(1,"blue")
->  at("3 0 0")->sphere(0.5)->back
->  at("0 2 0")
->  use("blue_cube")
->  at("0 2 0")
->  use("blue_cube")
->  at("0 2 0")
->  use("blue_cube")
->  at("0 2 0")
->  def("red_cube")->cube(.5,"red")
->  back
->  back
->  back
->  back
->end
->save;
