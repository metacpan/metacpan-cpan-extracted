package Text::Shirasu::Node;

=encoding utf-8

=head1 NAME

Text::Shirasu::Node - Shirasu Node Object for Text::MeCab

=head1 SYNOPSIS

    use utf8;
    use feature ':5.10';
    use Text::Shirasu;
    my $ts = Text::Shirasu->new;
    
    $ts->parse("昨日の晩御飯は「鮭のふりかけ」と「味噌汁」だけでした。");

    for my $node (@{ $ts->nodes }) {
        say $node->id;
        say $node->surface;
        say $node->length;
        say $node->rlength;
        say for @{ $node->feature };
        say $node->rcattr;
        say $node->lcattr;
        say $node->stat;
        say $node->isbest;
        say $node->alpha;
        say $node->beta;
        say $node->prob;
        say $node->wcost;
        say $node->cost;
    }

=head1 DESCRIPTION

Text::Shirasu::Node like L<Text::MeCab::Node>.

=cut

sub id      { $_[0]->{id}      }
sub surface { $_[0]->{surface} }
sub feature { $_[0]->{feature} }
sub length  { $_[0]->{length}  }
sub rlength { $_[0]->{rlength} }
sub rcattr  { $_[0]->{rcattr}  }
sub lcattr  { $_[0]->{lcattr}  }
sub stat    { $_[0]->{stat}    }
sub isbest  { $_[0]->{isbest}  }
sub alpha   { $_[0]->{alpha}   }
sub beta    { $_[0]->{beta}    }
sub prob    { $_[0]->{prob}    }
sub wcost   { $_[0]->{wcost}   }
sub cost    { $_[0]->{cost}    }

=head1 SEE ALSO

L<Text::Shirasu>

=head1 AUTHOR

Kei Kamikawa E<lt>x00.x7f@gmail.comE<gt>

=cut
1;