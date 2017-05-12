use strict;
use warnings;

use Test::More tests => 54;

use_ok('XML::Reader');

my @subs = qw(
  XML::Reader::import
  XML::Reader::activate
  XML::Reader::new
  XML::Reader::path
  XML::Reader::value
  XML::Reader::tag
  XML::Reader::attr
  XML::Reader::att_hash
  XML::Reader::dec_hash
  XML::Reader::type
  XML::Reader::level
  XML::Reader::prefix
  XML::Reader::comment
  XML::Reader::pyx
  XML::Reader::rx
  XML::Reader::rvalue
  XML::Reader::proc_tgt
  XML::Reader::proc_data
  XML::Reader::is_decl
  XML::Reader::is_start
  XML::Reader::is_proc
  XML::Reader::is_comment
  XML::Reader::is_text
  XML::Reader::is_attr
  XML::Reader::is_value
  XML::Reader::is_end
  XML::Reader::NB_data
  XML::Reader::NB_fh
  XML::Reader::iterate
  XML::Reader::get_token
  XML::Reader::handle_decl
  XML::Reader::handle_procinst
  XML::Reader::handle_comment
  XML::Reader::handle_start
  XML::Reader::handle_end
  XML::Reader::handle_char
  XML::Reader::convert_structure
  XML::Reader::DESTROY
  XML::Reader::slurp_xml
  XML::Reader::Token::found_start_tag
  XML::Reader::Token::found_end_tag
  XML::Reader::Token::found_attr
  XML::Reader::Token::found_text
  XML::Reader::Token::extract_tag
  XML::Reader::Token::extract_attkey
  XML::Reader::Token::extract_attval
  XML::Reader::Token::extract_text
  XML::Reader::Token::extract_comment
  XML::Reader::Token::extract_prv_SPECD
  XML::Reader::Token::extract_nxt_SPECD
  XML::Reader::Token::extract_attr
  XML::Reader::Token::extract_proc
  XML::Reader::Token::extract_decl
);

my $tctr = 0;

for my $s (@subs) {
    $tctr++;

    ok(defined(&{$s}), "Test-".sprintf('%03d', $tctr)." sub $s is defined");
}
