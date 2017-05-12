package WWW::Agent::Plugins::Focus;

use strict;
use Data::Dumper;
use POE;

sub new {
    my $class   = shift;
    my %options = @_;
    my $self    = bless { }, $class;

    $self->{hooks} = { 
	'init' => sub {
	    my ($kernel, $heap)   = (shift, shift);
#warn "focus reset";
	    $heap->{focus} = undef;
	    return 1; # it worked
	},
	'cycle_pos_response' => sub {
	    my ($kernel, $heap) = (shift, shift);
#warn "positive response code";
	    my ($tab, $object)  = (shift, shift);
	    $heap->{focus} = _refocus ($object->content);
##warn "focus after response ".Dumper $heap->{focus};
	    return $object;
	},
	'cycle_neg_response' => sub {
	    my ($kernel, $heap)   = (shift, shift);
	    my ($tab, $object)  = (shift, shift);
#warn "negative response code";
	    $heap->{focus} = {};
	    return $object;
	},
	'focus_reset' => sub {
	    my ($kernel, $heap) = @_[KERNEL, HEAP];
#warn "focus reset";
	    $heap->{focus} = _refocus ($heap->{focus}->{content});
#warn "after reset ".$heap->{focus}->{focus};
	},
	'focus_set' => sub {   
	    my ($kernel, $heap) = @_[KERNEL, HEAP];
#warn "focus set";
	    my ($tag, $pattern, $index, $baseurl) = @_[ARG0, ARG1, ARG2, ARG3];

	    my $focus = $heap->{focus}->{focus};
					
	    my @cands = $focus->look_down ( sub {
		my $e = shift;
		return $e->tag eq $tag;
	    } );
#warn "found cands". scalar @cands;
#warn "found cands".  Dumper \@cands;

	    if ($pattern) { # filter out those which do match
		@cands = grep (_match ($_->as_HTML, $pattern), @cands);
	    }
#warn "2 found cands ". scalar @cands;
#warn "2 found cands".  Dumper \@cands;
#warn "index ".$index;

	    $heap->{focus}->{focus} = $cands[$index]; # just to indicate what we have found
	    if ($heap->{focus}->{focus} && $tag =~ /form/i) {
		use HTML::Form;
		$heap->{focus}->{form} = HTML::Form->parse ($heap->{focus}->{focus}->as_HTML, $baseurl);
#warn "created form";
	    }
	    return $heap->{focus}->{focus};
	},
	'focus_get' => sub  {
	    my ($kernel, $heap) = @_[KERNEL, HEAP];
#warn "focus get";
	    return $heap->{focus}->{form} || $heap->{focus}->{focus}; # when we have a FORM we prefer that
	},
	'focus_fill' => sub {
	    my ($kernel, $heap) = @_[KERNEL, HEAP];
#warn "focus fill";
	    my ($field, $value) = @_[ARG0, ARG1];

	    return 0 unless $heap->{focus}->{form};
	    my $form = $heap->{focus}->{form};
	    
	    $form->value( $field, $value );
#warn  $form->dump;
	    return 1;
	},
    };

    $self->{namespace} = 'focus';
    return $self;
}

sub _match {
    my $s = shift;
    my $p = shift;
 
#warn "checking '$s' against pattern $p".Dumper $p;
    return $s =~ $p;
}

sub _refocus {
    my $content = shift;

    use HTML::TreeBuilder;
    return { focus   => HTML::TreeBuilder->new_from_content ($content),
	     form    => undef,
	     content => $content };
}

1;

__END__



