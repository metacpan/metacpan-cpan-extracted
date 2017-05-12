package WWW::Webrobot::XML2Tree;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004-2006 ABAS Software AG

=head1 NAME

WWW::Webrobot::XML2Tree - wrapper for L<XML::Parser>

=cut

use XML::Parser;


sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    $self->{parser} = new XML::Parser(Style => 'Tree', ErrorContext => 5);
    #$self->{u2i} = Unicode::Lite::convertor('utf8', 'latin1') if $has_converter;
    return $self;
}

sub parsefile {
    my ($self, $file) = @_;
    my $tree = $self->{parser}->parsefile($file);
    return $self->_parse0($tree);
}

sub parse {
    my ($self, $string) = @_;
    my $tree = $self->{parser}->parse($string);
    return $self->_parse0($tree);
}

sub _parse0 {
    my ($self, $tree) = @_;
    unshift @$tree, {};
    _delete_white_space($tree);
    #use Data::Dumper; print "DUMP: ", Dumper($tree);
    return $tree;
}


sub _delete_white_space {
    my ($tree) = @_;
    return _delete_white_space($tree->[1]) if scalar @$tree == 2; # root is special

    # Note: scalar @$tree % 2 == 1
    for (my $i = scalar @$tree; $i > 1; $i-=2) {
        if (! $tree->[$i-2] && $tree->[$i-1] =~ m/^\s*$/s) {
            # ??? optimize: splice in the middle of an array may be inefficient
            splice(@$tree, $i-2, 2);
        }
        elsif (ref $tree->[$i-1]) {
            _delete_white_space($tree->[$i-1]);
        }
    }
}


{
    my $s;

    sub _print_xml0 {
        my ($tree, $prefix) = @_;
        return "" if !$tree;
        my $p = "    " x $prefix;
        for (my $i = 0; $i < scalar @$tree; $i += 2) {
            my $tag = $tree->[$i];
            my $content = $tree->[$i+1];
            if (ref $content) {
                my $attributes = $content->[0];
                my $attr = "";
                foreach (sort keys %$attributes) {
                    my $v = $attributes->{$_};
                    $v =~ s/'/\\'/g;
                    $attr .= " $_='$v'";
                }
                my @c = @$content[1 .. scalar @$content-1];
                if (scalar @c) {
                    $s .= "$p<$tag$attr>\n";
                    _print_xml0(\@c, $prefix+1);
                    $s .= "$p</$tag>\n";
                }
                else {
                    $s .= "$p<$tag$attr/>\n";
                }
            }
            elsif (defined $content) { # $tag == 0
                $content =~ s/^\s+//;
                $content =~ s/\s+$//;
                $s .= "$content\n";
            }
        }
        return $s;
    }

    sub print_xml {
        $s = "";
        my ($tree) = @_;
        _print_xml0($tree, 0);
        return $s;
    }

}


1;
