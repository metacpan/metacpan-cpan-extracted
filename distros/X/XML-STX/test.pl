# XML-STX test suite
BEGIN { 
    $| = 1;
    unshift @INC, 
      "blib/lib", "blib/arch", "test";
}

use strict;
use XML::STX;
use TestHandler;

print '-' x 47, "\n";
print "loaded\n";

my $total = 0;
my $passed = 0;
my @failed = ();
my @errors = (0,0,0);
my @err0 = ();
my $m = 0; # to measure times or not
my $time = 0;

$@ = undef;
eval "require Time::HiRes;";
$m = 1 unless $@;

my $stx = XML::STX->new(Writer => 'XML::STX::Writer');
$stx->{Parser} = 'XML::SAX::ExpatXS';

open(INDEX,'test/_index');

while (<INDEX>) {

    next if $_ =~ /^#/ or $_ =~ /^\s*$/;

    if ($_ =~ /^\$ERRORS(.*)$/) {
	@err0 = split(' ', $1);
	next;
    };

    chomp;
    $total++;
    my @ln = split('\|', $_, 4);

    my $templ_uri = "test/$ln[0].stx";
    my $data_uri = "test/_data$ln[1].xml";

    my $handler = TestHandler->new();

    $stx->{ErrorListener} = $handler;

    my $transformer = $stx->new_transformer($templ_uri);

    # external parameters
    unless ($ln[2] =~ /^\d+$/) {
	foreach (split(' ', $ln[2])) {
	    my ($name, $value) = split('=',$_,2);
	    $transformer->{Parameters}->{$name} = $value;
	}
    }

    my $source = $stx->new_source($data_uri);
    my $result = $stx->new_result($handler);

    $transformer->{ErrorListener} = $handler;

    my $t0 = Time::HiRes::time() if $m;
    $transformer->transform($source, $result);
    my $t = Time::HiRes::time() - $t0 if $m;
    $time += $t;

    $handler->{result} =~ s/\s//g;
    $ln[3] =~ s/\s//g;

    #print "->$handler->{result}\n";
    #print "->$ln[3]\n";

    my $dots = 35 - length($ln[0]);

    if ($handler->{result} eq $ln[3]) {
	print "$ln[0]", '.' x $dots, "OK";
	printf " (%.3f \s\)", $t if $m;
	print "\n";
	$passed++;

    } else {
	print "$ln[0]", '.' x $dots, "FAILED!\n";
	push @failed, $ln[0];
    }

    $errors[0] += $handler->{warnings};
    $errors[1] += $handler->{errors};
    $errors[2] += $handler->{fatals};
}

close INDEX;

# errors
$total++;
my $error_line = 'errors (' . join('-', @errors) . ')';
my $dots = 35 - length($error_line);

if (join('-',@err0) eq join('-', @errors)) {
    print $error_line, '.' x $dots, "OK\n";
    $passed++;
    
} else {
    print $error_line, '.' x $dots, "FAILED\n";
    push @failed, 'errors';
}
print '-' x 47, "\n";

if ($passed == $total) {
    print "All tests passed successfully: $passed/$total\n";
    printf "Total time: %.3f s\n", $time if $m;

} else {
    print "There were problems: $passed/$total\n";
    print '(', join(', ', @failed), ")\n";
}

print '-' x 47, "\n";
