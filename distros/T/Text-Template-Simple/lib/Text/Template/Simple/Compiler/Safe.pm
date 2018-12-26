package Text::Template::Simple::Compiler::Safe;
$Text::Template::Simple::Compiler::Safe::VERSION = '0.91';
# Safe compiler. Totally experimental
use strict;
use warnings;

use Text::Template::Simple::Dummy;

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

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Compiler::Safe

=head1 VERSION

version 0.91

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Safe template compiler.

=head1 NAME

Text::Template::Simple::Compiler::Safe - Safe compiler

=head1 METHODS

=head2 compile STRING

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
