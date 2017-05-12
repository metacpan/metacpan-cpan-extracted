package Tiffany::HTML::Template::Pro;
use strict;
use warnings;
use HTML::Template::Pro;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};
    bless {%$args}, $class;
}

sub render {
    my ($self, $stuff, $args) = @_;

    my $type = ref $stuff ? 'scalarref' : 'filename';
    my $ht = HTML::Template::Pro->new($type => $stuff, %$self);
    $ht->param(%$args);
    my $output = $ht->output();
    return $output;
}

1;
__END__

=head1 NAME

Tiffany::HTML::Template::Pro - Tiffany gateway for HTML::Templat::Proe

=head1 SYNOPSIS

    use Tiffany;

    my $tmpl = Tiffany->load('HTML::Template::Pro');
    is $tmpl->render(\q{Hello, <TMPL_VAR NAME="name">.}, {name => 'john'}), "Hello, john.";

=head1 AUTHOR

Tokuhiro Matsuno

