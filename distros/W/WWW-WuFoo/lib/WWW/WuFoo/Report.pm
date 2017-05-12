package WWW::WuFoo::Report;
{
  $WWW::WuFoo::Report::VERSION = '0.007';
}

use Moose;

# ABSTRACT: The Reports API is used to gather details about the reports you have permission to view.

has '_wufoo'            => (is => 'rw', isa => 'WWW::WuFoo');
has 'name'    => (is => 'rw', isa => 'Str');
has 'ispublic'    => (is => 'rw', isa => 'Str');
has 'url'    => (is => 'rw', isa => 'Str');
has 'description'    => (is => 'rw', isa => 'Str');
has 'datecreated'    => (is => 'rw', isa => 'Str');
has 'dateupdated'    => (is => 'rw', isa => 'Str');
has 'hash'    => (is => 'rw', isa => 'Str');



1;
