package Net::LDAP::Shell::Parse;

#-----------------------------------------------------------------------------------
#
# Net::LDAP::Shell::Parse
#
#-----------------------------------------------------------------------------------

use vars qw($VERSION);

$VERSION = 1.00;

#@ISA = qw(Net::LDAP::Shell);

use Parse::Lex;

use Net::LDAP::Shell::Parser;

# these are global because Parse::Lex defaines the terms as global,
# so otherwise these get redefined and i get warnings
# yuck
use vars qw(@LEXGRAMMAR $LEXER $PARSER);

	#'RETURN', '\n',
	#'SPACE', '\s',
	#'COLON', ':',
	#'EQUALS', '=',
# I choose this quoting method so i can see the code
@LEXGRAMMAR = (
	'COMMENT', '(?<!\\$)#.*$',
	'SPACE', '[ \t]+',
	'FIRSTWORD:NAME', '\w+',
	'DQSTRING', [ '"', '[^"]*', '"' ], sub {
			my ($token, $string) = @_;
			$string =~ s/^"//;
			$string =~ s/"$//;
			return $string;
	},
	'SQSTRING', [ "'", "[^']*", "'" ], sub {
			my ($token, $string) = @_;
			$string =~ s/^'//;
			$string =~ s/'$//;
			return $string;
	},
	'STRING', '\S+',
	'ERROR', '(?s:.*)',
		sub {
			my $line = $_[0]->line();
			die "line $line: syntax error: \"$_[1]\"\n";
		}
);

# shouldn't this be a function or something?
#unless ($LEXER) {
#	$LEXER = Parse::Lex->new(@LEXGRAMMAR) or
#		die "Could not make lexer\n";
#	$LEXER->configure('Skip' => '[ \t]+');
	#$LEXER->configure('Skip' => '');
	#$LEXER->configure();
#}

#------------------------------------------------------------------------
# _lexer
sub _lexer {
	my ($parser) = @_;
	my ($token, $lexer);

	$lexer = $parser->YYData->{'lexer'};
#	print "lexer = $lexer\n";

	while (1) {
		$token = $lexer->next;

		if ($lexer->eoi) {
			#print "lexer returning EOI\n";
			return ('', undef);
			#return ('EOL', undef);
		}

		next if ($token->name eq 'COMMENT');

#		print "lexer returning (" . $token->name . ", \"" . $token->text . "\")\n";
		return ($token->name, $token->text);
	}
}
# _lexer
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# _error
sub _error {
	my ($parser) = @_;
	my ($config, $lexer, $file, $line);

	$file = $parser->YYData->{'file'};

	$lexer = $parser->YYData->{'lexer'};
	$line = $lexer->line;

	die("parse error\n");
}
# _error
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# Net::LDAP::Shell::Parse::parse
sub parse {
	my ($class,$obj,$objlist,$ref,$file,@lines,$comment,$refclass);

	$line = shift;

	#my $typehandle = new FileHandle $file, "r" or
	#	die "Could not open $file: $!\n";

	#open TYPES, $file or die "Could not open $file: $!\n";
	#@lines = <TYPES>;
	#close TYPES;

	Parse::Lex->inclusive('FIRSTWORD');

	unless ($LEXER) {
		$LEXER ||= Parse::Lex->new(@LEXGRAMMAR) or
			die "Could not make lexer\n";
		$LEXER->configure('Skip' => '[ \t]+');
		#$LEXER->configure('Skip' => '');
		#$LEXER->configure();
	}


	$LEXER->from($line);
	unless ($PARSER) {
		$PARSER ||= Net::LDAP::Shell::Parser->new();
	}
	#my $parser = Net::LDAP::Shell::Parser->new();
	$PARSER->YYData->{'lexer'} = $LEXER;
	$LEXER->start('FIRSTWORD');

	return $PARSER->YYParse(yylex => \&_lexer,
		#yydebug => 0x1F,
		yyerror => \&_error
	);

	#if (wantarray) {
	#	return @{ $parser->YYData->{'objects'} };
	#} else {
	#	return $parser->YYData->{'objects'};
	#}
}
# Net::LDAP::Shell::Parse::parse
#-----------------------------------------------------------------------------------

=head1 NAME

Net::LDAP::Shell::Parse - Modules for parsing Net::LDAP::Shell lines

=head1 SYNOPSIS

Net::LDAP::Shell::Parse

=head1 DESCRIPTION

B<Net::LDAP::Shell::Parse>

=head1 OPTIONS

=head1 SEE ALSO

L<Net::LDAP::Shell>

=head1 AUTHOR

Luke A. Kanies, luke@madstop.com

=for html <hr>

I<$Id: Parse.pm,v 1.4 2004/01/06 22:19:40 loosifer Exp $>

=cut
1;
