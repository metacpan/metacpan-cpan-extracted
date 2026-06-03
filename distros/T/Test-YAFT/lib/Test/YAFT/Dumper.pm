
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT::Dumper v1.0.3 {
	use parent q (Data::Dumper);

	use Ref::Util;

	use mro;

	my %ref_map;
	my %builder_map;

	sub new {
		my ($class, @args) = @_;

		my $self = $class->next::method (@args);

		$self->{useperl} = 1;

		return $self;
	}

	sub _dump {
		my ($self, $value, $name) = @_;

		if (my $refaddr = Scalar::Util::refaddr ($value)) {
			return $self->_dump_builder ($value, $builder_map{$refaddr})
				if defined $ref_map{$refaddr}
				;
		}

		return $value->$_ ($self, $name)
			if local $_ = $value->$Safe::Isa::_can (q (__dump_yaft))
			;

		my $result = $self->next::method ($value, $name);

		# qr/(?^u:foo)/ => qr/foo/u
		$result =~ s ( ^ ( qr/) [(] [?] [\^] ([a-z]+) [:] (.*) [)] (/) ) ($1$3$4$2)x
			if $] < 5.020
			;


		return $result;
	}

	sub _dump_builder {
		my ($self, $value, $data) = @_;

		my $builder = $data->{builder};
		my $args    = $data->{args} // [];
		my $indent  = $self->_indent;

		return qq ($builder ())
			unless @$args
			;

		$self->{level} ++;

		my @args = map { $self->_indent . $self->_dump ($_, q ()) . q (,) } @$args;

		$self->{level} --;

		return join qq (\n) => (
			qq [$builder (],
			@args,
			qq [$indent)]
		);
	}

	sub _indent {
		my ($self) = @_;

		return $self->{xpad} x $self->{level};
	}

	sub Dumper {
		__PACKAGE__->Dump ([@_]);
	}

	sub register_ref_builder {
		my ($class, $ref, $builder, @args) = @_;

		return
			unless my $refaddr = Scalar::Util::refaddr ($ref)
			;

		$builder_map{$refaddr} = {
			builder => $builder,
			args    => \ @args,
		};

		$ref_map{$refaddr} = $ref;
		Scalar::Util::weaken ($ref);

		();
	}

	1;
};
