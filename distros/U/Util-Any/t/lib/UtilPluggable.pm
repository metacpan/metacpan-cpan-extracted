package UtilPluggable;

use Util::Any -Base, -Pluggable;

our $Utils = {
	      -pluggable => [
			     [
			      "String::CamelCase", '',
			      ["camelize"],
			     ],
			    ]
};

1;
