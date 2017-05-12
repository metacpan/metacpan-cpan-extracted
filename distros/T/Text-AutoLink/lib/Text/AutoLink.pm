package Text::AutoLink;
use strict;
use warnings;
use 5.006;
use vars qw($VERSION);
use HTML::TreeBuilder;
use Module::Pluggable
    require => 0,
    search_path => 'Text::AutoLink::Plugin',
    sub_name => 'available_plugins',
;

BEGIN {
    $VERSION = '0.04000'
}

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = bless {
        plugins => [],
    }, $class;

    $args{plugins} ||= [$class->available_plugins];
    foreach my $p (@{$args{plugins}}) {
        if (! ref $p) {
            eval "require $p";
            die if $@;
            $p = $p->new;
        }

        push @{$self->{plugins}}, $p;
    }

    return $self;
}

sub plugins
{
    my $self = shift;
    wantarray ? @{$self->{plugins}} : $self->{plugins};
}

sub _parse
{
    my $self = shift;
    my $x = shift;

    if ($x->attr('_tag') eq 'a') {
        return;
    }

    my @list = $x->content_list;
    for(my $i = 0; $i < @list; $i++) {
        my $c = $list[$i];
        if (ref $c) {
            $self->_parse($c);
        } else {
            foreach my $p ($self->plugins) {
                next unless $c;
                next unless $p->process(\$c);
                my $subtree = HTML::TreeBuilder->new_from_content($c);
                $self->_parse($subtree);
                $x->splice_content($i, 1, $subtree);
            }
        }
    }
}

sub parse_file
{
    my $self = shift;
    my $file = shift;
    open my $fh, "<", $file or die "Failed to open file $file: $!";
    $self->parse_fh($fh);
}

sub parse_fh
{
    my $self = shift;
    my $fh   = shift;
    my $text = join '', <$fh>;
    return $self->parse_string($text);
}

sub parse_string
{
    my $self = shift;
    my $string = shift;

    my $ret;
    my $tree = HTML::TreeBuilder->new_from_content($string);
    $self->_parse($tree);
    foreach my $i ($tree->look_down(_implicit => 1)) {
        $i->replace_with_content if $i->parent;
    }
    if ($tree->implicit) {
        $ret = join('',
            map { ref $_ ? $_->as_HTML : $_ } $tree->content_list );
    } else {
        $ret = $tree->as_HTML;
    }
    $tree->delete;
    return $ret;
}

1;

__END__

=head1 NAME

Text::AutoLink - Automatically Linkfy

=head1 SYNOPSIS

  use Text::AutoLink;
  my $auto = Text::AutoLink->new;
  my $text = $auto->parse_string('http://search.cpan.org');
  # '<a href="http://search.cpan.org">http://search.cpan.org</a>'

  my $auto = Text::AutoLink->new(
    plugins => [
        'Text::AutoLink::Plugin::HTTP'
        Text::AutoLink::Plugin::FTP->new(%args)
    ]
  );

=head1 DESCRIPTION

Text::AutoLink is a module inspired by Text::Hatena. I just wanted to
automatically make HTML links in arbitrary text that is not in Text::Hatena
format, so here it is.

Text::AutoLink is designed such that it can handle plain text or HTML text,
with the focus on allowing arbitrary plugins to handle the transformation.

=head1 METHODS

=head2 new(%args)

Creates a new Text::AutoLink object.

=over 4

=item plugins ARRAYREF

You may specify the list of plugins that you want to apply on a text.
If you don't specify this parameter, Text::AutoLink will include all
the plugins that are available under Text::AutoLink::Plugin namespace.

=back

=head2 plugins

Returns the list of plugins that are associated with this instance.

=head2 parse_string SCALAR

Parses the given string and auto-links strings that are not already
linked. Returns the modified string.

=head2 parse_file SCALAR

Parses the given file.

=head2 parse_fh FILEHANDLE

Parses the given file handle.

=head1 CAVEATS

Text::AutoLink internally uses HTML::TreeBuilder, so the resulting text may
slightly be different from the input. In my experience this is usually not
a problem, but if you are being strict it may bite you.

=head1 AUTHOR

Copyright (c) 2006-2007 Daisuke Maki E<lt>daisuke@endeworks.jp<gt>. 

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
