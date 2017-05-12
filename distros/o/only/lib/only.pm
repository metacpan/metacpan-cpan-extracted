package only;
$VERSION = '0.28';
use strict;
use 5.006001;
use only::config;
use File::Spec;
use Config;
use Carp;
use overload '""' => \&stringify;

BEGIN {
    *qv = eval {require 'version.pm'} ? \&version::qv : sub{$_[0]};
}

# sub X { require Data::Dumper; die Data::Dumper::Dumper(@_) }
# sub Y { require Data::Dumper; print Data::Dumper::Dumper(@_) }

my $versionlib = '';

sub import {
    goto &_install if @_ == 2 and $_[1] eq 'install';
    my $class = shift;
    my $args = {};
    my $module = (($_[0]||"") =~ /\A!?-?\d/) ? 'perl itself' : shift;
    return unless defined $module and $module;
    if (ref $module eq 'HASH') {
        $args = $module;
        $module = shift || '';
    }
    
    my (@sets, $s);
    if (not @_) {
        @sets = (['']);
    }
    elsif (ref($_[0]) eq 'ARRAY') {
        @sets = @_;
    }
    else {
        @sets = ([@_]);
    }


    my $loaded = 0;
    for my $set (@sets) {
        $s = $class->new;
        $s->initialize($args, $module, $set) or return;
        if ($module ne 'perl itself' && $s->search) {
            $s->include;
            local $^W = 0;
            eval "require " . $s->module;
            croak 'Trouble loading ' . $s->found_path . "\n$@" if $@;
            fix_INC();     # fix 5.6.1 %INC bug
            $loaded = 1;
            last;
        }
    }

    if ($module eq 'perl itself') {
        my $perl_version = qv( $] );
        my $required_version = $_[0];
        $required_version =~ s/!\s*/other than /g;
        $required_version =~ s/(?<=\D)-/no later than /g;
        $required_version =~ s/-(?=\D)/ or later/g;
        croak "Perl version $required_version required ",
              "but this is perl $perl_version.\nstopped"
            unless $s->check_version($perl_version);
        return;
    }
    elsif (not defined $INC{$s->canon_path}) {
        eval "require " . $s->module;
        $loaded = not($@) && $s->check_version($s->module->VERSION);
    }

    if (not $loaded) {
        $s->module_not_found;
    }

    my $import = $s->export
      or return;

    @_ = ($s->module, @{$s->arguments});
    goto &$import;
}

sub new {
    my ($class) = @_;
    my $s = bless {}, $class;
    $s->found_path('');
    $s->versionlib($versionlib || &only::config::versionlib);
    return $s;
}

sub initialize {
    my ($s, $args, $module, $set) = @_;
    my ($condition, @arguments) = @$set;

    if (defined $args->{versionlib}) {
        $s->versionlib($args->{versionlib});
        if (not $module) {
            only->versionlib($args->{versionlib});
        }
    }

    return 0 unless $module;
    $s->module($module || '');
    $s->condition($condition || '');
    $s->arguments(\@arguments);

    $s->no_export(@arguments == 1 and
                  ref($arguments[0]) eq 'ARRAY' and
                  @{$arguments[0]} == 0
                 );

    return 1;
}

# Try to squish most occurences of a 5.6.1 bug.
my ($fix_key, $fix_value) = ('', '');
sub fix_INC {
    if ($fix_key) {
        $INC{$fix_key} = $fix_value;
        $fix_key = $fix_value = '';
    }
}
INIT { fix_INC }


sub only::INC {
    my ($s, $module_path) = @_;
    fix_INC;
    $s->search unless $s->found_path;
    return unless defined $s->distribution_modules->{$module_path};

    my $version = $s->distribution_version;

    my $lib_path  = File::Spec->catfile($s->versionlib,  
                                        $version, 
                                        split('/', $module_path),
                                       );
    my $arch_path = File::Spec->catfile($s->versionarch, 
                                        $version, 
                                        split('/', $module_path),
                                       );
    for my $path ($lib_path, $arch_path) {
        if (-f $path) {
            open my $fh, $path
              or die "Can't open $path for input\n";
            $INC{$module_path} = $path;
            ($fix_key, $fix_value) = ($module_path, $path);
            return $fh;
        }
    }
    die "Can't load versioned $module_path\n";
}

