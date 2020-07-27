package Variable::Eject;

=head1 NAME

Variable::Eject - Eject variables from hash to current namespace

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Variable::Eject;

    my $hash = {
        scalar => 'scalar value',
        array  => [1..3],
        hash   => { my => 'value' },
    };

    # Now, eject vars from hash
    eject(
        $hash => $scalar, @array, %hash,
    );

    # Let's look
    say $scalar;
    say @array;
    say keys %hash;

    # Let's modify (source will be modified)
    $scalar .= ' modified';
    shift @array;
    $hash{another} = 1;

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 eject ( $source_hash => $scalar, @array, %hash ... );

=cut

use uni::perl;
m{
use strict;
use warnings;
}x;
use Devel::Declare;
use Lexical::Alias ();
use Carp ();

our $SUBNAME = 'eject';
our @CARP_NOT = qw(Variable::Eject Devel::Declare);

BEGIN {
	if (!defined &Variable::Eject::DEBUG) {
		if ($ENV{ PERL_VARIABLE_EJECT_DEBUG }) {
			*DEBUG = sub () { 1 };
		} else {
			*DEBUG = sub () { 0 };
		}
	}
}

sub import{
	my $class = shift;
	my $caller = caller;
	Devel::Declare->setup_for(
		$caller,
		{ $SUBNAME => { const => \&parse } }
	);
	{
		no strict 'refs';
		*{$caller.'::'.$SUBNAME } = sub (@) { Carp::carp( (0+@_)." <@_> this shouldn't be called - report your case to author\n" ) };
	}
}

sub parse {
	my $parser = Variable::Eject->new($_[1]);
	$parser->process();
}

sub new {
	my ($class, $offset) = @_;
	bless \$offset, $class;
}

sub whereami {
	my $self = shift;
	my $line = Devel::Declare::get_linestr();
	warn "..>".substr($line,$$self);
}

sub process {
	my $self = shift;
	
	$self->whereami if DEBUG;
	
	$$self += Devel::Declare::toke_skipspace($$self);
	
	if (my $len = Devel::Declare::toke_scan_word($$self, 1)) {
		my $subname = substr(Devel::Declare::get_linestr(), $$self, $len);
		warn "Skip subname $subname" if DEBUG;
		return if $subname ne $SUBNAME;
	}
	
	my $move = Devel::Declare::toke_move_past_token($$self);
	warn "Move past token +$move" if DEBUG;
	$$self += $move;
	
	$$self += Devel::Declare::toke_skipspace($$self);
	
	$self->whereami if DEBUG;
	$self->skip_spaces();
	
	my $args = $self->extract_args();
	
	$args =~ s/(\r|\n)//go;
	my @args = split /\s*(?:,|=>)\s*/, $args;
	@args > 1 or croak( 'Usage: '.$Variable::Eject::SUBNAME.'( $source_hash => $scalar, @array, %hash, ... )' );
	my $from = shift @args;
	warn "Have args $args: $from => [ @args ]" if DEBUG;
	my $inj;
	for (@args) {
		s{(?:^\s+|\s+$)}{}sg; # ' $var ' => '$var'
		my $type = substr($_,0,1,'');
		s{(?:^\s+|\s+$)}{}sg; # ' { var } ' => '{ var }'
		#s{^\s+}{}s; # ' { var } ' => '{ var }'
		s{^\s*\{?\s*|\s*\}?\s*$}{}sg;
		warn "arg = <$type : $_>\n" if DEBUG;
		#$_ = '{'.$_.'}' unless m/^\{.+\}$/;
		if ($type eq '$') {
			$inj .= 'Lexical::Alias::alias( '.$from.'->{'.$_.'} => my $'.$_.' );';
		} else {
			$inj .= 'Lexical::Alias::alias( '.$type.'{'.$from.'->{'.$_.'}} => my '.$type.$_.' );';
		}
	}
	warn "$inj" if DEBUG;
	$self->whereami if DEBUG;
	$self->inject($inj);
	return;
}

sub skip_spaces {
	my $self = shift;
	$$self += Devel::Declare::toke_skipspace($$self);
}

sub extract_args {
	my $self = shift;
	warn "extract_args called at $$self\n" if DEBUG;
	my $linestr = Devel::Declare::get_linestr();
	if (substr($linestr, $$self, 1) eq '(') {
		my $length = Devel::Declare::toke_scan_str($$self);
		my $proto = Devel::Declare::get_lex_stuff();
		Devel::Declare::clear_lex_stuff();
		$linestr = Devel::Declare::get_linestr();
		if (
			$length < 0
				||
			$$self + $length > length($linestr)
		){
			Carp::croak("Unbalanced text supplied");
		}
		warn "<<< '$linestr'\n" if DEBUG;
		my $hide = '(42) if 0;';
		substr($linestr, $$self, $length) = $hide;
		warn ">>> '$linestr'\n" if DEBUG;
		$$self += length $hide;
		Devel::Declare::set_linestr($linestr);
		
		return $proto;
	} else {
		Carp::croak "Can't use ".$SUBNAME.' without brackets. Use '.$SUBNAME.'(...)';
	}
	return '';
}

sub inject{
	my ($self, $inject) = @_;
	
	warn "inject called at $$self for '$inject'\n" if DEBUG;
	
	my $linestr = Devel::Declare::get_linestr();
	
	warn "<<< '$linestr'\n" if DEBUG;
	
	if ($$self > length($linestr)) {
		croak("Parser tried to inject data outside program source, stopping");
	}
	substr($linestr, $$self, 0) = $inject;
	warn ">>> '$linestr'\n" if DEBUG;
	
	Devel::Declare::set_linestr($linestr);
	$$self += length($inject);
}


=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-variable-eject at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Variable-Eject>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2020 Mons Anderson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Variable::Eject
