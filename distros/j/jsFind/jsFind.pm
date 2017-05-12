package jsFind;

use 5.005;
use strict;
use warnings;
use HTML::Entities;

our $VERSION = '0.06';

use Exporter 'import';
use Carp;

our @ISA = qw(Exporter);

BEGIN {
	import 'jsFind::Node';
}

=head1 NAME

jsFind - generate index for full text search engine in JavaScript

=head1 SYNOPSIS

  use jsFind;
  my $t = new jsFind(B => 4);
  my $f = 1;
  foreach my $k (qw{minima ut dolorem sapiente voluptatem}) {
  	$t->B_search(Key => $k,
  		Data => {
  			"path" => {
  			t => "word $k",
  			f => $f },
  		},
  		Insert => 1,
  		Append => 1,
  	);
  }

=head1 DESCRIPTION

This module can be used to create index files for jsFind, powerful tool for
adding a search engine to a CDROM archive or catalog without requiring the
user to install anything. 

Main difference between this module and scripts delivered with jsFind are:

=over 5

=item *

You don't need to use swish-e to create index

=item *

you can programatically (and incrementaly) create index for jsFind

=item *

you can create more than one index and search them using same C<search.html>
page

=back

You can also examine examples which come as tests with this module,
for example C<t/04words.t> or C<t/10homer.t>.

=head2 jsFind

jsFind search engine was written by Shawn Garbett from eLucid Software.
The search engine itself is a small piece of JavaScript (1.2 with level 2
DOM). It is easily customizable to fit into a current set of HTML. This
JavaScript searches an XML index dataset for the appropriate links, and can
filter and sort the results.

JavaScript code distributed with this module is based on version 0.0.3 which
was current when this module development started. Various changes where done
on JavaScript code to fix bugs, add features and remove warnings. For
complete list see C<Changes> file which comes with distribution.

This module has been tested using C<html/test.html> with following browsers:

=over 5

=item Mozilla FireFox 0.8 to 1.0

using DOM 2 C<document.implementation.createDocument>

=item Internet Explorer 5.5 and 6.0

using ActiveX C<Microsoft.XMLDOM> or C<MSXML2.DOMDocument>

=item Konqueror 3.3

using DOM 2 C<document.implementation.createDocument>

=item Opera 7.54 (without Java)

using experimental iframe implementation which is much slower than other methods.

=back

If searching doesn't work for your combination of operating system and
browser, please open C<html/test.html> file and wait a while. It will search sample
file included with distribution and report results. Reports with included
test debugging are welcomed.

=head1 jsFind methods

C<jsFind> is mode implementing methods which you, the user, are going to
use to create indexes.

=head2 new

Create new tree. Arguments are C<B> which is maximum numbers of keys in
each node and optional C<Root> node. Each root node may have child nodes.

All nodes are objects from C<jsFind::Node>.

 my $t = new jsFind(B => 4);

=cut

my $DEBUG = 1;

sub new {
  my $package = shift;
  my %ARGV = @_;
  croak "Usage: {$package}::new(B => number [, Root => root node ])"
      unless exists $ARGV{B};
  if ($ARGV{B} % 2) {
    my $B = $ARGV{B} + 1;
    carp "B must be an even number.  Using $B instead.";
    $ARGV{B} = $B;
  }
    
  my $B = $ARGV{B};
  my $Root = exists($ARGV{Root}) ? $ARGV{Root} : jsFind::Node->emptynode;
  bless { B => $B, Root => $Root } => $package;
}

=head2 B_search

Search, insert, append or replace data in B-Tree

 $t->B_search(
 	Key => 'key value',
	Data => { "path" => {
			"t" => "title of document",
			"f" => 99,
			},
		},
	Insert => 1,
	Append => 1,
 );

Semantics:

If key not found, insert it iff C<Insert> argument is present.

If key B<is> found, replace existing data iff C<Replace> argument
is present or add new datum to existing iff C<Append> argument is present.

=cut

