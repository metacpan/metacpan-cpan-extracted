package HTML::Tags;

use strict;
use warnings FATAL => 'all';
use XML::Tags ();

my @HTML_TAGS = qw(
a
abbr
address
area
article
aside
audio
b
base
bb
bdo
blockquote
body
br
button
canvas
caption
cite
code
col
colgroup
command
datagrid
datalist
dd
del
details
dialog
dfn
div
dl
dt
em
embed
eventsource
fieldset
figure
footer
form
h1
h2
h3
h4
h5
h6
head
header
hr
html
i
iframe
img
input
ins
kbd
label
legend
li
link
mark
map
menu
meta
meter
nav
noscript
object
ol
optgroup
option
output
p
param
pre
progress
q
ruby
rp
rt
samp
script
section
select
small
source
span
strong
style
sub
sup
table
tbody
td
textarea
tfoot
th
thead
time
title
tr
ul
var
video
);

sub import {
  my ($class, @rest) = @_;
  my $opts = ref($rest[0]) eq 'HASH' ? shift(@rest) : {};
  ($opts->{into_level}||=1)++;
  XML::Tags->import($opts, @HTML_TAGS, @rest);
}

sub to_html_string { XML::Tags::to_xml_string(@_) }

1;
