package Verilog::VCD::Writer::Symbol;
$Verilog::VCD::Writer::Symbol::VERSION = '0.004';
# ABSTRACT: Signal name to symbol mapper. Private class nothing to see here.
use Math::BaseCalc;

use MooseX::Singleton;
 




has count => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);
sub symbol{
	my $self=shift;
	my $conv=new Math::BaseCalc(digits=> [
        '!','"','#','$','%','&',"'",'(',')',
        '*','+',',','-','.','/',
        '0','1','2','3','4','5','6','7','8','9',
        ':',';','<','=','>','?','@',
        'A','B','C','D','E','F','G','H','I','J','K','L','M',
        'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
        '[','\\',']','^','_','`',
        'a','b','c','d','e','f','g','h','i','j','k','l','m',
        'n','o','p','q','r','s','t','u','v','w','x','y','z',
        '{','|','}','~']);
my $rval= $conv->to_base($self->count);
$self->count($self->count+1);
return $rval;
}
1

__END__

=pod

=encoding UTF-8

=head1 NAME

Verilog::VCD::Writer::Symbol - Signal name to symbol mapper. Private class nothing to see here.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Verilog::VCD::Writer::Symbol;

  This is a Singleton class to map the signal name to a compact symbol

=for Pod::Coverage *EVERYTHING*

=head1 AUTHOR

Vijayvithal Jahagirdar<jvs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vijayvithal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
