# template_lexer.pl
#   perl library associated with template.y (the template parser definition)
#
# NOTE:  extensive use of Perl5 regular expressions is made in this
#  file.  see perlre(1) 

package Text::PORE::Parser;
use English;

my $TAG_PREFIX = "PORE";

my $lexer_token;
my $lexer_buffer = '';
my $lineno = 1;

# yyerror
#  displays error messages
#   called by yyparse
sub yyerror {
    my ($msg) = @_;
	print STDERR "$lineno: $msg at '$yylval'\n";
}

# countlines
#  increments the line counter used by yyerror
sub countlines {
    my ($string) = shift;

	if (defined $string) {
    	$lineno += ($string =~ s/\n/$1/gos);
	}
}

# returns the current line number (in the template) for debugging purposes
sub getlineno {
    return $lineno;
}

sub setInput {
    my ($input) = shift;

    $Parser::INPUT = $input;
}

# yylex
#  supplies tokens for yyparse
#  NOTE: no escape sequences are defined
#  (don't put a '>' within a tag, etc.)

sub yylex {
    my $input;

    while (1) {
	if ($INTAG) {           # Are we inside a PORE tag?
	    $lexer_buffer =~ s/^\s+//; # ignore whitespace in tags
	    countlines($MATCH);
	    
	    if ($lexer_buffer =~ s/^$TAG_PREFIX.(\w+)//si) {
		$yylval = lc($1);
		if ($yylval eq "if")   { $lexer_token = 'IF_ID';   }
		elsif ($yylval eq "else") { $lexer_token = 'ELSE_ID'; }
		elsif ($yylval eq "context")  { $lexer_token = 'CONTEXT_ID';  }
		elsif ($yylval eq "link") { $lexer_token = 'LINK_ID'; }
		elsif ($yylval eq "list") { $lexer_token = 'LIST_ID'; }
		elsif ($yylval eq "render") { $lexer_token = 'RENDER_ID'; }
		elsif ($yylval eq "ref")  { $lexer_token = 'REF_ID';  }
		elsif ($yylval eq "table") { $lexer_token = 'TABLE_ID'; }
		else { yyerror("Unrecognized tag"); }
	    } elsif ($lexer_buffer =~ s/^\///s) {
		$yylval = $MATCH;		# Match slash ('/')
		$lexer_token = 'SLASH';
	    } elsif ($lexer_buffer =~ s/^(\w+)//s) {
		$yylval = $MATCH;		# Match an identifier
		$lexer_token = 'NAME';
	    } elsif ($lexer_buffer =~ s/^=\s*([\.\w]+)//s) {
		$yylval = $1;		# Match a value ('= val')
		$lexer_token = 'VAL';
	    } elsif ($lexer_buffer =~ s/^=\s*([\'\"])\1//s) {
		$yylval = $1;		# Match a value ('=""')
		$lexer_token = 'VAL';
	    } elsif ($lexer_buffer =~ s/^=\s*([\'\"])(([^\\]|\\.)*?)\1//s) {
		$yylval = $2;		# Match a value ('= "long val"')
		$lexer_token = 'VAL';
	    } elsif ($lexer_buffer =~ s/^>//s) {
		$yylval = $MATCH;		# Match a close_bracket ('>')
		$lexer_token = 'CLOSE_BRACKET';
	    } elsif ($lexer_buffer =~ s/^<//s) {
		$yylval = $MATCH;
		$lexer_token = 'OPEN_BRACKET';
	    } 
	    
	} else {                      # Not in a PORE tag
	    if (defined $lexer_buffer && 
			$lexer_buffer =~ s/^<(?=\/?$TAG_PREFIX\.)//si) {
		$yylval = $MATCH;		# Match an open_bracket ('<')
		$lexer_token = 'OPEN_BRACKET';
	    } elsif (defined $lexer_buffer && 
			$lexer_buffer =~ s/^.+?(?=<\/?$TAG_PREFIX\.)|^.+//si) {
		$yylval = $MATCH;		    # Open_bracket followned by 
		$lexer_token = 'FREETEXT';
	    }
	}
	
	# Return match
	if ($lexer_token) {
	    my ($token_val) = eval "$$lexer_token";
	    $lexer_token = undef;
	    countlines($yylval);
	    return $token_val;

        # If we didn't match anything, grab more input
	} else {
	    $input = $Parser::INPUT->readLine();

	    if (!(defined $input) || !length($input)) { 
		# if no more input, and unrecognized token, error
			if ($lexer_buffer) {
			    $lexer_buffer =~ s/\n.*$/.../s;
			    print STDERR "$lineno: Unrecognized token " .
				"[$lexer_buffer].\nAborting with errors\n";
			    exit;
			} else { # if no more input, and no more tokens, we're done
			    return 0;
			}
	    }
		$lexer_buffer .= $input if defined $input;
	}
    }
}

1;
