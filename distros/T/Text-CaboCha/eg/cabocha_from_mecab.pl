use strict;
use lib 'lib';
use Text::CaboCha;
use Text::MeCab;

printf("** Using cabocha %s **\n", Text::CaboCha::CABOCHA_VERSION);
my $text = "太郎は次郎が持っている本を花子に渡した。";

my $mecab = Text::MeCab->new;
my $node = $mecab->parse($text);

my $cabocha = Text::CaboCha->new;
my $tree = $cabocha->parse_from_node($node);

# Print tree
print $tree->tostr(Text::CaboCha::CABOCHA_FORMAT_TREE), "\n";

my $token_size = $tree->token_size;
my $cid = 0;
for (my $i = 0; $i < $token_size; $i++) {
    my $token = $tree->token($i);
    if ($token->chunk) {
        printf("* %d %dD %d/%d %f\n",
              $cid++,
              $token->chunk->link,
              $token->chunk->head_pos,
              $token->chunk->func_pos,
              $token->chunk->score);
        printf("%s\t%s\t%s\n",
                $token->surface,
                $token->feature,
                $token->ne ? $token->ne : "O");
    }
}

# You can also try this one.
# for my $token (@{ $tree->tokens }) {
#      if ($token->chunk) {
#         printf("* %d %dD %d/%d %f\n",
#               $cid++,
#               $token->chunk->link,
#               $token->chunk->head_pos,
#               $token->chunk->func_pos,
#               $token->chunk->score);
#         printf("%s\t%s\t%s\n",
#                 $token->surface,
#                 $token->feature,
#                 $token->ne ? $token->ne : "O");
#     }
# }

my $chunk_size = $tree->chunk_size();
for (my $i = 0; $i < $chunk_size; $i++) {
    my $chunk = $tree->chunk($i);
    for my $feature_list (@{ $chunk->feature_list }) {
        print "$feature_list\n";
    }
}

# You can also try this one.
# for my $chunk (@{ $tree->chunks }) {
#    for my $feature_list (@{ $chunk->feature_list }) {
#        print "$feature_list\n";
#    }
# }
