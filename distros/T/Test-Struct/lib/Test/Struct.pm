package Test::Struct;
use strict;
use warnings;
require overload;
require Exporter;
use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION);
use Scalar::Util qw(refaddr reftype blessed isweak readonly tainted);
use List::Util qw(max min);
use Data::Dumper;
use Test::Builder;
use Test::More;

my $Test = Test::Builder->new;
@ISA = qw(Exporter);
@EXPORT_OK = ('deep_eq');
@EXPORT = ('deep_eq');

$VERSION = '0.01';

BEGIN {
    # no-op regex if we can't find DDS
    eval "sub regex { return }"
        unless eval "use Data::Dump::Streamer qw(regex); 1"
}

sub import {
    my($self) = shift;
    my $pack = caller;

    my (@plan,@import);
    my $i=0;
    while ($i<@_) {
        my $arg=$_[$i++];
        if ($arg=~/^(no_plan|skip_all)$/) {
            push @plan,$arg;
        } elsif($arg eq 'tests') {
            push @plan,$arg,$_[$i++];
        } elsif($arg eq 'import') {
            push @import,@{$_[$i++]};
        } else {
            push @import,$arg;
        }
    }
    $Test->exported_to($pack);
    $Test->plan(@plan);
    $self->export_to_level(1, $self,@import);
}

# private utility subs
sub _qquote {
    return defined $_[0] ? Data::Dumper::qquote($_[0]) : 'undef';
}

sub _safe {
    return defined $_[0] ? $_[0] : 'undef';
}

sub _msg {
    my $msg=shift;
    my $noqquote;
    if (@_>2) { $noqquote=pop; }
    return "$msg: ".
            join " ne ",
            map { $noqquote ? _safe($_)
                            : _qquote($_) } @_
}
sub _a { my $str=shift; $str=~s/\$o/\$got/g; $str }
sub _b { my $str=shift; $str=~s/\$o/\$expected/g; $str }

sub _subscr {
    my ($v,$script)=@_;
    if ($v=~/^\$\{.*\}$/ or $v=~/\w$/) {
        $v.="->".$script;
    } else {
        $v.=$script
    }
    return $v
 }



sub _bool_ne {
    my ($t1,$t2,$name,$n,$error)=@_;
    my $nok = !$t1 != !$t2;
    if ($nok) {
        push @$error,"at "._a($n)
               .($t1 ? ' not expecting ' : ' expecting ')
               ."$name.";
    }
    return $nok;
}

sub _ne {
    my ($t1,$t2,$name,$n,$error)=@_;
    my $nok = $t1 ne $t2;
    if ($nok) {
        push @$error,"at "._a($n)
                    ." expecting $name "._qquote($t2)
                    ." but got "._qquote($t1).".";
    }
    return $nok;
}


