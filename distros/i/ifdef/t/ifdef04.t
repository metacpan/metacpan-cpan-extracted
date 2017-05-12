
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ('../lib','.');
    }
}

use Test::More tests => 6;
use strict;
use warnings;

use_ok( 'ifdef','_testing_' );
my $original = <<'EOD';
my $foo = 'foo';

print "before sections: $foo\n";

=foo DEBUGGING

This is foo documentation

=begin DEBUGGING

my $foo = 'bar';
print "within debugging: $foo\n";

=begin VERBOSE

my $foo = 'baz';
print "within verbose: $foo\n";

=end

More foo documentation

=cut

# DEBUGGING print "we're debugging now\n";

print "after sections: $foo\n";
EOD

@ENV{qw(DEBUGGING VERBOSE)} = (0,0);
is( ifdef::process( $original ),<<'EOD',"Check process output" );
my $foo = 'foo';

print "before sections: $foo\n";





















# DEBUGGING print "we're debugging now\n";

print "after sections: $foo\n";
EOD

foreach ([1,0],[1,1]) {
    @ENV{qw(DEBUGGING WHOOPI)} = @{$_};
    is( ifdef::process( $original ),<<'EOD',"Check process output" );
my $foo = 'foo';

print "before sections: $foo\n";





{;

my $foo = 'bar';
print "within debugging: $foo\n";

}










 print "we're debugging now\n";

print "after sections: $foo\n";
EOD
}

@ENV{qw(DEBUGGING VERBOSE)} = (1,1);
is( ifdef::process( $original ),<<'EOD',"Check process output" );
my $foo = 'foo';

print "before sections: $foo\n";





{;

my $foo = 'bar';
print "within debugging: $foo\n";

}{

my $foo = 'baz';
print "within verbose: $foo\n";

}





 print "we're debugging now\n";

print "after sections: $foo\n";
EOD

@ENV{qw(DEBUGGING VERBOSE)} = (0,1);
is( ifdef::process( $original ),<<'EOD',"Check process output" );
my $foo = 'foo';

print "before sections: $foo\n";










{;

my $foo = 'baz';
print "within verbose: $foo\n";

}





# DEBUGGING print "we're debugging now\n";

print "after sections: $foo\n";
EOD
