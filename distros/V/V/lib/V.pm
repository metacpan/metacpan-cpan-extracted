package V;
use strict;

use vars qw( $VERSION $NO_EXIT );
$VERSION  = "0.19";

$NO_EXIT ||= 0; # prevent import() from exit()ing and fall of the edge

our $DEBUG ||= $ENV{PERL_V_DEBUG} || 0;

=head1 NAME

V - Print version of the specified module(s).

=head1 SYNOPSIS

    $ perl -MV=V

or if you want more than one

    $ perl -MV=CPAN,V

Can now also be used as a light-weight module for getting versions of
modules without loading them:

    require V;
    printf "%s has version '%s'\n", "V", V::get_version( "V" );

Starting with version B<0.17>, V will show all C<package>s or C<class>es in a
file that have a version. If one wants to see all packages/classes from that
file, set the environment variable C<PERL_V_SHOW_ALL> to a I<true> value.

If you want all available files/versions from C<@INC>:

    require V;
    my @all_V = V::Module::Info->all_installed("V");
    printf "%s:\n", $all_V[0]->name;
    for my $file (@all_V) {
        my ($versions) = $file->version; # Must be list context
        if (@$versions > 1) {
            printf "\t%s:\n", $file->name;
            for my $ver (@versions) {
                print "\t    %-30s: %s\n", $ver->{pkg}, $ver->{version};
            }
        }
        else {
            printf "\t%-50s - %s\n", $file->file, $versions->[0]{version};
        }
    }

Each element in that array isa C<V::Module::Info> object with 3 attributes and a method:

=over

=item I<attribute> B<name>

The package name.

=item I<attribute> B<file>

Full filename with directory.

=item I<attribute> B<dir>

The base directory (from C<@INC>) where the package-file was found.

=item I<method> B<version>

This method will look through the file to see if it can find a version
assignment in the file and uses that to determine the version. As of version
B<0.13_01>, all versions found are passed through the L<version> module.

As of version B<0.16_03> we look for all types of version declaration:

    package Foo;
    our $VERSION = 0.42;

and

    package Foo 0.42;

and

    package Foo 0.42 { ... }

Not only do we look for the C<package> keyword, but also for C<class>.
In list context this method will return an arrayref to a list of structures:

=over 8

=item I<pkg>

The name of the C<package>/C<class>.

=item I<version>

The version for that C<package>/C<class>. (Can be absent if C<$PERL_V_SHOW_ALL>
is true.)

=item I<ord>

The ordinal number of occurrence in the file.

=back

=back

=head1 DESCRIPTION

This module uses stolen code from L<Module::Info> to find the location
and version of the specified module(s). It prints them and exit()s.

It defines C<import()> and is based on an idea from Michael Schwern
on the perl5-porters list. See the discussion:

  https://www.nntp.perl.org/group/perl.perl5.porters/2002/01/msg51007.html

=head2 V::get_version($pkg)

Returns the version of the first available file for this package as found by
following C<@INC>.

=head3 Arguments

=over

=item 1. $pkg

The name of the package for which one wants to know the version.

=back

=head3 Response

This C<V::get_version()> returns the version of the file that was first found
for this package by following C<@INC> or C<undef> if no file was found.

=begin implementation

=head2 report_pkg

This sub prints the results for a package.

=head3 Arguments

=over

=item 1. $pkg

The name of the package that was probed for versions

=item 2. @versions

An array of Module-objects with full path and version.

=back

=end implementation

=head1 AUTHOR

Abe Timmerman C<< <abeltje@cpan.org> >>.

=head1 COPYRIGHT & LICENSE

Copyright 2002-2006 Abe Timmerman, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

sub report_pkg($@) {
    my $pkg = shift;

    print "$pkg\n";
    @_ or print "\tNot found\n";
    for my $module ( @_ ) {
        my ($versions) = $module->version;
        if (@$versions > 1) {
            printf "\t%s:\n", $module->file;
            for my $option (@$versions) {
                printf "\t    %s: %s\n", $option->{pkg}, $option->{version} || '';
            }
        }
        else {
            printf "\t%s: %s\n", $module->file, $versions->[0]{version} || '?';
        }
    }
}

sub import {
    shift;
    @_ or push @_, 'V';

   for my $pkg ( @_ ) {
        my @modules = V::Module::Info->all_installed( $pkg );
        report_pkg $pkg, @modules;
    }
    exit() unless $NO_EXIT;
}

sub get_version {
    my( $pkg ) = @_;
    my( $first ) = V::Module::Info->all_installed( $pkg );
    return $first ? $first->version : undef;
}

caller or V->import( @ARGV );

1;

# Okay I did the AUTOLOAD() bit, but this is a Copy 'n Paste job.
# Thank you Michael Schwern for Module::Info! This one is mostly that!

package V::Module::Info;

require File::Spec;

