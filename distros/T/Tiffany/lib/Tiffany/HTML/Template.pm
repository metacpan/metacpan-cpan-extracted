package Tiffany::HTML::Template;
use strict;
use warnings;
use HTML::Template;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};
    bless {%$args}, $class;
}

sub render {
    my ($self, $stuff, $args) = @_;

    my $type = ref $stuff ? 'scalarref' : 'filename';
    my $ht = HTML::Template->new($type => $stuff, %$self);
    $ht->param($args);
    return $ht->output();
}

1;
__END__

=head1 NAME

Tiffany::HTML::Template - Tiffany gateway for HTML::Template

=head1 SYNOPSIS

    use Tiffany;

    my $tmpl = Tiffany->load('HTML::Template');
    is $tmpl->render(\q{Hello, <TMPL_VAR NAME="name">.}, {name => 'john'}), "Hello, john.";

=head1 AUTHOR

Tokuhiro Matsuno

