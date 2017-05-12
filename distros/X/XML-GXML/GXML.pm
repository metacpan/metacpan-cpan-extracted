# GXML module: generic, template-based XML transformation tool
# Copyright (C) 1999-2001 Josh Carter <josh@multipart-mixed.com>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package XML::GXML;

# 'strict' turned off for release, but stays on during development.
# use strict;
use Cwd;
use XML::Parser;

# Most of these vars are used as locals during parsing.
use vars ('$VERSION', '@attrStack', '$output', 
		  '$baseTag', '$rPreserve', '$self');
$VERSION = 2.4;

my $debugMode = 0;

#######################################################################
# new, destroy, other initialization and attributes
#######################################################################

sub new
{
	my ($pkg, $rParams) = @_;

	my $templateDir = ($rParams->{'templateDir'}    || 'templates');
	my $varMarker   = ($rParams->{'variableMarker'} || '%%%');
	my $templateMgr = new XML::GXML::TemplateManager($templateDir, 
							$rParams->{'addlTemplates'},
							$rParams->{'addlTemplate'},
							$rParams->{'addlTempExists'},
							$varMarker);

	$debugMode = $rParams->{'debugMode'} unless ($debugMode);
	
	# Create the new beast
	my $self = bless
	{
		_templateMgr => $templateMgr,
		_varMarker   => $varMarker,
		_remappings  => ($rParams->{'remappings'}  || { }),
		_htmlMode    => ($rParams->{'html'}        || 0),
		_dashConvert => ($rParams->{'dashConvert'} || 0),
		_addlAttrs   => ($rParams->{'addlAttrs'}   || undef),
	}, $pkg;

	$self->AddCallbacks($rParams->{'callbacks'});

	return $self;
}

sub DESTROY
{
	# nothing needed for now
}

#
# AddCallbacks
#
# Callbacks allow you to be notified at the start or end of a given
# tag. Pass in a hash of tag names to subroutine refs. Tag names
# should be prefixed with "start:" or "end:" to specify where the
# callback should take place. See docs for more info on using
# callbacks.
#
sub AddCallbacks
{
	my ($self, $rCallbacks) = @_;
	my (%start, %end);

	# add our default commands
	%start = ('gxml:foreach'  => \&ForEachStart);
	%end = ('gxml:ifexists'   => \&ExistsCommand,
			'gxml:ifequals'   => \&EqualsCommand,
			'gxml:ifequal'    => \&EqualsCommand,
			'gxml:ifnotequal' => \&NotEqualsCommand,
			'gxml:include'    => \&IncludeCommand,
			'gxml:foreach'    => \&ForEachEnd,);

	# and add the stuff passed in, if anything
	foreach my $callback (keys %{$rCallbacks})
	{
		if ($callback =~ /^start:(.*)/)
		{
			$start{$1} = $rCallbacks->{$callback};
			XML::GXML::Util::Log("adding start callback $1");
		}
		elsif ($callback =~ /^end:(.*)/)
		{
			$end{$1} = $rCallbacks->{$callback};
			XML::GXML::Util::Log("adding end callback $1");
		}
		else
		{
			XML::GXML::Util::Log("unknown callback type $callback");
		}
	}

	$self->{'_cb-start'} = \%start;
	$self->{'_cb-end'}   = \%end;
}

#######################################################################
# Process, ProcessFile
#######################################################################

#
# Process
#
# Processes a given XML string. Returns the output as a scalar.
#
sub Process()
{
	my ($selfParam, $stuff) = @_;
	
	# Set up these pseudo-global vars
	local (@attrStack, $output, $baseTag, $rPreserve);

	# Also create this so XML::Parser handlers can see it
	local $self = $selfParam;

	# See note in LoadTemplate about this
	$stuff =~ s/$self->{_varMarker}/::VAR::/g;

	# Process the beastie
	my $xp = new XML::Parser(ErrorContext => 2);
	$xp->setHandlers(Char		=> \&HandleChar,
					 Start		=> \&HandleStart,
					 End		=> \&HandleEnd,
					 Comment	=> \&HandleComment,
					 Default	=> \&HandleDefault);

	$xp->parse($stuff);

	return $output;
}

#
# ProcessFile
#
# Processes a given XML file. If an output file name is provided, the
# result will be dumped into there. Otherwise it will return the
# output as a scalar.
#
sub ProcessFile()
{
	my ($selfParam, $source, $dest) = @_;
	my $fileName;
	my $baseDir = cwd();
	
	# Set up these pseudo-global vars
	local (@attrStack, $output, $baseTag, $rPreserve);

	# Also create this so XML::Parser handlers can see it
	local $self = $selfParam;

	#
	# Open and parse the input file.
	#
	$fileName = XML::GXML::Util::ChangeToDirectory($source);
	
	open(IN, $fileName) || die "open input $fileName: $!";

	# Slurp everything
	local $/;
	undef $/;	# turn on slurp mode
	my $file = <IN>;
	
	close(IN);
	chdir($baseDir);

	# See note in LoadTemplate about this
	$file =~ s/$self->{_varMarker}/::VAR::/g;

	# Process the beastie
	my $xp = new XML::Parser(ErrorContext => 2);
	$xp->setHandlers(Char		=> \&HandleChar,
					 Start		=> \&HandleStart,
					 End		=> \&HandleEnd,
					 Comment	=> \&HandleComment,
					 Default	=> \&HandleDefault);

	$xp->parse($file);

	return $output unless ($dest);

	#
	# Find and open the output file.
	#
	chdir($baseDir);
	$fileName = XML::GXML::Util::ChangeToDirectory($dest);

	open(OUT, ">$fileName") || die "open output $fileName: $!";
	
	# Ensure the permissions are correct on the output file.
	my $cnt = chmod 0745, $fileName;
	warn "chmod failed on $fileName: $!" unless $cnt;

	# Print the results
	print OUT $output;

	close(OUT);
	chdir($baseDir);
}

