# Trek through a [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)) one character at a time.


![Test](https://github.com/philiprbrenan/TreeTrek/workflows/Test/badge.svg)

Test cases can be seen at the end of [file](https://en.wikipedia.org/wiki/Computer_file) **lib/Tree/Trek.pm**.  The [test](https://en.wikipedia.org/wiki/Software_testing) cases
are run by the [GitHub Action](https://docs.github.com/en/free-pro-team@latest/actions/quickstart). 

## Create a trekkable [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)) and trek through it.
  ```
  my $n = node;

  $n->put("aa") ->data = "AA";
  $n->put("ab") ->data = "AB";
  $n->put("ba") ->data = "BA";
  $n->put("bb") ->data = "BB";
  $n->put("aaa")->data = "AAA";

  is_deeply [map {[$_->key, $_->data]} $n->traverse],
   [["aa",  "AA"],
    ["aaa", "AAA"],
    ["ab",  "AB"],
    ["ba",  "BA"],
    ["bb",  "BB"]];
   ```


For documentation see: [CPAN](https://metacpan.org/pod/Tree::Trek)