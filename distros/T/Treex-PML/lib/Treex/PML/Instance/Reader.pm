package Treex::PML::Instance::Reader;
{
use 5.008;
use strict;
use warnings;
no warnings qw(recursion);
use Scalar::Util qw(blessed);
use UNIVERSAL::DOES;

use Carp;
use Data::Dumper;

BEGIN {
  our $VERSION = '2.22'; # version template
}
use List::Util qw(first);
use Scalar::Util qw(weaken);
use Treex::PML::Instance::Common qw(:diagnostics :constants);
use Treex::PML::Schema;
use XML::LibXML::Reader;
use Treex::PML::IO qw(open_uri close_uri rename_uri);
use Encode;

use constant {
  XAT_TYPE  => 0,
  XAT_NAME  => 1,
  XAT_VALUE => 1,
  XAT_NS  => 2,
  XAT_ATTRS => 3,
  XAT_CHILDREN => 5,
  XAT_LINE => 4,
};

our $STRICT =1;
our $XTC_FLAGS;
use vars qw( $HAVE_XS );
BEGIN {
  if (!$ENV{PML_COMPILE_NO_XS} && eval {
    require XML::CompactTree::XS;
    import XML::CompactTree::XS;
    $HAVE_XS = 1;
    1;
  }) {
    # print STDERR "Using XML::CompactTree::XS\n" if $HAVE_XS;
    $XTC_FLAGS = XML::CompactTree::XS::XCT_ATTRIBUTE_ARRAY()|
                 XML::CompactTree::XS::XCT_LINE_NUMBERS()|
                 XML::CompactTree::XS::XCT_IGNORE_COMMENTS();
  } else {
    require XML::CompactTree;
    import XML::CompactTree;
    $XTC_FLAGS = XML::CompactTree::XCT_ATTRIBUTE_ARRAY()|
                 XML::CompactTree::XCT_LINE_NUMBERS()|
                 XML::CompactTree::XCT_IGNORE_COMMENTS();
    $HAVE_XS = 0;
  }
}

my (%handlers,%src,
    %handler_cache,@handler_cache,
    %schema_cache,@schema_cache
   );

# TODO:
# - create one handler per cdata+format type
# - test inline schemas

our $CACHE_HANDLERS=1;
our $CACHE_SCHEMAS=1;
our $MAX_SCHEMA_CACHE_SIZE=50;

our $VALIDATE_CDATA=0;
our $VALIDATE_SEQUENCES=1;
our $BUILD_TREES = 1;
our $LOAD_REFFILES = 1;
our $KNIT = 1;

our $READER_OPTS = {
  no_cdata => 1,
  clean_namespaces => 1,
  expand_entities => 1,
  expand_xinclude => 1,
  no_xinclude_nodes => 1,
};

require Treex::PML;

sub _get_handlers_cache_key {
  my ($schema)=@_;
  my $key="$schema"; $key=~s/.*=//; # strip class
  return
    [
      $key,
      join ',',
      $key,
      $VALIDATE_CDATA || 0,
      $VALIDATE_SEQUENCES || 0,
      $BUILD_TREES || 0,
      $LOAD_REFFILES || 0,
      $KNIT || 0,
      $Treex::PML::Node::TYPE,
      $Treex::PML::Node::lbrother,
      $Treex::PML::Node::rbrother,
      $Treex::PML::Node::parent,
      $Treex::PML::Node::firstson,
     ];
}

sub _get_schema_cache_key {
  my ($schema_file)=@_;
  if ((blessed($schema_file) and $schema_file->isa('URI'))) { # assume URI
    if (($schema_file->scheme||'') eq 'file') {
      $schema_file = $schema_file->file
    } else {
      return '0 '.$schema_file;
    }
  }
  if (-f $schema_file) {
    my $mtime = (stat $schema_file)[9];
    return $mtime.' '.$schema_file;
  }
}

sub get_cached_schema {
  my ($schema_file)=@_;
  return unless defined $schema_file;
  my $cached = $schema_cache{$schema_file};
  if ($cached and $schema_cache[-1] ne $schema_file) {
    # move the last retrieved schema to the end of the queue
    @schema_cache = ((grep { $_ ne $schema_file } @schema_cache),$schema_file);
  }
  return $cached;
}

sub cache_schema {
  my ($key,$schema)=@_;
  push @schema_cache,$key;
  $schema_cache{$key} = $schema;
  if (@schema_cache > $MAX_SCHEMA_CACHE_SIZE) {
    my $del = delete $schema_cache{ shift @schema_cache };
    delete $handler_cache{ $del }; # delete also from the handler cache
    @handler_cache = grep { $_->[0] ne $del } @handler_cache;
    if (exists &Treex::PML::Instance::Writer::forget_schema) {
      Treex::PML::Instance::Writer::forget_schema($schema);
    }
  }
}

sub get_cached_handlers {
  my ($key)=@_;
  my $subkey = $key->[1];
  my $cached = $handler_cache{ $key->[0] }{ $subkey };
  if ($cached and $handler_cache[-1][1] ne $subkey) {
    # move the last retrieved schema to the end of the queue
    @handler_cache = ((grep { $_->[1] ne $subkey } @handler_cache),$key);
  }
  return $cached;
}

sub cache_handlers {
  my ($key,$handlers)=@_;
  my $subkey = $key->[1];
  push @handler_cache,$key;
  $handler_cache{$key->[0]}{$subkey} = $handlers;
  if (@handler_cache > $MAX_SCHEMA_CACHE_SIZE) {
    my $del = shift @handler_cache;
    delete $handler_cache{ $del->[0] }{ $del->[1] };
  }
}

sub load {
  my $ctxt = shift;
  my $opts = shift;
  if (ref($opts) ne 'HASH') {
    croak("Usage: Treex::PML::Instance->load({option=>value,...})\n");
  }
  if (!ref($ctxt)) {
    $ctxt = Treex::PML::Factory->createPMLInstance;
  }
  my $config = $opts->{config};
  if ($config and ref(my $load_opts = $config->get_data('options/load'))) {
    $opts = {%$load_opts, %$opts};
  }
  $Treex::PML::Instance::DEBUG = $config->get_data('options/debug') if (!$Treex::PML::Instance::DEBUG and $config and defined($config->get_data('options/debug')));

  local $READER_OPTS = { %$READER_OPTS, %{$opts->{parser_options} || {}} };

  if (exists $opts->{filename}) {
    $ctxt->set_filename( $opts->{use_resources}
                           ? Treex::PML::FindInResourcePaths($opts->{filename})
                           : $opts->{filename}
                       );
  }
  my $reader;
  my $fh_to_close;
  # print Dumper($opts),"\n";
  if (defined $opts->{dom}) {
    $reader = XML::LibXML::Reader->new(DOM => delete $opts->{dom}, %$READER_OPTS);
  } elsif (defined $opts->{fh}) {
    $reader = XML::LibXML::Reader->new(IO => $opts->{fh}, %$READER_OPTS,
                                       URI => $ctxt->{'_filename'},
                                       %$READER_OPTS
                                      );
  } elsif (defined $opts->{string}) {
    $reader = XML::LibXML::Reader->new(string => $opts->{string}, %$READER_OPTS,
                                       URI => $ctxt->{'_filename'},
                                       %$READER_OPTS
                                      );
  } elsif (defined $ctxt->{_filename}) {
    if ($ctxt->{_filename} eq '-') {
      $reader = XML::LibXML::Reader->new(FD => \*STDIN,
                                         %$READER_OPTS,
                                        );
    } else {
      $fh_to_close = open_uri($ctxt->{_filename});
      $reader = XML::LibXML::Reader->new(FD => $fh_to_close,
                                         URI => $ctxt->{_filename},
                                         %$READER_OPTS,
                                        );
    }
  } else {
    croak("Treex::PML::Instance->load: at least one of filename, fh, string, or dom arguments are required!");
  }
  eval {
  # check NS
  $reader->nextElement();
  my @transform_map =
    grep {
      my $id = $_->{id};
      if (defined($id) and length($id)) {
        $_
      } else {
        warn(__PACKAGE__.": Skipping PML transform in ".$config->get_url." (required attribute id missing):".Dumper($_));
        ()
      }
    }
    (eval {
      ($config and $config->get_root) ? $config->get_root->{transform_map}->values : ()
    });
  my $root_element = $reader->localName;
  my $root_ns = $reader->namespaceURI || '';
  if ($root_ns ne PML_NS
        or grep { (($_->{ns}||'') eq PML_NS and ($_->{root}||'') eq $root_element) } @transform_map) {
      if ($config and $config->get_root) {
      # TRANSFORM
      $reader->preserveNode;
      $reader->finish;
      my $dom = $reader->document;
      foreach my $transform (@transform_map) {
        my $id = $transform->{'id'};
        my ($in_xsl) = $transform->{in};
        my $type = $in_xsl && $in_xsl->{'type'};
        next unless ($type and $type =~ /^(?:xslt|perl|pipe|shell)$/);
        my $test = $transform->{'test'};
        _debug("Trying transformation rule '$id'");
        if (($test or $transform->{ns} or $transform->{root})
            and (!$transform->{ns} or $transform->{ns} eq $root_ns)
            and (!$transform->{root} or $transform->{root} eq $root_element)
            and !$test or eval { $dom->find($test) }) {
          if ($type eq 'xslt') {
            die "Buggy libxslt version 10127\n" if XSLT_BUG;
            if (eval { require XML::LibXSLT; 1 }) {
              my $in_xsl_href = URI->new(Encode::encode_utf8($in_xsl->get_member('href')));
              next unless $in_xsl_href;
              _debug("Transforming to PML with XSLT '$in_xsl_href'");
              $ctxt->{'_transform_id'} = $id;
              my $params = $in_xsl->content;
              my %params;
              %params = map { $_->{'name'} => $_->value } $params->values if $params;
              $in_xsl_href = Treex::PML::ResolvePath($config->{'_filename'}, $in_xsl_href, 1);
              my $xslt = XML::LibXSLT->new;
              my $in_xsl_parsed = $xslt->parse_stylesheet_file($in_xsl_href)
                || die("Cannot locate XSL stylesheet '$in_xsl_href' for transformation $id\n");
              $dom = $in_xsl_parsed->transform($dom,%params);
              $dom->setBaseURI($ctxt->{'_filename'}) if $dom and $dom->can('setBaseURI');
              $dom->setURI($ctxt->{'_filename'}) if $dom and $dom->can('setURI');
              $reader = XML::LibXML::Reader->new(DOM => $dom);
              $reader->nextElement();
              last;
            } else {
              warn "Cannot use XML::LibXSLT for transformation!\n";
            }
          } elsif ($type eq 'perl') {
            my $code = $in_xsl->get_member('command');
            next unless $code;
            _debug("Transforming to PML with Perl code: $code");
            $ctxt->{'_transform_id'} = $id;
            my $params = $in_xsl->content;
            my %params;
            %params = map { $_->{'name'} => $_->value } $params->values if $params;
            $dom = perl_transform($code, $dom, %params);
            die("Perl-based transformation '$id' failed: $@") if $@;
            die("Perl-based transformation didn't return a XML::LibXML::Document object!\n") unless
              (blessed($dom) and $dom->isa('XML::LibXML::Document'));
            $dom->setBaseURI($ctxt->{'_filename'}) if $dom and $dom->can('setBaseURI');
            $dom->setURI($ctxt->{'_filename'}) if $dom and $dom->can('setURI');
            $reader = XML::LibXML::Reader->new(DOM => $dom);
            $reader->nextElement();
            last;
          } elsif ($type eq 'pipe' or $type eq 'shell') {
            my $code = $in_xsl->get_member('command');
            next unless $code;
            _debug("Transforming to PML with $type code: $code");
            $ctxt->{'_transform_id'} = $id;
            my $params = $in_xsl->content;
            my @params;
            @params = grep {defined and length } map { $_->{'name'} => $_->value } $params->values if $params;
            my $tmp_file_in;
            if ($type eq 'pipe') {
              (my $fh, $tmp_file_in) = File::Temp::tempfile();
              $dom->toFH($fh);
              close $fh;
            } else {
              push @params, $dom->URI;
            }
            my $tmp_file_out;
            {
              local *OLDIN;
              local *OLDOUT;
              open OLDOUT,"<&STDOUT";
              open OLDIN,"<&STDIN";

              if ($type eq 'pipe') {
                open STDIN, '<', $tmp_file_in;
              } else {
                close STDIN;
              }
              (undef, $tmp_file_out) = File::Temp::tempfile();
              open STDOUT, '>', $tmp_file_out;
              system($code,@params);
              unlink $tmp_file_in if $tmp_file_in;
              open STDIN,"<&OLDIN";
              open STDOUT,">&OLDOUT";
            }
            {
              open(my $fh, '<', $tmp_file_out) or die("Failed to read output from pipe transformation: $code\n");
              unlink $tmp_file_out if $tmp_file_out;
              $reader = XML::LibXML::Reader->new(IO => $fh, URI => $ctxt->{'_filename'});
            }
            $reader->nextElement();
            last;
          }
        } else {
          _debug("failed");
        }
      }
    }
    if (($reader->namespaceURI||'') ne PML_NS) {
      my $f = $ctxt->{'_filename'} || '';
      die("Root element of '$f' isn't in PML namespace: '".($reader->localName()||'')."' ".($reader->namespaceURI()||''))
    }
  }

  $ctxt->{_root} = read_header($ctxt,$reader,$opts);
  my $schema = $ctxt->{'_schema'};
  unless (ref($schema)) {
    die("Instance doesn't provide PML schema!");
  }
  unless (length($schema->{version}||'')) {
    die("PML Schema file ".$ctxt->{'_schema-url'}." does not specify version!");
  }
  if (index(SUPPORTED_PML_VERSIONS," ".$schema->{version}." ")<0) {
    die("Unsupported PML Schema version ".$schema->{version}." in ".$ctxt->{'_schema-url'});
  }

  {
    # preprocess the options selected_references and selected_keys:
    # we map the reffile names to reffile id's
    my $sel_knit = ($ctxt->{_selected_knits} =
                      $opts->{selected_knits});
    my $sel_refs = ($ctxt->{_selected_references} =
                      $opts->{selected_references});
    croak("Treex::PML::Instance->load: selected_knits must be a Hash ref!")
      if defined($sel_knit) && ref($sel_knit) ne 'HASH';
    croak("Treex::PML::Instance->load: selected_references must be a Hash ref!")
      if defined($sel_refs) && ref($sel_refs) ne 'HASH';
    ($ctxt->{'_selected_knits_ids'},
     $ctxt->{'_selected_references_ids'}) = map {
       my $sel = $_;
       my $ret = {
         (defined($sel) ?
           (map {
             my $ids = $ctxt->{'_refnames'}->{$_};
             my $val = $sel->{$_};
             map { $_=>$val }
               defined($ids) ? (ref($ids) ? @$ids : ($ids)) : ()
           } keys %$sel) : ())
        };
       $ret
     } ($sel_knit,$sel_refs);
  }

  $ctxt->read_reffiles({use_resources=>$opts->{use_resources}});
  $ctxt->{'_no_read_trees'} = $opts->{no_trees};
  local $BUILD_TREES = $opts->{no_trees} ? 0 : 1;
  local $LOAD_REFFILES = $opts->{no_references} ? 0 : 1;
  local $KNIT = $opts->{no_knit} ? 0 : $LOAD_REFFILES;
  local $VALIDATE_CDATA =$opts->{validate_cdata} ? 1 : 0;
  local $VALIDATE_SEQUENCES =$opts->{ignore_content_patterns} ? 0 : 1;
  $ctxt->{'_id-hash'}={};

  prepare_handlers($ctxt);
  dump_handlers($ctxt) if $opts->{dump_handlers} or $ENV{PML_COMPILE_DUMP};
  load_data($ctxt,$reader,$opts);
  while ($reader->read) {
    if ($reader->nodeType == XML_READER_TYPE_PROCESSING_INSTRUCTION) {
      push @{$ctxt->{'_pi'}}, [ $reader->name,$reader->value ];
    }
  }

  $handlers{'#initialize'}->($ctxt);
  $ctxt->{_root} = $handlers{'#root'}->($ctxt->{_root});
  };
  ($handlers{'#cleanup'}||sub{})->();
  %handlers=();
  close_uri($fh_to_close) if defined $fh_to_close;
  die $@ if $@;
  $ctxt->{'_parser'} = undef;
  return $ctxt;
}

######################################################
# $ctxt

sub _reader_address {
  my ($ctxt,$reader)=@_;
  my $line_number=$reader->lineNumber;
  return " at ".$ctxt->{'_filename'}." line ".$line_number."\n";
}

sub read_header {
  my ($ctxt,$reader,$opts)=@_;

  # manually extract the root node
  my $root = [XML_READER_TYPE_ELEMENT,
              $reader->localName,
              undef,
             ];
  # read root node attributes
  $root->[XAT_LINE] = 0;
  $root->[XAT_ATTRS] = readAttributes($reader);
  my $found_head = 0;
  while ($reader->read == 1) {
    my $type = $reader->nodeType;
    if ($type == XML_READER_TYPE_TEXT) { # no CDATA
      die "Unexpected content of a root element preceding <head>"._reader_address($ctxt,$reader);
    } elsif ($type == XML_READER_TYPE_ELEMENT) {
      if ($reader->localName eq 'head' and $reader->namespaceURI eq PML_NS) {
        # we have head!
        $found_head = 1;
        last;
      } else {
        die "Unexpected element '".$reader->name."' precedes PML header <head>"._reader_address($ctxt,$reader);
      }
    }
  }
  unless ($found_head) {
    die "Did not find PML <head> element: the document '".$ctxt->{_filename}."' is not a PML instance!";
  }

  my (%references,%named_references);
  while ($reader->read == 1) {
    last if $reader->depth<=1;
    my $type = $reader->nodeType;
    if ($type == XML_READER_TYPE_ELEMENT and $reader->namespaceURI eq PML_NS) {
      my $name = $reader->localName;
      if ($name eq 'schema') {
        if ($ctxt->{'_schema'}) {
          warn "Multiple <schema> elements in a PML <head>!";
          $reader->nextSibling || last;
          redo;
        }
        # read schema here:
        my %a = @{ readAttributes($reader) || [] };
        my $schema_file = delete $a{href};
        if (defined $schema_file and length $schema_file) {
          $schema_file = URI->new(Encode::encode_utf8($schema_file));
          # print "$schema_file\n";
          $ctxt->{'_schema-url'} = $schema_file; # store the original URL, not the resolved one!
          my $schema_path = Treex::PML::ResolvePath($ctxt->{'_filename'},$schema_file,1);
          my $key = _get_schema_cache_key($schema_path);
          if (!($ctxt->{'_schema'}=get_cached_schema($key))) {
            # print "loading schema $schema_path\n";
            $ctxt->{'_schema'} =
              Treex::PML::Factory->createPMLSchema({
                filename => $schema_path,
                use_resources => 1,
                revision_error =>
                  "Error: ".$ctxt->{'_filename'}." requires different revision of PML schema %f: %e\n",
                %a, # revision_opts
              });
            cache_schema($key, $ctxt->{'_schema'}) if $CACHE_SCHEMAS;
          }
        } else {
          # inline schema
          $ctxt->{'_schema'} = Treex::PML::Factory->createPMLSchema({
            reader=>$reader,
            base_url => $ctxt->{'_filename'},
            use_resources => 1,
            revision_error =>
              "Error: ".($ctxt->{'_filename'}||'document')." requires different revision of PML schema %f: %e\n",
            %a, # revision_opts
          });
        }
      } elsif ($name eq 'references') {
        if ($reader->read) {
          while ($reader->depth==3) {
            if ($reader->localName eq 'reffile' and
                  $reader->namespaceURI eq PML_NS) {
              my %a = @{ readAttributes($reader) || [] };
              my ($id,$name,$href) = @a{qw(id name href)};
              if (defined($id) and length($id) and
                    defined($href) and length($href)) {
                if (defined $name and length $name) {
                  my $prev_ids = $named_references{ $name };
                  if (defined $prev_ids) {
                    if (ref($prev_ids)) {
                      push @$prev_ids,$id;
                    } else {
                      $named_references{ $name }=Treex::PML::Factory->createAlt([$prev_ids,$id],1);
                    }
                  } else {
                    $named_references{ $name } = $id;
                  }
                }
                # Encode: all filenames must(!) be bytes
                $references{$id} = Treex::PML::ResolvePath
                  ($ctxt->{'_filename'},
                   URI->new(Encode::encode_utf8($href)),
                   $opts->{use_resources});
                # Resources are not used for non-readas references,
                # though, they must be handled manually.
              } else {
                warn "Missing id or href attribute on a <reffile>: ignoring\n";
              }
            }
            $reader->nextSibling || last;
          }
        }
      }
    }
  }
  $ctxt->{'_schema'} or
    die "Did not find <schema> element in PML <head>: the document '".$ctxt->{_filename}."' is not a valid PML instance!";
  $ctxt->{'_references'} = \%references;
  $ctxt->{'_refnames'} = \%named_references;
  return $root;
}

sub prepare_handlers {
  my ($ctxt,$opts)=@_;
  %handlers=();
  my $schema = $ctxt->{'_schema'};
  my $key=_get_handlers_cache_key($schema);
  my $cached = get_cached_handlers($key);
  if ($cached) {
    %handlers= @$cached;
  } else {
    compile_schema($schema);
    cache_handlers($key,[%handlers]) if $CACHE_HANDLERS;
  }
}

sub dump_handlers {
  my $dir = '.pml_compile.d';
  (-d $dir) || mkdir($dir) || die "Can't dump to $dir: $!\n";
  # print "created $dir\n";
  for my $f (keys %src) {
    my $dump_file = File::Spec->catfile($dir,$f);
    open (my $fh, '>:utf8', $dump_file)
      || die "Can't write to $dump_file: $!\n";
    my $sub = $src{$f};
    $sub=~s/^\s*#line[^\n]*\n//;
    print $fh ($sub);
    close $fh;
  }
}

sub load_data {
  my ($ctxt,$reader)=@_;
  my $root = $ctxt->{_root};
  my ($children);
  $reader->read if $reader->nodeType == XML_READER_TYPE_END_ELEMENT;
  if ($HAVE_XS) {
    my %ns;
    $children = XML::CompactTree::XS::readLevelToPerl(
      $reader,
      $XTC_FLAGS,
      \%ns
     );
    $root->[XAT_NS]=$ns{(PML_NS)} || -1;
  } else {
    my %ns;
    $children = XML::CompactTree::readLevelToPerl(
      $reader,
      $XTC_FLAGS,
      \%ns
     );
    $root->[XAT_NS]=$ns{(PML_NS)} || -1;
  }

  $root->[XAT_CHILDREN]=$children;
  # print Dumper($root);

#   print Dumper({references => $ctxt->{'_references'},
#                 refnames => $ctxt->{'_refnames'}});
  return $root;
}

sub _set_trees_seq {
  my ($ctxt,$type,$data)=@_;
  $ctxt->{'_pml_trees_type'} = $type;
  my $trees  = $ctxt->{'_trees'} ||= Treex::PML::Factory->createList;
  my $prolog = $ctxt->{'_pml_prolog'} ||= Treex::PML::Factory->createSeq;
  my $epilog = $ctxt->{'_pml_epilog'} ||= Treex::PML::Factory->createSeq;
  my $phase = 0; # prolog
  foreach my $element (@$data) {
    my $val = $element->[1];
    if (UNIVERSAL::DOES::does($val,'Treex::PML::Node')) {
      if ($phase == 0) {
        $phase = 1;
      }
      if ($phase == 1) {
        $val->{'#name'} = $element->[0]; # manually delegate_name on this element
        push @$trees, $val;
      } else {
        $prolog->push_element_obj($element);
      }
    } else {
      if ($phase == 1) {
        $phase = 2; # start epilog
      }
      if ($phase == 0) {
        $prolog->push_element_obj($element);
      } else {
        $epilog->push_element_obj($element);
      }
    }
  }
}

sub readAttributes {
  my ($r)=@_;
  my @attrs;
  my ($prefix,$name);
  if ($r->moveToFirstAttribute==1) {
    do {{
      $prefix = $r->prefix;
      $name = $r->localName;
      push @attrs, ($name,$r->value) unless ($prefix and $prefix eq 'xmlns') or (!$prefix and $name eq 'xmlns');
    }} while ($r->moveToNextAttribute==1);
    $r->moveToElement;
  }
  \@attrs;
}


sub _paste_last_code {
  my ($node,$prev,$p)=@_;
  return qq`
            #$node\->{'$Treex::PML::Node::rbrother'}=undef;
            $prev\->{'$Treex::PML::Node::rbrother'}=$node;
            weaken( $node\->{'$Treex::PML::Node::lbrother'} = $prev );
            weaken( $node\->{'$Treex::PML::Node::parent'} = $p );
`;
}
sub _paste_first_code {
  my ($node,$p)=@_;
  return qq`
           #$node\->{'$Treex::PML::Node::rbrother'}=undef;
           #$node\->{'$Treex::PML::Node::lbrother'}=undef;
           $p\->{'$Treex::PML::Node::firstson'}=$node;
           weaken( $node\->{'$Treex::PML::Node::parent'} = $p );
`;
}

sub hash_id_code {
  my ($key,$value)=@_;
  return q`
        for (`.$key.q`) {
          if (defined and length) {
            if (exists($ID_HASH->{$ID_PREFIX.$_}) and
                $ID_HASH->{$ID_PREFIX.$_} != `.$value.q`) {
               warn("Duplicated ID '$_'");
            }
            weaken( $ID_HASH->{$ID_PREFIX.$_} = `.$value.q` );
          }
        }`
}

sub _fix_id_member {
  my ($decl)=@_;
  return unless $decl;
  my ($idM) = $decl->find_members_by_role('#ID');
  if ($idM) {
    # what follows is a hack fixing buggy PDT 2.0 schemas
    my $cdecl = $idM->get_content_decl(1); # no_resolve
    if ($cdecl and $cdecl->get_decl_type == PML_CDATA_DECL and $cdecl->get_format eq 'ID') {
      $cdecl->set_format('PMLREF');
    } elsif ($cdecl = $idM->get_content_decl()) {
      if ($cdecl and $cdecl->get_decl_type == PML_CDATA_DECL and $cdecl->get_format eq 'ID') {
          warn "Trying to knit object of type '".$decl->get_decl_path."' which has an #ID-attribute ".
            "'".$idM->get_name."' declared as <cdata format=\"ID\"/>. ".
              "Note that the data-type for #ID-attributes in objects knitted as DOM should be ".
                "<cdata format=\"PMLREF\"/> (Hint: redeclare with <derive> for imported types).";
      }
    }
  }
  return $idM;
}

sub knit_code {
  my ($decl,$assign,$fail)=@_;
  my $sub = q`
             if ($ref) {
               $ref =~ s/^(?:(.*?)\#)//;
               my $file_id = $1||'';
               my $do_knit=$selected_knits->{$file_id};
               unless (defined($do_knit) and $do_knit==0) {
                 my $target;
                 if (length $file_id) {
                   my $f = $parsed_reffile->{ $file_id };
                   if (ref $f) {
                     if (UNIVERSAL::DOES::does($f,'Treex::PML::Instance')) {
                       $target = $f->{'_id-hash'}->{$ref};
                       $target->{'#knit_prefix'}=$file_id;
                     } else { # DOM`;
  if ($decl) {
    my $idM = _fix_id_member($decl);
    my $idM_name = $idM && $idM->get_name;
    my $decl_path = $decl->get_decl_path; $decl_path =~ s/^!//;
    $sub .= q`
                       my $dom_node = $ref_index->{$file_id}{$ref} || $f->getElementsById($ref);
                       if (defined $dom_node) {
                         $target  = $ID_HASH->{$ID_PREFIX.$file_id.'#'.$ref};
                         if (!defined $target) {
                            my $p = $ID_PREFIX;
                            $ID_PREFIX.=$file_id.'#';
                            my $r = XML::LibXML::Reader->new(string=>'<f xmlns="`.PML_NS.q`">'.$dom_node->toString.'</f>');
                            $r->nextElement;
                            # print $r, $dom_node->toString,"\n";
                            my %ns;
                            my $tree = XML::CompactTree`.($HAVE_XS ? '::XS' : '').q`::readSubtreeToPerl($r,`.$XTC_FLAGS.q`,\%ns);
                            my $index = $pml_ns_index;
                            $pml_ns_index = $ns{'`.PML_NS.q`'} || -1;
                            # print "index: $pml_ns_index\n";
                            # print Dumper($tree->[0][XAT_CHILDREN][0]);
                            $target = $handlers{'`.$decl_path.q`'}->($tree->[XAT_CHILDREN][0]);`;
    if ($idM) {
      $sub .= q`
                            $target->{`.$idM_name.q`}=$file_id.'#'.$target->{`.$idM_name.q`} if $target;`;
    }
    $sub .= q`
                            $pml_ns_index = $index;
                            $weaken=0;
                            $ID_PREFIX=$p;
                         }
                        }`;
  } else {
    $sub .= q`
                        warn("DOM knit error: knit content type not declared in the schema!\n");`;
  }
  $sub.=q`
                     }
                   } else {
                         warn("warning: KNIT failed: document '$file_id' not loaded\n");
                   }
                 } else {
                   $target = $ID_HASH->{$ID_PREFIX.$ref};
                 }
                 if (ref $target) {`.$assign.q`
                 } else {
                       warn("warning: KNIT failed: ID $ref not found in reffile '$file_id'\n");`.$fail.q`
                 }
               }
             }
          `;
  return $sub;
}

sub _report_error {
  my ($err)=@_;
  if ($STRICT) {die $err} else {warn $err};
}
sub _unhandled {
  my ($what,$pml_file,$el,$path)=@_;
  _report_error( "Error: $what not declared for type '$path' at ".$pml_file." line ".$el->[XAT_LINE] );
  return sub{};
}

sub compile_schema {
  my ($schema)=@_;
  my $schema_name = $schema->get_root_decl->get_name;
  my ($ctxt,$pml_file,$pml_ns_index,$ID_HASH,$ID_PREFIX,$selected_knits,$ref_index,$parsed_reffile,$trees_type,$have_trees);
  $handlers{'#cleanup'}= sub {
    undef $_ for ($ctxt,$pml_file,$pml_ns_index,$ID_HASH,$ID_PREFIX,$selected_knits,$ref_index,$parsed_reffile);
  };
  $handlers{'#initialize'}= sub {
    my ($instance)=@_;
    $ctxt = $instance;
    $pml_file = $instance->{'_filename'};
    $pml_ns_index = $instance->{_root}->[XAT_NS];
    $selected_knits = $instance->{_selected_knits_ids};
    $ref_index = $instance->{'_ref-index'};
    $ID_HASH = $instance->{'_id-hash'};
    $ID_PREFIX = $instance->{'_id_prefix'} || '';
    $parsed_reffile=$instance->{'_ref'};
    $have_trees = 0;
  };
  $schema->for_each_decl(sub {
    my ($decl)=@_;
    #  no warnings 'uninitialized';
    my $decl_type=$decl->get_decl_type;
    my $path = $decl->get_decl_path;
    $path =~ s/^!// if $path;
    return if $decl_type == PML_ATTRIBUTE_DECL ||
      $decl_type == PML_MEMBER_DECL    ||
        $decl_type == PML_TYPE_DECL      ||
          $decl_type == PML_ELEMENT_DECL;
    if ($decl_type == PML_ROOT_DECL) {
      my $name = $decl->get_name;
      my $cpath = $decl->get_content_decl->get_decl_path;
      $cpath =~ s/^!//;
      my $src = $schema_name.'__generated_read_root';
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
    sub {
      my ($p)=@_;
      unless (ref($p) and
              $p->[XAT_TYPE] == XML_READER_TYPE_ELEMENT and
              $p->[XAT_NS] == $pml_ns_index and
              $p->[XAT_NAME] eq '`.$name.q`'
             ) {
        die q(Did not find expected root element '`.$name.q` in ').$pml_file;
      }
      return ($handlers{ '`.$cpath.q`' })->($p);
    }`;
      $src{$src}=$sub;
      $handlers{'#root'}=eval $sub; die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_STRUCTURE_DECL) {
      #    print $path,"\n";
      my $src = $schema_name.'__generated_read_structure@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
       sub {
         my ($p)=@_;
         my $a=$p->[XAT_ATTRS];
         my $c=$p->[XAT_CHILDREN];
         # print join(",",map {defined($_) ? $_ : 'undef'} $p->[XAT_NAME],$p->[XAT_LINE],@$p)."\n";
         my (%s,$k,$v);`;
      if ($VALIDATE_CDATA) {
        $sub .= q`
         if ($a) {
           while (@$a) {
             $k=shift @$a;
             $v=shift @$a;
             $s{ $k } = ($handlers{ '`.$path.q`/'.$k }||_unhandled("attribute member '$k'",$pml_file,$p,'`.$path.q`'))->( $v );
           }
         }`;
      } else {
        $sub .= q`
         %s = @$a if $a;`;
      }
      $sub .= q`
         if ($c) {
           for my $el (@$c) {
             unless (ref($el) and $el->[XAT_TYPE] == XML_READER_TYPE_ELEMENT
                     and $el->[XAT_NS] == $pml_ns_index) {
               if (!ref($el) || $el->[XAT_TYPE] == XML_READER_TYPE_TEXT || $el->[XAT_TYPE] == XML_READER_TYPE_CDATA) {
                 warn q(Ignoring unexpected text content ').$el->[XAT_VALUE].q('  in a structure '`.$path.q`');
               } elsif ($el->[XAT_TYPE] == XML_READER_TYPE_ELEMENT) {
                 warn q(Ignoring unexpected element ').$el->[XAT_NAME].q(' in a structure '`.$path.q`');
               }
               next;
             }
             $k = $el->[XAT_NAME];
             $s{ $k } = ($handlers{ '`.$path.q`/'.$k }||_unhandled("member '$k'",$pml_file,$el,'`.$path.q`'))->($el);
           }
         }`;
      my ($id, $children_member);
      for my $member ($decl->get_members) {
        my $mdecl = $member->get_content_decl;
        if ($member->is_required) {
          my $name = $member->get_name;
          if ($mdecl && $mdecl->get_role eq '#TREES') {
            # this is a bit of a hack:
            # in this case, if the trees have been read from the member, the member handler returns
            # a stub value '#TREES' that will get deleted
            $sub.=q`
            ref or ($_ eq '#TREES' and delete($s{'`.$name.q`'})) or warn q(Missing required member '`.$name.q`' in structure '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE] for $s{'`.$name.q`'};`;
          } else {
            $sub.=q`
         ref or defined and length or warn q(Missing required member '`.$name.q`' in structure '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE] for $s{'`.$name.q`'};`;
          }
        } elsif ($mdecl and $mdecl->get_decl_type == PML_CONSTANT_DECL) {
          $sub.=q`
         defined or $_="`.quotemeta($mdecl->{value}).q`" for $s{'`.$member->get_name.q`'};`;
        }
        my $role = $member->get_role;
        if ($KNIT and !$role) {
          $mdecl ||= $member->get_content_decl;
          if ($mdecl and $mdecl->get_decl_type == PML_LIST_DECL and
              $mdecl->get_role eq '#KNIT') {
            my $mname = $member->get_name;
            my $knit_name = $mname; $knit_name=~s/\.rf$//;
#            warn("#KNIT on list not yet implemented: ".$member->get_name."\n");
            $sub .=q`
          my $ref_list = $s{'`.$mname.q`'};
          if ($ref_list) {
            my (@knit_list,@weaken,$weaken);
             for my $ref (@$ref_list) {
               $weaken=1;`
            .knit_code($mdecl->get_knit_content_decl(),q`
                   push @knit_list, $target;
                   push @weaken, $weaken;`,
                  q`undef $ref_list; last;`)
            .q`
            }
            if (defined $ref_list) {
              my $i=0;
              for (@knit_list) {
                weaken($_) if $weaken[$i++];
              }
              $s{'`.$knit_name.q`'}=Treex::PML::Factory->createList(\@knit_list);`;
            if ($mname ne $knit_name) {
              $sub .= q`delete $s{'`.$mname.q`'};`;
            }
            $sub .= q`
            } else {
              warn("KNIT failed on list '`.$mname.q`'");
            }
          }`;
          next;
          }
        }
        if ($role eq '#ID') {
          $id = $member->get_name;
        } elsif (!$trees_type and $role eq '#TREES' and $BUILD_TREES) {
          $mdecl ||= $member->get_content_decl;
          my $mtype = $mdecl->get_decl_type;
          if ($mtype == PML_LIST_DECL) {
            # check that content type is of role #NODE
            my $cmdecl = $mdecl->get_content_decl;
            my $cmdecl_type = $cmdecl->get_decl_type;
            unless ($cmdecl && ($cmdecl->get_role||'') eq '#NODE' &&
                      ($cmdecl_type == PML_STRUCTURE_DECL or
                         $cmdecl_type == PML_CONTAINER_DECL)) {
              _report_error("List '$path' with role #TREES may only contain structures or containers with role #NODE in schema ".
                $decl->get_schema->get_url."\n");
            }
            $trees_type = $mdecl;
            $sub .= q`
          unless ($have_trees) {
            $ctxt->{'_pml_trees_type'} = $trees_type;
            $have_trees=1;
            $ctxt->{'_trees'} = delete $s{'`.$member->get_name.q`'};
          }`;
          } elsif ($mtype == PML_SEQUENCE_DECL) {
            $trees_type = $mdecl;
            $sub .= q`
             unless ($have_trees) {
               $have_trees=1;
               defined($_) && _set_trees_seq($ctxt,$trees_type,$_->elements_list) for (delete $s{'`.$member->get_name.q`'});
             }`;
          } else {
            _report_error("#TREES member '$path/".$member->get_name."' is neither a list nor a sequence in schema ".$member->get_schema->get_url."\n");
          }
        } elsif ($role eq '#CHILDNODES') {
          if ($children_member) {
            _report_error("#CHILDNODES role defined on multiple members of type '$path': '$children_member' and '".$member->get_name."' in schema ".$member->get_schema->get_url."\n");
          } else {
            $children_member=$member->get_name;
          }
        } elsif ($role eq '#KNIT' and $KNIT) {
          my $mname = $member->get_name;
          my $knit_name = $mname; $knit_name=~s/\.rf$//;
          $sub .= q`
            my $ref = $s{'`.$mname.q`'}; my $weaken = 1;`
          .knit_code($member->get_knit_content_decl,q`
                   if ($weaken) {
                     weaken( $s{'`.$knit_name.q`'}=$target );
                   } else {
                     $s{'`.$knit_name.q`'}=$target;
                   } `.
                   ($mname ne $knit_name ? q`delete $s{'`.$mname.q`'};` : ''), '');
        }
      }
      if ($decl->get_role eq '#NODE' and $BUILD_TREES) {
        $sub .= q`
         my $node = Treex::PML::Factory->createTypedNode($decl,\%s,1);
         # my $node = bless \%s, 'Treex::PML::Node';
         # $node->{`.$Treex::PML::Node::TYPE.q`}=$decl;`;
        if ($children_member) {
          my $cdecl = $decl->get_member_by_name($children_member)->get_content_decl;
          my $ctype = $cdecl->get_decl_type;
          if ($ctype == PML_LIST_DECL) {
            my $cmdecl = $cdecl->get_content_decl;
            my $cmdecl_type = $cmdecl->get_decl_type;
            unless ($cmdecl->get_role eq '#NODE' &&
                      ($cmdecl_type == PML_STRUCTURE_DECL or
                         $cmdecl_type == PML_CONTAINER_DECL)) {
              _report_error("List '$path' with role #CHILDNODES may only contain structures or containers with role #NODE in schema '".
                $decl->get_schema->get_url."'; got ".$cmdecl->get_decl_type_str." (".$cmdecl->get_decl_path.") with role '".$cmdecl->get_role."' instead!\n");
            }
            $sub .= q`
            my $content = delete $node->{'`.$children_member.q`'};
            if ($content) {
              my $prev;
              foreach my $son (@{ $content }) {
                if ($prev) {
                  `._paste_last_code(qw($son $prev $node)).q`
                } else {
                  `._paste_first_code(qw($son $node)).q`
                }
                $prev = $son;
              }
            }`;
          } elsif ($ctype == PML_SEQUENCE_DECL) {
            for my $edecl ($cdecl->get_elements) {
              my $cmdecl = $edecl->get_content_decl;
              my $cmdecl_type = $cmdecl->get_decl_type;
              unless ($cmdecl->get_role eq '#NODE' &&
                        ($cmdecl_type == PML_STRUCTURE_DECL or
                           $cmdecl_type == PML_CONTAINER_DECL)) {
                _report_error("Sequence '$path' with role #CHILDNODES may only contain structures or containers with role #NODE in schema '".
                  $decl->get_schema->get_url."'; got ".$cmdecl->get_decl_type_str." (".$cmdecl->get_decl_path.") with role '".$cmdecl->get_role."' instead!\n");
              }
            }
            $sub .= q`
            my $content = delete $node->{'`.$children_member.q`'};
            if ($content) {
              # $content->delegate_names('#name');
              foreach my $element (@{$content->[0]}) { # manually delegate
                $element->[1]{'#name'} = $element->[0]; # store element's name in key $key of its value
              }
              my $prev;
              foreach my $son (map $_->[1], @{$content->[0]}) { # $content->values
                if ($prev) {
                  `._paste_last_code(qw($son $prev $node)).q`
                } else {
                  `._paste_first_code(qw($son $node)).q`
                }
                $prev = $son;
              }
            }`;
          } else {
            _report_error("Role #CHILDNODES can only occur on a structure member of type list or sequence, not on ".$cdecl->get_decl_type_str." '$path' in schema ".$cdecl->get_schema->get_url."\n");
          }
        }
      } else {
        $sub.=q`
         my $node = Treex::PML::Factory->createStructure(\%s,1);
         # my $node = bless \%s, 'Treex::PML::Struct';
       `;
      }
      if (defined $id) {
        $sub.=hash_id_code(qq(\$s{'$id'}),'$node');
      }
      $sub.=q`
         return $node;
       }`;
      # print $sub;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_CONTAINER_DECL) {
      my %attributes;
      @attributes{ map $_->get_name, $decl->get_attributes } = ();
      my $cdecl = $decl->get_content_decl;
      my $cpath = $cdecl && $cdecl->get_decl_path;
      $cpath=~s/^!// if $cpath;
      my $src = $schema_name.'__generated_read_container@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
       sub {
         my ($p)=@_;
         my $a=$p->[XAT_ATTRS];
         my $c=$p->[XAT_CHILDREN];
         my (%s,$k,$v,$content,@a_rest);
         if ($a) {
           while (@$a) {
             $k=shift @$a;
             $v=shift @$a;
             if (exists $attributes{$k}) {`;
      if ($VALIDATE_CDATA) {
        $sub .= q`
               $s{ $k } = ($handlers{ '`.$path.q`/'.$k }||_unhandled("attribute '$k'",$pml_file,$p,'`.$path.q`'))->( $v );`;
      } else {
        $sub .= q`
               $s{ $k } = $v;`;
      }
      $sub .= q`
             } else {
               push @a_rest, $k, $v;
             }
           }
         }
         $p->[XAT_ATTRS]=\@a_rest;`;
      if ($cdecl) {
        $sub .= q`
         $content = $handlers{ '`.$cpath.q`' }->($p);`;
      } else {
        $sub .= q`
         !$c or !grep { !($_->[XAT_TYPE] == XML_READER_TYPE_WHITESPACE or $_->[XAT_TYPE] == XML_READER_TYPE_SIGNIFICANT_WHITESPACE) } @$c or _report_error(qq(Unexpected content of an empty container type '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);`;
      }
      my $id;
      for my $member ($decl->get_attributes) {
        if ($member->is_required) {
          my $name = $member->get_name;
          $sub.=q`
         ref or defined and length or _report_error(q(missing required attribute '`.$name.q`' in container '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]) for $s{'`.$name.q`'};`;
        }
        if ($member->get_role eq '#ID') {
          $id = $member->get_name;
        }
      }
      if ($decl->get_role eq '#NODE' and $BUILD_TREES) {
        $sub .= q`
         my $node = Treex::PML::Factory->createTypedNode($decl,\%s,1);
         # my $node = bless \%s, 'FSNode';
         # $node->{`.$Treex::PML::Node::TYPE.q`}=$decl;`;
        if ($cdecl and ($cdecl->get_role||'') eq '#CHILDNODES') {
          my $ctype = $cdecl->get_decl_type;
          if ($ctype == PML_LIST_DECL) {
            my $cmdecl = $cdecl->get_content_decl;
            my $cmdecl_type = $cmdecl->get_decl_type;
            unless ($cmdecl->get_role eq '#NODE' &&
                      ($cmdecl_type == PML_STRUCTURE_DECL or
                         $cmdecl_type == PML_CONTAINER_DECL)) {
              _report_error("List '$path' with role #CHILDNODES may only contain structures or containers with role #NODE in schema '".
                $decl->get_schema->get_url."'; got ".$cmdecl->get_decl_type_str." (".$cmdecl->get_decl_path.") with role '".$cmdecl->get_role."' instead!\n");
            }
            $sub .= q`
            if ($content) {
              my $prev;
              foreach my $son (@{ $content }) {
                if ($prev) {
                  `._paste_last_code(qw($son $prev $node)).q`
                } else {
                  `._paste_first_code(qw($son $node)).q`
                }
                $prev = $son;
              }
            }`;
          } elsif ($ctype == PML_SEQUENCE_DECL) {
            for my $edecl ($cdecl->get_elements) {
              my $cmdecl = $edecl->get_content_decl or
                _report_error("Element '".$edecl->get_name."' of sequence '$path' has no content type declaration");
              my $cmdecl_type = $cmdecl->get_decl_type;
              unless ($cmdecl->get_role eq '#NODE' &&
                        ($cmdecl_type == PML_STRUCTURE_DECL or
                           $cmdecl_type == PML_CONTAINER_DECL)) {
              _report_error("Sequence '$path' with role #CHILDNODES may only contain structures or containers with role #NODE in schema '".
                $decl->get_schema->get_url."'; got ".$cmdecl->get_decl_type_str." (".$cmdecl->get_decl_path.") with role '".$cmdecl->get_role."' instead!\n");
              }
            }
            $sub .= q`
            if ($content) {
              # $content->delegate_names('#name');
              foreach my $element (@{$content->[0]}) { # manually delegate
                $element->[1]{'#name'} = $element->[0]; # store element's name in key $key of its value
              }
              my $prev;
              foreach my $son (map $_->[1], @{$content->[0]}) { # $content->values
                if ($prev) {
                  `._paste_last_code(qw($son $prev $node)).q`
                } else {
                  `._paste_first_code(qw($son $node)).q`
                }
                $prev = $son;
              }
            }`;
          } else {
            _report_error("Role #CHILDNODES can only occur on a container content type if it is a list or sequence, not on a ".$cdecl->get_decl_type_str." '".$path."' in schema ".$cdecl->get_schema->get_url."\n");
          }
        } elsif ($cdecl) {
          $sub .= q`
         $node->{'#content'} = $content if $content;`;
        }
      } else {
        $sub.=q`
         my $node = Treex::PML::Factory->createContainer($content,\%s,1);
         # $s{'#content'}=$content if $content;
         # my $node = bless \%s, 'Treex::PML::Container';`;
      }
      if (defined $id) {
        $sub.=hash_id_code(qq(\$s{'$id'}),'$node');
      }
      $sub.=q`
         return $node;
       }`;
      #    print $sub;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_SEQUENCE_DECL) {
      my $src = $schema_name.'__generated_read_sequence@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
       sub {
          my ($p)=@_;
          my $c=$p->[XAT_CHILDREN];
          return undef unless $c and @$c;
          my @seq;
          my $k;
          for my $el (@$c) {
            if (ref($el) and $el->[XAT_TYPE] == XML_READER_TYPE_ELEMENT
                and $el->[XAT_NS] == $pml_ns_index) {
              # print "element: $el->[XAT_NAME]\n";
              $k = $el->[XAT_NAME];
              push @seq, bless [$k, ($handlers{ '`.$path.q`/'.$k }||_unhandled("element '$k'",$pml_file,$el,'`.$path.q`'))->($el)], 'Treex::PML::Seq::Element';`;
      if ($decl->is_mixed) {
        $sub .= q`
            } elsif (!ref($el)) {`;
      $sub .= q`
              push @seq, bless ['#TEXT',$el], 'Treex::PML::Seq::Element';
            } elsif ($el->[XAT_TYPE] == XML_READER_TYPE_TEXT or $el->[XAT_TYPE] == XML_READER_TYPE_CDATA
                     or $el->[XAT_TYPE] == XML_READER_TYPE_WHITESPACE or $el->[XAT_TYPE] == XML_READER_TYPE_SIGNIFICANT_WHITESPACE) {
              push @seq, bless ['#TEXT',$el->[XAT_VALUE]], 'Treex::PML::Seq::Element';
            }`;
      } else {
        $sub .= q`
            } elsif (!ref($el) or $el->[XAT_TYPE] == XML_READER_TYPE_TEXT or $el->[XAT_TYPE] == XML_READER_TYPE_CDATA) {
               _report_error(q(Unexpected text content in a non-mixed sequence '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
            }`;
      }
      $sub .= q`
          }`;
      my $content_pattern = $decl->get_content_pattern;
      if ($VALIDATE_SEQUENCES and $content_pattern) {
        my $re = Treex::PML::Seq::content_pattern2regexp($content_pattern);
        $sub .= q`
        unless (join('',map '<'.$_->[0].'>',@seq) =~ m{^`.$re.q`$}ox) {
          warn("Sequence content (".join(",",map $_->[0], @seq).") does not follow the pattern `.quotemeta($content_pattern).q` in ".$pml_file.' line '.$p->[XAT_LINE]);
        }`;
      }
      if (!$trees_type and $decl->get_role eq '#TREES' and $BUILD_TREES) {
        $trees_type = $decl;
        $sub .= q`
        unless ($have_trees) {
          $have_trees=1;
          _set_trees_seq($ctxt,$trees_type,\@seq);
          return;
        }`;
      }
      if ($content_pattern) {
        $sub .= q`
        return Treex::PML::Factory->createSeq(\@seq, "`.quotemeta($content_pattern).q`",1);
      }`;
      } else {
        $sub .= q`
        return Treex::PML::Factory->createSeq(\@seq, undef, 1);
      }`;
      }
      $src{$src}=$sub;
      $handlers{$path} = eval $sub; die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_LIST_DECL) {
      #    print $path."\t@".$decl->get_decl_type_str,"\n";
      my $cdecl = $decl->get_content_decl
        or croak("Invalid PML Schema: list type without content: ",$decl->get_decl_path);
      my $cpath = $cdecl->get_decl_path;
      $cpath=~s/^!//;
      my $src = $schema_name.'__generated_read_list@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
       sub {
          my ($p)=@_;
          my $c=$p->[XAT_CHILDREN];
          my $a=$p->[XAT_ATTRS];
          return undef unless $c and @$c or $a and @$a;
          my @list;
          my $singleton = $a && @$a ? 1 : 0;
          unless ($singleton) {
          for my $el (@$c) {
            if (!ref($el) or $el->[XAT_TYPE] == XML_READER_TYPE_TEXT or $el->[XAT_TYPE] == XML_READER_TYPE_CDATA) {
               $singleton = 1;
               last;
            } elsif ($el->[XAT_TYPE] == XML_READER_TYPE_ELEMENT) {
               $singleton = 1 if $el->[XAT_NAME] ne 'LM' and $el->[XAT_NS] == $pml_ns_index;
               last;
            }
          }}
          if ($singleton) {
            @list = ($handlers{ '`.$cpath.q`' }->($p));
          } else {
            for my $el (@$c) {
              if (ref($el) and $el->[XAT_TYPE] == XML_READER_TYPE_ELEMENT and $el->[XAT_NS] == $pml_ns_index) {
                $el->[XAT_NAME] eq 'LM' or _report_error(q(Unexpected non-LM element ').$el->[XAT_NAME].q(' in a list: '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
                push @list, $handlers{ '`.$cpath.q`' }->($el);
              } elsif (!ref($el) or $el->[XAT_TYPE] == XML_READER_TYPE_TEXT or $el->[XAT_TYPE] == XML_READER_TYPE_CDATA) {
                 _report_error(q(Unexpected text content in a list '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
              }
            }
          }`;
      if (!$trees_type and $decl->get_role eq '#TREES' and $BUILD_TREES) {
        my $cdecl_type = $cdecl->get_decl_type;
        unless ($cdecl && ($cdecl->get_role||'') eq '#NODE' &&
                  ($cdecl_type == PML_STRUCTURE_DECL or
                     $cdecl_type == PML_CONTAINER_DECL)) {
          _report_error("List '$path' with role #TREES may only contain structures or containers with role #NODE in schema ".
            $decl->get_schema->get_url."\n");
        }
        $trees_type = $decl;
        $sub .= q`
          unless ($have_trees) {
            $have_trees = 1;
            $ctxt->{'_pml_trees_type'} = $trees_type;
            $ctxt->{'_trees'} = Treex::PML::Factory->createList(\@list,1);
            return;
          }`;
      }
      $sub .= q`
          return Treex::PML::Factory->createList(\@list,1);
        }`;
      # print $sub;
      $src{$src}=$sub;
      $handlers{$path} = eval $sub; die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_ALT_DECL) {
      # print $path."\t@".$decl->get_decl_type_str,"\n";
      my $cpath = $decl->get_content_decl->get_decl_path;
      $cpath=~s/^!//;
      my $src = $schema_name.'__generated_read_alt@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
       sub {
          my ($p)=@_;
          my $c=$p->[XAT_CHILDREN];
          my $a=$p->[XAT_ATTRS];
          return undef unless $c and @$c or $a and @$a;
          my $singleton = $a && @$a ? 1 : 0;
          unless ($singleton) {
            for my $el (@$c) {
              if (!ref($el) or $el->[XAT_TYPE] == XML_READER_TYPE_TEXT or $el->[XAT_TYPE] == XML_READER_TYPE_CDATA) {
                $singleton = 1;
                last;
              } elsif ($el->[XAT_TYPE] == XML_READER_TYPE_ELEMENT and $el->[XAT_NS] == $pml_ns_index) {
                $singleton = 1 if $el->[XAT_NAME] ne 'AM';
                last;
              }
            }
          }
          if ($singleton) {
            return $handlers{ '`.$cpath.q`' }->($p);
          } else {
            my @alt;
            for my $el (@$c) {
              if (ref($el) and $el->[XAT_TYPE] == XML_READER_TYPE_ELEMENT and $el->[XAT_NS] == $pml_ns_index) {
                $el->[XAT_NAME] eq 'AM' or _report_error(q(Unexpected non-AM element ').$el->[XAT_NAME].q(' in an alt: '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
                push @alt, $handlers{ '`.$cpath.q`' }->($el);
              } elsif (!ref($el) or $el->[XAT_TYPE] == XML_READER_TYPE_TEXT or $el->[XAT_TYPE] == XML_READER_TYPE_CDATA) {
                 _report_error(q(Unexpected text content in an alt: '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
              }
            }
            return @alt == 0 ? undef : @alt == 1 ? $alt[0] :
               #return bless \@alt, 'Treex::PML::Alt';
               Treex::PML::Factory->createAlt(\@alt,1);
          }
       }
    `;
      # print $sub;
      $src{$src}=$sub;
      $handlers{$path} = eval $sub; die _nl($sub)."\n".$@.' ' if $@;

    } elsif ($decl_type == PML_CDATA_DECL) {
      my $src = $schema_name.'__generated_read_cdata@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
         sub {
            my ($p)=@_;
            my $text;
            if (ref($p)) {
              my $c = $p->[XAT_CHILDREN];
              return undef unless $c and @$c;
              my $type;
              $text = join '',
              map {
                if (ref($_)) {
                  $type = $_->[XAT_TYPE];
                  if ($type == XML_READER_TYPE_TEXT ||
                      $type == XML_READER_TYPE_WHITESPACE ||
                      $type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE ||
                      $type == XML_READER_TYPE_CDATA) {
                    $_->[XAT_VALUE]
                  } elsif ($type == XML_READER_TYPE_ELEMENT) {
                     _report_error(q(Element found where only character data were expected in element <).$_->[XAT_NAME].q(> of CDATA type '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
                  }
                } else {
                  $_
                }
              } @$c;`;
      my $format_checker;
      if ($VALIDATE_CDATA and $decl->get_format ne 'any') {
        $sub .=q`
            } else {
              $text = $p;
            }`;
        $format_checker = $decl->_get_format_checker();
        if (defined $format_checker) {
          if (ref($format_checker) eq 'CODE') {
            $sub .= q`
            if (defined $text and length $text and !$format_checker->($text)) {`;
          } else {
            $sub .= q`
            if (defined $text and length $text and $text !~ $format_checker) {`;
          }
          $sub .= q`
              warn("CDATA value '$text' does not conform to format '`.$decl->get_format.q`' at ".$pml_file.' line '.$p->[XAT_LINE]);
            }`;
        }
        $sub .= q`
            return $text;
          }`;
      } else {
        $sub .=q`
              return $text;
            } else {
              return $p;
            }
          }`;
      }
      #    print $sub;
      $src{$src}=$sub;
      $handlers{$path} = eval $sub; die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_CHOICE_DECL) {
      #    print $path,"\n";
      my $value_hash = $decl->{value_hash};
      unless ($value_hash) {
        $value_hash={};
        @{$value_hash}{@{$decl->{values}}}=();
        $decl->{value_hash}=$value_hash;
      }
      my $src = $schema_name.'__generated_read_choice@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
         sub {
            my ($p)=@_;
            my $text;
            if (ref($p)) {
              my $c = $p->[XAT_CHILDREN];
              return undef unless @$c;
              $c=$c->[0];
              if (ref($c)) {
                my $type = $c->[XAT_TYPE];
                if ($type == XML_READER_TYPE_TEXT ||
                    $type == XML_READER_TYPE_WHITESPACE ||
                    $type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE ||
                    $type == XML_READER_TYPE_CDATA) {
                  $text = $c->[XAT_VALUE]
                } elsif ($type == XML_READER_TYPE_ELEMENT) {
                     _report_error(q(Element found where only character data were expected in element <).$p->[XAT_NAME].q(> of choice type '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
                }
              } else {
                $text = $c;
              }
            } else {
              $text=$p;
            }
            return undef unless defined $text;
            exists($value_hash->{$text}) or _report_error(qq(Invalid value '$text' in element <).$p->[XAT_NAME].q(> of choice type '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
            return $text;
         }`;
      #    print $sub;
      $src{$src}=$sub;
      $handlers{$path} = eval $sub; die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_CONSTANT_DECL) {
      #    print $path,"\n";
      my $value = quotemeta($decl->{value});
      my $src = $schema_name.'__generated_read_constant@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 0 ".pml_compile.d/`.$src.q`"
         sub {
            my ($p)=@_;
            my $text;
            if (ref($p)) {
              my $c = $p->[XAT_CHILDREN];
              return undef unless $c and @$c;
              $c=$c->[0];
              if (ref($c)) {
                my $type = $c->[XAT_TYPE];
                if ($type == XML_READER_TYPE_TEXT ||
                    $type == XML_READER_TYPE_WHITESPACE ||
                    $type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE ||
                    $type == XML_READER_TYPE_CDATA) {
                  $text = $c->[XAT_VALUE]
                } elsif ($type == XML_READER_TYPE_ELEMENT) {
                   _report_error(q(Unexpected element occurrence in element <).$p->[XAT_NAME].q(> of constant type '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
                }
              } else {
                $text = $c;
              }
            } else {
              $text=$p;
            }
            !(defined($text) and length($text)) or ($text eq "`.$value.q`") or
                 _report_error(qq(Invalid value '$text' in element <).$p->[XAT_NAME].q(> of constant type '`.$path.q`' at ).$pml_file.' line '.$p->[XAT_LINE]);
            return $text;
         }`;
      #    print $sub;
      $src{$src}=$sub;
      $handlers{$path} = eval $sub; die _nl($sub)."\n".$@.' ' if $@;
    }
    #  print "@_\n";
  });
  $schema->for_each_decl(
    sub {
      my ($decl)=@_;
      my $decl_type=$decl->get_decl_type;
      if ($decl_type == PML_ATTRIBUTE_DECL ||
            $decl_type == PML_MEMBER_DECL ||
              $decl_type == PML_ELEMENT_DECL
             ) {
        my $parent = $decl->get_parent_decl;
        my $path = $parent->get_decl_path . '/'. $decl->get_name;
        $path =~ s/^!// if $path;
        my $mdecl;
        if ($decl_type == PML_MEMBER_DECL and $decl->is_required) {
          # a hack that fixes missing content of a required member
          # containing a construct with the role #TREES
          #
          # the modified handler returns string '#TREES' instead
          # and the value gets deleted in the structure handler
          $mdecl = $decl->get_content_decl;
          if ($mdecl->get_role eq '#TREES' and $mdecl==$trees_type) {
            my $mpath = $mdecl->get_decl_path;
            $mpath =~ s/^!// if $mpath;
            my $handler = $handlers{$mpath};
            $handlers{$path}=sub {
              if (!$have_trees and $BUILD_TREES) {
                my $ret = &$handler;
                return '#TREES' if $have_trees and !defined($ret);
                return $ret;
              } else {
                return &$handler;
              }
            };
            return;
          }
        }
        #    print "$path\n";
        if (!exists($handlers{$path})) {
          $mdecl ||= $decl->get_content_decl;
          my $mpath = $mdecl && $mdecl->get_decl_path;
          if ($mpath) {
            $mpath =~ s/^!//;
            #      print "mapping $path -> $mpath ... $handlers{$mpath}\n";
            $handlers{$path} = $handlers{$mpath};
          }
        }
      }
    });
}

sub _nl {
  my ($str)=@_;
  my $i=0;
  return join "\n", map sprintf("%4d\t",$i++).$_, split /\n/, $str;
}

}

{
  # outside the main blog so that we leak no lexicals other than $dom
  sub perl_transform {
    return eval shift();
  }
}

1;
__END__

=head1 NAME

Treex::PML::Instance::Reader

=head1 DESCRIPTION

This module provides implements the load() method of
L<Treex::PML::Instance> and is not intended for direct use.

=head1 IMPLEMENTATION NOTES

The module analyses a L<Treex::PML::Schema> and generates Perl code to
parse PML instances conforming to that schema (by generating handlers
for individual data types). L<XML::CompactTree::XS> (or
L<XML::CompactTree>) is used to first slurp the XML into in-memory
Perl data structures (much faster than using SAX, XML::LibXML::Reader,
DOM, or any other parsing strategy known). The Perl code generated by
this module transforms these data structures into the coresponding
L<Treex::PML> objects.

The handlers for last 50 PML schemas are cached in memory, to boost
processing large collections of PML instances conforming to only a few
distinct schemas.

The module also implements automatic pluggable XSLT, external command,
or Perl pre-processing (transformation) of the input document; this
pre-processing can be specified in a configuration file
(C<pmlbackend_conf.xml>, see L<Treex::PML::Instance/"CONFIGURATION">
for more details).

=head1 DEBUGGING

If the environment variable PML_COMPILE_DUMP=1 is set, the module
dumps the generated code to the C<.pml_compile.d/> folder in the
current working directory. This is very for debugging or profiling the
generated code.

=head1 SEE ALSO

L<Treex::PML::Instance>, L<Treex::PML::Instance::Writer>,

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