#######################################################################
# XML parser callbacks
#######################################################################

#
# HandleStart
#
# Create a new attribute frame for this element and fill it with the
# element's attributes, if any. Nothing is printed to $output just yet;
# that comes in HandleEnd.
#
sub HandleStart()
{
	my ($xp, $element, %attrs) = @_;
	my ($key, %cbParams);

	# First element in the document is always the base
	$baseTag = $element unless defined($baseTag);
	
	XML::GXML::Util::Log("start: $element");

	foreach $key (keys %attrs)
	{
		my $val = $attrs{$key};

		# Compact whitespace, strip leading and trailing ws.
		$val =~ s/\s+/ /g;
		$val =~ s/^\s*(.*?)\s*$/$1/;

		# Make variable substitutions in each key.
		$val = SubstituteAttributes($val);

		# Stick newly molested $val back into $attrs if we've still
		# got something left, or delete the attribute if it's empty
		# (could have been made empty after substitition).
		if (length($val))
			{ $attrs{$key} = $val; }
		else
			{ delete $attrs{$key}; }

		XML::GXML::Util::Log("\t$key: $val");
	}

	# Save our tag name in the attrs, too.
	$attrs{_TAG_} = $element;

	# Add these attributes to the master tree.
	AddAttributeNode($element, \%attrs);

	# Call registered callback, if one exists
	if ($self->{'_cb-start'}->{$element})
	{
		&{$self->{'_cb-start'}->{$element}}(\%cbParams);
	}
}

#
# HandleEnd
#
# By now we should have stuff in the current attribute frame's _BODY_
# special attribute, assuming there was char data. We need to either
# run a substitution for the tag, or just echo the _BODY_ framed by
# opening and closing tags. If there was no char data and this isn't a
# templated element, just echo <tag> (HTML syntax).
#
sub HandleEnd()
{
	my ($xp, $element) = @_;
	my $orig = $element;
	my $html = ($self->{_htmlMode} ne 0);
	my ($rActions, $discard, $repeat, $strip);
	my %cbParams;

	XML::GXML::Util::Log("end: $element");

	# Get the attribute frame for this element, and also the next one up.
	my $attrsRef  = $attrStack[-1];
	my $nextFrame = $attrStack[-2];
	my $destRef   = undef;

	# Our element's tag may be a variable. Substitute now.
	$element = SubstituteAttributes($element);

	#
	# If the element should be remapped into something else, do that
	# now. NOTE: this means that an untemplatted tag can be remapped
	# into a templatted one, and the template *will* be applied.
	#
	if (exists $self->{'_remappings'}->{$element})
	{
		$element = $self->{'_remappings'}->{$element};
	}

	# Bail if the tag was substituted/remapped to nothing
	if (!length($element))
	{
		XML::GXML::Util::Log("discarding $orig because it's remapped to nil");
		LeaveAttributeNode();
		return;
	}

repeat:

	# Call callback if needed
	if ($self->{'_cb-end'}->{$element})
	{
		$rActions = &{$self->{'_cb-end'}->{$element}}(\%cbParams);

		# Make sure these are clear, since a previous 'repeat' may
		# have changed them.
		undef $discard; undef $repeat; undef $strip;

		if (defined($rActions) && ref($rActions) eq 'ARRAY')
		{
			foreach my $action (@$rActions)
			{
				if    ($action eq 'discard')  { $discard = 1; }
				elsif ($action eq 'repeat')   { $repeat  = 1; }
				elsif ($action eq 'striptag') { $strip   = 1; }
			}
		}
	}

	if ($discard)
	{
		XML::GXML::Util::Log("discarding $orig because callback told me to");
		LeaveAttributeNode();
		return;
	}

	if ($repeat)
	{
		#
		# This requires some explanation. The gxml:foreach start
		# callback (assuming we're repeating because of foreach) would
		# have set aside its 'expr' variable as something HandleChar
		# shouldn't substitute. If that happened, each iteration would
		# have the same expr value -- it would just sub the first
		# value in there, and then the variable wouldn't exist
		# anymore. Thus it must be saved until here and substituted.
		#
		# First step: fetch the original body which has the SAVE
		# marker preserved. If this is the first pass through, grab it
		# from the attrs.
		#
		my $body = $cbParams{'body'};

		if (!defined($body))
		{
			$body = $attrsRef->{_BODY_};
			$cbParams{"body"} = $body;
		}

		# Figure out what we were saving
		my $var = $cbParams{'expr'} || Attribute('expr');

		# Now sub back the VAR marker and sub in the attribute
		$body =~ s/::SAVE::(${var}:?.*?)::SAVE::/::VAR::$1::VAR::/g;
		$body = SubstituteAttributes($body);

		# Finally, refresh this for later code
		$attrsRef->{_BODY_} = $body;
	}

	#
	# If there's a frame above us and we're not the document's base
	# element, we want to proceed normally. All output should go into
	# the _BODY_ attribute of the frame above us. Otherwise we want to
	# dump the current _BODY_ to $output and return.
	#
	if ((defined $nextFrame) && ($baseTag ne $element))
	{
		$destRef = \$nextFrame->{_BODY_};
	}
	else
	{
		# Special case for the very top-level element: if the beast has
		# a template, substitute it and dump the output directory into
		# $output, since there's no upper-level _BODY_ for it.
		if (!defined $nextFrame && $self->TemplateExists($element))
		{
			$output .= $self->SubstituteTemplate($element);
		}
		elsif (defined ($attrsRef->{_BODY_}))
		{
			# Otherwise just dump to $output. NOTE: this case also
			# applies to the base tag of templates.

			$output .= $attrsRef->{_BODY_};
		}
		
		unless ($html)
		{
			$output = "<$element>$output</$element>";
		}

		LeaveAttributeNode();
		return;
	}

	if ($self->TemplateExists($element))
	{
		#
		# There's a template for this element, so we need to 
		# substitute it in.
		#
		XML::GXML::Util::Log("found template for $element");

		my $substitution = $self->SubstituteTemplate($element);
		$$destRef .= $substitution if defined($substitution);
		
		# Update our _BODY_ to reflect the new substitution.
		$attrsRef->{_BODY_} = $substitution;
	}
	elsif ($strip)
	{
		#
		# If a callback said to strip its tag off the output, just
		# echo our body without a tag wrapped around it.
		#
		$$destRef .= $attrsRef->{_BODY_} if defined($attrsRef->{_BODY_});
	}
	else
	{
		#
		# No template, so just echo the tag and relevant _BODY_ in XML
		# syntax (i.e. <tag/> single-tag element syntax), unless $html
		# is set, in which case we want it in HTML syntax.
		#

		# Grab a reference to _only_ the attributes in our
		# current frame. 
		my $attrsRef = $attrStack[-1];

		# If the tag has an explicit 'html:' namespace prefix, strip
		# that if we're in HTML mode.
		$element =~ s/^html:// if $html;
		
		# Print the tag.
		$$destRef .= '<' . $element;

		# Print the attibute list for this (and only this) element.
		foreach my $key (keys %$attrsRef)
		{
			next if $key =~ /^_[-_A-Z]+_$/; # skip special variables

			my $cleankey = $key;
			$cleankey =~ s/^html:// if $html;
			
			$$destRef .= " $cleankey=\"" . $attrsRef->{$key} . "\"";
		}

		#
		# If there's character data (i.e. this is not a single-tag
		# element), print that data and a closing tag.
		#
  		if (defined($attrsRef->{_BODY_}) && length($attrsRef->{_BODY_}))
		{
			# Close the opening tag
			$$destRef .= '>';

			$$destRef .= $attrsRef->{_BODY_};

			$$destRef .= '</' . $element . '>';
		}
		elsif ($html)
		{
			# Single-tag element, but in HTML <tag> mode.
			$$destRef .= '>';
		}
		else
		{
			# Single-tag element, and we're just doing a generic
			# XML->XML conversion, so preserve <tag/> syntax.
			$$destRef .= '/>';
		}
	}

	if ($repeat)
	{
		# Callback will be called again at top of this loop.
		goto repeat;
	}

	LeaveAttributeNode();
}

