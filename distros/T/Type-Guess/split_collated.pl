use Mojo::File qw/path/;
use Mojo::Util qw/dumper/;
use strict;

$\ = "\n"; $, = "\t";

for (map { path($_) } grep { -f } @ARGV) {
    my $input = $_->slurp;

    my $files = { grep { $_ } split /#{12,}\n# (.+?)\n#{12,}\n+/, $input };

    # print dumper $files;
    
    for (keys $files->%*) {
	my $output = path($_);
	$output->dirname->make_path;
	$output->spew($files->{$_});
    }
}
