package blx::xsdsql::ios::ostream;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(Exporter);
use subs qw(print say binmode);

my  %t=( overload => [ qw ( print  say binmode) ]);
our %EXPORT_TAGS=( all => [ map { @{$t{$_}} } keys %t ],%t); 
our @EXPORT_OK=( @{$EXPORT_TAGS{all}} );
our @EXPORT=qw( );

sub _init_output_stream {
	my ($self,%params)=@_;
	$self->{LINE_SEPARATOR}=$params{LINE_SEPARATOR} if defined $params{LINE_SEPARATOR};
	return $self unless defined $self->{OUTPUT_STREAM}; 
	my $r=ref($self->{OUTPUT_STREAM});
	if ($r eq  'ARRAY') {
		$self->{O}->{I}=0;  
		$self->{LINE_SEPARATOR}="\n" unless defined $self->{LINE_SEPARATOR};
	}
	elsif ($r eq 'CODE') {
		$self->{_OUTPUT_BUFFER}="";
	}
	return $self;
}


sub new {
	my ($class,%params)=@_;
	my $s=bless(\%params,$class);
	return $s->_init_output_stream(%params);
}

sub set_output_descriptor {
	my ($self,$fd,%params)=@_;
	$self->{OUTPUT_STREAM}=$fd;
	return $self->_init_output_stream(%params);
}

sub mode {
	my ($self,$value,%params)=@_;
	my $stream = $self->{OUTPUT_STREAM};
	affirm { defined $stream } "OUTPUT_STREAM not set";
	
	if ($stream eq *STDOUT || $stream eq *STDERR || ref($stream) eq 'GLOB') {
		my $r=CORE::binmode($stream,$value);
		croak  "error: $!" unless defined $r;
	}
	$self->{BINMODE}=$value;
	return $self;
}
		
sub put_chars {
	my $self=shift;
	my $stream = $self->{OUTPUT_STREAM};
	affirm { defined $stream } "OUTPUT_STREAM not set";
	
	if ($stream eq *STDOUT || $stream eq *STDERR || ref($stream) eq 'GLOB') {
		my $r=CORE::print $stream @_;
		croak  "error: $!" unless defined $r;
	}
	elsif (ref($stream) eq '') { #string
		$self->{OUTPUT_STREAM} .= join('',@_);
	}
	elsif (ref($stream) eq 'ARRAY') {
		for my $i(0..scalar(@_) - 1) {
			my $s=$_[$i];
			affirm { defined $s } "element $i is not defined";
			my $n=index($s,$self->{LINE_SEPARATOR});
			while($n >= 0) {
				my $p=substr($s,0,$n);
				$stream->[$self->{O}->{I}]='' 
					unless defined  $self->{OUTPUT_STREAM}->[$self->{O}->{I}];
				$stream->[$self->{O}->{I}].=$p;
				$s=substr($s,$n + length($self->{LINE_SEPARATOR}));
				$n=index($s,$self->{LINE_SEPARATOR});
				$stream->[++$self->{O}->{I}]='';
			}
			$stream->[$self->{O}->{I}].=$s;
		}					
	}
	elsif (ref($stream) eq 'CODE') {
		if (defined $self->{LINE_SEPARATOR} && length($self->{LINE_SEPARATOR})) { 
			for my $i(0..scalar(@_) - 1) {
				my $s=$_[$i];
				affirm { defined $s } "element $i is not defined";
				$s=$self->{_OUTPUT_BUFFER}.$s;
				my $n=index($s,$self->{LINE_SEPARATOR});
				while($n >= 0) {
					my $p=substr($s,0,$n + length($self->{LINE_SEPARATOR}));
					$stream->($self,$p);
					if (($n + length($self->{LINE_SEPARATOR})) > length($s)) {
						$s='';
						$n=-1;
					}
					else {
						$s=substr($s,$n + length($self->{LINE_SEPARATOR}));
						$n=index($s,$self->{LINE_SEPARATOR});
					}
				}
				$self->{_OUTPUT_BUFFER}=$s;
			}
		}
		else {
			$stream->($self,@_);
		}
	}
	elsif (ref($stream) eq 'SCALAR') { #reference to scalar
		$$stream .= join('',@_);
	}
	else {
		croak ref($stream).': type non implemented';
	}
	return $self;
}


sub print { 
	my $self=shift;
	return CORE::print($self,@_) unless ref($self) =~/::/; #if $self is not a class use CORE::print
	return $self->put_chars(@_);
}



