package Test::FIT::Cell;
$VERSION = '0.10';
use strict;

sub new {
    my ($class, $array, $index1, $index2) = @_;
    $index2  = $index1 + 1 unless defined $index2;
    my $self = bless [], $class;
    $self->format_ref(\ $array->[$index1]);
    $self->text_ref(\ $array->[$index2]);
    return $self;
}

sub format {
    my $self = shift;
    return ${$self->[0]} unless @_;
    ${$self->[0]} = shift;
}

sub format_ref {
    my $self = shift;
    return $self->[0] unless @_;
    $self->[0] = shift;
}

sub text {
    my $self = shift;
    return ${$self->[1]} unless @_;
    ${$self->[1]} = shift;
}

sub text_ref {
    my $self = shift;
    return $self->[1] unless @_;
    $self->[1] = shift;
}

sub method {
    my $self = shift;
    my $method = $self->text;
    $method = $1 if $method =~ /(\w+)/;
    return $method;
}

sub class {
    my $self = shift;
    my $class = $self->text;
    $class = $1 if $class =~ /([\w.:-]+)/;
    return $class;
}

sub clean_value {
    my $self = shift;
    my $value = $self->text;
    if ($value =~ m!<pre>(.*)</pre>!is) {
        $value = $1;
        $value =~ s!<br>!\n!ig;
    }
    $value =~ s/^\s*(.*?)\s*$/$1/;
    $value =~ s!<.*?>!!sg;
    $value =~ s/\&lt;/</ig;
    $value =~ s/\&gt;/>/ig;
    return $value;
}

sub mark_passed {
    my $self = shift;
    my $format_ref = $self->format_ref;
    $$format_ref =~ s/bgcolor=[^\s>]*//;
#     $$format_ref =~ s/>/ bgcolor="#cfffcf">/;
    $$format_ref =~ s/>/ bgcolor="#80ff80">/;
    return unless @_;
    $self->text(shift);
}

sub mark_failed {
    my $self = shift;
    my $format_ref = $self->format_ref;
    $$format_ref =~ s/bgcolor=[^\s>]*//;
#     $$format_ref =~ s/>/ bgcolor="#ffcfcf">/;
    $$format_ref =~ s/>/ bgcolor="#ff8080">/;
    return unless @_;
    $self->text(shift);
}

sub mark_error {
    my $self = shift;
    my $format_ref = $self->format_ref;
    $$format_ref =~ s/bgcolor=[^\s>]*//;
#     $$format_ref =~ s/>/ bgcolor="#ffffcf">/;
    $$format_ref =~ s/>/ bgcolor="#ffff80">/; # XXX for laptop
    return unless @_;
    $self->text(shift);
}

1;

__END__

=head1 NAME

Test::FIT::Cell - A class for FIT table cells

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.gnu.org/licenses/gpl.html>

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