sub search {
    my ($s) = @_;
    $s->found_path('');

    if (defined $INC{$s->canon_path}) {
        return $s->check_version($s->get_loaded_version);
    }
        
    my @versions;
    if ($s->fancy) {
        @versions = grep $s->check_version($_), $s->all_versions();
    }
    else {
        @versions = map { $_->[0] } @{$s->condition_spec};
    }

    for my $version (sort { $b <=> $a } @versions) {
        my $lib_path = File::Spec->catfile($s->versionlib,  
                                           $version, $s->mod_path);
        my $arch_path = File::Spec->catfile($s->versionarch, 
                                            $version, $s->mod_path);
        for my $path ($lib_path, $arch_path) {
            if (-f $path) {
                $s->found_path($path);
                $s->distribution_modules($s->found_path);
                $s->distribution_version($version);
                return 1;
            }
        }
    }
    return 0;
}

sub stringify {
    my ($s) = @_;
    'only:' . $s->module . ':' . 
      File::Spec->catdir($s->versionlib, $s->distribution_version)
}

sub include {
    my ($s) = @_;
    $s->remove;
    unshift @INC, $s;
    $s
}

sub remove {
    my ($s) = @_;
    my $strval = overload::StrVal $s;
    my @inc = grep {not(ref($_)) or overload::StrVal($_) ne $strval} @INC;
    @INC = @inc;
    $s
}

# Generic OO accessors
for (qw( found_path mod_path canon_path
         condition_str condition_spec fancy
         versionarch arguments no_export
         distribution_version
    )) {
    eval <<END;
sub $_ {
    my \$s = shift;
    if (\@_) {
        \$s->{$_} = shift;
        return \$s
    }
    else {
        return defined \$s->{$_} ? \$s->{$_} : '';
    }
}
END
}

sub DESTROY {} # To avoid autoloading it.

sub module {
    my $s = shift;
    if (@_) {
        $s->found_path('');
        $s->{module} = shift;
        $s->mod_path(File::Spec->catdir(split '::', $s->{module}) . '.pm');
        $s->canon_path(join('/',split('::', $s->{module})).'.pm');
        return $s;
    }
    else {
        return $s->{module};
    }
}

sub condition {
    my $s = shift;
    if (@_) {
        $s->found_path('');
        $s->condition_str(shift);
        $s->parse_condition;
        return $s;
    }
    else {
        return $s->condition_str;
    }
}

sub versionlib {
    my $s = shift;
    if (ref $s) {
        if (@_) {
            $s->found_path('');
            $s->{versionlib} = shift;
            $s->versionarch(File::Spec->catdir($s->{versionlib}, 
                                               $Config{archname}
                                              ));
            return $s;
        }
        else {
            return $s->{versionlib};
        }
    }
    elsif (@_) {
        $versionlib = shift;
    }
    return $versionlib;
}

sub distribution_modules {
    my ($s, $path) = (@_, '');
    $s->{distribution_modules} ||= {};
    return $s->{distribution_modules}
      unless $path;
    $path =~ s/\.pm$/\.yaml/
      or return {};
    open META, $path
      or return {};
    $s->{distribution_modules} = {};
    my $meta = do {local $/; <META>};
    close META;
    $s->{distribution_modules}{$_} = 1 for ($meta =~ /^  - (\S+)/gm);
    $s->{distribution_modules}
}

sub export {
    my ($s) = @_;
    return if $s->no_export;
    $s->module->can('import')
}

