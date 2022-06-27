use strict;
use warnings;

package Util::H2O::More;
use parent q/Exporter/;

our $VERSION = q{0.0.8};

our @EXPORT_OK = (qw/baptise opt2h2o h2o o2h/);

use Util::H2O ();

use feature 'state';

# quick hack to export h2o, uses proper
# Util::H2O::h2o called with full namespace
sub h2o {
    return Util::H2O::h2o @_;
}

# maintains basically a count to create non-colliding
# unique $pkg names (basically what Util::H2O::h2o does
# if $pkg is not specified using -class
# monatomically increasing uuid
sub _uuid {
    state $uuid = 0;
    return ++$uuid;
}

# non-recursive option
sub baptise ($$@) {
    my ( $ref, $pkg, @default_accessors );
    my $pos0 = shift;

    # check pos0 for '-recurse'
    if ( $pos0 eq q{-recurse} ) {
        ( $ref, $pkg, @default_accessors ) = @_;
    }
    else {
        $ref = $pos0;
        ( $pkg, @default_accessors ) = @_;
    }

    my $self;
    my $real_pkg = sprintf qq{%s::_%s}, $pkg, _uuid;

    # uses -isa to inherit from $pkg; -class to bless with a package name
    # derived from $pkg
    if ( $pos0 eq q{-recurse} ) {
        $self = h2o -recurse, -isa => $pkg, -class => $real_pkg, $ref, @default_accessors;
    }
    else {
        $self = h2o -isa => $pkg, -class => $real_pkg, $ref, @default_accessors;
    }

    return $self;
}

# preconditioner for use with Getopt::Long flags; returns just the flag name given
# a list of option descriptors, e.g., qw/option1=s option2=i option3/;

# flags to keys
sub opt2h2o(@) {
    my @getopt_def = @_;
    my @flags_only = map { m/([^=|\s]+)/g; $1 } @getopt_def;
    return @flags_only;
}

# return a dereferences hash (non-recursive); reverse of `h2o'
sub o2h {
    # makes internal package name more generic for baptise created references
    $Util::H2O::_PACKAGE_REGEX = qr/::_[0-9A-Fa-f]+\z/;
    my $ref = Util::H2O::o2h @_;
    if ( ref $ref ne q{HASH} ) {
      die qq{Could not fully remove top-level reference. Probably an issue with \$Util::H2O_PACKAGE_REGEX\n};
    }
    return $ref;
}

1;

__END__

=head1 NAME

Util::H2O::More - like if C<bless> created accessors for you.
Intended for I<hash reference>-based Perl OOP only. This module
uses C<Util::H2O::h2o> as the basis for actual object creation;
but there's no reason other accessor makers couldn't have been
used or can be used. I just really like C<h2o>. :-)

NOTE: C<baptise_deeply> has been removed favour of properly handling
the C<-recurse> subroutine flag. Also, this is longer experimental.

=head1 SYNOPSIS

Creating a new module using C<baptise> instead of C<bless>,
which means it includes accessors (thanks to C<Util::H2O::h2o>).
Below is an example of a traditional Perl OOP class constructor
using C<baptise> to define a set of default accessors, in addition
to any that are created by virtue of the C<%opts> passed.

    use strict;
    use warnings;
    
    package Foo::Bar;

    # exports 'h2o' also
    use Util::H2O::More qw/baptise/;
      
    sub new {
      my $pkg    = shift;
      my %opts   = @_;
      
      # replaces bless, defines default constructures and creates
      # constructors based on what's passed into %opts
      
      my $self = baptise \%opts, $pkg, qw/bar haz herp derpes/;
       
      return $self;
    }
     
    1;

Then on a client script,

    use strict;
    use warnings;
     
    use Foo::Bar;
     
    my $foo = Foo::Bar->new(some => q{thing}, else => 4);
     
    print $foo->some . qq{\n};
     
    # set bar via default accessor
    $foo->bar(1);
    print $foo->bar . qq{\n};
    
    # default accessors also available from the class defined
    # above,
    #   $foo->haz, $foo->herp, $foo->derpes
    
    # and from the supplied tuple,
    #   $foo->else

For more example, please look at the classes created for the unit
tests contained in C<t/lib>. More examples may be forthcoming as
this module matures.

=head1 DESCRIPTION

The primary method, C<baptise>, essentially provides the same
interface as the core keyword C<bless> with an additional I<slurpy>
third parameter where one may specify a list of default accessors.