#
# HandleChar
#
# Substitute any attributes which show up in our input string, and
# append the resulting string to the last attr frame's _BODY_ attr.
#
sub HandleChar()
{
	my ($xp, $string) = @_;

	# Achtung! We must process the original string, not the one
	# munged by Expat into UTF-8, which will automatically remap
	# things like "&lt;" into "<". If the author wrote &lt; in their
	# XML document, that's probably because they wanted it in their
	# HTML document, too.
	$string = $xp->original_string;

	# Make variable substitutions.
	$string = SubstituteAttributes($string);

	# Convert m-dashes if needed.
	$string =~ s/--/&\#8212;/g if $self->{_dashConvert};

	# Append the body text to the _BODY_ attribute of the last
	# attribute frame on the stack (i.e. that of the most immediately
	# enclosing element).
	$attrStack[-1]->{_BODY_} .= $string;
}

#
# HandleComment
#
# Stick comments in the _BODY_ attr, too. Also supports attribute
# substitution.
#
sub HandleComment()
{
	my ($xp, $string) = @_;

	# Make variable substitutions.
	$string = SubstituteAttributes($string);

	# Append the text to the _BODY_ attribute of the last attribute
	# frame on the stack. Remember to put the comment markers back in!
	$attrStack[-1]->{_BODY_} .= '<!--' . $string . '-->';
}

#
# HandleDefault
#
# Discard all the other stuff which we may encounter.
#
sub HandleDefault()
{
	my ($xp, $string) = @_;

	# Discard stuff for now.
}



#######################################################################
# Attribute tree maintenance
#######################################################################



#
# AddAttributeNode
#
# Add a node to the document tree. The node's contents are the
# attributes of that element, both in the tag and the body (via the
# _BODY_ attr). This should be called in HandleStart, and paired with
# LeaveAttributeNode in HandleEnd.
#
sub AddAttributeNode
{
	my ($tag, $attrsRef) = @_;
	my ($parent);

	# Get our parent if there is one. This will be the last thing
	# on the stack, as we haven't added ourself yet.
	if (defined $attrStack[-1])
	{ 
		$parent = $attrStack[-1]; 
	}
	else
	{
		# No parent means we're the top-level element, so just add
		# ourself to the stack and return.
		push(@attrStack, $attrsRef);
		return;
	}

	# If our parent doesn't have any children yet, it does now.
	unless (exists $parent->{_CHILDREN_})
	{
		$parent->{_CHILDREN_} = { };
	}
	
	# If our parent has children with our tag name, add ourself to
	# that list. Otherwise create a new list with ourself in it.
	if (exists $parent->{_CHILDREN_}->{$tag})
	{
		push(@{$parent->{_CHILDREN_}->{$tag}}, $attrsRef);
	}
	else
	{
		$parent->{_CHILDREN_}->{$tag} = [ $attrsRef ];
	}

	# Finally, put ourself on the stack.
	push(@attrStack, $attrsRef);
}

#
# LeaveAttributeNode
#
# Keep the attribute stack intact.
#
sub LeaveAttributeNode
{
	pop(@attrStack);
}

#
# Attribute
#
# Find a given attribute and return its value. If there were multiple
# values, only return the first. (Use RotateAttribute to get others.)
#
sub Attribute
{
	my ($key) = @_;

	my $attr = FindAttribute($key);
	my $ref  = ref($attr);
	
	if ($ref eq 'ARRAY')
	{ 
		$attr = @{$attr}[0]->{_BODY_};
	}

	return $attr;
}

