package dtRdr::Book::ThoutBook_1_0::Base;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

use URI::Escape ();

use base qw(
  dtRdr::Book
);

# XXX I think we maybe didn't need this
use constant is_nesty => 1; # means this book is capable of silliness

use Class::Accessor::Classy;
rw qw(
  xml_content
  toc_cache_dirty
  toc_is_cached
  css_stylesheet
);
ro qw(
  base_dir
  location
);
no  Class::Accessor::Classy;

# set this for Book.pm
use constant XML_CONTENT_NODE => 'pkg:outlineMarker';

# our custom metadata object {{{
use constant METADATA_CLASS => 'dtRdr::Book::ThoutBook_1_0::Metadata';
{
  package dtRdr::Book::ThoutBook_1_0::Metadata;
  use base 'dtRdr::Metadata::Book';
  use Class::Accessor::Classy;
  rw this->_MYPROPS;
  use constant _MYPROPS => qw(
    revision
    copyright
    author
    publisher
    packager
    toc_background_color
  );
  use constant PROPS => (
    this->_MYPROPS,
    this->SUPER::PROPS
  );
  no  Class::Accessor::Classy;
} # end custom metadata object }}}

use dtRdr::Book::ThoutBook_1_0::Traits qw(
  _boolify
);

use dtRdr::Logger;
# yes we have a logger, but it's not free like constant optimization is
use constant DEBUG => 0;

use dtRdr::Range;
use dtRdr::Location;
use dtRdr::TOC;

use XML::Parser::Expat;
use XML::Twig;
use URI;

=head1 NAME

dtRdr::Book::ThoutBook_1_0::Base - shared stuff

=head1 SYNOPSIS

=cut

=head1 Constructor

=head2 new

  my $book = dtRdr::Book::ThoutBook_1_0_subclass->new();

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = $class->SUPER::new(@_);
  my %defaults = (
    xml_content => '',  # the content
    base_dir    => '',  # the directory
  );
  foreach my $k (keys(%defaults)) { $self->{$k} = $defaults{$k}; }
  return($self);
} # end subroutine new definition
########################################################################

=head1 Methods

=head2 set_id

URI-escapes the id because Thout1.0 books didn't have a proper ID.

  $book->set_id($id);

=cut

sub set_id {
  my $self = shift;
  my ($id) = @_;
  return($self->SUPER::set_id($self->_id_escape($id)));
} # end subroutine set_id definition
########################################################################

=head2 _id_escape

  $id = $self->_id_escape($id);

=cut

sub _id_escape {
  my $self = shift;
  return(URI::Escape::uri_escape($_[0], '^A-Za-z0-9.-'));
} # end subroutine _id_escape definition
########################################################################

=head2 set_base_dir

  $book->set_base_dir($dir);

=cut

sub set_base_dir {
  my $self = shift;
  my ($base_dir) = @_;
  $base_dir =~ s/\\/\//g; # un Billify win32 dirs
  $base_dir =~ s#/*$#/#;  # always one trailing slash
  (-e $base_dir) or die "non-existent base_dir '$base_dir'";

  $self->{base_dir} = $base_dir;
} # end subroutine set_base_dir definition
########################################################################

=head2 find_toc

Overrides the dtRdr::Book method.

This is needed because Thout 1.0 implements a showpage instruction (a
pseudo goto) and because loading a render="false" *root* node renders
the first child.

  my $toc = $book->find_toc($id);

=cut

sub find_toc {
  my $self = shift;
  my ($id) = @_;
  (1 == @_) or croak('not enough arguments');
  defined($id) or croak('need an id');

  my $root = $self->toc;
  my $toc = $root->get_by_id($id);
  defined($toc) or croak("find failed on id '$id'");

  my $real_toc = $toc;

  # Handle thout_1 root node bug (which is actually an any-node bug)
  if(! $toc->get_info('render') and ($toc->has_children)) {
    L('content')->debug("render = false on root node issue");
    $real_toc = $toc->child(0);
  }
  elsif(defined(my $sp = $toc->get_info('showpage'))) {
    $real_toc = $root->get_by_id($sp);
  }
  return($real_toc);
} # end subroutine find_toc definition
########################################################################

=head2 set_xml_content

  $self->set_xml_content($string);

=cut

sub set_xml_content {
  my $self = shift;
  my ($string) = @_;

  # set the checksum before Twig twiddles the chars so it matches the
  # on-disk file
  $self->mk_fingerprint(\$string);

  return $self->SUPER::set_xml_content($string);
} # end subroutine set_xml_content definition
########################################################################

=head2 setup_metadata

  my $meta = $self->setup_metadata(\%propsheet, \%xml_props);

=cut

