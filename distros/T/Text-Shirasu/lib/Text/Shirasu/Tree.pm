package Text::Shirasu::Tree;

=encoding utf-8

=head1 NAME

Text::Shirasu::Tree - Shirasu Tree Object for Text::CaboCha

=head1 SYNOPSIS

    use utf8;
    use feature ':5.10';
    use Text::Shirasu;
    my $ts = Text::Shirasu->new(cabocha => 1);
    
    $ts->parse("昨日の晩御飯は「鮭のふりかけ」と「味噌汁」だけでした。");

    for my $tree (@{ $ts->trees }) {
        say $tree->cid;
        say $tree->link;
        say $tree->head_pos;
        say $tree->func_pos;
        say $tree->score;
        say $tree->surface;
        say for @{ $tree->feature };
        say $tree->ne;
    }

=head1 DESCRIPTION

Text::Shirasu::Tree like L<Text::CaboCha::Token>, L<Text::CaboCha::Chunk>.

=cut

sub cid      { $_[0]->{cid}      }
sub link     { $_[0]->{link}     }
sub head_pos { $_[0]->{head_pos} }
sub func_pos { $_[0]->{func_pos} }
sub score    { $_[0]->{score}    }
sub surface  { $_[0]->{surface}  }
sub feature  { $_[0]->{feature}  }
sub ne       { $_[0]->{ne}       }

=head1 SEE ALSO

L<Text::Shirasu>

=head1 AUTHOR

Kei Kamikawa E<lt>x00.x7f@gmail.comE<gt>

=cut
1;