sub AddAttribute
{
	my ($key, $val, $recurse) = @_;

	# Add to last frame on stack; bail if no frames there.
	return unless (defined $attrStack[-1]);

	XML::GXML::Util::Log("addattr: marking " . $attrStack[-1]->{_TAG_} ." ". $val);
	$attrStack[-1]->{$key} = $val;

	if ($recurse =~ /^parents/)
	{
		foreach my $frame (reverse @attrStack)
		{
			# skip if value already defined and weak recurse
			next if (($recurse eq 'parents-weak') &&
					 defined($frame->{$key}));

			XML::GXML::Util::Log("addattr: marking " . $frame->{_TAG_} ." ". $val);
			$frame->{$key} = $val;
		}
	}
}

#
# RotateAttribute
#
# For an attribute which has multiple values, take the first one and
# stick it on the end. A subsequent call to Attribute() will then
# return the new first element.
#
sub RotateAttribute
{
	my ($key) = @_;

	my $attr = FindAttribute($key);
	my $ref  = ref($attr);
	
	if ($ref eq 'ARRAY')
	{ 
		my $front = shift @{$attr};
		push(@{$attr}, $front);
	}
	else
	{
		XML::GXML::Util::Log("tried to rotate attribute $key which wasn't a list");
	}
}

#
# NumAttributes
#
# Return the number of values an attribute has.
#
sub NumAttributes
{
	my ($key) = @_;

	my $attr = FindAttribute($key);
	my $ref  = ref($attr);
	my $num;
	
	if (!defined($attr))
		{ return 0; }
	elsif ($ref eq 'ARRAY')
		{ $num = int @{$attr}; return $num; }
	elsif (!defined($ref))
		{ return 1; }
}

#
# FindAttribute
#
# Scan backwards through the attribute stack looking for the first
# attribute match. If nothing is found, look for "key-default." If we
# find a child element acting as an attribute, return that list. If it
# was declared in the start tag, just return the text. Callers should
# check ref() on the return value to figure out what it is.
#
sub FindAttribute
{
	my ($key, @stack) = @_;
	my ($frame, $parent, $return, $subkeys);
	my $origkey = $key;

	@stack = reverse @attrStack unless int(@stack);

	if ($key =~ /^([^:]+):(.*)$/)
	{
		$key = $1;
		$subkeys = $2;
	}

	# Scan backwards through attribute stack trying to find the
	# requested key.
	foreach $frame (@stack)
	{
		# First check this level for immediate children whose tag
		# matches what we're looking for.
		if (exists $frame->{_CHILDREN_} &&
			exists $frame->{_CHILDREN_}->{$key})
		{
			$return = $frame->{_CHILDREN_}->{$key};
			goto found;
		}
		
		# Otherwise check element params embedded in the tag.
		return $$frame{$key} if (exists $$frame{$key});
	}

	# Call additional attribute method passed to new(), if any.
	if (defined $self->{_addlAttrs})
	{
		my $val = &{$self->{_addlAttrs}}($origkey);

		return $val if defined ($val);
	}

	# Hmm, I guess that didn't work. Now search for the same key with
	# "-default" tacked on the end.
	$key .= "-default";

	# Second verse same as the first...
	foreach $frame (@stack)
	{
		if (exists $frame->{_CHILDREN_} &&
			exists $frame->{_CHILDREN_}->{$key})
		{
			$return = $frame->{_CHILDREN_}->{$key};
			goto found;
		}
		
		return $$frame{$key} if (exists $$frame{$key});
	}

	XML::GXML::Util::Log("couldn't find a value for $key, dude.");
	return undef;

  found:

	if (defined($subkeys))
	{
		return FindAttribute($subkeys, @$return);
	}
	else
	{
		return $return;
	}
}

#
# SubstituteAttributes
#
# Dig through a string looking for variables and replace them with
# attributes in the current scope.
#
sub SubstituteAttributes
{
	my ($string, $marker) = @_;

	# Hack: see note in LoadTemplates about this.
	$marker = "::VAR::" unless defined($marker);

	# Change the marker for variables which we don't want substituted.
	foreach my $var (@$rPreserve)
	{
		$string =~ s/${marker}(${var}:?.*?)${marker}/::SAVE::$1::SAVE::/g;
	}

	# Special case!!! If someone requests the _BODY_ attribute, we
	# must scan upwards in the attribute stack and grab the body text
	# of the element immediately above the current template's base tag.
	# This will give us the text which is enclosed by the template's
	# tags (i.e. the character data of the template element).
	if ($string =~ /${marker}\s*?_BODY_[\w\-:]*?\s*?${marker}/)
	{
		# Get index of template element's attr frame minus one more.
		my $index = -1;
		while ($attrStack[$index--]->{_TAG_} ne $baseTag) { }

		# Attribute stack dump is sometimes helpful in debugging.
		if ($debugMode && 0)
		{
			print "_BODY_ sub; index is $index, stack size is " .
				scalar(@attrStack) . ", matching tag is " .
					$attrStack[$index]->{_TAG_} . "\n";
			print "lenth of body in each frame:\n";
			foreach my $frame (@attrStack)
			{
				print "  " . $frame->{_TAG_} . ":" . length($frame->{_BODY_});
			}
			print "\n";
		}
		
		# ...and substitute that.
		$string =~ s/${marker}\s*?(_BODY_[\w\-:]*?)\s*?${marker}/
			MungeAttributeSubstitition($1, $attrStack[$index]->{_BODY_}) /eg;
	}

	# Substitute other attributes as required. Start 
	# with plain %%%thing%%% ones first.
	$string =~ s/${marker}\s*?([\w\-:]+?)\s*?${marker}/
		MungeAttributeSubstitition($1) /eg;
	
	# Now do %%%(thing)%%% ones, which may have contained plain
	# %%%thing%%% ones that were just sub'd in the line above.
	$string =~ s/${marker}\(\s*?([\w\-:]+?)\s*?\)${marker}/
		MungeAttributeSubstitition($1) /eg;

	return $string;
}

