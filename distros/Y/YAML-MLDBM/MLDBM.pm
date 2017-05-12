package YAML::MLDBM;
$VERSION = '0.10';

use MLDBM (undef, 'YAML');
use Fcntl;
use Carp;

sub new {
    my $class = shift;
    my $db_file = shift;
    my $mode = shift || 0640;
    
    my %hash;
    tie %hash, 'MLDBM', $db_file, O_CREAT|O_RDWR, $mode 
    or do {
        confess "Can't make a tied hash for you: $!";
    };
    return \%hash;
}

1;

=head1 NAME

YAML::MLDBM - Use tied hash db-s with Python and Ruby

=head1 SYNOPSIS

    use YAML::MLDBM;

    my $h = YAML::MLDBM->new('./my_dbm_file');

    $h->{'@INC'} = \@INC;
    $h->{'%ENV'} = \%ENV;

    use Data::Dumper;
    print Dumper $h;

=head1 DESCRIPTION

This module is similar to MLDBM except that it stores data internally as
YAML, instead of Data::Dumper or Storable. By doing this, you can create
tied hash DBM databases that can be used seamlessly in Python or Ruby
applications. That's because those languages also have YAML and DBM
modules. As other languages get YAML support, you should be able to use
YAML::MLDBM with them as well.

This module is a wrapper around MLDBM, but you open a DBM file using the
new() method, instead of using a tie. new() will return a reference to a
tied hash.

You can also use YAML as a serialization method for MLDBM itself:

    use MLDBM qw(SDBM_File YAML);
    use Fcntl;
    
    tie %h, 'MLDBM', './my_dbm_file', O_CREAT|O_RDWR, 0640 or die $!;
    
    $h{'@INC'} = \@INC;
    $h{'%ENV'} = \%ENV;
    
    use Data::Dumper;
    print Dumper \%h;

This has the same affect, but is more verbose. It does offer you more
control if you want it though.

=head1 SEE ALSO

See L<MLDBM>, L<AnyDBM_File> and L<YAML> for more information.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003 Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