sub get_loaded_version {
    my ($s) = @_;
    my $path = $INC{$s->canon_path};
    my $version = $s->module->VERSION;
    if ($path =~ s/\.pm$/\.yaml/ and -f $path) {
        open META, $path
          or croak "Can't open $path for input:\n$!";
        my $meta = do {local $/;<META>};
        close META;
        if ($meta =~ /^install_version\s*:\s*(\S+)$/m) {
            $version = $1;
        }
    }
    $version
}

sub parse_condition {
    my ($s) = @_;
    my @condition = split /\s+/, $s->condition_str;
    $s->fancy(@condition ? 0 : 1);
    @condition = map {
        my $v;
        if (/^(!)?(\d[\d\.]*)?(?:(-)(\d[\d\.]*)?)?$/) {
            $s->fancy(1)
              if defined($1) or defined($3);
            my $lower = qv($2 || '0.00');
            my $upper = defined($4) ? qv($4) : 
                        defined($3) ? '99999999' : 
                        $lower;
            my $negate = defined($1) ? 1 : 0;
            croak "Lower bound > upper bound in '$_'\n"
              if $lower > $upper;
            $v = [$lower, $upper, $negate];
        }
        else {
            croak "Invalid condition '$_' specified for 'only'\n";
        }
        $v;
    } @condition;
    $s->condition_spec(\@condition)
}

sub all_versions {
    my ($s) = @_;
    my %versions;
    for my $lib ($s->versionlib, $s->versionarch) {
        opendir LIB, $s->versionlib;
        while (my $dir = readdir(LIB)) {
            next unless $dir =~ /^\d[\d\.]*$/;
            next if $dir eq $Config{version};
            $versions{$dir} = 1;
        }
        closedir(LIB);
    }
    keys %versions
}

sub check_version {
    my ($s, $version) = @_;
    my @specs = @{$s->condition_spec};
    return 1 unless @specs;
    my $match = 0;
    for my $spec (@specs) {
        my ($lower, $upper, $negate) = @$spec;
        next if $match and not $negate;
        if ($version >= $lower and $version <= $upper) {
            return 0 if $negate;
            $match = 1;
        }
    }
    $match
}

sub module_not_found {
    use Data::Dumper;
    my ($s) = @_;
    my $p = $s->module;
    if (defined $INC{$s->canon_path}) {
        my $v = qv($s->get_loaded_version);
        my $req = $s->condition_str();
        croak <<END;
Loaded $p, but version ($v) did not satisfy the requirement:

    use only $p => '$req';

END
    }
    my $faux_inc = 'only:' . $s->module . ':' . $s->versionlib;
    my $inc = join "\n", map "  - $_", ($faux_inc, @INC);
    croak <<END;
Can't locate desired version of $p in \@INC:
$inc
END
}

sub _install {
    require only::install;
    my %args;
    if (@ARGV == 1 and $ARGV[0] =~ /^[\d\.]+$/) {
        $args{version} = $ARGV[0];
    }
    else {
        for (@ARGV) {
            unless (/^(\w+)=(\S+)$/) {
                croak "Invalid option format '$_' for only=install\n";
            }
            $args{$1} = $2;
        }
    }
    only::install::install(%args);
    exit 0;
}
    
1;

__END__

=head1 NAME

only - Load specific module versions; Install many

=head1 SYNOPSIS

    # Install version 0.30 of MyModule
    cd MyModule-0.30
    perl Makefile.PL
    make test
    perl -Monly=install    # substitute for 'make install' 
    perl -Monly=install - version=0.33 versionlib=/home/ingy/perlmods
    
    # Only use MyModule version 0.30
    use only MyModule => 0.30;

    # Only use MyModule if version is between 0.30 and 0.50
    # but not 0.36; or if version is >= to 0.55.
    use only MyModule => '0.30-0.50 !0.36 0.55-', qw(:all);

    # Don't export anything!
    use only MyModule => 0.30, [];

    # Version dependent arguments
    use only MyModule =>
        [ '0.20-0.27', qw(f1 f2 f3 f4) ],
        [ '0.30-',     qw(:all) ];

    # Override versionlib
    use only {versionlib => '/home/ingy/perlmods'},
        MyModule => 0.33;
    
    # Override versionlib globally
    use only {versionlib => '/home/ingy/perlmods'};
    use only MyModule => 0.33;

    # Object Oriented Interface
    use only;
    $only = only->new;
    $only->module('MyModule');
    $only->condition('0.30');
    $only->include;
    require MyModule;
    $only->remove;
    