#
# MungeAttributeSubstitition
#
# Attributes can have post-processors on them. This scans for
# processors and applies them as needed (a.k.a. munging), returning
# the munged attr. The format of a variable which should be processed
# is attr-PROCESSOR, where the attribute is "attr" and the processor
# name is "PROCESSOR". Processors can be chained, too.
#
sub MungeAttributeSubstitition
{
	my ($attribute, $substitute) = @_;

	my %processors = ("URLENCODED" => \&URLEncode,
					  "LOWERCASE"  => \&Lowercase,
					  "UPPERCASE"  => \&Uppercase,);

	# Split the attribute name across dashes, with each chunk being a
	# potential processor
	my @attrchunks = split("-", $attribute);
	my ($chunk, $processor, @processors);

	# Now scan backwards over our chunks, popping off ones which
	# match known processors. Stop at the first unknown chunk, which
	# is part of the attribute name.
	while (defined ($processor = $processors{$chunk = pop @attrchunks}))
	{
		XML::GXML::Util::Log("found processor $processor for $attribute");
		push(@processors, $processor);
	}
	push (@attrchunks, $chunk); # push last one back on

	# Now restore the attribute name (which may have had dashes in
	# it), minus the processors chained on the end.
	$attribute = join("-", @attrchunks);
	
	# Use the restored attr name to get the substitute.
	$substitute = Attribute($attribute) 
		unless (defined $substitute || $attribute eq "_BODY_");

	# print "final attr $attribute = $substitute\n";

	# Now apply each processor to the substitute.
	while ($processor = pop @processors)
	{
		$substitute = &$processor($substitute);
	}

	# Return an empty string if $substitute is undef.
	$substitute = '' unless defined($substitute);

	return $substitute;
}



#######################################################################
# gxml:x commands
#######################################################################


#
# ExistsCommand
#
# Returns 'discard' to HandleEnd unless the attribute 'expr' is true.
# 'expr' may be an attribute name, or some combination of attribute
# names with logical operators, e.g. 'name AND NOT age'.
#
sub ExistsCommand
{
	my ($rParams) = @_;

	my $element = Attribute('expr');

	unless (length($element))
	{
		XML::GXML::Util::Log("couldn't find element for gxml:ifexists command");
		return;
	}

	#
	# Sub in perl logical operators in place of English...
	#
	$element =~ s/\band\b/\&\&/ig;
	$element =~ s/\bor\b/\|\|/ig;
	$element =~ s/\bnot\b/!/ig;
	$element =~ s/([\w:-_]+)/length(Attribute("$1"))/g;
	
	# ...and then eval() it. I love Perl.
	unless (eval($element))
	{
		# discard if expr not true
		return ['discard'];
	}

	# Be sure to discard the gxml:ifexists tag
	return ['striptag'];
}

#
# EqualsCommand
#
# Returns 'discard' to HandleEnd unless the attribute 'expr' is
# present and equal to 'equalto'.
# 
#
sub EqualsCommand
{
	my ($rParams) = @_;

	my $element = Attribute('expr');
	my $equalto = Attribute('equalto');

	unless (length($element))
	{
		XML::GXML::Util::Log("couldn't find element for gxml:equals command");
		return;
	}

    XML::GXML::Util::Log("equals: expr is $element, equalto is $equalto");

	unless (Attribute($element) eq $equalto)
	{
		# discard if expr not equal to equalto
		return ['discard'];
	}

	# Be sure to discard the gxml:ifequal tag
	return ['striptag'];
}

#
# NotEqualsCommand
#
# Returns 'discard' to HandleEnd unless the attribute 'expr' is
# present and NOT equal to 'equalto'.
# 
#
sub NotEqualsCommand
{
	my ($rParams) = @_;

	my $element = Attribute('expr');
	my $equalto = Attribute('equalto');

	unless (length($element))
	{
		XML::GXML::Util::Log("couldn't find element for gxml:equals command");
		return;
	}

    XML::GXML::Util::Log("equals: expr is $element, equalto is $equalto");

	unless (Attribute($element) ne $equalto)
	{
		# discard if expr equal to equalto
		return ['discard'];
	}

	# Be sure to discard the gxml:ifequal tag
	return ['striptag'];
}

#
# ForEachStart
#
# gxml:foreach will repeat a block for each value of its 'expr' param.
# Each iteration will contain a new value of expr, in the order they
# appear in the XML source. In this start handler we'll need to set up
# the special $rPreserve list with our expr so SubstituteAttributes
# will know to not mess with it.
#
sub ForEachStart
{
	my $element = Attribute('expr');

	unless (length($element))
	{
		XML::GXML::Util::Log("couldn't find element for gxml:foreach command");
		return;
	}

	$rPreserve = [] unless (defined($rPreserve));

	push(@$rPreserve, $element);
}

#
# ForEachEnd
#
# Counts the number of times we've interated, and rotates the 'expr'
# attribute to catch each value.
#
sub ForEachEnd
{
	my ($rParams) = @_;
	my $element = $rParams->{'expr'} || Attribute('expr');
	my $repeats = $rParams->{'repeats'};
	my $max     = $rParams->{'max'};

	unless (length($element))
	{
		XML::GXML::Util::Log("couldn't find element for gxml:foreach command");
		return;
	}

	if ($repeats)
	{
		# We've been through before, so just increment and rotate.
		$rParams->{'repeats'} = $repeats + 1;

		RotateAttribute($element);
	}
	else
	{
		# First time through. Set up our saved params hash.
		$repeats = 1;
		$max     = NumAttributes($element);

		# Bail if no attributes to iterate over.
		return ['discard'] if ($max == 0);

		# Don't need SubstituteAttributes to worry about us anymore.
		pop(@$rPreserve);

		$rParams->{'repeats'} = 1;
		$rParams->{'max'}     = $max;
		$rParams->{'expr'}    = $element;

		# Repeat and strip the gxml:foreach tag.
		return ['striptag', 'repeat'];
	}

	# We've rotated back to the start, so discard and stop looping.
	return ['discard'] if ($repeats >= $max);

	# We still need to loop. Repeat and strip the gxml:foreach tag.
	return ['striptag', 'repeat'];
}


