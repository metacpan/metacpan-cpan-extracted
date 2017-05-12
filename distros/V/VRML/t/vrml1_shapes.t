print "1..6\n";

use VRML;

if (VRML->new(1)->box("5 1 3","cyan")->as_string eq "#VRML V1.0 ascii
Group {
	Material {
	       diffuseColor  0 1 1
	}
	Cube {
	   width   5
	   height  1
	   depth   3
	}
}
") { print "ok 1\n"; } else { print "not ok 1\n";} ;

if (VRML->new(1)->cone("1 3","red")->as_string eq "#VRML V1.0 ascii
Group {
	Material {
	       diffuseColor  1 0 0
	}
	Cone {
	   bottomRadius    1
	   height  3
	}
}
") { print "ok 2\n"; } else { print "not ok 2\n";} ;

if (VRML->new(1)->cube(5,"magenta")->as_string eq "#VRML V1.0 ascii
Group {
	Material {
	       diffuseColor  1 0 1
	}
	Cube {
	   width   5
	   height  5
	   depth   5
	}
}
") { print "ok 3\n"; } else { print "not ok 3\n";} ;

if (VRML->new(1)->cylinder("2 4","blue")->as_string eq "#VRML V1.0 ascii
Group {
	Material {
	       diffuseColor  0 0 1
	}
	Cylinder {
	   radius  2
	   height  4
	}
}
") { print "ok 4\n"; } else { print "not ok 4\n";} ;

if (VRML->new(1)->sphere(5,"yellow")->as_string eq "#VRML V1.0 ascii
Group {
	Material {
	       diffuseColor  1 1 0
	}
	Sphere {
	   radius  5
	}
}
") { print "ok 5\n"; } else { print "not ok 5\n";} ;

if (VRML->new(1)->text("Hello world","white","10 SERIF BOLD")->as_string eq "\#VRML\ V1\.0\ ascii\
Group\ \{\
\	Material\ \{\
\	\ \ \ \ \ \ \ diffuseColor\ \ 1\ 1\ 1\
\	\}\
\	FontStyle\ \{\
\	\ \ \ size\ 10\
\	\ \ \ family\ SERIF\
\	\ \ \ style\ BOLD\
\	\}\
\	AsciiText\ \{\
\	\ \ \ string\ \"Hello\ world\"\
\	\}\
\}\
") { print "ok 6\n"; } else { print "not ok 6\n";} ;