=head1 USAGE

    # Note: <angle brackets> mean "optional".

    # To load a specific module
    use only MODULE => 'CONDITION SPEC' <, ARGUMENTS>;

    # To set options
    use only < { OPTIONS HASH } >, MODULE => 'CONDITION SPEC';

    # To set options globally
    use only < { OPTIONS HASH } >;

    # For multiple argument sets
    use only MODULE => 
        ['CONDITION SPEC 1' <, ARGUMENTS1>],
        ['CONDITION SPEC 2' <, ARGUMENTS2>],
        ...
        ;

    # To install an alternate version of a module
    perl -Monly=install <- ARGUMENTS>        # instead of 'make install'

=head1 DESCRIPTION

The C<only.pm> facility allows you to load a MODULE only if it satisfies
a given CONDITION. Normally that condition is a version. If you just
specify a single version, C<'only'> will only load the module matching
that version. If you specify multiple versions, the module can be any of
those versions. See below for all the different conditions you can use
with C<only>.

C<only.pm> will also allow you to load a particular version of a module,
when many versions of the same module are installed. See below for
instructions on how to easily install many different versions of the
same module.

=head1 CONDITION SPECS

A condition specification is a single string containing a list of zero
or more conditions. The list of conditions is separated by spaces. Each
condition can take one of the following forms:

=over 4

=item * plain version

This is the most basic form. The loaded module must match this
version string or be loaded from a B<version directory> that uses the
version string. Mulitiple versions means one B<or> the other.

    use only MyModule => '0.11';
    use only MyModule => '0.11 0.15';

=item * version range

This is two single versions separated by a dash. The end points are
inclusive in the range. If either end of the range is ommitted, then the
range is open ended on that side.

    use only MyModule => '0.11-0.12';
    use only MyModule => '0.13-';
    use only MyModule => '-0.10';
    use only MyModule => '-';       # Means any version

Note that a completely open range (any version) is not the same as
just saying:

    use MyModule;

because the C<only> module will search all the various version libs
before searhing in the regular @INC paths.

Also note that an empty string or no string means the same thing as '-'.

    # All of these mean "use any version"
    use only MyModule => '-';
    use only MyModule => '';
    use only 'MyModule';

=item * complement version or range

Any version or range beginning with a C<'!'> is considered to mean the
inverse of that specification. A complement takes precedence over all
other specifications. If a module version matches a complement, that
version is immediately rejected without further inspection.

    use only MyModule => '!0.31';
    use only MyModule => '0.30-0.40 !0.31-0.33';

=back

The search works by searching the version-lib directories (found in
C<only::config>) for a module that meets the condition specification. If
more than one version is found, the highest version is used. If no
module meets the specification, then a normal @INC style C<require> is
performed.

If the condition is a subroutine reference, that subroutine will be
called and passed an C<only> object. If the subroutine returns a false
value, the program will die. See below for a list of public methods that
may be used upon the C<only> object.

=head1 ARGUMENTS

All of the arguments following the CONDITION specification, will be
passed to the module being loaded. 

Normally you can pass an empty list to C<use> to turn off Exporting. To do this with C<only>, use an empty array ref.

    use only MyModule => '0.30';       # Default exporting
    use only MyModule => '0.30', [];   # No exporting
    use only MyModule => '0.30', qw(export list);  # Specific export

