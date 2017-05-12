package MyBuild;

use strict;
use base 'Module::Build';

# Run perltidy over all the Perl code
# Borrowed from Test::Harness
sub ACTION_tidy {
    my $self = shift;

    my %found_files = map { %$_ } $self->find_pm_files,
      $self->_find_file_by_type( 'pm', 't' ),
      $self->_find_file_by_type( 'pm', 'inc' ),
      $self->_find_file_by_type( 't',  't' ),
      $self->_find_file_by_type( 'PL', '.' );

    my @files = keys %found_files;

    print "Running perltidy on @{[ scalar @files ]} files...\n";
    for my $file ( sort { $a cmp $b } @files ) {
        print "  $file\n";
        system( 'perltidy', '-b', $file );
        unlink("$file.bak") if $? == 0;
    }
}

sub ACTION_critic {
    my $self = shift;

    my @files = keys %{ $self->find_pm_files };

    print "Running perlcritic on @{[ scalar @files ]} files...\n";
    system( "perlcritic", "-3", @files );
}

1;
