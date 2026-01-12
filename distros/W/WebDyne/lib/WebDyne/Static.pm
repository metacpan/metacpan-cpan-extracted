#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


package WebDyne::Static;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  Utilities, constants
#
use WebDyne::Constant;
use WebDyne::Util;


#  Version information in a format
#
$VERSION='2.065';


#  Debug
#
debug("%s loaded, version $VERSION");


#  And done
#
1;

#------------------------------------------------------------------------------


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->()                             || return;
    my $meta_hr=$self->meta()                         || return err();
    $meta_hr->{'static'}=1;

}


sub handler : method {


    #  Handler is a no-op, all work is done by filter code. Need a handler so
    #  module is seen by WebDyne autoload method when tracking back through
    #  chained modules
    #
    my $self=shift();
    $self->static(1);
    $self->SUPER::handler(@_);

}
__END__


=pod

=head1 WebDyne::Static(3pm)

=head1 NAME

WebDyne::Static - WebDyne module to flag pages as static and compile once to HTML

=head1 SYNOPSIS

    #  Sample time.psp compiled to static HTML. Every time this page is requested it will show
    #  the same time - the time it was first run/compiled
    #
    <start_html>
    This page was first loaded at <? localtime ?>
    __PERL__
    use WebDyne::Static;

=head1 DESCRIPTION

The WebDyne::Static module will flag that all dynamic components of a page should be run at compile time, and the resulting HTML saved as a static file which will be served on subsequent requests.

The WebDyne framework will monitor for changes in the source file and recompile to a new HTML if the source .psp file is updated.

=head1 METHODS

=over

=item * B<<< static() >>>

Get or set the static attribute for this page. When setting the static attribute for a page it is only set for that instance of the page. To set a page as permanently static (except on source file update) use the WebDyne::Static module as per synopsis, or update the meta data via $self->meta->{'static'}=1;

=back

=head1 OPTIONS

WebDyne::Static does not expose any options to the import function when called via use.

=head1 AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut