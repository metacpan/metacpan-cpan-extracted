package Foo::Bar;  # this is a hard-coded package name
use 5.010;

{
	use package::compute "../Quux";
	say __PACKAGE__;              # says "Foo::Quux";
	say __RPACKAGE__("./Xyzzy");  # says "Foo::Quux::Xyzzy";
	
	sub hello { say __PACKAGE__ };
}

say __PACKAGE__;   # says "Foo::Bar" (lexically scoped!)
Foo::Quux->hello;  # says "Foo::Quux"
