package Win32::API;

use 5.006002;

use strict;
use warnings;

use Carp;
use Time::Local ();

our $VERSION = '0.008';

my %mock = (
    KERNEL32	=> {
	FileTimeToLocalFileTime => {
	    arg		=> [ qw{ P P } ],
	    ret		=> 'I',
	    code	=> sub {
		$_[1] = $_[0];
		return 1;
	    },
	},
	FileTimeToSystemTime	=> {
	    arg		=> [ qw{ P P } ],
	    ret		=> 'I',
	    code	=> sub {
		my ( undef, $ft ) = unpack 'LL', $_[0];
		my @local = localtime $ft;
		@local = reverse @local[0..5];
		$local[0] += 1900;
		$local[1] += 1;
		splice @local, 2, 0, 0;
		push @local, 0;
		@_[1] = pack 'ssssssss', @local;
		return 1;
	    },
	},
	GetFileTime	=> {
	    arg		=> [ qw{ N P P P } ],
	    ret		=> 'I',
	    code	=> sub {
		my ( $fh ) = @_;
		my ( undef, undef, undef, undef, undef, undef, undef,
		    undef, $atime, $mtime, $ctime ) = stat $fh
		    or return;
		$_[1] = pack 'LL', 0, $ctime;
		$_[2] = pack 'LL', 0, $atime;
		$_[3] = pack 'LL', 0, $mtime;
		return 1;
	    },
	},
	LocalFileTimeToFileTime	=> {
	    arg		=> [ qw{ P P } ],
	    ret		=> 'I',
	    code	=> sub {
		$_[1] = $_[0];
		return 1;
	    },
	},
	SetFileTime	=> {
	    arg		=> [ qw{ N P P P } ],
	    ret		=> 'I',
	    code	=> sub {
		my ( $fh, $atime, $mtime ) = @_;
		( undef, $atime ) = unpack 'LL', $atime;
		( undef, $mtime ) = unpack 'LL', $mtime;
		return utime $atime, $mtime, $fh;
	    },
	},
	SystemTimeToFileTime	=> {
	    arg		=> [ qw{ P P } ],
	    ret		=> 'I',
	    code	=> sub {
		my @localtime = unpack 'sssssss', $_[0];
		splice @localtime, 2, 1;
		$localtime[0] -= 1900;
		$localtime[1] -= 1;
		my $local = Time::Local::timelocal( reverse @localtime );
		$_[1] = pack 'LL', 0, $local;
		return 1;
	    },
	},
    },
);

foreach my $dll ( keys %mock ) {
    foreach my $name ( keys %{ $mock{$dll} } ) {
	$mock{$dll}{$name}{name} = $name;
    }
}

sub new {
    my ( $class, $lib, $sub, $arg, $ret ) = @_;
    my $mock = join '__', '_mock', $lib, $sub;
    $mock{$lib}
	or croak "No mock code available for $lib.dll";
    my $info = $mock{$lib}{$sub}
	or croak "No mock code available for $lib $sub()";
    my $arg_got = join ' ', @{ $arg };
    my $arg_want = join ' ', @{ $info->{arg} };
    $arg_got eq $arg_want
	or croak "Incorrect arguments '$arg_got' for $lib $sub()";
    $ret = $info->{ret}
	or croak "Incorrect return value '$ret' for $lib $sub()";
    return bless $info, ref $class || $class;
}

# Note that in pretty much ALL the following, the Microsoft calling
# convention requires that arguments be modified, and that those
# modifications be visible to the caller. For this reason we must not
# unpack the argument list, at least not completely.
sub Call {
    my $self = shift;
    $self->_validate( @_ );
    return $self->{code}->( @_ );
}

{
    my @trace;

    sub __mock_add_to_trace {
	my @args = @_;
	push @trace, \@args;
	return;
    }

    sub __mock_clear_trace {
	@trace = ();
	return;
    }

    sub __mock_get_trace {
	return \@trace;
    }

}

{
    my $size_quad = _size( pack 'LL', 0, 0 );

    my %valid = (
	N	=> sub {
	    return;
	},
	P	=> sub {
	    # I used to validate this as being the same size as a
	    # quadword, but this is wrong, because the real Win32::API
	    # takes this to mean "make a pointer to the passed value,"
	    # which can be any size. It still needs to be preallocated,
	    # though.
	    return;
	},
    );

    sub _validate {
	my ( $self, @arg ) = @_;
	@arg == @{ $self->{arg} }
	    or croak 'Wrong number of arguments for $self->{name}()';
	my $inx = 0;
	foreach ( @arg ) {
	    my $spec = $self->{arg}[$inx];
	    my $code = $valid{$spec}
		or croak "No validation coded for '$spec'";
	    $code->( $self, $inx, $_ );
	} continue {
	    $inx++;
	}
	__mock_add_to_trace( $self->{name}, @arg );
	return;
    }
}

sub _size {
    my ( $arg ) = @_;
    my @c = unpack 'c*', $arg;
    return scalar @c;
}

1;

__END__

=head1 NAME

mock::Win32::API - Mock interface to Windows dlls.

=head1 SYNOPSIS

 use lib qw{ inc/mock };
 use Win32::API;
 
 my $lft2ft = Win32::API->new(
     KERNEL32 => 'LocalFileTimeToFileTime',
     [ qw{ P P } ], 'I' );
 my $lft = windows_style_local_file_time();
 my $ft = $lft;	# Just to get space allocated
 $lft2ft->Call( $lft, $ft )
     or die "Call failed";

=head1 DESCRIPTION

This module is private to this distribution. It can be changed or
retracted without notice. Documentation is for the benefit of the
author.

This Perl class mocks the L<Win32::API|Win32::API> module and whatever
system calls are needed by this package.

=head1 METHODS

This class supports the following methods, which are private to this
package:

=head2 new

 my $lft2ft = Win32::API->new(
     KERNEL32 => 'LocalFileTimeToFileTime',
     [ qw{ P P } ], 'I' );

This static method instantiates the object. The arguments are the name
of the DLL being mapped, the name of the function in that DLL, a
reference to an array encoding the types of the arguments to that
function, and the type of the return value. There must be a mocked
version of the function already coded in this module. The arguments will
be checked.

=head2 Call

 $lft2ft->Call( $lft, $ft )
     or die "Call failed";

This method invokes the mocked function. Just as in the case of the real
L<Win32::API|Win32::API>, all output arguments must already have space
preallocated.

=head1 SEE ALSO

L<Win32::API|Win32::API> (the real one).

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Tom Wyant (wyant at cpan dot org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
