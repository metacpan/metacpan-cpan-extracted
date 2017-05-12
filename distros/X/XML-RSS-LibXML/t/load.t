BEGIN {
	use File::Find;
	
	@files = ();

        my $lib = 'lib';
        $lib = 'blib/lib' if -e 'blib/lib';

	find(sub { push @files, $File::Find::name if $_ =~ m/\.pm$/;}, ($lib));
	
	@classes = map { my $x = $_;
		$x =~ s|^blib/lib/||;
		$x =~ s|/|::|g;
		$x =~ s|\.pm$||;
		$x;
		} @files;
	}

use Test::More tests => scalar @classes;
	
foreach my $class ( @classes ){
	print "bail out! $class did not compile" unless use_ok( $class );
}

