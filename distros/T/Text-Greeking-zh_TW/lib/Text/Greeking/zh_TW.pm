package Text::Greeking::zh_TW;
use common::sense 2.02;
use 5.008;
use utf8;

use List::Util qw(shuffle);

our $VERSION = '1.0';

sub new {
    my $class =shift;
    my $self = bless {}, $class;
    srand;
    $self->init;
}

sub init {
    $_[0]->paragraphs(2,8);
    $_[0]->sentences(2,8);
    $_[0]->words(5,15);
    $_[0];
}

sub paragraphs { $_[0]->{paragraphs} = [ $_[1], $_[2] ] }
sub sentences { $_[0]->{sentences} = [ $_[1], $_[2] ] }
sub words { $_[0]->{words} = [ $_[1], $_[2] ] }

sub generate {
    my $self = shift;
    my($paramin,$paramax) = @{$self->{paragraphs}};
    my($sentmin,$sentmax) = @{$self->{sentences}};
    my $pcount = int(rand($paramax-$paramin+1)+$paramin);
    my $out = "";
    for (my $x=0; $x < $pcount; $x++) {
        my $scount = int(rand($sentmax-$sentmin+1)+$sentmin);
        for (my $y=0; $y < $scount; $y++) {
            $out .= random_sentence();
        }
        $out .= "\n\n";
    }
    $out;
}

sub _generate {
    my $template = corpus();
    $template =~ s{ \p{Han} }{ random_word() }xegs;
    return $template;
}

{
    my @han = ();
    sub random_word {
        unless (@han) {
            my @char = split "", corpus();
            @han = shuffle grep /\p{Han}/, @char;
        }
        shift @han
    }

    my @text = ();
    sub random_paragraph {
        unless (@text) {
            @text = shuffle split /\n+/, _generate();
        }
        shift @text;
    }

    my @sentence = ();
    sub random_sentence {
        unless (@sentence) {
            @sentence = split /。|？/, random_paragraph()
        }
        (shift(@sentence) || random_sentence() ) . random_punct();
    }

    sub random_punct {
        my $r = int(rand(20));
        if ($r == 1) {
            "！"
        }
        elsif ($r == 2) {
            "？"
        }
        else {
            "。"
        }

    }
}

my $corpus;
sub add_source {
    my ($self, $source) = @_;
    if (ref $source) {
        warn "err - source sould be a scalar.";
        return;
    }

    $corpus .= $source;
    return $self;
}

