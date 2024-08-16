#!/usr/bin/env perl
use strict;
use warnings FATAL => qw/all/;
use 5.016;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Encode;
use Getopt::Long;
use File::Basename;

use YATT::Lite::XHF;

sub usage {
  die join("\n", @_, <<END);
Usage: $0 [-d OUTDIR]  FILES...
END

}

{

  GetOptions("d|outdir=s", \ (my $o_outdir)
             , "h|help",   \ (my $o_help)
             , "m|module=s", \ (my $o_yaml_module = "syck")
           )
    or usage("Invalid option");
  usage() if $o_help;

  if ($o_outdir) {
    usage("Can't find outdir: $o_outdir") unless -d $o_outdir;
    usage("outdir is not writable: $o_outdir") unless -w $o_outdir;
  }

  my $emitter = __PACKAGE__->can("emit_yaml_$o_yaml_module")
    or usage("Unsupported yaml_module: $o_yaml_module");

  foreach my $fn (@ARGV) {
    my $parser = YATT::Lite::XHF->new(file => $fn, encoding => 'utf8');

    # Read toplevel as dictionaries.
    my @data;
    # Metainfo. Maybe empty.
    push @data, scalar $parser->read(skip_comment => 0);
    # body.
    push @data, $_ while $_ = $parser->read;

    $emitter->($fn, $o_outdir, \@data);
  }
}

sub emit_yaml_tiny {
  my ($fn, $o_outdir, $data) = @_;

  require YAML::Tiny;

  my $yaml = YAML::Tiny->new($data);

  if ($o_outdir) {
    my $outfn = join("/", $o_outdir, basename($fn));
    $outfn =~ s/\.xhf$/.yaml/;
    $yaml->write($outfn);
  } else {
    print encode_utf8($yaml->write_string);
  }
}

sub emit_yaml_syck {
  my ($fn, $o_outdir, $data) = @_;

  require YAML::Syck;

  if ($o_outdir) {
    my $outfn = join("/", $o_outdir, basename($fn));
    $outfn =~ s/\.xhf$/.yaml/;

    YAML::Syck::DumpFile($outfn, $data);
  } else {

    YAML::Syck::DumpFile(\*STDOUT, $data);
  }
}