#######################################################################
# Attribute post-processors
#######################################################################


#
# URLEncode
#
# Simple URL form encoder. Certainly not per-spec, but should work
# okay for now.
#
sub URLEncode
{
	my ($string) = @_;

	$string =~ s/^\s*(.*?)\s*$/$1/; # strip leading/trailing ws
	$string =~ s/\&/\%26/g;
	$string =~ s/\=/\%3d/g;
	$string =~ s/\?/\%3f/g;
	$string =~ s/ /\+/g;

	return $string;
}

# Lowercase: does what you'd expect it to.
sub Lowercase
{
	my ($string) = @_;
	
	$string =~ tr/A-Z/a-z/;
	
	return $string;
}

# Uppercase: ditto.
sub Uppercase
{
	my ($string) = @_;
	
	$string =~ tr/a-z/A-Z/;
	
	return $string;
}


#######################################################################
# GXML class template management
#######################################################################


#
# TemplateMgr
#
# Returns a reference to the template manager.
#
sub TemplateMgr
{
	my $self = shift;

	return $self->{_templateMgr};
}

#
# TemplateExists
#
# Helper method; returns TemplateExists() from the template manager.
#
sub TemplateExists
{
	my ($self, $name) = @_;

	return $self->{_templateMgr}->TemplateExists($name);
}

#
# SubstituteTemplate
#
# Copy the template and parse it as a separate XML blob, but retain
# the existing attribute stack. Returns the resulting text.
#
sub SubstituteTemplate
{
	my ($self, $templateName) = @_;

	# Make our own copy of the template so we can parse and substitute
	# our attributes into it.
	my $template = ${$self->TemplateMgr()->Template($templateName)};
	
	# Create our own aliai of relevant globals
	local ($output, $baseTag);

	#
	# Now create a new parser and parse the template. This will, of
	# course, recurse as necessary.
	#
	my $xp = new XML::Parser(ErrorContext => 2);
	$xp->setHandlers(Char		=> \&HandleChar,
					 Start		=> \&HandleStart,
					 End		=> \&HandleEnd,
					 Comment	=> \&HandleComment,
					 Default	=> \&HandleDefault);
	
	$xp->parse($template);
	
	return $output;
}


#######################################################################
# XML::GXML::TemplateManager
#######################################################################


package XML::GXML::TemplateManager;

use Cwd;

sub new
{
	my ($pkg, $templateDir, $addlTemplates, 
		$addlTemplate, $addlTempExists, $varMarker) = @_;
	my $baseDir = cwd();

	# Create the new beast
	my $self = bless
	{
		_templateDir => $templateDir,
		_varMarker   => $varMarker,
	}, $pkg;

	$self->{_addlTemplates}  = $addlTemplates  if defined($addlTemplates);
	$self->{_addlTemplate}   = $addlTemplate   if defined($addlTemplate);
	$self->{_addlTempExists} = $addlTempExists if defined($addlTempExists);

	# Assemble the list of files in the templates directory
	chdir($templateDir);
	my $templateListRef = XML::GXML::Util::GetFileList();
	chdir($baseDir);

	foreach my $filename (@$templateListRef)
	{
		# Only grab .xml files
		next unless ($filename =~ /\.xml$/ || $filename =~ /\.xhtml$/);
		
		# Strip ".xml" for saving in template hash; these will be
		# referenced sans .xml extension
		$filename =~ s/\.xml$//;
		$filename =~ s/\.xhtml$//;

		# Store blank placeholder
		$self->{$filename} = '';
	}

	return $self;
}

sub DESTROY
{
	# nothing needed for now
}

#
# LoadTemplate
#
# Loads a given template name into the cache.
#
sub LoadTemplate
{
	my ($self, $name) = @_;
	my $baseDir = cwd();

	XML::GXML::Util::Log("loading template $name");

	my $filename = XML::GXML::Util::ChangeToDirectory(
					File::Spec->catfile($self->{_templateDir}, 
										$name . '.xml'));

	unless (open(TEMPLATE, $filename))
	{
		# Try .xhtml for file extension
		$filename =~ s/\.xml$/.xhtml/;

		unless (open(TEMPLATE, $filename))
		{
			XML::GXML::Util::Log("ERROR: couldn't open template $name: $!");
			chdir($baseDir);
			return;
		}
	}

	# slurp everything
	local $/;
	undef $/;	# turn on slurp mode
	my $file = <TEMPLATE>;
	
	close(TEMPLATE);
	chdir($baseDir);

	# A quick bit of haquage: change the variable markers
	# %%%blah%%% to something which is still weird (i.e. not
	# likely to conflict with legit content) but which can also be
	# a valid in an element name, which %%%blah%%% is not. I'm
	# picking "::VAR::blah::VAR::". Make sure this matches the
	# default $marker var in SubstituteAttribute().
	$file =~ s/$self->{_varMarker}/::VAR::/g;

	# ...and finally save a reference to the stuff we slurped.
	$self->{$name} = \$file;
}

#
# Template
#
# Returns the text of a template. Loads the template into memory if it
# isn't already cached.
#
sub Template()
{
	my ($self, $name) = @_;

	# Valid template name?
	unless (exists $self->{$name})
	{
		# Check addl hash if provided
		if (defined ($self->{_addlTemplates})
			&& defined($self->{_addlTemplates}->{$name}))
		{
			return &{$self->{_addlTemplates}->{$name}}($name);
		}
		# Check old-style addl function if provided
		elsif (defined ($self->{_addlTemplate}))
		{
			return &{$self->{_addlTemplate}}($name);
		}
	}

	# If we don't have it cached already, load it.
	unless (length($self->{$name}))
	{
		$self->LoadTemplate($name);
	}
	
	# MUST fetch from hash, as LoadTemplate may have updated the hash
	# with a filled-in entry.
	return $self->{$name};
}

