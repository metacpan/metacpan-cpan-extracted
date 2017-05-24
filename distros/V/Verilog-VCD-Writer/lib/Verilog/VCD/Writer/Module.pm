package Verilog::VCD::Writer::Module;
$Verilog::VCD::Writer::Module::VERSION = '0.002';
use strict;
use warnings;
use DateTime;

# ABSTRACT: Module abstraction layer for Verilog::VCD::Writer

use Verilog::VCD::Writer::Signal;
use  v5.10;
use Moose;
use namespace::clean;

has name => (is=>'ro');
has type => (is=>'ro',default=>'module');
has signals=>(is=>'rw',isa=>'ArrayRef[Verilog::VCD::Writer::Signal]',
	default=>sub{[]},
	traits=>['Array'],
	handles=>{signals_push=>'push',
		signals_all=>'elements'}
);
has modules=>(is=>'rw',isa=>'ArrayRef[Verilog::VCD::Writer::Module]',
	default=>sub{[]},
	traits=>['Array'],
	handles=>{modules_push=>'push',
		modules_all=>'elements'}
);
#has modules=>(is=>'rw',isa=>'ArrayRef');

#my @signals;
#my $modules;


sub addSignal {
	my ($self,$name,$bitmax,$bitmin)=@_;
	my $s=Verilog::VCD::Writer::Signal->new(
		name=>$name,
		bitmax=>$bitmax,
		bitmin=>$bitmin
	);
	$self->signals_push($s);
	return $s;
}

sub dupSignal {
	my ($self,$signal,$name,$bitmax,$bitmin)=@_;
	my $s=Verilog::VCD::Writer::Signal->new(
		name=>$name,
		bitmax=>$bitmax,
		bitmin=>$bitmin,
		symbol=>$signal->symbol
	);
	$self->signals_push($s);
	#push @signals,$s;
	return $s;
}

sub addSubModule {
	my ($self,$name,$type)=@_;
	my $m=Verilog::VCD::Writer::Module->new(
		name=>$name,
		type=>$type # Module,Function,Task etc.
	);
	$self->modules_push($m);
	return $m;
}


sub printScope {
	my ($self,$fh)=@_;
	say $fh '$scope '.$self->type.' '.$self->name.' $end';
	map{$_->printScope($fh)}  $self->signals_all;
	map{$_->printScope($fh)}  $self->modules_all;
	say $fh '$upscope $end';
}


1

__END__

=pod

=encoding UTF-8

=head1 NAME

Verilog::VCD::Writer::Module - Module abstraction layer for Verilog::VCD::Writer

=head1 VERSION

version 0.002

=head2 addSignal(name,bitmax,bitmin)

This method takes 3 parameters and returns a newly created Verilog::VCD::Writer::Signal Object.

Parameters are

name: Module name. Required.
bitmax: The upper index of the bitrange e.g. for byte[7:0] bitmax is 7
bitmin: The lower index of the bitrange e.g. for byte[7:0] bitmin is 0

bitmax and bitmin are not required for a single bit signal.

=head2 dupSignal (Signal,...)

Adds a signal to the current module which is an exact duplicate of a signal elsewhere.

The first parameter is a Verilog::VCD::Writer::Signal object, the rest are the same as the addSignal method.

=head2 addSubModule(name,type)

Adds a submodule/function/task etc under the current module.

This method takes two parameter

name: Name of the module that will be added

type: a string which is either module,function or task

returns a newly created object of the type Verilog::VCD::Writer::Module

=for Pod::Coverage printScope

=head1 AUTHOR

Vijayvithal Jahagirdar<jvs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vijayvithal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
