package WWW::BugMeNot;
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(password);
our $VERSION = '0.02';

use strict;
use warnings;
use LWP::Simple;
use HTML::TokeParser;


sub password {
    my $url = $_[0];
    my $retrieved_bugmenot_page = &retrieve_bugmenot_url($url);
    my @userpass = &parse_bugmenot_url($retrieved_bugmenot_page);
    return @userpass;
}


sub retrieve_bugmenot_url {
    my $url = $_[0];
    my $retrieved_page = get ("http://bugmenot.com/view.php?url=$url") or die("Could not retrieve http://bugmenot.com/view.php?url=$url");
    return $retrieved_page;
}


sub parse_bugmenot_url {
    my $page = $_[0];
    my $stream = HTML::TokeParser->new(\$page) or die("Parsing Error: $!");
    $stream -> get_tag("dd");
    my @userpass;
    $userpass[0] = $stream -> get_text("br");
    $userpass[1] = $stream -> get_text("/dd");
    return @userpass;
}



1;
__END__


=head1 NAME

WWW::BugMeNot - An interface to the BugMeNot.com website. Given a URL that requires a registration, it returns a donated username and password

=head1 VERSION

0.01 - September 12

=head1 SYNOPSIS

    use WWW::BugMeNot;
    my $url = "http://www.nytimes.com";
    my @username_and_password = password($url);
    print "Username = $username_and_password[0]";
    print "Password = $username_and_password[1]";

=head1 DESCRIPTION

Many websites require compulsory registration before they will allow readers to access their pages. This is bad for a variety of reasons, and so many people use BugMeNot.com to share common usernames and passwords. This module provides a programmatic interface to BugMeNot.

=head1 INTERFACE

WWW::BugMeNot presents one method to the outer world:

    password("$url")

Which takes a URL, and returns an array containing a username and password. The username is in $array[0] and the password in $array[1]

That's it. There is currently no checking for sites that are not listed on BugMeNot, and the module will do horrid things upon finding such a beast.

=head1 PREREQUISITES

L<LWP::Simple>, L<HTML::TokeParser>

=head1 AUTHOR

Ben Hammersley C<E<lt>ben@benhammersley.comE<gt>>

=head1 BUGS

Potentially many. This module uses screen-scraping to retrieve the passwords. If BugMeNot change their pages, the module will break.

Please use the CPAN bugtracking system at http://rt.cpan.org/ to report bugs, or make suggestions.

=head1 SEE ALSO

http://www.bugmenot.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ben Hammersley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