sub B_search {
  my $self = shift;
  my %args = @_;
  my $cur_node = $self->root;
  my $k = $args{Key};
  my $d = $args{Data};
  my @path;

  if ($cur_node->is_empty) {	# Special case for empty root
    if ($args{Insert}) {
      $cur_node->kdp_insert($k => $d);
      return $d;
    } else {
      return undef;
    }
  }

  # Descend tree to leaf
  for (;;) {

    # Didn't hit bottom yet.

    my($there, $where) = $cur_node->locate_key($k);
    if ($there) {		# Found it!
      if ($args{Replace}) {
	$cur_node->kdp_replace($where, $k => $d);
      } elsif ($args{Append}) {
      	$cur_node->kdp_append($where, $k => $d);
      }
      return $cur_node->data($where);
    }
    
    # Not here---must be in a subtree.
    
    if ($cur_node->is_leaf) {	# But there are no subtrees
      return undef unless $args{Insert}; # Search failed
      # Stuff it in
      $cur_node->kdp_insert($k => $d);
      if ($self->node_overfull($cur_node)) { # Oops--there was no room.
	$self->split_and_promote($cur_node, @path);
      } 
      return $d;
    }

    # There are subtrees, and the key is in one of them.

    push @path, [$cur_node, $where];	# Record path from root.

    # Move down to search the subtree
    $cur_node = $cur_node->subnode($where);

    # and start over.
  }				# for (;;) ...

  croak ("How did I get here?");
}



sub split_and_promote_old {
  my $self = shift;
  my ($cur_node, @path) = @_;
  
  for (;;) {
    my ($newleft, $newright, $kdp) = $cur_node->halves($self->B / 2);
    my ($up, $where) = @{pop @path};
    if ($up) {
      $up->kdp_insert(@$kdp);
      my ($tthere, $twhere) = $up->locate_key($kdp->[0]);
      croak "Couldn't find key `$kdp->[0]' in node after just inserting it!"
	  unless $tthere;
      croak "`$kdp->[0]' went into node at `$twhere' instead of expected `$where'!"
	  unless $twhere == $where;
      $up->subnode($where,   $newleft);
      $up->subnode($where+1, $newright);
      return unless $self->node_overfull($up);
      $cur_node = $up;
    } else { # We're at the top; make a new root.
      my $newroot = new jsFind::Node ([$kdp->[0]], 
				     [$kdp->[1]], 
				     [$newleft, $newright]);
      $self->root($newroot);
      return;
    }
  }
  
}

sub split_and_promote {
  my $self = shift;
  my ($cur_node, @path) = @_;
  
  for (;;) {
    my ($newleft, $newright, $kdp) = $cur_node->halves($self->B / 2);
    my ($up, $where) = @{pop @path} if (@path);
    if ($up) {
      $up->kdp_insert(@$kdp);
      if ($DEBUG) {
        my ($tthere, $twhere) = $up->locate_key($kdp->[0]);
        croak "Couldn't find key `$kdp->[0]' in node after just inserting it!"
  	  unless $tthere;
        croak "`$kdp->[0]' went into node at `$twhere' instead of expected `$where'!"
	  unless $twhere == $where;
      }
      $up->subnode($where,   $newleft);
      $up->subnode($where+1, $newright);
      return unless $self->node_overfull($up);
      $cur_node = $up;
    } else { # We're at the top; make a new root.
      my $newroot = new jsFind::Node([$kdp->[0]], 
				     [$kdp->[1]], 
				     [$newleft, $newright]);
      $self->root($newroot);
      return;
    }
  }
}

=head2 B

Return B (maximum number of keys)

 my $max_size = $t->B;

=cut

sub B {
  $_[0]{B};
}

=head2 root

Returns root node

 my $root = $t->root;

=cut

sub root {
  my ($self, $newroot) = @_;
  $self->{Root} = $newroot if defined $newroot;
  $self->{Root};
}

=head2 node_overfull

Returns if node is overfull

 if ($node->node_overfull) { something }

=cut

sub node_overfull {
  my $self = shift;
  my $node = shift;
  $node->size > $self->B;
}

=head2 to_string

Returns your tree as formatted string.

 my $text = $root->to_string;

