#!/usr/local/bin/perl
# $Id: files2dirs.pl,v 1.4 2006/05/14 01:40:03 kstephens Exp $

use 5.6.0;
use strict;
use warnings;

=head1 NAME

files2dirs - multiplexes a stream of files into separate files in their respective directories.

=head1 SYNOPSIS

files2dirs [ [-d <dir ] ]? <input.files> ]*

=head1 DESCRIPTION

Takes a stream of files and multplexes into separate files under the specified directory.

=head1 USAGE

uml2xmi test/test1.zargo 

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/06

=head1 SEE ALSO

L<ummf|ummf>

=head1 VERSION

$Revision: 1.4 $

=cut

use IO::File;

use File::Path;
use File::Basename;

my $tee = 0;
my $verbose = 0;
my $debug = 0;

my $_0dir = dirname($0);
my $pkg_dir = "$_0dir/..";
my $output_dir = '.';


sub process_input_file
{
    my ($input_file) = @_;

    my $src_in = new IO::File;
    $src_in->open("< $input_file") or die("Cannot read from '$input_file': $!");
    
    
    #my $out = [ '-', *STDOUT ];
    my $out = [ ];
    my @out;
    my $h = $out->[1];

    while ( defined($_ = <$src_in>) ) {
	chomp;
	
	print STDOUT $_, "\n" if ( $tee );
	
	my $ok = 1;

	if ( m@//-// FILE (COPY|MOVE) ([^\s]+)\s+([^\s]+)@ ) {
	  my $action = $1;
	  my $srcfile = $2;
	  my $dstfile = $3;
	  $dstfile = "$output_dir/$dstfile";
	  use File::Copy;
	  copy($srcfile, $dstfile) || die("Cannot copy file '$srcfile' to '$dstfile': $!");
	  unlink($srcfile) if $action eq 'MOVE';
	}
	elsif ( m@//-// FILE BEGIN ([^\s]+)@ ) {
	    my $file = $1;

	    push(@out, $out);
	    $out = [ $file, new IO::File ];

	    $file = "$output_dir/$file";
	    mkpath(dirname($file), 1);
	    
	    $out->[1]->open("> $file") || die("Cannot write to file '$file': $!");
	    $h = $out->[1];
   
	    print STDERR $_, "\n" if ( $verbose );
	}

	$ok = ! m@//-//@;

	print $h $_, "\n" if $h && $ok;
	
	if ( m@//-// FILE END ([^\s]+)@ ) {
	    my $file = $1;
	    die("Expected FILE END $out->[0]") unless $out->[0] eq $file;
	    $out->[1]->close;
	    $out = pop(@out) or die("Too many UNIT ENDs");
	    $h = $out->[1];
	}
    }
}



my @input_files;

while ( @ARGV ) {
    local $_ = shift @ARGV;
    if ( $_ eq '-' ) {
	push(@input_files, $_);
    }
    elsif ( s/^([-\+]){1,2}// ) {
	my $x = $1 . "1";
	if ( s/^v// ) {
	    $verbose += $x;
	}
	if ( s/^t// ) {
	    $tee += $x;
	}
	elsif ( s/^d// ) {
	    $output_dir = shift @ARGV;
	    die("Directory '$output_dir' does not exist") 
		unless -d $output_dir;
	}
    } 
    else {
	push(@input_files, $_);
    }
}


if ( @input_files ) {
    grep(process_input_file($_), @input_files);
} else {
    process_input_file('-');
}


exit(0);

1;