sub setup_metadata {
  my $self = shift;
  my ($propsheet, $xml_props) = @_;

  $propsheet or die "need propsheet data";
  $xml_props or die "need xml_props data";

  # ok, three or so sources of data
  # 1.  metadata object (possibly from user-defined values in cache)
  # 2.  propsheet
  # 3.  xml
  # TODO deal with #1 once the metadata object can express readonlyness

  my $meta = $self->meta or die 'no metadata here';

  # first merge everything together
  my %props = %$propsheet;
  foreach my $key (keys(%$xml_props)) {
    if(exists($props{$key})) {
      RL('#bookmeta')->info("overriding $key");
    }
    $props{$key} = $xml_props->{$key};
  }

  # not everything is meta-data
  my %delmap = (
    title          => 'name',
    css_stylesheet => 'stylesheet',
    map({$_ => $_} qw(
      id
    ))
  );
  # TODO serial

  foreach my $key (keys(%delmap)) {
    my $setter = 'set_' . $key;
    exists($props{$delmap{$key}}) or next;
    $self->$setter(delete($props{$delmap{$key}}));
  }

  # TODO deal with legacy we-do-not-actually-have-an-ID issue
  # like: unless(defined($self->id)) {
  #        something like: md5(title.publisher.revision)}
  unless(defined($self->id)) {
    $self->set_id($self->title);
  }

  # trash some internal meta stuff
  foreach my $key (qw(toc_data)) {
    delete($props{$key});
  }

  # special handling
  if(exists($props{annotation_server})) {
    eval {
    my $string = delete($props{annotation_server});
    my @v = split(/\|/, $string);
    (scalar(@v) == 2) or die "bad annotation_server '$string'";
    $meta->set_annotation_server(
      dtRdr::Metadata::Book::annotation_server->new(
        id  => $v[0],
        uri => $v[1],
      )
    );
    };
    $@ and RL('#author')->warn($@);
  }

  my %propmap = (
    map({$_ => $_}
      $self->METADATA_CLASS->PROPS
    ),
    qw(
      packager       packagedby
    ),
  );
  foreach my $key (keys(%propmap)) {
    my $want_prop = $propmap{$key};
    exists($props{$want_prop}) or next;
    my $setter = 'set_' . $key;
    $meta->$setter(delete($props{$want_prop}));
  }

  if(%props) {
    # TODO figure out what's allowed and list it above
    #warn "leftovers: ", join(', ', keys(%props));
  }

  return($meta);
} # end subroutine setup_metadata definition
########################################################################

=head2 load_properties

  my %props = $self->load_properties;

=cut

sub load_properties {
  my $self = shift;

  my $prop_content = $self->get_member_string('thout_package.properties');

  L('content')->debug("package properties: >>>$prop_content<<<");

  my %props;
  my @prop_content = split(/[\r\n]+/, $prop_content);
  for(@prop_content) {
    m/^\s*$/ and next;
    my ($key, $val) = m/\s*([^\:]+)\s*\:\s*(.+)\s*/ig; # XXX g?
    defined($key) or L('content')->warn("error in line: '$_' !");
    $props{$key} = $val;
    L('content')->debug("key:[$key] val:[$val]");
  }
  return(%props);
} # end subroutine load_properties definition
########################################################################

=head2 propify

Transform parsed info into properties hash.

  my %propinfo = $self->propify(%parse_info);

=cut

sub propify {
  my $self = shift;
  my (%info) = @_;

  my %props;
  if(my $patt = $info{package_attribs}) {
    foreach my $key (qw(name id revision serial)) {
      $props{$key} = $patt->{$key} if(exists($patt->{$key}));
    }
  }

  ######################################################################
  # the ad-hoc props-in-content xml bits are not cool
  # TODO multiple entries of one tag are an error?
  # first, a cleanup/collect
  my %adhoc;
  foreach my $prop (@{$info{props}}) {
    # I captured the attribs just so I could complain about them here
    %{$prop->{attribs}} and warn "these are ignored!";

    # cleanup the content string
    my $content = $prop->{content};
    $content =~ s/\s+/ /g;
    $content =~ s/^\s+//;
    $content =~ s/\s+$//;
    #$content = undef unless(length($content));

    my $name = $prop->{name} or die "huh?";
    $name =~ s/^pkg:// or die;
    my $list = $adhoc{$name} ||= [];
    push(@$list, $content);
  }
  # then, get rid of arrays
  ######################################################################
  foreach my $key (keys(%adhoc)) {
    exists($props{$key}) and # is this getting silly yet?
      die "book is broken '$key' appears in xml as an attrib and value";
    #warn "it is $adhoc{$key}";
    $props{$key} = join(', ', @{$adhoc{$key}})
  }

  # final pass
  foreach my $key (keys %props) {
    # XXX is there a valid use-case for no-length/undef keys?
    # XXX I hope not, since that would overwrite a defined value and
    # e.g. our old quickstartguide sets name="" in the XML!
    unless(defined($props{$key}) and length($props{$key})) {
      #warn "ugh: deleting null $key";
      delete($props{$key});
    }
  }

  return(%props);
} # end subroutine propify definition
########################################################################

