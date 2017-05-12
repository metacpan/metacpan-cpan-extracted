package blx::xsdsql::ios::istream;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use base qw(Exporter);

use overload "<>" => \&get_line;
#warning - exist a bug into package overload 
#calling @y=<$x> the operator <> return a one line (wantarray is false)

my  %t=( overload => [ ( "<>" ) ]);
our %EXPORT_TAGS=( all => [ map { @{$t{$_}} } keys %t ],%t); 
our @EXPORT_OK=( @{$EXPORT_TAGS{all}} );
our @EXPORT=qw( );

sub _pop_str {  #pop n chars from str pointer
	my ($p,$n)=@_;
	my $l=length($$p);
	my $s=substr($$p,$l - $n);
	$$p=substr($$p,0,$l - $n);
	return defined wantarray ? $s : undef;
}

sub _push_str { # push s to str pointer
	my ($p,$s,$maxsize)=@_;
	my $r=$$p.$s;
	$$p=substr($r,length($r) - $maxsize);	
	return defined wantarray ? $$p : undef;
} 

sub _init_input_stream {
	my ($self,%params)=@_;
	return $self unless defined $self->{INPUT_STREAM}; 
	my $r=ref($self->{INPUT_STREAM});
	if ($r eq '') { #string
		$self->{I}->{P}=0;  #current position
	}
	elsif ($r eq 'ARRAY') {
		$self->{I}={ R => 0,P => 0};  #current index + current position
	}
	elsif ($r eq 'SCALAR') { #reference to scalar
		$self->{I}->{P}=0;  #current index
	}
	elsif ($self->{INPUT_STREAM} eq *STDIN || $r eq 'GLOB') {
		$params{MAX_PUSHBACK_SIZE}=0 unless defined $params{MAX_PUSHBACK_SIZE};
		affirm {  $params{MAX_PUSHBACK_SIZE}=~/^\d+$/ } $params{MAX_PUSHBACK_SIZE}.': invalid param value MAX_PUSHBACK_SIZE';
		my $s='';
		$self->{BUFFER}=\$s;
		$self->{PUSHBACK_N}=0;
		$self->{MAX_PUSHBACK_SIZE}=$params{MAX_PUSHBACK_SIZE};
	}
	elsif ($r eq 'CODE') {
		#empty
	}
	else {
		croak $r.': type non implemented';
	}
	return $self;
}


sub new {
	my ($class,%params)=@_;
	my $max_pushback_size=delete $params{MAX_PUSHBACK_SIZE};
	my $self=bless(\%params,$class);
	return $self->_init_input_stream(MAX_PUSHBACK_SIZE => $max_pushback_size);
}


sub set_input_descriptor {
	my ($self,$fd,%params)=@_;
	$self->{INPUT_STREAM}=$fd;
	return $self->_init_input_stream(%params);
}


sub get_chars { 
	my ($self,$n,%params)=@_;
	$n=1 unless defined $n;
	my $stream=$self->{INPUT_STREAM};
	affirm { defined $stream } "INPUT_STREAM non set";
	affirm { $n=~/^\d+$/ } "$n: invalid first param value";
	return '' if $n == 0;
	my $r=ref($stream);
	if ($stream eq *STDIN || ref($stream) eq 'GLOB') {
		my $outs='';
		if ($self->{PUSHBACK_N}) {
			my $m=$n > $self->{PUSHBACK_N} ? $self->{PUSHBACK_N} : $n;
			$outs=_pop_str($self->{BUFFER},$m);
			$n -= $m;
			$self->{PUSHBACK_N}-=$m;  
		}
		if ($n) {
			my $s=undef;
			my $r=read $stream,$s,$n;
			croak "$!" unless defined $r;
			$s='' if $r == 0;
			if ($self->{MAX_PUSHBACK_SIZE} && length($s) > 0) {
				_push_str($self->{BUFFER},$s,$self->{MAX_PUSHBACK_SIZE});				
			}
			$outs.=$s;
		}
		return $outs;
	}
	elsif ($r eq '') { #string
		return  '' if  $self->{I}->{P} >= length($stream);
		my $s=substr($stream,$self->{I}->{P},$n);
		$self->{I}->{P} += $n;
		return $s;
	}
	elsif ($r eq 'ARRAY') {
		return '' if $self->{I}->{R} >= scalar(@{$self->{INPUT_STREAM}});
		my $s='';
		while($self->{I}->{R} < scalar(@$stream)  && length($s) < $n) {
			my $e=$self->{INPUT_STREAM}->[$self->{I}->{R}];
			$e='' unless defined $e;
			$s .= "\n" if $self->{I}->{P} == 0 && $self->{I}->{R} > 0;
			my $m=$n - length($s);
			$s .= substr($e,$self->{I}->{P},$m);	
			$self->{I}->{P} += $m;
			if ($self->{I}->{P}  >= length($e)) {
				$self->{I}->{P} = 0;
				++$self->{I}->{R};
			}
		}
		return $s;
	}
	elsif ($r eq 'CODE') {
		return $stream->($self,@_);
	}
	elsif ($r eq 'SCALAR') {
		return  '' if  $self->{I}->{P} >= length($$stream);
		my $s=substr($$stream,$self->{I}->{P},$n);
		$self->{I}->{P} += $n;
		return $s;
	}
	else {
		croak $r.': type non implemented';
	}
	undef;	
}

sub get_char {
	my ($self,%params)=@_;
	return $self->get_chars(1,%params);
}

