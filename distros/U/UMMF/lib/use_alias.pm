package use_alias;

use strict;
use warnings;


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/09/15 };
our $VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };


use Carp qw(confess);

our $global_debug = $ENV{'PERL_USE_ALIAS_DEBUG'};


my %visited;
my %package_sub;
my %use;


sub import
{
  my ($self, @use) = @_;

  # $DB::single = 1;

  my (@base, $base);

  my ($importer, $file, $line) = caller(0);
  return 1 if $visited{join("\t", $importer, $file, $line)} ++;

  
  my $debug = 
    # ($importer =~ /SomeBadImporter/) ||
      $global_debug;

  if ( $debug ) {
    print STDERR "=========================================\n";
    print STDERR "importer = '$importer'\n";
  }

  my $use;
  for my $x ( @use ) {
    my ($alias, $no_alias);

    # package Foo;
    # use use_alias qw(__PACKAGE__::Bar)
    # =>
    # use use_alias qw(Foo::Bar)
    #
    $x =~ s/^\.\.::/.::..::/s;
    $x =~ s/^(__PACKAGE__|\.)::/$importer . '::'/e;

    # Package Foo::Bar;
    # use use_alias qw(Foo::Bar::..::Baz);
    # =>
    # use use_alias qw(Foo::Baz);
    while ( $x =~ s/[^:]+::\.\.::/::/ ) {
      1;
    }
    while ( $x =~ s/::::/::/sg ) {
      1;
    }

    ($x, $alias, $no_alias) = split('=', $x, 3);
    $no_alias = defined $no_alias;

    my (@path) = split('::', $x, 9999);
    my $name = pop @path;
    $alias ||= $name unless $no_alias;

    print STDERR "x = '$x'\n" if $debug;
    print STDERR "name = '$name'\n" if $debug;
    print STDERR "alias = '$alias'\n" if $debug;

    if ( $x eq '}' ) {
      die "Too many '}': After use '$use'" unless @base;
      $base = pop(@base);
    }
    elsif ( $name eq '{' ) {
      push(@base, $base);
      if ( $path[0] eq '' ) {
	shift @path;
	unshift @path, $base;
      }
      $base = join('::', @path);
    }
    else {
      # X => $base::X
      if ( ! @path ) {
	$use = join('::', $base, $x);
      }
      # ::X::Y => $base::X::Y
      elsif ( $path[0] eq '' ) {
	$use = join('', $base, $x);
      }
      # X::Y::Z => X::Y::Z
      else {
	$use = $x;
      }

      # Don't use the package more than once.
      unless ( $use{$use} ) {
	$use{$use} = 1; # Recursion lock.

	print STDERR "use '$use'\n" if $debug;
	my $expr = qq{ use $use; };
	eval $expr; 
	if ( $@ ) {
	  $use{$use} = 0; # In case something trap via eval and tries again.
	  my $msg = "in expr: \n  $expr\nby importer: $importer\n$@";
	  die($msg);
	}
      }

      $alias = "${importer}::${alias}" unless 
	$alias =~ /::/;

      unless ( $no_alias ) {
	print STDERR "${alias} = '$use'\n" if $debug;

	no strict qw(refs);

	my $funcp = \$package_sub{$use};
	unless ( $$funcp ) {
	  # Use eval "" to create a sub() that returns 
	  # a computed "constant".  
	  # Slower now once, for speed later many.

	  my $use_local = $use;
	  my $expr = qq{ sub () { '${use_local}' } };
	  print STDERR "$use => $expr\n" if $debug;

	  $$funcp = eval $expr;
	  confess("in expr:\n$expr\n$@") if $@;
	}

	# Make the alias use the function
	# that returns the full-qualified package.
	*{"${alias}"} = $$funcp;
	# $DB::single = 1;
      }
    }
  }


  $use;
}


1;
