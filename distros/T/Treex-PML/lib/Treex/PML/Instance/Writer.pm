package Treex::PML::Instance::Writer;
{
use 5.008;
use strict;
use warnings;
no warnings qw(recursion);
use Carp;
use Data::Dumper;
use Scalar::Util qw(blessed);
use UNIVERSAL::DOES;

BEGIN {
  our $VERSION = '2.22'; # version template
}
use List::Util qw(first);
use Treex::PML::Instance::Common qw(:diagnostics :constants);
use Treex::PML::Schema;
use Treex::PML::IO qw(open_backend close_backend rename_uri);
use Encode;

my (
  %handlers,
  %src,
  %handler_cache,
  @handler_cache,
 );

# TODO:
# - test inline schemas
# - content_pattern and cdata validation on save
# - mixed content
# - decorate

our $CACHE_HANDLERS=1;
our $MAX_SCHEMA_CACHE_SIZE=50;

our $VALIDATE_CDATA=0;
our $SAVE_REFFILES = 1;
our $WITH_TREES = 1;
our $KEEP_KNIT = 0;
our $WRITE_SINGLE_LM = 0;
our $WRITE_SINGLE_CHILDREN_LM = 0;
our $INDENT = 2;

require Treex::PML;

sub _get_handlers_cache_key {
  my ($schema)=@_;
  my $key="$schema"; $key=~s/.*=//; # strip class
  return
    [
      $key,
      join ',',
      $key,
      $INDENT || 0,
      $VALIDATE_CDATA || 0,
      $SAVE_REFFILES || 0,
      $WITH_TREES || 0,
      $WRITE_SINGLE_LM || 0,
      $KEEP_KNIT || 0,
      $WRITE_SINGLE_CHILDREN_LM || 0,
];
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

sub forget_schema {
  my ($schema)=@_;
  delete $handler_cache{ $schema }; # delete also from the handler cache
  @handler_cache = grep { $_->[0] ne $schema } @handler_cache;
}

sub _indent {
  if ($INDENT>=0) {
    return q{"\n".('}.(' ' x $INDENT).q{' x $indent_level).}
  } else {
    return q()
  }
}
sub _indent_inc {
  if ($INDENT>0) {
    return q`
  $indent_level++;`;
  } else {
    return q()
  }
}
sub _indent_dec {
  if ($INDENT>0) {
    return q`
  $indent_level--;`;
  } else {
    return q()
  }
}

sub save {
  my ($ctxt,$opts)=@_;
  my $fh = $opts->{fh};
  local $VALIDATE_CDATA=$opts->{validate_cdata} if
    exists $opts->{validate_cdata};

  $ctxt->set_filename($opts->{filename}) if $opts->{filename};
  my $href = $ctxt->{'_filename'};

  $fh=\*STDOUT if ($href eq '-' and !$fh);
  my $config = $opts->{config};
  if ($config and ref(my $load_opts = $config->get_data('options/save'))) {
    $opts = {%$load_opts, %$opts};
  }

  local $KEEP_KNIT = 1 if $opts->{keep_knit};
  local $WRITE_SINGLE_LM = 1 if $opts->{write_single_LM};
  local $WRITE_SINGLE_CHILDREN_LM = 1 if $opts->{write_single_children_LM};
  local $INDENT = $opts->{indent} if defined $opts->{indent};
  unless ($fh) {
    if (defined($href) and length($href)) {
      eval {
        rename_uri($href,$href."~") unless $href=~/^ntred:/;
      };
      my $ok = 0;
      my $res;
      eval {
        $fh = open_backend($href,'w')
          || die "Cannot open $href for writing: $!";
        if ($fh) {
          binmode $fh;
          $res = $ctxt->save({%$opts, fh=> $fh});
          close_backend($fh);
          $ok = 1;
        }
      };
      unless ($ok) {
        my $err = $@;
        eval {
          rename_uri($href."~",$href) unless $href=~/^ntred:/;
        };
        die($err."$@\n") if $err;
      }
      return $res;
    } else {
      die("Usage: $ctxt->save({filename=>...,[fh => ...]})");
    }
  }
  $ctxt->{'_refs_save'} ||= $opts->{'refs_save'};
  binmode $fh if $fh;

  my $transform_id = $ctxt->{'_transform_id'};
  my ($out_xsl_href,$out_xsl,$orig_fh);
  my $xsl_source='';
  if ($config and defined $transform_id and length  $transform_id) {
    my $transform = $config->lookup_id( $transform_id );
    if ($transform) {
      ($out_xsl) = $transform->{'out'};
      if ($out_xsl->{'type'} ne 'xslt') {
        die(__PACKAGE__.": unsupported output transformation $transform_id (only type='xslt') transformations are supported)");
      }
      $out_xsl_href = URI->new(Encode::encode_utf8($out_xsl->get_member('href')));
      $out_xsl_href = Treex::PML::ResolvePath($config->{_filename}, $out_xsl_href, 1);
      unless (defined $out_xsl_href and length $out_xsl_href) {
        die(__PACKAGE__.": no output transformation defined for $transform_id");
      }
      $orig_fh = $fh;
      open(my $pml_fh, '>', \$xsl_source) or die "Cannot open scalar for writing!";
      $fh=$pml_fh;
    } else {
      die(__PACKAGE__.": Couldn't find PML transform with ID $transform_id");
    }
  }

  # dump embedded DOM documents
  my $refs_to_save = $ctxt->{'_refs_save'};
  # save_reffiles must be a id=>href hash reference

  my @refs_to_save = grep { ($_->{readas}||'') eq 'dom' or ($_->{readas}||'') eq 'pml' } $ctxt->get_reffiles();
  if (ref($refs_to_save)) {
    @refs_to_save = grep { exists $refs_to_save->{$_->{id}} } @refs_to_save;
    for (@refs_to_save) {
      unless (defined $refs_to_save->{$_->{id}}) {
        $refs_to_save->{$_->{id}}=$_->{href};
      }
    }
  } else {
    $refs_to_save = {};
  }

  my $references = $ctxt->{'_references'};

  # update all DOM trees to be saved
  $ctxt->{'_parser'} ||= $ctxt->_xml_parser();
  foreach my $ref (@refs_to_save) {
    if ($ref->{readas} eq 'dom') {
      $ctxt->readas_dom($ref->{id},$ref->{href});
    }
    # NOTE:
    # if ($refs_to_save->{$ref->{id}} ne $ref->{href}),
    # then the ref-file is going to be renamed.
    # Although we don't parse it as PML, it can be a PML file.
    # If it is, we might try to update it's references too,
    # but the snag here is, that we don't know if the
    # resources it references aren't moved along with it by
    # other means (e.g. by user making the copy).
  }

  binmode $fh,":utf8" if $fh;
  local $WITH_TREES = $ctxt->{'_no_read_trees'} ? 0 : 1;
  prepare_handlers($ctxt);
  dump_handlers($ctxt) if $opts->{dump_handlers} or $ENV{PML_COMPILE_DUMP};;
  $handlers{'#initialize'}->($ctxt,$refs_to_save,$fh);
  eval {
    $handlers{'#root'}->($ctxt->{_root});
    if ($ctxt->{'_pi'}) {
      my ($n,$v);
      for my $pi (@{$ctxt->{'_pi'}}) {
        # ($n,$v)=@$pi;
        # for ($n,$v) { s/&/&amp;/g; s/</&lt;/g; } # no no, _pi's are already quoted
        print $fh qq(<?@$pi?>\n);
      }
    }
  };
  ($handlers{'#cleanup'}||sub{})->();
  %handlers=();
#  close_uri($fh);
  $fh = $orig_fh if defined $orig_fh;
  die $@ if $@;

  if ($xsl_source and $out_xsl_href) {
    die "Buggy libxslt version 10127\n" if XSLT_BUG;
    my $xslt = XML::LibXSLT->new;
    my $params = $out_xsl->content;
    my %params;
    %params = map { $_->{'name'} => $_->value } $params->values
      if $params;
    my $out_xsl_parsed = $xslt->parse_stylesheet_file($out_xsl_href);
    my $dom = XML::LibXML->new()->parse_string($xsl_source);
    my $result = $out_xsl_parsed->transform($dom,%params);
    if (UNIVERSAL::can($result,'toFH')) {
      $result->toFH($fh,1);
    } else {
      $out_xsl_parsed->output_fh($result,$fh);
    }
    return 1;
  }

  # dump DOM trees to save
  if (ref($ctxt->{'_ref'})) {
    foreach my $ref (@refs_to_save) {
      if ($ref->{readas} eq 'dom') {
        my $dom = $ctxt->{'_ref'}->{$ref->{id}};
        my $href;
        if (defined($refs_to_save->{$ref->{id}})) {
          $href = $refs_to_save->{$ref->{id}};
        } else {
          $href = $ref->{href}
        }
        if (ref($dom)) {
          eval {
            rename_uri($href,$href."~") unless $href=~/^ntred:/;
          };
          my $ok = 0;
          eval {
            my $ref_fh = open_backend($href,"w");
            if ($ref_fh) {
              binmode $ref_fh;
              $dom->toFH($ref_fh,1);
              close_backend($ref_fh);
              $ok = 1;
            }
          };
          unless ($ok) {
            my $err = $@;
            eval {
              rename_uri($href."~",$href) unless $href=~/^ntred:/;
            };
            _die($err."$@") if $err;
          }
        }
      } elsif ($ref->{readas} eq 'pml') {
        my $ref_id = $ref->{id};
        my $pml = $ctxt->{'_ref'}->{$ref_id};
        if ($pml) {
          my $href;
          if (exists($refs_to_save->{$ref_id})) {
            $href = $refs_to_save->{$ref_id};
          } else {
            $href = $ref->{href}
          }
          $pml->save({ %$opts,
                       refs_save=>{
                         map { my $k=$_; $k=~s%^\Q$ref_id\E/%% ? ($k=>$refs_to_save->{$_}) : ()  }  keys %$refs_to_save
                       },
                       filename => $href, fh=>undef });
        }
      }
    }
  }
  return $ctxt;
}

######################################################

sub prepare_handlers {
  my ($ctxt)=@_;
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

sub _write_seq {
  my ($decl,$path,$seq)=@_;
  my $sub='';
  local $INDENT=-1 if $decl->is_mixed;
  $sub .= q`
           for my $el (`.$seq.q`->elements) {
             ($k,$v)=@$el;
             if (defined $v and (ref $v or length $v)) {
               $handlers{ '`.$path.'/'.q`'.$k }->($k,$v);
             } else {
               print $out `._indent().q`"<$k/>";
             }
           }`;
  return $sub;
}

sub _write_trees_seq {
  my ($decl)=@_;
  my $path = $decl->get_decl_path;
  $path =~ s/^!// if $path;
  return q`
         my $prolog = $ctxt->{'_pml_prolog'};
         if ($prolog) {`._write_seq($decl,$path,'$prolog').q`
         }
         for $v (@{$ctxt->{'_trees'}}) {
           if (ref $v) {
             $k=$v->{'#name'};
             $handlers{ '`.$path.'/'.q`'.$k }->($k,$v);
           }
         }
         my $epilog = $ctxt->{'_pml_epilog'};
         if ($epilog) {`._write_seq($decl,$path,'$epilog').q`
         }`;
}

sub _write_trees_list {
  my ($decl)=@_;
  my $path = $decl->get_content_decl->get_decl_path;
  $path =~ s/^!// if $path;
  return q`
         for $v (@{$ctxt->{'_trees'}}) {
           $handlers{ '`.$path.q`' }->('LM',$v);
         }`;
}

sub _write_children_seq {
  my ($tag,$decl)=@_;
  my $path = $decl->get_decl_path;
  $path =~ s/^!// if $path;
  my $sub = q`
             if ($v = $data->firstson) {`;
  $sub .= q`
               print $out `._indent().q`"<`.$tag.q`>";` if defined $tag;
  $sub .= _indent_inc().q`
               my $name;
               while ($v) {
                 $name = $v->{'#name'};
                 $handlers{ '`.$path.'/'.q`'.$name }->($name,$v);
                 $v = $v->rbrother;
               }`._indent_dec();
  $sub .= q`
               print $out `._indent().q`"</`.$tag.q`>";` if defined $tag;
  $sub.=q`
             }`;
  return $sub;
}

sub _write_children_list {
  my ($tag,$decl)=@_;
  $decl = $decl->get_content_decl;
  my $path = $decl->get_decl_path;
  $path =~ s/^!// if $path;
  my $sub = q`
             if ($v = $data->firstson) {`;
  if (defined $tag)  {
    if (!$WRITE_SINGLE_LM and !$WRITE_SINGLE_CHILDREN_LM) {
      $sub .= q`
               if ($v && !$v->rbrother && keys(%$v)) {
                 $handlers{ '`.$path.q`' }->('`.$tag.q`',$v);
               } else {`;
    }
    $sub .= q`
                 print $out `._indent().q`"<`.$tag.q`>";` ;
  }
  $sub.=_indent_inc().q`
                 while ($v) {
                   $handlers{ '`.$path.q`' }->('LM',$v);
                   $v = $v->rbrother;
                 }`._indent_dec();
  if (defined $tag)  {
    $sub .= q`
                 print $out `._indent().q`"</`.$tag.q`>";`;
    $sub .= q`
               }` if !$WRITE_SINGLE_LM and !$WRITE_SINGLE_CHILDREN_LM;
  }
  $sub.=q`
             }`;
  return $sub;
}


sub _knit_code {
  my ($knit_decl,$knit_decl_path,$name)=@_;
  my $idM = Treex::PML::Instance::Reader::_fix_id_member($knit_decl);
  if ($idM) {
    my $idM_name=$idM->get_name;
    return q`
                     my $knit_id = $v->{'`.$idM_name.q`'};
                     my $prefix;
                     unless (defined $knit_id) {
                       warn "Cannot KNIT back: `.$idM_name.q` not defined on object `.$knit_decl_path.q`!";
                     } elsif ($knit_id =~ s/^(.*?)#//) {
                       $prefix=$1;
                     } else {
                       $prefix = $v->{'#knit_prefix'};
                     }
                     print $out `._indent().q`'<`.$name.q`>'.($prefix ? $prefix.'#'.$knit_id : $knit_id).'</`.$name.q`>';
                     if ($prefix and !UNIVERSAL::DOES::does($ctxt->{'_ref'}{$prefix},'Treex::PML::Instance')) {
                       # DOM KNIT
                       my $rf_href = $refs_to_save->{$prefix};
                       if ( $rf_href ) {
                         my $indeces = $ctxt->{'_ref-index'};
                         if ($indeces and $indeces->{$prefix}) {
                           my $knit = $indeces->{$prefix}{$knit_id};
                           if ($knit) {
                             my $save_out = $out;
                             my $xml='';
                             open my $new_out, '>:utf8', \$xml; # perl 5.8.0
                             $out = $new_out;
                             local $INDENT=-1;
                             $handlers{'`.$knit_decl_path.q`' }->($knit->nodeName,$v);
                             close $new_out;
                             $out = $save_out;
                             $xml='<x xmlns="`.PML_NS.q`">'.$xml.'</x>';
                             my $new = $ctxt->{'_parser'}->parse_string($xml)->documentElement->firstChild;
                             $new->setAttribute('`.$idM_name.q`',$knit_id);
                             $knit->ownerDocument->adoptNode( $new );
                             $knit->parentNode->insertAfter($new,$knit);
                             $knit->unbindNode;
                             $indeces->{$prefix}{$knit_id}=$new;
                           } else {
                             _warn("Didn't find ID '$knit_id' in '$rf_href' ('$prefix') - cannot knit back!\n");
                           }
                         } else {
                           _warn("Knit-file '$rf_href' ('$prefix') has no index - cannot knit back!\n");
                         }
                       }
                     }`;
  } else {
    warn("Cannot KNIT ".$knit_decl_path." if there is no member/attribute with role='#ID'!");
  }
}

sub simplify {
    my $filename = shift;
    my $up  = File::Spec->updir;
    my $sep = File::Spec->catfile(q(), q());
    while($filename =~ /\Q$sep$up$sep/) {
        $filename =~ s/\Q$sep\E?[^$sep]*\Q$sep$up$sep/$sep/;
    }
    return $filename;
}

sub compile_schema {
  my ($schema)=@_;
  my ($ctxt,$refs_to_save,$out,$pml_trees_type,$have_trees,$indent_level);
  my $schema_name = $schema->get_root_decl->get_name;
  $handlers{'#cleanup'}= sub {
    undef $_ for ($ctxt,$refs_to_save,$out);
  };
  $handlers{'#initialize'}= sub {
    my ($instance,$refs_save,$fh)=@_;
    $ctxt = $instance;
    $refs_to_save = $refs_save;
    $out = $fh;
    $have_trees = 0;
    $pml_trees_type = $ctxt->{'_pml_trees_type'};
    $indent_level=0;
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
      my $cdecl = $decl->get_content_decl;
      my $cdecl_type = $cdecl->get_decl_type;
      my $cpath = $cdecl->get_decl_path;
      $cpath =~ s/^!//;
      my $src = $schema_name.'__generated_write_root';
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
    sub {
      my ($data)=@_;
      my $v;
      print $out '<?xml version="1.0" encoding="UTF-8"?>'."\n";
      print $out '<`.$decl->get_name.q` xmlns="`.PML_NS.q`"';`;
      # we need to know attributes now
      if ($cdecl_type == PML_CONSTANT_DECL ||
          $cdecl_type == PML_STRUCTURE_DECL) {
        for my $attr ($cdecl->get_attributes) {
          if ($attr->is_required) {
            $sub.=q`
              $v = $data->{'`.$attr->get_name.q`'};
              $v = '' unless defined $v;
              $v =~ s/&/&amp;/g; $v=~s/</&lt;/g; $v=~s/"/&quot;/g;
              print $out ' `.$attr->get_name.q`="'.$v.'"';
          `;
          } else {
            $sub.=q`
              $v = $data->{'`.$attr->get_name.q`'};
              if (defined($v) && length($v)) {
                $v=~s/&/&amp;/g; $v=~s/</&lt;/g; $v=~s/"/&quot;/g;
                print $out ' `.$attr->get_name.q`="'.$v.'"';
              }
          `;
          }
        }
      }
      # NOTE: using _^_ as indentation replacement!
      my $no_end_indent =
        ($cdecl_type == PML_SEQUENCE_DECL and
         $cdecl->is_mixed);
      my $psub = q`
      print $out ">\n",
                 "_^_<head>\n";
      my $inline = $ctxt->{'_schema-inline'};

      # remove /../ from filename, URI::rel gives strange results for base containing them
      my $filename = $ctxt->{_filename};
      $filename = $filename->path if ref $filename and index($filename,'file:/') == 0;
      $filename = simplify($filename) if -e $filename;

      if (defined $inline and length $inline) {
        print $out qq(_^__^_<schema>\n),$inline,qq(    </schema>\n);
      } else {
        $v = $ctxt->{'_schema-url'};
        if (defined $v and length $v) {
          $v=Treex::PML::IO::make_relative_URI($ctxt->{'_schema-url'},$filename);
          $v=~s/&/&amp;/g; $v=~s/</&lt;/g; $v=~s/"/&quot;/g;
          print $out qq(_^__^_<schema href="$v" />\n);
        } else {
          print $out qq(_^__^_<schema>\n);
          $ctxt->{'_schema'}->write({fh=>$out});
          print $out qq(_^__^_</schema>\n);
        }
      }
      my $references = $ctxt->{'_references'};
      if (ref($references) and keys(%$references)) {
        my $named = $ctxt->{'_refnames'};
        my %names = $named ? (map {
        my $name = $_;
        map { $_ => $name } (ref($named->{$_}) ? @{$named->{$_}} : $named->{$_})
      } keys %$named) : ();
        print $out qq(_^__^_<references>\n);
        foreach my $id (sort keys %$references) {
          my $href;
          if (exists($refs_to_save->{$id})) {
            # effectively rename the file reference
            $href = $references->{$id} = $refs_to_save->{$id}
          } else {
            $href = $references->{$id};
          }
          $href=Treex::PML::IO::make_relative_URI($href,$filename);
          my $name = $names{$id};
          for ($id,$href, (defined $name ? $name : ())) { s/&/&amp;/g;  s/</&lt;/g;  s/"/&quot;/g; }
          print $out qq(_^__^__^_<reffile id="${id}").(defined $name ? qq( name="${name}") : ()).qq( href="${href}" />\n);
        }
        print $out qq(_^__^_</references>\n);
      }
      print $out "_^_</head>";
      $handlers{ '`.$cpath.q`' }->(undef,$data);
      print $out `.($no_end_indent ? '' : _indent()).q`'</`.$decl->get_name.q`>'."\n";
    }`;
      my $indent = $INDENT>0 ? ' ' x $INDENT : '';
      $psub=~s/_\^_/$indent/g;
      $sub.=$psub;
      $src{$src}=$sub;
      $handlers{'#root'}=eval $sub; die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_STRUCTURE_DECL) {
      #    print $path,"\n";
      my $src = $schema_name.'__generated_write_structure@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
       sub {
         my ($tag,$data)=@_;
         my ($v,$k);
         unless (defined $data) {
            print $out defined $tag ? '/>' : '>' if !$tag;
            return;
         }
         my $close;
         if (defined $tag) {
           $close = '/>';
           print $out `._indent().q`'<'.$tag if length $tag;`;
      for my $attr ($decl->get_attributes) {
        my $name = $attr->get_name;
        if ($attr->is_required) {
          $sub.=q`
              $v = $data->{'`.$name.q`'};
              $v='' unless defined $v;
              $v=~s/&/&amp;/g; $v=~s/</&lt;/g; $v=~s/"/&quot;/g;
              print $out ' `.$name.q`'.'="'.$v.'"';
          `;
        } else {
          $sub.=q`
              $v = $data->{'`.$name.q`'};
              if (defined($v) && length($v)) {
                $v=~s/&/&amp;/g; $v=~s/</&lt;/g; $v=~s/"/&quot;/g;
                print $out ' `.$name.q`'.'="'.$v.'"';
              }
          `;
        }
      }
      $sub .= q`
         }`._indent_inc();
      my $this_trees_type;
      for my $m ($decl->get_members) {
        next if $m->is_attribute;
        my $name = $m->get_name;
        my $mdecl = $m->get_content_decl;
        my $mdecl_type = $mdecl->get_decl_type;
        $sub.=q`
         $v = $data->{'`.$name.q`'};`;
        my $close_brace=0;
        my $ignore_required=0;
        if ($WITH_TREES and $decl->get_role eq '#NODE' and $m->get_role eq '#CHILDNODES') {
          $close_brace=1;
          $sub.=q`
           if (UNIVERSAL::DOES::does($data,'Treex::PML::Node')) {
             if (defined $close) { undef $close; print $out '>'; }`;
          if ($mdecl_type == PML_SEQUENCE_DECL) {
            $sub .= _write_children_seq($name,$mdecl);
          } elsif ($mdecl_type == PML_LIST_DECL) {
            $sub .= _write_children_list($name,$mdecl);
          }
          $sub.=q`
           } else { `;
        } elsif ($WITH_TREES and ($m->get_role eq '#TREES' or $mdecl->get_role eq '#TREES')) {
          $close_brace=1;
          $this_trees_type = $mdecl;
          $ignore_required=1;
          $sub.=q`
           if (!$have_trees and !defined $v and (!defined($pml_trees_type) or $pml_trees_type==$this_trees_type)) {
             $have_trees=1;`;
          if ($m->is_required) {
            $sub.=q`
                 warn "Member '`.$path.'/'.$name.q`' with role #TREES is required but there are no trees, writing empty tag!\n"
                   if !$ctxt->{_trees} and @{$ctxt->{_trees}};`;
          }
          $sub.=q`
             if (defined $close) { undef $close; print $out '>'; }
             print $out `._indent().q`'<`.$name.q`>';`._indent_inc();
          if ($mdecl_type == PML_SEQUENCE_DECL) {
            $sub .= _write_trees_seq($mdecl);
          } elsif ($mdecl_type == PML_LIST_DECL) {
            $sub .= _write_trees_list($mdecl);
          }
          $sub.=_indent_dec().q`
             if (defined $close) { undef $close; print $out '>'; }
             print $out `._indent().q`'</`.$name.q`>';
           } else { `;
        }
        if ($mdecl_type == PML_CONSTANT_DECL and !$m->is_required) {
          # do not write
          $sub.=q`
             if (defined $v and (ref($v) or length $v and $v ne "`.quotemeta($mdecl->get_value).q`")) {
               warn "Disregarding invalid constant value in member '`.$name.q`': '$v'!\n";
             }`;
        } elsif ($m->get_role eq '#KNIT') {
          my $knit_name = $m->get_knit_name;
          my $knit_decl = $m->get_knit_content_decl();
          my $knit_decl_path = $knit_decl->get_decl_path;
          $knit_decl_path=~s/^!//;
            $sub.=q`
             if (defined $v and !ref $v and length $v) {
               if (defined $close) { undef $close; print $out '>'; }
               $handlers{'`.$path.'/'.$name.q`' }->('`.$name.q`',$v);
             } else {`;
            unless ($name eq $knit_name) {
              $sub .= q`
                  $v = $data->{'`.$knit_name.q`'};`;
            }
            $sub .=  q`
               if (defined $close) { undef $close; print $out '>'; }
               if (ref $v) {`;
          if ($KEEP_KNIT) {
            $sub .=  q`
                 $handlers{'`.$knit_decl_path.q`' }->('`.$name.q`',$v);`;
          } else {
            $sub.=_knit_code($knit_decl,$knit_decl_path,$name);
          }
          $sub .=  q`
               }`;
          if ($m->is_required) {
            $sub.=q` else {
                 warn "Required member '`.$path.'/'.$knit_name.q`' missing, writing empty tag!\n";
                 print $out `._indent().q`'<`.$knit_name.q`/>';
               }`;
          }
          $sub.=
            q`
             }`;
          $sub .= q`
           }` if $close_brace;
        } elsif ($mdecl_type == PML_LIST_DECL and $mdecl->get_role eq '#KNIT') {
          my $knit_name = $m->get_knit_name;
          my $knit_decl = $mdecl->get_knit_content_decl();
          my $knit_decl_path = $knit_decl->get_decl_path;
          $knit_decl_path=~s/^!//;
          if ($name ne $knit_name) {
            $sub.=q`
             if (ref $v) {
               if (defined $close) { undef $close; print $out '>'; }
               $handlers{'`.$path.'/'.$name.q`' }->('`.$name.q`',$v);
             } else {
               $v = $data->{'`.$knit_name.q`'};`;
          }
          if ($m->is_required) {
            $sub.=q` if (!ref $v) {
                 warn "Required member '`.$path.'/'.$knit_name.q`' missing, writing empty tag!\n";
                 if (defined $close) { undef $close; print $out '>'; }
                 print $out `._indent().q`'<`.$knit_name.q`/>';
               } else {`;
          } else {
            $sub .= q`
               if (ref $v) {
                 if (defined $close) { undef $close; print $out '>'; }`;
          }
          if ($KEEP_KNIT) {
            if (!$WRITE_SINGLE_LM) {
              $sub .=  q`
                 if (@$v==1 and defined($v->[0]) and !(UNIVERSAL::isa($v->[0],'HASH') and keys(%{$v->[0]})==0)) {
                   $handlers{'`.$knit_decl_path.q`' }->('`.$name.q`',$v->[0]);
                 } else {`;
            }
            $sub .=  q`
                   print $out `._indent().q`'<`.$name.q`>';`._indent_inc().q`
                   $handlers{'`.$knit_decl_path.q`' }->('LM',$_) for @$v;`._indent_dec().q`
                   print $out `._indent().q`'</`.$name.q`>';`;
            $sub .=  q`
                 }` if !$WRITE_SINGLE_LM;
          } else {
            if (!$WRITE_SINGLE_LM) {
              $sub .=  q`
                 if (@$v==1) {
                   if (defined $close) { undef $close; print $out '>'; }
                   $v=$v->[0];
                   `._knit_code($knit_decl,$knit_decl_path,$name).q`
                 } else {`;
            }
            $sub .=  q`
                   if (defined $close) { undef $close; print $out '>'; }
                   print $out `._indent().q`'<`.$name.q`>';`._indent_inc().q`
                   my $l = $v;
                   for $v (@$l) {`._knit_code($knit_decl,$knit_decl_path,'LM').q`
                   }`._indent_dec().q`
                   print $out `._indent().q`'</`.$name.q`>';`;
            $sub .=  q`
                 }` if !$WRITE_SINGLE_LM;
          }
          $sub.=
            q`
               }`;
          if ($name ne $knit_name) {
            $sub.=q`
             }`;
          }
          $sub .= q`
           }` if $close_brace;
        } else {
#           if ($mdecl->get_role eq '#TREES') {
#             $sub.=q`
#              $handlers{'`.$path.'/'.$name.q`' }->('`.$name.q`',$v);`;
#           } else {
          $sub.=q`
             if (defined $v and (ref $v or length $v)) {
               if (defined $close) { undef $close; print $out '>'; }
               $handlers{'`.$path.'/'.$name.q`' }->('`.$name.q`',$v);
             }`;
#       }
            if ($m->is_required and !$ignore_required ) {
            $sub.=q` else {
               warn "Required member '`.$path.'/'.$name.q`' missing, writing empty tag!\n";
               if (defined $close) { undef $close; print $out '>'; }
               print $out `._indent().q`'<`.$name.q`/>';
             }`;
          }
        }
        $sub .= q`
           }` if $close_brace;
      }
      $sub .= _indent_dec().q`
         if (defined $tag and length $tag) {
           print $out (defined($close) ? $close : `._indent().q`"</$tag>");
         }
      }`;
      # print $sub;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_CONTAINER_DECL) {
      my $src = $schema_name.'__generated_write_container@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
       sub {
         my ($tag,$data)=@_;
         my $v;
         unless (defined $data) {
            print $out defined $tag ? '/>' : '>' if !$tag;
            return;
         }
         my $close;
         my $ctag=$tag;`;
      my @attributes = $decl->get_attributes;
      if (@attributes) {
        $sub.=q`
         if (defined $tag) {
           print $out `._indent().q`'<'.$tag ; $close = '>'; $ctag='';`;
        for my $attr (@attributes) {
          my $name = $attr->get_name;
          if ($attr->is_required) {
            $sub.=q`
           $v = $data->{'`.$name.q`'};
           $v='' unless defined $v;
           $v=~s/&/&amp;/g; $v=~s/</&lt;/g; $v=~s/"/&quot;/g;
           print $out ' `.$name.q`'.'="'.$v.'"';
          `;
          } else {
            $sub.=q`
           $v = $data->{'`.$name.q`'};
           if (defined($v) && length($v)) {
             $v=~s/&/&amp;/g; $v=~s/</&lt;/g; $v=~s/"/&quot;/g;
             print $out ' `.$name.q`'.'="'.$v.'"';
           }
          `;
          }
        }
        $sub .= q`
         }`;
      } else {
        $sub .= q`undef $tag;`;
      }
      my $cdecl = $decl->get_content_decl;
      # TODO: #TREES
      if ($cdecl) {
        my $cdecl_type = $cdecl->get_decl_type;
        my $cpath = $cdecl->get_decl_path;
        $cpath =~ s/^!//;
        my $close_brace=0;
        if ($WITH_TREES and $decl->get_role eq '#NODE' and $cdecl->get_role eq '#CHILDNODES') {
          $close_brace=1;
          $sub.=q`
         if (UNIVERSAL::DOES::does($data,'Treex::PML::Node')) {
             undef $close;
             if (defined($ctag)) {
               if (!length($ctag)) {
                 print $out '>';
               } elsif ($data->firstson) {
                 print $out `._indent().q`qq{<$ctag>};
               } else {
                 print $out `._indent().q`qq{<$ctag/>};
               }
             }`;
          if ($cdecl_type == PML_SEQUENCE_DECL) {
            $sub .= _write_children_seq(undef,$cdecl);
          } elsif ($cdecl_type == PML_LIST_DECL) {
            $sub .= _write_children_list(undef,$cdecl);
          }
          $sub.=q`
           if ($data->firstson) {
             if (defined($ctag) and length($ctag)) {
               print $out `._indent().q`qq{</$ctag>};
             } else {
               print $out `._indent().q`'';
             }
           }
         } else { `;
        }
        $sub.=q`
           $v = $data->{'#content'};`;
        $sub.=q`
           undef $close;
           if (defined $v and (ref $v or length $v)) {
             $handlers{'`.$cpath.q`' }->($ctag,$v);
             my $ref = ref($v);
             print $out `._indent().q`'' if !$ctag and $ref and !((UNIVERSAL::DOES::does($v,'Treex::PML::Alt')`.($WRITE_SINGLE_LM ? '' : q` or UNIVERSAL::DOES::does($v,'Treex::PML::List')`)
               .q`) and @$v==1 and defined($v->[0]) and !(UNIVERSAL::isa($v->[0],'HASH') and keys(%{$v->[0]})==0));
           } else {
             if (defined($ctag) and length($ctag)) { print $out `._indent().q`qq{<$ctag/>} } else { $close='/>'; }
           }`;
        $sub .= q`
         }` if $close_brace;
      } else {
        $sub .= q`
         if (defined($ctag) and length($ctag)) { print $out `._indent().q`qq{<$ctag/>} } else {
         $close='/>'; }`;
      }
      $sub .= q`
         if (defined $tag and length $tag) {
           print $out (defined($close) ? $close : "</$tag>");
         }
      }`;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_SEQUENCE_DECL) {
      #    print $path,"\n";
      my $src = $schema_name.'__generated_write_sequence@'.$path;
      $src=~y{/}{@};
        # TODO: check it's a Seq, warn about on undefined element
      local $INDENT=-1 if $decl->is_mixed;
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
       sub {
         my ($tag,$data)=@_;
         my ($k,$v);
         unless (defined $data) {`;
      if ($WITH_TREES and $decl->get_role eq '#TREES') {
        $sub .= q`
           if (!$have_trees and (!defined($pml_trees_type) or $pml_trees_type==$decl)) {
             print $out (length($tag) ? `._indent().q`"<$tag>" : '>') if defined $tag;
             $have_trees=1;`._indent_inc()._write_trees_seq($decl)._indent_dec().q`
             print $out (length($tag) ? `._indent().q`"</$tag>" : '>') if defined $tag;
           } else {
             print $out defined $tag ? '/>' : '>' if !$tag;
           }`;
      } else {
        $sub .= q`
           print $out defined $tag ? '/>' : '>' if !$tag;`;
      }
      $sub .= q`
           return;
         }
         print $out (length($tag) ? `._indent().q`"<$tag>" : '>') if defined $tag;`
        ._indent_inc()._write_seq($decl,$path,'$data')._indent_dec();
      $sub.=q`
         if (defined $tag and length $tag) {
           print $out `._indent().q`"</$tag>";
         }
       }`;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
      $handlers{$path.'/#TEXT'} = eval q`sub { print $out ($_[1]); }` if $decl->is_mixed;
    } elsif ($decl_type == PML_LIST_DECL) {
      my $cdecl = $decl->get_content_decl;
      my $cpath = $cdecl->get_decl_path;
      $cpath=~s/^!//;
      my $src = $schema_name.'__generated_write_list@'.$path;
      $src=~y{/}{@};
        # TODO: check it's a List
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
       sub {
         my ($tag,$data)=@_;
         my ($v);
         if (!defined $data or !@$data) {`;
      if ($WITH_TREES and $decl->get_role eq '#TREES') {
        $sub .= q`
           if (!$have_trees and (!defined($pml_trees_type) or $pml_trees_type==$decl)) {
             print $out (length($tag) ? `._indent().q`"<$tag>" : '>') if defined $tag;
             $have_trees=1;`._indent_inc()._write_trees_list($decl)._indent_dec().q`
             print $out `._indent().q`"</$tag>" if defined $tag and length $tag;
             return;
           } else {
             print $out defined $tag ? '/>' : '>' if !$tag;
             return;
           } `;
      } else {
        $sub .= q`
           print $out defined $tag ? '/>' : '>' if !$tag;
           return;`;
      }
      if (!$WRITE_SINGLE_LM) {
        $sub .= q`
         } elsif (@$data==1 and defined($data->[0]) and !(UNIVERSAL::isa($data->[0],'HASH') and keys(%{$data->[0]})==0)) {
           print $out '>' if defined $tag and !length $tag;
           $handlers{ '`.$cpath.q`' }->($tag || 'LM',$data->[0]);`;
      }
      $sub .= q`
         } else {
           print $out (length($tag) ? `._indent().q`"<$tag>" : '>') if defined $tag;`._indent_inc().q`
           for $v (@$data) {
             if (defined $v and (ref $v or length $v)) {
               $handlers{ '`.$cpath.q`' }->('LM',$v);
             } else {
               print $out `._indent().q`"<LM/>";
             }
           }`._indent_dec().q`
           print $out `._indent().q`"</$tag>" if defined $tag and length $tag;
         }
       }`;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_ALT_DECL) {
      my $cdecl = $decl->get_content_decl;
      my $cpath = $cdecl->get_decl_path;
      $cpath=~s/^!//;
      my $src = $schema_name.'__generated_write_alt@'.$path;
      $src=~y{/}{@};
        # TODO: check it's an Alt
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
       sub {
         my ($tag,$data)=@_;
         unless (defined $data) {
            print $out defined $tag ? '/>' : '>' if !$tag;
            return;
         }
         if (!UNIVERSAL::DOES::does($data, 'Treex::PML::Alt')) {
           print $out '>' if defined $tag and !length $tag;
           $handlers{ '`.$cpath.q`' }->($tag || 'AM',$data);
         } elsif (@$data==1) {
           print $out '>' if defined $tag and !length $tag;
           $handlers{ '`.$cpath.q`' }->($tag || 'AM',$data->[0]);
         } elsif (@$data==0) {
           print $out defined $tag ? '/>' : '>' if !$tag;
           return;
         } else {
           my $v;
           print $out (length($tag) ? `._indent().q`"<$tag>" : '>') if defined $tag;`._indent_inc().q`
           for $v (@$data) {
             if (defined $v and (ref $v or length $v)) {
               $handlers{ '`.$cpath.q`' }->('AM',$v);
             } else {
               print $out `._indent().q`"<AM/>";
             }
           }`._indent_dec().q`
           print $out `._indent().q`"</$tag>" if defined $tag and length $tag;
         }
       }`;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_CDATA_DECL) {
      # TODO: CDATA FORMAT VALIDATION
      my $src = $schema_name.'__generated_write_cdata@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
       sub {
         my ($tag,$data)=@_;
         print $out (length($tag) ? `._indent().q`"<$tag>" : '>') if defined $tag;
         if (defined $data and length $data) {
           $data=~s/&/&amp;/g;$data=~s/</&lt;/g;$data=~s/\]\]>/]]&gt;/g;
           print $out $data;
         }
         print $out "</$tag>" if defined $tag and length $tag;
       }`;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_CHOICE_DECL) {
      my $value_hash = $decl->{value_hash};
      unless ($value_hash) {
        $value_hash={};
        @{$value_hash}{@{$decl->{values}}}=();
        $decl->{value_hash}=$value_hash;
      }
      my $src = $schema_name.'__generated_write_choice@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
       sub {
         my ($tag,$data)=@_;
         print $out (length($tag) ? `._indent().q`"<$tag>" : '>') if defined $tag;
         if (defined $data and length $data) {
           warn("Value: '$data' not allowed for choice type '`.$path.q`'; writing anyway!") if !exists $value_hash->{$data};
           $data=~s/&/&amp;/g;$data=~s/</&lt;/g;
           print $out $data;
         }
         print $out "</$tag>" if defined $tag and length $tag;
       }`;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
    } elsif ($decl_type == PML_CONSTANT_DECL) {
      my $value = quotemeta($decl->{value});
      my $src = $schema_name.'__generated_write_choice@'.$path;
      $src=~y{/}{@};
      my $sub = q`#line 1 ".pml_compile.d/`.$src.q`"
       sub {
         my ($tag,$data)=@_;
         print $out (length($tag) ? `._indent().q`"<$tag>" : '>') if defined $tag;
         if (defined $data and length $data) {
           warn("Invalid value '$data' in a constant type '`.$path.q`', should be '`.$value.q`'; writing anyway!") if $data ne "`.$value.q`";
           $data=~s/&/&amp;/g;$data=~s/</&lt;/g;
           print $out $data;
         }
         print $out "</$tag>" if defined $tag and length $tag;
       }`;
      $src{$src}=$sub;
      $handlers{$path} = eval($sub); die _nl($sub)."\n".$@.' ' if $@;
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
        if (!exists($handlers{$path})) {
          $mdecl ||= $decl->get_content_decl;
          my $mpath = $mdecl->get_decl_path;
          $mpath =~ s/^!// if $mpath;
          #      print "mapping $path -> $mpath ... $handlers{$mpath}\n";
          $handlers{$path} = $handlers{$mpath};
        }
      }
    });
}


}

