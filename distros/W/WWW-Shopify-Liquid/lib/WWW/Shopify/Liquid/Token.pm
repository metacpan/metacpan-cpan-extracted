
package WWW::Shopify::Liquid::Token;
use base 'WWW::Shopify::Liquid::Element';
sub new { return bless { line => $_[1], core => $_[2] }, $_[0]; };
sub stringify { return $_[0]->{core}; }
sub tokens { return $_[0]; }

package WWW::Shopify::Liquid::Token::Operator;
use base 'WWW::Shopify::Liquid::Token';

package WWW::Shopify::Liquid::Token::Operand;
use base 'WWW::Shopify::Liquid::Token';

package WWW::Shopify::Liquid::Token::String;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub process { my ($self, $hash) = @_; return $self->{core}; }

package WWW::Shopify::Liquid::Token::Number;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub process { my ($self, $hash) = @_; return $self->{core}; }

package WWW::Shopify::Liquid::Token::NULL;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub process { return undef; }

# package WWW::Shopify::Liquid::Token::True;
# use base 'WWW::Shopify::Liquid::Token::Operand';
# sub process { return 1; }

# package WWW::Shopify::Liquid::Token::False;
# use base 'WWW::Shopify::Liquid::Token::Operand';
# sub process { return 0; }

# package WWW::Shopify::Liquid::Token::Blank;
# use base 'WWW::Shopify::Liquid::Token::Operand';
# sub process { return ''; }

package WWW::Shopify::Liquid::Token::Bool;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub process { my ($self, $hash) = @_; return $self->{core}; }

package WWW::Shopify::Liquid::Token::FunctionCall;
use base 'WWW::Shopify::Liquid::Token::Operand';

use Scalar::Util qw(looks_like_number reftype blessed);

sub new {
	my $package = shift;
	return bless {
		line => shift,
		method => shift,
		self => shift,
		arguments => [@_]
	}, $package;
}

sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	if ($action eq "render") {
		die new WWW::Shopify::Liquid::Exception::Renderer::Forbidden($self->{line}) unless $pipeline->make_method_calls;
		
		my @arguments = map { $self->is_processed($_) ? $_ : $_->render($pipeline, $hash) } @{$self->{arguments}};
		my $inner_self = $self->is_processed($self->{self}) ? $self->{self} : $self->{self}->render($pipeline, $hash);
		my $method = $self->is_processed($self->{method}) ? $self->{method} : $self->{method}->render($pipeline, $hash);
		die new WWW::Shopify::Liquid::Exception::Renderer($self->{line}, "Can't find method $method on $inner_self.") unless $inner_self && blessed($inner_self) && !ref($method);
		return $inner_self->$method(@arguments);
	}
	return $self;
	
}

package WWW::Shopify::Liquid::Token::Variable;
use base 'WWW::Shopify::Liquid::Token::Operand';

use Scalar::Util qw(looks_like_number reftype blessed);

sub new { my $package = shift; return bless { line => shift, core => [@_] }, $package; };
sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	my $place = $hash;
	
	my @inner = @{$self->{core}};
	my $unprocessed = 0;
	foreach my $part_idx (0..$#inner) {
		my $part = $inner[$part_idx];
		if (ref($part) eq 'WWW::Shopify::Liquid::Token::Variable::Processing') {
			$place = $part->$action($pipeline, $hash, $place);
		}
		else {
			my $key = $self->is_processed($part) ? $part : $part->$action($pipeline, $hash);
			
			return $self unless defined $key && $key ne '';
			$self->{core}->[$part_idx] = $key if $self->is_processed($key) && $action eq "optimize";
			if (defined $place) {
				if (blessed($place) && $place->isa('WWW::Shopify::Liquid::Resolver')) {
					$place = $place->resolver->($place, $hash, $key);
				} elsif (reftype($place) && reftype($place) eq "HASH" && exists $place->{$key}) {
					$place = $place->{$key};
				} elsif (reftype($place) && reftype($place) eq "ARRAY" && looks_like_number($key) && defined $place->[$key]) {
					$place = $place->[$key];
				} elsif ($pipeline->make_method_calls && blessed($place) && $place->can($key)) {
					$place = $place->$key;
				} else {
					$unprocessed = 1;
					$place = undef;
				}
			}
			
		}
	}
	return $self if $unprocessed;
	return $place->resolver->($place, $hash) if (blessed($place) && $place->isa('WWW::Shopify::Liquid::Resolver'));
	return $place;
}
sub stringify { return join(".", map { $_->stringify } @{$_[0]->{core}}); }

sub set {
	my ($self, $pipeline, $hash, $value) = @_;
	my @vars = map { $self->is_processed($_) ? $_ : $_->render($pipeline, $hash) } @{$self->{core}};
	my ($reference) = $pipeline->variable_reference($hash, \@vars);
	$$reference = $value;
	return 1;
}


sub get {
	my ($self, $pipeline, $hash) = @_;
	my @vars = map { $self->is_processed($_) ? $_ : $_->render($pipeline, $hash) } @{$self->{core}};
	my ($reference) = $pipeline->variable_reference($hash, \@vars, 1);
	return $reference ? $$reference : undef;
}

package WWW::Shopify::Liquid::Token::Variable::Processing;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub process {
	my ($self, $hash, $argument, $action, $pipeline) = @_;
	return $self if !$self->is_processed($argument);
	my $result = $self->{core}->operate($hash, $argument);
	return $self if !$self->is_processed($result);
	return $result;
}

