package X86::Udis86;

use 5.008000;
use strict;
use warnings;
use Carp;

use X86::Udis86::Operand ':all';

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our $VERSION = '1.7.2.3';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&X86::Udis86::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('X86::Udis86', $VERSION);

sub DESTROY {
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

X86::Udis86 - Perl extension for the C disassembler Udis86.

=head1 SYNOPSIS

  use X86::Udis86;

=head1 DESCRIPTION

This module provides a Perl interface to the C disassembler Udis86.
See http://udis86.sourceforge.net/

The test program in t/X86-Udis86.t provides some indication of usage. 

The file udis86.pdf distributed with the C library documents the 
interface which has been followed in the Perl wrapper.

If you would like more extensive documentation, write to me and ask!

Currently the set_input_hook function is not provided here.

=head2 EXPORT

None by default. Exports @mnemonics on request.

=head1 AUTHOR

Bob Wilkinson, E<lt>bob@fourtheye.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2013 by Bob Wilkinson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
