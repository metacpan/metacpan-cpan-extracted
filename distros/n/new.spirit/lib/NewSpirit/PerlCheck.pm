# $Id: PerlCheck.pm,v 1.7 2001/10/18 13:03:47 joern Exp $

package NewSpirit::PerlCheck;

$VERSION = "0.01";

use strict;
use Carp;
use FileHandle;
use IPC::Open2;

sub new {
	my $type = shift;
	
	my %par = @_;
	
	my $fh_read = new FileHandle;
	my $fh_write = new FileHandle;
	
#	print STDERR "$$: open2 $CFG::perlcheck_program\n";

	open2 ($fh_read, $fh_write, "perl $CFG::perlcheck_program")
		or croak "can't call open2($CFG::perlcheck_program)";
	
	my $self = {
		fh_read => $fh_read,
		fh_write => $fh_write,
		directory => $par{directory} || $CFG::OS_temp_dir || '/tmp'
	};
	
	return bless $self, $type;
}

sub set_directory {
	my $self = shift;
	$self->{directory} = $_[0];
	1;
}

sub set_lib_path {
	my $self = shift;
	$self->{lib_path} = $_[0];
	1;
}

sub check {
	my $self = shift;
	
	my ($code_sref) = @_;
	
	my $fh_write = $self->{fh_write};
	my $fh_read = $self->{fh_read};
	
	my $delimiter = "__PERL_CODE_DELIMITER__";
	while ( $$code_sref =~ /$delimiter/ ) {
		$delimiter .= $$;
	}
	
	# send request to perlcheck.pl process

	print $fh_write <<__EOP;
check
$self->{directory}
$self->{lib_path}
$CFG::OS_temp_dir
$delimiter
$$code_sref
$delimiter
__EOP

	# read answer
	$delimiter = <$fh_read>;
	chomp $delimiter;

	my $result;
	while (<$fh_read>) {
		chomp;
		last if $_ eq $delimiter;
		$result .= "$_\n";
	}
		
	return $result;
}	

sub execute {
	my $self = shift;
	
	my ($code_sref, $filename) = @_;
	
	my $fh_write = $self->{fh_write};
	my $fh_read = $self->{fh_read};
	
	my $delimiter = "__PERL_CODE_DELIMITER__";
	while ( $$code_sref =~ /$delimiter/ ) {
		$delimiter .= $$;
	}
	
	# send request to perlcheck.pl process
	print $fh_write <<__EOP;
execute $filename
$self->{directory}
$self->{lib_path}
$CFG::OS_temp_dir
$delimiter
$$code_sref
$delimiter
__EOP

	# read answer
	$delimiter = <$fh_read>;
	chomp $delimiter;

	my $result;
	while (<$fh_read>) {
		chomp;
		last if $_ eq $delimiter;
		$result .= "$_\n";
	}
		
	return $result;
}	

sub DESTROY {
	my $self = shift;
	
	my $fh_write = $self->{fh_write};
	my $fh_read  = $self->{fh_read};
	
	# a empty line let the perlcheck.pl process exit
	print $fh_write "\n";

#	print STDERR "$$: send exit $CFG::perlcheck_program\n";
	
	close $fh_read;
	close $fh_write;
}

1;
