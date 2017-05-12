package Test::HTML::Tidy;

use strict;

use Test::Builder;
use Exporter;

use HTML::Tidy 1.00;

use vars qw( @ISA $VERSION @EXPORT );

@ISA = qw( Exporter );

=head1 NAME

Test::HTML::Tidy - Test::More-style wrapper around HTML::Tidy

=head1 VERSION

Version 1.28

    $Header: /home/cvs/test-html-tidy/Tidy.pm,v 1.4 2004/02/26 06:12:36 andy Exp $

=cut

$VERSION = '1.00';

my $Tester = Test::Builder->new;

=head1 SYNOPSIS

    use Test::HTML::Tidy tests => 4;

    my $page = build_a_web_page();
    html_tidy_ok( $page, 'Built page properly' );

=head1 DESCRIPTION

Handy way to check that HTML is valid, according to L<HTML::Tidy>.
It is built with L<Test::Builder> and plays happily with L<Test::More>
and friends.

If you are not already familiar with L<Test::More> now would be the time
to go take a look.

=head1 EXPORT

C<html_tidy_ok>

=cut

@EXPORT = qw( html_tidy_ok );

sub import {
    my $self = shift;
    my $pack = caller;

    $Tester->exported_to($pack);
    $Tester->plan(@_);

    $self->export_to_level(1, $self, @EXPORT);
}

=head2 html_tidy_ok( [$tidy, ] $html, $name )

Checks to see if C<$html> contains valid HTML.  C<$html> being blank is OK.
C<$html> being undef is not.

If you pass an HTML::Tidy object, C<html_tidy_ok()> will use that for its
settings.  The I<$html> will get passed through I<$tidy>.

    my $tidy = new HTML::Tidy;
    $tidy->ignore( type => TIDY_WARNING );
    html_tidy_ok( $tidy, $content, "Web page passes without errors" );

Otherwise, C<html_tidy_ok> will use the default rules.

    html_tidy_ok( $content, "Web page passes ALL tests" );

Note that if you pass in your own HTML::Tidy object, C<html_tidy_ok()>
will clear its errors before using it.

=cut

sub html_tidy_ok {
    my $tidy;

    if ( ref($_[0]) eq "HTML::Tidy" ) {
        $tidy = shift;
        $tidy->clear_messages();
    } else {
        $tidy = HTML::Tidy->new;
    }
    my $html = shift;
    my $name = shift;

    my $ok = defined $html;
    if ( !$ok ) {
        $Tester->ok( 0, $name );
    } else {
        $tidy->parse( $0, $html );
        my $nerr = scalar $tidy->messages;
        $ok = !$nerr;
        $Tester->ok( $ok, $name );
        if ( !$ok ) {
            my $msg = "Messages:";
            $msg .= " $name" if $name;
            $Tester->diag( $msg );
            $Tester->diag( $_->as_string ) for $tidy->messages;
        }
    }

    return $ok;
}

=head1 Bugs

Please report any bugs or feature requests to
C<bug-test-html-tidy@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 Author

Andy Lester, C<< <andy@petdance.com> >>

=head1 Copyright & License

Copyright 2004 Andy Lester, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=cut

1;
