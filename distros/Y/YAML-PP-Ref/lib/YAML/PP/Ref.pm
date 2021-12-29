# ABSTRACT: Generated Reference Parser backend for YAML::PP
package YAML::PP::Ref;
use strict;
use warnings;

use base 'YAML::PP';
use YAML::PP::Ref::Parser;

sub new {
    my ($class, %args) = @_;
    $args{parser} ||= YAML::PP::Ref::Parser->new;
    $class->SUPER::new(%args);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::Ref - Generated Reference Parser backend for YAML::PP

=head1 SYNOPSIS

    my $ypp = YAML::PP::Ref->new;

    my $data = $ypp->load_string($yaml);

    my $data = $ypp->load_file($file);

    open my $fh, '<:encoding(UTF-8)', $file or die $!;
    my $data = $ypp->load_file($fh);
    close $fh;

=head1 DESCRIPTION

The L<https://yaml.org/> YAML Specification can be used to generate a YAML
Parser from it.

Ingy has done that for several languages, and the one for Perl can be found
here: L<https://metacpan.org/dist/YAML-Parser>.

This module exchanges the default L<YAML::PP::Parser> parsing backend with
L<YAML::Parser>. So you can profit from a Parser 100% compliant to
the spec, but L<YAML::PP>'s functionalities on top of that, like loading
the parsing events into a data structure, and using the various L<YAML::PP>
plugins.

At the time of this release, it is quite slow compared to other Perl YAML
modules, but it might not make a difference for you depending on your
application. The grammar for YAML 1.2 is not optimized for speed.

Also the error messages are not really helpful currently.

Check out the documentation of L<YAML::Parser> regularly, these things might
have changed meanwhile.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut
