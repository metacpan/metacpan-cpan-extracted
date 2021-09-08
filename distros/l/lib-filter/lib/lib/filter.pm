package lib::filter;

#use 5.008009;  # the first version where Module::CoreList becomes core
use strict 'subs', 'vars'; # no need to avoid strict & warnings, because Config uses them
use warnings;
use Config;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-29'; # DATE
our $DIST = 'lib-filter'; # DIST
our $VERSION = '0.281'; # VERSION

# BEGIN snippet from Module::Path::More, with mods/simplification
my $SEPARATOR;
BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}
sub module_path {
    my ($file, $inc) = @_;

    foreach my $dir (@$inc) {
        next if !defined($dir);
        next if ref($dir);
        my $path = $dir . $SEPARATOR . $file;
        return $path if -f $path;
    }
    undef;
}
# END snippet from Module::Path::More

sub _open_handle {
    my $path = shift;
    open my($fh), "<", $path
        or die "Can't open $path: $!";
    $fh;
}

my $handler;
my $hook;
my ($orig_inc, $orig_inc_sorted_by_len);

sub lib::filter::INC { goto $handler }

sub import {
    my ($class, %opts) = @_;

    my $dbgh = "[lib::filter]";

    for (keys %opts) {
        die "Unknown option $_"
            unless /\A(
                        debug|
                        allow_core|allow_noncore|
                        extra_inc|
                        allow|allow_list|allow_re|
                        allow_is_recursive|
                        disallow|disallow_list|disallow_re|
                        filter
                    )\z/x;
    }

    $opts{debug} = $ENV{PERL_LIB_FILTER_DEBUG} unless defined($opts{debug});

    $opts{allow_core}    = 1 if !defined($opts{allow_core});
    $opts{allow_noncore} = 1 if !defined($opts{allow_noncore});

    if ($opts{filter} && !ref($opts{filter})) {
        # convenience, for when filter is specified from command-line (-M)
        $opts{filter} = eval $opts{filter}; ## no critic: BuiltinFunctions::ProhibitStringyEval
        die "Error in filter code: $@" if $@;
    }

    if ($opts{extra_inc}) {
        unshift @INC, split(/:/, $opts{extra_inc});
    }

    if (!$orig_inc) {
        $orig_inc = [@INC];
        $orig_inc_sorted_by_len = [sort {length($b) <=> length($a)} @INC];
    }

    my $core_inc = [@Config{qw(privlibexp archlibexp)}];
    my $noncore_inc = [grep {$_ ne $Config{privlibexp} &&
                                 $_ ne $Config{archlibexp}} @$orig_inc];
    my %allow;
    if ($opts{allow}) {
        for (split /\s*;\s*/, $opts{allow}) {
            $allow{$_} = "allow";
        }
    }
    if ($opts{allow_list}) {
        open my($fh), "<", $opts{allow_list}
            or die "Can't open allow_list file '$opts{allow_list}': $!";
        while (my $line = <$fh>) {
            $line =~ s/^\s+//;
            $line =~ /^(\w+(?:::\w+)*)/ or next;
            $allow{$1} ||= "allow_list";
        }
    }

    my %disallow;
    if ($opts{disallow}) {
        for (split /\s*;\s*/, $opts{disallow}) {
            $disallow{$_} = "disallow";
            (my $pm = "$_.pm") =~ s!::!/!g; delete $INC{$pm};
        }
    }
    if ($opts{disallow_list}) {
        open my($fh), "<", $opts{disallow_list}
            or die "Can't open disallow_list file '$opts{disallow_list}': $!";
        while (my $line = <$fh>) {
            $line =~ s/^\s+//;
            $line =~ /^(\w+(?:::\w+)*)/ or next;
            $disallow{$1} ||= "disallow_list";
            (my $pm = "$1.pm") =~ s!::!/!g; delete $INC{$pm};
        }
    }

    $handler = sub {
        my ($self, $file) = @_;

        my @caller = caller(0);

        warn "$dbgh hook called for $file (from package $caller[0] file $caller[1])\n" if $opts{debug};

        my $path;
      FILTER:
        {
            my $mod = $file; $mod =~ s/\.pm$//; $mod =~ s!/!::!g;
            my $err_prefix = "Can't locate $file";
            if ($opts{filter}) {
                local $_ = $mod;
                warn "$dbgh Checking against custom filter ...\n" if $opts{debug};
                unless ($opts{filter}->($mod)) {
                    die "$err_prefix (module '$mod' is disallowed (filter))";
                }
            }
            if ($opts{disallow_re} && $mod =~ /$opts{disallow_re}/) {
                die "$err_prefix (module '$mod' is disallowed (disallow_re))";
            }
            if ($disallow{$mod}) {
                die "$err_prefix (module '$mod' is disallowed ($disallow{$mod}))";
            }
            if ($opts{allow_re} && $mod =~ /$opts{allow_re}/) {
                warn "$dbgh module $mod matches allow_re\n" if $opts{debug};
                $path = module_path($file, $orig_inc);
                last FILTER if $path;
                die "$err_prefix (module '$mod' is allowed (allow_re) but can't locate $file in \@INC (\@INC contains: ".join(" ", @INC)."))";
            }
            if ($allow{$mod}) {
                warn "$dbgh module $mod matches $allow{$mod}\n" if $opts{debug};
                $path = module_path($file, $orig_inc);
                last FILTER if $path;
                die "$err_prefix (module '$mod' is allowed ($allow{$mod}) but can't locate $file in \@INC (\@INC contains: ".join(" ", @INC)."))";
            }
            if ($opts{allow_is_recursive}) {
                my $caller_pkg_from_file;
                for (@$orig_inc_sorted_by_len) {
                    #print "D:\$_=<$_> vs $caller[1]\n";
                    if (index($caller[1], $_) == 0) {
                        $caller_pkg_from_file = substr($caller[1], length($_)+1);
                        #print "D:caller_pkg_from_file=<$caller_pkg_from_file>\n";
                        $caller_pkg_from_file =~ s/\.pm\z//;
                        $caller_pkg_from_file =~ s/\Q$Config{archname}\E.//;
                        $caller_pkg_from_file =~ s![/\\]!::!g;
                    }
                }
                for my $caller_pkg (grep {defined} $caller[0], $caller_pkg_from_file) {
                    (my $pm = "$caller_pkg.pm") =~ s!::!/!g;
                    if (exists $INC{$pm}) {
                        $path = module_path($file, $orig_inc);
                        if ($path) {
                            warn "$dbgh module '$mod' allowed because it is require'd by $caller_pkg (allow_is_recursive=1)\n" if $opts{debug};
                            last FILTER;
                        }
                    }
                }
            }

            my $inc;
            if ($opts{allow_noncore} && $opts{allow_core}) {
                $inc = $orig_inc;
            } elsif ($opts{allow_core}) {
                $inc = $core_inc;
            } elsif ($opts{allow_noncore}) {
                $inc = $noncore_inc;
            }
            if ($inc) {
                warn "$dbgh searching $file in (".join(", ", @$inc).")\n" if $opts{debug};
                $path = module_path($file, $inc);
            }
            last FILTER if $path;
        } # FILTER

        unless ($path) {
            warn "$dbgh $file not found\n" if $opts{debug};
            return;
        }

        warn "$dbgh $file found at $path\n" if $opts{debug};
        $INC{$file} = $path;
        return _open_handle($path);
    };
    $hook = bless(sub{"dummy"}, __PACKAGE__);

    @INC = (
        $hook,
        grep {
            my $mod = $_;
            if ("$mod" eq "$hook") {
                0;
            } elsif ($opts{allow_core} && grep {$mod eq $_} @$core_inc) {
                1;
            } elsif ($opts{allow_noncore} && grep {$mod eq $_} @$noncore_inc) {
                1;
            } else {
                0;
            }
        } @$orig_inc,
    );
    #use DD; dd $orig_inc;
    #use DD; dd \@INC;
}

