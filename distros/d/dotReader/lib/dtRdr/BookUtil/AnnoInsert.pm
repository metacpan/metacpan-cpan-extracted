package dtRdr::BookUtil::AnnoInsert;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

use dtRdr::Logger;

use Class::Accessor::Classy;
ro 'parser';
ro qw(
  book
  node
  todo
  open_annos
  anno_order
);
ro qw(
  output
  leading_ws
  trailing_ws
);
rw qw(
  chars
  offset
);
no  Class::Accessor::Classy;

our $ROOT = 'justincasewehavenoroot';


=head1 NAME

dtRdr::BookUtil::AnnoInsert - XML parse/populate

=head1 SYNOPSIS

  my $answer = dtRdr::BookUtil::AnnoInsert->new(
    $book, %params
    )->parse($string)->done;

=cut

=head1 Frontend

=head2 new

  my $ai = dtRdr::BookUtil::AnnoInsert->new($book, %params);

=cut

sub new {
  my $class = shift;
  my $book = shift;
  eval {$book->isa('dtRdr::Book')} or croak("not a book");
  (@_ % 2) and croak("odd number of elements in argument list");
  my %args = @_;
  $args{todo} or die "ack";
  $args{node} or die "ack";
  my $self = {%args, book => $book};
  my $parser = $self->{parser} = 
    XML::Parser::Expat->new(ProtocolEncoding => 'UTF-8');
  $self->{chars} = [];
  $self->{output} = []; # ridiculously faster as an array
  $self->{offset} = 0;
  $self->{trailing_space} = 0;
  $self->{anno_order} = [];
  $self->{open_annos} = {};

  $self->{accum_string} = '';
  $parser->setHandlers(
    Start => sub {$self->start_handler(@_)},
    End   => sub {$self->end_handler(@_)},
    Char  => sub {$self->{accum_string} .= $_[1]},
  );

  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 parse

  $ai->parse($string);

=cut

sub parse {
  my $self = shift;
  my ($string) = @_;

  # these appear to make no difference
  $string =~ s/^(\s*)//;
  $self->{leading_ws} = $1 || '';
  $string =~ s/(\s*)$//;
  $self->{trailing_ws} = $1 || '';

  eval { $self->parser->parse("<$ROOT>$string</$ROOT>") };
  if($@) {
    DBG_DUMP('PARSE', 'thestringin.xml', sub{$string});
    die "XML parsing failed $@ ";
  }
  return($self);
} # end subroutine parse definition
########################################################################

=head2 done

  $output = $ai->done;

=cut

sub done {
  my $self = shift;

  my $book = $self->book;
  my $node = $self->node;

  $book->cache_node_characters($node, join('', @{$self->chars}));

  DBG_DUMP('CACHE', 'cache', sub {join('', @{$self->chars})});

  my $output = $self->output;
  my $n = 0;
  $n++ until(length($output->[$n]));
  $output->[$n] =~ s/^<$ROOT>// or die 'cannot get rid of my fake start tag';
  $n = -1;
  $n-- until(length($output->[$n]));
  $output->[$n] =~ s/<\/$ROOT>$// or
    die 'cannot get rid of my fake end tag >>>' ,
      $output->[$n] ,'<<<';

  # put the whitespace back
  return(join('', $self->leading_ws, @$output, $self->trailing_ws));
} # end subroutine done definition
########################################################################

=head1 XML Parsing Guts

=head2 start_handler

  $ai->start_handler($p, $el, %atts);

=cut

sub start_handler {
  my $self = shift;
  my ($p, $el, %atts) = @_;

  $self->do_chars;
  # TODO some way to not hop if tag pair is fully contained?
  # tag-hopping for the highlight spans
  my ($before, $after) = ('','');
  if(@{$self->anno_order}) {
    ($before, $after) = $self->hoppers;
  }

  my $rec_string = $p->recognized_string;

  my $book = $self->book;
  my $node = $self->node;

  # running callbacks
  if(my $subref = $self->{xml_callbacks}{start}{$el}) {
    $subref->(
      $book,
      node       => $node,
      before     => \$before,
      after      => \$after,
      during     => \$rec_string,
      attributes => \%atts,
    );
  }

  push(@{$self->{output}}, $before, $rec_string, $after);
  return;
} # end subroutine start_handler definition
########################################################################

=head2 end_handler

  $ai->end_handler($p, $el);

=cut

sub end_handler {
  my $self = shift;
  my ($p, $el, %atts) = @_;

  $self->do_chars;
  my ($before, $after) = ('','');
  if(@{$self->anno_order}) {
    ($before, $after) = $self->hoppers;
    # don't reopen at the end:
    ($el eq $ROOT) and ($after = '');
    # NOTE that $before also properly closes everything that's open as
    # long as we always wrap with this funny fakeroot tag
  }
  push(@{$self->{output}}, $before, $p->recognized_string, $after);
  return;
} # end subroutine end_handler definition
########################################################################

=head2 do_chars

  $ai->do_chars($byte_offset);

=cut

sub do_chars {
  my $self = shift;

  # maybe nothing to do here
  length($self->{accum_string}) or return;

  my $rec_string = $self->{accum_string};
  $self->{accum_string} = '';

  # clean it up (wait, why is the parser giving us this?)
  $rec_string =~ s/&/&amp;/g;
  $rec_string =~ s/</&lt;/g;

  my $book = $self->book;
  my $node = $self->node;
  my $chars = $self->{chars};
  my $offset = $self->offset;

  my $word_chars = $rec_string;
  # for counting, we say all groups of whitespace are one unit
  # but crossing tags messes with us a little
  my $lead = '';
  unless(@$chars) { # the very beginning
    # we don't count leading node whitespace if it is in a node before us
    if((! $node->is_root) and $book->whitespace_before($node)) {
      $word_chars =~ s/^\s+//;
      if($rec_string =~ s/^(\s+)//s) {
        $lead = $1;
      }
    }
    else {
      # AFAICT, this only happens on completely contrived books
      0 and warn "\n\nGAH! no whitespace before ", $node->id, "???!\n\n";
    }
  }
  elsif($self->{trailing_space}) {
    # strip leading space if the previous chars had a trailing space
    $word_chars =~ s/^\s+//;
    # honor this on the $rec_string too
    if($rec_string =~ s/^(\s+)//s) {
      $lead = $1;
    }
  }
  $word_chars =~ s/\s+/ /gs;

  # get out early
  unless(length($word_chars)) {
    # but don't lose "\n"-only entries (breaks pre-formatted text)
    push(@{$self->{output}}, $lead, $rec_string);
    return;
  }
  # NOTE: way faster (30-50%) to check against a short string and
  # remember it vs asking perl to look at the end of the very long and
  # ever-changing $$char string.
  $self->{trailing_space} = (substr($word_chars, -1) eq ' ');
  push(@$chars, $word_chars);

  my $new_offset = $offset + length($word_chars);

  # do placement within $rec_string, then put on output
  my $spliced =
    length($rec_string) ? $self->splice($rec_string, $new_offset) : '';

  push(@{$self->{output}}, $lead, $spliced);

  $offset = $new_offset;
  $self->set_offset($offset);
  0 and warn "offset now $offset\n",
    (1 ? "spliced '$spliced'\n" : ' '),
    (1 ? "chars now '@$chars'\n " : ' ');
} # end subroutine do_chars definition
########################################################################

=head1 String Handling

=head2 splice

  my $spliced = $ai->splice($string, $new_offset);

=cut

sub splice {
  my $self = shift;
  my ($rec_string, $new_offset) = @_;

  my $todo = $self->todo;
  @$todo or return($rec_string);
  
  my $splicer = dtRdr::String::Splicer->new($rec_string);
  my $book = $self->book;
  my $open_annos = $self->open_annos;
  my $anno_order = $self->anno_order;
  my $offset = $self->offset;

  while(@$todo) {

    # NOTE we want to get in after a tag at the start and before it at
    # the end -- this allows <p><highlight>foo</highlight></p> to DTRT
    # XXX but does break links when they get bookmarked :-/

    unless(
      ($todo->[0][1]->a == $todo->[0][0])
      ? ($todo->[0][0] < $new_offset)  # start
      : ($todo->[0][0] <= $new_offset) # end
      ) {
      last;
    }

    # otherwise, do something
    my $item = shift(@$todo);
    ($offset <= $item->[0]) or
      die "$offset <= $item->[0] < $new_offset failure";
    0 and WARN("handle $item->[0] after $offset and before $new_offset");
    my $marker;

    my $target = $item->[0] - $offset;
    my $anno = $item->[1];

    # NOTE all annotations appear to be two-part, so no sense in
    # checking that here.  Even if we break this assumption, we just
    # need to remove the one-part annotation from @todo upon opening.
    if(exists($open_annos->{$anno})) { # closing
      # get rid of it
      @$anno_order = grep({$_ ne $anno} @$anno_order);
      # and rebuild the index:
      %$open_annos = map({$anno_order->[$_] => $_} 0..$#$anno_order);

      # now get the hopper bits and make a marker
      my ($before, $after) = $self->hoppers;

      $marker = $before . '</span>' . $after .
        $self->closing_marker($anno);
    }
    else { # opening
      # The hoppers are not needed here iff we stick to only
      # inserting <span> elements (because closing span "a" is the
      # same as closing span "b".)

      # remember where it is and in what order
      $open_annos->{$anno} = push(@$anno_order, $anno) -1;

      $marker = $self->opening_marker($anno)
    }
    $splicer->insert($target, $marker);
  }
  return($splicer->string);
} # end subroutine splice definition
########################################################################

=head1 Formatting

=head2 hoppers

  $ai->hoppers;

=cut

sub hoppers {
  my $self = shift;
  my $before = '';
  my $after = '';
  foreach my $hl (@{$self->anno_order}) {
    $before .= '</span>';
    $after  .= $self->start_marker($hl->ANNOTATION_TYPE, $hl->id);
  }
  return($before, $after);
} # end subroutine hoppers definition
########################################################################

=head2 opening_marker

  $self->opening_marker($anno);

=cut

our %DO_ON_OPEN = map({$_ => 1} qw(bookmark highlight annoselection));
sub opening_marker {
  my $self = shift;
  my ($anno) = @_;


  my $type = $anno->ANNOTATION_TYPE;
  my $id = $anno->id;
  my $marker = (
    $DO_ON_OPEN{$type} ? $self->create_marker($type, $id) : ''
    ) .
    $self->start_marker($type, $id);

  return($marker);
} # end subroutine opening_marker definition
########################################################################

=head2 closing_marker

  $self->closing_marker($anno);

=cut

our %DO_ON_CLOSE = map({$_ => 1} qw(note notethread));
sub closing_marker {
  my $self = shift;
  my ($anno) = @_;


  my $type = $anno->ANNOTATION_TYPE;
  $DO_ON_CLOSE{$type} or return('');

  my $marker = '';
  my $id = $anno->id;

  my %opts;
  if($type eq 'notethread') { # deal with missing roots
    # TODO possibly link to the dummy root with some sort of flag?
    #$opts{path} = 'dummy/' if($anno->is_dummy);
    if($anno->is_dummy) { # just link to the first real one
      $anno->rmap(sub { my ($n, $ctrl) = @_;
        unless($n->is_dummy) { $id = $n->id; $ctrl->{prune} = 1; }
      });
    }
  }
  $marker .= $self->create_marker($type, $id, %opts);
  return($marker);
} # end subroutine closing_marker definition
########################################################################

=head2 create_marker

Build the annotation marker.

  $marker .= $self->create_marker($type, $id, %opts);

=cut

{
my %EXT = (
  note       => 'drnt',
  notethread => 'drnt',
  bookmark   => 'drbm',
);
sub create_marker {
  my $self = shift;
  my ($type, $id, %opts) = @_;

  my $ext = $EXT{$type};

  # we make a named anchor for everything, plus a link and image if
  my $string =
    qq(<a class="dr_$type" name="$id") .
      ($ext ? ( # ugly, but hopefully fast
        qq( href="dr://LOCAL/) .
          (exists($opts{path}) ? $opts{path} : '') . qq($id.$ext" ) .
          '><img class="dr_' . $type . '" src="' .
            $self->img("dr_${type}_link.png") .
          '" />'
      ) : # else just close the anchor
      '>') .
      '</a>';
  return($string)
} # end subroutine create_marker definition
} # end closure
########################################################################

=head2 img

Create (with caching) the img string (runs the book callbacks.)

  my $string = $self->img($png_path);

=cut

sub img {
  my $self = shift;
  my ($png_path) = @_;

  my $cache = $self->{_img_cache} ||= {};
  exists($cache->{$png_path}) and return($cache->{$png_path});
  ### warn "create cache for $png_path";

  my $book = $self->book;
  my $string = $book->get_callbacks->img_src_rewrite(
    $book->get_callbacks->core_link($png_path),
    $book
  );
  return($cache->{$png_path} = $string);
} # end subroutine img definition
########################################################################

=head2 start_marker

Create the start of a span marker

  my $marker = $self->start_marker($type, $id);

=cut

sub start_marker {
  my $self = shift;
  my ($type, $id) = @_;
  return(qq(<span class="dr_$type ) . $id . '">');
} # end subroutine start_marker definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
