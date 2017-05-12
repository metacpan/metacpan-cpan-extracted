package lib::xi;
use 5.008_001;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.03';

use File::Spec ();
use Config ();

our $VERBOSE;

# modules which dosn't exist in CPAN
our %IGNORE = map { $_ => 1 } (
    'Encode/ConfigLocal.pm',
    'Devel/StackTraceFrame.pm',
    'Log/Agent.pm', # used in Storable.pm
);

sub new {
    my($class, %args) = @_;
    return bless \%args, $class;
}

sub run_perl {
    my(@args) = @_;

    my %std_inc = map  { $_ => 1 }
                  grep { defined($_) && length } @Config::Config{qw(
          sitelibexp   sitearchexp
        venderlibexp venderarchexp
          privlibexp    archlibexp
    )};
    my @non_std_inc = map { File::Spec->rel2abs($_) }
                      grep { defined($_) && not $std_inc{$_} } @INC;

    system($^X, (map { "-I$_" } @non_std_inc), @args);
}

sub cpanm_command {
    my($self) = @_;
    return('cpanm', @{ $self->{cpanm_opts} });
}

# must be fully-qualified; othewise implied main::INC.
sub lib::xi::INC {
    my($self, $file) = @_;

    return if $IGNORE{$file};

    my $module = $file;
    $module =~ s/\.pm \z//xms;
    $module =~ s{/}{::}xmsg;

    my @cmd = ($self->cpanm_command, $module);
    if($VERBOSE) {
        print STDERR "# PERL_CPANM_OPT: ", ($ENV{PERL_CPANM_OPT} || '') ,"\n";
        print STDERR "# COMMAND: @cmd\n";
    }
    if(run_perl('-S', @cmd) == 0) {
        foreach my $lib (grep {defined} @{ $self->{myinc} }) {
            if(open my $inh, '<', "$lib/$file") {
                $INC{$file} = "$lib/$file";
                return $inh;
            }
        }
    }

    # fall back to the default behavior (Can't locate Foo.pm ...)
    return;
}

sub import {
    my($class, @cpanm_opts) = @_;

    my $install_dir;

    if(@cpanm_opts && $cpanm_opts[0] !~ /^-/) {
        require File::Spec;
        my $base;
        if($0 ne '-e' && -e $0) {
            my($volume, $dir, undef) = File::Spec->splitpath($0);
            $base = File::Spec->catpath($volume, $dir, '');
        }
        $install_dir = File::Spec->rel2abs(shift(@cpanm_opts), $base);
    }

    my @myinc;

    if($install_dir) {
        @myinc = (
            "$install_dir/lib/perl5/$Config::Config{archname}",
            "$install_dir/lib/perl5",
        );
        unshift @INC, @myinc;

        unshift @cpanm_opts, '-l', $install_dir;
    }

    $VERBOSE = scalar grep { $_ eq '-v' } @cpanm_opts;

    push @INC, $class->new(
        install_dir => $install_dir,
        myinc       => $install_dir ? \@myinc : \@INC,
        cpanm_opts  => \@cpanm_opts,
    );
    return;
}

sub install_dir { $_[0]->{install_dir} } # for testing

1;
__END__

=head1 NAME

lib::xi - Installs missing modules on demand

=head1 VERSION

This document describes lib::xi version 1.03.

=head1 SYNOPSIS

    # to install missing libaries automatically
    $ perl -Mlib::xi script.pl

    # with cpanm options
    $ perl -Mlib::xi=-q script.pl

    # to install missing libaries to extlib/ (with cpanm -l extlib)
    $ perl -Mlib::xi=extlib script.pl

    # with cpanm options
    $ perl -Mlib::xi=extlib,-q script.pl

    # with cpanm options via env
    $ PERL_CPANM_OPT='-l extlib -q' perl -Mlib::xi script.pl

=head1 DESCRIPTION

When you execute a script found in, for example, C<gist>, you'll be annoyed
at missing libraries and will install those libraries by hand with a CPAN
client. We have repeated such a task, which violates the great virtue of
Laziness. Stop doing it, making computers do it!

C<lib::xi> is a pragma to install missing libraries automatically if and only
if they are required.

The mechanism, using C<< @INC hook >>, is that when the perl interpreter cannot
find a library required, this pragma try to install it with C<cpanm(1)> and
tell it to the interpreter.

=head1 INTERFACE

=head2 The import method

=head3 C<< use lib::xi ?$install_dir, ?@cpanm_opts >>

Setups the C<lib::xi> hook into C<@INC>.

If I<$install_dir> is specified, it is used as the install directory as
C<cpanm --local-lib $install_dir>, adding C<$install_dir/lib/perl5> to C<@INC>
Note that I<$install_dir> will be expanded to the absolute path based on
where the script is. That is, in the point of C<@INC>, C<< use lib::xi 'extlib' >> is almost the same as the following code:

    use FindBin;
    use lib "$FindBin::Bin/extlib/lib/perl5";

I<@cpanm_opts> are passed directly to C<cpanm(1)>. Note that if the first argument starts with C<->, it is regarded as C<@cpanm_opts>, so you can simply omit
the I<$install_dir> if it's not needed.

=head1 COMPARISON

There are similar modules to C<lib::xi>, namely C<CPAN::AutoINC> and
C<Module::AutoINC>, which use C<CPAN.pm> to install modules; the difference
is that C<lib::xi> supports C<local::lib> (via C<cpanm -l>) and has little
overhead.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<cpanm> (App::cpanminus)

L<perlfunc/require> for the C<@INC> hook specification details

L<CPAN::AutoINC>

L<Module::AutoINC>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
