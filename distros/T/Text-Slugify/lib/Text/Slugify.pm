package Text::Slugify;
# ABSTRACT: create URL slugs from text
$Text::Slugify::VERSION = '0.002';
use warnings;
use strict;

use Exporter 'import';
our $unaccent = 0;

if(eval "require Text::Unaccent::PurePerl") {
    $unaccent = 1;
}
our @EXPORT_OK = qw(slugify);

sub slugify {
    my ($text) = @_;

    if($unaccent) {
        $text = Text::Unaccent::PurePerl::unac_string($text);
    }

    $text =~ s/[^a-z0-9]+/-/gi;
    $text =~ s/^-?(.+?)-?$/$1/;
    $text =~ s/^(.+)$/\L$1/;
    return $text;
}

1;

__END__

=pod

=head1 NAME

Text::Slugify - create URL slugs from text

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Text::Slugify 'slugify';

    my $slug = slugify("You won't believe what happened next!");

=head1 DESCRIPTION

Takes a bit of text, removes puncuation, spaces and other junk to produce a string suitable for use in a URL.

If you have L<Text::Unaccent::PurePerl> installed it will 'unaccent' accented characters instead of removing them.

=head1 BUGS

There's probably a huge amount of inputs for which nothing sane is produced. Patches are welcome!

Please submit bug reports and patches to L<https://github.com/Text-Slugify/issues>.

=head1 AUTHOR

Robert Norris E<lt>rob@eatenbyagrue.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Robert Norris.

This module is free software, you can redistribute it and/or modify it under the same terms as Perl itself.