package WWW::Shopify::Liquid::Token::Variable::Named;
use base 'WWW::Shopify::Liquid::Token::Operand';

sub new { my $package = shift; return bless { line => shift, name => shift, core => shift }, $package; };
sub process {
	my ($self, $hash, $action, $pipeline) = @_;
	return { $self->{name} => $self->{core}->$action($pipeline, $hash) };
}


package WWW::Shopify::Liquid::Token::Grouping;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub new { my $package = shift; return bless { line => shift, members => [@_] }, $package; };
sub members { return @{$_[0]->{members}}; }

# Parentheses
package WWW::Shopify::Liquid::Token::Grouping::Parenthetical;
use base 'WWW::Shopify::Liquid::Token::Grouping';

# Like a grouping, but not really.
# Square brackets
package WWW::Shopify::Liquid::Token::Array;
use base 'WWW::Shopify::Liquid::Token::Operand';

sub new { 
	my ($package, $line, @members) = @_;
	# Check to see whether or not the incoming member array is separated by commas.
	# Should never begin with a comma, should never end with a comma, should always be 
	# 101010101 in terms of data and separators. If this is not the case, then we
	# Should throw a lexing exception.
	die new WWW::Shopify::Liquid::Exception::Lexer::InvalidSeparator($line) unless
		int(grep { ($_ % 2) == 0 && $members[$_]->isa('WWW::Shopify::Liquid::Token::Separator') } (0..$#members)) == 0 &&
		int(grep { ($_ % 2) == 1 && (!$members[$_]->isa('WWW::Shopify::Liquid::Token::Separator') || $members[$_]->{core} ne ",") } (0..$#members)) == 0;
		
	my $self = bless { 
		line => $line,
		members => [grep { !$_->isa('WWW::Shopify::Liquid::Token::Separator') } @members]
	}, $package; 
	return $self;
};

sub members { return @{$_[0]->{members}}; }
sub process { 
	my ($self, $hash, $action, $pipeline) = @_; 
	my @members = $self->members;
	$members[$_] = $members[$_]->$action($pipeline, $hash) for (grep { !$self->is_processed($members[$_]) } (0..$#members));
	if ($action eq "optimize") {
		$self->{members}->[$_] = $_ for (grep { $self->is_processed($members[$_]) } 0..$#members);
	}
	return [@members];
}

# Curly brackets
package WWW::Shopify::Liquid::Token::Hash;
use base 'WWW::Shopify::Liquid::Token::Operand';

sub members { return @{$_[0]->{members}}; }
sub new { 
	my ($package, $line, @members) = @_;
	
	@members = map { $_->isa('WWW::Shopify::Liquid::Token::Variable::Named') ? (
		WWW::Shopify::Liquid::Token::String->new($_->{line}, $_->{name}),
		WWW::Shopify::Liquid::Token::Separator->new($_->{line}, ':'),
		$_->{core}
	) : $_ } @members;
	
	die new WWW::Shopify::Liquid::Exception::Lexer::InvalidSeparator($line) unless
		int(grep { ($_ % 2) == 0 && $members[$_]->isa('WWW::Shopify::Liquid::Token::Separator') } (0..$#members)) == 0 &&
		int(grep { 
			($_ % 4) == 1 && (!$members[$_]->isa('WWW::Shopify::Liquid::Token::Separator') || $members[$_]->{core} ne ":") ||
			($_ % 4) == 3 && (!$members[$_]->isa('WWW::Shopify::Liquid::Token::Separator') || $members[$_]->{core} ne ",") 
		} (0..$#members)) == 0 && 
		int(grep { !$_->isa('WWW::Shopify::Liquid::Token::Separator') } @members) % 2 == 0;
		
	return bless { 
		line => $line,
		members => [grep { !$_->isa('WWW::Shopify::Liquid::Token::Separator') } @members]
	}, $package; 
};

sub process { 
	my ($self, $hash, $action, $pipeline) = @_; 
	my @members = $self->members;
	$members[$_] = $members[$_]->$action($pipeline, $hash) for (grep { !$self->is_processed($members[$_]) } (0..$#members));
	if ($action eq "optimize") {
		$self->{members}->[$_] = $_ for (grep { $self->is_processed($members[$_]) } 0..$#members);
	}
	return { @members };
}


package WWW::Shopify::Liquid::Token::Text;
use base 'WWW::Shopify::Liquid::Token::Operand';
sub new { 
	my $self = { line => $_[1], core => $_[2] };
	my $package = $_[0];
	$package = 'WWW::Shopify::Liquid::Token::Text::Whitespace' if !defined $_[2] || $_[2] =~ m/^\s*$/;
	return bless $self, $package;
};
sub process { my ($self, $hash) = @_; return $self->{core}; }

package WWW::Shopify::Liquid::Token::Text::Whitespace;
use base 'WWW::Shopify::Liquid::Token::Text';

package WWW::Shopify::Liquid::Token::Tag;
use base 'WWW::Shopify::Liquid::Token';
sub new { return bless { line => $_[1], tag => $_[2], arguments => $_[3], strip_left => $_[4], strip_right => $_[5] }, $_[0] };
sub tag { return $_[0]->{tag}; }
sub stringify { return $_[0]->tag; }

package WWW::Shopify::Liquid::Token::Output;
use base 'WWW::Shopify::Liquid::Token';
sub new { return bless { line => $_[1], core => $_[2], strip_left => $_[3], strip_right => $_[4] }, $_[0]; };

package WWW::Shopify::Liquid::Token::Separator;
use base 'WWW::Shopify::Liquid::Token';


1;