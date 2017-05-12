package Throw;
use strict;
use warnings;
require 5.8.8;
use overload '""' => \&_str, fallback => 1;

=head1 NAME

Throw - Simple exceptions that do the right things in multiple contexts

=cut

our (@EXPORT, $trace, $level, $pretty, $js, $jp) = ('throw');
our $VERSION = '0.13'; #VERSION

sub import {
    no strict 'refs'; ## no critic
    my ($me, $you, $f, $l) = (shift, caller); @_ = @{"$me\::EXPORT"} if !@_;
    defined &{"$me\::$_"} ? *{"$you\::$_"} = \&{"$me\::$_"} : die "Cannot export $_ from $me to $you at $f line $l.\n" for @_;
}

sub throw {
    my $args = ref($_[0]) ? shift() : {%{$_[1]||{}}, error => $_[0]};
    $args->{'trace'} = caller_trace($trace || $args->{'trace'} || 1, $_[2]) if $trace || $args->{'trace'} || @_>2;
    die bless $args, __PACKAGE__;
}

sub new {
    my $class = shift;
    my $args = ref($_[0]) ? shift() : {%{$_[1]||{}}, error => $_[0]};
    $args->{'trace'} = caller_trace($trace || $args->{'trace'} || 1, $_[2]) if $trace || $args->{'trace'} || @_>2;
    return bless $args, $class;
}

sub croak   { my $a = {%{$_[1]||{}}, error => $_[0]};  $a->{'trace'} = caller_trace(1, ($_[2]||0)+1);  die bless $a, __PACKAGE__ }
sub carp    { my $a = {%{$_[1]||{}}, error => $_[0]};  $a->{'trace'} = caller_trace(1, ($_[2]||0)+1); warn bless $a, __PACKAGE__ }
sub confess { my $a = {%{$_[1]||{}}, error => $_[0]};  $a->{'trace'} = caller_trace(2, $_[2]);  die bless $a, __PACKAGE__ }
sub cluck   { my $a = {%{$_[1]||{}}, error => $_[0]};  $a->{'trace'} = caller_trace(2, $_[2]); warn bless $a, __PACKAGE__ }

sub _str {
    my $self = shift;
    my $err  = $self->{'error'} || "Something happened";
    my $p    = defined($pretty) ? $pretty : $self->{'_pretty'};
    local @$self{'error','_pretty'};  delete @$self{'error','_pretty'};
    return "$err\n" if !scalar keys %$self;
    require JSON;
    my $j = $p ? $jp ||= JSON->new->allow_unknown->allow_blessed->utf8->convert_blessed->canonical->pretty
               : $js ||= JSON->new->allow_unknown->allow_blessed->utf8->convert_blessed->canonical;
    return "$err: ".$j->encode({%$self}).($p ? '' : "\n");
}

