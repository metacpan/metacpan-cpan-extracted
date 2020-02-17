package Local::Example;
use Zydeco;

class Foo {
	has foo;
}

include MoreClasses;

class Bar {
	with MyRole;
	has bar;
}

include ::Local::Example::Roles;

1;
