        use strict;
        use Test::More;
        eval "use Test::Pod 1.00";
        plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
        my @poddirs = qw( blib script );
        all_pod_files_ok( all_pod_files( @poddirs ) );

__END__

use strict;
use warnings;

use Test::More;

my
	$VERSION = do { my @r = ( q$Revision: 1.2 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Cwd;
chdir "t" if getcwd() !~ '\Wt';	# For dev

eval "use Test::Pod 1.00";

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();

__END__

