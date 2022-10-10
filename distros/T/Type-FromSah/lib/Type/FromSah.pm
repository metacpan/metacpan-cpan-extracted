use 5.010001;
use strict;
use warnings;

package Type::FromSah;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Data::Sah qw( gen_validator normalize_schema );
use Type::Tiny;
use Types::Standard qw( Item Optional );

use Exporter::Shiny qw( sah2type );

sub sah2type {
	state $pl = 'Data::Sah'->new->get_compiler("perl");
	
	my ( $schema, %opts ) = @_;
	$schema = normalize_schema( $schema );
	
	return 'Type::Tiny'->new(
		_data_sah  => $schema,
		parent     => ( $schema->[1]{req} ? Item : Optional[Item] ),
		constraint => sub {
			state $coderef = gen_validator( $schema, coerce => 0 );
			@_ = $_;
			goto $coderef
		},
		inlined    => sub {
			my $varname = pop;
			my $cd;
			my $handle_varname = '';
			
			if ( $varname =~ /\A\$([^\W0-9]\w*)\z/ ) {
				$cd = $pl->compile( schema => $schema, coerce => 0, data_name => "$1" );
			}
			else {
				$cd = $pl->compile( schema => $schema, coerce => 0, data_name => 'data' );
				$handle_varname = "my \$data = $varname;";
			}
			
			my $code = $cd->{result};
			my $load_modules = join '',
				map $pl->stmt_require_module($_), @{ $cd->{modules} };
			
			return "do { $handle_varname $load_modules $code }";
		},
		constraint_generator => sub {
			my @params = @_;
			my $new_schema = [ $schema->[0], { %{ $schema->[1] }, @params } ];
			my $child = sah2type( $new_schema, parameters => \@params );
			$child->check(undef); # force type checks to compile BEFORE parent
			$child->{parent} = $Type::Tiny::parameterize_type;
			return $child;
		},
		( exists($schema->[1]{default})
			? ( type_default => sub { $schema->[1]{default} } )
			: () ),
		_build_coercion => sub {
			my $coercion = shift;
			my $f = gen_validator( $schema, { return_type => 'bool_valid+val' } );
			$coercion->add_type_coercions(
				Item() => sub {
					my ( undef, $new ) = @{ $f->($_) };
					return $new;
				},
			);
			$coercion->freeze;
		},
		%opts,
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::FromSah - create an efficient Type::Tiny type constraint from a Data::Sah schema

=head1 SYNOPSIS

  package My::Types {
    use Type::Library -base;
    use Type::FromSah qw( sah2type );
    
    __PACKAGE__->add_type(
      sah2type( [ "int", min => 1, max => 10 ], name => 'SmallInt' )
    );
  }
  
  use MyTypes qw(SmallInt);
  
  SmallInt->assert_valid( 7 );

=head1 DESCRIPTION

=head2 Functions

This module exports one function.

=head3 C<< sah2type( $schema, %options ) >>

Takes a L<Data::Sah> schema (which should be an arrayref), and generates
a L<Type::Tiny> type constraint object for it. Additional key-value pairs
will be passed to the Type::Tiny constructor.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-FromSah>.

=head1 SEE ALSO

L<Data::Sah>, L<Type::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