sub caller_trace {
    my $args = ref($_[0]) ? $_[0] : (!$_[0] || $_[0] !~ /^[123]$/) ? return $_[0]: {verbose => $_[0], level => $_[1]};
    my $i = ($level || $_[1] || $args->{'level'} || 0) + 1;
    return sprintf "Called from %s at %s line %s", (caller $i+1)[3]||'main', map{(my$s=$_)=~s|^(?:.+/)?lib/||;$s} (caller $i)[1,2] if $args->{'verbose'} && $args->{'verbose'} eq '1';
    my ($m1, $m2, $m3, $nv, @trace) = (0, 0, 0, eval {require 5.014} ? ($args->{'verbose'} || '') ne '3' : 1);
    while (1) {
        my ($pkg, $file, $line, $sub, $sargs) = $nv ? ((caller $i++)[0..3], [])
            : do { package DB;  local $DB::args[0] = \$nv; ((caller $i++)[0..3], ($DB::args[0]||'') ne \$nv ? [@DB::args] : []) };
        last if ! $sargs;
        $sub =~ s/.*://; $file =~ s|^(?:.+/)?lib/||;
        next if ($file eq __FILE__) || $args->{'skip'}->{$file} || $args->{'skip'}->{$pkg} || $args->{'skip'}->{$sub};
        splice @$sargs, $args->{'max_args'}, -1, '...' if @$sargs > ($args->{'max_args'} ||= 5);
        my $args = (!@$sargs || $i==2 && $sub eq 'throw') ? ''
            : ' ('.join(', ',map{
                my$d=!defined($_)?'undef':ref($_)||!/\D/?$_:do{(my$c=$_)=~s|([\'/])|\\$1|g;"'$c'"};
                substr($d,0,$args->{'max_arg_len'}||20)
            } @$sargs).')';
        $m1 = length $sub  if length($sub)  > $m1;
        $m2 = length $file if length($file) > $m2;
        $m3 = length $line if length($line) > $m3;
        push @trace, [$sub, $file, $line, $args];
    }
    return join "\n", map {sprintf "%-${m1}s at %-${m2}s line %${m3}s%s", @$_} @trace;
}

sub TO_JSON { return {%{$_[0]}} }

sub classify {
    my ($err, $ref) = @_;
    $ref = {$ref => 1} if ! ref $ref;
    my $type = !ref($err) ? 'undef.flat' : defined($err->{'type'}) ? $err->{'type'} : 'undef.none';
    my @keys = grep {$_ ne 'default'} keys %$ref;
    @keys = sort {length($b) <=> length($a) || $a cmp $b} @keys if @keys > 1;
    foreach my $key (@keys) {
        next if $type !~ /^\Q$key\E\b(?:$|\.)/;
        my $val = $ref->{$key};
        return ref($val) ? $val->($err, $key) : $val;
    }
    return if ! exists $ref->{'default'};
    my $val = $ref->{'default'};
    return ref($val) ? $val->($err, 'default') : $val;
}

1;

__END__

=head1 SYNOPSIS

    use Throw qw(throw);

    throw "Hey";

    throw "Hey", {info => "This is why"};

    throw "Hey", {trace => 1}; # simple trace

    throw "Hey", {trace => 2}; # full trace without args

    throw "Hey", {trace => 3}; # full trace with args


    use Throw qw(croak confess carp);

    croak "Hey";  # same as throw with {trace => 1}, 1

    confess "Hey";  # same as throw with {trace => 2}

    carp "Hey";  # warns from perspective of caller

    warn Throw->new("Hey");  # useful for some cases


    use Throw qw(throw classify);
    if (classify my $err = $@, "io") {
        throw "Got a disk error", {msg => $err};
    }

=head1 DESCRIPTION

Throw allows for light weight exceptions that can hold more
information than just the error message.  These exceptions do the
right thing when thrown on the commandline, or when consumed by
javascript based APIs.

=head1 METHODS

=over 4

=item throw

Takes an error message, an error message and extra arguments, or a
hashref.

If a hashref is passed, it should contain a key named error
representing the error.  If not, a string "Something happened" will be
used instead.  If an arguments hashref is passed, the error message
will be added to it.  If just an error message is passed, a hashref
will be created with the error as the single key.

In all cases, throw returns an hashref based object blessed into the
Throw class.  When an error message is passed independently.

If a key of "trace" is passed, its value will be passed to the
caller_trace subroutine and the result will be stored as the value of
trace.

An optional 3rd parameter can be passed which will be used as the "level"
for any stack traces performed.

=item new

Similar to throw call.  Useful for some cases.

=item croak

Gives a trace from the perspective of the caller.
Similar to throw - but with trace => 1 instead.  (passing a single hashref is not allowed)
Single level stack trace.

=item confess

Similar to throw - but with trace => 2 instead.  (passing a single hashref is not allowed)
Full stack trace.

=item carp

Gives a trace from the perspective of the caller.
Similar to throw but only warns with trace => 1.

=item cluck

Similar to throw but only warns with trace => 2.

=item caller_trace

Returns stack traces.  Takes parameters in a few different ways.

     caller_trace();    # {level => 0, verbose => 2}
     caller_trace(1);   # {level => 0, verbose => 1}
     caller_trace(2);   # {level => 0, verbose => 2}
     caller_trace(3);   # {level => 0, verbose => 3}

     caller_trace(undef, 3);  # {level => 3, verbose => 1}
     caller_trace(1, 4);      # {level => 4, verbose => 1}
     caller_trace(2, 2);      # {level => 2, verbose => 2}

     caller_trace({level => 1});                # {level => 1, verbose => 2}
     caller_trace({level => 1, verbose => 3});  # {level => 1, verbose => 3}

The "level" argument represents how many stack frames to skip
backwards.

The "verbose" argument can be one of 1, 2, or 3.  Default 2.  At level
1 you get a single line of trace.  With level 2 you get the full stack
trace.  With level 3 you get the full stack trace with function
arguments.

The "max_args" argument shows how many parameters to each level will
be represented.  If there are more an "..." will be shown.  Default is
5.

The "max_arg_len" argument shows where parameters will be truncated.
Default is 20.

The "skip" argument can be a hashref with keys of packages, files, or
subs that should be excluded from the trace.

=item classify

Allows for cleanly and safely classifying the types of errors received
assuming you use {type => 'error_type'} for specifying your error
hierarchy.  Classify takes an error (such as from $@), and a hashref
used to classify the error.  Each of the keys of the hashref will be
checked against the type of the error.  The classification keys are
checked based on hierarchy - so a key of "foo" will match an error
type of "foo" as well as "foo.bar", "foo.baz", and "foo.bar.baz".  A
key of "foo.bar" would match "foo.bar" and "foo.bar.baz" but not
"foo".

You may also pass a key named "default" to handle any cases not
matched by other keys.

Some errors passed to classify may not have been given a type
property, and some may not even have been blessed or come from the
Throw system.  Any unblessed errors will receive use a type of
"undef.flat" and any other errors that do not have a type attribute
will use "undef.none" for the type.

    use Throw qw(throw classify);
    use Try::Tiny qw(try catch);

    try {
        throw "No-no", {type => 'foo.bar'};
    } catch {
        classify $_, {
            foo => sub { print "I got foo\n" },
            'foo.bar' => sub { print "I got foo.bar\n" },
            default   => sub { throw "Don't know what I got", {msg => $_[0]} }
        };
    }


    # also
    if (classify $@, "foo") {
        print "I got a foo\n";
    }

=back

=head1 GLOBALS

There are also a few package globals that can make tracking down culprits easier.

=over 4

=item $trace

Turn on traces globally - can be any of the normal values passed to trace

=item $level

Set the level at which to trace.

=item $pretty

Allow all json error stringification to use pretty.  You can also set _pretty => 1 in
individual errors, but sometimes you won't have access to the error object before
it stringifies.

=item TO_JSON

JSONifies the error.

=back

=head1 AUTHORS

Paul Seamons <rhandom@cpan.org>, Jason Terry <oaxlin@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, 2014, Bluehost.com.

This module is free software; you can redistribute it and/or modify it under the same terms as
Perl itself, either version 5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.

The full text of the license can be found in the LICENSE file included with this module.
