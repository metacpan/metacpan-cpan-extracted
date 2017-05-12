package Lisp::Localize;

use strict;

use vars qw($DEBUG);
use Lisp::Symbol qw(symbolp);

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    print "new $self\n" if $DEBUG;
    $self;
}

sub save_and_set
{
    my($self, $symbol, $newval) = @_;
    die "Not a symbol $self->local($symbol, $newval)" unless symbolp($symbol);
    print "Localize $symbol->{'name'}\n" if $DEBUG;
    die "Can't localized the same symbol twice" if exists $self->{$symbol};
    unless (exists $symbol->{'value'}) {
	$self->{$symbol} = [$symbol];
    } else {
	$self->{$symbol} = [$symbol, $symbol->{'value'}];
    }
    $symbol->value($newval);
    $self;
}

sub DESTROY
{
    my $self = shift;
    # restore all values
    for (values %$self) {
	my $sym = shift @$_;
	print "Restoring $sym->{'name'}\n" if $DEBUG;
	if (@$_) {
	    $sym->{'value'} = shift @$_;
	} else {
	    delete $sym->{'value'};
	}
    }
}

1;
