#!/usr/bin/perl
#
# $Id: benchmark.pl,v 1.1 2001/02/27 15:56:07 tai Exp $
#
# Simple script to compare speed of various template processor
#

use Template;
use Benchmark;
use HTML::Embperl;
use Text::ScriptTemplate;
use Text::SimpleTemplate;

$text0 = <<'EOF';
<% for (0..9) { %>
<%= $name; %> = <%= $_ %><% if ($_ % 2) { %> (<%= $_ %> is odd)<% } %>
<% } %>
EOF

$text1 = <<'EOF';
[* for (0..9) { *]
[+ $main::name +] = [+ $_ +][* if ($_ % 2) { *] ([+ $_ +] is odd)[* } *]
[+ "\n" +]
[* } *]
EOF

$text2 = <<'EOF';
<%
my $text;
for (0..9) {
  $text .= qq{$name = $_};
  $text .= qq{ ($_ is odd)} if $_ % 2;
  $text .= qq{\n\n};
}
$text;
%>
EOF

$text3 = <<'EOF';
[% FOREACH i = [0..9] %]
[% name %] = [% i %][% IF i % 2 %] ([% i %] is odd)[% END %]
[% END %]
EOF

$text0 = "TEXT0:\n" . $text0 x 256;
$text1 = "TEXT1:\n" . $text1 x 256;
$text2 = "TEXT2:\n" . $text2 x 256;
$text3 = "TEXT3:\n" . $text3 x 256;
$name = 'value';

timethese(10, {
    'Text::ScriptTemplate' => \&func_00,
    'HTML::Embperl'        => \&func_01,
    'Text::SimpleTemplate' => \&func_02,
    'Template::Toolkit'    => \&func_03,
});

exit(0);

sub func_00 {
    my $temp;
    $tmpl = new Text::ScriptTemplate;
    $temp = $tmpl->pack($text0)->fill;
}

sub func_01 {
    my $buff = $text1; # needs to copy because of in-place data glinding
    my $temp; 

    HTML::Embperl::Execute({
        inputfile => 'test',
        input     => \$buff,
        output    => \$temp,
    });
}

sub func_02 {
    my $temp;
    $tmpl = new Text::SimpleTemplate;
    $temp = $tmpl->pack($text2)->fill;
}

sub func_03 {
    my $temp;
    $tmpl = new Template;
    $tmpl->process(\$text3, { name => $name }, \$temp);
}
