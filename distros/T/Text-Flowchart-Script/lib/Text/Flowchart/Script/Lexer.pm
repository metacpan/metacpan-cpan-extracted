package Text::Flowchart::Script::Lexer;
use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Feed Lexer);

use Lex;
our %patt = (
	     D => '[0-9]',
	     L => '[a-zA-Z_]',
	     );


our @tokens =
    (
     'COMMENT' => qr'/\*.+?\*/'so,
     'IDENTIFIER' => qr"$patt{L}($patt{D}|$patt{L})*"o,
     'STRING_LITERAL' => $patt{L}.'?(\'|\")(\\.|[^\\"])*\1',
     'CONSTANT' => qr"$patt{D}+"o, sub { "'$_[1]'" },
     'LEFTP' => '\(',
     'RIGHTP' => '\)',
     'LEFTSB' => '\[',
     'RIGHTSB' => '\]',
     'RELATE_OP' => '\->',
     'COLON'  => '[:]',
     'COMMA'  => qr'(,|=>)'o,
     'ASSIGN' => '[=]',
     'EOS'    => '[;]',
     'NEWLINE' => '[\n]',
     'TAB' => '[\t]',
     
     'ERROR' => '.+', sub { die "Unknown lexicon ( $_[1] ) encountered\n" }
     );

our $lexer = Lex->new(@tokens);

sub Feed{
    my $src = shift;
    my $code;
    if($src && -f $src){
	local $/;
	open _, $src or die $!;
	$code=<_>;
	close _;
    }
    elsif($src){
	$code = $src;
    }
    else{
	local $/;
	print ">> Enter your source code from STDIN\n\n";
	$code = <STDIN>;
    }
    $lexer->from($code);
}

sub Lexer{
  TOKEN:
    my $token = $lexer->nextToken;
    if (not $lexer->eof) {
	goto TOKEN if $token->name eq __PACKAGE__.'::NEWLINE';
	goto TOKEN if $token->name eq __PACKAGE__.'::TAB';
	goto TOKEN if $token->name eq __PACKAGE__.'::COMMENT';

	my ($type, $value) = ($token->name(), $token->get());
	$type=~s/^.+::(.+)/$1/o;
	goto TOKEN if $type eq 'COMMENT';
	$value =~ s/\n//go;
	return ($type, $value);
    }
    return ('', undef);
}


1;
