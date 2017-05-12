#
# subst.t 
#
# MetaText test script
#
# modify $ntests below to set the number of tests.  Test files 
# should be named $stub.n where 'n' is 1..$ntests

BEGIN { $stub = 'rogue'; $ntests = 4; 
        $| = 1; print "1..", $ntests + 1, "\n"; }

END   { print "not ok 1\n" unless $loaded; }

use Text::MetaText;
use lib qw(. t);
use vars qw($ntests $stub $testname);

require "test.pl";

$loaded = 1;
print "ok 1\n";


# initialise test functions and set post processing callback
&init();
&set_post_hook(\&write_warning);


# create a MetaText object
my $mtdef = Text::MetaText->new({
	ERROR => \&mt_warning,
    }) || die "failed to create MetaText object\n";

my $mtwrn = Text::MetaText->new({ 
	ROGUE => "warn",
	ERROR => \&mt_warning,
    }) || die "failed to create MetaText object\n";

my $mtdel = Text::MetaText->new({ 
	ROGUE => "delete",
	ERROR => \&mt_warning,
    }) || die "failed to create MetaText object\n";

my $mtdelwrn = Text::MetaText->new({ 
	ROGUE => "DELETE,warn",
	ERROR => \&mt_warning,
    }) || die "failed to create MetaText object\n";

my @mt = ($mtdef, $mtwrn, $mtdel, $mtdelwrn);

# a warning flag is set when MetaText complains, $messge is the error message
my $warning;
my $message;


# test each file
while ($loaded <= $ntests) {
    $testname = "$stub.$loaded";	    
    $warning  = 0;
    &test_file(++$loaded, $mt[($loaded - 2) % 4], $testname);
}



#
# MetaText warning function
#
sub mt_warning {
    $message = sprintf(shift, @_);
    $warning++;
}


#
# post_hook function
#
sub write_warning {
    my $mt   = shift;
    my $file = shift;
    local *WFP;

    return 0 unless $warning;

    open(WFP, ">> t/dest/$file") || return "t/dest/$file: $!\n";
    print WFP "MetaText Warning: $message";
    close WFP;

    # no error
    0;
}
    

