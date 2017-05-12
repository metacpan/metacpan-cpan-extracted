=head1 NAME

XAO::DO::FS::Config - embeddable configuration object for XAO::FS

=head1 SYNOPSIS

 use XAO::Projects;
 use XAO::Objects;

 my $config=XAO::Objects->new(objname => 'Config',
                              sitename => 'test');

 XAO::Projects::create_project(name => 'test',
                               object => $config,
                               set_current => 1);

 my $fsconfig=XAO::Objects->new(objname => 'FS::Config',
                                odb_args => {
                                    dsn => 'OS:MySQL_DBI:test_os'
                                    user => 'test',
                                    password => 'TeSt',
                                });

 $config->embed(fs => $fsconfig);

 my $odb=$config->odb();

=head1 DESCRIPTION

The XAO::DO::FS::Config is normally used in larger projects
configurations that are persistent in memory. See L<XAO::DO::Config> for
more information on how embeddable configuration objects work.

=cut

###############################################################################
package XAO::DO::FS::Config;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::FS::Config);

##
# Prototypes
#
sub cleanup ($;@);
sub disable_special_access ($);
sub embeddable_methods ($);
sub enable_special_access ($);
sub new ($%);
sub odb ($;$);

##
# Package version for checks and reference
#
use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Config.pm,v 2.2 2008/02/21 02:22:15 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=head1 METHODS

=over

=cut

###############################################################################

=item cleanup ()

Calls reset() method on the odb to clean up the handler and prepare it
for the next session.

=cut

sub cleanup ($;@) {
    my $self=shift;
    $self->{'odb'}->reset(@_) if $self->{'odb'};
}

###############################################################################

=item disable_special_access ()

Disables use of odb() method to set a new value (this is the default
state).

=cut

sub disable_special_access ($) {
    my $self=shift;
    delete $self->{special_access};
}

###############################################################################

=item embeddable_methods ()

Used internally by global Config object, returns an array with
embeddable method names. Currently there is only one embeddable
method -- odb().

=cut

sub embeddable_methods ($) {
    qw(odb);
}

###############################################################################

=item enable_special_access ()

Enables use of odb() method to set a new value. Normally you do
not need this method.

Example:

 $config->enable_special_access();
 $config->odb($odb);
 $config->disable_special_access();

=cut

sub enable_special_access ($) {
    my $self=shift;
    $self->{special_access}=1;
}

###############################################################################

=item new ($$)

Creates a new empty configuration object. If odb_args is given then it
will connect to a database using these arguments.

Example:

 my $fsconfig=XAO::Objects->new(objname => 'FS::Config',
                                odb_args => {
                                    dsn => 'OS:MySQL_DBI:test_os'
                                    user => 'test',
                                    password => 'TeSt',
                                });

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    my $self=bless {},ref($proto) || $proto;

    if($args->{odb_args}) {
        $self->{odb}=XAO::Objects->new(merge_refs( { objname => 'FS::Glue' },
                                                   $args->{odb_args}));
    }

    $self;
}

###############################################################################

=item odb (;$)

Returns current database handler. If called with an argument and
speciall access is enabled then replaces database handler.

=cut

sub odb ($;$) {
    my $self=shift;

    return $self->{odb} unless @_;

    $self->{special_access} ||
        throw XAO::E::DO::FS::Config "odb - setting odb requires special access";

    $self->{odb}=shift;

    $self->{odb};
}

###############################################################################
1;
__END__

=back

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Config>.
