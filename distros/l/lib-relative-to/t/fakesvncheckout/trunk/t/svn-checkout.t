use strict;
use warnings;

use Cwd qw(cwd abs_path);
use File::Spec;

use lib::relative::to SvnCheckout => 'lib';

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

done_testing();