Mostly usefull for debugging as output leaves much to be desired.

=cut

sub to_string {
  $_[0]->root->to_string;
}

=head2 to_dot

Create Graphviz graph of your tree

 my $dot_graph = $root->to_dot;

=cut

sub to_dot {
	my $self = shift;

	my $dot = qq/digraph dns {\nrankdir=LR;\n/;
	$dot .= $self->root->to_dot;
	$dot .= qq/\n}\n/;

	return $dot;
}

=head2 to_jsfind

Create xml index files for jsFind. This should be called after
your B-Tree has been filled with data.

 $root->to_jsfind(
 	dir => '/full/path/to/index/dir/',
	data_codepage => 'ISO-8859-2',
	index_codepage => 'UTF-8',
	output_filter => sub {
		my $t = shift || return;
		$t =~ s/&egrave;/e/;
	}
 );

All options except C<dir> are optional.

Returns number of nodes in created tree.

Options:

=over 4

=item dir

Full path to directory for index (which will be created if needed).

=item data_codepage

If your imput data isn't in C<ISO-8859-1> encoding, you will have to specify
this option.

=item index_codepage

If your index encoding is not C<UTF-8> use this option.

If you are not using supplied JavaScript search code, or your browser is
terribly broken and thinks that index shouldn't be in UTF-8 encoding, use
this option to specify encoding for created XML index.

=item output_filter

B<this is just draft of documentation for option which is not implemented!>

Code ref to sub which can do modifications on resulting XML file for node.
Encoding of this data will be in L<index_codepage> and you have to take care
not to break XML structure. Calling L<xmllint> on your result index
(like C<t/90xmllint.t> does in this distribution) is a good idea after using
this option.

This option is also right place to plug in unaccenting function using
L<Text::Unaccent>.

=back

=cut

my $iconv;
my $iconv_l1;

sub to_jsfind {
	my $self = shift;

	my %arg = @_;

	confess "to_jsfind need path to your index directory !" unless ($arg{'dir'});

	my $data_codepage = $arg{'data_codepage'};
	my $index_codepage = $arg{'index_codepage'} || 'UTF-8';

	# create ISO-8859-1 iconv for HTML::Entities decode
	$iconv_l1 = Text::Iconv->new('ISO-8859-1',$index_codepage);

	# create another iconv for data
	if ($data_codepage && $index_codepage) {
		$iconv = Text::Iconv->new($data_codepage,$index_codepage);
	}

	return $self->root->to_jsfind($arg{'dir'},"0");
}


# private, default cmd function
sub default_cmp {
  $_[0] cmp $_[1];
}

=head2 _recode

This is internal function to recode charset.

It will also try to decode entities in data using L<HTML::Entities>.

=cut

sub _recode {
	my $self = shift;
	my $text = shift || return;

	sub _decode_html_entities {
		my $data = shift || return;
		$data = $iconv_l1->convert(decode_entities($data)) || croak "entity decode problem: $data";
	}

	if ($iconv) {
		$text = $iconv->convert($text) || $text && carp "convert problem: $text";
		$text =~ s/(\&\w+;)/_decode_html_entities($1)/ges;
	}

	return $text;
}

#####################################################################

=head1 jsFind::Node methods

Each node has C<k> key-data pairs, with C<B> <= C<k> <= C<2B>, and 
each has C<k+1> subnodes, which might be null.

The node is a blessed reference to a list with three elements:

  ($keylist, $datalist, $subnodelist)

each is a reference to a list list.

The null node is represented by a blessed reference to an empty list.

=cut

package jsFind::Node;

use warnings;
use strict;

use Carp;
use File::Path;
use Text::Iconv;
use POSIX;

use base 'jsFind';

my $KEYS = 0;
my $DATA = 1;
my $SUBNODES = 2;

=head2 new

Create New node

 my $node = new jsFind::Node ($keylist, $datalist, $subnodelist);

You can also mit argument list to create empty node.

 my $empty_node = new jsFind::Node;

=cut

