#!/usr/bin/perl
use strict;

use lib qw(/usr/src/gam3/www-template/lib);

print "content-type: text/html\n\n";

use CGI;

use Data::Dumper;

my $cgi = CGI->new();

my %data = $cgi->Vars;

for my $x (keys %data) {
     $data{$x} = [ split("\0", $data{$x}) ];
}

our $bob = Dumper( \%data );

my @x = split('\s+', $bob);

chop($bob);

use WWW::Template;
use WWW::Template::Form;

my $data = sprintf(<<EOP, $bob);
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta name="generator" content=
  "HTML Tidy for Linux/x86 (vers 1 September 2005), see www.w3.org" />
  <title>bob</title>
</head>
<body>
  <div>
    <form name="form" id="form">
      This is test 1 <input type="checkbox" name="test" value=
      "1" /><br />
      This is test 2 <input type="checkbox" name="test" value=
      "2" /><br />
      This is test 3 <input type="checkbox" name="test" value=
      "3" /><br />
      This is test 4 <input type="checkbox" name="test" value=
      "4" /><br />
      <select name="test" multiple="multiple">
        <option value="1">one</option>
        <option value="2">two</option>
        <option value="3">three</option>
        <option value="4">four</option>
      </select>
      <br/>
      <input type="submit" />
    </form>
    <form name="form" id="form">
      This is test 1 <input type="checkbox" name="test2" value= "One" /><br />
      This is test 2 <input type="checkbox" name="test2" value= "Two" /><br />
      This is test 3 <input type="checkbox" name="test2" value= "Three" /><br />
      This is test 4 <input type="checkbox" name="test2" value= "Four" /><br />
      <select name="test2" multiple="multiple">
        <option value="1">one</option>
        <option value="2">two</option>
        <option value="3">three</option>
        <option value="4">four</option>
      </select>
      <br/>
      <input type="submit" />
    </form>
    <pre>%s</pre>
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
    name => 'test',
    type => 'multiselect',
);

$form->add_element(
    name => 'test2',
    type => 'multiselect',
    data => [
        {text => 'One'},
        {text => 'Two'},
        {text => 'Three'},
        {text => 'Four'},
    ],
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