#
# TemplateExists
#
# Does a given name match a template?
#
sub TemplateExists()
{
	my ($self, $name) = @_;

	# Valid template name?
	if (exists $self->{$name})
	{
		return 1;
	}
	# Check new-stile addl hash
	elsif (defined ($self->{_addlTemplates})
		   && defined($self->{_addlTemplates}->{$name}))
	{
		return 1;
	}
	# How about the (old style) addl method, if there is one?
	elsif (defined ($self->{_addlTempExists}))
	{
		return &{$self->{_addlTempExists}}($name);
	}

	# Guess not.
	return 0;
}

#
# CheckModified
#
# Checks to see if any templates have been modified since the last
# call to UpdateModified(). Returns true if so.
#
sub CheckModified()
{
	my $self    = shift;
	my $baseDir = cwd();
	my %templateModtimes;
	my $templatesChanged = 0;

	# Load the saved modification times for the templates. If any
	# templates have changed, return 1.

	my $modtimeFile = File::Spec->catfile($self->{_templateDir}, '.modtimes');
	XML::GXML::Util::LoadModtimes($modtimeFile, \%templateModtimes);

	foreach my $template (keys %$self)
	{
		next if $template =~ /^_/; # skip private variables

		$template = XML::GXML::Util::ChangeToDirectory(
						 File::Spec->catfile($self->{_templateDir},
						 $template . '.xml'));

		unless (-e $template)
		{
			# Try .xhtml for file extension
			$filename =~ s/\.xml$/.xhtml/;
		}

		# Check the mod time
		my $modtime = (stat $template)[9];
		if (!defined($templateModtimes{$template}) ||
			!defined($modtime)                     ||
			$modtime != $templateModtimes{$template})
		{
			XML::GXML::Util::Log("template $template was modified");
			$templateModtimes{$template} = $modtime;
			$templatesChanged = 1;
		}

		chdir($baseDir);
	}

	# Save this if needed for UpdateModified.
	$self->{_modtimes} = \%templateModtimes;

	return $templatesChanged;
}

#
# UpdateModified
#
# Updates the template mod times file to reflect current reality.
#
sub UpdateModified
{
	my $self = shift;

	# Update our modtimes if client didn't do that before
	unless (exists $self->{_modtimes})
	{
		$self->CheckModified();
	}

	my $modtimeFile = File::Spec->catfile($self->{_templateDir}, '.modtimes');

	XML::GXML::Util::SaveModtimes($modtimeFile, $self->{_modtimes});
}


#######################################################################
# XML::GXML::AttributeCollector
#######################################################################


package XML::GXML::AttributeCollector;

use Cwd;

# These vars are used as locals during parsing.
use vars ('@attrStack', '$baseTag', '$self');

sub new
{
	my ($pkg, $element, $key, $tocollect) = @_;

	my $self = bless
	{
		_element => $element,
		_collect => $tocollect,
		_key     => $key,
	}, $pkg;

	return $self;
}

sub DESTROY
{
	# nothing needed for now
}

sub Collect
{
	my ($selfParam, $stuff) = @_;

	# Set up these pseudo-global vars
	local (@attrStack, $baseTag);

	# Also create this so XML::Parser handlers can see it
	local $self = $selfParam;

	# Process the beastie
	my $xp = new XML::Parser(ErrorContext => 2);
	$xp->setHandlers(Char		=> \&CollectorChar,
					 Start		=> \&CollectorStart,
					 End		=> \&CollectorEnd,);

	$xp->parse($stuff);
}

sub CollectFromFile
{
	my ($selfParam, $file) = @_;
	my $baseDir = cwd();

	# Set up these pseudo-global vars
	local (@XML::GXML::attrStack, $baseTag);

	# Also create this so XML::Parser handlers can see it
	local $self = $selfParam;

	my $fileName = XML::GXML::Util::ChangeToDirectory($file);
	
	open(IN, $fileName) || die "open input $fileName: $!";

	# Process the beastie
	my $xp = new XML::Parser(ErrorContext => 2);
	$xp->setHandlers(Char		=> \&CollectorChar,
					 Start		=> \&CollectorStart,
					 End		=> \&CollectorEnd,);

	$xp->parse(*IN);

	close(IN);
	chdir($baseDir);
}

sub Clear
{
	my $self = shift;

	foreach my $item (keys %$self)
	{
		next if $item =~ /^_/; # preserve private vars

		delete $self->{$item};
	}
}

sub CollectorStart()
{
	my ($xp, $element, %attrs) = @_;
	my ($key);

	# First element in the document is always the base
	$baseTag = $element unless defined($baseTag);
	
	foreach $key (keys %attrs)
	{
		my $val = $attrs{$key};

		# Compact whitespace, strip leading and trailing ws.
		$val =~ s/\s+/ /g;
		$val =~ s/^\s*(.*?)\s*$/$1/;

		# Stick newly molested $val back into $attrs if we've still
		# got something left, or delete the attribute if it's empty.
		if (length($val))
			{ $attrs{$key} = $val; }
		else
			{ delete $attrs{$key}; }
	}

	# Save our tag name in the attrs, too.
	$attrs{_TAG_} = $element;

	# Add these attributes to the master tree.
	XML::GXML::AddAttributeNode($element, \%attrs);
}

