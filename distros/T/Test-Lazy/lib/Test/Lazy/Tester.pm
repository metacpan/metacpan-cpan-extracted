package Test::Lazy::Tester;

use warnings;
use strict;

=head1 NAME

Test::Lazy::Tester

=head1 SYNOPSIS

	use Test::Lazy::Tester;

    $tester = Test::Lazy::Tester->new;

    # Will evaluate the code and check it:
	$tester->try('qw/a/' => eq => 'a');
	$tester->try('qw/a/' => ne => 'b');
	$tester->try('qw/a/' => is => ['a']);

    # Don't evaluate, but still compare:
	$tester->check(1 => is => 1);
	$tester->check(0 => isnt => 1);
	$tester->check(a => like => qr/[a-zA-Z]/);
	$tester->check(0 => unlike => qr/a-zA-Z]/);
	$tester->check(1 => '>' => 0);
	$tester->check(0 => '<' => 1);

    # A failure example:

	$tester->check([qw/a b/] => is => [qw/a b c/]);

    # Failed test '['a','b'] is ['a','b','c']'
    # Compared array length of $data
    #    got : array with 2 element(s)
    # expect : array with 3 element(s)


    # Custom test explanation:

	$tester->try('2 + 2' => '==' => 5, "Math is hard: %?");

    # Failed test 'Math is hard: 2 + 2 == 5'
    #      got: 4
    # expected: 5

=head1 DESCRIPTION

See L<Test::Lazy> for more information.

=head1 METHODS

=head2 Test::Lazy::Tester->new( cmp_scalar => ?, cmp_structure => ?, render => ? )

Create a new Test::Lazy::Tester object, optionally amending the scalar comparison, structure comparison, and render subroutines
using the supplied hashes.

For now, more information on customization can be gotten by:

    perldoc -m Test::Lazy::Tester

=head2 $tester->check( <got>, <compare>, <expect>, [ <notice> ] )

See L<Test::Lazy::check> for details.

=head2 $tester->try( <got>, <compare>, <expect>, [ <notice> ] )

See L<Test::Lazy::try> for details.

=head2 $tester->template()

Creates a C<Test::Lazy::Template> using $tester as the basis.

See L<Test::Lazy::Template> for more details.

Returns a new L<Test::Lazy::Template> object.

=head2 $tester->render_value( <value> )

Render a gotten or expected value to a form suitable for the test notice/explanation.

This method will consult the $tester->render hash to see what if should do based on 'ref <value>'.
By default, ARRAY and HASH are handled by Data::Dumper using the following:

        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Varname = 0;
        local $Data::Dumper::Terse = 1;

An undef value is a special case, handled by the $tester->render->{undef} subroutine.
By default, the subroutine returns the string "undef"

=head2 $tester->render_notice( <left>, <compare>, <right>, <notice> )

Render the text explantaion message. You don't need to mess with this.

=cut

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/render cmp_scalar cmp_structure/);

use Data::Dumper qw/Dumper/;
use Carp;
use Test::Deep;
use Test::Builder();

my $deparser;
eval {
    require B::Deparse;
    $deparser = B::Deparse->new;
    $deparser->ambient_pragmas(strict => 'all', warnings => 'all');
};
undef $deparser if $@;

my %base_cmp_scalar = (
	ok => sub {
        Test::More::ok($_[0], $_[2])
    },

	not_ok => sub {
        Test::More::ok(! $_[0], $_[2])
    },

	(map { my $mtd = $_; $_ => sub {
        Test::More::cmp_ok($_[0] => $mtd => $_[1], $_[2])
    } }
	qw/< > <= >= lt gt le ge == != eq ne/),

	(map { my $method = $_; $_ => sub {
        no strict 'refs';
       "Test::More::$method"->($_[0], $_[1], $_[2])
    } }
	qw/is isnt like unlike/),
);

my %base_cmp_structure = (
	ok => sub {
        Test::More::ok($_[0], $_[2])
    },

	not_ok => sub {
        Test::More::ok(! $_[0], $_[2])
    },

    (map { $_ => sub {
        Test::Deep::cmp_bag($_[0], $_[1], $_[2]);
    } }
    qw/bag same_bag samebag/),

    (map { $_ => sub {
        Test::Deep::cmp_set($_[0], $_[1], $_[2]);
    } }
    qw/set same_set sameset/),

    (map { $_ => sub {
        Test::Deep::cmp_deeply($_[0], $_[1], $_[2]);
    } }
    qw/same is like eq ==/),

	(map { $_ => sub {
        Test::More::ok(!Test::Deep::eq_deeply($_[0], $_[1]), $_[2]);
    } }
    qw/isnt unlink ne !=/),
);

