package Text::APL::Compiler;

use strict;
use warnings;

use base 'Text::APL::Base';

sub _BUILD {
    my $self = shift;

    $self->{namespace} ||= 'Text::APL::';
}

sub compile {
    my $self = shift;
    my ($code, $context) = @_;

    my $template_class = "$self->{namespace}";

    $template_class .= '_' . ($context->name || '__anon__') . $context->id;
    $template_class =~ s{[^A-Za-z0-9:]}{_}g;

    my $package = '';
    $package .= qq/no strict 'refs'; %{"$template_class\::"} = ();/;
    $package .= "package $template_class;";
    $package .= 'sub {';
    $package .= 'use strict; use warnings;';
    $package .= 'my $__self = $_[0];';

    $package .= $self->_generate_vars($context);

    $package .= $self->_generate_helpers($context);

    $package .= $code . '}';

    eval $package or die $@;
}

sub _generate_vars {
    my $self = shift;
    my ($context) = @_;

    my $string = '';
    foreach my $var (keys %{$context->vars}) {
        $string .= qq/my \$$var = \$__self->vars->{$var};/;
    }

    return $string;
}

sub _generate_helpers {
    my $self = shift;
    my ($context) = @_;

    my $string = '';

    $string .= "sub var; local *var = sub { \$__self->vars->{\$_[0]} };";
    foreach my $key (keys %{$context->helpers}) {
        $string .= "sub $key; local *$key = \$__self->helpers->{$key};";
    }

    return $string;
}

1;
__END__

=pod

=head1 NAME

Text::APL::Compiler - compiler

=head1 DESCRIPTION

Builds a Perl package, generates variables and helpers declarations and evals
the produced code.

=head1 METHODS

=head2 C<compile>

Compile a Perl package.

=cut
