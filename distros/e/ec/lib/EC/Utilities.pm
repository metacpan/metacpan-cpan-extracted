package EC::Utilities;

my $VERSION = 0.01;

use Carp;
use Exporter ();
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw (Exporter);

@EXPORT = qw (inc_path expand_path verify_path content
	      content_as_str strexist strfill);

sub tkversion {
    require Tk;
    return ${Tk::VERSION};
}

sub inc_path {
    my ($filename) = $_[0];
    foreach (@INC) {
	return "$_/$filename" if -f "$_/$filename";
    }
}

# prepend $HOME directory to path name in place of ~
sub expand_path {
    my ($s) = $_[0];
    if( $s =~ /^\~/ ) {
	$s =~ s/~//;
	$s = $ENV{'HOME'}."/$s";
    }
    $s =~ s/\/\//\//g;
    return $s;
}

sub verify_path {
  my ($path) = @_;
  if ((not -d $path) and (not -f $path)) {
    carp "Verify_path(): Path $path not found: $!\n";
  }
}

sub content {
  my ($file) = @_;
  my ($l, @contents);
  eval {
    open FILE, $file or
      carp "Couldn't open $file: ".$!."\n";
    while (defined ($l=<FILE>)) {
      chomp $l;
      push @contents, ($l);
    }
    close FILE;
  };
  return @contents;
}

sub content_as_str { return join "\n", &content (@_) }

sub strexist { return defined $_[0] and length $_[0] }

sub strfill {
    my ($s, $length) = @_;

    if ( length ($s) > $length) {
	$s = substr $s, 0, $length;
    } elsif ( length ($s) < $length ) {
	$s .= ' ' x ($length - length ($s));
    }
    return $s;
}

1;
