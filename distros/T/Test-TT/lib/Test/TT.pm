package Test::TT;

use strict;
use warnings;

use Test::Builder;
use Exporter;

use Template;

use vars qw( @ISA $VERSION @EXPORT );

@ISA = qw( Exporter );

=head1 NAME

Test::TT - Test::More-style wrapper around Template

=head1 VERSION

Version 0.01

=cut

$VERSION = '0.01';

my $TEST = Test::Builder->new;

=head1 SYNOPSIS

    use Test::Template tests => 1;

    my $table = build_display_table();
    html_ok( $table, 'Built display table properly' );

=head1 DESCRIPTION

This module provides a few convenience methods for testing exception
based code. It is built with L<Test::Builder> and plays happily with
L<Test::More>.

=head1 EXPORT

C<tt_ok>

=cut

@EXPORT = qw( tt_ok );

sub import {
    my $self = shift;
    my $pack = caller;

    $TEST->exported_to($pack);
    $TEST->plan(@_);

    $self->export_to_level( 1, $self, @EXPORT );

    return;
}

=head2 tt_ok( [$tt_options, ] $tt_data, $name, $vars, $output )

Checks to see that C<$tt_data> is valid TT. 

Checks to see if C<$tt_data> is valid TT.  C<$tt_data> being blank is OK.
C<$tt_data> being undef is not. C<$tt_data> will be passed directly to 
Template Toolkit, so you should pass a filename, a text reference or a
file handle (GLOB).

If you pass a Template object, (<tt_ok()> will use that for parsing.

C<$vars> will be passed to the template object, and should be a hashref. Can be skipped.

C<$output> will be passed to the template object, and specifies what to the do with the output. 
If not present tt_ok will silently eat all the output.

=cut

sub tt_ok {
    my $template;

    my $ok = 1;
    if ( ref( $_[0] ) eq 'Template' ) {
        $template = shift;
    }
    else {
        $template = Template->new();
        if ( !$template ) {
            $ok = 0;
        }
    }
    my $tt_data = shift;
    my $name    = shift;
    my $vars    = shift;
    my $output  = shift;
    my $data;

    if ( !$ok ) {
        $TEST->ok( 0, $name );
        my $msg = 'Errors:';
        $msg .= " $name" if $name;
        $TEST->diag($msg);
        $TEST->diag( Template->error() );
    }

    if ( !$output ) {
        $output = \$data;
    }

    if ($ok) {
        $ok = defined $tt_data;
        if ( !$ok ) {
            $TEST->ok( 0, $name );
        }
    }

    if ($ok) {
        $ok = $template->process( $tt_data, $vars, $output );
        $TEST->ok( $ok, $name );
        if ( !$ok ) {
            my $msg = 'Errors:';
            $msg .= " $name" if $name;
            $TEST->diag($msg);
            $TEST->diag( $template->error() );
        }
    }

    return $ok;
}

=head1 BUGS

Please report any bugs to (patches welcome):

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Install-Debian


=head1 SEE ALSO

L<Template>


=head1 ACKNOWLEGEMENTS

Thanks to chromatic and Michael G Schwern for the excellent Test::Builder.

Thanks to Andy Wardley for Template Toolkit.

Thanks to Adrian Howard for writing Test::Exception, from which most of
this module is taken.

=head1 AUTHOR

BjE<oslash>rn-Olav Strand E<lt>bo@startsiden.noE<gt>

=head1 LICENSE

Copyright 2009 by BjE<oslash>rn-Olav Strand <bo@startsiden.no>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=cut

1;

