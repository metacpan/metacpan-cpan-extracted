package autorequire ;

use strict ;
use Carp ;
use File::Spec ;
use IO::File ;


our $VERSION = '0.08' ;


sub import {
	my $class = shift ;
	my $sub = shift ;

	my $ar = $class->new($sub) ;
	$ar->insert(-1) if defined($sub) ;
}


sub new {
	my $class = shift ;
	my $sub = shift ;
	my $list = shift || \@INC ;

	my $this = {} ;
	$this->{'sub'} = $sub ;
	$this->{'list'} = $list ;

	bless($this, $class) ;
}


sub _get_sub {
	my $this = shift ;

	return $this->{'sub'} ;
}


sub _get_list {
	my $this = shift ;

	return $this->{'list'} ;
}


# Insert $this into @INC at the specified
# position.
sub insert {
	my $this = shift ;
	my $idx = shift ;

	my $l = $this->_get_list() ;
	if (! scalar(@{$l})){
		push @{$l}, $this ;
	}
	else {
		my $cur = $l->[$idx] ;
		splice(@{$l}, $idx, 1, 
			($idx >= 0 
				? (scalar(@{$l}) > $idx 
					? ($this, $cur) 
					: ($this))
				: ($cur, $this))) ;
	}
}


# Remove $this from the @INC array.
sub delete {
	my $this = shift ;

	for (my $i = 0 ; $i < scalar(@{$this->{'list'}}) ; $i++){
		if ($INC[$i] eq $this){
			splice(@{$this->{'list'}}, $i, 1) ;
			$i-- ;
		}
	}
}


sub enable { 
	my $this = shift ;

	$this->{disabled} = 0 ;
}


sub disable { 
	my $this = shift ;

	$this->{disabled} = 1 ;
}


sub autorequire::INC {
	my ($this, $f) = @_ ;

	return undef if $this->{disabled} ;

	my $s = $this->_get_sub() ;
	if (! ref($s)){
		# Symbolic reference. It may not be defined yet.
		return undef if !defined(&{$s}) ;
		$s = \&{$s} ;
	}

	my $ret = $s->($this, $f) ;
	if (defined($ret)){
		if (! _is_handle($ret)){
			# Maybe the value returned is the name of a file.
			if (($ret !~ /\n/)&&(-r $ret)){
				my $file = $ret ;
				$ret = undef ;
				open($ret, "<$file") or
					croak("Can't open '$file' for reading: $!") ;
			}
			else {
				my $code = $ret ;
				$ret = undef ;
				open($ret, '<', (ref($code) ? $code : \$code)) or
					croak("Can't open in-memory filehandle: $!") ;
			}
		}
	}

	return $ret ;
}


# Pasted from File::Copy
sub _is_handle {
	my $h = shift ;

	return (ref($h)
		? (ref($h) eq 'GLOB'
			|| UNIVERSAL::isa($h, 'GLOB')
				|| UNIVERSAL::isa($h, 'IO::Handle'))
		: (ref(\$h) eq 'GLOB')) ;
}


sub is_loaded {
	my $class = shift ;
	my $filename = shift ;
	my %opts = @_ ;

	my $I = $INC{$filename} ;
	return $class->_name_or_open_or_slurp_file($I, %opts) ;
}


sub is_installed {
	my $class = shift ;
	my $filename = shift ;
	my %opts = @_ ;

	my $file = undef ;
	if (File::Spec->file_name_is_absolute($filename)){
		$file = $filename ;
	}
	else {
		foreach my $I (@INC){
			next if ref($I) ;
			my $test = File::Spec->catfile($I, $filename) ;
			if (-r File::Spec->catfile($I, $filename)){
				$file = $test ;
				last ;
			}
		}
	}

	return $class->_name_or_open_or_slurp_file($file, %opts) ;
}


sub _name_or_open_or_slurp_file {
	my $class = shift ;
	my $file = shift ;
	my %opts = @_ ;
	
	return undef unless defined($file) ;

	if (($opts{'open'})||($opts{slurp})){
		my $fh = new IO::File("<$file") ;
		croak("Can't open '$file' for reading: $!") unless defined($fh) ;

		if ($opts{slurp}){
			local $/ = undef ;
			return <$fh> ;
		}

		return $fh ;
	}

	return $file ;
}


1 ;
__END__
=head1 NAME

autorequire - Generate module code on demand

=head1 SYNOPSIS

  use autorequire sub {
    my ($this, $f) = @_ ;
    if ($f eq 'Useless.pm'){
      return "package Useless ;\n1 ;"
    }
    return undef ;
  } ;


=head1 DESCRIPTION

C<autorequire> allows you to automatically generate code for modules that are
missing from your installation. It does so by placing a handler at the end of
the @INC array and forwarding requests for missing modules to the subroutine 
provided.

The subroutine argument can be either a coderef or scalar value, in which 
case it will be used as a symbolic reference. Note: no error will be generated
if the symbolic reference does not resolve. This allows a handler to "kick in"
at later time when the subroutine in question is actually defined.

The subroutine must return the code for the module in the form of a filehandle,
a scalar reference or a scalar value. A return value of undef will pass control
to the next handler (either a previous C<autorequire> handler or Perl's default
require mechanism).


=head1 CONSTRUCTOR

=over 4

=item new ( HANDLER )

Creates a new C<autorequire> object that will call HANDLER when invoked. For it
to be of any use you must place the object in the proper array (in this case the
@INC array) using the L<insert> method.

=back


=head1 METHODS

=over 4

=item $ar->insert( POS )

Convenience method that places the C<autorequire> object at position POS in the 
@INC array. 

  $ar->insert(-1)   is equivalent to   push @INC, $ar 
  $ar->insert(0)    is equivalent to   unshift @INC, $ar

Note that it is possible to insert the same C<autorequire> object multiple times
in the @INC array by calling $ar->insert() repeatedly.

=item $ar->delete ()

Convenience method that removes every occurence of $ar from the @INC array.

=item $ar->disable ()

Disables $ar, effectively causing it to be skipped over when the INC array
is processed.

=item $ar->enabled ()

Enabled $ar, effectively causing it to be considered when the INC array
is processed.

=item autorequire->is_loaded( FILENAME )

Convenience method that returns the absolute path of FILENAME if the module
FILENAME is found in the %INC hash. Returns undef is the module is not loaded.

  autorequire->is_loaded($filename)   is equivalent to   $INC{$filename}

=item autorequire->is_installed( FILENAME )

Convenience method that returns the absolute path of FILENAME if the module
FILENAME is installed on the system. It does this by concatenating every 
entry in @INC with FILENAME and checking if the resulting path exists. Returns
undef if the module is not installed.

=back


=head1 SEE ALSO

L<perlfunc/require>.


=head1 AUTHOR

Patrick LeBoutillier, E<lt>patl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Patrick LeBoutillier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
