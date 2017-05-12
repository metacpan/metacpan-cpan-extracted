package Tree::M;

use Carp;
use DynaLoader;

BEGIN {
   $VERSION = 0.031;
   @ISA = qw(DynaLoader);
   bootstrap Tree::M, $VERSION;
}

=head1 NAME

Tree::M - implement M-trees for efficient "metric/multimedia-searches"

=head1 SYNOPSIS

  use Tree::M;

  $M = new Tree::M 

=head1 DESCRIPTION

(not yet)

Ever had the problem of managing multi-dimensional (spatial) data but your
database only had one-dimensional indices (b-tree etc.)? Queries like

 select data from table where latitude > 40 and latitude < 50
                          and longitude> 50 and longitude< 60;

are quite inefficient, unless longitude and latitude are part of the same
spatial index (e.g. an R-tree).

An M-tree is an index tree that does not directly look at the stored keys
but rather requires a I<distance> (a metric, e.g. a vector norm) function
to be defined that sorts keys according to their distance. In the example
above the distance function could be the maximum norm (C<max(x1-x2,
y1-y2)>). The lookup above would then be something like this:

   my $res = $M->range([45,55], 5);

This module implements an M-tree. Although the data structure and the
distance function is arbitrary, the current version only implements
n-dimensional discrete vectors and hardwires the distance function to the
suared euclidean metric (i.e. C<(x1-x2)**2 + (y1-y2)**2 + (z1-z2)**2 +
...>). Evolution towards more freedom is expected ;)

=head2 THE Tree::M CLASS

=over 4

=item $M = new Tree::M arg => value, ...

Creates a new M-Tree. Before it can be used you have to call one of the
C<create> or C<open> methods below.

   ndims => integer
      the number of dimensions each vector has

   range => [min, max, steps]
      min      the lowest allowable scalar value in each dimension
      max      the maximum allowable number
      steps    the number of discrete steps (used when stored externally)

   pagesize => integer
      the size of one page on underlying storage. usually 4096, but
      large objects (ndims > 20 or so) might want to increase this

Example: create an M-Tree that stores 8-bit rgb-values:

   $M = new Tree::M ndims => 3, range => [0, 255, 256];

Example: create an M-Tree that stores coordinates from -1..1 with 100 different steps:

   $M = new Tree::M ndims => 2, range => [-1, 1, 100];

=item $M->open(path)

=item $M->create($path)

Open or create the external storage file C<$path> and associate it with the tree.

[this braindamaged API will go away ;)]

=item $M->insert(\@v, $data)

Insert a vector (given by an array reference) into the index and associate
it with the value C<$data> (a 32-bit integer).

=item $M->sync

Synchronize the data file with memory. Useful after calling C<insert> to
ensure the data actually reaches stable storage.

=item $res = $M->range(\@v, $radius)

Search all entries not farther away from C<@v> then C<$radius> and return
an arrayref containing the searchresults.

Each result is again anarrayref composed like this:

   [\@v, $data]

e.g. the same as given to the C<insert> method.

=item $res = $M->top(\@v, $n)

Return the C<$n> "nearest neighbours". The results arrayref (see C<range>)
contains the C<$n> index values nearest to C<@v>, sorted for distance.

=item $distance = $M->distance(\@v1, \@v2)

Calculcate the distance between two vectors, just as they databse engine
would do it.

=item $depth = $M->maxlevel

Return the maximum height of the tree (usually a small integer specifying
the length of the path from the root to the farthest leaf)

=cut

sub new {
   my $class = shift;
   my %a = @_;
   $class->_new(
         $a{ndims},
         $a{range}[0],
         $a{range}[1],
         $a{range}[2],
         $a{pagesize},
   );
}

=back

=head1 BUGS

Inserting too many duplicate keys into the tree cause the C++ library to
die, so don't do that.

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>.

=head1 SEE ALSO

perl(1), L<DBIx::SpatialKeys>.

=cut

1;

