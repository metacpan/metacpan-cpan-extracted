use Test::More tests => 3;

my $class = 'Test::Output';
my $sub   = 'stderr_from';

use_ok( $class );
can_ok( $class, $sub );

use Carp qw(carp);

my $message = "This is from carp";

my $output = do {
	no strict 'refs';
	&{ "${class}::$sub" }(
		sub { carp $message } 
		);
	};

like( 
	$output, 
	qr/^\Q$message\E at .* line \d+/, 
	"stderr_from captures carp message" 
	);