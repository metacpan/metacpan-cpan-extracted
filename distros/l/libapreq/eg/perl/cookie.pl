#  Copyright 2000-2004  The Apache Software Foundation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use Apache::Cookie ();
use Apache::Request ();

use vars qw(@ANIMALS);

unless (@ANIMALS) {
    @ANIMALS = sort qw{
	lion tiger bear pig porcupine ferret zebra gnu ostrich
        emu moa goat weasel yak chicken sheep hyena dodo lounge-lizard
        squirrel rat mouse hedgehog racoon baboon kangaroo hippopotamus
	};
}

my $r = shift;
my $apr = Apache::Request->new($r);
my $cookies = Apache::Cookie->new($r)->parse;
my $c = $cookies->{'animals'}; 
my %zoo = ();
%zoo = $c->value if $c;

# Recover the new animal(s) from the parameter 'new_animal'
my @new = $apr->param('new_animals');

# If the action is 'add', then add new animals to the zoo.  Otherwise
# delete them.
foreach (@new) {
    if ($apr->param('action') eq 'Add') {
	$zoo{$_}++;
    } 
    elsif ($apr->param('action') eq 'Delete') {
	$zoo{$_}-- if $zoo{$_};
	delete $zoo{$_} unless $zoo{$_};
    }
}

# Add new animals to old, and put them in a cookie
my $cookie = Apache::Cookie->new($r,
				 -name => 'animals',
				 -value => \%zoo,
				 -expires => '+1h');

$cookie->bake;
$apr->send_http_header('text/html');
my $title = 'Animal crackers';

print <<EOF;
<HTML>
<HEAD><TITLE>$title</TITLE></HEAD>
<BODY>
<h1>$title</h1>
Choose the animals you want to add to the zoo, and click "add".
<p>
<center>
<table border>
<tr><th>Add/Delete<th>Current Contents
<tr><td>
<FORM METHOD="POST">
<SELECT NAME="new_animals" SIZE=10 MULTIPLE>
EOF

for (@ANIMALS) {
    print qq{<OPTION  VALUE="$_">$_\n}
}

print <<EOF;
</SELECT>
<br>
<INPUT TYPE="submit" NAME="action" VALUE="Delete">
<INPUT TYPE="submit" NAME="action" VALUE="Add">
</FORM>
<td>
EOF

if (%zoo) {
    print "<ul>\n"; 
    foreach (sort keys %zoo) { 
        print "<li>$zoo{$_} $_\n"; 
    } 
    print "</ul>\n"; 
}
else { 
    print "<strong>The zoo is empty.</strong>\n"; 
} 

print <<EOF;
</table></center>
</BODY></HTML>
EOF



