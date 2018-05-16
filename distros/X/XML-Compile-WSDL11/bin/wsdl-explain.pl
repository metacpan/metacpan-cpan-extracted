#!/usr/bin/env perl
# This example was contribute by Wesley Schwengle, MintLab NL 2015-08-22
# It has the same license as XML::Compile::WSDL11, where it is included
# in the bin/ directory of the distribution.
use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::SOAP11::Encoding;
use XML::Compile::Transport::SOAPHTTP;

my %opt = (
    help    => 0,
    recurse => 0,
    output  => 1,
);

GetOptions(
    \%opt, qw(
        help
        wsdl=s@
        xsd=s@
        list_namespace
        xml
        element=s@
        print_types
        call=s@
        recurse
        compile
        output!
        )
) or pod2usage(1);

pod2usage(verbose => 1) if $opt{help};

unless (defined $opt{wsdl}) {
    warn "Missing option: wsdl";
    pod2usage(1);
}

my $wsdl = XML::Compile::WSDL11->new();
$wsdl->addWSDL($opt{wsdl});

$wsdl->importDefinitions($opt{xsd});

if ($opt{compile}) {
    $wsdl->compileAll;
}
elsif ($opt{print_types}) {
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    foreach my $t (qw(message portType binding service)) {
        print Dumper { $t => [$wsdl->findDef($t)] };
    }
}
elsif ($opt{list_namespace}) {
    print join("\n", $wsdl->namespaces->list, "");
}
elsif ($opt{list_elements}) {
    print join("\n", $wsdl->elements, "");
}
elsif ($opt{element}) {
    my $type = $opt{xml} ? 'XML' : 'PERL';
    foreach (@{$opt{element}}) {
        print "\n" . $wsdl->template($type, $_, skip_header => 1) . "\n";
    }
}
elsif ($opt{call}) {
    my @opts = (
        $opt{xml} ? 'XML' : 'PERL' => $opt{output} ? 'OUTPUT' : 'INPUT',
        skip_header => 1
    );
    foreach my $c ( @{$opt{call}} ) {
        print $wsdl->explain($c, @opts);
    }
}
else {
    print join("\n", (map { $_->name } $wsdl->operations), '');
}

1;

__END__

=head1 NAME

wsdl-explain.pl - Explain WSDL files

=head1 SYNOPSIS

  wsdl-explain.pl OPTIONS

List all the actions:

  ./dev-bin/wsdl-explain.pl --wsdl buildservice.wsdl

Tell me more about a build call:

  ./dev-bin/wsdl-explain.pl --wsdl buildservice.wsdl --call build

Only tell me something about the input:

  ./dev-bin/wsdl-explain.pl --wsdl buildservice.wsdl \
     --call build --no-output

=head1 OPTIONS

=over 4

=item * wsdl

The path to the WSDL you want to check, required. Multiples are allowed.

=item * xsd

The path to the XSD to where the XML types are defined, optional. Multiples are allowed.

=item * compile

Try to compile the WSDL calls

=item * list_namespace

List all the namespaces

=item * element

Describe an element, consider using L<xsd-explain.pl>

=item * call

Explain a particular WSDL call, defaults to OUTPUT.

=item * xml

Explain the call in XML. Currently not supported by L<XML::Compile> and friends.

=item * recurse

Get more information about the underlying structures of the call.

=item * no-output

Do not display the OUTPUT of the call.

=back
