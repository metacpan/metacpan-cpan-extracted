package WordListUtil::CLI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-22'; # DATE
our $DIST = 'WordListUtil-CLI'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter 'import';
our @EXPORT_OK = qw(instantiate_wordlist);

sub instantiate_wordlist {
    my ($arg, $ignore) = @_;

    my ($wlname, $wlargs);
    if ($arg =~ /(.+?)=(.*)/) {
        $wlname = $1;
        $wlargs = [split /,/, $2];
    } else {
        $wlname = $arg;
        $wlargs = [];
    }

    my $mod = "WordList::$wlname";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    my $wlobj;
    eval {
        require $modpm;
        $wlobj = $mod->new(@{ $wlargs });
    };
    if ($@) {
        if ($ignore) {
            log_warn  "Cannot load/instantiate wordlist class $arg: $@";
            return;
        } else {
            log_fatal "Cannot load/instantiate wordlist class $arg: $@";
            die;
        }
    }
    $wlobj;
}

1;
# ABSTRACT: Some utility routines related to WordList::* and the CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListUtil::CLI - Some utility routines related to WordList::* and the CLI

=head1 VERSION

This document describes version 0.001 of WordListUtil::CLI (from Perl distribution WordListUtil-CLI), released on 2020-05-22.

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 instantiate_wordlist

Usage:

 my $wl = instantiate_wordlist($name [ , $ignore ]);

Examples:

 $wl1 = instantiate_wordlist("EN::Enable"); # dies on failure
 $wl2 = instantiate_wordlist("EN::Enable", 1); # return undef on failure
 $wl3 = instantiate_wordlist("MetaSyntactic::Any=theme,dangdut");

Load WordList::* module and instantiate the class. In the above example, C<$wl1>
will be an instance of L<WordList::EN::Enable> class.

Like Perl's C<-M> option, you can also pass parameters to a parameterized
wordlist using the C<=val1,val2,...> syntax (see C<$wl3> example above).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListUtil-CLI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListUtil-CLI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListUtil-CLI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