=head2 finish_load

  $self->finish_load;

=cut

sub finish_load {
  my $self = shift;

  my %props = eval { $self->load_properties};
  if($@) {
    die $@ unless($self->isa('dtRdr::Book::ThoutBook_1_0'));
    # more permissive allows authors some flexibility
    RL('#author')->warn(
      "you may be missing parts of your book -- error: '$@'");
  }

  my %info = $self->build_toc(props => \%props);
  #require YAML::Syck; warn "got: ", YAML::Syck::Dump(\%info);
  $self->setup_metadata(\%props, {$self->propify(%info)});

  return $self;
} # end subroutine finish_load definition
########################################################################

=head2 reduce_word_scope

Returns a Range with the appropriate TOC node and start/end positions
(in cache-coordinates.)

  my $range = $book->reduce_word_scope($node, $start, $end);

In our case, this involves checking each node along the way to ensure
that we properly account for holes (I<renderchildren=0>s' children and
I<render=0>s are holes.)

=cut

sub reduce_word_scope {
  my $self = shift;
  my ($node, $s_rp, $e_rp) = @_;
  # inputs are Rendered Positions

  # Node Positions
  my ($s_np, $e_np) = map({$self->_RP_to_NP($node, $_)} $s_rp, $e_rp);

  # Global Positions
  my $nstart = $node->word_start;
  my ($s_gp, $e_gp) = map({$_ + $nstart} $s_np, $e_np);


  # we go through descendants backwards to start with tightest scope
  my $found;
  foreach my $d (reverse($node->descendants)) {

    defined($d->word_start) or
      die $d->id, " node did not get an aot entry!";

    # XXX we need to determine if this descendant is a hole!
    # (see bug #11 and #12 and maybe #13)

    # we have to lookup nodes with Global Positions (GP)
    if(($d->word_start <= $s_gp) and ($d->word_end >= $e_gp)) {
      $found = $d;
      last;
    }
  }

  my @rp;
  if($found) {
    # now make sure we have correct RP's for this new node

    # first adjust to the new NP though
    my $delta = $found->word_start - $node->word_start;

    @rp = map({$self->_NP_to_RP($found, $_ - $delta)} $s_np, $e_np);
  }
  else {
    # the rendered positions from input are golden
    $found = $node;
    @rp = ($s_rp, $e_rp);
  }
  return(dtRdr::Range->create(node => $found, range => [@rp]));
} # end subroutine reduce_word_scope definition
########################################################################

=head2 _RP_to_NP

Translate a rendered position to a node position.

  $self->_RP_to_NP($node, $pos);

=cut

sub _RP_to_NP {
  my $self = shift;
  my ($node, $pos) = @_;
  $node or croak("must have a node");
  eval {$node->isa('dtRdr::TOC')} or croak('not a TOC object');

  0 and warn "_RP_to_NP for ", $node->id;

  # XXX should make $node->holes work for caching/sanity sake?
  my @holes = $self->_node_holes($node);

  my $node_pos = $pos;
  foreach my $hole (@holes) { # assumes holes are ordered
    # have to localize them!
    my @hole = map({$self->_GP_to_NP($node, $_)} @$hole);
    0 and warn "hole @hole vs $node_pos (orig: $pos)\n";
    # node_pos (approaching NP) must be at or past the start (NP) of the
    # hole for the hole to matter
    ($node_pos >= $hole[0]) or last;
    $node_pos += $hole[1] - $hole[0];
  }
  return($node_pos);
} # end subroutine _RP_to_NP definition
########################################################################

=head2 _NP_to_RP

Translate the node position to a rendered position.

  my $render_pos = $self->_NP_to_RP($node, $node_position);

=cut

sub _NP_to_RP {
  my $self = shift;
  my ($node, $np) = @_;
  $node or croak("must have a node");
  eval {$node->isa('dtRdr::TOC')} or croak('not a TOC object');

  my @holes = $self->_node_holes($node);
  0 and WARN "holes: ", join(", ", map({"[@$_]"} @holes));

  # XXX what is the answer if you ask for an NP which is in the middle
  # of a hole?

  # we have to globalize it because the holes are global
  $np = $self->_NP_to_GP($node, $np);
  my $rp = $np;
  foreach my $hole (@holes) {
    0 and WARN "$hole->[0] <= $np ($hole->[1])";
    ($hole->[0] < $np) or last;
    $rp -= $hole->[1] - $hole->[0];
    0 and WARN "rp now $rp";
  }
  return($self->_GP_to_NP($node, $rp));
} # end subroutine _NP_to_RP definition
########################################################################

