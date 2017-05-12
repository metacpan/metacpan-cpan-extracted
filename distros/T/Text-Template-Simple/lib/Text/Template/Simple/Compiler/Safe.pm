package Text::Template::Simple::Compiler::Safe;
# Safe compiler. Totally experimental
use strict;
use warnings;

use Text::Template::Simple::Dummy;

our $VERSION = '0.90';

sub compile {
   shift;
   return __PACKAGE__->_object->reval(shift);
}

sub _object {
   my $class = shift;
   if ( $class->can('object') ) {
      my $safe = $class->object;
      if ( $safe && ref $safe ) {
         return $safe if eval { $safe->isa('Safe'); 'Safe-is-OK' };
      }
      my $end = $@ ? q{: }.$@ : q{.};
      warn 'Safe object failed. Falling back to default' . $end . "\n";
   }
   require Safe;
   my $safe = Safe->new('Text::Template::Simple::Dummy');
   $safe->permit( $class->_permit );
   return $safe;
}

sub _permit {
   my $class = shift;
   return $class->permit if $class->can('permit');
   return qw( :default require caller );
}

1;

__END__

=head1 NAME

Text::Template::Simple::Compiler::Safe - Safe compiler

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

This document describes version C<0.90> of C<Text::Template::Simple::Compiler::Safe>
released on C<5 July 2016>.

Safe template compiler.

=head1 METHODS

=head2 compile STRING

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2016 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
