use VRML;

VRML->new(2)
->browser("Cosmo Player")
->worldinfo("Pyramid","Created with VRML-modules by H.Palm")
->viewpoint("Home","0 0 4","0 0 -1 0")
->pyramid("1 1 1","red,green,blue,yellow,cyan")
->save;