sub unimport {
    return unless $hook;
    @INC = grep { "$_" ne "$hook" } @INC;
}

1;
# ABSTRACT: Allow/disallow loading modules

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::filter - Allow/disallow loading modules

=head1 VERSION

This document describes version 0.281 of lib::filter (from Perl distribution lib-filter), released on 2021-08-29.

=head1 SYNOPSIS

 use lib::filter %opts;

=head1 DESCRIPTION

lib::filter lets you allow/disallow loading modules using some rules. It works
by installing a coderef in C<@INC> (and additionally by pruning some entries in
C<@INC>). The main use-case for this pragma is for testing.

It has been pointed out to me that for some tasks, alternatives to using this
module exist, so I'll be presenting those in the examples below.

=over

=item * To disallow loading any module:

 % perl -Mlib::filter=allow_core,0,allow_noncore,0 yourscript.pl

You can also use L<lib::none> for this, or simply empty C<@INC> yourself, e.g.:

 {
     local @INC = ();
     ...
 }

To no-op instead of disallowing, see L<lib::noop::all>.

=item * To allow only core modules:

For example for testing a fatpacked script (see L<App::FatPacker>):

 % perl -Mlib::filter=allow_noncore,0 yourscript.pl

You can also use L<lib::core::only> for this, which comes with the
L<App::FatPacker> distribution.

=item * To only allow a specific set of modules:

 % perl -Mlib::filter=allow_core,0,allow_noncore,0,allow,'XSLoader;List::Util' yourscript.pl

To no-op instead of disallowing, see L<lib::noop::except>.

=item * To allow core modules plus some additional modules:

