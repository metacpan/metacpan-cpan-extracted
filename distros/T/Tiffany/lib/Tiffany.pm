package Tiffany;
use strict;
use warnings;
use 5.00800;
our $VERSION = '1.01';

sub load {
    my ($class, $klass, $args) = @_;
    $klass = _load_class($klass, 'Tiffany');
    return $klass->new($args);
}

# code taken from Plack::Util::load_class.
my %loaded;
sub _load_class {
    my ( $class, $prefix ) = @_;

    if ($prefix) {
        unless ( $class =~ s/^\+// || $class =~ /^$prefix/ ) {
            $class = "$prefix\::$class";
        }
    }

    return $class if $loaded{$class}++;

    my $file = $class;
    $file =~ s!::!/!g;
    require "$file.pm";    ## no critic

    return $class;
}

1;
__END__

=encoding utf8

=head1 NAME

Tiffany - Generic interface for Perl5 template engines.

=head1 SYNOPSIS

    use Tiffany;

    my $tmpl = Tiffany->load('Text::Xslate', {syntax => 'TTerse'});
    $tmpl->render(\'Hello, [% name %]', {name => 'John'});
    # => "Hello, John"

=head1 DESCRIPTION

Tiffany is a generic interface for Perl5 template engines.

=head1 FACTORY METHOD

Tiffany.pm acts as a factory for Tiffany::* classes, which in turn are the actual adaptor classes for each template engine.

=over 4

=item C<< my $tiffany = Tiffany->load($klass, $args) >>

Load Tiffany::* class if necessary, and create new instance of using the given arguments.

    my $xslate = Tiffany->load("Text::Xslate", +{syntax => 'TTerse'});

    my $xslate = Tiffany->load("+My::Template::Engine", +{option => 'here'});

=back

=head1 The Tiffany Protocol

The Tiffany protocol is based on duck typing. A template adaptor does not need to inherit from a particular class, but its API needs to adhere to the spec provided here.

In the documentation that follows, C<Tiffany::Thing> represents an adaptor class.

=over 4

=item C<< my $tiffanny = Tiffany::Thing->new([$args:HashRef|ArrayRef]); >>

The module SHOULD have a B<new> method.

This method creates a new instance of Tiffany module.

$args should be passed to the constructor of the template engine.

=item C<< my $result = $tmpl->render($stuff:Scalar|ScalarRef [, @args]); >>

The module SHOULD have a B<render> method.

This method should invoke the appropriate rendering method for the underlying template engine, using @args.

If the template engine found any errors, this method MUST throw an exception.

If the template engine throws any exceptions, Tiffany module SHOULD pass through the exception unaltered.

B<$stuff> SHOULD expect a Scalar that represents the template filename. The module MAY allow a ScalarRef that holds the actual template code.

This method MUST return plain string. Do not return a blessed reference.

=back

=head1 HOW TO USE IT IN MY WEB APPLICATION FRAMEWORK?

Example code is here: eg/sinatraish/ in distribution tar ball or L<http://github.com/tokuhirom/p5-tiffany/tree/master/eg/sinatraish/>.

=head1 FAQ

=over 4

=item Is Tiffany supports JSON?

Tiffany should not support JSON. Tiffany protocol can support JSON serialize.
But real web application needs more things like Content-Type.
It is not supported area for Tiffany.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Any::Template>, L<http://github.com/rtomayko/tilt>

=head1 THANKS TO

kazuhooku

gfx

miyagawa

lestrrat

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