=head2 _node_holes

Gets the holes (nonrendered children) for a node.  @holes will be a list
of [$global_start, $global_stop] array-ref pairs.

  my @holes = $self->_node_holes($node);

=cut

sub _node_holes {
  my $self = shift;
  my ($node) = @_;
  $node or croak("must have a node");
  eval {$node->isa('dtRdr::TOC')} or croak('not a TOC object');

  my @holes;
  $node->rmap(sub { my ($n, $ctrl) = @_;
    if(not $n->get_info('render_children')) {
      push(@holes, [$n->child(0)->word_start, $n->child(-1)->word_end])
        if($n->has_children);
      $ctrl->{prune} = 1;
    }
    elsif(not $n->get_info('render')) {
      0 and WARN("hole ", $n->id);
      push(@holes, [$n->word_start, $n->word_end]);
      $ctrl->{prune} = 1;
    }
  });
  return(@holes);
} # end subroutine _node_holes definition
########################################################################

=head1 Node Relations

Our rendered structure does not map directly onto the TOC structure.

We have to handle:

showpage - does nothing except give a different response for
find_toc() -- therefore we ignore it in all node relations

render=0 - trim yourself

render="parent" - trim yourself

render_children=0 - trim all your children

root node - is a switcharoo to its first child when render=false

=head2 descendant_nodes

  my @nodes =  $book->descendant_nodes($node);

  render_children=0 - stop descending
  render=0 - bye
  showpage - not an issue

=cut

sub descendant_nodes {
  my $self = shift;
  my ($toc) = @_;

  # check whether this is the root node
  my $root = $self->toc;

  my @desc;
  my $rsub = sub {
    my ($node, $ctrl) = @_;
    # forget the children if we're not rendered or they aren't rendered
    if(
      ! $node->get_info('render') or
      ! $node->get_info('render_children')
      ) {
      $ctrl->{prune} = 1;
      return;
    }
    foreach my $child ($node->children) {
      if($child->get_info('render')) {
        # as long as render is true
        push(@desc, $child);
      }
    }
  }; # end $rsub
  $toc->rmap($rsub);

  return(@desc);
} # end subroutine descendant_nodes definition
########################################################################

=head2 ancestor_nodes

Returns the node's ancestors, taking into account whether this node or
one of it's parents is a hole.

  my @nodes =  $book->ancestor_nodes($node);

=cut

sub ancestor_nodes {
  my $self = shift;
  my ($node) = @_;

  $node->get_info('render') or return;
  # it is not my ancestor if I'm a hole
  my @ancestors;
  while(my $parent = $node->parent) {
    $parent->get_info('render_children') or last;
    push(@ancestors, $parent);
    $node = $parent;
  }
  return(@ancestors);
} # end subroutine ancestor_nodes definition
########################################################################

=head1 TOC handling

=head2 build_toc

Run through a sax parse to build-up a TOC tree and memorize some byte
offsets and character positions, extract package info, file your taxes,
etc.

  my %info = $self->build_toc;

Returns a hash of properties/metadata.

=cut

sub build_toc {
  my $self = shift;
  (@_ % 2) and croak("odd number of arguments");
  my %args = @_;

  unless($self->toc_cache_dirty) {
    # TODO still must fetch properties and metadata and return %info
    if(defined(my $tocpath = $args{props}{toc_data})) {
      $self->_load_cached_toc($tocpath) and return;
    }
  }

  my $xml = $self->xml_content or die "cannot parse without content";

  my $parser = XML::Parser::Expat->new(ProtocolEncoding => 'UTF-8');

  # get the handlers
  my $data = $self->_get_toc_handlers(%args);
  $parser->setHandlers(%{$data->{handlers}});

  $parser->parse($xml);
  $data->{done} and return($data->{done}->());
  return;
} # end subroutine build_toc definition
########################################################################

=head2 _get_toc_handlers

Gets the SAX parser handler subs.

  my $data = $self->_get_toc_handlers(%options)

  $parser->setHandlers(%{$data->{handlers}});
  ...
  return($data->{done}->());

Options: none for now

=cut

