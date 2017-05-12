use strict;
use Devel::CheckOS qw(os_is os_isnt);
use Test::More;

my $script = 'get_streetmap';

# Exclude VMS because $^X doesn't work
# In general perl is a symlink to perlx.y.z
# but VMS stores symlinks differently...
if(os_is('OSFeatures::POSIXShellRedirection') and os_isnt('VMS') ) {
    plan tests => 1;
}
else {
    plan skip_all => 'Test not compatible with your OS';
}

my $out = `$^X -cw script/$script 2>&1`;

if($?) {
	diag($out);
	ok(0, 'Script does not compile');
}
else {
	ok(1);
}
