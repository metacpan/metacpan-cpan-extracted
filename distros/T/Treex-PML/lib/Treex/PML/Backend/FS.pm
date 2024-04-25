
############################################################
#
# Treex::PML::Backend::FS
# =========
#

package Treex::PML::Backend::FS;

use Carp;
use vars qw($CheckListValidity $emulatePML);
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.27'; # version template
}
use Treex::PML::IO qw(open_backend close_backend);
use Treex::PML::Factory;

use UNIVERSAL::DOES;

sub DOES {
  my ($self,$role)=@_;
  if ($role eq 'FSBackend' or $role eq __PACKAGE__) {
    return 1;
  } else {
    return $self->SUPER::DOES($role);
  }
}


=pod

=head2 NAME

Treex::PML::Backend::FS - IO backend for reading/writing FS files.

=head1 SYNOPSIS

use Treex::PML;
Treex::PML::AddBackends(qw(FS))

my $document = Treex::PML::Factory->createDocumentFromFile('input.fs');
...
$document->save();

=head1 DESCRIPTION

This module implements a Treex::PML input/output backend which accepts
reads/writes documents in the FS format.

=head1 REFERENCE

=over 4

=item Treex::PML::Backend::FS::$emulatePML

This variable controls whether a simple PML schema should be created
for FS files (default is 1 - yes). Attribute whose name contains one
or more slashes is represented as a (possibly nested) structure where
each slash represents one level of nesting. Attributes sharing a
common name-part followed by a slash are represented as members of
the same structure. For example, attributes C<a>, C<b/u/x>, C<b/v/x> and
C<b/v/y> result in the following structure:

C<{a => value_of_a,
   b => { u => { x => value_of_a/u/x },
          v => { x => value_of_a/v/x,
                 y => value_of_a/v/y }
        }
  }>

In the PML schema emulation mode, it is forbidden to have both C<a>
and C<a/b> attributes. In such a case the parser reverts to
non-emulation mode.

=cut

$emulatePML=1;


sub test {
  my ($f,$encoding)=@_;
  if (ref($f) eq 'ARRAY') {
    return $f->[0]=~/^@/; 
  } elsif (ref($f)) {
    binmode $f unless UNIVERSAL::DOES::does($f,'IO::Zlib');
    my $test = ($f->getline()=~/^@/);
    return $test;
  } else {
    my $fh = open_backend($f,"r");
    my $test = $fh && test($fh);
    close_backend($fh);
    return $test;
  }
}


sub _fs2members {
  my ($fs)=@_;
  my $mbr = {};
  my $defs = $fs->defs;
  # sort, so that possible short parts go first
  foreach my $attr (sort $fs->attributes) {
    my $m = $mbr;
    # check that no short attr exists
    my @parts = split /\//,$attr;
    my $short=$parts[0];
    for (my $i=1;$i<@parts;$i++) {
      if ($defs->{$short}) {
        warn "Can't emulate PML schema: attribute name conflict between $short and $attr: falling back to non-emulation mode\n";
      }
      $short .= '/'.$parts[$i];
    }
    for my $part (@parts) {
      $m->{structure}{member}{$part}{-name} = $part;
      $m=$m->{structure}{member}{$part};
    }
    # allow ``alt'' values concatenated with |
    if ($fs->isList($attr)) {
      $m->{alt} = {
        -flat => 1,
        choice => [ $fs->listValues($attr) ]
      };
    } else {
      $m->{alt} = {
        -flat => 1,
        cdata => { format =>'any' }
      };
    }
  }
  return $mbr->{structure}{member};
}

