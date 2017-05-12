package Tiffany::Template::Semantic;
use strict;
use warnings;
use Template::Semantic;

sub new {
    my ($class, $args) = @_;
    $args ||= +{};
    my $ts = Template::Semantic->new(%$args);
    bless {
        ts => $ts,
    }, $class;
}

sub render {
    my ($self, $stuff, @args) = @_;
    $self->{ts}->process( $stuff, @args);
}

1;
__END__

=head1 NAME

Tiffany::Template::Semantic - Tiffany gateway for Template::Semantic

=head1 SYNOPSIS

    use Tiffany;

    my $tmpl = Tiffany->load('Template::Semantic');
    is $tmpl->render(\q{<html xmlns="http://www.w3.org/1999/xhtml">Hello, <div id="name">ben</div>.</html>}, {'#name' => 'john'}), qq{<html xmlns="http://www.w3.org/1999/xhtml">Hello, <div id="name">john</div>.</html>\n};

=head1 AUTHOR

Tokuhiro Matsuno

