use strict;
use warnings;

use Cwd qw(cwd abs_path);
use File::Spec;

use lib::relative::to SvnCheckout => 'lib';

use Directory::relative::to qw(relative_dir);

use Test::More;

my $lookfor = abs_path(File::Spec->catdir(
    cwd(),
    qw(t fakesvncheckout trunk lib)
));

$lookfor =~ s/\//\\/g if($lookfor =~ /^[A-Z]:\//);;
ok(
    (grep { $_ eq $lookfor } @INC),
    "Found '$lookfor' in \@INC"
) || diag('@INC contains ['.join(', ', @INC).']');

is_deeply(
    [relative_dir( SvnCheckout => 'lib' )],
    [$lookfor],
    "relative_dir() returns the correct directories"
);

done_testing();
