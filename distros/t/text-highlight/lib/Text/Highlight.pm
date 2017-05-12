package Text::Highlight;

use strict;
use Carp qw/cluck croak/;

#accessable and editable if someone really wants them
use vars qw($VERSION $VB_FORMAT $VB_WRAPPER $VB_ESCAPE 
            $TGML_FORMAT $TGML_WRAPPER $TGML_ESCAPE $RAW_COLORS
            $DEF_FORMAT $DEF_ESCAPE $DEF_WRAPPER $DEF_COLORS
            $ANSI_FORMAT $ANSI_WRAPPER $ANSI_COLORS);
$VERSION      = 0.04;

#some wrapper settings for typical message boards (ie, the ones I frequent :)
#Anyone with an idea for IPB or phpBB settings, let me know. Last time I checked IPB, 
#    the only way to set mono-spaced font is to use [code] tags, which destroy any markup within. 
#A PHP port is planned once the issues with this get ironed out.
$VB_FORMAT    = '[color=%s]%s[/color]';
$VB_WRAPPER   = '[code]%s[/code]';
# [ -> &#91;
$VB_ESCAPE  = sub { $_[0] =~ s/\[/&#91;/g; $_[0] };

$TGML_FORMAT  = '[color %s]%s[/color]';
$TGML_WRAPPER = "[code]\n%s\n[/code]";
# [ -> [&#91;]
$TGML_ESCAPE  = sub { $_[0] =~ s/\[/[&#91;]/g; $_[0] };

$RAW_COLORS   = { comment => '#006600',
                  string  => '#808080',
                  number  => '#FF0000',
                  key1    => '#0000FF',
                  key2    => '#FF0000',
                  key3    => '#FF8000',
                  key4    => '#00B0B0',
                  key5    => '#FF00FF',
                  key6    => '#D0D000',
                  key7    => '#D0D000',
                  key8    => '#D0D000',
                };

#default values in new()
$DEF_FORMAT   = '<span class="%s">%s</span>';
$DEF_ESCAPE   = \&_simple_html_escape;
$DEF_WRAPPER  = '<pre>%s</pre>';
$DEF_COLORS   = { comment => 'comment',
                  string  => 'string',
                  number  => 'number',
                  key1    => 'key1',
                  key2    => 'key2',
                  key3    => 'key3',
                  key4    => 'key4',
                  key5    => 'key5',
                  key6    => 'key6',
                  key7    => 'key7',
                  key8    => 'key8',
                };

#set limit maximum of keyword groups (must change default colors hash, too)
#not a package var, must be changed here (better know what you're doing)
my $KEYMAX = 8;

sub new
{
	my $class = shift;
	
	my $self = {};
	
	#set defaults (as copies of $DEF_*)
	$self->{_output}      = '';
	$self->{_format}      = $DEF_FORMAT;
	$self->{_escape}      = $DEF_ESCAPE;
	$self->{_wrapper}     = $DEF_WRAPPER;
	%{$self->{_colors}}   = %$DEF_COLORS;
	$self->{_grammars}    = {};
	
	bless $self, $class;
	
	#set any parameters passed to new
	$self->configure(@_);
	
	return $self;
}

sub configure
{
	my $self = shift;
	
	#my extensive parameter checking :(
	my %param = @_ if(@_ % 2 == 0);
	
	return unless %param;
	
	#do we want vBulletin-friendly output?
	if(exists $param{vb} && $param{vb})
	{
		#set generalized defaults for posting in a forum
		$self->{_format}    = $VB_FORMAT;
		$self->{_wrapper}   = $VB_WRAPPER;
		%{$self->{_colors}} = %$RAW_COLORS;
		$self->{_escape}    = $VB_ESCAPE; 
	}

	#do we want Tek-Tips-friendly output?
	if(exists $param{tgml} && $param{tgml})
	{
		#set generalized defaults for posting in a forum
		$self->{_format}    = $TGML_FORMAT;
		$self->{_wrapper}   = $TGML_WRAPPER;
		%{$self->{_colors}} = %$RAW_COLORS;
		$self->{_escape}    = $TGML_ESCAPE; 
	}
	
	#do we want ANSI-terminal-friendly output?
	if(exists $param{ansi} && $param{ansi})
	{
		#dumped in an eval block to only require the module for those who use it
		eval q[
			use Term::ANSIColor;
			$ANSI_FORMAT   = '%s%s'.color('reset');
			$ANSI_WRAPPER  = '%s';
			$ANSI_COLORS   = { comment => color('bold green'),
			                   string  => color('bold yellow'),
			                   number  => color('bold red'),
			                   key1    => color('bold cyan'),
			                   key2    => color('bold red'),
			                   key3    => color('bold magenta'),
			                   key4    => color('bold blue'),
			                   key5    => color('bold blue'),
			                   key6    => color('bold blue'),
			                   key7    => color('bold blue'),
			                   key8    => color('bold blue'),
			                 };
			];
		if($@)
		{
			cluck $@;
		}
		else
		{
			#set ANSI color escape sequences
			$self->{_format}  = $ANSI_FORMAT;
			$self->{_wrapper} = $ANSI_WRAPPER;
			%{$self->{_colors}} = %$ANSI_COLORS;
			
			#set the escape to undef, assuming it's not already set
			$param{escape} = undef unless(exists $param{escape});
		}
	}
		
	#if array ref, set to all readable files in list, else just the one passed
	if(exists $param{wordfile})
	{
		if(ref $param{wordfile} eq 'ARRAY')
		{
			my $tmpref = [];
			for(@{$param{wordfile}})
			{
				-r && push @$tmpref, $_;
			}
			$self->{_wordfile} = $tmpref if(@$tmpref > 0);
		} else {
			-r $param{wordfile} && push @{$self->{_wordfile}}, $param{wordfile};
		}
	}
	
	#should have two "%s" strings in it, for type and code
	if(exists $param{format})
	{
		if($param{format} =~ /(\%s.*){2}/)
		{
			$self->{_format} = $param{format};
		} else {
			cluck "Param format invalid: does not have two %s strings.\n";
		}
	}
	
	#need one %s for the code
	if(exists $param{wrapper})
	{
		#undef -> no wrapper
		unless(defined($param{wrapper}))
		{
			$self->{_wrapper} = '%s';
		}
		
		#if not undef, needs to have a %s for the code
		elsif($param{wrapper} =~ /\%s/)
		{
			$self->{_wrapper} = $param{wrapper};
		}
		
		else {
			cluck "Param wrapper invalid: does not have %s string.\n";
		}
	}
	
	#sub is the same prototype as CGI.pm's escapeHTML()
	#and HTML::Entity's encode_entities()
	#$escaped_string = escapeHTML("unescaped string");
	if(exists $param{escape})
	{
		#undef -> no escaping, set dummy sub to return input
		unless(defined($param{escape}))
		{
			$self->{_escape} = sub { return $_[0] };
		}
		
		#if not undef, check for code ref
		elsif(ref $param{escape} eq 'CODE')
		{
			$self->{_escape} = $param{escape};
		}
		
		#and last, check for 'default' string
		elsif($param{escape} =~ /^default$/i)
		{
			$self->{_escape} = $DEF_ESCAPE;
		}
		
		else {
			cluck "Param escape invalid: is not coderef, undef, or 'default' string.\n";
		}
	}
	
	#must pass a hashref
	if(exists $param{colors})
	{
		if(ref $param{colors} eq 'HASH')
		{
			#loop over only predefined classes (defaults from new)
			for(keys %{$self->{_colors}})
			{
				$self->{_colors}{$_} = $param{colors}{$_} if(exists $param{colors}{$_});
			}
		} else {
			cluck "Param colors invalid: is not a hashref.\n";
		}
	}
}

#get the stynax from a sub-module, and maybe the sub-module will even do the parsing
sub highlight
{
	my $self = shift;
	#call with a hash or not
	my %args = @_ if(@_ % 2 == 0);
	my($type,$code,$options);
	if(exists $args{type} && exists $args{code})
	{
		$type = $args{type};
		$code = $args{code};
		$options = $args{options}; #optional
	}
	else
	{
		$type = shift;
		$code = shift;
		$options = shift; #optional
	}
	
	#check null context
	return undef unless defined wantarray;
	
	#this is not a class method, don't try it
	return undef unless ref $self;
	
	#check if we've loaded this type custom from a file, as it overrides any default option
	if(exists $self->{_grammars}{$type}) {
		$self->{_active} = $self->{_grammars}{$type};
		$self->_highlight($code);
	} else {
		
		#this is where the module for this type should be
		#since this is being require-d, should probably taint check $type a bit
		my $grammar = __PACKAGE__ . "::$type";
	
		#try to include it
		eval "require $grammar" or croak "Bad grammar: $@";
		
		#clear output
		$self->{_output} = '';
	
		#check if the module has a highlight method, else just get the syntax from it and use the parser here
		if($grammar->can('highlight') && $options ne 'simple')
		{
			$grammar->highlight($self, $code, $options);
		}
		elsif($grammar->can('syntax'))
		{
			$self->{_active} = $grammar->syntax;
			$self->_highlight($code);
		}
		else
		{
			croak "$grammar does not have a highlight or syntax method.";
		}
	}
	
	#wrap the code in whatever tags
	$self->{_output} = sprintf($self->{_wrapper}, $self->{_output});
	
	return $self->output;
}

#the one that does all the work
sub _highlight
{
	my $self = shift;
	my $code = shift;
	
	#make a hash to store the index of the next occurance of each comment/string/escape delimiter
	my %delims;
	
	$delims{ $self->{_active}{escape} } = 1;
	#check definedness and emptiness in case of ordering oddities in the grammar file
	defined && ($_ ne '') && ($delims{$_} = 1)    for(@{$self->{_active}{quot}});
	defined && ($_ ne '') && ($delims{$_} = 1)    for(@{$self->{_active}{lineComment}});
	
	#a valid open AND close tag is a must to consider a block comment
	for(0,1)
	{
		if(defined $self->{_active}{blockCommentOn}[$_]  and
		   $self->{_active}{blockCommentOn}[$_] ne ''    and
		   defined $self->{_active}{blockCommentOff}[$_] and
		   $self->{_active}{blockCommentOff}[$_] ne '')
		{
			$delims{ $self->{_active}{blockCommentOn}[$_] } = 1;
		}
	}
	
	#index to the current string location in $code
	my $cur = 0;
	
	#search for the first occurance of each delimiter
	$delims{$_} = index($code, $_, $cur) for(keys %delims);
	
	#while some delimiters still remain
	while(%delims and $cur != -1)
	{
		#find the next delimiter and recalculate any passed indexes
		my $min = _find_next_delim(\%delims, \$code, $cur);
		
		#break out of the loop if it couldn't find a delim
		last unless(defined($min));

		#colorize what was before the found comment/string
		$self->_keyword(substr($code, $cur, $delims{$min}-$cur));
		
		#I realize this is pretty pointless, it's just that in older versions of this
		#whose code is reused, there was no $min, just a $delim that was pulled from a regex
		#mnemonically, $delim is the delimiter, and $min is the key to the minimum index
		#spare the couple bytes for now so I don't have to say $delims{$delim}
		my $delim = $min;
		
		#move the index of $min past the delimiter itself
		#it makes for easier reading substr() and index() calls
		#it gets reset to 0 after each call below, anyway,
		#so it will get recalculated on the next iteration
		$delims{$min} += length($min);
		
		#if an escape sequence
		if($delim eq $self->{_active}{escape})
		{
			#pass thru uncolored (might define an 'escape' color sometime)
			#most escape sequences tend to be in strings, anyway
			#the original delimiter (escape character) and the one after it are passed
			$self->_colorize(undef,$delim.substr($code, $delims{$min}, 1));
			
			#move the current index past the character following the escape
			$cur = $delims{$min} + 1;
			
			#reset escape's next position
			$delims{$min} = 0;
			
			#find me another delimiter!
			next;
		}
		
		#if a quote
		if(grep { $delim eq $_ } @{$self->{_active}{quot}})
		{
			#since a string can contain escape sequences, this if {} block functions
			#roughly the same as the outer while {} block, but with its own %delim (as %d)
			#and $min (as $m) and $cur (as $idx)
			
			#init %d with whatever quote character got us in here (and may get us out)
			#and the stored escape character for this language
			my %d = ( $delim => 1, $self->{_active}{escape} => 1);
			
			#add newline as an escape unless this language support multiline quotes
			$d{"\n"} = 1 unless($self->{_active}{continueQuote});
			
			#the search for the end of the string starts after the starting quote
			my $idx = $delims{$min};
			
			#search for the first occurance of each delimiter
			$d{$_} = index($code, $_, $idx) for(keys %d);
			
			while(%d and $idx != -1)
			{
				#find the next delimiter
				my $m = _find_next_delim(\%d, \$code, $idx);
				
				#if it couldn't find any delimter or we found a newline, we couldn't
				#close the string, so set a negative index and drop out of the loop
				if(!defined($m) || $m eq "\n")
				{
					$idx = -1;
					last;
				}
				
				#set after the found delimiter
				$d{$m} += length($m);
				
				#if esc, set the index past the escape sequence and reset esc's idx
				if($m eq $self->{_active}{escape})
				{
					$idx = $d{$m} + 1;
					$d{$m} = 0;
				}
				
				#if a closing quote, set index to after it and drop from the loop
				if($m eq $delim)
				{
					$idx = $d{$m};
					last;
				}
			}
			
			#if a suitable closing delimiter was found
			if($idx != -1)
			{
				$self->_colorize('string',$delim.substr($code, $delims{$min}, $idx-$delims{$min}));
				$cur = $idx;
			}
			else #couldn't close the quote, just send it on
			{
				$self->_colorize(undef,$delim);
				$cur = $delims{$min};
			}
			$delims{$min} = 0;
			next;
		}
		
		#check if it starts a line comment
		if(grep { $delim eq $_ } @{$self->{_active}{lineComment}})
		{
			#comment to the next newline
			if((my $end = index($code, "\n", $delims{$min})) != -1)
			{
				#check if we split a windows newline in the source, and move before it
				$end-- if(substr($code, $end - 1, 1) eq "\r");
				
				#if the source is viewed, it'll look prettier if the closing comment tag
				#is before the newline, so don't move the index past it
				$self->_colorize('comment',$delim.substr($code, $delims{$min}, $end-$delims{$min}));
				$cur = $end;
			}
			else #no newline found, so comment to string end
			{
				$self->_colorize('comment',$delim.substr($code, $delims{$min}));
				$cur = -1;
			}
			$delims{$min} = 0;
			next;
		}
		
		#something to remember which block comment this is
		my $t;
		#check if it starts a block comment
		if(grep { ($delim eq $self->{_active}{blockCommentOn}[$_]) && defined($t = $_) }
		                                                  (0..$#{$self->{_active}{blockCommentOn}}))
		{
			#comment to the closing comment tag
			if((my $end = index($code, $self->{_active}{blockCommentOff}[$t], $delims{$min})) != -1)
			{
				#set end after the closing tag
				$end += length($self->{_active}{blockCommentOff}[$t]);
				$self->_colorize('comment',$delim.substr($code, $delims{$min}, $end-$delims{$min}));
				$cur = $end;
			}
			else #no closing tag found, so comment to string end
			{
				$self->_colorize('comment',$delim.substr($code, $delims{$min}));
				$cur = -1;
			}
			$delims{$min} = 0;
			next;
		}
	}
	
	#colorize last chunk after all comments and strings if there is one
	$self->_keyword(substr($code, $cur)) if($cur != -1);
	
#	return $self->output;
}

sub output
{
	my $self = shift;
	
	#return a two-element list of the marked-up code and the code type's name,
	#or just the marked-up code itself, depending on context
	#return wantarray ? ($self->{_output}, $self->{_active}{name}) : $self->{_output};
	
	#the above was useful when code's extention was passed, but now since module names
	#are passed, I assume those will be pretty descriptive, and this name method isn't needed.
	#Likely it'll just cause problems with people unexpected using list context (like print)
	return $self->{_output};
}

sub _find_next_delim
{
	#hash-ref, scalar-ref (could be a big scalar), scalar
	my($delims, $code, $cur) = @_;
	my $min;
	for(keys %$delims)
	{
		#find a new index for those not after the current "start" position
		$delims->{$_} = index($$code, $_, $cur) if($delims->{$_} < $cur);
		
		#doesn't exist in the remaining code, don't touch it again
		if($delims->{$_} == -1)
		{
			delete $delims->{$_};
			next;
		}
		
		#if min is not defined or min is less than new delim, set to new
		$min = $_ if(!defined($min) or $delims->{$_} < $delims->{$min});
	}	
	return $min;
}

sub _simple_html_escape
{
	my $code = shift;
	
	#escape the only three characters that "really" matter for displaying html
	$code =~ s/&/&amp;/g;
	$code =~ s/</&lt;/g;
	$code =~ s/>/&gt;/g;

	return $code;
}

sub _colorize
{
	my ($self, $type, $what) = @_;
	
	#do any escaping of characters before appending to output
	$what = &{$self->{_escape}}($what);
	
	#check if type is defined. Append type's class, else just the bare text
	$self->{_output} .= defined($type) ? sprintf($self->{_format}, $self->{_colors}{$type}, $what) : $what;
}

sub _keyword
{
	my ($self, $code) = @_;

	#escape all the delimiters that need to be and dump in char class
	my $d = quotemeta $self->{_active}{delimiters};
	
	#save the pattern so it doesn't compile each time (whitespace is considered a delim, too)
	my $re = qr/\G(.*?)([$d\s]+)/s;
	
	#could help, in theory, but it doesn't seem to help at all when doing
	#repeated m//g global searches with position anchors defeats the point of study()
	#study($code);
	
	while($code =~ /$re/gc ||  #search for a delimiter (don't reset pos on fail)
	      $code =~ /\G(.+)/sg) #grab what's left in the string if there's no delim
	{
		#before the delimiter
		my $chunk = $1;
		
		#the delimiter(s), or empty if no more delims
		my $delim = defined($2) ? $2 : undef;
		
		#remember if we actually did anything
		my $done = 0;
		
		#find which key group, if any, this chunk falls under
		#start at 1 and work up
		my $key = 1;
		
		#check if this key group exists for this language
		while(exists $self->{_active}{"key$key"})
		{
			my $check = ($self->{_active}{case}) ? $chunk : lc($chunk);
			
			#check if this chunk exists for this keygroup
			if(exists $self->{_active}{"key$key"}{$check})
			{
				#colorize it as this group, set done/found and exit loop
				$self->_colorize("key$key",$chunk);
				$done = 1;
				last;
			}
			
			#nope, not this key group, maybe next
			$key++;
		}
		
		#I had a much better "number" regex, but it was probably perl-specific and this should do
		if($chunk =~ /^\d*\.?\d+$/)
		{
			$self->_colorize('number',$chunk);
			$done = 1;
		}
		
		#if the chunk didn't match a pattern above, it's nothing and gets no color but default
		$self->_colorize(undef,$chunk) unless($done);
		
		#dump the delimiter to output, too, without color
		$self->_colorize(undef,$delim) if(defined($delim));
	}
}

#load syntax from a separate grammar file
sub get_syntax
{
	my $self = shift;
	my %args = @_ if(@_ % 2 == 0);
	my($type,$grammar,$format,$force);
	if(exists $args{type} && exists $args{grammar})
	{
		$type = $args{type};
		$grammar = $args{grammar};
		$format = $args{format};
		$force = $args{force};
	}
	else
	{
		$type = shift;
		$grammar = shift;
		$format = shift;
		$force = shift;
	}
	
	unless($type) {
		cluck "You must specify a type.\n";
		return undef;
	}
	
	#check if syntax for this type is already loaded and reload isn't forced
	return $self->{_grammars}{$type} if(!$force && exists $self->{_grammars}{$type});
	
	unless($grammar) {
		cluck "No grammar for '$type' found.\n";
		return undef;
	}
	
	#check if a hashref was passed in instead of a filename
	if(ref $grammar eq 'HASH') {
		$self->{_grammars}{$type} = $grammar;
		return $grammar;
	}
	
	#holds the grammar structure
	#initialize and set common defaults in case of incomplete grammar
	my %syntax = (
		name => 'Unknown-type',
		escape => '\\',
		case => 1,
		continueQuote => 0,
		blockCommentOn => [],
		lineComment => [],
		quot => [],
	);
	#attempt to open grammar file
	open FH, $grammar or croak "Cannot open '$grammar' to find syntax for '$type': $!";
	
	if($format eq 'editplus') {
		_get_syntax_editplus(\%syntax, \*FH);
	}
	elsif($format eq 'ultraedit') {
		_get_syntax_ultraedit(\%syntax, \*FH);
	}
	#else return a non-function yet parsable %syntax, might be desired?
	
	close FH;
	$self->{_grammars}{$type} = \%syntax;
	
	#dump the syntax table to stderr (less screen space than Data::Dumper)
	#print STDERR "$_ : ".((ref $syntax{$_} eq 'HASH') ? join(' | ', keys %{$syntax{$_}}) : (ref $syntax{$_} eq 'ARRAY') ? join(' | ', @{$syntax{$_}}) : $syntax{$_})."\n" for(keys %syntax);

	return $self->{_grammars}{$type};
}

sub _get_syntax_editplus
{
	my $syntax = shift;
	my $FH = shift;
	
	#make sure we break on newlines
	local $/ = "\n";

	my $key = 1;

	while(<$FH>)
	{
		#comment and blank lines ignored
		next if(/^;/ || !/./);

		#search for each type
		$syntax->{name} = $1                if(/^\#TITLE=(.+?)$/i);
		$syntax->{delimiters} = $1          if(/^\#DELIMITER=(.+?)$/i);
		$syntax->{escape} = $1              if(/^\#ESCAPE=(.+?)$/i);
		$syntax->{case} = 0                 if(/^\#CASE=n$/i);
		$syntax->{case} = 1                 if(/^\#CASE=y$/i);
		$syntax->{continueQuote} = 0        if(/^\#CONTINUE_QUOTE=n$/i);
		$syntax->{continueQuote} = 1        if(/^\#CONTINUE_QUOTE=y$/i);

		$syntax->{blockCommentOn}[0] = $1   if(/^\#COMMENTON=(.+?)$/i);
		$syntax->{blockCommentOff}[0] = $1  if(/^\#COMMENTOFF=(.+?)$/i);
		$syntax->{blockCommentOn}[1] = $1   if(/^\#COMMENTON2=(.+?)$/i);
		$syntax->{blockCommentOff}[1] = $1  if(/^\#COMMENTOFF2=(.+?)$/i);

		push @{$syntax->{lineComment}}, $1  if(/^\#LINECOMMENT\d?=(.+?)$/i);
		push @{$syntax->{quot}}, $1         if(/^\#QUOTATION\d?=(.+?)$/i);

		if(/^\#KEYWORD/ && $key <= $KEYMAX)
		{
			while(defined($_ = <$FH>) && !/^\#/)
			{
				#comment and blank lines ignored
				next if(/^;/ || !/./);
				chomp;

				#the escape character is ^ and possible escape sequences are ^^ ^; ^#
				s/\^([;^#])/$1/g;

				#save the literal if case sensitive, else lc it as key
				if($syntax->{case}){
					$syntax->{"key$key"}{$_} = $_;
				} else {
					$syntax->{"key$key"}{lc($_)} = $_;
				}
			}
			$key++;             #for next potential key group
			redo unless(eof);   #back to the top of the while without hitting <FILE> again, assuming not EOF
		}
	}
}

sub _get_syntax_ultraedit
{
	my $syntax = shift;
	my $FH = shift;
	
	#make sure we break on newlines
	local $/ = "\n";
		
	while(<$FH>)
	{
		$syntax->{name} = $1                   if(/^\/L\d+"(.+?)"/i);
		$syntax->{escape} = $1                 if(/Escape Char = (\S+)/);
		$syntax->{case} = 0                    if(/Nocase/);
		push @{$syntax->{quot}}, split //, $1  if(/String Chars = (\S{1,2})/);
		
		$syntax->{blockCommentOn}[0] = $1      if(/Block Comment On = (\S{1,5})/);
		$syntax->{blockCommentOff}[0] = $1     if(/Block Comment Off = (\S{1,5})/);
		$syntax->{blockCommentOn}[1] = $1      if(/Block Comment On Alt = (\S{1,5})/);
		$syntax->{blockCommentOff}[1] = $1     if(/Block Comment Off Alt = (\S{1,5})/);
		
		push @{$syntax->{lineComment}}, $1     if(/Line Comment (?:Alt )?= (\S{1,5})/);
		$syntax->{delimiters} = $1             if(/^\/Delimiters = (.+)$/i);
		
		my($key) = /^\/C(\d+)(?:".+")?$/;
		if($key && $key <= $KEYMAX)
		{
			#any non-escape line
			while(defined($_ = <$FH>) && !/^\/(?!\/)/)
			{
				chomp;

				#escape is a line that starts with //, allows the line to contain / in keywords
				s/^\/\///;

				#keywords are whitespace delimited, and ignore the empty strings with truth test
				for(grep $_, split /\s+/)
				{
					#save the literal if case sensitive, else lc it as key
					if($syntax->{case}){
						$syntax->{"key$key"}{$_} = $_;
					} else {
						$syntax->{"key$key"}{lc($_)} = $_;
					}
				}
			}
			redo unless(eof);   #back to the top of the while without hitting <FILE> again, assuming not EOF
		}
	}
	
	# UE has both quotes enabled by default, so if none were defined, use them
	@{$syntax->{quot}} or push @{$syntax->{quot}}, qw/' "/;
}

1;

__END__

=pod 

=head1 NAME

Text::Highlight - Syntax highlighting framework

=head1 SYNOPSIS

   use Text::Highlight 'preload';
   my $th = new Text::Highlight(wrapper => "<pre>%s</pre>\n");
   print $th->highlight('Perl', $code);

=head1 DESCRIPTION

Text::Highlight is a flexible and extensible tool for highlighting the syntax in programming code. The markup used and languages supported are completely customizable. It can output highlighted code for embedding in HTML, terminal escapes for an ANSI-capable display, or even posting on an online forum. Bundled support includes C/C++, CSS, HTML, Java, Perl, PHP and SQL.

=head1 INSTALLATION

In order to install and use this package you will need Perl version 5.005 or
better.

Installation as usual:

   % perl Makefile.PL
   % make
   % make test
   % su
     Password: *******
   % make install

=head1 DEPENDENCIES

No thirdy-part modules are required.

Following modules are optional

=over 4

=item HTML::SyntaxHighlighter and HTML::Parser (in order to have better
highlighting HTML code)

=item Term::ANSIColor (if you want terminal escapes)

=back 

=head1 API OVERVIEW

[Todo]

=head1 METHODS

Text::Highlight provides an object oriented interface described in
this section. Optionally, new can take the same parameters as the C<configure> method described below.

=over 4

C<my $th = new Text::Highlight( %args )>

=back

=head2 Public Methods:

C<< $th->configure( %args ) >>

=over 4

Sets the method used to output highlighted code. Any combination of the following properties can be passed at once. If any option is invalid (such as the wrapper containing no %s), a note of such is C<cluck>ed out to STDERR and is otherwise silently ignored.

C<< wrapper => '<pre>%s</pre>' >>

=over 4

An sprintf-style format string that the entire code is passed through when it's completed. It must include a single %s and any other optional formatting. If you do not want any wrapper, just the highlighted code, set this to a simple '%s'.
Also, be aware that since this is an sprintf format, you must be careful of other % characters in the format. Include only a single '%s' in the format for the highlighted code. Refer to L<perlfunc/sprintf>.

=back

C<< markup => '<span class="%s">%s</span>' >>

=over 4

Another sprintf format string, this one's for the markup of individual semantic pieces of the highlighted code. In short, it's what makes a comment turn green. The format contains two '%s' strings. The first is the markup identifier from the C<colors> hash for the type of snippet that's being marked up. The second is the actual snippet being marked up. A comment may look like C<< <span class="comment">#me comment</span> >> as final output.

The limitation of this is that the identifier for the type must come before the code itself. Normally, this is the way markup works, but if you have something that won't, you're out of luck for the immediate time being. Future versions may include support for setting a coderef to get around it.

=back

C<< colors => \%hash >>

=over 4

The default colors hash is:

  { comment => 'comment',
    string  => 'string',
    number  => 'number',
    key1    => 'key1',
    key2    => 'key2',
    key3    => 'key3',
    key4    => 'key4',
    key5    => 'key5',
    key6    => 'key6',
    key7    => 'key7',
    key8    => 'key8',
  };

This is the name to semantic markup token mapping hash. The parser breaks up code into semantic chunks denoted by the name keys. What gets passed through the above C<markup>'s format is the value set at each key. This can hold things like raw color values, ANSI terminal escapes, or, the default, CSS classes.

=back

C<< escape => \&escape_sub | 'default' | undef >>

=over 4

Every bit of displayed code is passed through an escape function customizable for the output medium. C<$escaped_string = escapeHTML("unescaped string")> If set to a code reference, it will be called for every piece of code. This gets called a lot, so if you're concerned with performance, take care that the function is pretty lightweight.

The default function does a minimal HTML escape, only the three & < and > characters are escaped. If you desire a more robust HTML escape, it has the same prototype as L<HTML::Entity>'s C<encode_entities()> and L<CGI>'s C<escapeHTML()>. If you change the escape routine and want to change it back to the default, just set it to the literal string 'default'.

A third option is no escaping at all and can be set by passing C<undef>.

=back

C<< vb => 1 >>,
C<< tgml => 1 >>,
C<< ansi => 1 >>

=over 4

When true, it sets the format, wrapper, escape, and colors to that of the specified markup. When C<vb> is true, it sets values for posting in vBulletin. For C<tgml> it's good at Tek-Tips. For C<ansi> it's good for display in a terminal that accepts ANSI color escapes.

Note, if more than one of these is present in a given call to C<configure>, it is indeterminite as to which one gets set. Also, if wrapper, markup, colors, or escape is passed along with vb, tgml, or ansi, it does not get overwritten. Hence, C<< $th->configure(wrapper => '[tt]%s[/tt]', tgml => 1) >> will set the stored TGML settings for markups, colors, and escape, but will use the custom wrapper passed in instead of the value stored for TGML.

=back

=back

C<< $code = $th->highlight($type, $code, $options) >>

C<< $code = $th->highlight(type => $type, code => $code, options => $options) >>

=over 4

The C<highlight> method is the one that does all the work. Given at least the C<type> and original C<code>, it will mark-up and return a string with the highlighted code. It takes named parameters as listed below, or just their values as a flat array in the order listed below. Order is subject to change, so you're probably safer using the hash syntax.

C<< type => $type >>

=over 4

The C<type> passed in is the name of the type of code. This can either be a type loaded from C<get_syntax> or is the name of a sub-module that has a syntax or highlight method, ie C<Text::Highlight::$type>. 

=back

C<< code => $code >>

=over 4

C<code> is the unmarked-up, unescaped, plain-text code that needs to be highlighted.

=back

C<< options => $options >>

=over 4

C<options> is optional and mostly not needed. Some parsing modules can take extra configuration options, so what C<options> is can vary greatly. Could be a string, a number, or a hashref of many options. The only standard is if it is set to the string 'simple' in which case the C<highlight> method of the syntax module is not called and Text::Highlight's local parsing method is used with the syntax module's C<syntax> hash.

=back

=back

C<< $code = $th->output >>

=over 4

Returns the highlighted code from the last time the C<highlight> method was called.

=back

C<< $th->get_syntax($type, $grammar, $format, $force) >>

C<< $th->get_syntax(type => $type, grammar => $grammar, format => $format, force => $force) >>

=over 4

In addition to the existing T::H:: sub-modules, you can specify new ones at runtime via text editor syntax files. Current support is for EditPlus and UltraEdit (both very good text/code editors). Many users make these files available on the web and shouldn't be difficult to find. This method can also be used to load an already parsed language syntax hash if, for whatever reason, you don't want to make them into modules.

This method returns a hashref to the parsed syntax if successful, or undef and a clucked error message if not. You can use the returned value as a simple truth test, or you can make your own static sub-module out of it and save reparsing time if you're using the same additional types often. See <a doc that doesn't yet exists> for details on creating a sub-module. The object keeps a copy of the new type and can be referenced in the highlight method for the object's life.

C<< type => $type >>

=over 4

The C<type> is the same that gets passed to C<highlight>, so whatever is specified here must match the call there for use. Also, if the same type is specified as one that already exits as a sub-module (visible in @INC as Text::Highlight::$type), the syntax loaded via C<get_syntax> will take precedence.

=back

C<< grammar => $filename | \%syntax >>

=over 4

C<grammar> can be one of two things: the filename containing the syntax, or a hashref to an already parsed language syntax. If a filename, the file must contain only a single language syntax definition. Though some editors allow multiple language defined in the same file, to be loaded here, it may contain only one. If a hashref, it is assumed to be valid and no further checking is done.

=back

C<< format => 'editplus' | 'ultraedit' >>

=over 4

C<format> is a string specifying which format the syntax definition in the file is in. It is not used if C<grammar> is a hashref, but is required if it is a filename. Currently, it must be set to one of the following strings: 'editplus' 'ultraedit'

The syntax for a language is set to the following default hash before parsing the file. This means if any of the options are not set in the syntax file, the default specified here is used instead. If C<format> is not set to a valid string, this default hash is also set and passed back instead of throwing an error. It will allow parsing to happen without error, but will not do anything to the code.

  { name => 'Unknown-type',
    escape => '\\',
    case => 1,
    continueQuote => 0,
    blockCommentOn => [],
    lineComment => [],
    quot => [],
  };

=back

C<< force => 1 >>

=over 4

If C<force> is set to a true value, the grammar specified will always be reparsed, reset, and reloaded. By default, if a grammar is loaded for a C<type> that has already been loaded, the existing copy is used instead and no reparsing is done. This works as a very simple cacheing mechanism so you don't have to worry about unneccessary processing unless you want to.

=back

=back

=head2 Examples:

Until I come up with some better examples, here's the defaults the module uses.

=over 4

  $DEF_FORMAT   = '<span class="%s">%s</span>';
  $DEF_ESCAPE   = \&_simple_html_escape;
  $DEF_WRAPPER  = '<pre>%s</pre>';
  $DEF_COLORS   = { comment => 'comment',
                    string  => 'string',
                    number  => 'number',
                    key1    => 'key1',
                    key2    => 'key2',
                    key3    => 'key3',
                    key4    => 'key4',
                    key5    => 'key5',
                    key6    => 'key6',
                    key7    => 'key7',
                    key8    => 'key8',
  };
  				
  #sub is the same prototype as CGI.pm's escapeHTML()
  #and HTML::Entity's encode_entities()
  sub _simple_html_escape
  {
      my $code = shift;
  	
      #escape the only three characters that "really" matter for displaying html
      $code =~ s/&/&amp;/g;
      $code =~ s/</&lt;/g;
      $code =~ s/>/&gt;/g;
  
      return $code;
  }

=back

=head1 API SYNTAX EXTENSIONS

[Todo]

=head1 EXAMPLES

[Todo]

=head1 TODO

=over 4

=item * 

Finish documentation (especially a "how do I make a custom highlighting module" kind of thing)

=item *

Let C<wrapper> and C<format> take coderefs instead of just sprintf format strings

=item *

Add support for C<get_syntax> to take a file handle

=item *

Add support for a force case option for case-insensitive languages (upper, lower, or match stored)

=item *

Write T::H:: wrappers for the modules in the Syntax:: namespace

=item * 

Test, test ,test ;-)

=back

=head1 AUTHORS

Andrew Flerchinger <icrf [at] wdinc.org>

Enrico Sorcinelli <enrico [at] sorcinelli.it> (main contributors)

=head1 BUGS 

Please submit bugs to CPAN RT system at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Highlight>
or by email at bug-text-highlight@rt.cpan.org

Patches are welcome and we'll update the module if any problems are found.

=head1 VERSION

Version 0.04

=head1 SEE ALSO

L<HTML::SyntaxHighlighter>, perl(1)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2005. All rights reserved. 
This program is free software; you can redistribute it  and/or modify it under
the same terms as Perl itself. 

=cut
