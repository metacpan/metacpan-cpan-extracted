package Web::API::Mapper::Test;
use warnings;
use strict;







1;
__END__

=head1 NAME

=head1 DESCRIPTION

=head1 SYNOPSIS

    my $tester = Web::API::Mapper::Test->new( mapper => $m );
    $tester->ok( '/foo/get/id' );
    $tester->is_deeply(  '/foo/get/id' , { data => "John" } , { data => "Johnny walker." } );
    $tester->is( '/foo/get/name' , 'John' );

=cut
