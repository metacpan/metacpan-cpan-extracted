package XML::SAX::Simple;

=head1 NAME

XML::SAX::Simple - SAX version of XML::Simple.

=head1 VERSION

Version 0.08

=cut

$VERSION = '0.08';

use 5.006;
use strict;
use warnings;
use Data::Dumper;

use vars qw(@EXPORT);
use XML::SAX;
use XML::Handler::Trees;
use base 'XML::Simple';
@EXPORT = qw(XMLin XMLout);

=head1 DESCRIPTION

C<XML::SAX::Simple> is a very simple version of L<XML::Simple> but for SAX.It can
be used as a complete drop-in replacement for L<XML::Simple>.

See the documentation for L<XML::Simple> for details.

=head1 SYNOPSIS

    use XML::SAX::Simple qw(XMLin XMLout);
    my $hash = XMLin("foo.xml");

=cut

sub XMLin {
    my $self;

    if ($_[0] and UNIVERSAL::isa($_[0], 'XML::Simple')) {
        $self = shift;
    }
    else {
        $self = XML::SAX::Simple->new();
    }

    $self->SUPER::XMLin(@_);
}

sub XMLout {
    my $self;

    if ($_[0] and UNIVERSAL::isa($_[0], 'XML::Simple')) {
        $self = shift;
    }
    else {
        $self = XML::SAX::Simple->new();
    }

    $self->SUPER::XMLout(@_);
}

sub build_tree {
    my ($self, $filename, $string) = @_;

    $self->{nocollapse} = 1;

    if ($filename and $filename eq '-') {
        local($/);
        $string = <STDIN>;
        $filename = undef;
    }

    my $handler = XML::Handler::Tree->new();
    my $parser  = XML::SAX::ParserFactory->parser(Handler => $handler);

    my $tree;

    if ($filename) {
        $tree = $parser->parse_uri($filename);
    }
    else {
        if (ref($string) && ref($string) ne 'SCALAR') {
            $tree = $parser->parse_file($string);
        }
        else {
            $tree = $parser->parse_string($$string);
        }
    }

    return $tree;
}

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

Currently maintained by Mohammad S Anwar (MANWAR), C<< <mohammad.anwar AT yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/XML-SAX-Simple>

=head1 SEE ALSO

L<XML::Simple>, L<XML::SAX>.

=head1 COPYRIGHT AND LICENCE

This is free  software. You  may use it and distribute it under the same terms as
Perl itself.

Copyright (C) 2001 Matt Sergeant, matt@sergeant.org

=cut

1; # end of XML::SAX::Simple
