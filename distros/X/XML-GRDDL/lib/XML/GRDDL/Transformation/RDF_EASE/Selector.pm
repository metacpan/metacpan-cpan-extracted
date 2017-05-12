package XML::GRDDL::Transformation::RDF_EASE::Selector;

use 5.008;
use strict;

our $VERSION = '0.004';

sub specificity
{
	return (
			specificity_count_ids(@_) * 1000000 +
			specificity_count_attrs(@_) * 1000 +
			specificity_count_elems(@_)
		);
}

sub get_tokens
{
	my $selector = shift;
	my @rv;
	
	while (length $selector)
	{
		if ($selector =~ /^ \s* ([\>\+]) \s* (.*) $/x)
		{
			push @rv, $1;
			$selector = $2;
		}
		elsif ($selector =~ /^ (\s+) (.*) $/x)
		{
			push @rv, ' ';
			$selector = $2;
		}
		elsif ($selector =~ /^ ([^\s\>\+]+) ([\s\>\+].*) $/x)
		{
			push @rv, $1;
			$selector = $2;
		}
		else
		{
			push @rv, $selector;
			$selector = '';
		}
	}
	
	return \@rv;
}

sub specificity_count_ids
{
	return scalar grep { /\#/ } @_;
}

sub specificity_count_attrs
{
	return scalar grep { /[\.[]/ } @_;
}

sub specificity_count_elems
{
	return scalar grep { /^[a-z]/i } @_;
}

sub to_xpath
{
	return '//'.to_partial_xpath(\@_);
}

sub token_to_pieces
{
	my $str = shift;
	my @rv;
	
	if ($str =~ /^ ([a-z0-9\*]+) (.*) $/ix)
	{
		push @rv, $1;
		$str = $2;
	}
	
	while (length $str)
	{
		if ($str =~ /^ (\[[^\]]*\]) (.*) $/ix)
		{
			push @rv, $1;
			$str = $2;
		}
		elsif ($str =~ /^ (\:[a-z-]+\([a-z_-]*\)) (.*) $/ix)
		{
			push @rv, $1;
			$str = $2;
		}
		elsif ($str =~ /^ (\.[a-z0-9_-]+) (.*) $/ix)
		{
			push @rv, $1;
			$str = $2;
		}
		elsif ($str =~ /^ (\#[a-z0-9_-]+) (.*) $/ix)
		{
			push @rv, $1;
			$str = $2;
		}
	}
	
	return @rv;
}

sub to_partial_xpath
{
	my $toks   = shift;
	my @tokens = @{$toks};
	my $self   = shift;
	my $next   = 0;
	my $t      = shift @tokens || return '';
	my $rv     = '';
	
	# Make $t always start with the tag name.
	$t = "*$t"
		if ($t =~ /^[\.\#\:]/);
	
	if ($t eq '>')
		{ $rv = '/'; }
	elsif ($t eq ' ')
		{ $rv = '//'; }
	elsif ($t eq '+')
		{ $rv = '/following-sibling::*[1]/'; $next = 1; }
	else
	{
		my @bits = token_to_pieces($t);
		foreach my $bit (@bits)
		{
			if ($bit =~ /^ \. (.*) $/ix)
				{ $rv .= "[contains(concat(\" \",\@class,\" \"),concat(\" \",\"$1\",\" \"))]"; }
			elsif ($bit =~ /^ \# (.*) $/ix)
				{ $rv .= "[\@id=\"$1\"]"; }
			elsif ($bit =~ /^ \[ \s* (.*) \s* \~\= \s* [\"\']?(.*)[\"\']? \s* \] $/ix)
				{ $rv .= "[contains(concat(\" \",\@$1,\" \"),concat(\" \",\"$2\",\" \"))]"; }
			elsif ($bit =~ /^ \[ \s* (.*) \s* \|\= \s* [\"\']?(.*)[\"\']? \s* \] $/ix)
				{ $rv .= "[\@$1=\"$2\" or starts-with(\@$1,concat(\"$2\",\"-\"))]"; }
			elsif ($bit =~ /^ \[ \s* (.*) \s*   \= \s* [\"\']?(.*)[\"\']? \s* \] $/ix)
				{ $rv .= "[\@$1=\"$2\"]"; }
			elsif ($bit =~ /^ \[ \s* (.*) \s* \] $/ix)
				{ $rv .= "[\@$1]"; }
			elsif (lc($bit) eq ':first-child')
				{ $rv = "*[1]/self::$rv"; }
			elsif ($bit =~ /^ \[ \s* \:lang\((.*)\) \s* \] $/ix)
				{ $rv .= "[\@lang=\"$1\" or starts-with(\@lang,concat(\"$1\",\"-\"))]"; }
			else
				{ $rv .= "xhtml:${bit}"; }
		}
	}
		
	return 'self::'.$rv.to_partial_xpath(\@tokens, $next)
		if ($self);
	return $rv.to_partial_xpath(\@tokens, $next);
}

1;

__END__

=head1 NAME

XML::GRDDL::Transformation::RDF_EASE::Selector - CSS 2.1 selector utility functions

=head1 DESCRIPTION

Utility functions for dealing with CSS 2.1 selectors.

Currently nothing here is suitable for external use. Hopefully as this is cleaned up,
it might be able to export some useful functions.

=head1 SEE ALSO

L<XML::GRDDL::Transformation::RDF_EASE::Functional>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
