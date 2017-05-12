package Text::Livedoor::Wiki::Plugin::Inline::Footnote;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{\(\(((?:(?<!\)\)).)*)\)\)});
__PACKAGE__->n_args(1);

sub process {
    my ( $class , $inline , $line ) = @_;
    $line = $inline->parse($line);
    my $scratchpad = $Text::Livedoor::Wiki::scratchpad ;
    $scratchpad->{footnotes} ||= [];
    push @{$scratchpad->{footnotes}},$line;
    my $cnt = scalar  @{$scratchpad->{footnotes}};
    return qq|<a href="#footer-footnote$cnt" name="footnote$cnt">*$cnt</a>|;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Footnote Footnote Inline Plugin

=head1 DESCRIPTION

This plugin is implement with really bad manner. Anyway, with this plugin , you can use footnote.

=head1 SYNOPSIS

 ((polocky is a charactor for livedoor wiki))polocky is...

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