If you need pass different arguments depending on which version is used,
simply wrap each condition spec and arguments with an array ref.

    use only MyModule =>
        [ '0.20-0.27', qw(f1 f2 f3 f4) ],
        [ '0.30-',     qw(:all) ];

=head1 OPTIONS

Options to C<only> are specified as a hash reference placed before the
module name. If there is no module name, the options become global,
and affect all other calls to only (even ones from other modules, so
be aware). 

Currently, the only option is C<versionlib>.

Sometimes you need to tell C<only> to use a specific version library to
load from. Use the C<versionlib> option to do this.

    use only { versionlib => '/home/ingy/modules' },
        MyModule => 0.33;

=head1 INSTALLING MULTIPLE MODULE VERSIONS

The C<only.pm> module also has a facility for installing more than one
version of a particular module. Using this facility you can install an
older version of a module and use it with the C<'use only'> syntax.

It works like this; when installing a module, do the familiar:

    perl Makefile.PL
    make
    make test

But instead of C<make install>, do this:

    perl -Monly=install

This will attempt to determine what version the module should be
installed under. In some cases you may need to specify the version
yourself. Do the following:

    perl -Monly=install - version=0.55

By default, everything will be installed in versionlib directory stored
in C<only::config>. To override the installation location, do this:

    perl -Monly=install - versionlib=/home/ingy/modules

NOTE:
Also works with C<Module::Build> style modules.

NOTE: 
The C<perl> you use for this must be the same C<perl> as the one used to
do C<perl Makefile.PL> or C<perl Build.PL>. While this seems obvious,
you may run into problems with C<sudo perl -Monly=install>, since the
C<root> account may have a different C<perl> in its path. If this
happens, just use the full path to your C<perl>.

=head2 Installing with Module::Build

When installing modules distributed with Module::Build, you can use the
following commands to install into version specific libraries:

    perl Build.PL
    ./Build
    ./Build versioninstall
 
For overrides:

    perl Build.PL version=1.23 versionlib=/home/ingy/modules
    ./Build
    ./Build versioninstall

NOTE: 
The Module::Build verion install does not suffer from the same C<sudo>
problem outlined above. Module::Build remembers the original perl path.

=head1 INSTALLATION LOCATION

When you install the C<only> module, you can tell it where to install
alternate versions of modules. These paths get stored into
C<only::config>. The default location to install things is parallel to
your sitelib. For instance if your sitelib was:

    /usr/lib/perl5/site_perl

C<only> would default to:

    /usr/lib/perl5/version

This keeps your normal install trees free from any potential
complication with version modules.

If you install version 0.24 and 0.26 of MyModule and version 0.26 of
Your::Module, they will end up here:

    /usr/lib/perl5/version/0.24/My/Module.pm
    /usr/lib/perl5/version/0.26/My/Module.pm
    /usr/lib/perl5/version/0.26/Your/Module.pm

=head1 HOW IT WORKS

C<only.pm> is kind of like C<lib.pm> on Koolaid! Instead of adding a
search path to C<@INC>, it adds a B<search object> to C<@INC>. This
object is actually the C<only.pm> object itself. The object keeps track
of all of the modules related to a given module distribution
installation, and takes responsibility for loading those modules. This
is very important because if you say:

    use only Goodness => '0.23';

and then later:

    require Goodness::Gracious;

you want to be sure that the correct version of the second module
gets loaded. Especially when another module is doing the loading.

=head1 OBJECT ORIENTED API

C<only> is implemented internally using Object Oriented Programming. 
You yourself can also make use of C<only> objects directly in your
program. Instead of saying something like this:

    use only MyModule => '0.30', qw(foo bar);

You could say:

    my $only;
    BEGIN {
        $only = only->new;
        $only->module('MyModule')->condition('0.30');
        $only->include;
    }
    use MyModule qw(foo bar);

The cool thing here is that we just used a normal C<use> statement to
load a particular module.

This gives you more control and you may be able to do some interesting
stuff this way.

The following sections detail the Object Oriented API.

=head2 Class Methods

