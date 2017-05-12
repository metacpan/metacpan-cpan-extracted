use strict;
use warnings;
use Test::More tests => 30;
use ok 'XML::All';

my $xml = < <a href='/'>1<b>2</b><em>3</em></a> >;

is($$xml, 'a', 'scalar fetch');
$$xml = 'link';
is($xml, < <link href='/'>1<b>2</b><em>3</em></link> >, 'scalar store');
is(join(",", @$xml), "1,<b>2</b>,<em>3</em>", 'array fetch all');
is($xml->[1], < <b>2</b> >, 'array fetch elem');
$xml->[2] = < <u>2</u> >;
is($xml->[2], < <u>2</u> >, 'array store elem at boundary');
$xml->[3] = < <i>3</i> >;
is($xml->[3], < <i>3</i> >, 'array store elem over boundary');
is($#$xml, 3, 'array count');
delete $xml->[2];
is($xml, < <link href='/'>1<b>2</b><i>3</i></link> >, 'array delete');

my $pop = pop @$xml;
is($pop, < <i>3</i> >, 'array pop');
is($xml, < <link href='/'>1<b>2</b></link> >, 'array pop');
push @$xml, <hr/>, <div/>;
is($xml, < <link href='/'>1<b>2</b><hr/><div/></link> >, 'array push');

my $shift = shift @$xml;
is($shift, 1, 'array shift');
is($xml, < <link href='/'><b>2</b><hr/><div/></link> >, 'array shift');
unshift @$xml, <hr/>, <div/>;
is($xml, < <link href='/'><hr/><div/><b>2</b><hr/><div/></link> >, 'array unshift');

@{$xml->[2]} = ();
is($#{$xml->[2]}, -1, 'array clear');

is(join(",", %$xml), "href,/", 'hash fetch');
is($xml->{href}, '/', 'hash fetch elem');
$xml->{class} = 'moose';
is($xml->{class}, 'moose', 'hash store elem');
is($xml, < <link class='moose' href='/'><hr/><div/><b></b><hr/><div/></link> >, 'hash store elem');

$xml->[0] = 123;
is($xml->[0], 123, 'set pcdata');
$xml->[2] = < <b>2</b> >;

is($xml->b, '<b>2</b>', 'selector');
is(($xml->b * 10), 20, 'numify');
is($xml->(), 123, 'pcdata deref');

is($xml->b + <hr/>, < <b>2<hr/></b> >, '+');
$xml += <hr/>;
is($xml->[-1], <hr/>, '+=');

$xml -= <div/>;
$xml -= <b/>;
is($xml, < <link class='moose' href='/'>123<hr/><hr/></link> >, '-');
is($xml - <hr/>, < <link class='moose' href='/'>123</link> >, '-=');

undef ${ $xml->[-1] };
is($xml, < <link class='moose' href='/'>123<hr/></link> >, 'undef $$x');

$xml->(
    hr => sub { $$_ = "moose" }
);
is($xml, < <link class='moose' href='/'>123<moose/></link> >, 'callback');
