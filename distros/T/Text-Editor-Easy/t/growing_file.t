use Test::More;
use Config;
BEGIN {
    if ( ! $Config{'useithreads'} ) {
        plan skip_all => "Perl not compiled with 'useithreads'";
    }
    elsif ( ! -f 'tk_is_ok' ) {
        plan skip_all => "Tk is not working properly on this machine";
    }
    else {
        plan no_plan;
    }
}

use strict;
use lib '../lib';

use Text::Editor::Easy;
use IO::File;

open (GRO, ">growing.txt" ) or die "Impossible d'ouvrir growing.txt : $!\n";
autoflush GRO;
print GRO "toto";


my $editor = Text::Editor::Easy->new({
    'file' => 'growing.txt',
    'growing_file' => 1,
});
		
is ( $editor->slurp, "toto", "No insertion");

print GRO "tutu";
$editor->growing_update;

is ( $editor->slurp, "tototutu", "insertion, no new line");

print GRO "titi\n";
$editor->growing_update;

is ( $editor->slurp, "tototututiti\n", "insertion, new empty line");

print GRO "tata";
$editor->growing_update;

is ( $editor->slurp, "tototututiti\ntata", "insertion, fill empty line");

print GRO "zaza\nzozo";
$editor->growing_update;

is ( $editor->slurp, "tototututiti\ntatazaza\nzozo", "insertion, fill non empty line, new line");

print GRO "\n";
$editor->growing_update;

is ( $editor->slurp, "tototututiti\ntatazaza\nzozo\n", "empty line");

print GRO "\n\n\n";
$editor->growing_update;

is ( $editor->slurp, "tototututiti\ntatazaza\nzozo\n\n\n\n", "3 empty lines");


close GRO;