There are three class methods available:

=over 4

=item * new

This simply constucts a new C<only> object. It takes no arguments.

    my $only = only->new;

=item * versionlib

When call as a class method, C<versionlib> sets the global default
versionlib for all future C<only> processing. This takes one argument.

    only->versionlib('/home/ingy/modules');

=item * fix_INC

There is a bug in Perl 5.6.1 that sometimes leaves an incorrect value 
in %INC after loading a module from an C<only> object. If you call 
this method after a C<use> or C<require> the values will be fixed.

=back

=head2 Object Methods

All of the following methods return themselves when used as
store-accessors. This lets you chain calls together:

    only->new->module('MyModule)->version('0.30')->include;

When used as fetch-accessors they, of course, return their values.

=over 4

=item * module

You pass this method the name of any one module from a particular
installed module distribution. The object becomes responsible for
loading any and all modules associated with the one you specified.

    $only->module('MyModule');

=item * condition

Sets the version condition specification.

    $only->condition('0.30-0.50');

=item * versionlib

When called as an object method, C<versionlib> sets the versionlib that
will be used by this object.

    $only->versionlib('/home/ingy/modules');

=item * include

This simply puts the object at the front of @INC. It also makes sure
that no other references to the same object are in @INC.

    $only->include;

Remember that your object will only have an effect on the Perl's
C<require> process, if it is in @INC.

=item * remove

This method removes any references to the object from @INC.

    $only->remove;

=item * search

You won't normally need to call this method yourself. Search determines
whether a matching copy of the module exists for the current values of
C<module>, C<condition> and C<versionlib>. It doesn't actually load
anything though.

    if ($only->search) {
        ...
    }

C<search> is called automatically when a C<use> or C<require> hits
your object.

=item * distribution_version

After a successful C<search> (or C<use> or C<require>), this method will
return the version that was found.

    my $version = $only->distribution_version;

=back

=head1 THE FINE PRINT ON VERSIONING

The C<only.pm> module loads a module by the following process:

 1) Look for the highest suitable version of the module in the version
    libraries specified in only::config.
 
 else:
 
 2) Do a normal require() of the module, and check to make sure the 
    version is in the range specified.

It is important to understand that the versions used in these two
different steps come from different places and might not be the same.
    
In the first step the version used is the version of the C<distribution>
that the module was installed from. This is grepped out of the Makefile
and saved as metadata for that module.

In the second step, the version is taken from $VERSION of that module.
This is the same process used when you do something like:

     use MyModule '0.50';

Unfortunately, there is no way to know what the distribution version is
for a normally installed module.

Fortunately, $VERSION is usually the same as the distribution version.
That's because the popular C<VERSION_FROM> Makefile.PL option makes it
happen. Authors are encouraged to use this option.

The conclusion here is that C<only.pm> usually gets things right. Always
check %INC, if you suspect that the wrong versions are being pulled in.
If this happens, use more C<'use only'> statements to pull in the right
versions. 

One failsafe solution is to make sure that all module versions in
question are installed into the version libraries.

=head1 LOADING MULTIPLE MODULE VERSIONS (at the same time)

You can't do that! Are you crazy? Well B<I> am. I can't do this yet but
I'd really like to. I'm working on it. If you have ideas on how this
might be accomplished, send me an email. If you don't have a good idea,
send me some coffee.

=head1 BUGS AND CAVEATS

=over 4

=item *

This module only works with Perl 5.6.1 and higher. That's because earlier
versions of Perl don't support putting objects in @INC.

=item *

There is currently no way to install documentation for multiple modules.
It wouldn't make much sense anyway, because C<perldoc> wouldn't have
support for reading the doc.

=item *

You can't use C<only> to load a specific version of C<only> itself,
because the default version gets loaded before it can do any trickery.

If you had both versions 1.23 and 3.21 installed:

    use only only => '1.23';

would load up 3.21 and then fail because it wasn't 1.23.

=back

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