sub get_line {
	my $self=shift;
	return <$self> if ref($self) ne  __PACKAGE__; 
	my $stream=$self->{INPUT_STREAM};
	affirm { defined $stream } "INPUT_STREAM non set";

	my $r=ref($stream);
	if (wantarray) {
		if ($stream eq *STDIN || $r eq 'GLOB') { 	#use the optimized version for file descriptor
			affirm { ! $self->{PUSHBACK_N}  } "push back not implemented for common streams";
			return <$stream>;
		} 
		my @s=();
		while(my $s=$self->get_line) {
			push @s,$s;
		}
		return @s;
	}

	if ($stream eq *STDIN || $r eq 'GLOB') {
		affirm { ! $self->{PUSHBACK_N}  } "push back not implemented for common streams";
		my $s=<$stream>;
		return $s;
	}
	elsif ($r eq '') { #string
		return if $self->{I}->{P} >= length($stream);
		my $s='';
		while($self->{I}->{P} < length($stream)) {
			my $c=substr($stream,$self->{I}->{P}++,1);
			$s .= $c;
			last if $c eq "\n";
		}			
		return $s;
	}
	elsif ($r eq 'ARRAY') {
		return if $self->{I}->{R} >= scalar(@$stream);
		return 	$stream->[$self->{I}->{R}++]."\n";
	}
	elsif ($r eq 'CODE') {
		affirm { ! $self->{PUSHBACK_N}  } "push back not implemented for code streamer";
		return $stream->($self,@_);
	}
	elsif ($r eq 'SCALAR') {
		return if $self->{I}->{P} >= length($$stream);
		my $s='';
		while($self->{I}->{P} < length($$stream)) {
			my $c=substr($$stream,$self->{I}->{P}++,1);
			$s .= $c;
			last if $c eq "\n";
		}			
		return $s;
	}
	else {
		croak $r.': type non implemented';
	}
	undef;	
}

sub push_back {
	my ($self,$n,%params)=@_;
	my $stream=$self->{INPUT_STREAM};
	affirm { defined $stream } "INPUT_STREAM non set";
	$n=1 unless defined $n;
	affirm { $n=~/^\d+$/ } "$n: invalid first param value";
	my $r=ref($stream);
	if ($stream eq *STDIN || ref($stream) eq 'GLOB') {
		$self->{PUSHBACK_N} += $n;
		affirm { 
					$self->{PUSHBACK_N} <= $self->{MAX_PUSHBACK_SIZE} 
					&&  
					$self->{PUSHBACK_N} <= length(${$self->{BUFFER}})
		} "pushback oveflow ";
	}
	elsif ($r eq '' || $r eq 'SCALAR') { 
		$self->{I}->{P} -= $n;
		affirm { $self->{I}->{P} >= 0 } "$n: invalid value for push_back";
	}
	else {
		croak "$r: push_back not implemented for this type";
	}
	return $self;
}

if (__FILE__ eq $0) {

	my @arr=();
	my $streamer=__PACKAGE__->new(INPUT_STREAM => \@arr);
	my $s=$streamer->get_chars(1);
	confess "check failed " if  length($s); 

	@arr= qw(pippo pluto paperino);
	$streamer=__PACKAGE__->new(INPUT_STREAM => \@arr);
	$s=$streamer->get_chars(10);
	confess "check failed " unless $s eq  "pippo\nplut";
	$s=$streamer->get_chars(3);
	confess "check failed " unless $s eq  "o\np";

	$s=$streamer->get_chars(3000);
	confess "check failed " unless $s eq  "aperino";

	$s=$streamer->get_chars(3000);
	confess "check failed " if length($s);
	


	my $src=join("\n",@arr);
	$streamer=__PACKAGE__->new(INPUT_STREAM => \$src);
	$s=$streamer->get_chars(10);
	confess "check failed " unless $s eq  "pippo\nplut";
	$s=$streamer->get_chars(3);
	confess "check failed " unless $s eq  "o\np";

	$s=$streamer->get_chars(3000);
	confess "check failed " unless $s eq  "aperino";

	$s=$streamer->get_chars(3000);
	confess "check failed " if  length($s);


	$streamer->set_input_descriptor(\@arr);
	my @t=$streamer->get_line;
	confess "check failed " if @t ne @arr;

	$streamer->set_input_descriptor(\@arr);
	@t=<$streamer>; 
	print STDERR  "(W) check failed - overload bug in ",__PACKAGE__," line  ",__LINE__," - continue \n" if @t ne @arr;

	$streamer->set_input_descriptor(\$src);
	@t=$streamer->get_line;
	confess "check failed " if @t ne @arr;

}

1;

__END__



=head1  NAME

blx::xsdsql::ios::istream - generic iterator for string,array,file descriptor or subroutine

=cut

=head1 SYNOPSIS

use blx::xsdsql::ios::istream

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

        INPUT_STREAMER  - an array,string,soubroutine or a file descriptor (default not set)

        MAX_PUSHBACK_SIZE - the max size in characters for the internal buffer used by push_back and the streamer is a file descriptor
                            the default is 0


set_input_descriptor - the first param  is a value same as INPUT_STREAMER
                       params:
                       MAX_PUSHBACK_SIZE - equal to same param of the constructor

    the method return the self object



get_chars - the first param is the number of chars to read (default 1)

    on EOF the method return a  null string
    if the first param is == 0 the method return null string
    on error throw an exception


get_char - equivalent to get_chars(1)


get_line - return a line in scalar mode or an array in array mode

    on EOF the method return a  null string
    on error throw an exception
    Note: if INPUT_STREAM is an array the line is an element of the array
    the line has the new line terminator "\n" also the result of <> iterator


push_back - push character into the streamer
            the first param is a number of characters to push back
            the default is 1
    the metod return the self object


=head1 EXPORT

None by default.


=head1 EXPORT_OK

<> - same as get_line

:overload - export only the overload methods

WARNING  - exist a bug for a call in context list - wantarray is every false
Ex: my @a=<$stream>  return one line  in @a


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
