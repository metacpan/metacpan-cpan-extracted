package inc::UninumMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub { +{
    %{ super() },
    XS      => {
        "lib/Unicode/Number.xs" => "lib/Unicode/Number.c",
    }
} };

override _build_WriteMakefile_dump => sub {
	my $str = super();
	$str .= <<'END';
$WriteMakefileArgs{CONFIGURE} = sub {
	require Alien::Uninum;
	my $u = Alien::Uninum->new;
	+{ CCFLAGS => $u->cflags, LIBS => $u->libs };
};
END
	$str;
};

__PACKAGE__->meta->make_immutable;
