#!/usr/bin/perl
# This example was contribute by Wesley Schwengle, MintLab NL 2015-08-22
# It has the same license as XML::Compile::WSDL11, where it is included
# in the bin/ directory of the distribution.

use warnings;
use strict;

use XML::Compile::Schema;
use Getopt::Long;
use Pod::Usage;

my %opt = (
    help => 0,
);

GetOptions(
    \%opt, qw(
        help
        xsd=s@
        element=s@
        print_index
        list_namespace
        xml
        )
) or pod2usage(1);

pod2usage(0) if ($opt{help});

unless (defined $opt{xsd}) {
    warn "Missing option: xsd";
    pod2usage(1);
}

my $schema = XML::Compile::Schema->new($opt{xsd});

if ($opt{element}) {
    my $type = $opt{xml} ? 'XML' : 'PERL';
    foreach (@{$opt{element}}) {
        print "\n" . $schema->template($type, $_, skip_header => 1) . "\n";
    }
}
elsif ($opt{print_index}) {
    $schema->printIndex;
}
elsif ($opt{list_namespace}) {
    print join("\n", $schema->namespaces()->list, '');
}
else {
    print join("\n", $schema->elements(), '');
}

1;

__END__


=head1 NAME

xsd-explain.pl - Explain XSD files

=head1 SYNOPSIS

  xsd-explain.pl OPTIONS

List all the elements

  xsd-explain.pl \
     --xsd buildservice.xsd \
     --xsd dev.java.net.array.xsd

=head1 OPTIONS

=over

=item * xsd

The path to the XSD you want to check, required. Multiples are allowed.

=item * element

The element you want to know more about, optional. Multiples are allowed.

=item * xml

If you have supplied an element, you can choose a Perl or an XML data structure.
When not enabled we display a perl data structure

=item * print_index

Prints the index of the schema

=item * list_namespace

List the namespaces

=back
