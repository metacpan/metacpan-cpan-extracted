package Verilog::VCD::Writer::Signal;
$Verilog::VCD::Writer::Signal::VERSION = '0.004';
use strict;
use warnings;
use DateTime;

# ABSTRACT: Signal abstraction layer for Verilog::VCD::Writer
use Verilog::VCD::Writer::Symbol;
use  v5.10;
use Moose;
use namespace::clean;
has name=>(is=>'ro',required=>1);
has type=>(is=>'ro',default=>'wire');
has bitmax=>(is=>'ro');
has bitmin=>(is=>'ro');
has width=>(is=>'ro',lazy=>1,builder=>"_getWidth");
has symbol=>(is=>'ro',builder=>"_getSymbol");




sub _getSymbol{
my $symTable=Verilog::VCD::Writer::Symbol->instance();
return $symTable->symbol;
}
sub _getWidth{
	my $self=shift;
	return 1 if (not defined $self->bitmax or not defined $self->bitmin);
	return 1+$self->bitmax-$self->bitmin if($self->bitmax>$self->bitmin);
	return 1+$self->bitmin - $self->bitmax;
}


sub printScope {
	my ($self,$fh)=@_;
	my $bus='';
	$bus="[$self->{bitmax}:$self->{bitmin}]" if(defined $self->bitmax and defined $self->bitmin);
 say $fh join(' ',('$var ', $self->{type},$self->width,$self->{symbol},$self->{name},$bus,'$end')) ;
}

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Verilog::VCD::Writer::Signal - Signal abstraction layer for Verilog::VCD::Writer

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Verilog::VCD::Writer;
  use Verilog::VCD::Writer::Signal;

  # my $signal=Verilog::VCD::Signal(
  # name=>'signalName',
  # type=> 'wire'
  # bitmax=>7,
  # bitmin=>0)

=head1 DESCRIPTION

This module is designed to be called from the Verilog::VCD::Writer::Module module.

=head1 INTERFACE

=head1 DEPENDENCIES

=head1 SEE ALSO

=for Pod::Coverage *EVERYTHING*

=head1 AUTHOR

Vijayvithal Jahagirdar<jvs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vijayvithal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
