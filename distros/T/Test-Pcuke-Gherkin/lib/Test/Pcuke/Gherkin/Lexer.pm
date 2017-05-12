package Test::Pcuke::Gherkin::Lexer;

use warnings;
use strict;
use utf8;

use Test::Pcuke::Gherkin::I18n;
=head1 NAME

Test::Pcuke::Gherkin::Lexer - roll your own cucumber

=head1 VERSION

Version 0.000001

=cut

our $VERSION = '0.000001';


=head1 SYNOPSIS

TODO SYNOPSIS

    use Test::Pcuke::Gherkin::Lexer;
	...
    my $lexens = Test::Pcuke::Gherkin::Lexer->scan( $input );
    ...

=cut

# TODO i18n!!!
my $REGEXP = {
	empty		=> [ qr{^\s*$}ix ],
	pragma		=> [ qr{^\s*#(?:\s*(\w+\s*:\s*\w+))+}i ],
	comment		=> [ qr{^\s*#}i ],
	tag			=> [ qr{@\w+}ix ],
	feature		=> [ qr{^\s*(feature: .*?)\s*$}ix ],
	any			=> [ qr{^\s*(.*?)\s*$}ix ],
	background	=> [ qr{^\s*(background:.*?)\s*$}ix ],
	scenario	=> [ qr{^\s*(scenario:.*?)\s*$}ix ],
	outline		=> [ qr{^\s*(scenario outline:.*?)\s*$}i, qr{^\s*(scenario template:.*?)\s*$}ix ],
	given		=> [ qr{^\s*(\*)\s*(.*?)\s*$}i, qr{^\s*(given)\s*(.*?)\s*$}ix ],
	when		=> [ qr{^\s*(\*)\s*(.*?)\s*$}i, qr{^\s*(when)\s*(.*?)\s*$}ix ],
	then		=> [ qr{^\s*(\*)\s*(.*?)\s*$}i, qr{^\s*(then)\s*(.*?)\s*$}ix ],
	and			=> [ qr{^\s*(\*)\s*(.*?)\s*$}i, qr{^\s*(and)\s*(.*?)\s*$}ix ],
	but			=> [ qr{^\s*(\*)\s*(.*?)\s*$}i, qr{^\s*(but)\s*(.*?)\s*$}ix ],
	examples	=> [ qr{^\s*(examples:.*?)\s*$}i, qr{^\s*(scenarios:.*?)\s*$}ix ],
	trow		=> [ qr{^ \s* \| (.*?) \| \s* $}ix ],
	text_quote	=> [ qr{^ \s* (""") \s* $}ix ],
};

my @LEVELS = qw{root};

my $TOKENIZERS = {
	root	=> [
		{
			regexps	=> ['empty'],
			mktoken => _skip() 
		},
		
		{
			regexps	=> ['pragma'],
			mktoken	=> _mktoken_split('PRAG', qr{\s*:\s*}),
		},
		
		{
			regexps	=> ['comment'],
			mktoken	=> _skip(),
		},
		
		{
			regexps	=> ['tag'],
			mktoken	=> _mktoken_perchunk('TAG'),
		},
		
		{
			regexps	=> ['feature'],
			mktoken	=> _mktoken_join('FEAT'),
			level	=> 'feature',
		},
		
		{
			regexps	=> ['any'],
			mktoken	=> _mktoken_join('ERR'),
		},
	],
	
	feature	=> [
		{
			regexps	=> ['empty', 'comment'],
			mktoken => _skip() 
		},
		
		{
			regexps	=> ['tag'],
			mktoken	=> _mktoken_perchunk('TAG'),
		},
		
		{
			regexps	=> ['background'],
			mktoken	=> _mktoken_join('BGR'),
			level	=> 'steps',
		},
		
		{
			regexps	=> ['scenario'],
			mktoken	=> _mktoken_join('SCEN'),
			level	=> 'steps',
		},
		
		{
			regexps	=> ['outline'],
			mktoken	=> _mktoken_join('OUTL'),
			level	=> ['outline', 'steps'],
		},
		
		{
			regexps	=> ['any'],
			mktoken	=> _mktoken_join('NARR'),
		},
	],
	
	steps	=> [
		{
			regexps	=> ['empty', 'comment'],
			mktoken => _skip() 
		},
		
		{
			regexps	=> [qw{given when then and but}],
			mktoken	=> sub {
				my ($self, $line, $type, $title) = @_;
				['STEP', uc $type, $title ]
			},
		},
		
		{
			regexps	=> ['text_quote'],
			mktoken	=> _skip(),
			level	=> 'text',
		},
		
		{
			regexps	=> ['trow'],
			mktoken	=> sub {
				my ($self, $line, @chunks) = @_;
				my @cols = map { s/^\s*|\s*$//g; $_ } split /\s*\|\s*/, $chunks[0];
				['TROW', @cols];
			}
		},
		
		{
			regexps	=> ['any'],
			mktoken	=> _mktoken_uplevel(),
		},
	],
	
	text	=> [
		{
			regexps	=> ['text_quote'],
			mktoken	=> _skip(),			# maybe _mktoken_skip_uplevel() ?
			level	=> 'steps',			# 'cause it is not very beautiful
		},
		{
			regexps	=> ['any'],
			mktoken => _mktoken_join('TEXT'),
		},
	],
	
	outline	=> [
		{
			regexps	=> ['empty', 'comment'],
			mktoken => _skip() 
		},
		
		{
			regexps	=> ['examples'],
			mktoken	=> _mktoken_join('SCENS'),
			level	=> 'scenarios',
		},
		
		{
			regexps	=> ['any'],
			mktoken	=> _mktoken_uplevel(),
		},
	],
	
	scenarios	=> [
		{
			regexps	=> ['empty', 'comment'],
			mktoken => _skip() 
		},
		
		{
			regexps	=> ['trow'],
			mktoken	=> _mktoken_split('TROW', qr{\s*\|\s*}), 
		},
		
		{
			regexps	=> ['any'],
			mktoken	=> _mktoken_uplevel(),
		},
	],
};

=head1 METHODS

=head2 scan $input

=cut

sub scan {
	my ($self, $input) = @_;
	my $result;
	my @lines = split /[\r\n]+/, $input;
	
	foreach my $line ( @lines ) {
		push @$result, @{ $self->_scan_line($line) };
	}
	
	return $result;
}

sub _scan_line {
	my ($self, $line) = @_;
	my @chunks;
	my @result;
	
	foreach my $tokenizer ( @{$TOKENIZERS->{ $self->_get_level } } ) {
		push @result, $self->_tokenize($tokenizer, $line);
		last if @result;
	}
	
	@result = grep { $_->[0] ne 'SKIP' } @result;
	
	$self->_process_pragmas( grep { $_->[0] eq 'PRAG' } @result);
	
	return \@result;
}

sub _tokenize {
	my ($self, $conf, $line) = @_;
	my @tokens;
	my @chunks;
	
	foreach my $re_name ( @{$conf->{regexps}} ) {
		foreach my $re ( @{ $REGEXP->{$re_name} } ) {
			@chunks = ($line =~ /$re/ig ); 
			if ( @chunks ) {
				push @tokens, $conf->{mktoken}->($self, $line, @chunks);
				
				if ( $conf->{level} ) {
					$conf->{level} = [$conf->{level}] unless ref $conf->{level};
					$self->_append_levels( @{ $conf->{level} } )
				}
				last;
			}
		}
		last if @tokens;
	}
	return @tokens;
}

sub _process_pragmas {
	my $self = shift;
	foreach (@_) {
		my ($prag, $name, $value) = @{$_};
		$self->_set_language($value)	if $name eq 'language'; 
	}
}

sub _set_language {
	my ($self, $language) = @_;
	$REGEXP = Test::Pcuke::Gherkin::I18n->patterns( $language );
}

sub _skip { return sub {['SKIP']} }

sub _mktoken_join {
	my ($label) = @_;
	return sub {
		my ($self, $line, @chunks) = @_;
		[$label, join(' ', @chunks) ]
	}
}

sub _mktoken_uplevel {
	return sub {
		my ($self, $line, @chunks) = @_;
		$self->_level_up;
		return @ { $self->_scan_line($line) };
	}
}

sub _mktoken_perchunk {
	my ($label) = @_;
	return sub {
		my ($self, $line, @chunks) = @_;
		map {[$label,$_]} @chunks;
	}
}

sub _mktoken_split {
	my ($label, $re) = @_;
	return sub {
		my ($self, $line, @chunks) = @_;
		map {[$label, map { s/^\s*|\s*$//g; $_ } split /$re/i, $_]} @chunks;
	}
}

sub reset {
	my ($self) = @_;
	$self->_set_levels( 'root' );
}

sub _set_levels {
	my $self = shift;
	@LEVELS = @_; 
}

sub _append_levels {
	my ($self, @levels) = @_;
	push @LEVELS, @levels;
}

sub _level_up {
	my ($self) = @_;
	if ( @LEVELS > 1 ) {
		pop @LEVELS;
	}
	else {
		# confess can't go nowhere
	}
}

sub _get_level { $LEVELS[-1] }

=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Lexer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke-Gherkin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is released under the following license: artistic


=cut

1; # End of Test::Pcuke::Gherkin::Lexer