# lukhnos.org
sub corpus {
    if ($corpus) {
        return $corpus;
    } else {
        return <<CORPUS;

她終於有勇氣重新開箱，拾出當年所封存的那些記憶。只不過那也是最後一次，那些記憶在開箱之後，不再散發香水的味道；所拾出的東西，也就直接進了垃圾袋。

她看著垃圾車的壓縮機輾壓過那些她曾經珍惜過的曾經，然後看著垃圾車駛離。「就這樣，」她想。

因為那一年某堂粗淺的人類學課程，讓她心生一計，開始買一個又一個的箱子，把那些碰觸不得的潰爛和難堪，給一一封存起來。離別的痛苦，伴隨著的是碰不得的屍體：生存與死亡的界限，生食與熟食，潔淨與塵垢。葬禮與守喪的時間延遞，是一種轉化的過程：當不潔的屍身再度化為了塵土，不可碰觸的終將化為了無所謂的──可以如清掃家門般將之一掃而出。

她花了整整一年的時間，把那些曾經有過的曾經給一一打包、整理、刷洗、更衣，她一邊整理一邊自言自語，哪些是她的初次、她的愚念、她的痴心、她的自甘墮落。來來往往這麼多年，她必須精心計算，購足相當數量的箱子、膠布、標籤紙，那些不可能再穿的衣服也得一一送洗、折疊、包裝。她編目，用圖書館員的耐心一一貼上標籤，空出架位，測量每件物品的大小──用了一半的香水瓶、一件毛衣、一本書、一張大頭照、一張小紙條、兩片CD、一盒太陽眼鏡…… 曾經她一度想將之一一整理販售，但是想到這世界之小，這些物品未來的主人將來說不定碰到原主，或者就只是那些人會在拍賣網站上看到。她雖然復仇心重，卻還是對散心大拍賣這種事有所保留。

全部封箱完的那一天，她完全崩潰，累倒在床上，高燒了整整兩天。

然後這一切都結束了。至少，暫時如此。

那幾年中，箱子就放在她的床下。她家人以為是學生時代的筆記書本，不曾多問。起先她還有睡在回憶上的感覺，之後她搬家、換工作，完完全全與箱子的世界分離了開來，也避開所有重新和那世界回復聯結的可能。不聯絡、不寫信、不和任何可能碰觸到箱子世界的人往來。稍微一點點可能觸及的預感（她這幾年因此嗅覺變得無比敏銳），就立刻送入隱形或擋駕名單。

只有在很後來，當她開始想要做更遠距離的移動時，才又突然想起那些箱子的存在。那些丟不掉搬不走的掛念，任何一個箱子都是一條連往過去的通道。那些被貼上封條的通道不會讓她陷落，她感到安全，然而她也不確定她是否哪天會有勇氣，重新開箱啟動這一切，再次於經驗的記憶中走一遭。

一直到了那一天。

她本來還想再拍張照片的。所謂符號的記憶，所謂的牌位：咒文或碑文，如一個指標般，指向那曾經存在的實體和全部。當一切身體都消逝，還有那符號可以喚起曾經存在的事實。所謂的記憶。然而那一天她發現了這記憶的弔詭：如同照片提醒了箱子的曾經存在，她似乎也可以將照片放置在她心中，用那照片的曾經存在，來指向那些指向了箱子曾經存在的照片。既然如此，拍照與否，又有什麼差別？

用刀片將膠布拆開，一一拾起那箱子中的物品時，她突然覺得，她已經和這些一點關係都沒有了──甚至不再是「距離已經很遙遠很遙遠」。距離：兩個實體間存在的空間關係。沒有關係：就連距離也不再存在的事實。沒有了距離也就不再感受到遙遠，那些如深淵般的通道裡傳來的微弱聲響也消失了。於是同樣也沒有了回頭：那稱作這一切起點的單一事件，已經消失在意識的地平面上。

她來到了經驗的新島嶼。

突然之間，那些放在她房間裡的一個個箱子，變成了外來的異物，路邊的灰塵。

開始丟棄那些箱子。不，這並不是否認。否認一件事物的前提是事物的存在。奇異的是她在丟棄之後，竟然得以開口說話。所有過去那些潰爛的難堪的不潔的，所有的恥辱和屈辱和自以為是，突然之間變成可以說的事情。那不只是因為她自己的經驗，或者，毋寧說，那已經不再只是經驗。個人的生命的經驗，隱沒銷融進入一個更廣闊無垠的核當中，那東西不需要任何被貼上封條的通道，也能夠被觸及到。

她自己的故事已經變得不是那麼無關緊要了，她想，隱沒進那無垠的才是。因為知道那無垠的存在，她突然覺得如同被釋放了一般。

第二天的清醒也因此變得如此值得期待了起來。她開始想獨自說說那隱沒帶下的無垠的事。

CORPUS
    }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Greeking::zh_TW - A module for generating meaningless Chinese text that creates the illusion of the finished document.

=head1 SYNOPSIS

  my $g = Text::Greeking::zh_TW->new;
  $g->paragraphs(3,15); # min of 1 paragraph and a max of 2
  $g->sentences(1,10);  # min of 2 sentences per paragraph and a max of 5
  $g->add_source($scalar); # use text yourself, not requisite
  print $g->generate;

=head1 DESCRIPTION

This module is for Chinese speakers to generate vary meanless Chinese text.

=head1 INTERFACE

=over

=item new()

Constructor.

=item paragraphs($min, $max)

Sets the minimum and maximum number of paragraphs to generate. Default is a minimum of 2 and a maximum of 8.

=item sentences($min, $max)

Sets the minimum and maximum number of sentences to generate per paragraph. Default is a minimum of 2 and a maximum of 8.

=item generate

Returns a body of random text generated from a randomly selected source using the minimum and maximum values set by paragraphs, sentences, and words minimum and maximum values. If generate is called without any sources a standard Lorem Ipsum block is used added to the sources and then used for processing the random text.

=item add_source($scalar)

Add text of yourself as corpus. Return instance itself, so we can add source serially.

    $g->add_source($source_one)->add_source($source_two);

=back

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Greeking>

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-greeking-zh_tw@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHORS

Lukhnos D. Liu C<< <lukhnos@gmail.com> >>, Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, 2008, 2009 Kang-min Liu C<< <gugod@gugod.org> >>, Lukhnos D. Liu C<< <lukhnos@gmail.com> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
