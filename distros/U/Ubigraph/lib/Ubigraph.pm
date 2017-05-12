package Ubigraph;

use 5.006;
use strict;
use warnings;
use Frontier::Client;

use Ubigraph::Edge;
use Ubigraph::Vertex;

our $VERSION = '0.05';


sub new {
    my $pkg = shift;
    my $url = shift || 'http://127.0.0.1:20738/RPC2';
    my $this = {};
    bless $this;

    $this->{'client'} = Frontier::Client->new(url=>$url);
    $this->clear();

    return $this;
}


sub clear {
    my $this = shift;
    $this->{'client'}->call('ubigraph.clear', 0);
}


sub Vertex{
    return new Ubigraph::Vertex(@_);
}

sub newVertex{
    return new Ubigraph::Vertex(@_);
}

sub Edge{
    return new Ubigraph::Edge(@_);
}

sub newEdge{
    return new Ubigraph::Edge(@_);
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ubigraph - Perl client of Ubigraph software

=head1 SYNOPSIS

    use Ubigraph;

    my $u = new Ubigraph();

    my $v1 = $u->Vertex();
    my $v2 = $u->Vertex(shape=>"sphere");

    my $e1 = $u->Edge($v1, $v2);

    $v1->shape("torus");
    $v1->size(3.5);

    sleep(2);

    $u->clear();

    my @v;
    for (0..100){
        $v[$_] = $u->Vertex();
    }

    for (0..100){
        $u->Edge($v[int(rand(100))], $v[int(rand(100))]);
        select(undef, undef, undef, 0.05);
    }



=head1 DESCRIPTION

Ubigraph is a Perl client interface for the UbiGraph software 
(http://ubietylab.net/ubigraph/) with object-oriented abstraction
over the XML-RPC calls. UbiGraph is a client-server software for
3D visualization and layout of graph-theoretical network diagrams.
This module hides the XML-RPC calls and allows visualization through
object-oriented access to Vertex and Edge objects, similar to 
Python and Ruby APIs.

=head2 EXPORT

None by default.

=head1 Ubigraph class

=over 5

=item B<$u = new Ubigraph()>

=item B<$u = new Ubigraph($url)>

=back

The constructor of Ubigraph class starts the XML::RPC binding to Ubigraph server. Default url to bind is 'http://127.0.0.1:20738/RPC2'. 

=over 5

=item B<$u-E<gt>clear()>

=back

This method clears all entities.

=over 5

=item B<$vertex = $u-E<gt>Vertex()>

=item B<$vertex = $u-E<gt>newVertex()>

=item B<$vertex = $u-E<gt>Vertex(%parameters)>

=item B<$vertex = $u-E<gt>newVertex(%parameters)>

=back

These class methods create a vertex (Ubigraph::Vertex instance), optionally with hash of parameters. 

=over 5

=item B<$edge = $u-E<gt>Edge($v1, $v2)>

=item B<$edge = $u-E<gt>newEdge($v1, $v2)>

=item B<$edge = $u-E<gt>Edge($v1, $v2, %parameters)>

=item B<$edge = $u-E<gt>newEdge($v1, $v2, %parameters)>

=back

These class methods create an edge (Ubigraph::Edge instance), optionally with hash of parameters. 


=head1 Ubigraph::Vertex class

The following method removes the vertex.

=over 5

=item B<$vertex-E<gt>remove()>

=back

The following methods change the corresponding vertex parameters.

=over 5

=item B<$vertex-E<gt>color($color)>

=item B<$vertex-E<gt>shape($shape)>

=item B<$vertex-E<gt>shapedetail($shapedetail)>

=item B<$vertex-E<gt>label($label)>

=item B<$vertex-E<gt>size($size)>

=item B<$vertex-E<gt>fontcolor($fontcolor)>

=item B<$vertex-E<gt>fontfamily($fontfamily)>

=item B<$vertex-E<gt>fontsize($fontsize)>

=item B<$vertex-E<gt>callback_left_doubleclick($url)>

=back


=head1 Ubigraph::Edge class


The following method removes the edge.

=over 5

=item B<$edge-E<gt>remove()>

=back

The following methods change the corresponding edge parameters.

=over 5

=item B<$edge-E<gt>arrow($arrow)>

=item B<$edge-E<gt>arrow_position($arrow_position)>

=item B<$edge-E<gt>arrow_radius($arrow_radius)>

=item B<$edge-E<gt>arrow_length($arrow_length)>

=item B<$edge-E<gt>arrow_reverse($arrow_reverse)>

=item B<$edge-E<gt>color($color)>

=item B<$edge-E<gt>label($label)>

=item B<$edge-E<gt>fontcolor($fontcolor)>

=item B<$edge-E<gt>fontfamily($fontfamily)>

=item B<$edge-E<gt>fontsize($fontsize)>

=item B<$edge-E<gt>oriented($oriented)>

=item B<$edge-E<gt>spline($spline)>

=item B<$edge-E<gt>showstrain($showstrain)>

=item B<$edge-E<gt>stroke($stroke)>

=item B<$edge-E<gt>strength($strength)>

=item B<$edge-E<gt>visible($visible)>

=item B<$edge-E<gt>width($width)>

=back

=head1 SEE ALSO

For the details of the parameters, users should refer to the UbiGraph
XML-RPC Manual (http://ubietylab.net/ubigraph/content/Docs/index.html).

=head1 AUTHOR

Kazuharu Arakawa E<lt>gaou@sfc.keio.ac.jpE<gt>
Kazuki Oshita E<lt>cory@g-language.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kazuharu Arakawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
