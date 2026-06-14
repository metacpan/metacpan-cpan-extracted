use Mojo::File qw/path/;
use Mojo::Util qw/dumper tablify/;
use Module::CoreList;
use strict;

$\ = "\n"; $, = "\t";

my $use;

for my $dir (qw/t lib/) {
    path($dir)->list_tree
	->grep(qr/\.pm$|\.pl$|\.t$/)
	->each(sub {
		   my $f = shift;
		   push $use->{$_}->@*, $f->to_string for map { /use ([\w:]+)/; $1 } grep { /use ([\S:]+)/ } split /\n/, $f->slurp;
	       });
}


print dumper $use;

print tablify [ map { [$_, Module::CoreList->first_release($_) ] } keys $use->%* ];

print for map { sprintf "%s = 0", $_ } sort grep { !Module::CoreList->first_release($_) } keys $use->%*;
