package Lisp::Subr::Core;

# implements the core subrs

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

use Lisp::Symbol      qw(symbol);
use Lisp::Special     qw(make_special);
use Lisp::Reader      qw(lisp_read);
use Lisp::Printer     qw(lisp_print);
use Lisp::Interpreter qw(lisp_eval);

use Lisp::Cons        qw(consp);

my $lambda = symbol("lambda");
my $nil    = symbol("nil");
my $t      = symbol("t");

sub lisp_true { defined($_[0]) && $_[0] != $nil }

symbol("list")->function(sub {[@_]});

symbol("quote")->function(make_special(sub {$_[0]}));
symbol("set")->function(sub {$_[0]->value($_[1]); $_[1]} );
symbol("setq")->function(
   make_special(sub{my $val = lisp_eval($_[1]); $_[0]->value($val); $val}));

symbol("car")->function(sub {$_[0][0]});
symbol("cdr")->function(
sub {
   my $obj = shift;
   return $obj->[-1] if consp($obj);
   die "wrong-argument-type" unless ref($obj) eq "ARRAY";

   #XXX The semantics is not really correct in this situation, because
   # we will return a copy of the CDR.  This matters if somebody modifies
   # the original list or the CDR.
   [ @{$obj}[1 .. @$obj - 1] ];
});

symbol("print")->function(sub{lisp_print($_[0])});
symbol("read")->function(sub{lisp_read($_[0])});
symbol("eval")->function(sub{lisp_eval($_[0])});

# Just some way to print out something
symbol("write")->function(sub{print join("\n", (map lisp_print($_), @_), "")});

# control structues
symbol("progn")->function(sub {$_[-1]});
symbol("prog1")->function(sub {$_[0]});
symbol("prog2")->function(sub {$_[1]});

symbol("if")->function(
    make_special(
	sub {
	    my $cond = shift;
	    $cond = lisp_eval($cond);
	    if (lisp_true(lisp_eval($cond))) {
		return lisp_eval(shift);  # then
	    }
	    shift;  # skip then-form
	    my $res;
	    for (@_) { $res = lisp_eval($_) };
	    return $res;
	}));

symbol("cond")->function(
    make_special(
        sub {
	    my $res;
	    my $clause;
	    for $clause (@_) {
		$res = lisp_eval($clause->[0]);
		next unless lisp_true($res);
		my $pc;
		for ($pc = 1; $pc < @$clause; $pc++) {
		    $res = lisp_eval($clause->[$pc]);
		}
		return $res;
	    }
	    undef;
	}));


sub lisp_not { lisp_true($_[0]) ? $nil : $t }

symbol("not" )->function(\&lisp_not);
symbol("null")->function(\&lisp_not);

symbol("and")->function(
    make_special(
        sub {
	    my $res;
	    for (@_) {
		$res = lisp_eval($_);
		return $res unless lisp_true($res);
	    }
	    $res;
	}));

symbol("or")->function(
    make_special(
        sub {
	    my $res;
	    for (@_) {
		$res = lisp_eval($_);
		return $res if lisp_true($res);
	    }
	    $res;
	}));

symbol("while")->function(
    make_special(
        sub {
	    my $condition = shift;
	    while (lisp_true(lisp_eval($condition))) {
		# evaluate body
		for (@_) { lisp_eval($_) }
	    }
	    undef;
	}));

# numeric functions
symbol("floatp")->function(sub {$_[0] =~ /^[-+]?(?:\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?$/ ? $t : $nil });
symbol("integerp")->function(sub {$_[0] =~ /^\d+$/ ? $t : $nil });
symbol("numberp")->function(symbol("floatp")->function);
symbol("zerop")->function(sub {$_[0] == 0 ? $t : $nil });

symbol("=" )->function(sub {$_[0] == $_[1] ? $t : $nil });
symbol("/=")->function(sub {$_[0] != $_[1] ? $t : $nil });
symbol("<" )->function(sub {$_[0] <  $_[1] ? $t : $nil });
symbol("<=")->function(sub {$_[0] <= $_[1] ? $t : $nil });
symbol(">" )->function(sub {$_[0] >  $_[1] ? $t : $nil });
symbol(">=")->function(sub {$_[0] >= $_[1] ? $t : $nil });


symbol("1+")->function(sub { $_[0]+1} );
symbol("+")->function(sub { my $sum=shift; for (@_) {$sum+=$_} $sum });
symbol("1-")->function(sub { $_[0]-1} );
symbol("-")->function(
sub {
    return 0 if $_ == 0;
    return -$_[0] if @_ == 1;
    my $sum = shift; for(@_) {$sum-=$_}
    $sum
});
symbol("*")->function(sub { my $prod=1; for (@_){$prod*=$_} $prod});
symbol("/")->function(sub { my $div=shift; for (@_){ $div/=$_} $div});
symbol("%")->function(sub { $_[0] % $_[1]});

symbol("max")->function(sub {my $max=shift;for(@_){$max=$_ if $_ > $max}$max});
symbol("min")->function(sub {my $min=shift;for(@_){$min=$_ if $_ < $min}$min});


# defining functions
symbol("fset")->function(sub {$_[0]->function($_[1]); $_[1]});
symbol("symbol-function")->function(sub {$_[0]->function});

symbol("defun")->function(
    make_special(
        sub {
	    my $sym = shift;
	    $sym->function([$lambda, @_]);
	    $sym;
	}));

symbol("put")->function(sub{$_[0]->put($_[1] => $_[2])});
symbol("get")->function(sub{$_[0]->get($_[1])});


# dynamic scoping
symbol("let")->function(
    make_special(
        sub {
	    my $bindings = shift;
	    my @bindings = @$bindings;  # make a copy

	    # First evaluate all bindings as variables
	    for my $b (@bindings) {
		if (symbolp($b)) {
		    $b = [$b, $nil];
		} else {
		    my($sym, $val) = @$b;
		    $val = $val->value if $val && symbolp($val);
		    $b = [$sym, $val];
		}
	    }
   
	    # Then localize
	    require Lisp::Localize;
	    my $local = Lisp::Localize->new;
	    for my $b (@bindings) {
		$local->save_and_set(@$b);
	    }

	    my $res;
	    for (@_) {
		$res = lisp_eval($_);
	    }
	    $res;
	}));


symbol("let*")->function(
    make_special(
        sub {
	    my $bindings = shift;
	    require Lisp::Localize;
	    my $local = Lisp::Localize->new;

	    # Evaluate and localize in the order given
	    for my $b (@$bindings) {
		if (symbolp($b)) {
		    $local->save_and_set($b, $nil);
		} else {
		    my($sym, $val) = @$b;
		    $val = $val->value if $val && symbolp($val);
		    $local->save_and_set($sym, $val);
		}
	    }
	    my $res;
	    for (@_) {
		$res = lisp_eval($_);
	    }
	    $res;
	}));

1;
