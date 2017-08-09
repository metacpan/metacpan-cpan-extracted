=head1 NAME

XAO::Projects - project context switcher for XAO

=head1 SYNOPSIS

 use XAO::SimpleHash;
 use XAO::Projects;

 my $fubar=new XAO::SimpleHash foo => 'bar';
 XAO::Projects::create_project(fubar => $fubar);
 XAO::Projects::set_current_project('fubar');

 ...

 ##
 # Probably in different module..
 #
 my $pd=XAO::Projects::get_current_project();

=head1 DESCRIPTION

B<XXX: Need to be proof read - left from Symphero::SiteConfig>

This object holds all site-specific configuration values and provides
various useful methods that are not related to any particular
displayable object (see L<XAO::Objects::Page>).

In mod_perl context this object is initialized only once for each apache
process and then is re-used every time until that process
die. SiteConfig keeps a cache of all site configurations and makes them
available on demand. It is perfectly fine that one apache process would
serve more then one site, they won't step on each other toes.

=head1 UTILITY FUNCTIONS

XAO::SiteConfig provides some utility functions that do not require
any configuration object context.

=over

=cut

###############################################################################
package XAO::Projects;
use strict;
use XAO::Utils qw(:args);
use XAO::Errors qw(XAO::Projects);

##
# Prototypes
#
sub create_project (%);
sub drop_project ($);
sub get_current_project ();
sub get_current_project_name ();
sub get_project ($);
sub set_current_project ($);

##
# Exporting
#
use Exporter;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);
@ISA=qw(Exporter);
%EXPORT_TAGS=(
    all => [qw(
        create_project
        drop_project
        get_current_project
        get_current_project_name
        get_project
        set_current_project
    )],
);
@EXPORT_OK=@{$EXPORT_TAGS{all}};

##
# Package version for checks and reference
#
use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Projects.pm,v 2.1 2005/01/13 22:34:34 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

##
# Cache with all active project contexts and variable with current
# project name.
#
use vars qw(%projects_cache $current_project_name);

###############################################################################

=item create_project (%)

XXX

=cut

sub create_project (%) {
    shift if $_[0] eq 'XAO::Projects';
    my $args=get_args(\@_);
    my $name=$args->{name} ||
        throw XAO::E::Projects "create_project - no 'name'";
    my $obj=$args->{object} ||
        throw XAO::E::Projects "create_project - no 'object'";

    $projects_cache{$name} &&
        throw XAO::E::Projects "create_project - project '$name' already exists";

    $projects_cache{$name}=$obj;

    set_current_project($name) if $args->{set_current};

    $obj;
}

###############################################################################

=item drop_project ($)

XXX

=cut

sub drop_project ($) {
    shift if $_[0] eq 'XAO::Projects';
    my $name=shift ||
        throw XAO::E::Projects "drop_project - no project name given";

    delete $projects_cache{$name};
    $current_project_name=undef if defined($current_project_name) &&
                                   $current_project_name eq $name;
}

###############################################################################

=item get_current_project ()

XXX

=cut

sub get_current_project () {
    my $name=$current_project_name || 
        throw XAO::E::Projects "get_current_project - no current project";
    get_project($name);
}

###############################################################################

=item get_current_project_name ()

XXX

=cut

sub get_current_project_name () {
    $current_project_name;
}

###############################################################################

=item get_project ($)

Looks into pre-initialized configurations list and returns object if
found or undef if not.

Example:

 my $cf=XAO::Projects->get_projects('testsite');

=cut

sub get_project ($) {
    shift if $_[0] eq 'XAO::Projects';
    my $name=shift ||
        throw XAO::E::Projects "get_project - no project name given";
    $projects_cache{$name};
}

###############################################################################

=item set_current_project ($)

XXX

=cut

sub set_current_project ($) {
    shift if $_[0] eq 'XAO::Projects';
    my $name=shift ||
        throw XAO::E::Projects "set_current_project - no project name given";
    exists $projects_cache{$name} ||
        throw XAO::E::Projects "set_current_project - no such project ($name)";
    my $old_name=$current_project_name;
    $current_project_name=$name;
    $old_name;
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing by default. Use `:all' tag to import everything.

=head1 AUTHOR

XAO, Inc.: Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Have a look at L<XAO::Base> for the general overview.
