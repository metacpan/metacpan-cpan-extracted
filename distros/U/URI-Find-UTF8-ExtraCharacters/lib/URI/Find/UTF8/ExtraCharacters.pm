package URI::Find::UTF8::ExtraCharacters;
$URI::Find::UTF8::ExtraCharacters::VERSION = '0.03';
use strict;
use warnings;

use base 'URI::Find::UTF8';
=head1 NAME

URI::Find::UTF8::ExtraCharacters - URI::Find::UTF8 with optional extra characters.

=head1 SYNOPSIS

    my $finder = URI::Find::UTF8::ExtraCharacters->new( sub {
            my ( $uri_obj, $url ) = @_;
            return "$uri_obj";
        },
        extra_characters => ['|'],
    );
    my $text = "link to zombo: http://zombo.com/lorem|ipsum?queryparam=queryval";
    $finder->find(\$text);
    say $text; #link to zombo: http://zombo.com/lorem%7Cipsum?queryparam=queryval

=head1 DESCRIPTION

The web is a wacky place full of screwed up URLs. This is a drop in replacement for L<URI::Find::UTF8>
( Which is a drop in replacement for L<URI::Find> ) which allows you to pass in additional characters that
URI::Find thinks are bogus. ( like '|' )

=head2 Public Methods

=over 4

=item B<new>

    my $finder = URI::Find::UTF8::ExtraCharacters->new(\&callback,
        extra_characters => \@chars );

Creates a new URI::Find::UTF8::ExtraCharacters object. See the docs for L<URI::Find> for more in depth documentation.

=back

=cut

sub uric_set {
    my $self = shift;
    join('', map { quotemeta($_) } @{ $self->{_extra_characters} } )
        . $self->SUPER::uric_set;
}

sub new {
    my($class,$callback,%params) = @_;
    my $extra_characters = $params{extra_characters} || [];
    my $self = $class->SUPER::new($callback);
    $self->{_extra_characters} = $extra_characters;
    return $self;
}

=head1 INCOMPATIBILITIES

This module does not export 'find_uris,' which L<URI::Find> does but L<URI::Find::UTF8> does not.

=head1 AUTHOR

Samuel Kaufman, skaufman-at-cpan.org

=head1 LICENSE

Copyright 2014 by Samuel Kaufman

 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

See L<http://www.perlfoundation.org/artistic_license_1_0>


=cut

1;
