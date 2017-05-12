package autodynaload ;
@ISA = qw(autorequire) ;

use strict ;
use autorequire ;
use Carp ;
use DynaLoader ;
use XSLoader ;
use Config ;
use ExtUtils::Installed ;
use File::Spec ;


our $VERSION = '0.08' ;

@autodynaload::INC = () ;
autodynaload->new($autodynaload::dl_findfile)->insert(-1) ;
$autodynaload::disable_expandspec = 1 ;

my $installed = undef ;
my $dlext = $Config{dlext} ;


BEGIN {
	# We need to probe the autoloader by calling it once...
	DynaLoader::dl_findfile() ;
	DynaLoader::dl_expandspec($INC{'autodynaload.pm'}) ;

	$autodynaload::bootstrap = \&DynaLoader::bootstrap ;
	$autodynaload::dl_findfile = \&DynaLoader::dl_findfile ;
	$autodynaload::dl_expandspec = \&DynaLoader::dl_expandspec ;
}


sub new {
	my $class = shift ;
	my $sub = shift ;

	return $class->SUPER::new($sub, \@autodynaload::INC) ; 
}


sub _bootstrap {
	my @args = @_ ;

	local $DynaLoader::do_expand = 1 ;
	$autodynaload::bootstrap->(@args) ;
}


# Stolen from XSLoader.pm
sub _bootstrap_inherit {
	package DynaLoader;

	my $module = $_[0];
	no strict 'refs' ;
	local *DynaLoader::isa = *{"$module\::ISA"};
	local @DynaLoader::isa = (@DynaLoader::isa, 'DynaLoader');
	# Cannot goto due to delocalization.  Will report errors on a wrong line?
	require DynaLoader;
	DynaLoader::bootstrap(@_);
}


sub _dl_findfile {
	my @args = @_ ;

	my @ret = () ;
	foreach my $ar (@autodynaload::INC){
		next if $ar->{disabled} ;

		my $s = $ar->_get_sub() ;
		if (! ref($s)){
			# Symbolic reference. It may not be defined yet.
			return undef if !defined(&{$s}) ;
			$s = \&{$s} ;
		}

		unshift @args, $ar unless $s eq $autodynaload::dl_findfile ;

		local $autodynaload::disable_expandspec = 0 ;
		@ret = $s->(@args) ;
		# warn "@args -> @ret" ;
		last if scalar(@ret) ;
	}

	return wantarray ? @ret : $ret[0] ;
}


sub _dl_expandspec {
	my @args = @_ ;

	return undef if $autodynaload::disable_expandspec ;
	$autodynaload::dl_expandspec->(@args) ;
}


sub is_loaded {
    my $class = shift ;
    my $filename = shift ;
    my %opts = @_ ;

	my $file = undef ;
	foreach my $so (@DynaLoader::dl_shared_objects){
			if ($so =~ /$filename\.$dlext$/){
				$file = $so ;
				last ;
			}
	}

    return $class->_name_or_open_or_slurp_file($file, %opts) ;
}


sub is_installed {
    my $class = shift ;
    my $filename = shift ;
    my %opts = @_ ;

	$installed = new ExtUtils::Installed() unless $installed ;

    my $file = undef ;
	if (File::Spec->file_name_is_absolute($filename)){
		$file = "$filename.$dlext" ;
	}
    else {
		foreach my $module ($installed->modules()){
			foreach my $test ($installed->files($module)){
				if ($test =~ /$filename\.$dlext$/){
					$file = $test ;
					last ;
				}
			}
		}
	}
	
    return $class->_name_or_open_or_slurp_file($file, %opts) ;
}


sub get_unresolved_deps {
	my $class = shift ;
	my $so = shift ;

	open(LDD, "/usr/bin/ldd $so |") or
		croak("Can't execute /usr/bin/ldd: $!") ;
	my @ret = () ;
	while (<LDD>){
		my $dep = $_ ;
		if ($dep =~ /^\s*(.*?)  => not found/){
			push @ret, $dep ;
		}
	}
	
	return @ret ;
}



BEGIN {
	local $^W ;
	no strict 'refs' ;
    *{'DynaLoader::dl_expandspec'}  = \&autodynaload::_dl_expandspec ;
	*{'DynaLoader::bootstrap'} = \&autodynaload::_bootstrap ;
	*{'DynaLoader::dl_findfile'} = \&autodynaload::_dl_findfile ;
	# Force XSLoader to use DynaLoader
	*{'XSLoader::load'} = \&autodynaload::_bootstrap_inherit ;
}


1 ;
__END__
=head1 NAME

autodynaload - Dynamically locate shared objects on your system

=head1 SYNOPSIS

  use autodynaload sub {
    my ($this, $f) = @_ ;
    if ($f eq 'some_object'){
      return "/path/to/some_object.so" ;
    }
    return undef ;
  } ;


=head1 DESCRIPTION

C<autodynaload> allows you to specify the location of a shared object at
runtime. It does so by overriding the proper L<DynaLoader> methods and
allowing for handlers to be registered.

The subroutine argument can be either a coderef or scalar value, in which
case it will be used as a symbolic reference. Note: no error will be generated
if the symbolic reference does not resolve. This allows a handler to "kick in"
at later time when the subroutine in question is actually defined.

The subroutine must return the absolute path to the shared object. A return 
value of undef will pass control to the next handler (either a previous 
C<autodynaload> handler or L<DynaLoader>'s default mechanism).


=head1 CONSTRUCTOR

=over 4

=item new ( HANDLER )

Creates a new C<autodynaload> object that will call HANDLER when invoked. For it
to be of any use you must place the object in the proper array (in this case the
@autodynaload::INC array) using the L<insert> method.

=back


=head1 METHODS

Note: C<autodynaload> extends L<autorequire>. See L<autorequire> for methods not 
documented here.

=over 4

=item $ar->insert( POS )

See L<autorequire/insert>. In this case the array will be @autodynaload::INC.

=item $ar->delete ()

See L<autorequire/delete>. In this case the array will be @autodynaload::INC.

=item autodynaload->is_loaded( FILENAME )

Convenience method that returns the absolute path of FILENAME if the shared
object FILENAME is found in the @DynaLoader::dl_shared_objects array. Returns
undef is the shared object is not loaded.

=item autodynaload->is_installed( FILENAME )

Convenience method that returns the absolute path of FILENAME if the shared 
object FILENAME is installed on the system. It does this using the 
L<ExtUtils::Installed> module. Please that this method is somewhat slow.

=back


=head1 SEE ALSO

L<DynaLoader>, L<autorequire>.


=head1 AUTHOR

Patrick LeBoutillier, E<lt>patl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Patrick LeBoutillier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
