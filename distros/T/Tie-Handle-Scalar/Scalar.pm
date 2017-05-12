package Tie::Handle::Scalar;
use 5.006;

use strict;
use Carp;
use FileHandle;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $AUTOLOAD $FILEHANDLE);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = "0.1";


sub TIEHANDLE {
	my $class = bless {}, shift;
	
	my ($stringref) = @_;
	
	if (! defined($stringref)) {
		my $temp_s = ''; 
		$stringref = \$temp_s;
	}
	
	if (ref($stringref) ne "SCALAR") {
		croak "need a reference to a scalar,";
	}
	
	$class->{position} = 0;
	$class->{data} = $stringref;
	$class->{end} = 0;
	my $tmpfile = $class->{tmpfile} = '.tmp.' . $$;
	$FILEHANDLE = new FileHandle "$tmpfile", O_RDWR|O_CREAT or croak "$tmpfile: $!";
	$class->{FILENO} = $FILEHANDLE->fileno();
	$class;
}

sub FILENO {
	my $class = shift;
	return $class->{FILENO};
}

sub WRITE {
	my $class = shift;
	my($buf,$len,$offset) = @_;
        $offset = 0 if (! defined $offset);
    	my $data = substr($buf, $offset, $len);
    	my $n = length($data);
    	$class->print($data);
        return $n;
}

sub PRINT { 
	my $class = shift;
        ${$class->{data}} .= join('', @_);
    	$class->{position} = length(${$class->{data}});
    	1;
}

sub PRINTF {
	my $class = shift;
	my $fmt = shift;
	$class->PRINT(sprintf $fmt, @_);
}

sub READ {
	my $class = shift;
	
	my ($buf,$len,$offset) = @_;
    	$offset = 0 if (! defined $offset);
    	
    	my $data = ${ $class->{data} };
    	
    	if ($class->{end} >= length($data)) {
		return 0;
	}
	$buf = substr($data,$offset,$len);
        $_[0] = $buf;
        $class->{end} += length($buf);
        return length($buf);
}

sub READLINE { 
	my $class = shift; 
	if ($class->{end} >= length(${ $class->{data} })) {
		return undef;
	}
	my $recsep = $/;
	my $rod = substr(${ $class->{data} }, $class->{end}, -1);
	$rod =~ m/^(.*)$recsep{0,1}/; # use 0,1 for line sep to include possible no \n on last line
	my $line = $1 . $recsep;
	$class->{end} += length($line);
	return $line;
}

sub CLOSE { 
	my $class = shift;
	if (-e $class->{tmpfile}) {
		$FILEHANDLE->close();
		unlink $class->{tmpfile} or warn $!;
	}
	$class = undef;
	1;
}

sub DESTROY {
	my $class = shift;
	if (-e $class->{tmpfile}) {
		unlink $class->{tmpfile} or warn $!;
	}
	$class = undef;
	1;undef $class;
}

1;
__END__

=head1 NAME

Tie::Handle::Scalar - Perl extension for tieing a scalar to a filehandle.

=head1 SYNOPSIS

  use Tie::Handle::Scalar;
  my $file = "This is a test";
  tie *FH, 'Tie::Handle::Scalar', \$file;
  print FH "\nAnother line\n\n\n\n";
  while (<FH>) {
      print;
  }
  untie FH;


=head1 DESCRIPTION

WARNING - This ONLY works with perl version 5.6.0< or above. This may be due to interfaces to handles in older versions of perl not being complete ;)
Tie::Handle::Scalar allows you to tie a scalar to a filehandle.
Supported and unsupported/untested methods are listed below.
I wrote this before I realised there were 2 other modules that do something similar.... IO::Stringy and IO::String.
These two may work better for you. But I couldn't get either of them to work with Net::FTP as they don't appear to support the FILENO method.

=head1 SUPPORTED METHODS


=item TIEHANDLE

=item FILENO

=item WRITE

=item PRINT

=item READ

=item READLINE

=item CLOSE

=item DESTROY

=head1 UNSUPPORTED/UNTESTED METHODS (to be done).


=item PRINTF

=item SYSREAD

=item SYSWRITE

=item GETC


And there are a few others I'm sure

=head1 AUTHOR

Andy Williams (andy.williams@lampsolutions.co.uk)

=head1 REPORTING BUGS

Please direct any bugs/fixes to the author.

=head1 SEE ALSO

perl(1). IO::Stringy. IO::String

=head1 THANKS

Dave Cross (dave@dave.org.uk) for answering most if not all my questions.

=head1 COPYRIGHT 

Copyright 2001 Andy Williams. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
