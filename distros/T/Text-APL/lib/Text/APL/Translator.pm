package Text::APL::Translator;

use strict;
use warnings;

use base 'Text::APL::Base';

sub translate {
    my $self = shift;
    my ($tape) = @_;

    my $code = '';

    foreach my $token (@$tape) {
        if ($token->{type} eq 'expr') {
            my $value = $token->{value};
            if (exists $token->{as_is} && $token->{as_is}) {
                $code .= '__print(do {' . $value . '});';
            }
            else {
                $code .= '__print_escaped(do {' . $value . '});';
            }
        }
        elsif ($token->{type} eq 'exec') {
            $code .= $token->{value};
            $code .= ';' unless $token->{line};
            $code .= "\n";
        }
        else {
            $token->{value} =~ s/}/\\}/gms;
            $token->{value} =~ s/{/\\{/gms;
            $code .= '__print(q{' . $token->{value} . '});';
        }
    }

    $code;
}

1;
__END__

=pod

=head1 NAME

Text::APL::Translator - translator

=head1 DESCRIPTION

Translates token tree produced by L<Text::APL::Parser> into Perl code.
Introduces special C<__print> and C<__print_escaped> functions.

=head1 METHODS

=head2 C<translate>

Translates token tree into Perl code.

=cut
