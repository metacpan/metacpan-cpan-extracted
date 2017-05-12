package WWW::Mechanize::Script::Plugin::TextMatchTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

# ABSTRACT: check for required/forbidden text in response

use Params::Util qw(_ARRAY0);

our $VERSION = '0.100';

use 5.014;


sub check_value_names
{
    return qw(text_forbid text_require);
}


sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $text_require = $self->get_check_value( $check, "text_require" );
    my $text_forbid  = $self->get_check_value( $check, "text_forbid" );
    my $ignore_case = $self->get_check_value_as_bool( $check, "ignore_case" );
    my $content = $mech->is_html() ? $mech->text() : $mech->content();

    defined($text_require) and ref($text_require) ne "ARRAY" and $text_require = [$text_require];
    defined($text_forbid)  and ref($text_forbid)  ne "ARRAY" and $text_forbid  = [$text_forbid];

    my @match_fails;
    my $code = 0;
    my $case_ign = $ignore_case ? "(?i)" : "";
    my @msg;
    foreach my $text_line ( @{$text_require} )
    {
        if ( $content !~ m/$case_ign\Q$text_line\E/ )
        {
            my $err_code = $self->get_check_value( $check, "text_require_code" ) // 1;
            $code = &{ $check->{compute_code} }( $code, $err_code );
            push( @match_fails, $text_line );
        }
    }
    @match_fails
      and push( @msg,
                    "required text "
                  . join( ", ", map { "'" . $_ . "'" } @match_fails )
                  . " not found in received content" );

    @match_fails = ();
    foreach my $text_line ( @{$text_forbid} )
    {
        if ( $content =~ m/$case_ign\Q$text_line\E/ )
        {
            my $err_code = $self->get_check_value( $check, "text_forbid_code" ) // 1;
            $code = &{ $check->{compute_code} }( $code, $err_code );
            push( @match_fails, $text_line );
        }
    }
    @match_fails
      and push( @msg,
                    "forbidden text "
                  . join( ", ", map { "'" . $_ . "'" } @match_fails )
                  . " found in received content" );

    if ( $code or @msg )
    {
        return ( $code, @msg );
    }

    return (0);
}

1;

__END__

=pod

=head1 NAME

WWW::Mechanize::Script::Plugin::TextMatchTest - check for required/forbidden text in response

=head1 VERSION

version 0.101

=head1 METHODS

=head2 check_value_names()

Returns qw(text_forbid text_require).

=head2 check_response(\%check,$mech)

This method checks whether any line of I<text_forbid> is found in received
content (and accumulates I<text_forbid_code> into I<$code> when found) or
any line of I<text_require> missing in content (and accumulates
I<text_forbid_code> into I<$code> when missing).

In case of an HTML response, the received content is rendered into plain
text before searching for matches.

Return the accumulated I<$code> and appropriate constructed message, if
any match approval failed.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Script or by email
to bug-www-mechanize-script@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jens Rehsack <rehsack@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
