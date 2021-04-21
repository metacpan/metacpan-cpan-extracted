package Test::Vars;
use 5.010_000;
use strict;
use warnings;

our $VERSION = '0.015';

our @EXPORT = qw(all_vars_ok test_vars vars_ok);

use parent qw(Test::Builder::Module);

use B ();
use ExtUtils::Manifest qw(maniread);
use IO::Pipe;
use List::Util 1.33 qw(all);
use Storable qw(freeze thaw);
use Symbol qw(qualify_to_ref);

use constant _VERBOSE       => ($ENV{TEST_VERBOSE} || 0);
use constant _OPpLVAL_INTRO => 128;

#use Devel::Peek;
#use Data::Dumper;
#$Data::Dumper::Indent = 1;

sub all_vars_ok {
    my(%args) = @_;

    my $builder = __PACKAGE__->builder;

    if(not -f $ExtUtils::Manifest::MANIFEST){
        $builder->plan(skip_all => "No $ExtUtils::Manifest::MANIFEST ready");
    }
    my $manifest = maniread();
    my @libs    = grep{ m{\A lib/ .* [.]pm \z}xms } keys %{$manifest};

    if (! @libs) {
        $builder->plan(skip_all => "not lib/");
    }

    $builder->plan(tests => scalar @libs);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $fail = 0;
    foreach my $lib(@libs){
        _vars_ok(\&_results_as_tests, $lib, \%args) or $fail++;
    }

    return $fail == 0;
}

sub _results_as_tests {
    my($file, $exit_code, $results) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $builder = __PACKAGE__->builder;
    my $is_ok = $builder->ok($exit_code == 0, $file);

    for my $result (@$results) {
        my ($method, $message) = @$result;
        $builder->$method($message);
    }

    return $is_ok;
}

sub test_vars {
    my($lib, $result_handler, %args) = @_;
    return _vars_ok($result_handler, $lib, \%args);
}

