#!/usr/bin/perl
use strict;

print "content-type: text/html\n\n";

use CGI;

my $cgi = CGI->new();

my %data = $cgi->Vars;

for my $x (keys %data) {
    $data{$x} = [ split("\0", $data{$x}) ];
}

use WWW::Template;
use WWW::Template::Form;

my $data = sprintf(<<EOP);
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta name="generator" content=
  "HTML Tidy for Linux/x86 (vers 1 September 2005), see www.w3.org" />
  <title>bob</title>
</head>
<body>
  <div>
    <form name="form" id="form">
      This is test 1 <input type="checkbox" name="checkbox" value=
      "1" /><br />
      This is test 2 <input type="checkbox" name="checkbox" value=
      "2" /><br />
      This is test 3 <input type="checkbox" name="checkbox" value=
      "3" /><br />
      This is test 4 <input type="checkbox" name="checkbox" value=
      "4" /><br />
      <input type="submit" />
    </form>
  </div>
</body>
</html>
EOP

my $template;
eval {
    $template = WWW::Template->new(name => \$data, type => '');
};

my $form = WWW::Template::Form->new(name => 'form', method => 'get');

$form->add_element(
    name => 'checkbox',
    type => 'checkbox',
);

$form->add_params( %data );

eval {
    print $template->output(
	form => $form,
    );
};
if ($@) {
    print $@;
}

