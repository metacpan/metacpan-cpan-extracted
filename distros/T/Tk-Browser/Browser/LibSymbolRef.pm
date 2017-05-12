package Lib::SymbolRef;
my $RCSRevKey = '$Revision: 1.1.1.1 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=0.51;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
push @ISA, qw( Exporter DB );
@EXPORT_OK=qw($VERSION);

require Exporter;
require Carp;
use Browser::LibModuleSymbol;

=head1  NAME

  Browser::LibSymbolref.pm -- Manage tied references to symbol table hash
  entries.

=head1 SYNOPSIS

  use Browser::LibModule;
  use Browser::LibModuleSymbol;
  use Browser::LibSymbolRef;

  if( defined ($val = ${*{"$pkg"}}{$packagekey} ) ) {
      $obj = tie $val, 'Lib::SymbolRef', $packagekey;
  }

=head1 DESCRIPTION

Provides tied symbol table objects for Tk::Browser.

=head1 REVISION

$Id: LibSymbolRef.pm,v 1.1.1.1 2015/04/18 18:43:42 rkiesling Exp $

=head1 COPYRIGHT

Copyright © 2001-2004 Robert Kiesling, rkies@cpan.org.

Licensed using the same terms as Perl.  Refer to the file,
"Artistic," for information.

=head1 SEE ALSO

Browser::LibModule(3), Browser::LibModuleSymbol(3), Tk::Browser(3),
perltie(1).

=cut

sub TIESCALAR {
  my ($package, $name, $refer) = @_;
  print "TIESCALAR\n";
  my $obj = { name => $name, refs=>('name' => $refer) };
  bless $obj, $package;
  return $obj;
}

sub TIEHANDLE {
  my ($package, $name, $refer) = @_;
  ### Until re-tied.
  no warnings;
  my $obj = { name => $name, refs => ('refer' => $refer) };
  use warnings;
  bless $obj, $package;
  return $obj;
}

sub TIEARRAY {
}

sub PRINTF {
  my $self = shift;
  my $fmt = shift;
}

sub FETCH {
  return undef;
}

sub GETC {
  return undef;
}

sub READ {
  return undef;
}

sub OPEN {
  return undef;
}

sub READLINE {
  return undef;
}

sub STORE {
  return undef;
}


# ---- Hash methods -----


sub TIEHASH {
  my ($varref, $package, $callingpkg ) = @_;
  print "TIEHASH\n";
  my $obj = [ name => $varref, callingpkg => $callingpkg, {%$hr} ];
  bless $obj, $package;
  print "TIEHASH: $varref, $package, $callingpkg\n";
  return $obj;
}

sub FIRSTKEY {
}

sub CLEAR {
}

# ---- Instance methods

sub name {
  my $self = shift;
  if (@_) {
    $self -> {name} = shift;
  }
  return $self -> {name}
}

1;