For example to test a fatpacked script that might still require some XS modules:

 # allow additional modules by pattern
 % perl -Mlib::filter=allow_noncore,0,allow_re,'^DateTime::.*' yourscript.pl

 # allow additional modules listed in a file
 % perl -Mlib::filter=allow_noncore,0,allow_list,'/tmp/allow.txt' yourscript.pl

 # allow core modules plus additional modules found in some dirs
 % perl -Mlib::filter=allow_noncore,0,extra_inc,'.:proj/lib' yourscript.pl

 # allow some non-core XS modules
 % perl -MModule::CoreList -Mlib::filter=filter,'sub{ return 1 if Module::CoreList->is_core($_); return 1 if m!Clone|Acme/Damn!; 0' yourscript.pl
 % perl -Mlib::coreplus=Clone,Acme::Damn yourscript.pl

Alternatively, you can also test by preloading the additional modules before
using lib::core::only:

 % perl -mClone -mAcme::Damn -Mlib::core::only yourscript.pl

=item * To allow a module and recursively all other modules that the module requires

This is convenient when we want to allow a non-trivial module which itself uses
some other modules, e.g. L<Moo> or L<Moose>:

 % perl -Mlib::filter=allow_noncore,0,allow,Moo,allow_is_recursive=0

=item * To disallow some modules:

For example to test that a script can still run without a module (e.g. an
optional prereq):

 % perl -Mlib::filter=disallow,'YAML::XS;JSON::XS' yourscript.pl

 # idem, but the list of disallowed modules are retrieved from a file
 % perl -Mlib::filter=disallow_list,/tmp/disallow.txt yourscript.pl

L<Devel::Hide> is another module which you can you for exactly this purpose:

 % perl -MDevel::Hide=YAML::XS,JSON::XS yourscript.pl

To no-op instead of disallowing, see L<lib::noop>.

=item * Do custom filtering

 % perl -Mlib::filter=filter,sub{not/^Foo::/} yourscript.pl

=back

=for Pod::Coverage .+

=head1 OPTIONS

Known options:

=over

=item * debug => bool

If set to true, print diagnostics when filtering.

=item * disallow => str

Add a semicolon-separated list of modules to disallow.

=item * disallow_re => str

Add modules matching regex pattern to disallow.

=item * disallow_list => filename

Read a file containing list of modules to disallow (one module per line).

=item * allow => str

Add a semicolon-separated list of module names to allow.

=item * allow_re => str

Allow modules matching regex pattern.

=item * allow_list => filename

Read a file containing list of modules to allow (one module per line).

=item * allow_is_recursive => bool (default: 0)

If set to 1, then will also allow modules that are required by the allowed
modules (and modules that are allowed by I<those> modules, and so on). This is
convenient if you want to allow a non-trivial module, say, L<Moo> or L<Moose>
which will require other modules too. Without this option, you will need to
explicitly allow each of those modules yourself.

=item * allow_core => bool (default: 1)

Allow core modules.

=item * allow_noncore => bool (default: 1)

Allow non-core modules.

=item * extra_inc => str

Add additional path to search modules in. String must be colon-separated paths.

=item * filter => code

Do custom filtering. Code will receive module name (e.g. C<Foo/Bar.pm>) as its
argument (C<$_> is also localized to contained the module name, for convenience)
and should return 1 if the module should be allowed.

=back

How a module is filtered:

=over

=item * First it's checked against C<filter>, if that option is defined

=item * then, it is checked against the C<disallow>/C<disallow_re>/C<disallow_list>.

If it matches one of those options then the module is disallowed.

=item * Otherwise it is checked against the C<allow>/C<allow_re>/C<allow_list>.

If it matches one of those options and the module's path is found in the
directories in C<@INC>, then the module is allowed.

=item * If C<allow_is_recursive> is true, check the requirer.

If the calling package is already in C<%INC>, we allow that. For example, if we
allow C<Moo> and C<Moo> calls L<Moo::_strictures> and L<Module::Runtime>, we
will also allow them. Later if C<Moo::_strictures> tries to load L<strictures>,
we also allow it, and so on.

=item * Finally, allow_core/allow_noncore is checked.

When C<allow_core> is set to false, core directories are excluded. Likewise,
when C<allow_noncore> is set to false, non-core directories are excluded.

=back

=head1 ENVIRONMENT

=head2 PERL_LIB_FILTER_DEBUG

Boolean. Sets the default for the C<debug> option.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/lib-filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-lib-filter>.

=head1 SEE ALSO

Related/similar modules: L<lib::none>, L<lib::core::only>, L<Devel::Hide>,
L<Test::Without::Module>.

To simulate the absence of certain programs in PATH, you can try
L<File::Which::Patch::Hide>.

To no-op instead of disallowing, see L<lib::noop>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTORS

=for stopwords A. Sinan Unur Olivier Mengué

=over 4

=item *

A. Sinan Unur <nanis@cpan.org>

=item *

Olivier Mengué <dolmen@cpan.org>

=back

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
