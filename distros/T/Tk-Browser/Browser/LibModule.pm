package Browser::LibModule;
my $RCSRevKey = '$Revision: 1.1.1.1 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=0.67;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
push @ISA, qw( Tk Exporter DB );

@EXPORT_OK=qw($VERSION new retrieve readlib BaseName DESTROY);

require Exporter;
require Carp;
use File::Basename;
use Browser::LibModuleSymbol;
use Browser::LibSymbolRef;

my @modulepathnames;
my @libdirectories;

=head1 Browser::LibModule.pm - Perl Library Support for Tk::Browser.pm

=head1 SYNOPSIS

  use Browser::LibModule;
  use Browser::LibModuleSymbol;
  use Browser::LibSymbolRef;

=head1 DESCRIPTION

Browser::LibModule provides a Tk::Browser(3) with hierarchical object
references to Perl library modules, including package name, file name,
version, arrays of stash references, and superclasses, if any.

Browser::LibModule stores objects in a tree similar to the Perl class
hierarchy.  The library module that the Browser::LibModule object
references need not be object oriented.  Every module is a subclass of
Perl's default superclass UNIVERSAL.

Browser::LibModuleSymbol.pm provides lexical scanning and lookup, and
cross referencing subroutines.

Browser::LibSymbolRef provides a few methods for tied objects that correspond
to stash references.

=head2 Running Under Perl/Tk

Browser::LibModule call Tk::Event::DoOneEvent() to provide window
updates.  The function usesTk() determines whether the module is
called from a program that uses Perl/Tk and returns true if called
from a program that has a Tk::MainWindow.  Otherwise usesTk() returns
false.

=head1 REVISION

$Id: LibModule.pm,v 1.1.1.1 2015/04/18 18:43:42 rkiesling Exp $

=head1 COPYRIGHT

Copyright © 2001-2004 Robert Kiesling, rkies@cpan.org.

Licensed using the same terms as Perl.  Refer to the file,
"Artistic," for information.

=head1 SEE ALSO

Browser::LibModuleSymbol(3), Lib::SymbolRef(3), Tk::Browser(3), perlmod(1),
perlmodlib(1), perl(1).

=cut

sub new {
    my $proto = shift;
    my $class = ref( $proto ) || $proto;
    my $self = {
	children => [],
	parents => '',
	pathname => '',
	basename => '',
	packagename => '',
	version => '',
	superclasses => undef,  
	baseclass => '',
	moduleinfo => undef,
	symbols => []
	};
    bless( $self, $class);
    return $self;
}

# Given a file base name, return the Module object.
sub retrieve {
    my $parent = shift;
    my ($n) = @_;
    if ( $parent -> {basename}  =~ /^$n/ ) { 
	return $parent; }
    foreach ( @{$parent -> {children}} ) {
	if ( $_ -> {basename} =~ /^$n/ ) {
	    return $_;
	}
    } 
    foreach ( @{$parent -> {children}} ) {
	if ( retrieve( $_, $n ) ) { 
	    return $_; }
    }
    return undef;
}

# Given a file pathname, return the Module object.
sub pathname_retrieve {
    my $parent = shift;
    my ($n) = @_;
    print "$n\n";
    if ( $parent -> {pathname}  eq $n ) { 
	return $parent; }
    foreach ( @{$parent -> {children}} ) {
	if ( $_ -> {pathname} eq $n ) {
	    print $_ -> {pathname} . "  $n \n";
	    return $_;
	}
    } 
    foreach ( @{$parent -> {children}} ) {
	if ( retrieve( $_, $n ) ) { 
	    return $_; }
    }
    return undef;
}

# Given a module package or sub-package name, return the module object.
# It's probably desirable to use this in preference to retrieve, 
# with external calls, to avoid dealing with the library pathnames 
# unless necessary.
sub retrieve_module {
    my $parent = shift;
    my ($n) = @_;
    if ( $parent -> {packagename}  eq $n ) { 
	return $parent; }
    foreach ( @{$parent -> {children}} ) {
	if ( $_ -> {packagename} eq $n ) {
	    return $_;
	}
    } 
    foreach ( @{$parent -> {children}} ) {
	if ( retrieve( $_, $n ) ) { 
	    return $_; }
    }
    return undef;
}

