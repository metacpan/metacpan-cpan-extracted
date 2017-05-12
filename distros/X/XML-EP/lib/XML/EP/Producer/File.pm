# -*- perl -*-

use strict;

use XML::DOM ();

package XML::EP::Producer::File;

$XML::EP::Producer::File::VERSION = '0.01';


sub new {
    my $proto = shift;
    my $self = (@_ == 1) ? \%{ shift() } : { @_ };
    bless($self, (ref($proto) || $proto));
}

sub Produce {
    my $self = shift;  my $ep = shift;
    my $request = $ep->Request();
    my $path = $request->PathTranslated() || $request->PathInfo() ||
	die XML::EP::Error->new("Missing path specification", 500);
    die XML::EP::Error->new("No such file or directory", 404)
	unless -f $path;
    $ep->{'path'} = $path;
    $ep->{'path_mtime'} = (stat _)[9];
    my $parser = XML::DOM::Parser->new();
    my $xml = $parser->parsefile($path)  ||
        die XML::EP::Error->new("Failed to parse $path", 500);
    $xml;
}


1;
