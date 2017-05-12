package Tiffany::Text::ClearSilver;
use strict;
use warnings;
use Text::ClearSilver;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};

    my $cs = Text::ClearSilver->new($args);
    bless {
        cs => $cs,
    }, $class;
}

sub render {
    my ($self, $stuff, $vars, @extra) = @_;

    my $out;
    $self->{cs}->process($stuff, $vars, \$out, @extra);
    return $out;
}

1;
__END__

=head1 NAME

Tiffany::Text::ClearSilver - Tiffany gateway for Text::ClearSilver

=head1 SYNOPSIS

    use Tiffany;

    my $tiffany = Tiffany->load('Text::ClearSilver', {load_path => ['/path/to/template']});
    my $output = $tiffany->render(\q{hello, <?cs var:user_name ?>.}, {user_name => 'john'});
    my $expected = "hello, john.";

    is $output, $expected;

=head1 SEE ALSO

L<Text::ClearSilver>

L<Tiffany>

=head1 AUTHOR

Fuji, Goro (gfx)

=cut

