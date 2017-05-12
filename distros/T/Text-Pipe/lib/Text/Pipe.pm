package Text::Pipe;

use strict;
use warnings;
use 5.006;
use Text::Pipe::Base;   # for def_pipe()
use Sub::Name;
use UNIVERSAL::require;


our $VERSION = '0.10';


use base 'Exporter';


our %EXPORT_TAGS = (
    util  => [ qw(PIPE) ],
);


our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };


# this is just a factory

sub new {
    my ($class, $type, @config) = @_;
    my $package = "Text::Pipe::$type";

    # Check; it might have been defined with def_pipe(), so ->require wouldn't
    # work.

    unless (UNIVERSAL::can($package, 'filter')) {
        $package->require or die $@;
    }

    $package->new(@config);
}   


sub def_pipe {
    my ($self, $name, $code) = @_;
    my $package = "Text::Pipe::$name";

    no strict 'refs';
    @{ "${package}::ISA" } = ('Text::Pipe::Base');
    *{ "${package}::filter" } = subname "${package}::filter" => $code;
}


# Easier, procedural, way to construct a pipe

sub PIPE {
    my ($type, @args) = @_;
    Text::Pipe->new($type, @args);
}


1;


__END__

=head1 NAME

Text::Pipe - Common text filter API

=head1 SYNOPSIS

    my $pipe = Text::Pipe->new('List::First', code => { $_ < 7 });
    my $result = $pipe->filter('foo');

    # or

    use Web::Scraper;
    my $scraper = scraper {
        process '//p/a',
            'texts[]' => [ 'TEXT', PIPE('Trim'), PIPE('Uppercase') ];
    };

=head1 DESCRIPTION

This class is a factory for text pipes. A pipe has a C<filter()> method
through which input can pass. The input can be a string or a reference to an
array of strings. Pipes can be stacked together using
L<Text::Pipe::Stackable>.

The problem that this distribution tries to solve is that there are several
distributions on CPAN which use text filtering in some way or other, for
example the Template Toolkit or Web::Scraper. But each distribution is
somewhat different, and they have to reimplement the same text filters over
and over again.

This distribution aims at offering a common text filter API. So if you want to
use text pipes with Template Toolkit, you just need to write an adapter. With
Web::Scraper, you can even use text pipes directly Using the C<PIPE()>
function, as shown in the synopsis.

Text pipe segments live in the C<Text::Pipe::> namespace. So if you implement
a C<Text::Pipe::Foo::Bar> pipe segment, you can instantiate it with

    my $pipe = Text::Pipe->new('Foo::Bar');

Some pipe segments take arguments. These are described in their respective
class documentations.

=head1 EXPORTS

=over 4

=item C<PIPE>

    my $pipe = PIPE('Reverse', times => 2, join => ' = ');
    my $pipe = PIPE('UppercaseFirst');

Text::Pipe exports, on request, the function C<PIPE()> that makes it easier to
construct pipes. It takes the same arguments as new() and returns the
corresponding pipe.

=back

=head1 METHODS

=over 4

=item C<new>

    my $pipe = Text::Pipe->new('List::First', code => { $_ < 7 });

Constructs a new pipe. The first argument is the pipe segment type - in the
example above a C<Text::Pipe::List::First> would be constructed. The remaining
arguments are passed to that segment's constructor.

=item C<def_pipe>

    Text::Pipe->def_pipe('Foobar', sub { lc $_[1] });
    my $pipe_lowercase = Text::Pipe->new('Foobar');
    is($pipe_lowercase->filter('A TEST'), 'a test', 'lowercase pipe');

This method provides a lightweight way to define a new pipe segment class. The
first argument is the segment type - in the example above, a new segment class
C<Text::Pipe::Foobar> would be defined. The second argument is a coderef that
acts as the segment's filter. The segment class will subclass
C<Text::Pipe::Base>.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

The development version lives at L<http://github.com/hanekomu/text-pipe/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