sub modulepathnames {
    return @modulepathnames;
}

sub libdirectories {
    return @libdirectories;
}

sub scanlibs {
    my $b = shift;
    my $m;
    my ($path, $bname, $ext);
  LOOP: foreach my $i ( @modulepathnames ) {
      ($bname, $path, $ext) = fileparse($i, qw(\.pm$ \.pl$) );
      # Don't use RCS Archives or Emacs bacups
      if( $bname =~ /(,v)|~/ ) { next LOOP; }
      Tk::Event::DoOneEvent(255) if usesTk ();
      if( $bname =~ /UNIVERSAL/ ) {
	  $b -> modinfo( $i );
      } else {
	  $m = new Browser::LibModule;
	  next LOOP if ! $m -> modinfo( $i );
	  $m -> {parents} = $b; 
	  push @{$b -> {children}}, ($m); 
      }
  }
}

sub modinfo {
    my $self = shift;
    my ($path) = @_;
    my ($dirs, $bname, $ext);
    my ($supers, $pkg, $ver, @text, @matches); 
    ($bname, $dirs, $ext) = fileparse($path, qw(\.pm \.pl));
    $self -> {pathname} = $path;
    @text = $self -> readfile;
    my $p = new Browser::LibModuleSymbol;
    return undef if ! $p -> text_symbols( @text, $path );
    $self -> {moduleinfo} = $p ;
    $self -> {packagename} = $p -> {packagename};
    $self -> {version} = $p -> {version};
    # We do a static match here because it's faster
    # Todo: include base classes from "use base" statements.
    @matches = grep /^\@ISA(.*?)\;/, @text;
    $supers = $matches[0];
    $supers =~ s/(qw)|[=\(\)\;]//gms if $supers;
    $self -> {basename} = $bname;
    $self -> {superclasses} = $supers;
    return 1;
}

# See the perlmod manpage
# Returns a hash of symbol => values.
# Handles as separate ref.
# Typeglob dereferencing deja Symdump.pm and dumpvar.pl, et al.
# Package namespace creation and module loading per base.pm.
sub exportedkeys {
    my $m = shift;
    my ($pkg) = @_;
    my $obj;
    my $packagekey; my $val;
    my $rval;
    my $nval;
    my %keylist = ();
    $m -> {symbols} = ();
    my @vallist;
    my $i = 0;
  EACHKEY: foreach $packagekey ( keys %{*{"$pkg"}} ) {
      next unless $packagekey;
      if( defined ($val = ${*{"$pkg"}}{$packagekey} ) ) {
        no warnings; # avoid uninitalized value warnings.
        $rval = $val; $nval = $val; 
	$obj = tie $rval, 'Lib::SymbolRef', $packagekey;
	push @{$m -> {symbols}}, ($obj);
	foreach( @vallist) { if ( $_ eq $rval ) { next EACHKEY } }
	# Replace the static $VERSION and @ISA values 
	# of the initial library scan with the symbol
	# compile/run-time values.
	local (*v) = $val;
	# Look for the stash values in case they've changed 
	# from the source scan.
	if( $packagekey =~ /VERSION/ ) {
	  $m -> {version} = ${*v{SCALAR}};
	}
	if($packagekey =~ /ISA/ ) {
	  $m -> {superclasses} = "@{*v{ARRAY}}";
	}
        use warnings;
      }
    }
    $keylist{$packagekey} = ${*{"$pkg"}}{$packagekey} if $packagekey;
    # for dumping symbol refs to STDOUT.
    # example of how to print listing of symbol refs.
#    foreach my $i ( @{$m -> {symbols}} ) { 
#      foreach( @{$i -> {name}} ) {
#	print $_; 
#      }
#      print "\n--------\n";
#    }
    return %keylist;
}

