package XML::Essex::Constants;

$VERSION = 0.000_1;

=head1 NAME

XML::Essex::Constants - Export a few constants used within Essex

=head1 SYNOPSIS

    use XML::Essex::Constants;

=head1 DESCRIPTION

This is really for internal use only and is not needed by outside
callers.  Subclasses of XML::Filter::Handler may also need this.

Hacker's note: see the source for some minor magic used in debugging
and testing.

=over

=cut

use Carp qw( croak );

my %exports = map {
        ( $_ => undef );
    } qw( BOD EOD debugging SEPPUKU threaded_essex );

sub import {
    my $class = shift;
    my $caller = caller;
    *{"${caller}::$_"} = \&$_
        for ! @_
            ? keys %exports
            : grep {
                exists $exports{$_} || croak "$_ not exported by $class";
            } @_;
}

=item debugging

Returns 1 if $ENV{ESSEXDEBUG}, for now.

=cut

BEGIN {
    eval join 
        $ENV{ESSEXDEBUG}
            ? $ENV{ESSEXDEBUG} eq "VARY"
                ? '$ENV{ESSEXDEBUG}'
                : 1
            : 0,
        "sub debugging() {",
        "} 1"
    or die $@;
}

=item BOD

BOD is an event sent before the first event (a set_document_locator or
start_document) in a document.  It is used to sync up the slave
thread.  Right now, this means that any events before the first
set_document_locator or start_document are lost.

=cut

sub BOD() { "start of XML document" }

=item EOD

EOD is sent after the end_document to flag the fact that there
are no more events coming.  This is not necessary, as the child
could trigger off the end_document, but it is convenient because
the child does not need to maintain any EndDocumentSeen state.
It also opens up the door for a "reset" method on the parent to force
the child's main() to exit, if we ever need that.

=cut

sub EOD()     { "end of XML document" }

=item SEPPUKU

SEPPUKU is sent if the parent is DESTROYed so the child thread may
follow it in to oblivion, with honor.

=cut

sub SEPPUKU() { "end of parent life" }

=item threaded_essex

Returns 1 if Essex should use threads.

=cut

our $threading;  ## Used only by t/XML-Handler-Essex-Threaded.t

eval join
    exists $threads::{VERSION}
        && defined $threads::VERSION
        && $threads::VERSION >= 0.99
        ?  defined $threading
            ? '$threading'
            : 1
        : 0,

    "sub threaded_essex() {",
    "} 1"
    or die $@;

=back

=head1 LIMITATIONS

Does not pay attention to the parameter list passed with use().  This
is speedy and light, but not kind.  It's for internal use only, however,
and this should be sufficient.

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
