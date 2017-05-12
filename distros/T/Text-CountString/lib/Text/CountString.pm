package Text::CountString;
use strict;
use warnings;
use utf8;

our $VERSION = '0.03';

my $COUNTER;

sub import {
    my ($class, $implement) = @_;

    $COUNTER = ($implement && $implement eq 'split')
             ? \&_split_implement
             : \&_regexp_implement;

    my $caller = caller;
    no strict 'refs'; ## no critic
    *{"${caller}::count_string"} = \&count_string;
}

sub _regexp_implement {
    return 0 if !defined($_[0]) || $_[0] eq '';
    return 0 if !defined($_[1]) || $_[1] eq '';
    return () = ($_[0] =~ /\Q$_[1]\E/g);
}

sub _split_implement {
    return 0 if !defined($_[0]) || $_[0] eq '';
    return 0 if !defined($_[1]) || $_[1] eq '';
    my @list = split /\Q$_[1]\E/, $_[0], -1;
    return scalar(@list) - 1;
}

sub count_string {
    my $target_text = shift;

    my $result;

    if (@_ == 1) {
        $result = $COUNTER->($target_text, $_[0]);
    }
    else {
        for my $string (@_) {
            $result->{$string} = $COUNTER->($target_text, $string);
        }
    }
    return $result;
}

1;

__END__

=head1 NAME

Text::CountString - the frequency count of strings


=head1 SYNOPSIS

    use Text::CountString;

    warn count_string("There is more than one way to do it", "o"); # 4


=head1 DESCRIPTION

Text::CountString is the module for counting the frequency of words.


=head1 METHOD

below methods are exported.

=head2 count_string($target_text, $string)

    warn count_string("a b c d a b c", "a"); # 2

To get the frequency count of strings

Also you can get counts of bulk strings

    my $result = count_string(
        "There is more than one way to do it.",
        "o", "e", "h",
    );
    warn $result->{o}; # 4
    warn $result->{e}; # 4
    warn $result->{h}; # 2


=head1 CHANGE IMPLEMENTS

This module can switch implements for counting string.

By default, to count strings is invoked by the regexp implement. Generally, It's fast enough.

    use Text::CountString

However, if you can guess that there are many many matched strings, then the 'C<split> implement' is faster than regexp implement.
So the internal implement can be switched 'regexp' to 'split' like below.

    use Text::CountString qw/split/;


=head1 REPOSITORY

Text::CountString is hosted on github
<http://github.com/bayashi/Text-CountString>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
