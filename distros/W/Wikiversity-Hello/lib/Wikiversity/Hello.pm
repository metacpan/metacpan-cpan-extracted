package Wikiversity::Hello;
# Wikiversity::Hello - introductory module in Wikiversity Perl training
#
# Copyright (C) 2007 by Ian Kluft  http://ian.kluft.com/
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.8 or,
# at your option, any later version of Perl 5 you may have available.

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# export controls
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( go );

# version number used by module-building modules
our $VERSION = '0.01';

# congratulate the user for successfully installing and running the module
sub hurrah
{
	print "Congratulations!  You have successfully installed and ran "
		.__PACKAGE__."!\n";
};

1;
__END__

=head1 NAME

Wikiversity::Hello - introductory module in Wikiversity Perl training

=head1 SYNOPSIS

  perl -MWikiversity::Hello -e hurrah

=head1 DESCRIPTION

Wikiversity::Hello is an introductory module for readers following the
tutorial about loading a CPAN module at
   http://en.wikiversity.org/wiki/Perl_Modules_on_CPAN

Installation of this module is the exercise at the end of that lesson.
The module simply provides a function which congratulates the user for
successfully installing and running it.

=head1 PERL LESSONS AT WIKIVERSITY

Wikiversity is an online educational site of the Wikimedia Foundation,
the same organization as Wikipedia.  This module is part of the Perl
training at Wikiversity.  http://en.wikiversity.org/wiki/Topic:Perl

If you conduct Perl training, you may use this in your curriculum.
And of course you knew this part was coming - please also help make
the training better by adding your experience to it.

=head1 SEE ALSO

http://en.wikiversity.org/wiki/Perl_Modules_on_CPAN

http://en.wikiversity.org/wiki/Topic:Perl

=head1 AUTHOR

Ian Kluft, E<lt>ik-cpan@thunder.sbay.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ian Kluft  http://ian.kluft.com/

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
