=head1 NAME

XAO::Objects - dynamic objects loader

=head1 SYNOPSIS

 use XAO::Objects;

 sub foo {
    ...
    my $page=XAO::Objects->new(objname => 'Web::Page');
 }

=head1 DESCRIPTION

Loader for XAO dynamic objects. This module is most extensively used
throughout all XAO utilities and packages.

The idea of XAO dynamic objects is to seamlessly allow multiple projects
co-exist in the same run-time environment -- for instance multiple web
sites in mod_perl environment. Using traditional Perl modules or objects
it is impossible to have different implementations of an object in the
same namespace -- once one site loads a Some::Object the code is then
re-used by all sites executing in the same instance of Apache/mod_perl.

The architecture of XAO::Web and XAO::FS requires the ability to load an
object by name and at the same time provide a pissibly different
functionality for different sites.

This is achieved by always loading XAO objects using functions of
XAO::Objects package.

Have a look at this example:

 my $dobj=XAO::Objects->new(objname => 'Web::Date');

What happens when this code is executed is that in case current site has
an extended version of Web::Date object -- this extended version will be
returned, otherwise the standard Web::Date is used. This allows for
customizations of a standard object specific to a web site without
affecting other web sites.

For creating an site specific object based on standard object the
following syntax should be used:

 package XAO::DO::Web::MyObject;
 use strict;
 use XAO::Objects;

 use base XAO::Objects->load(objname => 'Web::Page');

 sub display ($%) {
     my $self=shift;
     my $args=get_args(\@_);

     .....
 }

To extend or alter the functionality of a standard object the following
syntax should be used to avoid infinite loop in the object loader:

 package XAO::DO::Web::Date;
 use strict;
 use XAO::Objects;

 use base XAO::Objects->load(objname => 'Web::Date', baseobj => 1);

XAO::Objects is not limited to web site use only, in fact it is used in
XAO Foundation server to load database objects, in XAO::Catalogs to load
custom catalog filters and so on.

=head1 FUNCTIONS

The following functions are available. They can be
called either as 'XAO::Objects->function()' or as
'XAO::Objects::function()'. XAO::Objects never creates objects of its
own namespace, so these are functions, not methods.

=over

=cut

###############################################################################
package XAO::Objects;
use strict;
use XAO::Base qw($homedir $projectsdir);
use XAO::Utils qw(:args :debug);
use XAO::Errors qw(XAO::Objects);
use XAO::Projects;

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Objects.pm,v 2.1 2005/01/13 22:34:34 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

##
# Prototypes
#
sub load (@);
sub new ($%);

###############################################################################

=item load

Pre-loads an object into memory for quicker access and inheritance.

On success returns class name of the loaded object, on error --
undefined value.

It is allowed to call load outside of any site context - it just would
not check site specific objects.

Arguments:

 objname  => object name (required)
 baseobj  => ignore site specific objects even if they exist (optional)
 sitename => should only be used to load Config object

=cut

use vars qw(%objref_cache);
sub load (@) {
    my $class=(scalar(@_)%2 || ref($_[1]) ? shift(@_) : 'XAO::Objects');
    my $args=get_args(\@_);
    my $objname=$args->{objname} ||
        throw XAO::E::Objects "load - no objname given";

    ##
    # Config object is a special case. When we load it we do not have
    # site configuration yet and so we have to rely on supplied site
    # name.
    #
    my $sitename;
    if($args->{baseobj}) {
        # No site name for base object
    }
    elsif($objname eq 'Config') {
        $sitename=$args->{sitename} ||
            throw XAO::E::Objects "load - no sitename given for Config object";
    }
    else {
        $sitename=$args->{sitename} ||
                  XAO::Projects::get_current_project_name() ||
                  '';
    }

    ##
    # Checking cache first
    #
    my $tref;
    if($sitename && ($tref=$objref_cache{$sitename})) {
        return $tref->{$objname} if exists $tref->{$objname};
    }
    elsif(!$sitename && ($tref=$objref_cache{'/'})) {
        return $tref->{$objname} if exists $tref->{$objname};
    }

    ##
    # Checking project directory
    #
    my $objref;
    my $system;
    if($sitename) {
        (my $objfile=$objname) =~ s/::/\//sg;
        $objfile="$projectsdir/$sitename/objects/$objfile.pm";
        if(-f $objfile && open(F,$objfile)) {

            ##
            # Changing $/ can affect module initialization below, so
            # making it in as small scope as possible (bug fix by Eugene
            # Karpachov).
            #
            my $text=do { local $/; <F> };
            close(F);

            $text=~s{^\s*(package\s+(XAO::DO|Symphero::Objects))::($objname\s*;)}
                    {${1}::${sitename}::${3}}m;
            $1 || throw XAO::E::Objects
                  "load - package name is not XAO::DO::$objname in $objfile";
            $2 eq 'XAO::DO' ||
                eprint "Old style package name in $objfile - change to XAO::DO::$objname";

            eval "\n#line 1 \"$objfile\"\n" . $text;
            throw XAO::E::Objects
                  "load - error loading $objname ($objfile) -- $@" if $@;

            $objref="XAO::DO::${sitename}::${objname}";
        }
        $system=0;
    }
    if(! $objref) {
        $objref="XAO::DO::${objname}";
        eval "require $objref";
        throw XAO::E::Objects
              "load - error loading $objname ($objref) -- $@" if $@;
        $system=1;
    }

    ##
    # In case no object was found.
    #
    $objref || throw XAO::E::Objects
                     "load - no object file found for sitename='$sitename', objname='$objname'";

    ##
    # Returning class name and storing into cache
    #
    $objref_cache{$sitename ? $sitename : '/'}->{$objname}=$objref;
}

###############################################################################

=item new (%)

Creates an instance of named object. There is just one required
argument - 'objname', everything else is passed into object's
constructor unmodified.

=cut

sub new ($%) {
    my $class=(scalar(@_)%2 || ref($_[1]) ? shift(@_) : 'XAO::Objects');
    my $args=get_args(\@_);

    my $objname=$args->{objname} ||
        throw XAO::E::Objects "new - no 'objname' given";

    ##
    # Looking up what is real object reference for that objname.
    #
    my $objref=$class->load($args) ||
        throw XAO::E::Objects "new - can't load object ($args->{objname})";

    ##
    # Creating instance of that object
    #
    my $obj=$objref->new($args) ||
        throw XAO::E::Objects "new - error creating instance of $objref ($@)";

    $obj;
}

###############################################################################

1;
__END__

=back

=head1 AUTHOR

Copyright (c) 2000-2002 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Have a look at: L<XAO::Web>, L<XAO::Utils>, L<XAO::FS>.
