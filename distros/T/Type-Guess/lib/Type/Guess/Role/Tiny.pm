package Type::Guess::Role::Tiny;

use Mojo::Base -role;

use Scalar::Util qw(looks_like_number);
use Type::Tiny;
use Types::Standard qw( Int Num Str );
use Mojo::Util qw/dumper/;

use Package::Stash;
# use Class::Method::Modifiers;

has "name" => sub { };
has "type_tiny" => sub { Str };

has "types" => sub { [ Int, Num, Str, ] };

# print $class_opts;

our $class_opts = { tolerance => 0, skip_empty => 1, encoding => "", types => [ Int, Num, Str, ] };

sub class_opts {
    my ($class, $opt, $val) = @_;
    die sprintf "Invalid option %s\n" unless exists $class_opts->{$opt};
    $class_opts->{$opt} = $val if defined $val;
    return $class_opts->{$opt}
}

around "new" => sub {
    my $orig = shift;
    my $self = shift;
    if (scalar @_ > 1 && !ref $_[0] && ref $_[-1]) {
	my $opts = pop @_;
	for (keys $opts->%*) {
	    $self->class_opts($_, $opts->{$_}) if $class_opts->{$_};
	}
    }
    my $ret = $orig->($self, @_);
    return $ret
};

our $types = [ Int, Num, Str, ];

sub _type {
    my $class = shift;

    my @vals =
       map { looks_like_number($_) && int($_) == $_ ? int($_) : $_ }
       map { s/(\d\.*\d*)%$/$1/r }
       @_;

    my $tot = scalar @vals;
    for ($class->class_opts("types")->@*) {
	my $tiny_type = ref $_ ? $_ : eval $_ || eval '$' . $_;
	my $ok = scalar $tiny_type->grep(@vals);
	if ($ok / $tot >= (1 - $class->tolerance)) {
	    return $tiny_type
	}
    }
}


# around "_type" => sub {
#     my $orig = shift;
#     my $class = shift;

#     return $orig->($class, @_);
# };

1;
