package Treex::PML::Instance;

use 5.008;
use strict;
use warnings;
use Carp;
use Cwd;

BEGIN {

require Exporter;
import Exporter qw(import);

}

use Scalar::Util qw(weaken blessed);
use UNIVERSAL::DOES;
use Treex::PML::Instance::Common qw(:all);
use Treex::PML::Schema;
use Encode;
use File::Spec;
use URI;
use URI::file;
our $DEFAULT_ENCODING = 'utf-8';

BEGIN {

=begin comment

 TODO

  Note: correct writing with XSLT requires XML::LibXML >= 1.59 (!!!)

 (GENERAL):

  - improve reading/writing trees (use the live object)
    Postponing because:
       1/ sequences of tree/no-tree objects are problematic
       2/ changing this would break binary compatibility

  - Treex::PML:
       find_role_in_data,
       traverse_data($node, $decl, sub($data,$decl,$decl_resolved))

  - readas DOM => readas PML, where #KNITting means pointing to the same data (if possible).
    test implementation: breaks old Undo/Redo, but ok with the new "object-preserving" one

  (XSLT):

  - support for external xslt processors (maybe a common wrapper)
  - with LibXSLT, cache the parsed stylesheets

  DONE:

  - hash by #ID into appData('id-hash')/{'id-hash'} (knitted instances could be hashed with prefix#, 
    knitted-knitted instances with prefix1#prefix2#...)
    (this is temporary)

=end comment

=cut

}

