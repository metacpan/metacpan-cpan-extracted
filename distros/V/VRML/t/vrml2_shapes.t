print "1..6\n";

use VRML;

if (VRML->new(2)->box("5 1 3","cyan")->as_string eq "#VRML V2.0 utf8
Shape {
   appearance Appearance {
	       material Material {
		       diffuseColor    0 1 1
		}
	}
   geometry Box {
	   size    5 1 3
	}
}
") { print "ok 1\n"; } else { print "not ok 1\n";} ;

if (VRML->new(2)->cone("1 3","red")->as_string eq "#VRML V2.0 utf8
Shape {
   appearance Appearance {
	       material Material {
		       diffuseColor    1 0 0
		}
	}
   geometry Cone {
	   bottomRadius    1
	   height  3
	}
}
") { print "ok 2\n"; } else { print "not ok 2\n";} ;

if (VRML->new(2)->cube(5,"magenta")->as_string eq "#VRML V2.0 utf8
Shape {
   appearance Appearance {
	       material Material {
		       diffuseColor    1 0 1
		}
	}
   geometry Box {
	   size    5 5 5
	}
}
") { print "ok 3\n"; } else { print "not ok 3\n";} ;

if (VRML->new(2)->cylinder("2 4","blue")->as_string eq "#VRML V2.0 utf8
Shape {
   appearance Appearance {
	       material Material {
		       diffuseColor    0 0 1
		}
	}
   geometry Cylinder {
	   radius  2
	   height  4
	}
}
") { print "ok 4\n"; } else { print "not ok 4\n";} ;

if (VRML->new(2)->sphere(5,"yellow")->as_string eq "#VRML V2.0 utf8
Shape {
   appearance Appearance {
	       material Material {
		       diffuseColor    1 1 0
		}
	}
   geometry Sphere {
	   radius  5
	}
}
") { print "ok 5\n"; } else { print "not ok 5\n";} ;

if (VRML->new(2)->text("Hello world","white","10 SERIF BOLD")->as_string eq "\#VRML\ V2\.0\ utf8\
Shape\ \{\
\ \ \ appearance\ Appearance\ \{\
\	\ \ \ \ \ \ \ material\ Material\ \{\
\	\	\ \ \ \ \ \ \ diffuseColor\ \ \ \ 1\ 1\ 1\
\	\	\}\
\	\}\
\ \ \ geometry\ Text\ \{\
\	\ \ \ string\ \"Hello\ world\"\
\	\ \ \ fontStyle\ FontStyle\ \{\
\	\	\ \ \ size\ 10\
\	\	\ \ \ family\ \"SERIF\"\
\	\	\ \ \ style\ \"BOLD\"\
\	\	\}\
\	\}\
\}\
") { print "ok 6\n"; } else { print "not ok 6\n";} ;