sub read {
  my ($fileref,$fsfile) = @_;
  return unless ref($fsfile);
  my $FS = Treex::PML::Factory->createFSFormat();
  $FS->readFrom($fileref) || return 0;
  $fsfile->changeFS( $FS );

  my $emu_schema_type;
  if ($emulatePML) {
    # fake a PML Schema:
    my $members = _fs2members($fsfile->FS);
    $members->{'#childnodes'}={
      role => '#CHILDNODES',
      list => {
        ordered => 1,
        type => 'fs-node.type',
      },
    };
    my $node_type = {
      name => 'fs-node',
      role => '#NODE',
      member => $members,
    };
    my $schema= Treex::PML::Schema->convert_from_hash({
      description => 'PML schema generated from FS header',
      root => { name => 'fs-data',
                structure => {
                  member => {
                    trees => {
                      -name => 'trees',
                      role => '#TREES',
                      required => 1,
                      list => {
                        ordered => 1,
                        type => 'fs-node.type'
                       }
                     }
                   }
                 }
              },
      type => {
        'fs-node.type' => {
          -name => 'fs-node.type',
          structure => $node_type,
        }
      }
    });
    if (defined($node_type->{member})) {
      $emu_schema_type = $node_type;
      $fsfile->changeMetaData('schema',$schema);
    }
  }

  my ($root,$l,@rest);
  $fsfile->changeTrees();

  # this could give us some speedup.
  my $ordhash;
  {
    my $i = 0;
    $ordhash = { map { $_ => $i++ } $fsfile->FS->attributes };
  }

  while ($l=ReadEscapedLine($fileref)) {
    if ($l=~/^\[/) {
      $root=ParseFSTree($fsfile->FS,$l,$ordhash,$emu_schema_type);
      push @{$fsfile->treeList}, $root if $root;
    } else { push @rest, $l; }
  }
  $fsfile->changeTail(@rest);

  #parse Rest
  my @patterns;
  foreach ($fsfile->tail) {
    if (/^\/\/Tred:Custom-Attribute:(.*\S)\s*$/) {
      push @patterns,$1;
    } elsif (/^\/\/Tred:Custom-AttributeCont:(.*\S)\s*$/) {
      $patterns[$#patterns].="\n".$1;
    } elsif (/^\/\/FS-REQUIRE:\s*(\S+)\s+(\S+)=\"([^\"]+)\"\s*$/) {
      my $requires = $fsfile->metaData('fs-require') || $fsfile->changeMetaData('fs-require',[]);
      push @$requires,[$2,$3];
      my $refnames = $fsfile->metaData('refnames') || $fsfile->changeMetaData('refnames',{});
      $refnames->{$1} = $2;
    }
  }
  $fsfile->changePatterns(@patterns);
  unless (@patterns) {
    my ($peep)=$fsfile->tail;
    $fsfile->changePatterns( map { "\$\{".$fsfile->FS->atno($_)."\}" } 
                    ($peep=~/[,\(]([0-9]+)/g));
  }
  $fsfile->changeHint(join "\n",
                    map { /^\/\/Tred:Balloon-Pattern:(.*\S)\s*$/ ? $1 : () } $fsfile->tail);
  return 1;
}


sub write {
  my ($fileref,$fsfile) = @_;
  return unless ref($fsfile);

#  print $fileref @{$fsfile->FS->unparsed};
  {
    my $encoding = $fsfile->encoding;
    if (defined $encoding) {
      print $fileref '@E '."$encoding\n";
    }
  }
  $fsfile->FS->writeTo($fileref);
  PrintFSFile($fileref,
              $fsfile->FS,
              $fsfile->treeList,
              ref($fsfile->metaData('schema')) ? 1 : 0
             );

  ## Tredish custom attributes:
  $fsfile->changeTail(
                    (grep { $_!~/\/\/Tred:(?:Custom-Attribute(?:Cont)?|Balloon-Pattern):/ } $fsfile->tail),
                    (map {"//Tred:Custom-Attribute:$_\n"}
                     map {
                       join "\n//Tred:Custom-AttributeCont:",
                         split /\n/,$_
                       } $fsfile->patterns),
                    (map {"//Tred:Balloon-Pattern:$_\n"}
                     split /\n/,$fsfile->hint),
                   );
  print $fileref $fsfile->tail;
  if (ref($fsfile->metaData('fs-require'))) {
    my $refnames = $fsfile->metaData('refnames') || {};
    foreach my $req ( @{ $fsfile->metaData('fs-require') } ) {
      my ($name) = grep { $refnames->{$_} eq $req->[0] } keys(%$refnames);
      print $fileref "//FS-REQUIRE:$name $req->[0]=\"$req->[1]\"\n";
    }
  }
  return 1;
}

sub Print ($$) {
  my (
      $output,   # filehandle or string
      $text      # text
     )=@_;
  if (ref($output) eq 'SCALAR') {
    $$output.=$text;
  } else {
    print $output $text;
  }
}

sub PrintFSFile {
  my ($fh,$fsformat,$trees,$emu_schema)=@_;
  foreach my $tree (@$trees) {
    PrintFSTree($tree,$fsformat,$fh,$emu_schema);
  }
}

sub PrintFSTree {
  my ($root,      # a reference to the root-node
      $fsformat,  # FSFormat object
      $fh,
      $emu_schema
     )=@_;

  $fh=\*STDOUT unless $fh;
  my $node=$root;
  while ($node) {
    PrintFSNode($node,$fsformat,$fh,$emu_schema);
    if ($node->{$Treex::PML::Node::firstson}) {
      Print($fh, "(");
      $node = $node->{$Treex::PML::Node::firstson};
      redo;
    }
    while ($node && $node != $root && !($node->{$Treex::PML::Node::rbrother})) {
      Print($fh, ")");
      $node = $node->{$Treex::PML::Node::parent};
    }
    croak "Error: NULL-node within the node while printing\n" if !$node;
    last if ($node == $root || !$node);
    Print($fh, ",");
    $node = $node->{$Treex::PML::Node::rbrother};
    redo;
  }
  Print($fh, "\n");
}

sub PrintFSNode {
  my ($node,      # a reference to the root-node
      $fsformat,
      $output,    # output stream
      $emu_schema
     )=@_;
  my $v;
  my $lastprinted=1;

  my $defs = $fsformat->defs;
  my $attrs = $fsformat->list;
  my $attr_count = $#$attrs+1;

  if ($node) {
    Print($output, "[");
    for (my $n=0; $n<$attr_count; $n++) {
      $v=$emu_schema ? $node->attr($attrs->[$n]) : $node->{$attrs->[$n]};
      $v=~s/([,\[\]=\\\n])/\\$1/go if (defined($v));
      if (index($defs->{$attrs->[$n]}, " O")>=0) {
        Print($output,",") if $n;
        unless ($lastprinted && index($defs->{$attrs->[$n]}," P")>=0) # N could match here too probably
          { Print($output, $attrs->[$n]."="); }
        $v='-' if ($v eq '' or not defined($v));
        Print($output,$v);
        $lastprinted=1;
      } elsif (defined($v) and length($v)) {
        Print($output,",") if $n;
        unless ($lastprinted && index($defs->{$attrs->[$n]}," P")>=0) # N could match here too probably
          { Print($output,$attrs->[$n]."="); }
        Print($output,$v);
        $lastprinted=1;
      } else {
        $lastprinted=0;
      }
    }
    Print($output,"]");
  } else {
    Print($output,"<<NULL>>");
  }
}

=item Treex::PML::Backend::FS::ParseFSTree ($fsformat,$line,$ordhash)

Parse a given string (line) in FS format and return the root of the
resulting FS tree as a node object.

=cut

sub ParseFSTree {
  my ($fsformat,$l,$ordhash,$emu_schema_type)=@_;
  return unless ref($fsformat);
  my $root;
  my $curr;
  my $c;

  unless ($ordhash) {
    my $i = 0;
    $ordhash = { map { $_ => $i++ } @{$fsformat->list} };
  }

  if ($l=~/^\[/o) {
    $l=~s/&/&amp;/g;
    $l=~s/\\\\/&backslash;/g;
    $l=~s/\\,/&comma;/g;
    $l=~s/\\\[/&lsqb;/g;
    $l=~s/\\]/&rsqb;/g;
    $l=~s/\\=/&eq;/g;
    $l=~s/\\//g;
    $l=~s/\r//g;
    $curr=$root=ParseFSNode($fsformat,\$l,$ordhash,$emu_schema_type);   # create Root

    while ($l) {
      $c = substr($l,0,1);
      $l = substr($l,1);
      if ( $c eq '(' ) { # Create son (go down)
        my $first_son = $curr->{$Treex::PML::Node::firstson} = ParseFSNode($fsformat,\$l,$ordhash,$emu_schema_type);
        $first_son->{$Treex::PML::Node::parent}=$curr;
        $curr=$first_son;
        next;
      }
      if ( $c eq ')' ) { # Return to parent (go up)
        croak "Error paring tree" if ($curr eq $root);
        $curr=$curr->{$Treex::PML::Node::parent};
        next;
      }
      if ( $c eq ',' ) { # Create right brother (go right);
        my $rb = $curr->{$Treex::PML::Node::rbrother} = ParseFSNode($fsformat,\$l,$ordhash,$emu_schema_type);
        $rb->set_lbrother( $curr );
        $rb->set_parent( $curr->{$Treex::PML::Node::parent} );
        $curr=$rb;
        next;
      }
      croak "Unexpected token... `$c'!\n$l\n";
    }
    croak "Error: Closing brackets do not lead to root of the tree.\n" if ($curr != $root);
  }
  return $root;
}


sub ParseFSNode {
  my ($fsformat,$lr,$ordhash,$emu_schema_type) = @_;
  my $n = 0;
  my $node;
  my @ats=();
  my $pos = 1;
  my $a=0;
  my $v=0;
  my $tmp;
  my @lv;
  my $nd;
  my $i;
  my $w;

  my $defs = $fsformat->defs;
  my $attrs = $fsformat->list;
  my $attr_count = $#$attrs+1;
  unless ($ordhash) {
    my $i = 0;
    $ordhash = { map { $_ => $i++ } @$attrs };
  }

  $node = $emu_schema_type
    ? Treex::PML::Factory->createTypedNode($emu_schema_type)
    : Treex::PML::Factory->createNode();
  if ($$lr=~/^\[/) {
    chomp $$lr;
    $i=index($$lr,']');
    $nd=substr($$lr,1,$i-1);
    $$lr=substr($$lr,$i+1);
    @ats=split(',',$nd);
    while (@ats) {
      $w=shift @ats;
      $i=index($w,'=');
      if ($i>=0) {
        $a=substr($w,0,$i);
        $v=substr($w,$i+1);
        $tmp=$ordhash->{$a};
        $n = $tmp if (defined($tmp));
      } else {
        $v=$w;
        $n++ while ( $n<$attr_count and $defs->{$attrs->[$n]}!~/ [PNW]/);
        if ($n>$attr_count) {
          croak "No more positional attribute $n for value $v at position in:\n".$n."\n";
        }
        $a=$attrs->[$n];
      }
      if ($CheckListValidity) {
        if ($fsformat->isList($a)) {
          @lv=$fsformat->listValues($a);
          foreach $tmp (split /\|/,$v) {
            print("Invalid list value $v of atribute $a no in @lv:\n$nd\n" ) unless (defined(Index(\@lv,$tmp)));
          }
        }
      }
      $n++;
      $v=~s/&comma;/,/g;
      $v=~s/&lsqb;/[/g;
      $v=~s/&rsqb;/]/g;
      $v=~s/&eq;/=/g;
      $v=~s/&backslash;/\\/g;
      $v=~s/&amp;/&/g;
      if ($emu_schema_type and $a=~/\//) {
        $node->set_attr($a,$v);
      } else {
        # speed optimized version
        #      $node->setAttribute($a,$v);
        $node->{$a}=$v;
      }
    }
  } else { croak $$lr," not node!\n"; }
  return $node;
}

sub ReadLine {
  my ($handle)=@_;
  local $_;
  if (ref($handle) eq 'ARRAY') {
    $_=shift @$handle;
  } else { $_=<$handle>;
           return $_; }
  return $_;
}

sub ReadEscapedLine {
  my ($handle)=@_;                # file handle or array reference
  my $l="";
  local $_;
  while ($_=ReadLine($handle)) {
    if (s/\\\r*\n?$//og) {
      $l.=$_; next;
    } # if backslashed eol, concatenate
    $l.=$_;
#    use Devel::Peek;
#    Dump($l);
    last;                               # else we have the whole tree
  }
  return $l;
}


=back

=cut

1;


__END__

=head1 SEE ALSO

Description of FS format:
L<http://ufal.mff.cuni.cz/pdt/Corpora/PDT_1.0/Doc/fs.html>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