sub _nl {
  my ($str)=@_;
  my $i=0;
  return join "\n", map sprintf("%4d\t",$i++).$_, split /\n/, $str;
}

1;
__END__

=head1 NAME

Treex::PML::Instance::Writer

=head1 DESCRIPTION

This module provides implements the save() method of
L<Treex::PML::Instance> and is not intended for direct use.

=head1 IMPLEMENTATION NOTES

The module analyses a L<Treex::PML::Schema> and generates Perl code to
serialize PML instances conforming to that schema (by generating
handlers for individual data types). The Perl code generated by this
module transforms L<Treex::PML> objects directly into XML (we
intentionally avoid using of abstract interfaces like SAX or
XML::Writer for speed).

The handlers for last 50 PML schemas are cached in memory, to boost
processing large collections of PML instances conforming to only a few
distinct schemas.

The module also implements automatic pluggable XSLT post-processing
(transformation) of the resulting document; this post-processing can
be specified in a configuration file (C<pmlbackend_conf.xml>, see
L<Treex::PML::Instance/"CONFIGURATION"> for more details).

=head1 TODO

Implement post-processing via an external command or Perl module.

=head1 DEBUGGING

If the environment variable PML_COMPILE_DUMP=1 is set, the module
dumps the generated code to the C<.pml_compile.d/> folder in the
current working directory. This is very for debugging or profiling the
generated code.

=head1 SEE ALSO

L<Treex::PML::Instance>, L<Treex::PML::Instance::Reader>,

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
