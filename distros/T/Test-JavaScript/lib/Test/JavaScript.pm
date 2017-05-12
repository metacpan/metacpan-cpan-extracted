package Test::JavaScript;

=head1 NAME

Test::JavaScript - JavaScript Testing Module

=head1 SYNOPSIS

    use Test::JavaScript qw(no_plan);

    js_eval_ok("/path/to/MyFile.js");

    js_ok("var obj = new MyFile", "Create a MyFile object");

    js_ok("obj.someFunction = function () { return 'ok' }");

    js_is("obj.someFunction()", "ok");

=head1 DESCRIPTION

Test::JavaScript provides a method of unit testing javascript code from within
perl. This module uses the JavaScript::SpiderMonkey package to evaluate
JavaScript using the SpiderMonkey JavaScript engine.

=cut

use strict 'vars';
use warnings;

use Exporter;
use Carp qw(croak);

use Test::Builder;
our $Test = Test::Builder->new;

use JavaScript::SpiderMonkey;
our $js = JavaScript::SpiderMonkey->new();
$js->init();
END { $js->destroy };

our $VERSION = 0.06;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(js_ok js_eval_ok js_is js_isnt js_diag);

sub no_ending { $Test->no_ending(@_) }
sub plan { $Test->plan(@_) }

sub import {
    my $self = shift;
    my $caller = caller;

    for my $f (@EXPORT) {
	*{$caller.'::'.$f} = \&$f;
    }

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub try_eval {
    my ($code, $name) = @_;
    my $rc = $js->eval($code);
    unless ($rc) {
	my $ok = $Test->ok( !$@, $name );
        $Test->diag(<<DIAGNOSTIC);
    $@
DIAGNOSTIC
	$@ = '';
    }
}

sub escape_args {
    my $name = pop @_;
    my @args = @_;
    $args[0] = $name and $name = '' unless @args;
    s/'/\\'/g foreach @args;
    (my $escaped = $name) =~ s/'/\\'/g;
    return (@args,$escaped,$name);
}

=item B<js_eval_ok>

  js_eval_ok($filename)

This reads a file and evals it in JavaScript

For example:

    js_eval_ok( "/path/to/some/file.js" );

=cut

sub js_eval_ok ($;@) {
    my $filename = shift || croak "filename required";
    croak "$filename doesn't exist" unless $filename;

    open my $fh, $filename or die "Couldn't read $filename: $!";
    my @lines = <$fh>;
    close $fh or die "Couldn't read $filename: $!";

    my $rc = $js->eval(join("\n", @lines));
    my $ok = $Test->ok( !$@, "use $filename;" );

    unless( $rc ) {
        $Test->diag(<<DIAGNOSTIC);
    Tried to use '$filename'.
    $@
DIAGNOSTIC
    }
}

=item B<js_is>

=item B<js_isnt>

  js_is  ( $this, $that, $test_name );
  js_isnt( $this, $that, $test_name );

This compares two values in JavaScript land. They can be literal strings
passed from perl or variables defined earlier.

For example:

    js_ok("var i = 3");					// ok
    js_is("i", 3, "i is 3");				// ok
    js_is("3", 3, "3 is 3");				// ok
    js_is("3", 2, "3 is 2");				// not ok

    js_ok("function three () { return 3 }");		// ok
    js_is("three()", 3);				// ok
    js_is("three()", 4);				// not ok

    js_isnt("3", 4, "3 is not 4");			// ok

=cut

$js->function_set("is", sub { $Test->is_eq(@_) });

sub js_is {
    my ($test,$actual,$ename,$name) = escape_args(@_);
    my $code = <<EOT;
is( $test, '$actual', '$ename'.replace(/\\'/,"'"));
EOT
    try_eval($code, $name);
}

$js->function_set("isnt", sub { $Test->isnt_eq(@_) });

sub js_isnt {
    my ($test,$actual,$ename,$name) = escape_args(@_);
    my $code = <<EOT;
isnt( $test, '$actual', '$ename'.replace(/\\'/,"'"));
EOT
    try_eval($code, $name);
}

=item B<js_ok>

  js_ok("var monkey = 3", $test_name);

The expression passed as the first parameter is evaluated as either true or
false. The test fails if the expression explicitly returns false, or if a
syntax error occurs in JavaScript land

For example:

    js_ok("var i = 3");					    // ok
    js_ok("true", "true is true");			    // ok
    js_ok("1 == 2", "1 is equal to 2");			    // not ok
    js_ok("false", "false is false");			    // not ok
    js_ok("var array = ['one','two',non_existing_var];")    // not ok

=cut

$js->function_set("ok", sub { $Test->ok(@_) });
sub js_ok {
    my ($test,$ename,$name) = escape_args(@_);
    my $lines = join"\n", map { "code.push('$_');" } split("\n", $test);
    my $code = <<EOT;
var code = new Array;
$lines
var result = eval(code.join("\\n")) ? true : false;
ok( result, '$ename'.replace(/\\'/,"'"));
EOT

    try_eval($code, $name);
}

=item B<diag>

  js_ok("var myval = 3; diag('the variable myval is ' + myval)");

This subroutine simply logs the parameters passed as a comment

=cut

$js->function_set("diag", sub { $Test->diag(@_) });

=head1 AUTHORS

Kevin Jones, C<< <kevinj at cpan.org> >>

=head1 COPYRIGHT

Copyright 2006 Kevin Jones, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

return 1;
