package Software::License::CCpack;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.11'; # VERSION
# ABSTRACT: Software::License pack for Creative Commons' licenses

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::License::CCpack - Software::License pack for Creative Commons' licenses

=head1 SYNOPSIS

    use Software::License::CC_BY_4_0;
 
    my $license = Software::License::CC_BY_4_0->new({
       holder => 'Brendan Byrd',
    });
 
    print $license->fulltext;

=head1 DESCRIPTION

This "license pack" contains all of the licenses from Creative Commons,
except for CC0, which is already included in L<Software::License>.

Note that I don't recommend using these licenses for your own CPAN
modules.  (Most of the licenses aren't even compatible with CPAN.)
However, S:L modules are useful for more than mere L<CPAN::Meta>-E<gt>license
declaration, so these modules exist for those other purposes.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Software-License-CCpack>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Software::License::CCpack/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/Software-License-CCpack/issues>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 CONTRIBUTOR

=for stopwords Zoffix Znet

Zoffix Znet <cpan@zoffix.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brendan Byrd.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 3, June 2007

=cut
