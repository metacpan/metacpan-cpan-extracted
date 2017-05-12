# $Id$
#
# This is free software, you may use it and distribute it under the same terms as
# Perl itself.
#
# Copyright 2014 LitRes.
#
#
package TurboXSLT;

use strict;
our ($VERSION, @ISA);


BEGIN {
use Carp;

require Exporter;

$VERSION = "1.2";

require DynaLoader;

@ISA = qw(DynaLoader);

# avoid possible shared library name conflict on Win32
# not using this trick on 5.10.0 (suffering from DynaLoader bug)
local $DynaLoader::dl_dlext = "xs.$DynaLoader::dl_dlext" if (($^O eq 'MSWin32') && ($] ne '5.010000'));

bootstrap TurboXSLT $VERSION;

# the following magic lets XML::LibXSLTMT internals know
# where to register XML::LibXMLMT proxy nodes
#INIT_THREAD_SUPPORT()
}


sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless \%options, $class;
    $self->{TURBOXSL_GLOBAL_CONTEXT} = new XSLTGLOBALDATAPtr;
    $self->{TURBOXSL_CALLBACKS} = {};
    return $self;
}

sub EnableExternalCache {
  my $self = shift;
  my $list = shift;
  _enable_external_cache($self->{TURBOXSL_GLOBAL_CONTEXT},$list);
}

sub AddURLRevision {
  my $self = shift;
  my $url = shift;
  my $revision = shift;
  _add_url_revision($self->{TURBOXSL_GLOBAL_CONTEXT},$url,$revision);
}

sub DefineGroupRights {
  my $self = shift;
  my $library = shift;
  my $group = shift;
  my $actions = shift;
  _define_group_rights($self->{TURBOXSL_GLOBAL_CONTEXT},$library,$group,$actions);
}

sub LoadStylesheet {
  my $self = shift;
  my $file = shift;
  return new TurboXSLT::Stylesheet($self->{TURBOXSL_GLOBAL_CONTEXT}, $file);
}

sub Parse {
  my $self = shift;
  my $text = shift;
  return _parse_str($self->{TURBOXSL_GLOBAL_CONTEXT},$text);
}

sub ParseFile {
  my $self = shift;
  my $file = shift;
  return _parse_file($self->{TURBOXSL_GLOBAL_CONTEXT},$file);
}

sub RegisterCallback {
  my $self = shift;
  my $name = shift;
  my $funp = shift;
  unless($self->{TURBOXSL_CALLBACKS}->{$name}) {
    $self->{TURBOXSL_CALLBACKS}->{$name} = $funp;
    _register_callback($self->{TURBOXSL_GLOBAL_CONTEXT},$name,$funp);
  }
}

sub Output {
  my $self = shift;
  my $ctx = shift;
  my $doc = shift;
  return _output_str($ctx, $doc);
}

sub OutputFile {
  my $self = shift;
  my $ctx = shift;
  my $doc = shift;
  my $file = shift;
  return _output_file($ctx,$doc,$file);
}

sub SetVar {
  my $self = shift;
  my $name = shift;
  if(defined $name && $name ne '') {
    my $value = shift || '';
    setvarg($self->{TURBOXSL_GLOBAL_CONTEXT},$name,$value);
  } else {
    warn "usage: TurboXSLT->SetVar(name[,value])";
  }
}

sub AddHashVar {
  my $self = shift;
  my $name = shift;
  my $index = shift;
  my $value = shift;
  
  $name = '@'.$name.'@'.$index;
  $self->SetVar($name, $value);
}

1;

###########################################################################

__END__

=head1 NAME

TurboXSLT - Interface to multithreaded XML+XSLT transformation library libturboxsl

=head1 SYNOPSIS

  use TurboXSLT;

  my $xslt = TurboXSLT->new;

  my $doc = $xslt->Parse("<foo><bar/></foo>");
   or
  my $doc = $xslt->ParseFile("document.xml");

  my $style = $xslt->LoadStylesheet("test.xsl");

  my $res = $style->Transform($doc);

  my $result_text = $style->Output($res);
    or
  $style->OutputFile("output.xml", $res);

=head1 DESCRIPTION

This module is an interface to the turboxsl library, a fast,
multithreaded xml parse and xsl transformation library.
While not as stable and functional as libxml+libxslt,
turboxsl is times faster and is intended mainly for HTML
generation in large, heavy loaded projects.

=head1 NOTE

Both library and interface are still under development, so 
some bugs may occur in transformation; parser is not verified
to be 100% standard-compatible.
Only UTF8 encoding is currently supported both for input and
output

=cut
