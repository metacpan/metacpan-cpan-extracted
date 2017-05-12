package Variable::Eject;

=head1 NAME

Variable::Eject - Eject variables from hash to current namespace

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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
use Devel::Declare ();
use Lexical::Alias ();

our @CARP_NOT = qw(Devel::Declare);
our $SUBNAME = 'eject';

sub import{
	my $class = shift;
	my $caller = caller;
	Devel::Declare->setup_for(
		$caller,
		{ $SUBNAME => { const => \&parse } }
	);
	{
		no strict 'refs';
		*{$caller.'::'.$SUBNAME } = sub (@_) { warn "this shouldn't be called - report your case to author\n" };
	}
}


sub parse {
	my $parser = Variable::Eject->new($_[1]);
	return if $parser->get_word() ne $SUBNAME;
	$parser->process();
}

package # hide
	Variable::Eject;

use uni::perl;
our @CARP_NOT = qw(Variable::Eject Devel::Declare);

sub DEBUG () { 0 }

sub new {
	my ($class, $offset) = @_;
	#print STDERR "new called at $offset\n" if DEBUG;
	bless \$offset, $class;
}
sub whereami {
	my $self = shift;
	my $line = Devel::Declare::get_linestr;
	warn "..>".substr($line,$$self);
}
sub process {
	my $self = shift;
	$self->whereami if DEBUG;
	$$self+=Devel::Declare::toke_move_past_token($$self);
	$self->whereami if DEBUG;
	$self->skip_spaces();
	my $args = $self->extract_args();
	$args =~ s/(\r|\n)//go;
	my @args = split /\s*(?:,|=>)\s*/, $args;
	@args > 1 or croak( 'Usage: '.$Variable::Eject::SUBNAME.'( $source_hash => $scalar, @array, %hash, ... )' );
	my $from = shift @args;
	#warn "Have args $args: $from => [ @args ]";
	my $inj;
	for (@args) {
		#warn "arg = >$_<\n";
		s{(?:^\s+|\s+$)}{}sg; # ' $var ' => '$var'
		my $type = substr($_,0,1,'');
		s{^\s+}{}s; # ' { var } ' => '{ var }'
		s{^\s*\{?\s*|\s*\}?\s*$}{}sg;
		#$_ = '{'.$_.'}' unless m/^\{.+\}$/;
		if ($type eq '$') {
			$inj .= 'Lexical::Alias::alias( '.$from.'->{'.$_.'} => my $'.$_.' );';
			#$inj .= 'Lexical::Alias::alias( '.$from.'->'.$_.' => my $'.$_.' );';
		} else {
			$inj .= 'Lexical::Alias::alias( '.$type.'{'.$from.'->{'.$_.'}} => my '.$type.$_.' );';
			#$inj .= 'Lexical::Alias::alias( '.$type.'{'.$from.'->'.$_.'} => my '.$type.$_.' );';
		}
		#warn "$inj";
	}
	$self->whereami if DEBUG;
	$self->inject("() if 0; $inj");
	return;
}

sub get_word {
	my $self = shift;

	print STDERR "get_word called at $$self\n" if DEBUG;

	if (my $len = Devel::Declare::toke_scan_word($$self, 1)) {
		return substr(Devel::Declare::get_linestr(), $$self, $len);
	}
	return '';
}

sub skip_spaces {
	my $self = shift;

	print STDERR "skip_spaces called at $$self\n" if DEBUG;

	$$self += Devel::Declare::toke_skipspace($$self);
}

sub extract_args {
	my $self = shift;

	print STDERR "extract_args called at $$self\n" if DEBUG;

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
			require Carp;
			Carp::croak("Unbalanced text supplied for assert");
		}
		substr($linestr, $$self, $length) = '';
		Devel::Declare::set_linestr($linestr);

		return $proto;
	} else {
		croak "Can't use '.$Variable::Eject::SUBNAME.' without brackets. Use '.$Variable::Eject::SUBNAME.'(...)";
	}
	return '';
}

sub inject{
	my ($self, $inject) = @_;

	print STDERR "inject called at $$self for '$inject'\n" if DEBUG;

	my $linestr = Devel::Declare::get_linestr;
	if ($$self > length($linestr)){
		croak("Parser tried to inject data outside program source, stopping");
	}
	substr($linestr, $$self, 0) = $inject;
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

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Variable::Eject
