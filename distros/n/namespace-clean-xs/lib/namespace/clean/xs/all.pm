package namespace::clean::xs::all;
use strict;
use namespace::clean::xs ();

BEGIN {
    our $VERSION = $namespace::clean::xs::VERSION;

    $INC{'namespace/clean.pm'} = $INC{'namespace/clean/xs.pm'};

    for my $glob (qw/import unimport clean_subroutines get_functions get_class_store/) {
        no strict 'refs';
        *{"namespace::clean::$glob"} = *{"namespace::clean::xs::$glob"}{CODE};
    }

    $namespace::clean::VERSION = 0.26; # latest as of times of writing
}

1;
__END__

=head1 NAME

namespace::clean::xs::all - Use XS for namespace::clean globally

=head1 SYNOPSIS

    use namespace::clean::xs::all; # at the beginning of your application

=head1 DESCRIPTION

This module replaces L<namespace::clean> with L<namespace::clean::xs> globally,
so you won't have to search-and-replace usage lines. All L<namespace::clean>
unfinished calls will be finished by non-xs version.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Sergey Aleynikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
