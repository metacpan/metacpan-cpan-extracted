package inc::Plan9MakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub {
    my ($self) = @_;

    our @DIR = qw(libutf libfmt libregexp);
    our @OBJ = map { s/\.c$/.o/; $_ }
               grep { ! /test/ }
               glob "lib*/*.c";

    return +{
        %{ super() },
        DIR           => [ @DIR ],
        INC           => join(' ', map { "-I$_" } @DIR),

        # This used to be '-shared lib*/*.o' but that doesn't work on Win32
        LDDLFLAGS     => "-shared @OBJ",
    };
};

__PACKAGE__->meta->make_immutable;