=head2 Why Was This Created?

The really short answer: because C<h2o> doesn't play nice
inside of the traditional Perl OOP constructor (C<new>) idiom.
This is not C<h2o>'s fault. This is my fault for wanting to use
it to do something it was never meant to do.

Implied above is that I wanted to maintain the usage pattern of
C<bless>, but extend it to include the generation of accessors.
I wanted a I<better bless>.

The long answer...

C<h2o> is a deceptively powerful tool that, above all, makes
it I<easy> and I<fun> to add accessors to ad hoc hash references
that many Perl developers like to use and that get emitted,
I<unblessed> by many popular modules. For example, C<HTTP::Tiny>,
C<Web::Scraper>, and the more common I<select%> methods C<DBI>
flavors implement. 

The usage pattern of C<h2o> begs it to be able to support being
used as a I<drop in> replacement for C<bless>. However, this is
not C<h2o>'s original intent and it will not work as a I<better
bless>. But is does a fine job as serving as the I<basis> for a
I<better bless>.

=head1 METHODS

=over 4

=item C<baptise $hash_ref, $pkg, LIST>

Takes the same first 2 parameters as C<bless>; with the addition
of a list that defines a set of default accessors that do not
rely on the top level keys of the provided hash reference.

=item C<baptise -recurse, $hash_ref, $pkg, LIST>

Like C<baptise>, but creates accessors recursively for a nested
hash reference. Uses C<h2o>'s C<-recurse> flag.

Note: The accessors created in the nested hashes are handled
directly by C<h2o> by utilizing the C<-recurse> flag. This means
that they will necessarily be blessed using the unchangable
behavior of C<h2o>, which maintains the name space of C<Util::H2O::_$hash>
even if C<h2o> is passed with the C<-isa> and C<-class> flags,
which are both utilized to achieve the effective outcome of
C<baptise> and C<bastise -recurse>.

=item C<opt2h2o LIST>

Handy function for working with C<Getopt::Long>, which takes
a list of options meant for C<Getopt::Long>; and extracts the
flag names so that they may be used to create default accessors
without having more than one list. E.g.,

    use Getopt::Long qw//;
    my @opts = (qw/option1=s options2=s@ option3 option4=i o5|option5=s/);
    my $o = h2o {}, opt2h2o(@opts);
    Getopt::Long::GetOptionsFromArray( @ARGV, $o, @opts );
    
    # now options are all available as accessors, e.g.:
    if ($o->option3) {
      do_the_thing();
    }

Note: default values for options may still be placed inside
of the anonymous hash being I<objectified> via C<h2o>. This
will work perfectly well with C<baptise> and friends.

    use Getopt::Long qw//;
    my @opts = (qw/option1=s options2=s@ option3 option4=i o5|option5=s/);
    my $o = h2o { option1 => q{foo} }, opt2h2o(@opts);
    Getopt::Long::GetOptionsFromArray( \@ARGV, $o, @opts );
    # ...
    # now $o can be used to query all possible options, even if they were
    # never passed at the commandline 

=item C<o2h REF>

Uses C<Util::H2O::o2h>, so behaves identical to it.  A new hash reference
is returned, unlike C<h2o> or C<baptise>. See C<Util::H2O>'s POD for
a lot more information.

This method complements C<h2o> or C<baptise> very well in the sitution,
e.g., when one is dealing with an ad hoc object that then needs to be
sent as a serialzied JSON string. It's convenient to be able to get
the un<bless>'d data structure most JSON encoding methods are expecting.

Implementation note:

Access to C<Util::H2O::o2h>, but adjusts $Util::H2O::_PACKAGE_REGEX to
accept package names that are generated by C<Util::H2O::More::baptise>.

=item C<baptise_deeply, $hash_ref, $pkg, LIST>

This has been removed.

=back

=head1 EXTERNAL METHODS

=over 4

=item C<h2o>

Because C<Util::H2O::More> exports C<h2o> as the basis for its
operations, C<h2o> is also available without needing to qualify
its full name space.

=back

=head1 DEPENDENCIES

Requires C<Util::H2O> because this module is effectively a wrapper
around C<h2o>.

It also uses the C<state> keyword, which is only available in perls
>= 5.10.

=head1 BUGS

Yes, I mean maybe. Buyer beware.

=head1 LICENSE AND COPYRIGHT 

Perl/perl

=head1 AUTHOR

Oodler 577 L<< <oodler@cpan.org> >> 
