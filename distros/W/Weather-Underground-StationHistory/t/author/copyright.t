#!perl

# Taken from http://www.chrisdolan.net/talk/index.php/2005/11/14/private-regression-tests/.

use utf8;
use strict;
use warnings;

use File::Find;
use File::Slurp;
use Test::More qw(no_plan);

my $this_year = [localtime]->[5]+1900;
my $copyrights_found = 0;
find({wanted => \&check_file, no_chdir => 1}, 'blib');
for (grep {/^readme/i} read_dir('.')) {
    check_file();
}
ok($copyrights_found != 0, 'found a copyright statement');

sub check_file {
    # $_ is the path to a filename, relative to the root of the
    # distribution

    # Only test plain files
    return if (! -f $_);

    # Filter the list of filenames
    return if (! m,^(?: README.*          # docs
                     |  .*/scripts/[^/]+  # programs
                     |  .*/script/[^/]+   # programs
                     |  .*/bin/[^/]+      # programs
                     |  .*\.(?: pl        # program ext
                             |  pm        # module ext
                             |  html      # doc ext
                             |  3pm       # doc ext
                             |  3         # doc ext
                             |  1         # doc ext
                            )
                    )$,xms);

    my $content = read_file($_);

    # Note: man pages will fail to match if the correct form of the
    # copyright symbol is used because the man page translators don't
    # handle UTF-8.
    my @copyright_years = $content =~ m/
                                       (?: copyright | \(c\) | © )
                                       \s*
                                       (?: \d{4} \\? - )?
                                       (\d{4})
                                       /gixms;
    if (0 < grep {$_ ne $this_year} @copyright_years) {
        fail("$_ copyrights: @copyright_years");
    } elsif (0 == @copyright_years) {
        pass("$_, no copyright found");
    } else {
        pass($_);
    } # end if

    $copyrights_found += @copyright_years;
} # end check_file()

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
