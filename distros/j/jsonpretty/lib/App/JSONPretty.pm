package App::JSONPretty;

use strictures 1;
use JSON ();
use Try::Tiny;

our $VERSION = 1;

my $usage = "Usage:
  $0 <filename
  $0 filename
";

sub new_json_object {
  JSON->new->utf8->pretty->relaxed->canonical;
}

sub source_filehandle {
  if (@ARGV > 1) {
    die "Too many arguments.\n${usage}";
  } elsif (@ARGV == 1) {
    open my $fh, '<', $ARGV[0]
      or die "Couldn't open $ARGV[0]: $!";
    $fh;
  } else {
    *STDIN;
  }
}

sub source_data {
  my $src = source_filehandle;
  do { local $/; <$src> }
    or die "No source data supplied.\n${usage}";
}

sub decode_using {
  my ($json, $src_data) = @_;
  try {
    $json->decode($src_data)
  } catch {
    die "Error parsing JSON: $_\n";
  }
}

sub encode_using {
  my ($json, $data_structure) = @_;
  try {
    $json->encode($data_structure)
  } catch {
    die "Error generating JSON: $_\n";
  }
}

sub run {
  my $json = new_json_object;

  print STDOUT encode_using $json, decode_using $json, source_data;

  return 0;
}

exit run unless caller;

1;

=head1 NAME

jsonpretty - JSON prettification script

=head1 SYNOPSIS

  $ jsonpretty <file.json
  $ jsonpretty file.json

=head1 DESCRIPTION

The jsonpretty script reads the JSON file given on STDIN or as its first
argument, decodes it (allowing errors such as shell style comments and extra
trailing commas on lists), then pretty prints it.

The pretty printed form is indented and has hash keys sorted and as such is
suitable for diffing.

This program always works in utf8. If your JSON is not valid utf8, please ask
the nearest internationalisation expert to kill you with a big hammer.

=head1 AUTHOR

Matt S. Trout <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None required yet. Maybe this code is perfect (hahahahaha ...).

=head1 COPYRIGHT

Copyright (c) 2011 the App::JSONPretty L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
