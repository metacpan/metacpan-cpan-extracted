package XML::Liberal::LibXML;
use strict;

use Carp;
use XML::LibXML;
use XML::Liberal::Error;

use base qw( XML::Liberal );

our $XML_LibXML_new;

sub globally_override {
    my $class = shift;

    no warnings 'redefine';
    unless ($XML_LibXML_new) {
        $XML_LibXML_new = \&XML::LibXML::new;
        *XML::LibXML::new = sub { XML::Liberal->new('LibXML') };
    }

    1;
}

sub globally_unoverride {
    my $class = shift;

    no warnings 'redefine';
    if ($XML_LibXML_new) {
        *XML::LibXML::new = $XML_LibXML_new;
        undef $XML_LibXML_new;
    }

    return 1;
}

sub new {
    my $class = shift;
    my %param = @_;

    my $self = bless { %param }, $class;
    $self->{parser} = $XML_LibXML_new
        ? $XML_LibXML_new->('XML::LibXML') : XML::LibXML->new;

    $self;
}

sub extract_error {
    my $self = shift;
    my($exn, $xml_ref) = @_;

    # for XML::LibXML > 1.69. Some time between lixml2 2.9.4 and 2.9.12,
    # multiple errors are returned as an array you need to unwind using
    # _prev. Stringifying the root error still gives the combined errors,
    # joined by newlines.
    if (ref $exn eq 'XML::LibXML::Error') {
        $exn = $exn->as_string;
    }
    my @errors = split /\n/, $exn;

    # strip internal error and unregistered error message
    while ($errors[0] =~ /^:\d+: parser error : internal error/ ||
           $errors[0] =~ /^:\d+: parser error : Unregistered error message/) {
        splice @errors, 0, 3;
    }

    my $line = $errors[0] =~ s/^:(\d+):\s*// ? $1  : undef;

    my ($column, $location);
    if (defined $line && defined $errors[1] && defined $errors[2]) {
        my $line_start = 0;
        $line_start = 1 + index $$xml_ref, "\n", $line_start
            for 2 .. $line;
        no warnings 'utf8'; # if fixing bad UTF-8, such warnings are confusing
        if (my ($spaces) = $errors[2] =~ /^(\s*)\^/) {
            my $context = substr $errors[1], 0, length $spaces;
            pos($$xml_ref) = $line_start;
            if ($$xml_ref =~ /\G.*?\Q$context\E /x) {
                $location = $+[0];
                $column = $location - $line_start + 1;
            }
            pos($$xml_ref) = undef; # so future matches work as expected
        }
    }

    return XML::Liberal::Error->new({
        message  => $errors[0],
        line     => $line,
        column   => $column,
        location => $location,
    });
}

# recover() is not useful for Liberal parser ... IMHO
sub recover { }

1;
