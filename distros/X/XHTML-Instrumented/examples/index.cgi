#!/usr/bin/perl

print "content-type: text/html;\n\n";

print <<EOP
<html>
<head>
<title>XHTML::Instrumented Examples</title>
</head>
<body>
<div id="all">
<h1> Tests </h1>
<ul>
<li><a href="test.cgi">test</a></li>
<li><a href="checkbox.cgi">checkbox</a></li>
<li><a href="multi.cgi">multi</a></li>
</ul>
</div>
</body>
</html>
EOP
