package rig::task::red;
{
  $rig::task::red::VERSION = '0.04';
}

sub rig {
     return {
      use => [
         'strict',
         { 'warnings'=> [ 'FATAL','all' ] },
         '+IO::All',
         { 'feature' => ['say'] },
         { 'Data::Dumper' => ['Dump dd'] },
         'Try::Tiny',
         'Path::Class',
         { 'File::Slurp' => [ 'slurp' ] },
         'autobox::Core'
      ]
   };
}

=head1 NAME

rig::task::red - the 'red' rig

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This is one of the standard rigs packaged into C<rig> for
an out-of-the-box experience.

It includes the following:

    use strict;
    use warnings qw/FATAL all/;
    use feature 'say';
    use Data::Dumper;  # and aliased Dump to dd
    use Try::Tiny;
    use Path::Class;
    use autobox::Core;

=cut

1;
