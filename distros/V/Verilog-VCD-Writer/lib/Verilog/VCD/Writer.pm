use strict;
use warnings;
package Verilog::VCD::Writer;
$Verilog::VCD::Writer::VERSION = '0.002';
use DateTime;
use Verilog::VCD::Writer::Module;

# ABSTRACT: VCD waveform File creation module.
 


use  v5.10;
use Moose;
use namespace::clean;


has timescale =>(is =>'ro',default=>'1ps');
has vcdfile =>(is =>'ro');
has date =>(is=>'ro',isa=>'DateTime',default=>sub{DateTime->now()});
has _modules=>(is=>'ro',isa=>'ArrayRef[Verilog::VCD::Writer::Module]',
	default=>sub{[]},
	traits=>['Array'],
	handles=>{modules_push=>'push',
		modules_all=>'elements'}
);
has _comments=>(is=>'ro',isa=>'ArrayRef',
	default=>sub{[]},
	traits=>['Array'],
	handles=>{comments_push=>'push',
		comments_all=>'elements'}
);
has _fh=>(is=>'ro',lazy=>1,builder=>"_redirectSTDOUT");

sub _redirectSTDOUT{
	my $self=shift;
	my $fh;
		if(defined $self->vcdfile){
		   open($fh, ">", $self->vcdfile) or die "unable to write to $self->vcdfile";
	   }else{
		   open($fh, ">-") or die "unable to write to STDOUT";
	   }
	   return $fh;
	}


sub writeHeaders{
my $self=shift;
my $fh=$self->_fh;
say  $fh '$date';
say $fh $self->date;
say $fh '$end
$version
   Perl VCD Writer Version '.$Verilog::VCD::Writer::VERSION.'
$end
$comment';
say $fh join("::\n",$self->comments_all);
say $fh '$end
$timescale '.$self->timescale.' $end';
$_->printScope($fh) foreach ($self->modules_all);
say $fh '$enddefinitions $end
$dumpvars
';
}


sub addModule{
	my ($self,$modulename)=@_;
	my $m=Verilog::VCD::Writer::Module->new(name=>$modulename,type=>"module");
	$self->modules_push($m);
	return $m;
}



sub setTime {
	my ($self,$time)=@_;
	my $fh=$self->_fh;
	say $fh '#'.$time;
	
}
sub _dec2bin {
    my $str = unpack("B32", pack("N", shift));
    $str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return $str;
}


sub addValue {
	my ($self,$sig,$value)=@_;
	my $fh=$self->_fh;
	#say  STDERR "Adding Values $sig $value";
	if ($sig->width == 1){
	say $fh $value.$sig->symbol;
	}else {
	say $fh  "b"._dec2bin($value)." ". $sig->symbol;
}
}


sub addComment{
	my ($self,$comment)=@_;
	$self->comments_push("   ".$comment);
}


sub flush{
	my ($self)=shift;
	my$fh=$self->_fh;
	$fh->autoflush(1);

}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Verilog::VCD::Writer - VCD waveform File creation module.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

	use Verilog::VCD::Writer;

	my $writer=Verilog::VCD::Writer->new(timescale=>'1 ns',vcdfile=>"test.vcd");
	$writer->addComment("Author:Vijayvithal");

	my $top=$writer->addModule("top"); # Create toplevel module
	my $TX=$writer->addSignal("TX",7,0); #Add Signals to top
	my $RX=$writer->addSignal("RX",7,0);

	my $dut=$top->addModule("DUT");  Create SubModule
	$dut->dupSignal($TX,"TX",7,0); #Duplicate signals from Top in submodule
	$dut->dupSignal($RX,"RX",7,0);
	
	$writer->writeHeaders(); # Output the VCD Header.
	$writer->setTime(0); # Time 0
	$writer->addValue($TX,0); # Record Transition
	$writer->addValue($RX,0);
	$writer->setTime(5); # Time 1ns
	$writer->addValue($TX,1);
	$writer->addValue($RX,0);

=head1 METHODS

=head2 addComment(comment)

Adds a comment to the VCD file header. This method should be called before writeHeaders();

=head2 flush()

Flushes the output buffer.

=head1 DESCRIPTION
This module originated out of my need to view the <Time,Voltage> CSV dump from the scope using GTKWave. 

This module provides an interface for creating a VCD (Value change Dump) file.

=head2 new (timescale=>'1ps',vcdfile=>'test.vcd',date=>DateTime->now());

The constructor takes the following options

=over 4

=item *

timescale: default is '1ps'

=item *

vcdfile: default is STDOUT, if a filename is given the VCD output will be written to it.

=item *

Date: a DateTime object, default is current date.

=back

=head2 writeHeaders()

This method should be called after all the modules and signals are declared.
This method outputs the header of the VCD file

=head2 addModule(ModuleName)

This method takes the module name as an input string and returns the corresponding Verilog::VCD::Writer::Module object.

=head2 setTime(time)

This module takes the time information as an integer value and writes it out to the VCD file.

=head2 addValue(Signal,Value)

This method takes two parameters, an Object of the type Verilog::VCD::Writer::Signal and the decimal value of the signal at the current time.
This module prints the <Signal,Value> information as a formatted line to the VCD file

=head1 AUTHOR

Vijayvithal Jahagirdar<jvs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vijayvithal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
