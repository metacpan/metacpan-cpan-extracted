package Text::CSV::Auto::ExportTo;
BEGIN {
  $Text::CSV::Auto::ExportTo::VERSION = '0.06';
}
use Moose::Role;

requires 'export';

has 'auto' => (
    is       => 'ro',
    isa      => 'Text::CSV::Auto',
    required => 1,
);

1;
