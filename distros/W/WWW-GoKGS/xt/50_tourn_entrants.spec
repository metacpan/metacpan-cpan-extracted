=== static (Swiss)
--- input read_file decode_utf8 html
xt/data/TournEntrants/20140616-id-857-sort-n/input.html
--- expected read_file strict eval
xt/data/TournEntrants/20140616-id-857-sort-n/expected.pl

=== static (Round Robin)
--- input read_file decode_utf8 html
xt/data/TournEntrants/20140616-id-104-sort-n/input.html
--- expected read_file strict eval
xt/data/TournEntrants/20140616-id-104-sort-n/expected.pl

=== static (Single Elimination)
--- input read_file decode_utf8 html
xt/data/TournEntrants/20140616-id-12-sort-n/input.html
--- expected read_file strict eval
xt/data/TournEntrants/20140616-id-12-sort-n/expected.pl

=== dynamic (Single or Double Elimination)
--- input yaml build_uri
id: 885
sort: n

=== dynamic (Swiss or McMahon)
--- input yaml build_uri
id: 887
sort: n

=== dynamic (Round Robin)
--- input yaml build_uri
id: 525
sort: n

