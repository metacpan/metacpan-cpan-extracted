package Treex::PML::Backend::PML;

use Treex::PML;
use Treex::PML::IO qw(close_backend);
use strict;
use warnings;
use File::ShareDir;
use File::Spec;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.27'; # version template
}

use Treex::PML::Instance qw( :all :diagnostics $DEBUG );

use constant EMPTY => q{};

use Carp;

use vars qw($config $config_file $allow_no_trees $config_inc_file $TRANSFORM @EXPORT_OK);

use Exporter qw(import);

BEGIN {
  $TRANSFORM=0;
  @EXPORT_OK = qw(open_backend close_backend test read write);
  $config = undef;
  $config_file = 'pmlbackend_conf.xml';
  $config_inc_file = 'pmlbackend_conf.inc';
  $allow_no_trees = 0;
}

sub configure {
  my @resource_path = Treex::PML::ResourcePaths();
  my $ret = eval { _configure() };
  my $err = $@;
  Treex::PML::SetResourcePaths(@resource_path);
  die $err if ($err);
  $config = $ret;
  return $ret;
}

sub _configure {
  my $cfg;
  my $schema_dir = eval { File::ShareDir::module_dir('Treex::PML') };
  unless (defined($schema_dir) and length($schema_dir) and -f File::Spec->catfile($schema_dir,'pmlbackend_conf_schema.xml')) {
    $schema_dir = Treex::PML::IO::CallerDir(File::Spec->catfile(qw(.. share)));
  }
  Treex::PML::AddResourcePath($schema_dir) if defined($schema_dir) and length($schema_dir);
  my $file = Treex::PML::FindInResources($config_file,{strict=>1});
  if ($file and -f $file) {
    _debug("config file: $file");
    $cfg = Treex::PML::Instance->load({filename => $file});
  } else {
    _debug("using empty pmlbackend_conf.xml file");
    $cfg = Treex::PML::Instance->load({string=><<'_CONFIG_',filename => $file});
<?xml version="1.0" encoding="UTF-8"?>
<pmlbackend xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
  <head><schema href="pmlbackend_conf_schema.xml"/></head>
  <transform_map/>
</pmlbackend>
_CONFIG_
  }
  if ($cfg) {
    my @config_files = Treex::PML::FindInResources($config_inc_file,{all=>1});
    my $T = $cfg->get_root->{transform_map} ||= Treex::PML::Factory->createSeq();
    for my $file (reverse @config_files) {
      _debug("config include file: $file");
      eval {
	my $c = Treex::PML::Instance->load({filename => $file});
	# merge
	my $t = $c->get_root->{transform_map};
	if ($t) {
	  for my $transform (reverse $t->elements) {
	    my $copy = Treex::PML::CloneValue($transform);
	    $T->unshift_element_obj($copy);
	    if (ref($copy->value) and $copy->value->{id}) {
	      $cfg->hash_id($copy->value->{id}, $copy->value, 1);
	    }
	  }
	}
      };
      warn $@ if $@;
    }
  }
  return $cfg;
}


###################

sub open_backend {
  my ($filename, $mode, $encoding)=@_;
  my $fh = Treex::PML::IO::open_backend($filename,$mode) # discard encoding
    || die "Cannot open $filename for ".($mode eq 'w' ? 'writing' : 'reading').": $!";
  return $fh;
}

sub read ($$) {
  my ($input, $fsfile)=@_;
  return unless ref($fsfile);

  my $ctxt = Treex::PML::Instance->load({fh => $input, filename => $fsfile->filename, config => $config });
  $ctxt->convert_to_fsfile( $fsfile );
  my $status = $ctxt->get_status;
  if ($status and 
      !($allow_no_trees or defined($ctxt->get_trees))) {
    _die("No trees found in the Treex::PML::Instance!");
  }
  return $status
}


sub write {
  my ($fh,$fsfile)=@_;
  my $ctxt = Treex::PML::Instance->convert_from_fsfile( $fsfile );
  $ctxt->save({ fh => $fh, config => $config });
}


sub test {
  my ($f,$encoding)=@_;
  if (ref($f)) {
    local $_;
    if ($TRANSFORM and $config) {
      1 while ($_=$f->getline() and !/\S/);
      # see <, assume XML
      return 1 if (defined and /^\s*</);
    } else {
      # only accept PML instances
      # xmlns:...="..pml-namespace.." must occur in the first tag (on one line)

      # FIXME: the following code will fail for UTF-16 and UTF-32;
      # proper fix would be to use XML::LibXML::Reader to read the
      # first tag (performance impact on processing many files past
      # PML backend to be measured). Another way to fix for UTF-16 is
      # to check for UTF-16 BOM (both BE and LE) and decode
      # accordingly if present; UTF-32 is rarely used and probably not
      # worth fixing.
      my ($in_first_tag,$in_pi,$in_comment, $past_BOM);
      while ($_=$f->getline()) {
	unless ($past_BOM) {
	  # ignore UTF-8 BOM
	  s{^\x{ef}\x{bb}\x{bf}}{};
	  $past_BOM = 1;
	}
	next if !/\S/;  # whitespace
	if ($in_first_tag) {
	  last if />/;
	  return 1 if m{\bxmlns(?::[[:alnum:]]+)?=([\'\"])http://ufal.mff.cuni.cz/pdt/pml/\1};
	  next;
	} elsif ($in_pi) {
	  next unless s/^.*?\?>//;
	  $in_pi=0;
	} elsif ($in_comment) {
	  next unless s/^.*?\-->//;
	  $in_comment=0;
	}
	s/^(?:\s*<\?.*?\?>|\s*<!--.*?-->)*\s*//;
	if (/<\?/) {
	  $in_pi=1;
	} elsif (/<!--/) {
	  $in_comment=1;
	} elsif (/^</) {
	  last if />/;
	  $in_first_tag=1;
	  return 1 if m{^[^>]*xmlns(?::[[:alnum:]]+)?=([\'\"])http://ufal.mff.cuni.cz/pdt/pml/\1};
	} elsif (length) {
	  return 0; # nothing else allowed before the first tag
	}
      }
      return 0 if !$in_first_tag && !(defined($_) and s/^\s*<//);
      return 1 if defined($_) and m{^[^>]*xmlns(?::[[:alnum:]]+)?=([\'\"])http://ufal.mff.cuni.cz/pdt/pml/\1};
      return 0;
    }
  } else {
    my $fh = Treex::PML::IO::open_backend($f,"r");
    my $test = $fh && test($fh,$encoding);
    Treex::PML::IO::close_backend($fh);
    return $test;
  }
}


######################################################


################### 
# INIT
###################
package Treex::PML::Backend::PML;
eval {
  configure();
};
Carp::cluck( $@ ) if $@;

1;

=pod

=head1 NAME

Treex::PML::Backend::PML - I/O backend for PML documents

=head1 SYNOPSIS

use Treex::PML;
Treex::PML::AddBackends(qw(PML))

my $document = Treex::PML::Factory->createDocumentFromFile('input.pml');
...
$document->save();

=head1 DESCRIPTION

This module implements a Treex::PML input/output backend which accepts
reads/writes PML files. See L<Treex::PML::Instance> for details.

NOTE: L<Treex::PML> enables this backend by default.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
