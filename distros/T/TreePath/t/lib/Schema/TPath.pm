use utf8;
package Schema::TPath;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'DBIx::Class::Schema';

our $VERSION = 1;

__PACKAGE__->load_namespaces;

sub _populate {
  my $self = shift;

  my @files = $self->populate(
        'File',
        [
            [ qw/ id  file              page_id/ ],
            [     1,  '/tmp/file1.txt', 1        ],
            [     2,  '/tmp/file2.txt', 1        ],
        ]
    );

  my @pages = $self->populate(
        'Page',
        [
            [ qw/ id name parent_id / ],
            [     1,  '/', 0        ],
            [     2,  'A', 1        ],
            [     3,  'B', 2        ],
            [     4,  'C', 3        ],
            [     5,  'D', 4        ],
            [     6,  'E', 4        ],
            [     7,  '♥', 2        ],
            [     8,  'G', 7        ],
            [     9,  'E', 7        ],
            [     10, 'I', 9        ],
            [     11, 'J', 9        ],
        ]
    );

  my @comments = $self->populate(
        'Comment',
        [
            [ qw/ id  page_id body       /],
            [     1,  1,      'comment 1' ],
            [     2,  1,      'comment 2' ],
            [     3,  2,      'comment 3' ],
            [     4,  2,      'comment 4' ],
            [     5,  1,      'comment 5' ],
            [     6,  7,      'comment 6' ],
            [     7, 11,      'comment 7' ],
            [     8, 11,      'comment 8' ],
        ]
    );
}
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
