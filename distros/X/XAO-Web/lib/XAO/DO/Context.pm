=head1 NAME

XAO::DO::Context - base class to access site context

=head1 SYNOPSIS

    package XAO::DO::Blah;
    use XAO::Objects;
    use base XAO::Objects->load(objname => 'Context');

    sub method() {
        my $self=shift;

        my $config=$self->siteconfig;

        my $cgi=$self->cgi;

        my $clipboard=$self->clipboard;
    }

=head1 DESCRIPTION

This is a convenience base class for accessing site configuration,
clipboard, and CGI object.

=over

=cut

###############################################################################
package XAO::DO::Context;
use strict;
use warnings;
use XAO::Projects;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Atom');

###############################################################################

=item cgi ()

Convenience shortcut to get CGI object from the site configuration.

=cut

sub cgi ($;@) {
    my $self=shift;
    return $self->siteconfig->cgi(@_);
}

###############################################################################

=item clipboard ()

Convenience shortcut to site configuration's clipboard() method.

=cut

sub clipboard (@) {
    my $self=shift;
    $self->siteconfig->clipboard(@_);
}

###############################################################################

=item siteconfig ()

Convenience shortcut to the current site configuration.

=cut

sub siteconfig ($) {
    my $self=shift;
    return XAO::Projects::get_current_project();
}

###############################################################################
1;
