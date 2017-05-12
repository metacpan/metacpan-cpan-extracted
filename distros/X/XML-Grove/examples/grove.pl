#
# Copyright (C) 1998 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: grove.pl,v 1.4 1999/05/06 23:13:02 kmacleod Exp $
#

use XML::Parser::PerlSAX;
use XML::Grove;
use XML::Grove::Builder;

my $builder = XML::Grove::Builder->new;
my $parser = XML::Parser::PerlSAX->new(Handler => $builder);

my $doc;
foreach $doc (@ARGV) {
    my $grove = $parser->parse (Source => { SystemId => $doc });

    dump_grove ($grove);
}


sub dump_grove {
    my $grove = shift;
    my @context = ();

    _dump_contents ($grove->{Contents}, \@context);
}

sub _dump_contents {
    my $contents = shift;
    my $context = shift;

    foreach $item (@$contents) {
	if (ref ($item) =~ /::Element/) {
	    push @$context, $item->{Name};
	    my @attributes = %{$item->{Attributes}};
	    print STDERR "@$context \\\\ (@attributes)\n";
	    _dump_contents ($item->{Contents}, $context);
	    print STDERR "@$context //\n";
	    pop @$context;
	} elsif (ref ($item) =~ /::PI/) {
	    my $target = $item->{Target};
	    my $data = $item->{Data};
	    print STDERR "@$context ?? $target($data)\n";
	} elsif (ref ($item) =~ /::Characters/) {
	    my $data = $item->{Data};
	    $data =~ s/([\x80-\xff])/sprintf "#x%X;", ord $1/eg;
	    $data =~ s/([\t\n])/sprintf "#%d;", ord $1/eg;
	    print STDERR "@$context || $data\n";
	} elsif (!ref ($item)) {
	    print STDERR "@$context !! SCALAR: $item\n";
	} else {
	    print STDERR "@$context !! OTHER: $item\n";
	}
    }
}
