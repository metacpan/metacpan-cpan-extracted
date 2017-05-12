package WWW::WuFoo::Comment;
{
  $WWW::WuFoo::Comment::VERSION = '0.007';
}

use Moose;

# ABSTRACT: The Comments API is used to gather details about comments you’ve made on forms you have permission to view.

has '_wufoo'      => (is => 'rw', isa => 'WWW::WuFoo');
has 'subdomain'   => (is => 'rw', isa => 'Str');
has 'xml'         => (is => 'rw', isa => 'Str');
has 'json'        => (is => 'rw', isa => 'Str');
has 'formid'      => (is => 'rw', isa => 'Str');
has 'pretty'      => (is => 'rw', isa => 'Str');
has 'entryid'     => (is => 'rw', isa => 'Str');
has 'pagesize'    => (is => 'rw', isa => 'Str');
has 'pagestart'   => (is => 'rw', isa => 'Str');


1;
