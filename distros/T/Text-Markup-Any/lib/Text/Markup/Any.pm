package Text::Markup::Any;
use strict;
use warnings;
use utf8;
our $VERSION = '0.04';

use parent 'Exporter';
use Class::Load qw/load_class/;

our @EXPORT = qw/markupper/;

my $markdown = {markup_method   => 'markdown'};
our %MODULES = (
    'Text::Markdown'            => $markdown,
    'Text::MultiMarkdown'       => $markdown,
    'Text::Markdown::Discount'  => $markdown,
    'Text::Markdown::GitHubAPI' => $markdown,
    'Text::Markdown::Hoedown' => {
        class         => 'Text::Markdown::Hoedown::Markdown',
        markup_method => 'render',
        args          => sub { [0, 16, Text::Markdown::Hoedown::Renderer::HTML->new(0, 99)] },
        deref         => 1,
    },
    'Text::Xatena'              => {markup_method => 'format'},
    'Text::Textile'             => {markup_method => 'process'},
);

sub new {
    my ($pkg, $class, @args) = @_;

    my $args;
    if (@args) {
        $args = ref $args[0] ? $args[0] : {@args};
    }

    my $info = $MODULES{$class}
        or die "no configuration found: $class. You want to use $class, directory call $pkg->adaptor constractor.";

    if ($args) {
        if ($info->{args} && ref($info->{args}) eq 'HASH') {
            $info->{args} = {
                %{ $info->{args} },
                %$args,
            };
        }
        else {
            $info->{args} = $args;
        }
    }

    load_class($class) if $info->{class};
    $pkg->adaptor(
        class   => $class,
        %$info,
    );
}

# taken from Ark::Models
sub adaptor {
    my ($pkg, %info) = @_;

    my $class         = $info{class} or die q{Required class parameter};
    my $markup_method = $info{markup_method} or die q{Required markup_method parameter};
    my $constructor   = $info{constructor} || 'new';

    load_class($class);
    $info{args} = $info{args}->() if ref $info{args} eq 'CODE';

    my $instance;
    if ($info{deref} and my $args = $info{args}) {
        if (ref($args) eq 'HASH') {
            $instance = $class->$constructor(%$args);
        }
        elsif (ref($args) eq 'ARRAY') {
            $instance = $class->$constructor(@$args);
        }
        else {
            die qq{Couldn't dereference: $args};
        }
    }
    elsif ($info{args}) {
        $instance = $class->$constructor($info{args});
    }
    else {
        $instance = $class->$constructor;
    }

    bless {
        _instance      => $instance,
        _markup_method => $markup_method,
    }, $pkg;
}

sub markup {
    my ($self, @text) = @_;

    my $meth = $self->{_markup_method};
    $self->{_instance}->$meth(@text);
}

sub markupper {
    my $class = shift;
    $class = "Text::$class" unless $class =~ /^\+/;

    __PACKAGE__->new($class, @_);
}


1;
__END__

=head1 NAME

Text::Markup::Any - Common Lightweight Markup Language Interface

=head1 SYNOPSIS

  use Text::Markup::Any;

  # OO Interface
  my $md = Text::Markup::Any->new('Text::Markdown');
  my $html = $md->markup('# hoge'); # <h1>hoge</h1>

  # Functional Interface
  my $tx = markupper 'Textile'; # snip 'Text::' in functional inteface.
  my $html = $tx->markup('h1. hoge'); # <h1>hoge</h1>

=head1 DESCRIPTION

Text::Markup::Any is Common Lightweight Markup Language Interface.
Currently supported modules are L<Text::Markdown>, L<Text::MultiMarkdown>,
L<Text::Markdown::Discount>, L<Text::Markdown::GitHubAPI>,
L<Text::Markdown::Hoedown>, L<Text::Xatena> and L<Text::Textile>.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