sub put_line { my $self=shift; return $self->put_chars(@_,"\n"); }

sub say {  
			my $self=shift;
			return $self->put_line(@_) if ref($self) =~/::/;  	  #if $self is not a class use CORE::say if is implemented
			local $@;
			my $r=eval("CORE::say($self,@_)"); ## no critic
			return print STDOUT $self,@_,"\n" if $@;
			return $r;
}

sub binmode { 
	my $self=shift;
	return CORE::binmode($self,@_) unless ref($self) =~/::/; #if $self is not a class use CORE::binmode
	return $self->mode(@_);
}

sub flush {
	my ($self,%params)=@_;
	my $stream = $self->{OUTPUT_STREAM};
	affirm { defined $stream } "OUTPUT_STREAM not set";
	if (ref($stream) eq 'CODE') {
		$stream->($self,$self->{_OUTPUT_BUFFER}) if length($self->{_OUTPUT_BUFFER});
	}  
	return  $self;	
}

if (__FILE__ eq $0) {

	use constant {
		STR 	=> 'this is a string'
		,K   	=> 'this is a key'
		,STRM	=> "this is\na multi\nline\nstring\n"
	};

	my $out=*STDOUT;
	my $streamer=__PACKAGE__->new(OUTPUT_STREAM => \$out);
	binmode($streamer,':encoding(UTF-8)');
	$streamer->put_line(STR);

	$out='';
	$streamer=__PACKAGE__->new(OUTPUT_STREAM => \$out);
	$streamer->put_line(STR);
	croak "check failed " if $out ne STR."\n";

	my @arr=();
	$streamer=__PACKAGE__->new(OUTPUT_STREAM => \@arr);
	$streamer->put_line(STR);
	croak "check failed " if scalar(@arr) != 2;
	croak "check failed " if join('',@arr) ne STR;
	$streamer->put_chars(STR,STR,"\n",STR);
	croak "check failed " if scalar(@arr) != 3;
	croak "check failed " if join("\n",@arr) ne STR."\n".STR.STR."\n".STR;

	
	@arr=();
	$streamer=__PACKAGE__->new(OUTPUT_STREAM => sub { push @arr,$_[1]},LINE_SEPARATOR => "\n" );
	$streamer->put_line(STRM);
	$streamer->flush;
	croak "check failed " if join('',@arr) ne STRM."\n";
	croak "check failed " if scalar(@arr) != 5;
	@arr=();
	$streamer=__PACKAGE__->new(OUTPUT_STREAM => sub { push @arr,$_[1] },LINE_SEPARATOR => "\n" );
	$streamer->put_line(STRM,STRM);
	$streamer->flush;
	croak "check failed " if join('',@arr) ne STRM.STRM."\n";
	croak "check failed " if scalar(@arr) != 9;

	@arr=();
	$streamer=__PACKAGE__->new(OUTPUT_STREAM => sub { push @arr,$_[1] },LINE_SEPARATOR => 's' );
	$streamer->put_chars(K,'s');
	$streamer->flush;
	croak "check failed " if join('',@arr) ne K."s";
	croak "check failed " if scalar(@arr) != 3;

	@arr=();
	$streamer=__PACKAGE__->new(OUTPUT_STREAM => sub { push @arr,$_[1] },LINE_SEPARATOR => 's' );
	$streamer->put_chars(K);
	$streamer->flush;
	croak "check failed " if join('',@arr) ne K;
	croak "check failed " if scalar(@arr) != 3;
	
	$streamer=__PACKAGE__->new(OUTPUT_STREAM => '');
	$streamer->put_line(STR);
	croak "check failed " if $streamer->{OUTPUT_STREAM} ne STR."\n";

}

1;

__END__

=head1  NAME

blx::xsdsql::ios::ostream -  generic  output streamer into a  string,array,file descriptor or subroutine

=cut

=head1 SYNOPSIS

use blx::xsdsql::ios::ostream

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new




=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

this module defined the followed functions


new - constructor

    PARAMS:
        OUTPUT_STREAMER -  an array,string,soubroutine or a file descriptor (default not set)



set_output_descriptor - the first param  is a value same as OUTPUT_STREAMER

    the method return the self object



put_chars -   emit @_ on the streamer

    the method return the self object
    on error throw an exception


put_line  - equivalent to put_chars(@_,"\n");


print - equivalent to put_chars


say - equivalent to put_line


flush - flush the internal buffer


=head1 EXPORT

None by default.


=head1 EXPORT_OK

print

say

:all  export all

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