our %EXPORT_TAGS = ( 
  'functions' => [ qw( get_data set_data count_matches for_each_match get_all_matches ) ],
  'constants' => $Treex::PML::Instance::Common::EXPORT_TAGS{constants},
  'diagnostics' => $Treex::PML::Instance::Common::EXPORT_TAGS{diagnostics},
);
$EXPORT_TAGS{'all'} = [ @{ $EXPORT_TAGS{'constants'} },
                        @{ $EXPORT_TAGS{'diagnostics'} },
                        @{ $EXPORT_TAGS{'functions'} },
                        qw( $DEBUG )
                      ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(  );
our $VERSION = '2.26'; # version template

BEGIN {
require Treex::PML::IO;
require Treex::PML;


# FIELDS:
use fields qw(
    _schema 
    _schema-url
    _schema-inline
    _types
    _dom
    _root
    _parser
    _writer
    _filename
    _transform_id
    _status
    _readas-trees
    _references
    _refnames
    _ref
    _ref-index
    _pml_trees_type
    _no_read_trees
    _no_references
    _no_knit
    _selected_references
    _selected_references_ids
    _selected_knits
    _selected_knits_ids
    _trees
    _pml_prolog
    _pml_epilog
    _id-hash
    _log
    _id_prefix
    _trees_written
    _refs_save
    _save_flags
    _pi
   );

} # BEGIN

use Treex::PML::Instance::Reader;
use Treex::PML::Instance::Writer;

# PML Instance File
sub get_filename {
  my $filename= $_[0]->{'_filename'};
  if (blessed($filename) and $filename->isa('URI')
      and $filename->scheme eq 'file') {
    return $filename->file;
  }
  return $filename;
}
sub get_url {
  my $filename= $_[0]->{'_filename'};
  if ($filename and not (blessed($filename) and $filename->isa('URI'))) {
    return Treex::PML::IO::make_URI($filename);
  }
  return $filename;
}

sub set_filename {
  $_[0]->{'_filename'} = Treex::PML::IO::make_abs_URI($_[1]); # 1K faster than cwd
}
sub get_transform_id  {  $_[0]->{'_transform_id'}; }
sub set_transform_id  {  $_[0]->{'_transform_id'} = $_[1]; }

# Schema
sub schema            {  $_[0]->{'_schema'} }
*get_schema = \&schema;
sub set_schema        {  $_[0]->{'_schema'} = $_[1] }
sub get_schema_url    {  $_[0]->{'_schema-url'} }
sub set_schema_url    {  $_[0]->{'_schema-url'} = $_[1]; }

# Data
sub get_root          {  $_[0]->{'_root'}; }
sub set_root          {  $_[0]->{'_root'} = $_[1]; }
sub get_trees         {  $_[0]->{'_trees'}; }
#sub set_trees        {  $_[0]->{'_trees'} = $_[1]; }
sub get_trees_prolog  {  $_[0]->{'_pml_prolog'}; }
#sub set_trees_prolog {  $_[0]->{'_pml_prolog'} = $_[1]; }
sub get_trees_epilog  {  $_[0]->{'_pml_epilog'}; }
#sub set_trees_epilog {  $_[0]->{'_pml_epilog'} = $_[1]; }
sub get_trees_type    {  $_[0]->{'_pml_trees_type'}; }
#sub set_trees_type   {  $_[0]->{'_pml_trees_type'} = $_[1]; }

# References
sub get_references_hash {
  return ($_[0]->{'_references'}||={});
}
sub set_references_hash {  $_[0]->{'_references'} = $_[1]; }
sub get_ref_ids_by_name {
  my ($self,$name)=@_;
  my $refs = $self->get_refname_hash->{$name};
  return ref($refs) ? @$refs : ($refs);
}
sub get_refs_by_name {
  my ($self,$name)=@_;
  return map {$self->get_ref($_)} $self->get_ref_ids_by_name;
}
sub get_refname_hash {
  return ($_[0]->{'_refnames'}||={});
}
sub set_refname_hash {  $_[0]->{'_refnames'} = $_[1]; }
sub get_ref {
  my ($self,$id)=@_;
  my $refs = $self->{'_ref'};
  return $refs ? $refs->{$id} : undef;
}
sub set_ref {
  my ($self,$id,$obj)=@_;
  my $refs = $self->{'_ref'};
  $self->{'_ref'} = $refs = {} unless ($refs);
  return $refs->{$id}=$obj;
}

# Status=1 (if parsed fine)
sub get_status  {  $_[0]->{'_status'}; }
#sub set_status {  $_[0]->{'_status'} = $_[1]; }

sub get_reffiles {
  my ($ctxt)=@_;
  my $references = [$ctxt->{'_schema'}->get_named_references];
  my @refs;
  if ($references) {
    foreach my $reference (@$references) {
      my $refids = $ctxt->{'_refnames'}->{$reference->{name}};
      if ($refids) {
        foreach my $refid (ref($refids) ? @$refids : ($refids)) {
          my $href = $ctxt->{'_references'}->{$refid};
          if ($href) {
            _debug("Found '$reference->{name}' as $refid# = '$href'");
            push @refs,{
              readas => $reference->{readas},
              name => $reference->{name},
              id => $refid,
              href => $href
             };
          } else {
            _die("No href for $refid# ($reference->{name})")
          }
        }
      } else {
        _warn("Didn't find any reference to '".$reference->{name}."'\n");
      }
    }
  }
  return @refs;
}

sub read_reffiles {
  my ($ctxt,$opts) = @_;
  foreach my $ref ($ctxt->get_reffiles()) {
    my $id = $ref->{id};
    my $selected = $ctxt->{'_selected_references_ids'}{$id};
    next if (defined($selected) ? $selected==0 : $ctxt->{'_no_references'});
    my $readas = $ref->{readas};
    if (defined $readas) {
      if ($readas eq 'dom') {
        $ctxt->readas_dom($id,$ref->{href},$opts);
      } elsif($readas eq 'trees') {
        #  when translating to Treex::PML::Document, 
      #  push to fs-require [$id,$ref->{href}];
      } elsif($readas eq 'pml') {
        $ctxt->readas_pml($id,$ref->{href},$opts);
      } elsif (length($readas)) {
        _warn("Ignoring references with unknown readas method: '$readas' for reffile id='$id', href='$ref->{href}'\n");
      }
    }
  }
}

sub readas_pml {
  my ($ctxt,$refid,$href,$opts)=@_;
  # embed PML documents
  my $ref_data;
  _debug("readas_pml: $refid => $href");
  my $pml = Treex::PML::Instance->load({
    filename => $href,
    no_knit => $ctxt->{_no_knit},
    selected_knits => $ctxt->{_selected_knits},
    no_references => $ctxt->{_no_references},
    selected_references => $ctxt->{_selected_references},
    ($opts ? %$opts : ()),
  });
  $ctxt->{'_ref'} ||= {};
  $ctxt->{'_ref'}->{$refid}=$pml;
  $ctxt->{'_ref-index'} ||= {};
  weaken( $ctxt->{'_ref-index'}->{$refid} = $pml->{'_id-hash'} );
  1;
}

# $ctxt, $refid, $href
sub readas_dom {
  my ($ctxt,$refid,$href,$opts)=@_;
  # embed DOM documents
  my $ref_data;
  # if ($opts and $opts->{use_resources}) {
  #   $href = Treex::PML::FindInResourcePaths($href);
  # }

  my ($local_file,$remove_file) = Treex::PML::IO::fetch_file($href);
  my $ref_fh = Treex::PML::IO::open_uri($local_file);
  _die("Cannot open $href for reading") unless $ref_fh;
  _debug("readas_dom: $refid => $href");
  my $parser = $ctxt->{'_parser'} || $ctxt->_xml_parser();
  if ($ref_fh){
    eval {
      $ref_data = $parser->parse_fh($ref_fh, $href);
    };
    _die("Error parsing $href $ref_fh $local_file ($@)") if $@;
    $ref_data->setBaseURI($href) if $ref_data and $ref_data->can('setBaseURI');;
    $parser->process_xincludes($ref_data);
    Treex::PML::IO::close_uri($ref_fh);
    $ctxt->{'_ref'} ||= {};
    $ctxt->{'_ref'}->{$refid}=$ref_data;
    $ctxt->{'_ref-index'} ||= {};
    $ctxt->{'_ref-index'}->{$refid}=_index_by_id($ref_data);
    if ($href ne $local_file and $remove_file) {
      local $!;
      unlink $local_file || _warn("couldn't unlink tmp file $local_file: $!\n");
    }
  } else {
    if ($href ne $local_file and $remove_file) {
      local $!;
      unlink $local_file || _warn("couldn't unlink tmp file $local_file: $!\n");
    }
    _die("Couldn't open '".$href."': $!");
  }
  1;
}

sub _xml_parser {
  my ($self,$opts) = @_;
  my $parser = XML::LibXML->new();
  $parser->keep_blanks(0);
  $parser->line_numbers(1);
  $parser->load_ext_dtd(0);
  $parser->validation(0);
  if (ref($opts) and $parser->can('set_options')) {
    $parser->set_options($opts);
  }
  return $parser;
}

###################################
# CONSTRUCTOR
####################################

sub new {
  my $class = shift;
  _die('Usage: ' . __PACKAGE__ . '->new()') if ref($class);
  return fields::new($class);
}



###################################
# LOAD
###################################

sub load {
  return &Treex::PML::Instance::Reader::load;
}

sub save {
  return &Treex::PML::Instance::Writer::save;
}

sub lookup_id {
  my ($ctxt,$id)=@_;
  my $hash = $ctxt->{'_id-hash'} ||= {};
  return $hash->{ $id };
}

sub hash_id {
  my ($ctxt,$id,$object,$check_uniq) = @_;
  return unless defined($id) and length($id);
  my $prefix = $ctxt->{'_id_prefix'} || '';
  $id = $prefix . $id;
  my $hash = $ctxt->{'_id-hash'} ||= {};
  if ($check_uniq) { # and $prefix eq ''
    my $current = $hash->{$id};
    if (defined $current and $current != $object) {
      _warn("Duplicated ID '$id'");
    }
  }
  if (ref($object)) {
    weaken( $hash->{$id} = $object );
  } else {
    $hash->{$id} = $object;
  }
}

sub _index_by_id {
  my ($dom) = @_;
  my %index;
  $dom->indexElements;
  for my $node (@{$dom->findnodes('//*/@*[name()="id" or name()="xml:id"]')}) {
    $index{ $node->value }=$node->ownerElement;
  }
  return \%index;
}

##########################################
# Validation
#########################################

sub validate_object {
  my ($ctxt, $object, $type, $opts)=@_;
  $type->validate_object($object,$opts);
}

##########################################
# Data pulling
#########################################


sub get_data {
  my ($node,$path, $strict) = @_;
  if (UNIVERSAL::DOES::does($node,'Treex::PML::Instance')) {
    $node = $node->get_root;
  }
  my $val = $node;
  if (!defined $path) {
    carp("Treex::PML::Instance::get_data : undefined attribute path!");
    return;
  }
  for my $step (split /\//, $path) {
    next if $step eq '.';
    my $is_list = UNIVERSAL::DOES::does($val,'Treex::PML::List');
    if ($is_list or UNIVERSAL::DOES::does($val,'Treex::PML::Alt')) {
      if ($step =~ /^\[([-+]?\d+)\]/) {
        $val =
          $1>0 ? $val->[$1-1] :
          $1<0 ? $val->[$1] : undef;
      } elsif ($strict) {
#        warn "Can't follow attribute path '$path' (step '$step')\n";
        return; # ERROR
      } else {
        $val = $val->[0];
        redo unless $step eq ($is_list ? LM : AM);
      }
    } elsif (UNIVERSAL::DOES::does($val,'Treex::PML::Seq')) {
      if ($step =~ /^\[([-+]?\d+)\](.*)/) {
        $val =
          $1>0 ? $val->elements_list->[$1-1] :
          $1<0 ? $val->elements_list->[$1] : undef; # element
        if ($val) {
          if (defined $2 and length $2) { # optional name test
            return if $val->[0] ne $2; # ERROR
          }
          $val = $val->[1]; # value
        }
      } elsif ($step =~ /^([^\[]+)(?:\[([-+]?\d+)\])?/) {
        my $i = $2;
        $val = $val->values($1);
        if ($i ne q{}) {
          $val = $i>0 ? $val->[$i-1] :
                 $i<0 ? $val->[$i] : undef;
        }
      } else {
        return; # ERROR
      }
    } elsif (ref($val)) {
      $val = $val->{$step};
    } elsif (defined($val)) {
#      warn "Can't follow attribute path '$path' (step '$step')\n";
      return; # ERROR
    } else {
      return undef;
    }
  }
  return $val;
}

sub get_all {
  my ($node,$path) = @_;
  if (UNIVERSAL::DOES::does($node,'Treex::PML::Instance')) {
    $node = $node->get_root;
  }
  my @vals = ($node);
  my $val;
  my $redo=0;
  my $dot;
  for my $step (ref($path) ? @$path : (split /\//, $path)) {
    $dot= ($step eq '.');
    next if $dot;
    $redo=0;
    @vals = map {
      $val=$_;
      my $is_list = UNIVERSAL::DOES::does($val,'Treex::PML::List');
      if ($is_list or UNIVERSAL::DOES::does($val,'Treex::PML::Alt')) {
        if ($step =~ /^\[([-+]?\d+)\]/) {
          $1>0 ? $val->[$1-1] :
            $1<0 ? $val->[$1] : ();
        } else {
          $redo=1 unless $step eq ($is_list ? 'LM' : 'AM');
          @$val
        }
      } elsif (UNIVERSAL::DOES::does($val,'Treex::PML::Seq')) {
        #        grep { $_->[0] eq $step } @{$val->[0]}
        if ($step =~ /^\[([-+]?\d+)\](.*)/) {
          $val =
            $1>0 ? $val->elements_list->[$1-1] :
            $1<0 ? $val->elements_list->[$1] : undef; # element
          $val ?
            (defined $2 and length $2) ?
              ($val->[0] eq $2) ? ($val->[1]) : ()
            : $val->[1]
          :()
        } elsif ($step =~ /^([^\[]+)(?:\[([-+]?\d+)\])?/) {
          my $i = $2;
          $val = $val->values($1);
          if (defined $i and length $i) {
             $i>0 ? $val->[$i-1] :
             $i<0 ? $val->[$i] : ();
          } else {
            @$val
          }
        } else { () }
      } elsif (ref($val)) {
        ($val->{$step});
      } else {
        ()
      }
    } @vals;
    redo if $redo;
  }
  return @vals if $dot; # a path may end with a /. to prevent expanding trailing lists and alts
  return map { (UNIVERSAL::DOES::does($_,'Treex::PML::List') or UNIVERSAL::DOES::does($_,'Treex::PML::Alt')) ? __expand_list_alt($_) : ($_) } @vals;
}
sub __expand_list_alt {
  return map { (UNIVERSAL::DOES::does($_,'Treex::PML::List') or UNIVERSAL::DOES::does($_,'Treex::PML::Alt')) ? _expand_list_alt($_) : ($_) } @{$_[0]};
}

sub set_data {
  my ($node,$path, $value, $strict) = @_;
  if (UNIVERSAL::DOES::does($node,'Treex::PML::Instance')) {
    $node = $node->get_root;
  }
  my $val = $node;
  my @steps = split /\//, $path;
  while (@steps) {
    my $step = shift @steps;
    if (UNIVERSAL::DOES::does($val,'Treex::PML::List') or UNIVERSAL::DOES::does($val,'Treex::PML::Alt')) {
      if ($step =~ /^\[([-+]?\d+)\]/) {
        if (@steps) {
          $val =
            $1>0 ? $val->[$1-1] :
            $1<0 ? $val->[$1] : undef;
        } else {
          return
            $1>0 ? ($val->[$1-1]=$value) :
            $1<0 ? ($val->[$1]=$value) : undef;
        }
      } elsif ($strict) {
        my $msg = "Can't follow attribute path '$path' (step '$step')";
        croak $msg if ($strict==2);
        warn $msg."\n";
        return; # ERROR
      } else {
        if (@steps) {
          $val = $val->[0]{$step};
        } else {
          $val->[0]{$step} = $value;
          return $value;
        }
      }
    } elsif (UNIVERSAL::DOES::does($val,'Treex::PML::Seq')) {
      if ($step =~ /^\[([-+]?\d+)\](.*)/) {
        my $i = $1;
        my $el = $i>0 ? $val->elements_list->[$i-1] :
                 $i<0 ? $val->elements_list->[$i] : undef; # element
        if (defined $el and defined $2 and length $2 and $el->[0] ne $2) { # optional name test
          my $msg = "Can't follow attribute path '$path' (step '$step')";
          croak $msg if ($strict==2);
          warn $msg."\n";
          return; # ERROR
        }
        if (@steps) {
          $val = $el->[1];
        } else {
          if (UNIVERSAL::DOES::does($value,'Treex::PML::Seq::Element')) {
            $val = $val->elements_list;
            return
              $i>0 ? ($val->[$i-1]=$value) :
              $i<0 ? ($val->[$i]=$value) : undef;
          } elsif (ref $val->[$i-1]) {
            $el->[1]=$value;
            return $value;
          } else {
            my $msg = "Can't follow attribute path '$path' (no sequence element found at step '$step')";
            croak $msg if ($strict==2);
            warn $msg."\n";
            return; # ERROR
          }
        }
      } elsif ($step =~ /^([^\[]+)(?:\[([-+]?\d+)\])?/) {
        my $i = $2;
        $val = $val->values($1);
        unless (@steps) {
          $val = $1>0 ? $val->[$1-1] :
                 $1<0 ? $val->[$1] : undef;
          if (defined $val) {
            if (UNIVERSAL::DOES::does($value,'Treex::PML::Seq::Element')) {
              $val->[0]=$value->[0];
              $val->[1]=$value->[1];
              return $val;
            } else {
              $val->[1]=$value;
              return $value;
            }
          } else {
            my $msg = "Can't follow attribute path '$path' (no sequence element found at step '$step')";
            croak $msg if ($strict==2);
            warn $msg."\n";
            return; # ERROR
          }
        }
      } else {
        return; # ERROR
      }
    } elsif (ref($val)) {
      if (@steps) {
        if (!defined($val->{$step}) and $steps[0]!~/^\[/) {
          $val->{$step}=Treex::PML::Factory->createStructure();
        }
        $val = $val->{$step};
      } else {
        $val->{$step} = $value;
        return $value;
      }
    } elsif (defined($val)) {
      my $msg = "Can't follow attribute path '$path' (step '$step')";
      croak $msg if ($strict==2);
      warn $msg."\n";
      return; # ERROR
    } else {
      return '';
    }
  }
  return;
}



sub __match_path {
  my ($match_paths, $step)=@_;
  my @r;
  my $s = $step;
  $s =~ s/^\[\d+\]//;
  foreach my $m (@$match_paths) {
    my ($m_step,@rest) = @{$m->[0]};
    if (defined $m_step and length($m_step)==0) {
      # handle //
      push @r,$m, [\@rest=>$m->[1]];
    } elsif ($m_step eq $step or $m_step eq '*') {
      push @r,[\@rest=>$m->[1]];
    } elsif ($m_step !~ /^\[/) {
      if (!length($s)) {
        push @r,$m;
      } elsif ($s eq $m_step) {
        push @r,[\@rest=>$m->[1]];
      }
    }
  }
  return \@r;
}

sub __split_path {
  my @p =  split m{/}, $_[0];
  if (@p>0 and length($p[0])==0) { shift @p; }
  return \@p;
}

sub for_each_match {
  my ($obj,$paths,$opts) = @_;
  $opts||={};
  my @match_paths;
  if (UNIVERSAL::isa($paths,'HASH')) {
    @match_paths = map { [ __split_path($_) => $paths->{$_} ] } keys %$paths;
  } else {
    croak("Usage: \$pml->for_each_match( { path1 => callback1, path2 => callback2,...} )\n".
          "   or: Treex::PML::Instance::for_each_match( \$obj, { path1 => callback1, ... } )\n");
  }
  my $type;
  if (UNIVERSAL::DOES::does($obj,'Treex::PML::Instance')) {
    if (exists $opts->{type}) {
      $type = $opts->{type}
    } else {
      $type = $obj->get_schema->get_root_type
    }
    $obj = $obj->get_root;
  } elsif (exists $opts->{type}) {
    $type = $opts->{type};
  }
  __for_each_match_dispatch('','',\@match_paths,$obj,$type) if @match_paths;
}

sub __for_each_match_dispatch {
  my ($path, $step, $match_paths, $v, $type)=@_;
  $path .= $path eq '/' ? $step : '/'.$step;
  my $match = __match_path($match_paths,$step);
  my @m;
  if (defined $type) {
    my $dt = $type->get_decl_type;
    if ($dt==PML_ATTRIBUTE_DECL ||
        $dt==PML_MEMBER_DECL    ||
        $dt==PML_ELEMENT_DECL) {
      $type = $type->get_content_decl;
    }
  }
  for my $m (@$match) {
    if ( @{$m->[0]}>0 ) {
      push @m, $m;
    } else {
      my $cb = $m->[1];
      my @args;
      if (UNIVERSAL::isa($cb,'ARRAY')) {
        ($cb,@args) = @$cb;
      }
      $cb->({path => $path,  value => $v, type=>$type},@args);
    }
  }
  __for_each_match($path,$v,\@m,$type) if (@m);
}

sub __for_each_match {
  my ($p, $val, $match_paths,$type)=@_;
  if ($val) {
    my $dt = (defined($type)||undef) && $type->get_decl_type;
    if (defined($type) and $dt == PML_ALT_DECL and !UNIVERSAL::DOES::does($val, 'Treex::PML::Alt')) {
      $type=$type->get_content_decl;
      $dt=$type->get_decl_type;
    }
    if ((UNIVERSAL::DOES::does($val, 'Treex::PML::List') or UNIVERSAL::DOES::does($val, 'Treex::PML::Alt'))
        and (!defined($dt) ||
               $dt == PML_LIST_DECL ||
               $dt == PML_ALT_DECL)) {
      my $no = 1;
      my $content_type =(defined($type)||undef) && $type->get_content_decl;
      foreach my $v (@$val) {
        __for_each_match_dispatch($p,"[$no]",$match_paths,
                                  $v,$content_type);
        $no++;
      }
    } elsif ((UNIVERSAL::DOES::does($val, 'Treex::PML::Seq'))
               and (!defined($dt) || $dt == PML_SEQUENCE_DECL)) {
      my $no = 1;
      foreach my $e ($val->elements) {
        my $name = $e->name;
        my $content_type = (defined($type)||undef) && $type->get_element_by_name($name);
        if (!defined($type) || defined($content_type)) {
          __for_each_match_dispatch($p,"[$no]$name",$match_paths,
                                    $e->value, $content_type);
        }
        $no++;
      }
    } elsif (UNIVERSAL::isa($val,'HASH')
        and (!defined($dt)
               || $dt == PML_STRUCTURE_DECL
               || $dt == PML_CONTAINER_DECL)) {
      foreach my $name (keys %$val) {
        my $content_type = (defined($type)||undef) && $type->get_member_by_name($name);
        if (!defined($type) || defined($content_type)) {
          __for_each_match_dispatch($p,$name,$match_paths,$val->{$name},
                                    $content_type);
        }
      }
    }
  }
}
sub get_all_matches {
  my ($obj,$path_list,$opts) = @_;

  unless (UNIVERSAL::isa($path_list,"ARRAY")) {
    if (ref($path_list)) {
      die "Usage: ".__PACKAGE__."::get_all_matches: expected a string or a list, got $path_list";
    } else {
      $path_list = [$path_list];
    }
  }
  my @matches;
  my $sub = sub { push @matches, $_[0] };
  for_each_match($obj, { map { $_=>$sub } @$path_list }, $opts);
  return wantarray ? @matches : \@matches;
}
sub count_matches {
  my ($obj,$path_list,$opts) = @_;

  unless (UNIVERSAL::isa($path_list,"ARRAY")) {
    if (ref($path_list)) {
      die "Usage: ".__PACKAGE__."::get_all_matches: expected a string or a list, got $path_list";
    } else {
      $path_list = [$path_list];
    }
  }
  my $matches;
  my $sub = sub { $matches++ };
  for_each_match($obj, { map { $_=>$sub } @$path_list }, $opts);
  return $matches;
}


sub traverse_data {
  my ($value,$decl,$callback,$opts)=@_;
  $opts||={};
  die "Usage: traverse_data(\$data,\$type_decl,\$callback,\$option_hash)"
    unless blessed($value) and $decl->isa('Treex::PML::Schema::Decl')
      and ref($callback) eq 'CODE'
      and ref($opts) eq 'HASH';
  return _traverse_data($value,$decl,$callback,$opts);
}

sub _traverse_data {
  my ($value,$decl,$callback,$opts)=@_;
  my $decl_is = $decl->get_decl_type;
  my $desc;
  $callback->($value,$decl,$opts->{data});
  if ($decl_is == PML_STRUCTURE_DECL) {
    my @members = $decl->get_members;
    if ($opts->{no_childnodes}) {
      @members = grep {
        my $role = $_->get_role;
        !defined($role) or $role ne '#CHILDNODES'
      } $decl->get_members;
    }
    if ($opts->{no_trees}) {
      @members = grep {
        my $role = $_->get_role;
        !defined($role) or $role ne '#TREES'
      } $decl->get_members;
    }
    for (@members) {
      my $n = $_->get_knit_name;
      my $v = $value->{$n};
      _traverse_data($v,$_->get_knit_content_decl,$callback,$opts) if defined $v;
    }
  } elsif ($decl_is == PML_CONTAINER_DECL) {
    my @attrs = $decl->get_attributes;
    for (@attrs) {
      my $n = $_->get_name;
      my $v = $value->{$n};
      _traverse_data($v,$_->get_content_decl,$callback,$opts) if defined $v;
    }
    my $content_decl = $decl->get_knit_content_decl;
    my $v = $value->{'#content'};
    _traverse_data($v,$content_decl,$callback,$opts) if $v;
  } elsif ($decl_is == PML_SEQUENCE_DECL) {
    my @elems = $decl->get_elements;
    for (@{$value->elements_list}) {
      my $n = $_->name;
      my $v = $_->value;
      my $e = $decl->get_element_by_name($n);
      _traverse_data($v,$e,$callback,$opts) if $v and $e;
    }
  } elsif ($decl_is == PML_LIST_DECL || $decl_is == PML_ALT_DECL) {
    if ($decl_is == PML_ALT_DECL and not UNIVERSAL::DOES::does($value,'Treex::PML::Alt')) {
      $value=Treex::PML::Factory->createAlt([$value],1);
    }
    my $content_decl=$decl->get_knit_content_decl;
    for my $v ($value->values) {
      _traverse_data($v,$content_decl,$callback,$opts) if defined($v);
    }
  } elsif ($decl_is == PML_CHOICE_DECL || $decl_is == PML_CONSTANT_DECL || $decl_is == PML_CDATA_DECL) {
  } else {
    die "unhandled data type: $decl\n";
  }
  return;
}



##########################################
# Convert to Treex::PML::Document
#########################################

sub convert_to_fsfile {
  my ($ctxt,$fsfile,$opts)=@_;

  my $schema = $ctxt->{'_schema'};
  $opts||={};

  unless (ref($fsfile)) {
    $fsfile = Treex::PML::Factory->createDocument({ backend => 'PML' } );
  }

  $fsfile->changeURL( $ctxt->{'_filename'} );
  $fsfile->changeEncoding($DEFAULT_ENCODING);

  if ($schema->isa('Treex::PML::Schema') and not UNIVERSAL::DOES::does($schema, 'Treex::PML::Schema')) {
    # rebless
    require Treex::PML::Schema;
    bless $schema, 'Treex::PML::Schema';
  }
  $fsfile->changeMetaData( 'schema',         $schema                    );
  $fsfile->changeMetaData( 'schema-url',     $ctxt->{'_schema-url'}      );
  $fsfile->changeMetaData( 'schema-inline',  $ctxt->{'_schema-inline'}   );
  $fsfile->changeMetaData( 'pml_transform',  $ctxt->{'_transform_id'}    );
  $fsfile->changeMetaData( 'references',     $ctxt->{'_references'}      );
  $fsfile->changeMetaData( 'refnames',       $ctxt->{'_refnames'}        );
  $fsfile->changeMetaData( 'fs-require',
     [ map { [$_->{id},$_->{href}] } 
         grep { $_->{readas} eq 'trees' } $ctxt->get_reffiles() ]
  );

  $fsfile->changeAppData(  'ref',            $ctxt->{'_ref'} || {}         );
#  $fsfile->changeAppData(  'ref-index',      $ctxt->{'_ref-index'} || {} );
  $fsfile->changeAppData(  'id-hash',        $ctxt->{'_id-hash'}         );

  $fsfile->changeMetaData( 'pml_root',       $ctxt->{'_root'}            );
  $fsfile->changeMetaData( 'pml_trees_type', $ctxt->{'_pml_trees_type'}  );
  $fsfile->changeMetaData( 'pml_prolog',     $ctxt->{'_pml_prolog'}        );
  $fsfile->changeMetaData( 'pml_epilog',     $ctxt->{'_pml_epilog'}        );
  
  if ($ctxt->{'_pi'}) {
    my @patterns = map { $_->[1] } grep { $_->[0] eq 'tred-pattern' } @{$ctxt->{'_pi'}};
    my ($hint) = map { $_->[1] } grep { $_->[0] eq 'tred-hint' } @{$ctxt->{'_pi'}} ;
    for (@patterns, $hint) {
      next unless defined;
      s/&lt;/</g;
      s/&gt;/>/g;
      s/&amp;/&/g;
    }
    $fsfile->changePatterns( @patterns  );
    $fsfile->changeHint( $hint );
  }

  $fsfile->changeTrees( @{$ctxt->{'_trees'}} ) if $ctxt->{'_trees'};

  my @nodes = $ctxt->{'_schema'}->find_role('#NODE');
  my (@order,@hide);
  for my $path (@nodes) {
    my $node_decl = $schema->find_type_by_path($path);
    $node_decl or die "Type-path $path does not lead to anything\n";

    push @order, map { $_->get_name } $node_decl->find_members_by_role('#ORDER');
    push @hide, map { $_->get_name } $node_decl->find_members_by_role('#HIDE' );
  }
  my %uniq;
  @order = grep { !$uniq{$_} && ($uniq{$_}=1) } @order;
  %uniq=();
  @hide = grep { !$uniq{$_} && ($uniq{$_}=1) } @hide;
  if (@order>1) {
    _warn("Treex::PML::Document only supports #ORDER members/attributes with a same name: found {",
          join(',',@order),"}, using $order[0]!");
  }
  if (@hide>1) {
    _warn("Treex::PML::Document only supports #HIDE members/attributes with a same name: found {",
          join(',',@hide),"} $hide[0]!");
  }
  my $defs = $fsfile->FS->defs;
  $defs->{$order[0]} = ' N' if @order;
  $defs->{$hide[0]}  = ' H' if @hide;

  return $fsfile;
}

##########################################
# Convert from Treex::PML::Document
##########################################

sub convert_from_fsfile {
  my ($ctxt,$fsfile)=@_;

  unless (ref($ctxt)) {
    $ctxt = $ctxt->new();
  }

  $ctxt->{'_transform_id'}   = $fsfile->metaData('pml_transform');
  $ctxt->{'_filename'}       = $fsfile->filename;
  $ctxt->{'_schema'}         = $fsfile->metaData('schema');
  $ctxt->{'_root'}           = $fsfile->metaData('pml_root');
  $ctxt->{'_schema-inline'}  = $fsfile->metaData('schema-inline'); # not used anymore
  $ctxt->{'_schema-url'}     = $fsfile->metaData('schema-url');
  $ctxt->{'_references'}     = $fsfile->metaData('references');
  $ctxt->{'_refnames'}       = $fsfile->metaData('refnames');
  $ctxt->{'_pml_trees_type'} = $fsfile->metaData('pml_trees_type');
  $ctxt->{'_pml_prolog'}     = $fsfile->metaData('pml_prolog');
  $ctxt->{'_pml_epilog'}     = $fsfile->metaData('pml_epilog');
  $ctxt->{'_trees'}          = Treex::PML::Factory->createList( $fsfile->treeList );

  $ctxt->{'_refs_save'}      = $fsfile->appData('refs_save');

  $ctxt->{'_ref'}            = $fsfile->appData('ref');
#  $ctxt->{'_ref-index'}      = $fsfile->appData('ref-index');
  $ctxt->{'_id-hash'}        = $fsfile->appData('id-hash');

  my $PIs = $ctxt->{'_pi'} = [];
  for my $pattern ($fsfile->patterns) {
    $pattern =~ s/&/&amp;/g;
    $pattern =~ s/</&lt;/g;
    $pattern =~ s/>/&gt;/g;
    push @$PIs, ['tred-pattern', $pattern];
  }
  my $hint = $fsfile->hint;
  if (defined $hint and length $hint) {
    $hint =~ s/&/&amp;/g;
    $hint =~ s/</&lt;/g;
    $hint =~ s/>/&gt;/g;
    push @$PIs, [ 'tred-hint', $hint ];
  }
  
  return $ctxt;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Treex::PML::Instance - Perl extension for loading/saving PML data

=head1 SYNOPSIS

   use Treex::PML::Instance;

   Treex::PML::AddResourcePath( "$ENV{HOME}/my_pml_schemas" );

   my $pml = Treex::PML::Instance->load({ filename => 'foo.xml' });

   my $schema = $pml->get_schema;
   my $data   = $pml->get_root;

   $pml->save();

=head1 DESCRIPTION

This class provides a simple implementation of a PML instance.

=head1 EXPORT

None by default.

The following export tags are available:

=over 4

=item :constants

Imports the following constants:

=over 8

=item LM

name of the "<LM>" (list-member) tag

=item AM

name of the "<AM>" (alt-member) tag

=item PML_NS

XML namespace URI for PML instances

=item PML_SCHEMA_NS

XML namespace URI for PML schemas

=item SUPPORTED_PML_VERSIONS

space-separated list of supported PML-schema version numbers

=back

=item :diagnostics

Imports internal _die, _warn, and _debug diagnostics commands.

=back


=head1 CONFIGURATION

The option 'config' of the methods load() and save() can provide a
parsed configuration file. The configuration file is a PML instance whose PML
schema is defined in the file C<pmlbackend_conf_schema.xml>
distributed with L<Treex::PML> in
C<Treex/PML/Backend/pmlbackend_conf_schema.xml>.

This file can set defaults for some options of load() and save() and
it can also define rules for pre-processing the input documents before
parsing them as PML and for post-processing the output documents after
serializing them as PML. Currently only XSLT 1.0, Perl and
external-command pre-processing and XSLT 1.0 post-processing are
implemented.

The C<PMLTransform> backend, when intialized (e.g. by calling
by calling C<AddBackend('PMLTransform')>), automatically loads the
first configuration file named C<pmlbackend_conf.xml> it finds in the
C<Treex::PML>'s resource paths.  Additionally, it searches for all
configuration files named C<pmlbackend_conf.inc> in the resource paths
and merges their transformation rules into in-memory image of the main
configuration file. Then, C<PMLTransform>  uses this resulting configuration for all
load/save operations.

IMPORTANT NOTE: it is recommended to add the C<PMLTransform> backend as the last
I/O backend since its test() method automatically accepts any XML file
(with the prospect of attempting to transform it during the read()
phase)! So it B<must> be added into the I/O backends list after all other backends
working with XML-based formats.

Here is an example of a configuration file (see the schema for more
details).

    <?xml version="1.0" encoding="utf-8"?>
    <pmlbackend xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
      <head>
        <schema href="pmlbackend_conf_schema.xml"/>
      </head>
      <options>
        <load>
          <validate_cdata>1</validate_cdata>
          <use_resources>1</use_resources>
        </load>
        <save>
          <indent>4</indent>
          <validate_cdata>1</validate_cdata>
          <write_single_LM>1</write_single_LM>
        </save>
      </options>
      <transform_map>
        <transform id="alpino" test="alpino_ds[@version='1.1' or @version='1.2']">
          <in type="xslt" href="alpino2pml.xsl"/>
          <out type="xslt" href="pml2alpino.xsl"/>
        </transform>
        <transform id="sdata" root="sdata" ns="http://ufal.mff.cuni.cz/pdt/pml/">
          <in type="perl" command="require SDataMerge; return SDataMerge::transform(@_);"/>
        </transform>
        <transform id="tei" test="*[namespace-uri()='http://www.tei-c.org/ns/1.0']">
          <in type="pipe" command="tei2pml.sh">
            <param name="--stdin" />
            <param name="--stdout" />
          </in>
        </transform>
      </transform_map>
    </pmlbackend>

=head1 METHODS

=over 3

=item Treex::PML::Instance->new ()

NOTE: Don't call this constructor directly, use
Treex::PML::Factory->createPMLInstance() instead!

Create a new empty PML instance object.

=item Treex::PML::Instance->load (\%opts)

=item $pml->load (\%opts)

NOTE: Don't call this method as a constructor directly, use
Treex::PML::Factory->createPMLInstance() instead!

Read a PML instance from file, filehandle, string, or DOM.  This
method may be used both on an existing object (in which case it
operates on and returns this object) or as a constructor (in which
case it creates a new C<Treex::PML::Instance> object and returns it). Possible
options are: 

  {
    filename => $filename,   # and/or
    fh => \*FH,              # or
    string => $xml_string,   # or
    dom => $document,        # (XML::LibXML::Document)

    config => $cfg_pml,      # (Treex::PML::Instance)

    parser_options => \%opt, # (XML::LibXML parser options)
    no_trees => $bool,
    no_references => $bool,
    no_knit => $bool,
    selected_references => { name => $bool, ... },
    selected_knits => { name => $bool, ... }
  }

where C<filename> may be used either by itself or in combination with
any of C<fh> , C<string>, or C<dom>, which are otherwise mutually
exclusive. The C<config> option may be used to pass a C<Treex::PML::Instance>
with the parsed PML backend configuration file (see L</CONFIGURATION>).  The
C<parser_options> option may be used to pass a HASH reference
containing options for the XML::LibXML parser (depending on
implementation, these will be used to configure either an
XML::LibXML::Reader or an XML::LibXML::Parser).  If C<no_trees> is
true, then the roles #TREES, #NODE and #CHILDNODES are ignored.  The
option C<selected_references> determines which reffiles (with
non-empty readas attribute) to read; if true, the reffile with a given
name is read, if false, it is never read; if a value is not given for
some reffile, the reffile is read unless the C<no_references> flag is
on.  The options C<selected_knits> and C<no_knits> determine data from
which reffiles can be copied into this document following the rules
for the role #KNIT. Their meaning is just like that for
C<selected_references> and C<no_references>.  Moreover,
C<no_references> implies C<no_knit>, unless C<no_knit> is explicitly
specified.

=item $pml->get_status ()

Returns 1 if the last load() was successful.

=item $pml->save (\%opts)

Save PML instance to a file or file-handle. Possible options are:
C<filename, fh, config, refs_save, write_single_LM>.  If both
C<filename> and C<fh> are specified, C<fh> is used, but the filename
associated with the C<Treex::PML::Instance> object is changed to C<filename>.  If
neither is given, the filename currently associated with the
C<Treex::PML::Instance> object is used. The C<config> option may be used to pass a
C<Treex::PML::Instance> representing the parsed PML backend configuration file
(see L</CONFIGURATION>).  The C<refs_save> option may be used to
specify which reference files should be saved along with the
C<Treex::PML::Instance> and where to. The value of C<refs_save>, if given, should
be a HASH reference mapping reference IDs to the target URLs
(filenames). If C<refs_save> is given, only those references listed in
the HASH are saved along with the C<Treex::PML::Instance>. If C<refs_save> is
undefined or not given, all references are saved (to their original
locations). In both cases, only files declared as readas='dom' or
readas='pml' can be saved.

=item $pml->convert_to_fsfile (fsfile)

Translates the current C<Treex::PML::Instance> object to a C<Treex::PML::Document> object
(using L<Treex::PML::Document> MetaData and AppData fields for storage of non-tree
data). If fsfile argument is not provided, creates a new C<Treex::PML::Document> object,
otherwise operates on a given fsfile. Returns the resulting C<Treex::PML::Document> object.

=item $pml->convert_from_fsfile (fsfile)

=item Treex::PML::Instance->convert_from_fsfile (fsfile)

Translates a C<Treex::PML::Document> object to a C<Treex::PML::Instance> object. Non-tree
data are fetched from Treex::PML::Document MetaData and AppData fields. If called
on an instance, modifies and returns the instance, otherwise creates
and returns a new instance.

=item Treex::PML::Instance::get_data ($obj,$path)

Retrieve a possibly nested value from the attribute data structure of
$obj.  The path argument uses an XPath-like expression of the form

   step1/step2/...

where each step (depending on the value retrieved by the preceding
part of the expression) can be one of:

=over 8

=item name of a member of a structure 

to retrieve that member

=item name of an attribute of a container 

to retrieve that attribute

=item name of an element of a sequence 

to retrieve the first element of that name

=item index of the form [n] 

to retrieve n-th element /counting from 1/ from a list, sequence, or an alternative

=item combination of name and index of the form name[n]

to retrieve n-th element named 'name' from a sequence

=item combination of index and name of the form [n]name

to retrieve the n-th element of a sequence provided the n-th element's
name is 'name'

=back

In the preceding cases, [n] can be negative, in which case the
retrieved value is the n-th element from the end of the list or
sequence.

If a step of the form [n] is not given for a list or
alternative value then [1] is assumed and the next step is processed.

If the value retrieved by some step is undefined or the step does not
match the data type of the value retrieved by the preceding steps, the
evaluation is stopped and undef is returned.

For example,

  my $value = Treex::PML::Instance::get_data($obj,'foo/bar[2]/[-4]/baz/[5]bam');

is roughly equivalent to

  my $el = $obj->{foo}->values('bar')->[1]->[-4]->{baz}->[4];
  my $value = $el->name eq 'bam' ? $el->value : undef;

but without the side effect of creating array or hash structures where
there is none. To be more specific, if, say $obj->{x} is not defined,
then the Perl expression

   if ($obj->{x}[3]{y}) {...}

automatically causes a side-effect of creating an ARRAY reference in
$obj->{x} and a HASH reference in the fourth element of this
ARRAY. An analogous construct

   Treex::PML::Instance::get_data($obj,'foo/[4]/baz');

simply returns undef without either of these side-effects.

The following behave the same (provided that the path /foo/bar[2]
retrieves a list, sequence or an alternative and /foo/bar[2]/[1]/baz
retrieves a sequence):

  my $value = Treex::PML::Instance::get_data($obj,'foo/bar[2]/[1]/baz/[1]bam');
  my $value = Treex::PML::Instance::get_data($obj,'foo/bar[2]/baz/bam');


=item Treex::PML::Instance::get_all($obj, $path)

This function returns all matches of a given attribute path on the
object. It works just as C<Treex::PML::Instance>::get_data except that it recurses
into all values of a list, alt or sequence instead of just the first
one on attribute-path steps that do not give an exact
index. Furthermore, unlike C<Treex::PML::Instance::get_data>, this functions
does expands trailing Lists and Alts, which means this:
If the path leads to a List or Alt value, the members values
are returned instead; this replacement is applied recursively.

The expansion of trailing Lists and Alts can be prevented by appending
a slash followed by a dot to the attribute path ("$path/.").


=item Treex::PML::Instance::set_data ($obj,$path,$value,$strict?)

Store a given value to a possibly nested attribute of $obj specified
by path. The path argument uses the XPath-like syntax described above
for the method C<Treex::PML::Instance::get_data>. If $strict==0 and a non-index step is to be
processed on an alternative or list, then step [1] is assumed and the
1st element of the list or alternative is used for further processing
of the path expression (except when this occurs in the last step, in
which case the entire list or alternative is overwritten by the given
value). If $strict==1 and a non-index step is to be processed on an
alternative or list, a warning is issued and undef is returned. If
$strict==2, the same approach as with $strict==1 is taken, but croak is
used instead of warn.

=item $pml->for_each_match( { path1 => callback1, path2 => callback2,...})

=item Treex::PML::Instance::for_each_match( $obj, { path1 => callback1, path2 => callback2,...}, \%opts )

This function traverses a given PML data structure and dispatches
callbacks at all occurrences of given attribute paths.

If called on other object that C<Treex::PML::Instance> (i.e. L<Treex::PML::Struct>,
L<Treex::PML::List>, etc.), the corresponding data type (Treex::PML::Schema::*
object) can be provided in the \%opts argument as

   { type => $type_decl }

The callback gets one argument: a hash reference of the form

  { value => $matched_obj, path => $matched_obj_path, type => $obj_type_decl }

where $matched_obj_path is full canonical path to the matching
object. The type key is present in hash only if C<for_each_match> was
called on a C<Treex::PML::Instance> or if Treex::PML::Schema type of the initial object was
given in \%opts.

The path syntax is as described in C<Treex::PML::Instance::get_data>, with the
following differences:

1. Path steps of the form [n] or name[n], where n is a number, are not
supported (but steps of the form [n]name work).

2. Additionally, steps can be separated with //. Like in XPath, this
indicates a descendant axis, that allows arbitrary structures between
the steps. I.e. a//z matches any data matched by a/z, a/b/z, /a/b/c/z,
etc.  One can also use // at the very beginning of an expression
(//a/b) to match arbitrarily nested occurrence of a/b (e.g. one
matching x/y/z/a/b).

=item Treex::PML::Instance::get_all_matches($obj,$path,\%opts)

=item Treex::PML::Instance::get_all_matches($obj,\@path_list,\%opts)

This function returns all data matching given path or, if the second
argument is an array reference, any of given paths. The path(s), as
well as $obj and \%opts argument are as in
C<Treex::PML::Instance::for_each_match>. The function returns an array in
array context and an array reference in scalar context.

=item Treex::PML::Instance::count_matches($obj,$path,\%opts)

=item Treex::PML::Instance::count_matches($obj,\@path_list,\%opts)

Like C<Treex::PML::Instance::get_all_matches>, but returns only the number of
matching objects (without creating any intermediate list).

=item Treex::PML::Instance::traverse_data($object, $type_decl, $callback, \%options)

Traverses the nested PML content of the given Treex::PML data object
(C<Treex::PML::Instance>, L<Treex::PML::Node>, L<Treex::PML::Struct>,
etc.). The second argument must be the type of $object, i.e. a
L<Treex::PML::Schema::Decl> (or derived). The $callback is an CODE
reference (anonymous function) which will get called for each nested
value with the following arguments: the value, type declaration for
the value (a L<Treex::PML::Schema::Decl>), and the value of
$options{data} passed in by the caller to this method.

Options:

C<no_childnodes>: do not descend into child nodes (role #CHILDNODES)

C<no_trees>: do not descend into lists or sequences with the role #TREE

C<data>: user data passed to the callback

=item $class_or_instance->validate_object($object, $decl, \%options)

Convenience function which currently just calls:

  $decl->validate_object($object,\%options).

in order to determine, if the object conforms to the data type
declaration.

=item $pml->hash_id (id,object,warn)

Hash a given object under a given ID. If warn is true, then a warning
is issued if the ID already wash hashed with a different object.

=item $pml->lookup_id (id)

Lookup an object by ID.

=item $pml->get_filename ()

Return the filename (string) or URL (URI object) of the PML instance.

=item $pml->get_url ()

Return URL of the PML instance as URI object.

=item $pml->set_filename (filename)

Change filename of the PML instance.

=item $pml->get_transform_id ()

Return ID of the XSL-based transformation specification which was used
to convert between an original non-PML format and PML (and back).

=item $pml->set_transform_id (transform)

Set ID of an XSL-transformation specification which is to be used for
conversion from PML to an external non-PML format (and back).

=item $pml->get_schema ()

Return C<Treex::PML::Schema> object associated with the PML instance.

=item $pml->set_schema (schema)

Associate a C<Treex::PML::Schema> with the PML instance (this method should
not be used for an instance containing data).

=item $pml->get_schema_url ()

Return URL of the PML schema file associated with the PML instance.

=item $pml->set_schema_url (url)

Change URL of the PML schema file associated with the PML instance.

=item $pml->get_root ()

Return the root data structure.

=item $pml->set_root (object)

Set the root data structure.

=item $pml->get_trees ()

Return a L<Treex::PML::List> object containing data structures with role
'#NODE' belonging in the first block (list or sequence) with role
'#TREES' occuring in the PML instance.

=item $pml->get_trees_prolog ()

If the PML instance consists of a sequence with role '#TREES', return a
L<Treex::PML::Seq> object containing the maximal (but possibly empty)
initial segment of this sequience consisting of elements with role
other than '#NODE'.

=item $pml->get_trees_epilog ()

If the PML instance consists of a sequence with role '#TREES', return
a L<Treex::PML::Seq> object containing all elements of the sequence
following the first maximal contiguous subsequence of elements with
role '#NODE'.

=item $pml->get_trees_type ()

Return the type declaration associated with the list of trees.

=item $pml->get_references_hash ()

Returns a HASHref mapping file reference IDs to URLs.

=item $pml->set_references_hash (\%map)

Set a given HASHref as a map between refrence IDs and URLs.

=item $pml->get_ref_ids_by_name ($name)

Returns a list of reference IDs associated with a given name.

=item $pml->get_refs_by_name ($name)

Returns a list of references associated with a given name.

=item $pml->get_reffiles ()

Returns a list of hash references. Each element represents a document
referenced from the current instance.  The list contains only
references that were associated with a name (pre-declared in the PML
schema). However, a 'name' can be associated with several document
references. The elements in the list returned by this method have the
following keys:

=over 10

=item readas

the value of the 'readas' attribute of the corresponding PML schema declaration

=item name

the symbolic name of the (type of the) reference as declared in the
PML schema

=item href

an URI of the target document

=item id

an ID use in the current PML instance to refer to the target document

=back


=item $pml->get_refname_hash ()

Returns a HASHref mapping file reference names to reference IDs.  Each
value of the hash is either a ID string (if there is just one
reference with a given name) or a L<Treex::PML::Alt> containing all IDs
associated with a given name.


=item $pml->set_refname_hash (\%map)

Set a given HASHref as a map between refrence IDs and URLs.

=item $pml->get_ref (id)

Return a DOM or C<Treex::PML::Instance> object representing the referenced
resource with a given ID (applies only to resources declared as
readas='dom' or readas='pml').

=item $pml->set_ref (id,object)

Use a given DOM or C<Treex::PML::Instance> object as a resource of the current
C<Treex::PML::Instance> with a given ID (note that this may break knitting).

=back

=head1 SEE ALSO

Prague Markup Language (PML) format:
L<http://ufal.mff.cuni.cz/jazz/PML/>

Tree editor TrEd: L<http://ufal.mff.cuni.cz/tred>

Related packages: L<Treex::PML>, L<Treex::PML::Schema>, L<Treex::PML::Document>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