sub CollectorEnd
{
	my ($xp, $element) = @_;
	my %values;

	# We can bail quick if this isn't an element we're looking for
	if ($element ne $self->{_element})
	{
		XML::GXML::LeaveAttributeNode();
		return;
	}

	foreach my $attr (@{$self->{_collect}})
	{
		$values{$attr} = XML::GXML::Attribute($attr);
	}

	my $key = XML::GXML::Attribute($self->{_key});
	$self->{$key} = \%values;

	XML::GXML::LeaveAttributeNode();
}

sub CollectorChar()
{
	my ($xp, $string) = @_;

	# Achtung! We must process the original string, not the one
	# munged by Expat into UTF-8, which will automatically remap
	# things like "&lt;" into "<". If the author wrote &lt; in their
	# XML document, that's probably because they wanted it in their
	# HTML document, too.
	$string = $xp->original_string;

	# Append the body text to the _BODY_ attribute of the last
	# attribute frame on the stack (i.e. that of the most immediately
	# enclosing element).
	$XML::GXML::attrStack[-1]->{_BODY_} .= $string;
}


#######################################################################
# Utilities
#######################################################################


package XML::GXML::Util;

use Cwd;
use File::Basename;
use File::Path;
use File::Spec;

#
# ChangeToDirectory
#
# Given a path to a file, change into the directory for that file,
# creating the directories along the way if they don't already exist.
# Returns the file name sans all directory stuff.
#
sub ChangeToDirectory
{
	my ($fullName) = @_;

	my ($name, $path) = fileparse($fullName);

	# strip trailing / if necessary
	$path =~ s/\/$//;

	mkpath($path);
	chdir($path);
	
	return $name;
}

#
# GetFileList
#
# Scans the current directory and returns all the filenames therein,
# recursing through directories as needed. This should probably be
# replaced with something super-easy-to-use from an existing Perl
# module. (Real Soon Now.)
#
sub GetFileList
{
	my ($prefix) = @_;
	my (@files, $entry, $name);
	my $currentDir = cwd();
	local *DIR;

	opendir(DIR, $currentDir) or die "can't opendir startdir: $!";
	
	while(defined($entry = readdir(DIR)))
	{
		next if $entry =~ /^\.\.?$/; # skip '.' and '..'
		next if $entry =~ /^\.modtimes$/; # skip our mod times file
		next if $entry =~ /^CVS$/;   # skip CVS directories
		next if $entry =~ /^\.AppleDouble$/;	# ditto
		next if $entry =~ /~$/;		 # emacs temp files
		next if $entry =~ /^\#/;	 # ditto

		if (defined($prefix))
			{ $name = File::Spec->catdir($prefix, $entry); }
		else
			{ $name = $entry; }

		if (chdir($entry))
		{
			my $subfilesRef = GetFileList($name);
			push(@files, @$subfilesRef);
			
			chdir($currentDir);
		}
		else
		{
			push(@files, $name);
		}
	}
	
	closedir(DIR);
	
	return \@files;
}

#
# LoadModtimes
#
# Loads a list of modification times into a hash. Format of the mod
# time file is "filename\tmodtime", one filename per line.
#
sub LoadModtimes
{
	my ($modfile, $modtimesRef) = @_;

	open(MODTIMES, $modfile) or return;

	while (my $line = <MODTIMES>)
	{
		chomp($line);
		my ($filename, $modtime) = split("\t", $line);
		$modtimesRef->{$filename} = $modtime;
	}
	
	close(MODTIMES);
}

#
# SaveModtimes
#
# Dumps a hash of mod times into a file which LoadModtimes can read.
#
sub SaveModtimes
{
	my ($modfile, $modtimesRef) = @_;

	open (MODTIMES, '>' . $modfile);

	foreach my $filename (keys %$modtimesRef)
	{
		print MODTIMES $filename . "\t" . $modtimesRef->{$filename} . "\n";
	}

	close (MODTIMES);
}

#
# Log
#
# Prints stuff to STDERR if $debugMode is turned on.
#
sub Log
{
	if ($debugMode)
	{
		my $message = shift;
	
		print STDERR "**log** $message\n";
	}
} 

# sucessful package load
1;

__END__

=head1 NAME

XML::GXML - Perl extension for XML transformation, XML->HTML conversion

=head1 SYNOPSIS

  use XML::GXML;
  
  my $gxml = new XML::GXML();
  
  # Take a scalar, return a scalar
  my $xml = '<basetag>hi there</basetag>';
  my $new = $gxml->Process($xml);
  
  # Take a file, return a scalar
  print $gxml->ProcessFile('source.xml');
  
  # Take a file, output to another file
  $gxml->ProcessFile('source.xml', 'dest.xml');

=head1 DESCRIPTION

GXML is a perl module for transforming XML. It may be put to a variety
of tasks; in scope it is similar to XSL, but less ambitious and much
easier to use. In addition to XML transformations, GXML is well-suited
to translating XML into HTML. Please see the documentation with your
distribution of GXML, or visit its web site at:

  http://multipart-mixed.com/xml/

=head1 SUMMARY OF PARAMETERS

These are the options for creating a new GXML object. All options are
passed in via a hash reference, as such:

  # Turn on HTML mode and provide callbacks hash
  my $gxml = new XML::GXML({'html'      => 'on', 
                            'callbacks' => \%callbacks});

Here's the complete list of options. Keys are provided first, with
their values following:

  html:           'on' or 1 will format output as HTML (see docs).
  templateDir:    directory to look for templates.
  remappings:     hashref mapping tag names to remap to their remapped
                  names.
  dashConvert:    'on' or 1 will convert '--' to unicode dash.
  addlAttrs:      reference to subroutine that gets called on lookup
                  for dynamic attributes.
  addlTemplates:  hashref mapping from dynamic template name to
                  subroutine that will create that template. (Use this
                  instead of the following 2 params.)
  addlTempExists: (outdated -- use addlTemplates instead.)
  addlTemplate:   (outdated -- use addlTemplates instead.)

=head1 AUTHOR

Josh Carter, josh@multipart-mixed.com

=head1 SEE ALSO

perl(1).

=cut
