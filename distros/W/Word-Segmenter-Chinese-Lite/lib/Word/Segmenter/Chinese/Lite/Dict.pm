package Word::Segmenter::Chinese::Lite::Dict;

use 5.008008;
use strict;
use warnings;
use JSON::XS qw(decode_json);

use Word::Segmenter::Chinese::Lite::Dict::Default;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(wscl_get_dict_default);

sub wscl_get_dict_default {
    my $dict_default_hashref =
      decode_json($Word::Segmenter::Chinese::Lite::Dict::Default::DICT_DEFAULT);
    return %$dict_default_hashref;
}

1;
__END__

=head1 NAME

Word::Segmenter::Chinese::Lite - Perl extension for blah blah blah

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