# main worker sub
sub deep_ne_list {
    my ($o1,$o2,$n,$state)=@_;
    $state||={};
    $n||='$o';

    my @error;

    # make sure they are both defined
    _bool_ne(defined($o1),defined($o2),"defined value",$n,\@error)
        and return @error;

    return if !defined($o1); # return if they are undef

    my $ra1=refaddr \$_[0];
    my $ra2=refaddr \$_[1];

    return if $state->{sv_seen1}{$ra1} &&
              $state->{sv_seen2}{$ra2} &&
              $state->{sv_seen1}{$ra1} eq
              $state->{sv_seen2}{$ra2};

    my $t1=($state->{sv_seen1}{$ra1}||=$n);
    my $t2=($state->{sv_seen2}{$ra2}||=$n);


    if ($t1 ne $t2) {
        if ($t1 eq $n) {
            return "expected to have seen "._a($n)
                  ." before at "._a($t2).".";
        } elsif ($t2 eq $n) {
            return "not expected to have seen "._a($n)
                  ." before at "._a($t1).".";
        } else {
            return "expected to have seen "._a($n)
                  ." before at ".a_($t2)
                  ." but saw it in "._a($t1)
                  ." instead.";
        }
     }


    _bool_ne(readonly($_[0]),readonly($_[1]),"a readonly value",$n,\@error);
    _bool_ne(tainted($_[0]),tainted($_[1]),"a tainted value",$n,\@error);
    _bool_ne(!!ref($o1),!!ref($o2),"value isa reference",$n,\@error)
        and return @error;


    if (!ref($o1)) {
        _ne($o1,$o2,"value of",$n,\@error);
        return @error;
    }

    #################################################################
    # We are dealing with a ref.
    $ra1=refaddr($o1);
    $ra2=refaddr($o2);
    return if $state->{rv_seen1}{$ra1} &&
              $state->{rv_seen2}{$ra2} &&
              $state->{rv_seen1}{$ra1} eq
              $state->{rv_seen2}{$ra2};

    $t1=($state->{rv_seen1}{$ra1}||=$n);
    $t2=($state->{rv_seen2}{$ra2}||=$n);

    if ($t1 ne $t2) {
        if ($t1 eq $n) {
            return "expected to have seen reference in "._a($n)
                  ." before at "._a($t2).".";
        } elsif ($t2 eq $n) {
            return "not expected to have seen reference in "._a($n)
                  ." before at "._a($t1).".";
        } else {
            return "expected to have seen reference in "._a($n)
                  ." before at ".a_($t2)." but saw it in "._a($t1)
                  ." instead."
        }
    }


    $t1=blessed($o1);
    $t2=blessed($o2);

    _bool_ne(defined($t1),defined($t2),"a blessed ref",$n,\@error);
    _ne($t1,$t2," object of class ",$n,\@error)
        if defined $t1;
    _bool_ne(isweak($_[0]),isweak($_[1]),"weak ref",$n,\@error);

    my $rt=reftype($o1);
    $t2=reftype($o2);

    # Can't procede further if they are different reftypes
    # No point in comparing arrays to hashes.
    _ne($rt,$t2,"reftype",$n,\@error)
        and return @error;


    if ($rt eq 'ARRAY') {
        my $min=min(0+@$o1,0+@$o2);
        _ne(0+@$o1,0+@$o2,"element count of","\@{".$n."}",\@error);
        for my $idx (0..$min-1) {
            push @error, deep_ne_list($o1->[$idx],$o2->[$idx],
                          $n."->[$idx]",$state);
        }
    } elsif ($rt eq 'HASH') {
        # Its a hash. get a list of all the keys in both
        # hashes, and then cycle through them checking
        # for equivelence.
        my %dupe;
        my @all=grep !$dupe{$_}++,keys %$o1,keys %$o2;
        foreach my $key (@all) {

            _bool_ne(exists($o1->{$key}),exists($o2->{$key}),
                     "key "._qquote($key),"%{".$n."}",\@error)
                and next;
            push @error,deep_ne_list($o1->{$key},$o2->{$key},
                          _subscr($n,"{"._qquote($key)."}"),$state);
        }
    } elsif ($rt eq 'REF' or $rt eq 'SCALAR') {
        $t1=regex($_[0]);
        $t2=regex($_[1]);
        _bool_ne($t1,$t2,"regex",$n,\@error);
        if($t1 && $t2) {
            _ne($t1,$t2,"pattern",$n,\@error);
        } else {
            push @error, deep_ne_list($$o1,$$o2,"\${".$n."}",$state);
        }
    } else {
        die "Whoah nelly! This is just a prototype. Can't handle reftype '$rt'";
    }
    return @error;
}

sub deep_eq($$;$) {
    my $name;
    # strip off the name if there is one
    $name = pop @_ if @_==3;
    my @errors=deep_ne_list(@_);
    local $Test::Builder::Level=2;
    ok(!@errors,$name);
    diag(join "\n",@errors) if @errors;
    return !@errors;
}


1;
__END__

=head1 NAME

Test::Struct - Perl extension for testing for structural equivelence.

=head1 SYNOPSIS

  use Test::Struct;

  deep_eq($hairy_struct,$expected,'Hairy structural test');
  is($x,$y); # and everything else Test::More has to offer!

=head1 DESCRIPTION

Test::Struct is used for doing deep structural comparisons of two
objects. The module contains only one subrotuine which is intended
to be used as a mix-in with other more generic Test::Builder derived
modules like Test::More or Test::Simple. The code normally uses
Scalar::Util for inspecting the data, but it will also use additional
fine tuned comparison tools from Data::Dump::Streamer if they are
available.

=over 4

=item deep_eq($got,$expected,$name)

Does a deep level comparison of two objects. It traverses the two
structures in parallel checking as many attributes as it can for
differences. If the objects differ it will output a diagnostic
message containing a list of the differences it encountered before
it finished the comparison. Some types of mismatch prevent further
comparison so the list may not be exhaustive.

The intention of this routine is that it will pass the test only
if $got is functionally identical to $expected. However, at current
time there are some data types it does not handle properly, such as
CODE refs.

=back

=head2 EXPORT

Only deep_eq().

=head1 SEE ALSO

Test::More, Test::Builder

=head1 AUTHOR

Yves Orton, Demerphq at the Google email service.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Yves Orton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