sub new {
  my $self = shift;
  my $package = ref $self || $self;
  croak "Internal error:  jsFind::Node::new called with wrong number of arguments."
      unless @_ == 3 || @_ == 0;
  bless [@_] => $package;
}

=head2 locate_key

Locate key in node using linear search. This should probably be replaced
by binary search for better performance.

 my ($found, $index) = $node->locate_key($key, $cmp_coderef);

Argument C<$cmp_coderef> is optional reference to custom comparison
operator.

Returns (1, $index) if $key[$index] eq $key.

Returns (0, $index) if key could be found in $subnode[$index].

In scalar context, just returns 1 or 0.

=cut

sub locate_key {
  # Use linear search for testing, replace with binary search.
  my $self = shift;
  my $key = shift;
  my $cmp = shift || \&jsFind::default_cmp;
  my $i;
  my $cmp_result;
  my $N = $self->size;
  for ($i = 0; $i < $N; $i++) {
    $cmp_result = &$cmp($key, $self->key($i));
    last if $cmp_result <= 0;
  }
  
  # $i is now the index of the first node-key greater than $key
  # or $N if there is no such.  $cmp_result is 0 iff the key was found.
  (!$cmp_result, $i);
}


=head2 emptynode

Creates new empty node

 $node = $root->emptynode;
 $new_node = $node->emptynode;

=cut

sub emptynode {
  new($_[0]);			# Pass package name, but not anything else.
}

=head2 is_empty

Test if node is empty

 if ($node->is_empty) { something }

=cut

# undef is empty; so is a blessed empty list.
sub is_empty {
  my $self = shift;
  !defined($self) || $#$self < 0;
}

=head2 key

Return C<$i>th key from node

 my $key = $node->key($i);

=cut

sub key {
#  my ($self, $n) = @_;
#  $self->[$KEYS][$n];

#	speedup
   $_[0]->[$KEYS][$_[1]];
}

=head2 data

Return C<$i>th data from node

 my $data = $node->data($i);

=cut

sub data {
  my ($self, $n) = @_;
  $self->[$DATA][$n];
}

=head2 kdp_replace

