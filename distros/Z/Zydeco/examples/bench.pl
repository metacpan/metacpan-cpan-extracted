=pod

=head1 PURPOSE

Speed comparison between
MooseX::Declare,
Moops,
Zydeco, and
Dios.

 # ============================================================
 # Moose implementations
 # ============================================================
 #               Rate         MXD    Zy_Moose Moops_Moose
 # MXD         94.2/s          --        -98%        -98%
 # Zy_Moose    4525/s       4702%          --        -18%
 # Moops_Moose 5531/s       5769%         22%          --
 # 
 # ============================================================
 # Moo implementations
 # ============================================================
 #             Rate Moops_Moo    Zy_Moo
 # Moops_Moo 3169/s        --      -24%
 # Zy_Moo    4148/s       31%        --
 # 
 # ============================================================
 # Mouse implementations
 # ============================================================
 #               Rate    Zy_Mouse Moops_Mouse
 # Zy_Mouse    5966/s          --        -31%
 # Moops_Mouse 8698/s         46%          --
 # 
 # ============================================================
 # All implementations
 # ============================================================
 #               Rate    Dios   MXD Moops_Moo  Zy_Moo  Zy_Moose Moops_Moose  Zy_Mouse Moops_Mouse
 # Dios        2.19/s      --  -98%     -100%   -100%     -100%       -100%     -100%       -100%
 # MXD         94.5/s   4209%    --      -97%    -98%      -98%        -98%      -98%        -99%
 # Moops_Moo   3139/s 142960% 3220%        --    -26%      -31%        -45%      -47%        -64%
 # Zy_Moo      4225/s 192461% 4369%       35%      --       -7%        -26%      -29%        -52%
 # Zy_Moose    4567/s 208038% 4731%       45%      8%        --        -20%      -23%        -48%
 # Moops_Moose 5689/s 259136% 5917%       81%     35%       25%          --       -5%        -35%
 # Zy_Mouse    5966/s 271781% 6210%       90%     41%       31%          5%        --        -32%
 # Moops_Mouse 8727/s 397592% 9130%      178%    107%       91%         53%       46%          --

For Moose classes, Moops is the fastest, followed by Zydeco,
with MooseX::Declare trailing a long was behind.

For Moo classes, Zydeco beats Moops.

For Mouse classes, Moops beats Zydeco.

Overall, Mouse beats Moose beats Moo.

All of the above are faster than Dios.

Compile time isn't measured in this benchmark, but it's likely that Moo-based
classes will compile faster. Moops compiles a lot faster than MooseX::Declare
and Dios. Zydeco does not compile as fast as Moops, but it's not much slower.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Benchmark ':all';
use Test::More;
use Test::Fatal;
use IO::Callback;

{
	use Moops;
	class Foo::Moops_Moose using Moose {
		has n => (is => 'ro', writer => '_set_n', isa => Int, default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	class Foo::Moops_Moo using Moo {
		has n => (is => 'ro', writer => '_set_n', isa => Int, default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	class Foo::Moops_Mouse using Mouse {
		has n => (is => 'ro', writer => '_set_n', isa => Int, default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
}

{
	use MooseX::Declare;
	class Foo::MXD {
		has n => (is => 'ro', writer => '_set_n', isa => 'Int', default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
}

{
	use Dios;
	class Foo::Dios {
		has Int $.n is rw //= 0;
		method add (Int $x) {
			$self->set_n( $self->get_n + $x );
		}
		method n () {
			$self->get_n;
		}
	}
}

{
	use Zydeco;
	class ::Foo::Zy_Moose {
		toolkit Moose;
		has n (is => rwp, type => Int, default => 0);
		method add :optimize (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	class ::Foo::Zy_Mouse {
		toolkit Mouse;
		has n (is => rwp, type => Int, default => 0);
		method add :optimize (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	class ::Foo::Zy_Moo {
		toolkit Moo;
		has n (is => rwp, type => Int, default => 0);
		method add :optimize (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
	
	class ::Foo::ZyShv_Moose {
		toolkit Moose;
		has n (
			is          => rwp,
			type        => Int,
			default     => 0,
			handles_via => 'Counter',
			handles     => { add => 'inc' },
		);
	}
	class ::Foo::ZyShv_Mouse {
		toolkit Mouse;
		has n (
			is          => rwp,
			type        => Int,
			default     => 0,
			handles_via => 'Counter',
			handles     => { add => 'inc' },
		);
	}
	class ::Foo::ZyShv_Moo {
		toolkit Moo;
		has n (
			is          => rwp,
			type        => Int,
			default     => 0,
			handles_via => 'Counter',
			handles     => { add => 'inc' },
		);
	}
}

my @impl = qw(
	Moops_Moose  Moops_Mouse  Moops_Moo
	Zy_Moose    Zy_Mouse    Zy_Moo
	ZyShv_Moose ZyShv_Mouse ZyShv_Moo
	MXD
	Dios
);

# Test each class works as expected
#
for my $impl (@impl) {
	my $class = "Foo::$impl";
	like(
		exception { $class->new(n => 1.1) },
		qr{(Validation failed for 'Int')|(did not pass type constraint "Int")|(is not of type Int)|(failed type constraint)},
		"Class '$class' throws error on incorrect constructor call",
	);
	my $o = $class->new(n => 0);
	like(
		exception { $o->add(1.1) },
		qr{(^Validation failed)|(did not pass type constraint "Int")|(is not of type Int)|(failed type constraint)},
		"Objects of class '$class' throw error on incorrect method call",
	);
	$o->add(40);
	$o->add(2);
	is($o->n, 42, "Objects of class '$class' function correctly");
}

# Ensure benchmarks run with TAP-friendly output.
#
my $was = select(
	'IO::Callback'->new('>', sub {
		my $data = shift;
		$data =~ s/^/# /g;
		print STDOUT $data;
	})
);

# Prepare tests to benchmark.
#
my %speed_test = (map {
	my $class = "Foo::$_";
	$_ => sprintf(q{
		my $sum = q[%s]->new(n => 0);
		$sum->add($_) for 0..100;
	}, $class),
} @impl);

print "=" x 60, "\n";
print "Moose implementations\n";
print "=" x 60, "\n";
cmpthese(-1, { map { $_ => $speed_test{$_} } qw/ Moops_Moose Zy_Moose ZyShv_Moose MXD / });
print "\n";

print "=" x 60, "\n";
print "Moo implementations\n";
print "=" x 60, "\n";
cmpthese(-1, { map { $_ => $speed_test{$_} } qw/ Moops_Moo Zy_Moo ZyShv_Moo / });
print "\n";

print "=" x 60, "\n";
print "Mouse implementations\n";
print "=" x 60, "\n";
cmpthese(-1, { map { $_ => $speed_test{$_} } qw/ Moops_Mouse Zy_Mouse ZyShv_Mouse / });
print "\n";

print "=" x 60, "\n";
print "All implementations\n";
print "=" x 60, "\n";
cmpthese(-1, \%speed_test);
print "\n";

#use Data::Dumper;
#$Data::Dumper::Deparse = 1;
#print Dumper ({ map {
#	$_ => $_->can('add')
#} qw/ Foo::MXP Foo::Moops / });

select($was);

done_testing;
