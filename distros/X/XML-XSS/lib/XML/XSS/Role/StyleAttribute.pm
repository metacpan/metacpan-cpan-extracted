package XML::XSS::Role::StyleAttribute;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Trait of style attributes
$XML::XSS::Role::StyleAttribute::VERSION = '0.3.5';
use Moose::Role;
use XML::XSS::StyleAttribute;

before '_process_options' => sub {
    my ( $class, $name, $options ) = @_;

    $options->{is}        ||= 'ro';
    $options->{isa}       ||= 'XML::XSS::StyleAttribute';
    $options->{default}   ||= sub {
        return XML::XSS::StyleAttribute->new;
    };

    $options->{handles} ||= {
        "set_$name" => 'set_value',
        "clear_$name" => 'clear_value',
        "has_$name" => 'has_value',
    };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XSS::Role::StyleAttribute - Trait of style attributes

=head1 VERSION

version 0.3.5

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2013, 2011, 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
