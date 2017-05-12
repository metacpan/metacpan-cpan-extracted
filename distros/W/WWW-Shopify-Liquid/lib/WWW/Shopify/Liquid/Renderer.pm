#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

# Designed to wrap objects in the hash taht shoudln't be cloned. Only works for top level.
package WWW::Shopify::Liquid::Renderer::NoClone;
sub new { return bless { inner => $_[0] }; }

package WWW::Shopify::Liquid::Renderer;
use base 'WWW::Shopify::Liquid::Pipeline';
use WWW::Shopify::Liquid::Security;

# WATCH THIS CLONING. IT CAN CAUSE SEGFAULTS DEPENDING ON WHAT'S CLONED.
sub new { my $package = shift; return bless { clone_hash => 1, silence_exceptions => 1, timeout => undef, max_inclusion_depth => 5, inclusion_context => undef, inclusion_depth => 0, security => WWW::Shopify::Liquid::Security->new, @_ }, $package; }
sub clone_hash { $_[0]->{clone_hash} = $_[1] if defined $_[1]; return $_[0]->{clone_hash}; }
sub security { $_[0]->{security} = $_[1] if defined $_[1]; return $_[0]->{security}; }
sub silence_exceptions { $_[0]->{silence_exceptions} = $_[1] if defined $_[1]; return $_[0]->{silence_exceptions}; }
sub timeout { $_[0]->{timeout} = $_[1] if defined $_[1]; return $_[0]->{timeout}; }
sub max_inclusion_depth { $_[0]->{max_inclusion_depth} = $_[1] if defined $_[1]; return $_[0]->{max_inclusion_depth}; }
sub inclusion_context { $_[0]->{inclusion_context} = $_[1] if defined $_[1]; return $_[0]->{inclusion_context}; }
sub inclusion_depth { $_[0]->{inclusion_depth} = $_[1] if defined $_[1]; return $_[0]->{inclusion_depth}; }

use Clone qw(clone);

sub render {
	my ($self, $hash, $ast) = @_;
	return '' if !$ast && !wantarray;
	my $hash_clone = $self->clone_hash && $self->clone_hash == 1 ? clone($hash) : $hash;
	return ('', $hash_clone) unless $ast;
	my $result;
	eval {
		local $SIG{ALRM} = sub { die new WWW::Shopify::Liquid::Exception::Timeout(); };
		alarm $self->timeout if $self->timeout;
		$result = $ast->isa('WWW::Shopify::Liquid::Element') ? $ast->render($self, $hash_clone) : "$ast";
		alarm 0;
	};
	if (my $exp = $@) {
		die $exp;
	}
	return $result unless wantarray;
	return ($result, $hash_clone);
}

1;