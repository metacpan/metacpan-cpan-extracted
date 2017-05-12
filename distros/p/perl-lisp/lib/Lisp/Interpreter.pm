package Lisp::Interpreter;

use strict;
use vars qw($DEBUG @EXPORT_OK $VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

use Lisp::Symbol  qw(symbol symbolp);
use Lisp::Printer qw(lisp_print);
use Lisp::Special qw(specialp);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(lisp_eval lisp_read_eval_print);

my $macro  = symbol("macro");
my $lambda = symbol("lambda");
my $nil    = symbol("nil");

# symbols in the argument list
my $opt    = symbol("&optional");
my $rest   = symbol("&rest");

my $evalno = 0;

sub lisp_eval
{
    my $form = shift;
    my $no = ++$evalno;
    
    if ($DEBUG) {
	print "lisp_eval $evalno ", lisp_print($form), "\n";
    }

    return $form unless ref($form);  # a string or a number
    return $form->value if symbolp($form);

    my @args = @$form;
    my $func = shift(@args);

    while (symbolp($func)) {
	if ($func == $macro) {
	    shift(@args);
	    last;
	} elsif ($func == $lambda) {
	    last;
	} else {
	    $func = $func->function;
	}
    }

    unless (specialp($func) || $func == $macro) {
	# evaluate all arguments
	for (@args) {
	    if (ref($_)) {
		if (symbolp($_)) {
		    $_ = $_->value;
		} elsif (ref($_) eq "ARRAY") {
		    $_ = lisp_eval($_);
		} else {
		    # leave it as it is
		}
	    }
	}
    }

    my $res;
    if (UNIVERSAL::isa($func, "CODE")) {
	$res = &$func(@args);
    } elsif (ref($func) eq "ARRAY") {
	if ($func->[0] == $lambda) {
	    $res = lambda($func, \@args)
	} else {
	    die "invalid-list-function (@{[lisp_print($func)]})";
	}
    } else {
	die "invalid-function (@{[lisp_print($func)]})";
    }
    if ($DEBUG) {
	print " $no ==> @{[lisp_print($res)]}\n";
    }
    $res;
}


sub lambda  # calling a lambda expression
{
    my($lambda, $args) = @_;
    
    # set local variables
    require Lisp::Localize;
    my $local = Lisp::Localize->new;
    my $localvar = $lambda->[1];

    my $do_opt;
    my $do_rest;
    my $i = 0;
    for my $sym (@$localvar) {
	if ($sym == $opt) {
	    $do_opt++;
	} elsif ($sym == $rest) {
	    $do_rest++;
	} elsif ($do_rest) {
	    $local->save_and_set($sym, [ @{$args}[$i .. @$args-1] ] );
	    last;
	} elsif ($i < @$args || $do_opt) {
	    $local->save_and_set($sym, $args->[$i]);
	    $i++;
	} else {
	    die "too-few-arguments";
	}
    }
    if (!$do_rest && @$args > $i) {
	die "too-many-arguments";
    }

    # execute the function body
    my $res = $nil;
    my $pc = 2;  # starting here (0=lambda, 1=local variables)
    while ($pc < @$lambda) {
	$res = lisp_eval($lambda->[$pc]);
	$pc++;
    }
    $res;
}


sub lisp_read_eval_print
{
    require Lisp::Reader;
    my $form = Lisp::Reader::lisp_read(join(" ", @_));
    unshift(@$form, symbol("progn")) if ref($form->[0]) eq "ARRAY";
    lisp_print(lisp_eval($form));
}

1;