sub vars_ok {
    my($lib, %args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return _vars_ok(\&_results_as_tests, $lib, \%args);
}

sub _vars_ok {
    my($result_handler, $file, $args) = @_;

    # Perl sometimes produces Unix style paths even on Windows, which can lead
    # to us producing error messages with a path like "lib\foo/bar.pm", which
    # is really confusing. It's simpler to just use Unix style everywhere
    # internally.
    $file =~ s{\\}{/}g;

    my $pipe = IO::Pipe->new;
    my $pid = fork();
    if(defined $pid){
        if($pid != 0) { # self
            $pipe->reader;
            my $results = thaw(join('', <$pipe>));
            waitpid $pid, 0;

            return $result_handler->($file, $?, $results);
        }
        else { # child
            $pipe->writer;
            exit !_check_vars($file, $args, $pipe);
        }
    }
    else {
        die "fork failed: $!";
    }
}

sub _check_vars {
    my($file, $args, $pipe) = @_;

    my @results;

    my $package = $file;

    # Looks like a file name. Turn it into a package name.
    if($file =~ /\./){
        $package =~ s{\A .* \b lib/ }{}xms;
        $package =~ s{[.]pm \z}{}xms;
        $package =~ s{/}{::}g;
    }

    # Looks like a package name. Make a file name from it.
    else{
        $file .= '.pm';
        $file =~ s{::}{/}g;
    }

    if(ref $args->{ignore_vars} eq 'ARRAY'){
        $args->{ignore_vars} = { map{ $_ => 1 } @{$args->{ignore_vars}} };
    }

    if(not exists $args->{ignore_vars}{'$self'}){
        $args->{ignore_vars}{'$self'}++;
    }

    # ensure library loaded
    {
        local $SIG{__WARN__} = sub{ }; # ignore warnings

        # set PERLDB flags; see also perlvar
        local $^P = $^P | 0x200; # NAMEANON

        local @INC = @INC;
        if($file =~ s{\A (.*\b lib)/}{}xms){
            unshift @INC, $1;
        }
        eval { require $file };

        if($@){
            $@ =~ s/\n .*//xms;
            push @results, [diag => "Test::Vars ignores $file because: $@"];
            _pipe_results($pipe, @results);
            return 1;
        }
    }

    push @results, [note => "checking $package in $file ..."];
    my $check_result = _check_into_stash(
        *{qualify_to_ref('', $package)}{HASH}, $file, $args, \@results);

    _pipe_results($pipe, @results);
    return $check_result;
}

sub _check_into_stash {
    my($stash, $file, $args, $results) = @_;
    my $fail = 0;

    foreach my $key(sort keys %{$stash}){
        my $ref = \$stash->{$key};

        if (ref ${$ref} eq 'CODE') {
            # Reify the glob and let perl figure out what to put in
            # GvFILE. This is needed for the optimization added in 5.27.6 that
            # stores coderefs directly in the stash instead of in a typeglob
            # in the stash.
            no strict 'refs';
            () = *{B::svref_2object($stash)->NAME . "::$key"};
        }

        next if ref($ref) ne 'GLOB';

        my $gv = B::svref_2object($ref);

        my $hashref = *{$ref}{HASH};
        my $coderef = *{$ref}{CODE};

        if(($hashref || $coderef) && $gv->FILE =~ /\Q$file\E\z/xms){
            if($hashref && B::svref_2object($hashref)->NAME){ # stash
                if(not _check_into_stash(
                    $hashref, $file, $args, $results)){
                        $fail++;
                }
            }
            elsif($coderef){
                if(not _check_into_code($coderef, $args, $results)){
                    $fail++;
                }
            }
        }
    }

    return $fail == 0;
}

sub _check_into_code {
    my($coderef, $args, $results) = @_;

    my $cv = B::svref_2object($coderef);

    # If ROOT is null then the sub is a stub, and has no body for us to check.
    if($cv->XSUB || $cv->ROOT->isa('B::NULL')){
        return 1;
    }

    my %info;
    _count_padvars($cv, \%info, $results);

    my $fail = 0;

    foreach my $cv_info(map { $info{$_} } sort keys %info){
        my $pad = $cv_info->{pad};

        push @$results, [note => "looking into $cv_info->{name}"] if _VERBOSE > 1;

        foreach my $p(@{$pad}){
            next if !( defined $p && !$p->{outside} );

            if(! $p->{count}){
                next if $args->{ignore_vars}{$p->{name}};

                if(my $cb = $args->{ignore_if}){
                    local $_ = $p->{name};
                    next if $cb->($_);
                }

                my $c = $p->{context} || '';
                push @$results, [diag => "$p->{name} is used once in $cv_info->{name} $c"];
                $fail++;
            }
            elsif(_VERBOSE > 1){
                push @$results, [note => "$p->{name} is used $p->{count} times"];
            }
        }
    }

    return $fail == 0;

}

sub _pipe_results {
    my ($pipe, @messages) = @_;
    print $pipe freeze(\@messages);
    close $pipe;
}

my @padops;
my $op_anoncode;
my $op_enteriter;
my $op_entereval; # string eval
my $op_null;
my @op_svusers;
BEGIN{
    foreach my $op(qw(padsv padav padhv padcv match multideref subst)){
        $padops[B::opnumber($op)]++;
    }
    # blead commit 93bad3fd55489cbd split aelemfast into two ops.
    # Prior to that, 'aelemfast' handled lexicals too.
    my $aelemfast = B::opnumber('aelemfast_lex');
    $padops[$aelemfast == -1 ? B::opnumber('aelemfast') : $aelemfast]++;

    $op_anoncode = B::opnumber('anoncode');
    $padops[$op_anoncode]++;

    $op_enteriter = B::opnumber('enteriter');
    $padops[$op_enteriter]++;

    $op_entereval = B::opnumber('entereval');
    $padops[$op_entereval]++;

    $op_null = B::opnumber('null');

    foreach my $op(qw(srefgen refgen sassign aassign)){
        $op_svusers[B::opnumber($op)]++;
    }
}

sub _count_padvars {
    my($cv, $global_info, $results) = @_;

    my %info;

    my $padlist  = $cv->PADLIST;

    my $padvars  = $padlist->ARRAYelt(1);

    my @pad;
    my $ix = 0;
    foreach my $padname($padlist->ARRAYelt(0)->ARRAY){
        if($padname->can('PVX')){
            my $pv = $padname->PVX;

            # Under Perl 5.22.0+, $pv can end up as undef in some cases. With
            # a threaded Perl, instead of undef we see an empty string.
            #
            # $pv can also end up as just '$' or '&'.
            if(defined $pv && length $pv && $pv ne '&' && $pv ne '$' && !($padname->FLAGS & B::SVpad_OUR)){
                my %p;

                $p{name}    = $pv;
                $p{outside} = $padname->FLAGS & B::SVf_FAKE ? 1 : 0;
                if($p{outside}){
                    $p{outside_padix} = $padname->PARENT_PAD_INDEX;
                }
                $p{padix} = $ix;

                $pad[$ix] = \%p;
            }
        }
        $ix++;
    }

    my ( $cop_scan, $op_scan ) = _make_scan_subs(\@pad, $cv, $padvars, $global_info, $results, \%info);
    local *B::COP::_scan_unused_vars;
    *B::COP::_scan_unused_vars = $cop_scan;

    local *B::OP::_scan_unused_vars;
    *B::OP::_scan_unused_vars = $op_scan;

    my $name = sprintf('&%s::%s', $cv->GV->STASH->NAME, $cv->GV->NAME);

    my $root = $cv->ROOT;
    if(${$root}){
        B::walkoptree($root, '_scan_unused_vars');
    }
    else{
        push @$results, [note => "NULL body subroutine $name found"];
    }

    %info = (
        pad  => \@pad,
        name => $name,
    );

    return $global_info->{ ${$cv} } = \%info;
}

sub _make_scan_subs {
    my ($pad, $cv, $padvars, $global_info, $results, $info) = @_;

    my $cop;
    my $cop_scan = sub {
        ($cop) = @_;
    };

    my $stringy_eval_seen = 0;
    my $op_scan = sub {
        my($op) = @_;

        return if $stringy_eval_seen;

        my $optype = $op->type;
        return if !defined $padops[ $optype ];
        # stringy eval could refer all the my variables
        if($optype == $op_entereval){
            foreach my $p(@$pad){
                $p->{count}++;
            }
            $stringy_eval_seen = 1;
            return;
        }

        # In Perl 5.22+, pad variables can be referred to in ops like
        # MULTIDEREF, which show up as a B::UNOP_AUX object. This object can
        # refer to multiple pad variables.
        if($op->isa('B::UNOP_AUX')) {
            foreach my $i(grep {!ref}$ op->aux_list($cv)) {
                # There is a bug in 5.24 with multideref aux_list where it can
                # contain a value which is completely broken. It numifies to
                # undef when used as an array index but "defined $i" will be
                # true! We can detect it by comparing its stringified value to
                # an empty string. This has been fixed in blead.
                next unless do {
                    no warnings;
                    "$i" ne q{};
                };
                $pad->[$i]{count}++
                    if $pad->[$i];
            }
            return;
        }

        my $targ = $op->targ;
        return if $targ == 0; # maybe foreach (...)

        my $p = $pad->[$targ];
        $p->{count} ||= 0;

        if($optype == $op_anoncode){
            my $anon_cv = $padvars->ARRAYelt($targ);
            if($anon_cv->CvFLAGS & B::CVf_CLONE){
                my $my_info = _count_padvars($anon_cv, $global_info, $results);

                $my_info->{outside} = $info;

                foreach my $p(@{$my_info->{pad}}){
                    if(defined $p && $p->{outside_padix}){
                        $pad->[ $p->{outside_padix} ]{count}++;
                    }
                }
            }
            return;
        }
        elsif($optype == $op_enteriter or ($op->flags & B::OPf_WANT) == B::OPf_WANT_VOID){
            # if $op is in void context, it is considered "not used"
            if(_ckwarn_once($cop)){
                $p->{context} = sprintf 'at %s line %d', $cop->file, $cop->line;
                return; # skip
            }
        }
        elsif($op->private & _OPpLVAL_INTRO){
            # my($var) = @_;
            #    ^^^^     padsv/non-void context
            #          ^  sassign/void context
            #
            # We gather all of the sibling ops that are not NULL. If all of
            # them are SV-using OPs (see the BEGIN block earlier) _and_ all of
            # them are in VOID context, then the variable from the first op is
            # being used once.
            my @ops;
            for(my $o = $op->next; ${$o} && ref($o) ne 'B::COP'; $o = $o->next){
                push @ops, $o
                    unless $o->type == $op_null;
            }

            if (all {$op_svusers[$_->type] && ($_->flags & B::OPf_WANT) == B::OPf_WANT_VOID} @ops){
                if(_ckwarn_once($cop)){
                    $p->{context} = sprintf 'at %s line %d',
                        $cop->file, $cop->line;
                    return; # unused, but ok
                }
            }
        }

        $p->{count}++;
    };

    return ($cop_scan, $op_scan);
}

sub _ckwarn_once {
    my($cop) = @_;

    my $w = $cop->warnings;
    if(ref($w) eq 'B::SPECIAL'){
        return $B::specialsv_name[ ${$w} ] !~ /WARN_NONE/;
    }
    else {
        my $bits = ${$w->object_2svref};
        # see warnings::__chk() and warnings::enabled()
        return vec($bits, $warnings::Offsets{once}, 1);
    }
}

1;
__END__

=head1 NAME

Test::Vars - Detects unused variables in perl modules

=head1 VERSION

This document describes Test::Vars version 0.015.

=head1 SYNOPSIS

    use Test::Vars;

    # Check all libs that are listed in the MANIFEST file
    all_vars_ok();

    # Check an arbitrary file
    vars_ok('t/lib/MyLib.pm');

    # Ignore some variables while checking
    vars_ok 't/lib/MyLib2.pm', ignore_vars => [ '$an_unused_var' ];

=head1 DESCRIPTION

Test::Vars provides test functions to report unused variables either in an entire distribution or in some files of your choice in order to keep your source code tidy.

=head1 INTERFACE

=head2 Exported

=head3 all_vars_ok(%args)

Tests libraries in your distribution with I<%args>.

I<libraries> are collected from the F<MANIFEST> file.

If you want to ignore variables, for example C<$foo>, you can
tell it to the test routines:

=over 4

=item C<< ignore_vars => { '$foo' => 1 } >>

=item C<< ignore_vars => [qw($foo)] >>

=item C<< ignore_if => sub{ $_ eq '$foo' } >>

=back

Note that C<$self> will be ignored by default unless you pass
explicitly C<< { '$self' => 0 } >> to C<ignore_vars>.

=head3 vars_ok($lib, %args)

Tests I<$lib> with I<%args>.

See C<all_vars_ok>.

=head2 test_vars($lib, $result_handler, %args)

This subroutine tests variables, but instead of outputting TAP, calls the
C<$result_handler> subroutine reference provided with the results of the test.

The C<$result_handler> sub will be called once, with the following arguments:

=over 4

=item * $filename

The file that was checked for unused variables.

=item * $exit_code

The value of C<$?> from the child process that actually did the tests. This
will be 0 if the tests passed.

=item * $results

This is an array reference which in turn contains zero or more array
references. Each of those references contains two elements, a L<Test::Builder>
method, either C<diag> or C<note>, and a message.

If the method is C<diag>, the message contains an actual error. If the method
is C<notes>, the message contains extra information about the test, but is not
indicative of an error.

=back

=head1 MECHANISM

C<Test::Vars> is similar to a part of C<Test::Perl::Critic>, but the mechanism
is different.

While C<Perl::Critic>, the backend of C<Test::Perl::Critic>, scans the source
code as text, this modules scans the compiled opcodes (or AST: abstract syntax
tree) using the C<B> module. See also C<B> and its submodules.

=head1 CONFIGURATION

C<TEST_VERBOSE = 1 | 2 > shows the way this module works.

=head1 CAVEATS

https://rt.cpan.org/Ticket/Display.html?id=60018

https://rt.cpan.org/Ticket/Display.html?id=82411

=head1 DEPENDENCIES

Perl 5.10.0 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Perl::Critic>

L<warnings::unused>

L<B>

L<Test::Builder::Module>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