my %base_render = (
    ARRAY => sub {
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Varname = 0;
        local $Data::Dumper::Terse = 1;
        my $self = shift;
        my $value = shift;
        return Dumper($value);
    },

    HASH => sub {
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Varname = 0;
        local $Data::Dumper::Terse = 1;
        my $self = shift;
        my $value = shift;
        return Dumper($value);
    },

    undef => sub {
        return "undef";
    },
);

sub new {
    my $self = bless {}, shift;
    local %_ = @_;
    $self->{cmp_scalar} = { %base_cmp_scalar, %{ $_{cmp_scalar} || {} } };
    $self->{cmp_structure} = { %base_cmp_structure, %{ $_{cmp_structure} || {} } };
    $self->{render} = { %base_render, %{ $_{base_render} || {} } };
    return $self;
}

sub render_notice {
    my $self = shift;
    my ($left, $compare, $right, $notice, $length) = @_;

	# my $_notice = $length == 4 ? "$left $compare $right" : "$left $compare";
	my $_notice = "$left $compare $right";
	if (defined $notice) {
        if ($notice =~ m/%\?/) {
		    $notice =~ s/%\?/$_notice/g;
        }
        else { # Old version, deprecated.
		    $notice =~ s/%(?!%)/%?/g;
		    $notice =~ s/%%/%/g;
		    $notice =~ s/%\?/$_notice/g;
        }
	}
	else {
		$notice = $_notice;
	}

    return $notice;
}

sub render_value {
    my $self = shift;
	my $value = shift;

    my $type = ref $value;
    $type = "undef" unless defined $value;

    return $value unless $type;
    return $value unless my $renderer = $self->render->{$type};
    return $renderer->($self, $value);
}

sub _test {
    my $self = shift;
	my ($compare, $got, $expect, $notice) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $cmp = $compare;
	if (ref $cmp eq "CODE") {
		Test::More::ok($cmp->($got, $expect), $notice);
	}
	else {
        my $structure = ref $expect eq "ARRAY" || ref $expect eq "HASH";
        my $scalar = ! $structure;

        my $cmp_source = $scalar ? $self->cmp_scalar : $self->cmp_structure;

		die "Don't know how to compare via ($compare)" unless $cmp = $cmp_source->{$cmp};
        local $Test::Builder::Level = $Test::Builder::Level + 1;
		$cmp->($got, $expect, $notice);
	}
}

sub check {
    my $self = shift;
	my ($got, $compare, $expect, $notice) = @_;
    my $length = @_;

	my $left = $self->render_value($got);
	my $right = $self->render_value($expect);
    $notice = $self->render_notice($left, $compare, $right, $notice, $length);

    local $Test::Builder::Level = $Test::Builder::Level + 1;

	return $self->_test($compare, $got, $expect, $notice);
}

sub try {
    my $self = shift;
	my ($statement, $compare, $expect, $notice) = @_;
    my $length = @_;

	my @got = ref $statement eq "CODE" ? $statement->() : eval $statement;
	die "$statement: $@" if $@;
	my $got;
	if (@got > 1) {
		if (ref $expect eq "ARRAY") {
			$got = \@got;
		}
		elsif (ref $expect eq "HASH") {
			$got = { @got };
		}
		else {
			$got = scalar @got;
		}
	}
	else {
		if (ref $expect eq "ARRAY" && (! @got || ref $got[0] ne "ARRAY")) {
			$got = \@got;
		}
		elsif (ref $expect eq "HASH" && ! @got) {
			$got = { };
		}
		else {
			$got = $got[0];
		}
	}
	
    my $left;
	if (ref $statement eq "CODE" && $deparser) {
		my $deparse = $deparser->coderef2text($statement);
		my @deparse = split m/\n\s*/, $deparse;
		$deparse = join ' ', "sub", @deparse if 3 == @deparse;
		$left = $deparse;
	}
	else {
		$left = $statement;
	}
	my $right = $self->render_value($expect);
    $notice = $self->render_notice($left, $compare, $right, $notice, $length);

    local $Test::Builder::Level = $Test::Builder::Level + 1;

	return $self->_test($compare, $got, $expect, $notice);
}

sub template {
    my $self = shift;
    require Test::Lazy::Template;
	return Test::Lazy::Template->new($self, @_);
}

1;
