use strict;
use warnings;

use Cwd qw(cwd abs_path);
use File::Spec;

use Test::More;

# this hateful noise is because we can't store a dir called .git
# in a git repo.
{
    use lib::relative::to;
    my $create_dir;
    my $create_file;
    sub _cleanup {
        unlink($create_file);
        rmdir($create_dir);
    }
    BEGIN {
        $create_dir = File::Spec->catdir(
            abs_path(
                lib::relative::to->parent_dir(
                    lib::relative::to->parent_dir(__FILE__)
                )
            ),
            '.git'
        );
        $create_file = File::Spec->catfile($create_dir, 'config');
        _cleanup();
        mkdir($create_dir)
            || die("Couldn't create temporary .git dir $create_dir: $!\n");
        open(my $fh, '>', $create_file)
            || die("Couldn't create temporary .git/config file $create_file: $!\n");
        close($fh);
    }
    END { _cleanup() }
}

use lib::relative::to GitRepository => 'lib';

my $lookfor = abs_path(File::Spec->catdir(
    cwd(),
    qw(t fakegitrepo lib)
));

$lookfor =~ s/\//\\/g if($lookfor =~ /^[A-Z]:\//);;
ok(
    (grep { $_ eq $lookfor } @INC),
    "Found '$lookfor' in \@INC"
) || diag('@INC contains ['.join(', ', @INC).']');

done_testing();
