#
# Usage: perl batch.t [-g] [-p pattern]
#
# -p pattern:	Only runs the test cases for which the output filename
#		(e.g. t/out/dv_attr1.err) matches the specified pattern.
# -g:		Generates the t/out/*.err files (should probably only be 
#		used by enno)
# -d:		If specified, generates 2 output files in t/out:
#			dv_attr1.err.out1 : result of test case
#			dv_attr1.err.out2 : expected output (same as .err with 
#							     normalized newlines)
# -o:		Also print the result of the test case.
#
# This script basically runs all test cases for all xml files in the t/ directory
# and compares the output with the appropriate output in t/out/*.err
#
# There are currently 4 test cases:
# - cp: Uses XML::Checker::Parser
# - dc: Uses XML::DOM::Parser to create a XML::DOM::Document
#	and checks it with $doc->check.
# - dv: uses XML::DOM::ValParser
# - sc: Uses XML::Parser::PerlSAX to parse and 
#	passes data onto the SAX interface of XML::Checker
#
# The expected output of running script 'cp' on file attr.xml can be found in
# t/out/cp_attr1.err

use strict;
use Carp;
use Getopt::Std;
use Cwd;

use vars qw( $opt_t $opt_g $opt_p $opt_d $opt_o );
# disable warnings with -w
#$opt_o = $opt_d = $opt_t = $opt_g = $opt_p = undef;

getopts ("dogt:p:");

# Determine OS path separator
sub get_path_sep
{
    if ((defined $^O and
         $^O =~ /MSWin32/i ||
         $^O =~ /Windows_95/i ||
         $^O =~ /Windows_NT/i) ||
        (defined $ENV{OS} and
         $ENV{OS} =~ /MSWin32/i ||
         $ENV{OS} =~ /Windows_95/i ||
         $ENV{OS} =~ /Windows_NT/i))
    {
        return "\\";
    }
    elsif  ((defined $^O and $^O =~ /MacOS/i) ||
            (defined $ENV{OS} and $ENV{OS} =~ /MacOS/i))
    {
	return ":";
    }
    else	# Unix
    {
	return "/";
    }
}

sub slurp
{
    my $file = shift;
    local $/;          # slurp mode
    open (FILE, $file) || die "can't read $file";
    my $str = <FILE>;
    close FILE;

    # Normalize newlines to Unix style
    $str =~ s/(\x0D\x0A|\x0D|\x0A)/\x0A/g;

    return $str;
}

my $sep = get_path_sep();

# chdir to the t/ subdirectory
my $currdir = cwd;
my $prefix = "";
if (-d 't')
{
    chdir 't';
    $prefix = "t$sep";
}

