package 
    t::TT2LikeTest;
use Exporter 'import';
use Test::More ();
use Text::Xslate;
use Text::Xslate::Bridge::TT2Like;

our @EXPORT_OK = qw(render_xslate render_ok);

our $XSLATE = Text::Xslate->new(
    syntax   => 'TTerse',
    module   => [ 'Text::Xslate::Bridge::TT2Like' ],
);

sub render_xslate {
    my ($template, $args) = @_;
    $args ||= {
        foo => "foo",
        foobar => "foo bar",
        strings => [ "abc", "def", "ghi", "jkl" ],
        numbers => [ 1, 2, 3, 4, 5 ],
        hashmap => {
            abc => "def",
            ghi => "jkl",
            list => [
                { list_foo1 => "list_bar1" },
                { list_foo2 => "list_bar2" }
            ]
        }
    };
    $XSLATE->render_string( $template, $args ),
}

sub render_ok {
    my ($template, $args, $expect, $name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $ref = ref $expect;
    if (! $ref ) {
        $func = \&Test::More::is;
    } elsif ( $ref =~ /^Reg[Ee]xp$/ ) {
        $func = \&Test::More::like;
    } else {
        die "Don't know how to handle expect type $ref";
    }

    $func->(
        render_xslate( $template, $args ),
        $expect,
        $name
    );
}

1;