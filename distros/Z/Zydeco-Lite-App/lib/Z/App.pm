use strict;
use warnings;

package Z::App;
use parent 'Z';

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use IO::Handle ();

sub modules {
	my @modules = shift->SUPER::modules( @_ );
	for my $mod ( @modules ) {
		next unless $mod->[0] eq 'Zydeco::Lite';
		$mod->[0] .= '::App';
		$mod->[1] = '0';
	}
	return @modules;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Z::App - load Zydeco::Lite::App, strict, warnings, Types::Standard, etc 

=head1 SYNOPSIS

In C<< consumer.pl >>:

  #! perl
  
  use Z::App;
  
  app 'MyApp' => sub {
    
    command 'Eat' => sub {
      
      constant documentation => 'Consume some food.';
      
      arg 'foods' => (
        type          => ArrayRef[Str],
        documentation => 'A list of foods.',
      );
      
      run {
        my ( $self, $foods ) = ( shift, @_ );
        $self->info( "Eating $_." ) for @$foods;
        return 0;
      };
    };
    
    command 'Drink' => sub {
      
      constant documentation => 'Consume some drinks.';
      
      arg 'drinks' => (
        type          => ArrayRef[Str],
        documentation => 'A list of drinks.',
      );
      
      run {
        my ( $self, $drinks ) = ( shift, @_ );
        $self->info( "Drinking $_." ) for @$drinks;
        return 0;
      };
    };
  };
  
  'MyApp'->execute( @ARGV );

At the command line:

  $ ./consumer.pl help eat
  usage: consumer.pl eat [<foods>...]
  
  Consume some food.
  
  Flags:
    --help  Show context-sensitive help.
  
  Args:
    [<foods>]  A list of foods.

  $ ./consumer.pl eat pizza chocolate
  Eating pizza.
  Eating chocolate.

=head1 DESCRIPTION

Z::App is like L<Z> but loads L<Zydeco::Lite::App> instead of L<Zydeco::Lite>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Zydeco-Lite-App>.

=head1 SEE ALSO

L<Z>, L<Zydeco::Lite::App>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

