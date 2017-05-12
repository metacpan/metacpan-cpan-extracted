package version::Restrict;

use strict;
use warnings;
use version 0.77;

our $VERSION = '0.01'; # VERSION

my $v0 = version->parse("0");

sub import {
    my $self = shift;
    my %restricted = @_;
    my @ranges = keys %restricted;
    my $package = (caller())[0];

    no strict 'refs';

    for my $range (@ranges) {
        my ($lb, $lower, $upper, $ub) =
            ($range =~ /(.)([0-9.]+),([0-9.]+)(.)/);
        $lb = '>' . ( $lb eq '[' ? '=' : '');
        $ub = '<' . ( $ub eq ']' ? '=' : '');
        $lower = version->parse($lower);
        $upper = version->parse($upper);
        ${"$package\::__version_required"} = 1
            if $lb eq '>=' && $lower == $v0;
        my $test = "sub { \$_[0] $lb version->parse('$lower') && ".
            "\$_[0] $ub version->parse('$upper') }";
        $restricted{$range} = [eval($test), $restricted{$range}];
    }

    *{"$package\::VERSION"} = sub {
        my ($package, $req) = @_;
        $req = version->parse($req);
        my $version = version->parse(${"$package\::VERSION"});
        if ($req > $version) {
            die "$package version $req required--this is only version $version";
        }
        for my $range (@ranges) {
            if ($restricted{$range}[0]->($req)) {
                die "Cannot 'use $package $req': $restricted{$range}[1]\n";
            }
	}
        ${"$package\::__version_checked"} = 1;

        #print "required=", ${"$package\::__version_required"}, "\n";
        return $version;
    };

    my $has_import  = defined(&{"$package\::import"});
    my $orig_import = \&{"$package\::import"};
    #print "pkg=$package, has_import=$has_import\n";

    *{"$package\::import"} = sub {
        my $self = shift;

        #print "checked=", ${"$package\::__version_checked"}, "\n";
        #print "required=", ${"$package\::__version_required"}, "\n";

        my $version = version->parse(${"$package\::VERSION"});
        die "Cannot 'use $package': must specify desired version, ".
            "e.g. 'use $package $version';\n"
                if ${"$package\::__version_required"} &&
                    !${"$package\::__version_checked"};
        ${"$package\::__version_checked"} = 0;

        if ($has_import) {
            $orig_import->($self, @_);
        } else {
            # XXX if Exporter-based only?
            $self->SUPER::import(@_);
        }
    };

}

1;
#ABSTRACT: Control permitted versions that can be use'd

__END__

=pod

=head1 NAME

version::Restrict - Control permitted versions that can be use'd

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your module (you don't want users using version C<v> where C<< 0.0.0 <= v <
1.0.0 >> or C<< 2.2.4 <= v < 2.3.1 >>):

 package YourModule;
 use version::Restrict (
     "[0.0.0,1.0.0)" => "constructor syntax has changed",
     "[2.2.4,2.3.1)" => "frobniz method croaks without second argument",
 );

Now your module users will die when they write:

 use YourModule;       # no version specified
 use YourModule 0.0.1; # contructor syntax has changed
 use YourModule 2.2.5; # frobniz method croaks without second argument

But any of these are OK:

 use YourModule 1.0.0;
 use YourModule 2.4.1;

=head1 DESCRIPTION

Status: experimental/proof-of-concept.

This module is like L<version::Limit>, but with a different interface (you
specify restricted versions in the C<use> statement) and a different behavior
(if v0.0.0 is in one of the restricted versions, your module user must specify
desired version of your module explicitly, otherwise they will die).

This module works by installing a C<VERSION()> method to your module. This
method will be called by Perl when your module user use's your module with
specified version, e.g. C<< use YourModule 0.123; >>.

Additionally, this module will also install (or wrap) an C<import()> method to
your module. The task of this method is to check whether C<VERSION()> has been
called via checking a flag variable. We require C<VERSION()> to be run if one of
the restricted versions is C<v0.0.0>, meaning that you don't want your module
users to just say C<< use YourModule; >> (without specifying explicit version).
After that, the installed C<import()> method just passes control to the original
import method.

=head1 SEE ALSO

L<version::Limit>

http://blogs.perl.org/users/steven_haryanto/2013/09/breaking-users-of-old-versions-of-a-module.html

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
