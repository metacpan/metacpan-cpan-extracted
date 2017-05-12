=== static
--- input read_file html
xt/data/TzList/tz-GMT/input.html
--- expected read_file strict eval
xt/data/TzList/tz-GMT/expected.pl

=== dynamic
--- input yaml build_uri
tz: GMT
--- expected read_file strict eval
xt/data/TzList/tz-GMT/expected.pl

