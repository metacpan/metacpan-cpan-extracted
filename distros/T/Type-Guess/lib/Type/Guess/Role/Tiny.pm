package Type::Guess::Role::Tiny;

use Mojo::Base -role;

use Scalar::Util qw(looks_like_number);
use Type::Tiny;
use Types::Standard qw( Int Num Str );
use Mojo::Util qw/dumper/;

use Package::Stash;

has "name" => sub { };
has "type_tiny" => sub { Str };

sub _type {
    my $class = shift; 
    my $opts = pop @_ if ref $_[-1] eq "HASH";

    $opts->{types} //= [qw/Int Num Str/];
    $opts->{tolerance} //= 1;

    my @vals =
	map { looks_like_number($_) && int($_) == $_ ? int($_) : $_ }
	map { s/(\d)%$/$1/r }
	@_;

    my $tot = scalar @vals;
    for ($opts->{types}->@*) {
	my $tt = ref $_ ? $_ : eval $_ || eval '$' . $_;
	my $ok = scalar $tt->grep(@vals);
	if ($ok / $tot >= $opts->{tolerance}) {
	    return $tt
	}
    }
}

1;
