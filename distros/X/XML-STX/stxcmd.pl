#!/usr/bin/perl
BEGIN {
    unshift @INC, "blib/lib", "blib/arch",
}

use strict;
use XML::STX;

my $stx = XML::STX->new();

# set custom parser and writer here
#$stx->{Parser} = 'XML::SAX::ExpatXS';
#$stx->{Writer} = 'XML::STX::Writer';

my ($v, $m, $sheet, $data, $params) = _check_arguments(@ARGV);

my $t1 = Time::HiRes::time() if $m;
my $transformer = $stx->new_transformer($sheet);
my $t2 = Time::HiRes::time() if $m;

foreach (keys %$params) {
    $transformer->{Parameters}->{$_} = $params->{$_};
}

my $source = $stx->new_source($data);
my $result = $stx->new_result();

my $t3 = Time::HiRes::time() if $m;
my $rc = $transformer->transform($source, $result);
my $t4 = Time::HiRes::time() if $m;

if ($m) {
    my $t_parse = $t2 - $t1;
    my $t_trans = $t4 - $t3;
    my $t_total = $t4 - $t1;
    
    print "\n-------------------------------\n";
    printf "Parsing templates: %.6f \[s\]\n", $t_parse;
    printf "Transformation   : %.6f \[s\]\n", $t_trans;
    printf "Total time       : %.6f \[s\]\n", $t_total;
}


######################################################################
#subroutines

sub _help {
    print "STXCMD.PL\n\ta command line interface to XML::STX\n";
    print "USAGE\n\tstxcmd.pl [OPTIONS] <stylesheet> <data> [PARAMS]\n\n";
    print "OPTIONS\n";
    print "\t-m : measures and displays duration of transformation\n";
    print "\t-h : displays this help info\n";
    print "\t-v : displays versions of XML::STX and parser/writer to be used\n\n";
    print "PARAMS\n\tname=value pairs separated by a space\n\n";
    print "EXAMPLE\n\tstxcmd.pl -m stylesheet.stx data.xml p1=5 p2=yes\n\n";
    print "copyright (C) 2002 - 2003 Ginger Alliance (www.gingerall.com)\n";
}

sub _check_arguments {
    my @args = @_;
    my $v; 
    my $m; 
    my $sheet; 
    my $data;
    my @params;

    (@args >= 1) || (_help and exit);

    if ($args[0] =~ /^-([m|h|v])$/) {
	shift @args;

	if ($1 eq 'h') {
	    _help and exit;

	} elsif ($1 eq 'v') {
	    print "\nXML::STX $XML::STX::VERSION\n";
	    _desc($stx->_get_parser);
	    _desc($stx->_get_writer);
	    exit;

	} else { # $1 eq 'm'
	    if (@args >= 2) {
		$sheet = shift @args;
		$data = shift @args;
		@params = @args;
		$m = 1;

		$@ = undef;
		eval "require Time::HiRes;";
		if ($@) {
		    print "Time::HiRes is required to measure times!\n";
		    exit;
		}

	    } else {
		_help and exit;
	    }
	}

    } else {
	
	if (@args >= 2) {
	    $sheet = shift @args;
	    $data = shift @args;
	    @params = @args;
	    
	} else {
	    _help and exit;
	}
    }

    my $params = {};
    foreach (@params) {
	my ($name, $value) = split('=',$_,2);
	$params->{$name} = $value;
    }

    return ($v, $m, $sheet, $data, $params);
}

sub _desc {
    my $o = shift;

    my $name = ref $o;
    my $v = $o->VERSION();

    # XML::SAX::Writer needs an extra treatment :(
    if ($name eq 'XML::Filter::BufferText'){
	$name = 'XML::SAX::Writer';
	$v = $XML::SAX::Writer::VERSION;
    }

    print "$name $v\n";
}

exit 0;