sub new_from_file {
    my($proto, $file) = @_;
    my($class) = ref $proto || $proto;

    return unless -r $file;

    my $self = {};
    $self->{file} = File::Spec->rel2abs($file);
    $self->{dir}  = '';
    $self->{name} = '';

    return bless $self, $class;
}

sub all_installed {
    my($proto, $name, @inc) = @_;
    my($class) = ref $proto || $proto;

    @inc = @INC unless @inc;
    my $file = File::Spec->catfile(split m/::/, $name) . '.pm';

    my @modules = ();
    foreach my $dir (@inc) {
        # Skip the new code ref in @INC feature.
        next if ref $dir;

        my $filename = File::Spec->catfile($dir, $file);
        if( -r $filename ) {
            my $module = $class->new_from_file($filename);
            $module->{dir} = File::Spec->rel2abs($dir);
            $module->{name} = $name;
            push @modules, $module;
        }
    }

    do {print {*STDERR} "# $file: @{[scalar $_->version]}\n" for @modules} if $V::DEBUG;
    return @modules;
}

# Once thieved from ExtUtils::MM_Unix 1.12603
sub version {
    my($self) = shift;

    my $parsefile = $self->file;

    open(my $mod, '<', $parsefile) or die "open($parsefile): $!";

    my $inpod = 0;
    local $_;
    my %eval;
    my ($cur_pkg, $cur_ord) = ("main", 0);
    $eval{$cur_pkg} = { ord => $cur_ord };
    while (<$mod>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;
        next if m/^\s*#/;

        chomp;
        if (m/^\s* (?:package|class) \s+ (\w+(?:::\w+)*) /x) {
            $cur_pkg = $1;
            $eval{$cur_pkg} = { ord => ++$cur_ord } if !exists($eval{$cur_pkg});
        }

        next if $cur_pkg =~ m{^V::Module::Info};

        if (m/(?:our)?\s*([\$*])(([\w\:\']*)\bVERSION)\s*\=(?![=~])/) {
            { local($1, $2); ($_ = $_) = m/(.*)/; } # untaint
            my ($sigil, $name) = ($1, $2);
            next if m/\$$name\s*=\s*eval.+\$$name/;
            next if m/my\s*\$VERSION\s*=/;
            $eval{$cur_pkg}{prg} = qq{
                package V::Module::Info::_version_var;
                # $cur_pkg
                no strict;
                local $sigil$name;
                \$$name=undef; do {
                    $_
                }; \$$name
            };
        }
        # perl 5.12.0+
        elsif (m/^\s* (?:package|class) \s+ [^\s]+ \s+ (v?[0-9.]+) \s* [;\{]/x) {
            my $ver = $1;
            if ( $] >= 5.012000 ) {
                $eval{$cur_pkg}{prg} = qq{
                    package V::Module::Info::_version_static $ver;
                    # $cur_pkg
                    V::Module::Info::_version_static->VERSION;
                };
            }
            else {
                warn("Your perl doesn't understand the version declaration of $cur_pkg\n");
                $eval{$cur_pkg}{prg} = qq{ $ver };
            }
        }
    }
    close($mod);

    # remove our stuff
    delete($eval{$_}) for grep { m/^V::Module::Info/ } keys %eval;

    my @results;
    while (my ($pkg, $dat) = each(%eval)) {
        my $result;
        if ($dat->{prg}) {
            print {*STDERR} "# $pkg: $dat->{prg}\n" if $V::DEBUG;
            local $^W = 0;
            $result = eval($dat->{prg});
            warn("Could not eval '$dat->{prg}' in $parsefile: $@")
                if $@ && $V::DEBUG;

            # use the version modulue to deal with v-strings
            require version;
            $dat->{ver} = $result = version->parse($result);
        }
        push(
            @results,
            {
                (exists($dat->{ver}) ? (version => $result) : ()),
                pkg => $pkg,
                ord => $dat->{ord}
            }
        );
    }
    if (! $ENV{PERL_V_SHOW_ALL}) {
        @results = grep { exists($_->{version}) } @results;
    }

    if (@results > 1) {
        @results = grep {
            $_->{pkg} ne 'main' || exists($_->{version})
        } @results;
    }

    if (! wantarray ) {
        for my $option (@results) {
            next unless $option->{pkg} eq $self->name;
            return $option->{version};
        }
        return;
    }
    return [ sort {$a->{ord} <=> $b->{ord} } @results ];
}

sub accessor {
    my $self = shift;
    my $field = shift;

    $self->{ $field } = $_[0] if @_;
    return $self->{ $field };
}

sub AUTOLOAD {
    my( $self ) = @_;

    use vars qw( $AUTOLOAD );
    my( $method ) = $AUTOLOAD =~ m|.+::(.+)$|;

    if ( exists $self->{ $method } ) {
        splice @_, 1, 0, $method;
        goto &accessor;
    }
}
