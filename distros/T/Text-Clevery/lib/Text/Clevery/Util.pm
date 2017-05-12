package Text::Clevery::Util;
use strict;
use warnings;

use parent qw(Exporter);

our @EXPORT_OK = qw(
    safe_join
    safe_cat
    make_tag
    true
    false
    ceil floor
);

use Text::Xslate::Util qw(
    p
    mark_raw html_escape
);


sub true()  { 1 }
sub false() { 0 }

sub make_tag {
    my $name    = shift;
    my $content = shift;
    my $attrs = '';
    while(my($name, $value) = splice @_, 0, 2) {
        if(defined $value) {
            $attrs .= sprintf q{ %s="%s"}, html_escape($name), html_escape($value);
        }
    }
    if(defined $content) {
        return mark_raw(sprintf q{<%1$s%2$s>%3$s</%1$s>}, $name, $attrs, html_escape($content));
    }
    else {
        return mark_raw(sprintf q{<%1$s%2$s />}, $name, $attrs);
    }
}

sub safe_join {
    my $sep = shift;
    return mark_raw join html_escape($sep)->as_string,
        map { html_escape($_)->as_string } @_;
}

sub safe_cat {
    return mark_raw join '',
        map { html_escape($_)->as_string } @_;
}

sub floor {
    my($n) = @_;
    return int(int($n) > $n ? $n - 1 : $n);
}

sub ceil {
    my($n) = @_;
    return int(int($n) < $n ? $n + 1 : $n);
}
1;
__END__

=head1 NAME

Text::Clevery::Util - Utilities for Text::Clevery

=head1 SEE ALSO

L<Text::Clevery>

=cut
