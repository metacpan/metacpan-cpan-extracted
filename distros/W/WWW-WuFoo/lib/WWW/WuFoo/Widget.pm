package WWW::WuFoo::Widget;
{
  $WWW::WuFoo::Widget::VERSION = '0.007';
}

use Moose;

# ABSTRACT: The Widgetes API is used to gather details about the widgets you have permission to view. Used in combination with the reports you could easily build a tool to view widgets for a given report.

has _wufoo          => (is => 'rw', isa => 'WWW::WuFoo');
has 'name'          => (is => 'rw', isa => 'Str');
has 'size'          => (is => 'rw', isa => 'Str');
has 'type'          => (is => 'rw', isa => 'Str');
has 'typedesc'      => (is => 'rw', isa => 'Str');
has 'hash'          => (is => 'rw', isa => 'Str');



1;