my @xml = map { s/\.xml$//; $_ } <*.xml>;	# strip .xml suffix
chdir $currdir;

my $GENERATE = $opt_g;
my $ONLY = $opt_p || undef;

my @scripts = qw( sc dv cp dc );
my $num_tests = @xml * @scripts;

print "1..$num_tests\n";

my $testcase = 1;
for my $script (@scripts)
{
    for my $xml (@xml)
    {
	my $outfile = "${prefix}out${sep}${script}_$xml.err";
	next if defined $ONLY && $outfile !~ /$ONLY/;

#	print "-- run $outfile\n";

	my $err;
	{ 
	    no strict "refs";
	    $err = &$script ($prefix . $xml);
	}

	if ($GENERATE)
	{
	    if (open (OUT, ">$outfile"))
	    {
		print OUT $err;
		close OUT;
	    }
	    else
	    {
		print "(gen) could not open $outfile\n";
	    }
	}
	else
	{
	    my $same = same ($err, $outfile);
	    my $not = $same ? "" : "not ";
	    print "${not}ok $testcase - $script/$xml\n";
	}
	$testcase++;
    }
}

my $error_str = "";

sub my_fail
{
    $error_str .= XML::Checker::error_string (@_);
}

sub append_str
{
    $error_str .= shift() . "\n";
}

sub same
{
    my ($str, $outfile) = @_;
    if (open (FILE, $outfile))
    {
	local $/;	# temporarily set file slurping on
	my $str2 = <FILE> || "";
	close FILE;

	# Normalize newlines to current platform
	$str2 =~ s/(\x0D\x0A|\x0D|\x0A)/\n/g;

	# Different XML::Parser versions generate different 'byte' numbers
	# in their exceptions (e.g. some print 'byte -1' at the end of the
	# XML file, others print e.g. 'byte 42'), so here we simply
	# remove the byte number
	$str =~ s/byte\s\-?\d+//g;
	$str2 =~ s/byte\s\-?\d+//g;

	# Depending on the version of Perl (e.g. 5.005 vs. 5.6.0),
	# the order of the error messages is different, so here we
	# re-order the lines in alphabetical order
	$str = join("\n", sort split("\n",$str));
	$str2 = join("\n", sort split("\n",$str2));

	if ($opt_o)
	{
	    print $str;
	}

	if ($str eq $str2)
	{
	    return 1;
	}
	else
	{
	    if ($opt_d)
	    {
		open (OUT, ">$outfile.out1");
		print OUT $str;
		close OUT;
		open (OUT, ">$outfile.out2");
		print OUT $str2;
		close OUT;
	    }
	    return 0;
	}
    }
    else
    {
	print "ERROR: could not open $outfile: $?\n";
	return 0;
    }
}

# XML::Parser throws exceptions of the form:
#
#  no element found at line 5, column 0, byte -1 at 
#  /home1/enno/perl500502/lib/site_perl/5.005/sun4-solaris/XML/Parser.pm line 168
#
# For comparison purposes we have to chop off the filename, because that will
# be different for each installation
sub chop_exception
{
    my ($ex) = @_;
    $ex =~ s/ at \S+ line \d+//;
    $ex;
}

# Script 'cp': Uses XML::Checker::Parser
sub cp
{
    my ($xml) = @_;
    
    require XML::Checker::Parser;

    local $XML::Checker::FAIL = \&my_fail;
    $error_str = "";
    my $parser = new XML::Checker::Parser;
    eval
    {
	$parser->parse (slurp("$xml.xml"));
    };
    if ($@)
    {
	$error_str .= "PARSER TERMINATED: " . chop_exception($@);
    }
    $error_str;
}

# Script 'dc': Uses XML::DOM::Parser to create a XML::DOM::Document
#		and checks it with $doc->check.
sub dc
{
    my ($xml) = @_;
    
    require XML::DOM;
    require XML::Checker;

    local $XML::Checker::FAIL = \&my_fail;
    local *XML::DOM::warning = \&append_str;

    $error_str = "";
    my $parser = new XML::DOM::Parser;	# could pass options!
    eval
    {
	my $doc = $parser->parse (slurp("$xml.xml"));
	$doc->check;	# could pass Checker with options!
	$doc->dispose;
    };
    if ($@)
    {
	$error_str .= "PARSER TERMINATED: " . chop_exception($@);
    }
    $error_str;
}

# Script 'dv': uses XML::DOM::ValParser
sub dv
{
    my ($xml) = @_;
    
    require XML::DOM;
    require XML::DOM::ValParser;

    local $XML::Checker::FAIL = \&my_fail;
    local *XML::DOM::warning = \&append_str;

    $error_str = "";
    my $parser = new XML::DOM::ValParser;	# could pass options!
    eval
    {
	my $doc = $parser->parse (slurp("$xml.xml"));
	$doc->dispose;
    };
    if ($@)
    {
	$error_str .= "PARSER TERMINATED: " . chop_exception($@);
    }
    $error_str;    
}

# Script 'sc': Uses XML::Parser::PerlSAX to parse and 
#		passes data onto the SAX interface of XML::Checker
sub sc
{
    my ($xml) = @_;
    
    require XML::Parser::PerlSAX;
    require XML::Checker;

    local $XML::Checker::FAIL = \&my_fail;

    $error_str = "";
    my $checker = new XML::Checker;	# could pass options!
    my $parser = new XML::Parser::PerlSAX (Handler => $checker);

    if (open (STREAM, "$xml.xml"))
    {
	eval
	{
	    $parser->parse (Source => { ByteStream => \*STREAM });
	};
	if ($@)
	{
	    $error_str .= "PARSER TERMINATED: " . chop_exception($@);
	}
	close STREAM;
    }
    $error_str;
}