#
#  Here for example only.  This function (or the statements
# it contains), must be in the package that has the main:: stash
# space in order to list the packages symbols into the correct
# stash context.  
#
# sub modImport {
#  my ($pkg) = @_;
#  eval "package $pkg";
#  eval "use $pkg";
#  eval "require $pkg";
#}

sub readfile {
  my $self = shift;
  my $fn;
  if (@_){ ($fn) = @_; } else { $fn = $self -> PathName; }
  my @text;
  open FILE, $fn or warn "Couldn't open file $fn: $!.\n";
  @text = <FILE>;
  close FILE;
  return @text;
}

# de-allocate module and all its children
sub DESTROY ($) {
    my ($m) = @_;
    @c = $m -> {children};
    $d = @c;
    if ( $d == 0 )  {   
	$m = {
	    children => undef
	};
	return;
      }
    foreach my $i ( @{$m -> {children}} ) {
	Browser::LibModule -> DESTROY($i);
    }
  }

sub libdirs {
    my $f; my $f2;
    my $d; 
    foreach $d ( @INC ) {
	push @libdirectories, ($d);
	opendir DIR, $d;
	@dirfiles = readdir DIR;
	closedir DIR;
	# look for subdirs of the directories in @INC.
	foreach $f ( @dirfiles ) {
	    next if $f =~ m/^\.{1,2}$/ ;
	    $f2 = $d . '/' . $f;
	    if (opendir SUBDIR, $f2 ) {
		push @libdirectories, ($f2);
		&libsubdir( $f2 );
		closedir SUBDIR;
	    }
	}
    }
}

sub libsubdir {
    my ($parent) = @_;
    opendir DIR, $parent;
    my @dirfiles = readdir DIR;
    closedir DIR;
    foreach (@dirfiles) {
	next if $_ =~ m/^\.{1,2}$/ ;
	my $f2 = $parent . '/' . $_;
	if (opendir SUBDIR, $f2 ) {
	    push @libdirectories, ($f2);
	    libsubdir( $f2 );
	    closedir SUBDIR;
	}
    }
}

sub module_paths {
    my $self = shift;
    my ($f, $pathname, @allfiles);
    Tk::Event::DoOneEvent(255) if usesTk ();
    foreach ( @libdirectories ) {
	opendir DIR, $_;
	@allfiles = readdir DIR;
	closedir DIR;
	foreach $f ( @allfiles ) {
	    if ( $f =~ /\.p[lm]/ ) {
		$pathname = $_ . '/' . $f;
		push @modulepathnames, ($pathname);
	    }
	}
    }
}


sub Children {
    my $self = shift;
    if (@_) { $self -> {children} = shift; }
    return $self -> {children}
}

sub Parents {
    my $self = shift;
    if (@_) { $self -> {parents} = shift; }
    return $self -> {parents}
}

sub PathName {
    my $self = shift;
    if (@_) { $self -> {pathname} = shift; }
    return $self -> {pathname}
}

sub BaseName {
    my $self = shift;
    if (@_) { $self -> {basename} = shift; }
    return $self -> {basename}
}

sub PackageName {
    my $self = shift;
    if (@_) { $self -> {packagename} = shift; }
    return $self -> {packagename}
}

sub Symbols {
    my $self = shift;
    if (@_) { $self -> {symbols} = shift; }
    return $self -> {symbols}
}

###
### Version, SuperClass -- Module.pm uses hashref directly.
###
sub Version {
    my $self = shift;
    if (@_) { $self -> {version} = shift; }
    return $self -> {version}
}

sub SuperClasses {
    my $self = shift;
    if (@_) { $self -> {superclasses} = shift; }
    return $self -> {superclasses}
}

sub BaseClass {
    my $self = shift;
    if (@_) { $self -> {baseclass} = shift; }
    return $self -> {baseclass}
}

sub ModuleInfo {
    my $self = shift;
    if (@_) { $self -> {moduleinfo} = shift; }
    return $self -> {moduleinfo}
}

sub Import {
  my ($pkg) = @_;
  &Exporter::import( $pkg ); 
}

sub usesTk {
  return ( exists ${"main\:\:"}{"Tk\:\:"} );
}

1;

