
use strict;
use warnings;

package WWW::Shopify::Liquid::Exception;
use Devel::StackTrace;
use overload
	fallback => 1,
	'""' => sub { return $_[0]->english . ($_[0]->line ? " on line " . $_[0]->line . ", character " . $_[0]->{line}->[1] .  ($_[0]->{line}->[3] ? ", file " . $_[0]->{line}->[3] : '') : ''); };
sub line { return $_[0]->{line} ? (ref($_[0]->{line}) && ref($_[0]->{line}) eq "ARRAY" ? $_[0]->{line}->[0] : $_[0]->{line}) : undef; }
sub column { return $_[0]->{line} && ref($_[0]->{line}) && ref($_[0]->{line}) eq "ARRAY" ? $_[0]->{line}->[1] : undef; }
sub stack { return $_[0]->{stack}; }
sub english { return $_[0]->{error} ? $_[0]->{error} : "Unknown Error"; } 
sub error { return $_[0]->{error}; }

use Devel::StackTrace;
use Scalar::Util qw(blessed);

sub new {
	my ($package, $line, $message) = @_;
	my $self = bless {
		error => $message,
		stack => Devel::StackTrace->new,
	}, $package;
	if (blessed($line)) {
		if ($line->isa('WWW::Shopify::Liquid::Tag') || $line->isa('WWW::Shopify::Liquid::Token') || $line->isa('WWW::Shopify::Liquid::Operator') || $line->isa('WWW::Shopify::Liquid::Filter')) {
			$self->{token} = $line;
			$line = $line->{line};
		}
	}
	if (defined $line && ref($line) ne "ARRAY") {
		print STDERR $self->stack->as_string . "\n";
		die "Improper exception.";
	}
	$self->{line} = $line;
	return $self;
}

package WWW::Shopify::Liquid::Exception::Timeout;
use base 'WWW::Shopify::Liquid::Exception';

package WWW::Shopify::Liquid::Exception::Control;
use base 'WWW::Shopify::Liquid::Exception';
sub english { return "Control exception"; }

sub initial_render { my $self = shift; $self->{initial_render} = \@_ if int(@_) > 0; return $self->{initial_render}; }

package WWW::Shopify::Liquid::Exception::Control::Continue;
use base 'WWW::Shopify::Liquid::Exception::Control';
sub english { return "Continue exception"; }

package WWW::Shopify::Liquid::Exception::Control::Break;
use base 'WWW::Shopify::Liquid::Exception::Control';
sub english { return "Break exception"; }

package WWW::Shopify::Liquid::Exception::Lexer;
use base 'WWW::Shopify::Liquid::Exception';
sub english { return "Lexer exception"; }

package WWW::Shopify::Liquid::Exception::Lexer::UnbalancedBrace;
use base 'WWW::Shopify::Liquid::Exception::Lexer';
sub english { return "Unbalanced brace found"; }

package WWW::Shopify::Liquid::Exception::Lexer::UnbalancedSingleQuote;
use base 'WWW::Shopify::Liquid::Exception::Lexer';
sub english { return "Unbalanced single quote found"; }

package WWW::Shopify::Liquid::Exception::Lexer::UnbalancedDoubleQuote;
use base 'WWW::Shopify::Liquid::Exception::Lexer';
sub english { return "Unbalanced double quote found"; }

package WWW::Shopify::Liquid::Exception::Lexer::UnbalancedTag;
use base 'WWW::Shopify::Liquid::Exception::Lexer';
sub english { return "Unbalanced tag found"; }

package WWW::Shopify::Liquid::Exception::Lexer::UnbalancedOutputTag;
use base 'WWW::Shopify::Liquid::Exception::Lexer';
sub english { return "Unbalanced output tag found"; }

package WWW::Shopify::Liquid::Exception::Lexer::UnbalancedLexingHalt;
use base 'WWW::Shopify::Liquid::Exception::Lexer';
sub english { return "Unbalanced lexing halter found"; }

package WWW::Shopify::Liquid::Exception::Lexer::InvalidSeparator;
use base 'WWW::Shopify::Liquid::Exception::Lexer';
sub english { return "Invalid separator during array/hash construction."; }

package WWW::Shopify::Liquid::Exception::Lexer::Tag;
use base 'WWW::Shopify::Liquid::Exception::Lexer';
sub english { return "Malformed tag "  . $_[0]->{message}; }


package WWW::Shopify::Liquid::Exception::Parser;
use base 'WWW::Shopify::Liquid::Exception';
sub english { return "Parser exception"; }

package WWW::Shopify::Liquid::Exception::Parser::NoClose;
use base 'WWW::Shopify::Liquid::Exception::Parser';
sub english { return "Unable to find closing tag for '" . $_[0]->{token}->stringify . "'"; }

package WWW::Shopify::Liquid::Exception::Parser::Operands;
use base 'WWW::Shopify::Liquid::Exception::Parser';

sub new {
	my $package = shift;
	my $self = $package->SUPER::new(@_);
	my ($token, $op1, $op, $op2) = @_;
	$self->{operands} = [$op1, $op, $op2];
	return $self;
}

sub english { return "All operands inside an expression must be joined by operators, under most conditions."; }

package WWW::Shopify::Liquid::Exception::Parser::NoOpen;
use base 'WWW::Shopify::Liquid::Exception::Parser';
sub english { return "Unable to find opening tag for '" . $_[0]->{token}->stringify . "'"; }

package WWW::Shopify::Liquid::Exception::Parser::Arguments;
use base 'WWW::Shopify::Liquid::Exception::Parser';
sub english { return "Invalid arguments"; }

package WWW::Shopify::Liquid::Exception::Parser::UnknownTag;
use base 'WWW::Shopify::Liquid::Exception::Parser';
sub english { return "Unknown tag '" . $_[0]->{token}->stringify . "'"; }

package WWW::Shopify::Liquid::Exception::Parser::NakedInnerTag;
use base 'WWW::Shopify::Liquid::Exception::Parser';
sub english { return "Inner tag " . $_[0]->{token}->stringify . " found without enclosing statement"; }

package WWW::Shopify::Liquid::Exception::Parser::UnknownFilter;
use base 'WWW::Shopify::Liquid::Exception::Parser';
sub english { return "Unknown filter '" . $_[0]->{token}->stringify . "'"; }

package WWW::Shopify::Liquid::Exception::Optimizer;
use base 'WWW::Shopify::Liquid::Exception';
sub english { return "Optimizer exception"; }

package WWW::Shopify::Liquid::Exception::Renderer;
use base 'WWW::Shopify::Liquid::Exception';
sub english { return "Rendering exception"; }

package WWW::Shopify::Liquid::Exception::Renderer::Unimplemented;
use base 'WWW::Shopify::Liquid::Exception::Renderer';
sub english { return "Unimplemented method"; }

package WWW::Shopify::Liquid::Exception::Renderer::Arguments;
use base 'WWW::Shopify::Liquid::Exception::Renderer';
sub english { print STDERR $_[0]->stack->as_string; return "Wrong type? Number of arguments."; }

1;