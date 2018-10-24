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
use warnings;
use feature qw(state);
use XAO::Base qw($homedir $projectsdir);
use XAO::Utils qw(:args :debug);
use XAO::Errors qw(XAO::Objects);
use XAO::Projects;

our $VERSION=(2.001);

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

When called from an established site context that context is checked for
an optional configuration value /xao/objects/include that may contain a
list of "library" projects that are checked for object implementations.

Given an objname equal "Foo::Bar" the logic is this:

  1. If there a current site, or a sitename is given, check that site
     for objects/Foo/Bar.pm and load if it exists.
  2. If there is a /xao/objects/include configuration, then check
     that list of sites for their objects/Foo/Bar.pm implementations,
     returning first found if any.
  3. Default to the system XAO::DO::Foo::Bar implementation if none
     are found in site context.

If there is a 'baseobj' argument then the first step is skipped and the
search is started with included sites defaulting to the system object.

=cut

sub load (@) {
    my $class=(scalar(@_)%2 || ref($_[1]) ? shift(@_) : 'XAO::Objects');
    my $args=get_args(\@_);

    my $objname=$args->{'objname'} ||
        throw XAO::E::Objects "- no objname given";

    my $baseobj=$args->{'baseobj'};

    # Config object is a special case. When we load it we do not have
    # site configuration yet and so we have to rely on supplied site
    # name.
    #
    my $current_sitename=XAO::Projects::get_current_project_name();
    my $sitename=$args->{'sitename'} || $current_sitename || '';

    if($objname eq 'Config') {
        $baseobj || $sitename ||
            throw XAO::E::Objects "- no sitename given for Config object";
    }

    # Checking the cache first
    #
    state %objref_cache;

    my $cache_key=($baseobj ? '^' : '') . $sitename . '/' . $objname;
    my $objref=$objref_cache{$cache_key};

    return $objref if $objref;

    # There might be an inheritance chain configured for library
    # projects.
    #
    my @siteinc;
    if($sitename && !$baseobj) {
        push(@siteinc,$sitename);
    }

    if($current_sitename && $current_sitename eq $sitename) {
        my $config=XAO::Projects::get_current_project();
        if($config && $config->is_embedded('hash') && (my $include=$config->get('/xao/objects/include'))) {
            push(@siteinc,@$include);
        }
    }

    ### dprint "----$sitename:$objname: SITEINC: (".join('|',@siteinc).")";

    if(@siteinc) {
        (my $objfile=$objname) =~ s/::/\//sg;
        $objfile.='.pm';

        foreach my $sn (@siteinc) {
            my $objpath="$projectsdir/$sn/objects/$objfile";

            next unless -f $objpath;

            ### dprint "----$sitename:$objname: Have $objname in $objpath";

            # %INC has package names converted to file notation.
            # In our case there is no real file for
            # XAO/DO/sitename/Foo.pm, but the convention is
            # still kept.
            #
            my $pkg="XAO::DO::${sn}::${objname}";
            (my $pkgfile=$pkg)=~s/::/\//sg;
            $pkgfile.='.pm';

            # It is possible we already loaded this before
            #
            if(!$INC{$pkgfile}) {
                open(F,$objpath) ||
                    throw XAO::E::Objects "- unable to open $objpath: $!";

                # Changing $/ can affect module initialization below, so
                # making it in as small scope as possible (bug fix by
                # Eugene Karpachov).
                #
                my $text=do { local $/; <F> };

                close(F);

                $text=~s{^\s*(package\s+)XAO::DO::$objname(\s*;)}
                        {$1$pkg$2}m;
                $1 ||
                    throw XAO::E::Objects "- package name is not XAO::DO::$objname in $objpath";

                ### dprint "----$sitename:$objname: (((".($text=~/^(.*?)\n/s ? $1 : '').")))";

                eval "\n#line 1 \"$objpath\"\n" . $text;

                !$@ ||
                    throw XAO::E::Objects "- error loading $objname ($objpath) -- $@";

                $INC{$pkgfile}=$objpath;

                ### dprint "----$sitename:$objname: INC{$pkgfile}=",$INC{$pkgfile};
                ### if(1) {
                ###     no strict 'refs';
                ###     my $scope=$pkg.'::';
                ###     foreach my $k (sort keys %$scope) {
                ###         dprint "------${scope}{$k}=$scope->{$k}";
                ###     }
                ### }
            }

            $objref=$pkg;

            last;
        }
    }

    # System installed package is the default
    #
    if(! $objref) {
        $objref="XAO::DO::${objname}";
        eval "require $objref";
        !$@ ||
            throw XAO::E::Objects "- error loading $objname ($objref) -- $@";
    }

    # In case no object was found.
    #
    $objref ||
        throw XAO::E::Objects "- no object file found for sitename='$sitename', objname='$objname'";

    ### dprint "----$sitename:$objname: ============ load($objname) cache{$cache_key}=$objref";

    # Returning class name and storing into cache
    #
    return $objref_cache{$cache_key}=$objref;
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

    my $objname=$args->{'objname'} ||
        throw XAO::E::Objects "- no 'objname' given";

    # Looking up what is real object reference for that objname.
    #
    my $objref=$class->load($args) ||
        throw XAO::E::Objects "- can't load object ($objname)";

    # Creating instance of that object
    #
    my $obj=$objref->new($args) ||
        throw XAO::E::Objects "- error creating instance of $objref ($@)";

    return $obj;
}

###############################################################################

1;
__END__

=back

=head1 AUTHOR

Copyright (c) 2000-2002 XAO Inc.

Andrew Maltsev <am@ejelta.com>.

=head1 SEE ALSO

Have a look at: L<XAO::Web>, L<XAO::Utils>, L<XAO::FS>.
