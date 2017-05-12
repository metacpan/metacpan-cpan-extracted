use Text::Reform;

print form
{ header => { left => "Demo of problems", right=>sub{"page $_[0]"}, width=>20},
  footer => "end\n"x20,
  pagelen => 20
},
"<<<<<<<<<<<<<<<",
"oops";

{
	my $lexical = form { interleave=>1 };
}