Set key data pair for C<$i>th element in node

 $node->kdp_replace($i, "key value" => {
	"data key 1" => "data value 1",
	"data key 2" => "data value 2",
 };

=cut

sub kdp_replace {
  my ($self, $n, $k => $d) = @_;
  if (defined $k) {
    $self->[$KEYS][$n] = $k;
    $self->[$DATA][$n] = $d;
  }
  [$self->[$KEYS][$n], 
   $self->[$DATA][$n]];
}

=head2 kdp_insert

Insert key/data pair in tree

  $node->kdp_insert("key value" => "data value");

No return value.

=cut

sub kdp_insert {
  my $self = shift;
  my ($k => $d) = @_;
  my ($there, $where) = $self->locate_key($k) unless $self->is_empty;

  if ($there) { croak("Tried to insert `$k => $d' into node where `$k' was already present."); }

  # undef fix
  $where ||= 0;

  splice(@{$self->[$KEYS]}, $where, 0, $k);
  splice(@{$self->[$DATA]}, $where, 0, $d);
  splice(@{$self->[$SUBNODES]}, $where, 0, undef);
}

=head2 kdp_append

Adds new data keys and values to C<$i>th element in node

 $node->kdp_append($i, "key value" => {
	"added data key" => "added data value",
 };

=cut

sub kdp_append {
  my ($self, $n, $k => $d) = @_;
  if (defined $k) {
    $self->[$KEYS][$n] = $k;
    my ($kv,$dv) = %{$d};
    $self->[$DATA][$n]->{$kv} = $dv;
  }
  [$self->[$KEYS][$n], 
   $self->[$DATA][$n]];
}

=head2 subnode

Set new or return existing subnode

 # return 4th subnode
 my $my_node = $node->subnode(4);

 # create new subnode 5 from $my_node
 $node->subnode(5, $my_node);

=cut

sub subnode {
  my ($self, $n, $newnode) = @_;
  $self->[$SUBNODES][$n] = $newnode if defined $newnode;
  $self->[$SUBNODES][$n];
}

=head2 is_leaf

Test if node is leaf

 if ($node->is_leaf) { something }

=cut

sub is_leaf {
  my $self = shift;
  ! defined $self->[$SUBNODES][0]; # undefined subnode means leaf node.
}

=head2 size

Return number of keys in the node

 my $nr = $node->size;

=cut

sub size {
  my $self = shift;
  return scalar(@{$self->[$KEYS]});
}

=head2 halves

Split node into two halves so that keys C<0 .. $n-1> are in one node
and keys C<$n+1 ... $size> are in the other.

  my ($left_node, $right_node, $kdp) = $node->halves($n);

=cut

sub halves {
  my $self = shift;
  my $n = shift;
  my $s = $self->size;
  my @right;
  my @left;

  $left[$KEYS] = [@{$self->[$KEYS]}[0 .. $n-1]];
  $left[$DATA] = [@{$self->[$DATA]}[0 .. $n-1]];
  $left[$SUBNODES] = [@{$self->[$SUBNODES]}[0 .. $n]];

  $right[$KEYS] = [@{$self->[$KEYS]}[$n+1 .. $s-1]];
  $right[$DATA] = [@{$self->[$DATA]}[$n+1 .. $s-1]];
  $right[$SUBNODES] = [@{$self->[$SUBNODES]}[$n+1 .. $s]];

  my @middle = ($self->[$KEYS][$n], $self->[$DATA][$n]);

  ($self->new(@left), $self->new(@right), \@middle);
}

=head2 to_string

Dumps tree as string

 my $str = $root->to_string;

=cut

sub to_string {
  my $self = shift;
  my $indent = shift || 0;
  my $I = ' ' x $indent;
  return '' if $self->is_empty;
  my ($k, $d, $s) = @$self;
  my $result = '';
  $result .= defined($s->[0]) ? $s->[0]->to_string($indent+2) : '';
  my $N = $self->size;
  my $i;
  for ($i = 0; $i < $N; $i++) {
#    $result .= $I . "$k->[$i] => $d->[$i]\n";
    $result .= $I . "$k->[$i]\n";
    $result .= defined($s->[$i+1]) ? $s->[$i+1]->to_string($indent+2) : '';
  }
  $result;
}

=begin comment

use Data::Dumper;

sub to_string {
  my $self = shift;
  my $indent = shift || 0;
  my $path = shift || '0';
  return '' if $self->is_empty;
  my ($k, $d, $s) = @$self;
  my $result = '';
  $result .= defined($s->[0]) ? $s->[0]->to_string($indent+1,"$path/0") : '';
  my $N = $self->size;
  for (my $i = 0; $i < $N; $i++) {
  	my $dump = Dumper($d->[$i]);
	$dump =~ s/[\n\r\s]+/ /gs;
	$dump =~ s/\$VAR1\s*=\s*//;
    $result .= sprintf("%-5s [%2d] %2s: %s => %s\n", $path, $i, $indent, $k->[$i], $dump);
    $result .= defined($s->[$i+1]) ? $s->[$i+1]->to_string($indent+1,"$path/$i") : '';
  }
  $result;
}

=end comment

=head2 to_dot

Recursivly walk nodes of tree

=cut

sub to_dot {
	my $self = shift;
	my $parent = shift;

	return '' if $self->is_empty;

	my $dot = '';

	my ($k, $d, $s) = @$self;
	my $N = $self->size;

	my @dot_keys;

	my $node_name = $parent || '_';
	$node_name =~ s/\W+//g;
	$node_name .= " [$N]";

	for (my $i = 0; $i <= $N; $i++) {
		if (my $key = $k->[$i]) {
			push @dot_keys, qq{<$i>$key};
		}
		$dot .= $s->[$i]->to_dot(qq{"$node_name":$i}) if ($s->[$i]);
	}
	push @dot_keys, qq{<$N>...} if (! $self->is_leaf);

	my $label = join("|",@dot_keys);
	$dot .= qq{"$node_name" [ shape=record, label="$label" ];\n};

	$dot .= qq{$parent -> "$node_name";\n} if ($parent);

	$dot;
}

=head2 to_xml

Escape <, >, & and ", and to produce valid XML

=cut

my %escape = ('<'=>'&lt;', '>'=>'&gt;', '&'=>'&amp;', '"'=>'&quot;');
my $escape_re  = join '|' => keys %escape;

sub to_xml {
	my $self = shift || confess "you should call to_xml as object!";

	my $d = shift || return;
	$d = $self->SUPER::_recode($d);
	confess "escape_re undefined!" unless ($escape_re);
	$d =~ s/($escape_re)/$escape{$1}/g;
	return $d;
}

=head2 base_x

Convert number to base x (used for jsFind index filenames).

 my $n = $tree->base_x(50);

=cut

sub base_x {
	my $self = shift;

	my $value = shift;

	confess("need non-negative number") if (! defined($value) || $value < 0);

	my @digits = qw(
		0 1 2 3 4 5 6 7 8 9
		a b c d e f g h i j k l m n o p q r s t u v w x y z
	);

	my $base = scalar(@digits);
	my $out = "";
	my $pow = 1;
	my $pos = 0;


	if($value == 0) {
		return "0";
	}

	while($value > 0) {
		$pos = $value % $base;
		$out = $digits[$pos] . $out;
		$value = floor($value/$base);
		$pow *= $base;
	}

	return $out;
}

=head2 to_jsfind

Create jsFind xml files

 my $nr=$tree->to_jsfind('/path/to/index','0');

Returns number of elements created

=cut

sub to_jsfind {
	my $self = shift;
	my ($path,$file) = @_;

	return 0 if $self->is_empty;

	confess("path is undefined.") unless ($path);
	confess("file is undefined. Did you call \$t->root->to_jsfind(..) instead of \$t->to_jsfind(..) ?") unless (defined($file));

	$file = $self->base_x($file);

	my $nr_keys = 0;

	my ($k, $d, $s) = @$self;
	my $N = $self->size;

	my ($key_xml, $data_xml) = ("<n>","<d>");

	for (my $i = 0; $i <= $N; $i++) {
		my $key = lc($k->[$i]);

		if ($key) {
			$key_xml .= '<k>'.$self->to_xml($key).'</k>';
			$data_xml .= '<e>';
	#use Data::Dumper;
	#print Dumper($d->[$i]);
			foreach my $path (keys %{$d->[$i]}) {
				$data_xml .= '<l f="'.($d->[$i]->{$path}->{'f'} || 1).'" t="'.$self->to_xml($d->[$i]->{$path}->{'t'} || 'no title').'">'.$self->to_xml($path).'</l>';
				$nr_keys++;
			}
			$data_xml .= '</e>';
		}

		$nr_keys += $s->[$i]->to_jsfind("$path/$file","$i") if ($s->[$i]);
	}

	$key_xml .= '</n>';
	$data_xml .= '</d>';

	if (! -e $path) {
		mkpath($path) || croak "can't create dir '$path': $!";
	}

	open(K, "> ${path}/${file}.xml") || croak "can't open '$path/$file.xml': $!";
	open(D, "> ${path}/_${file}.xml") || croak "can't open '$path/_$file.xml': $!";

	print K $key_xml;
	print D $data_xml;

	close(K);
	close(D);

	return $nr_keys;
}

1;
__END__

=head1 SEE ALSO

jsFind web site L<http://www.elucidsoft.net/projects/jsfind/>

B-Trees in perl web site L<http://perl.plover.com/BTree/>

This module web site L<http://www.rot13.org/~dpavlin/jsFind.html>

=head1 AUTHORS

Mark-Jonson Dominus E<lt>mjd@pobox.comE<gt> wrote C<BTree.pm> which was
base for this module

Shawn P. Garbett E<lt>shawn@elucidsoft.netE<gt> wrote jsFind

Dobrica Pavlinusic E<lt>dpavlin@rot13.orgE<gt> wrote this module

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Dobrica Pavlinusic

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version. This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

=cut