sub _get_toc_handlers {
  my $self = shift;
  my (%options) = @_;

# toc spans closure
my $toc;
my %parse_info = (props => []); # return value from $done->()

my $capturing_prop; # flag

# setup properties to be grabbed
my %proptags = map({'pkg:'.$_ => 1} qw(
  author
  publisher
  stylesheet
));

my $sh = sub {
  my ($p, $el, %atts) = @_;

  if($capturing_prop) { # check integrity of pkg:$meta bits
    die "hit start handler on '$el', but already in '$capturing_prop'";
  }

  # only look at our tag types
  return unless($el =~ /^pkg:/);

  # mostly everything hits the first condition
  if($el eq 'pkg:outlineMarker') {
    my $name = ($atts{OutlineName} || 'undefined');
    defined(my $id = $atts{id}) or die "Toc id is undefined";
    # Get starting location object for this TOC entry
    my $sloc = dtRdr::Location->new($self, $p->current_byte());

    ####################################################################
    # LEGACY:  the old client blindly borked the duplicated ID issue,
    # so now we have to check it and autobump
    if($toc and $toc->get_by_id($id)) {
      RL('#author')->error( # I at least get to throw a fit now, right?
        "the id '$id' has been duplicated -- this will cause some " .
          "of the instances using it to be inaccessible"
      );
      my $flag = '.##thout-autonumbered##.';
      my $new_id = $id . $flag . 0;
      my $counter = 0;
      while($toc->get_by_id($new_id)) {
        $counter++;
        $new_id = $id . $flag . $counter;
      }
      $id = $new_id;
    }
    ####################################################################

    my $range = dtRdr::Range->new(id => $id,
      start => $sloc,
      end   => undef # We'll fill that in later
    );

    # TOC entry args
    my %args = (
      title   => $name,
      visible => _boolify($atts{visible}),
      (($atts{copy} || '' eq 'true') ? (copy_ok => 1) : ()),
      info    => {
        # NOTE the naming normalization
        render_children => _boolify($atts{'renderchildren'}),
        render          => _boolify($atts{'render'}),
        (defined($atts{showpage}) ? (showpage => $atts{showpage}) : ()),
      }
    );

    unless($toc) { # root of TOC
      # assumes thout_1_0 stays legacy (only 1 top-level node)
      $self->{toc} = $toc = dtRdr::TOC->new($self, $id, $range, \%args);
    }
    else {
      # create child in current parent
      $toc = $toc->create_child($id, $range, \%args);
    }
    DEBUG and L('toc')->debug("+"x(scalar($toc->ancestors)), $toc->id);

  } # pkg:outlinemarker
  elsif($el eq 'pkg:package') {
    # just collect the attributes because this doesn't close until EOF
    $parse_info{package_attribs} = {%atts};
  }
  elsif($proptags{$el}) {
    $capturing_prop = $el;
    push(@{$parse_info{props}}, {
      name    => $el,
      attribs => {%atts},
      content => '',
    });
  }
  return;
}; # $sh sub

# TODO there are still issues where the metadata is in the book and not
# the package so maybe just skip the character counting rather than the
# entire parse -- or possibly just setup a set of very wee handlers?
# (e.g. maybe with twig since we can prune the outlineMarker nodes.)

# Note that we can't actually put everything in the cached toc because
# it couldn't be encrypted there.

my $w_offset = 0;
my $tr_wsp = 0;
my $ch = sub {
  my ($p, $string) = @_; # XXX $string is utf8

  # process pkg:$meta bits here too
  if($capturing_prop) {
    # this will throw-off character counters if we're underway, so bail
    $toc and die "oops, broken book";
    $parse_info{props}[-1]{content} .= $string;
    return;
  }

  # we should have a $toc already -- if we don't it is because we're not
  # started yet, so forget about it
  $toc or return;

  # NOTE also might bail on the above condition after the end-handler
  # for the root toc.  That's okay too.

  $string =~ s/&/&amp;/g;
  $string =~ s/</&lt;/g;
  my $word_chars = $string;

  my $id = $toc->id;
  unless(defined($toc->get_word_start)) {
    # This node just started, so remember that number.
    $toc->set_word_start($w_offset);
  }

  # if we're at the very beginning or the last ch saw trailing space,
  # then don't count the leading space
  if($tr_wsp or !$w_offset) { $word_chars =~ s/^\s+//s;}

  $word_chars =~ s/\s+/ /gs;
  my $length = length($word_chars) or return;
  $w_offset += $length;
  #$tr_wsp = (substr($word_chars, -1) eq ' '); # TO_OPT is m/ $/ faster?
  $tr_wsp = ($word_chars =~ m/ $/); # TO_OPT is m/ $/ faster?

}; # $ch sub

my $eh = sub {
  my ($p, $el) = @_;
  if($capturing_prop) { # check integrity of pkg:$meta bits
    ($capturing_prop eq $el) or
      die "hit end handler on '$el', but looking for '$capturing_prop'";
    return $capturing_prop = undef;
  }
  return unless($el eq 'pkg:outlineMarker');

  # Get a location object for the end of this entry
  use bytes;
  my $eloc = dtRdr::Location->new($self,
    # where we are, plus the rest of the tag
    $p->current_byte + length($p->original_string)
  );

  # finish the open range object
  $toc->get_range->set_end($eloc);

  # might have an empty node?
  defined($toc->get_word_start) or $toc->set_word_start($w_offset);
  $toc->set_word_end($w_offset);

  DEBUG and L('toc')->debug("-"x(scalar($toc->ancestors)), $toc->id);

  # go back up...
  $toc = $toc->get_parent;

  return;
}; # $eh sub

my $done = sub {
  0 and dtRdr::Logger->editor( sub { $self->toc->yaml_dump });
  return(%parse_info);
};

  return({
    handlers => { Start => $sh, End => $eh, Char => $ch },
    done     => $done
  });
} # end subroutine _get_toc_handlers definition
########################################################################

=head2 _load_cached_toc

  $self->_load_cached_toc($filename);

=cut

sub _load_cached_toc {
  my $self = shift;
  my ($tocpath) = @_;

  defined($tocpath) or die "need tocpath";
  my $load_method = 'yaml_load';
  if($^O ne 'darwin') { # TODO check byte order or something
    my $altpath = $tocpath . '.stb';
    if($self->member_exists($altpath)) {
      $tocpath = $altpath;
      $load_method = 'stb_load';
      L->info("loading storable file $tocpath");
    }
  }

  my $toc_cont = $self->get_member_string($tocpath);
  my $toc = eval { dtRdr::TOC->$load_method(\$toc_cont, $self) };
  if(my $err = $@) {
    # TODO try to rebuild the yaml if failure was in stb?
    RL('#author')->warn("the book's TOC cache had problems loading >>>$err<<<");
    return(0);
  }

  L->info("loaded cached TOC");
  $self->{toc} = $toc;
  $self->set_toc_is_cached(1);
  return(1);
} # end subroutine _load_cached_toc definition
########################################################################

=head2 whitespace_before

  $book->whitespace_before($node);

=cut

sub whitespace_before {
  my $self = shift;
  my ($node) = @_;
  my $pos = $node->range->a;
  $pos or return(0);
  use bytes;
  my $char = substr($self->{xml_content}, $pos - 1, 1);
  return($char =~ m/\s/);
} # end subroutine whitespace_before definition
########################################################################

=head2 get_content_by_id

Get the content for the $id (ala C<find_toc()>.)

  my $content = $book->get_content_by_id($id);

=cut

sub get_content_by_id {
  my $self = shift;
  my ($id) = @_;
  L('content')->debug("get html by id: $id");
  if(defined(my $toc = $self->find_toc($id))) {
    $self->get_content($toc);
  }
} # end subroutine get_content_by_id definition
########################################################################

=head2 get_content

Gets trimmed, wrapped, and NBH'd content.

  my $content = $book->get_content($toc);

=cut

sub get_content {
  my $self = shift;
  my ($toc) = @_;
  eval {$toc->isa('dtRdr::TOC')} or
    croak("usage:  get_content(<dtRdr::TOC>)");

  if(defined($toc->get_info('showpage'))) {
    # this is supposed to be handled by find_toc now, so calling this
    # with a showpage'd node is invalid.
    # XXX showpage links are broken now from the above
    die('showpage nodes are invalid ', $toc->get_info('showpage'));
  }

  # TODO this should not live here {{{
  # Handle thout_1 root node bug - must happen after showpage check above
  if(! $toc->get_info('render') and ($toc->has_children)) {
    die "must go through find_toc()";

    # TODO also supposed to be able to return a younger sibling?
    # (show me a real-world use case for that)

    # XXX I'm just letting you have a terminal node for now

    L('content')->debug("render = false");
    $toc = $toc->child(0);
  }
  # should not live here }}}

  L('content')->debug('render children ', $toc->get_info('render_children'));

  my $content = $self->get_trimmed_content($toc);
  DBG_DUMP('DBG_TRIMMED', 'trimmed.html', sub {$content});

  # now we should insert nbh data and grab a character cache
  $content = $self->insert_nbh($toc, $content);

  my $wrapped = $self->_fancy_html_lead . $content . $self->_html_tail;
  DBG_DUMP('DBG_WRAPPED', 'wrapped.html', sub {$wrapped});
  return($wrapped);
} # end subroutine get_content definition
########################################################################

=head2 get_trimmed_content

  my $xml = $self->get_trimmed_content($toc);

=cut

sub get_trimmed_content {
  my $self = shift;
  my ($toc) = @_;

  my @plan = $self->_build_trim_plan($toc);
  0 and warn "got plan ", join("\n  ", '',
    map({'[' . join(", ", @$_) . ']'} @plan)), "\n";
  use bytes;

  my $content = '';
  foreach my $item (@plan) {
    my ($start, $stop) = @$item;
    $content .= substr($self->{xml_content}, $start, $stop - $start);
  }
  return($content);
} # end subroutine get_trimmed_content definition
########################################################################

=head2 _build_trim_plan

  @plan = $self->_build_trim_plan($node);

=cut

sub _build_trim_plan {
  my $self = shift;
  my ($toc, $plan) = @_;
  $plan ||= [];

  my ($start, $end) = ($toc->range->a, $toc->range->b);
  my @children = $toc->children;
  unless(@children) { # terminal node
    $self->_append_trim_plan($start, $end, $plan);
    return(@$plan);
  }

  my $f_start  = $children[0]->range->a;
  my $l_end    = $children[-1]->range->b;

  # just up to the first child
  $self->_append_trim_plan($start, $f_start, $plan);
  my $rc = $toc->get_info('render_children');
  for(my $i = 0; $i < @children; $i++) {
    my $child = $children[$i];
    if($rc) {
      if($child->get_info('render')) {
        $self->_build_trim_plan($child, $plan);
      }
    }
    # AND we need to get any bit that might be between the children
    if(my $next = $children[$i+1]) {
      my $c_stop = $child->range->b;
      my $n_start = $next->range->a;
      if($c_stop < $n_start) {
        $self->_append_trim_plan($c_stop, $n_start, $plan);
      }
      else { # just to assert
        ($c_stop == $n_start) or die "bad overlap $c_stop $n_start";
      }
    }
  }
  # and after the last child
  $self->_append_trim_plan($l_end, $end, $plan);
  return(@$plan);
} # end subroutine _build_trim_plan definition
########################################################################

=head2 _append_trim_plan

  $self->_append_trim_plan($start, $stop, \@plan);

=cut

sub _append_trim_plan {
  my $self = shift;
  my ($start, $stop, $plan) = @_;
  #warn "plan: $start, $stop";
  @$plan or return(@$plan = ([$start, $stop]));
  if($start == $plan->[-1][1]) {
    $plan->[-1][1] = $stop;
  }
  else {
    push(@$plan, [$start, $stop]);
  }
} # end subroutine _append_trim_plan definition
########################################################################

=head2 get_copy_content

  $book->get_copy_content($toc);

=cut

sub get_copy_content {
  my $self = shift;
  my ($toc) = @_;

  # TODO this is a huge bug because it doesn't account for non-rendered
  # children and no-render_children aspects of sub toc's but
  # get_trimmed_content() should do that.  We can't use parse_content()
  # because it won't skip the toplevel and this node might not be
  # render=true.

  my $content = $self->get_trimmed_content($toc);
  defined($content) or die 'got no content for ', $toc->id;

  return($self->_html_lead . $content . $self->_html_tail);
} # end subroutine get_copy_content definition
########################################################################

=head2 get_raw_content

  $book->get_raw_content($toc);

=cut

sub get_raw_content {
  my $self = shift;
  my ($toc) = @_;
  my ($start, $end) = ($toc->range->a, $toc->range->b);
  return(substr($self->{xml_content}, $start, $end - $start));
} # end subroutine get_raw_content definition
########################################################################

=head1 HTML formatting

TODO rework these

=head2 _fancy_html_lead

  $content = $self->_fancy_html_lead;

=cut

sub _fancy_html_lead {
  my $self = shift;

  my $css_content = '';
  my $title = $self->title || $self->id;
  L->debug("title: >>>$title<<<");
  my $base_dir = $self->get_base_dir;
  L->debug("base: '$base_dir'");

  if(my $stylesheet = $self->css_stylesheet) {
    RL('#bookcss')->debug("get stylesheet $stylesheet");
    $css_content = $self->get_member_string($stylesheet);
  }
  # TODO get these bits off into some universal package like Book.pm
  $css_content .=
    "\nspan.dr_highlight {\n    " .
    "background-color: yellow;\n margin:0px;\n}\n" .
    # de-uglify the link images
    join("\n", map({"a.dr_$_ img {border: none;}"} qw(
      note notethread bookmark copy
    ))) .
    '';
  $css_content .=
    "span.dr_annoselection {\n" .
    "    background-color: #49FF49;\n" .
    "    margin:0px;\n}\n";
  if(0) { # make notes and bookmarks ugly for debugging
    $css_content .=
      "span.dr_note {\n" .
      "    background-color: cyan;\n" .
      #"    font-size: 50px;\n" .
      "    margin:0px;\n}\n".
      "span.dr_bookmark {\n" .
      "    background-color: lightgreen;\n" .
      "    margin:0px;\n}\n".
      '';
  }

  L('content')->debug("$css_content");

  return <<"CONTENT";
<html>
  <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>$title</title>
  <base href="$base_dir" />
    <style type="text/css">
    <!--
    $css_content
    -->
    </style>
  </head>
  <body>
CONTENT
} # end subroutine _fancy_html_lead definition
########################################################################

=head2 _html_lead

  $self->_html_lead;

=cut

sub _html_lead {
  my $self = shift;
  return(<<"CONTENT");
<html>
  <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  </head>
  <body>
CONTENT
} # end subroutine _html_lead definition
########################################################################

=head2 _html_tail

  $self->_html_tail;

=cut

sub _html_tail {
  my $self = shift;
  return(<<"CONTENT");

  </body>
</html>
CONTENT
} # end subroutine _html_tail definition
########################################################################

=head1 TOC-related Methods

These methods contain the rendering-order logic for this type of book.
Goto and redirect constructs make this slightly different than the
purely structural ordering of the TOC object.

=head2 next_node

Return the TOC object for the (linearly) next node.  If there is none,
returns undef.

  my $next = $book->next_node($toc);

=cut

sub next_node {
  my $self = shift;
  my ($toc) = @_;

  unless(defined $toc->get_info('showpage')) {
    # not a goto, so safe to call find_toc
    $toc = $self->find_toc($toc->id);
  }
  if($toc->has_children and $toc->get_info('render_children') == 0) {
    return($toc->child(0));
  }

  while($toc) {
    my $next = $toc->next_sibling;
    if($next and $next->visible) {
      # TODO now we're skipping any trailing content in the parent
      # need to check for trailing un-noded content in the parent
      return $next;
    }
    $toc = $toc->parent;
  }
} # end subroutine next_node definition
########################################################################

=head2 prev_node

Return the TOC object for the (linearly) previous node.

  my $prev = $book->prev_node($toc);

=cut

sub prev_node {
  my $self = shift;
  my ($toc) = @_;

  unless(defined $toc->get_info('showpage')) {
    $toc = $self->find_toc($toc->id);
  }

  if(my $prev = $toc->prev_sibling) {
    # jump into to previous sibling's deepest visible descendant
    foreach my $node (reverse($prev->descendants)) {
      L->debug('visible: ', $node->visible);
      return $node if($node->visible);
    }
    # just the sibling itself
    return $prev;
  }
  return($toc->parent);

} # end subroutine prev_node definition
########################################################################

=head2 searcher

Returns a subref for the quicksearch (first-pass.)  See
L<dtRdr::Search::Book> for details.

  my $subref = $book->searcher($regexp);

=cut

sub searcher {
  my $self = shift;
  my ($regexp) = @_;

  sub SDBG () {0};
  my $content = $self->xml_content;
  if(utf8::is_utf8($content)) {
    die "that will be slow";
  }
  my $toc = $self->toc;
  my $limit = 0;
  my $subref = sub {
    # ($limit++ > 10) and die "limit"; # for breaking loops
    SDBG and WARN "going to start at ", pos($content);
    if($content =~ m/$regexp/g) {
      my ($start, $stop) = ($-[0], $+[0]);
      SDBG and WARN "hit something at $start $stop",
        substr($content, $start, 10);
      my $node = $toc->enclosing_node($stop);
      # searching for the author name lands us in the metadata before
      # the first node
      unless($node) {
        pos($content) = $stop;
        SDBG and WARN pos($content), " is $stop";
        return(1);
      }
      if($node->is_root and ! $node->get_info('render')) {
        pos($content) = $stop;
        SDBG and WARN pos($content), " is $stop";
        return(1);
      }
      SDBG and WARN 'hit on ', $node->id;
      # optimize, but not so aggressively that we miss something
      my $gopos = $stop;
      if($node->get_info('render_children')) {
        # set position after the end of this node
        # but maybe the first non-rendered child
        my $gochild;
        foreach my $child ($node->children) {
          if($child->visible and ! $child->get_info('render')) {
            $gochild = $child;
            last;
          }
        }
        if($gochild) {
          SDBG and WARN "gochild";
          $gopos = $gochild->range->a;
        }
        else {
          SDBG and WARN "next";
          $gopos = $node->range->b;
        }
      }
      else {
        # go to the first child
        SDBG and WARN "first visible child";
        my ($child) = grep({$_->visible} $node->children);
        if($child) {
          $gopos = $child->range->a;
        }
      }
      # refuse to backtrack even if something got silly
      if($gopos < $stop) {
        SDBG and WARN "tree thought we should go backwards :-/";
        $gopos = $stop;
      }
      pos($content) = $gopos;
      return($node);
    } # end if m//g
    return();
  };
  return($subref);
} # end subroutine searcher definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006-2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

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
