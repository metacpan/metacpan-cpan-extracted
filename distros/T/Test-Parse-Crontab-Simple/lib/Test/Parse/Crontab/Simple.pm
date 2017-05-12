package Test::Parse::Crontab::Simple;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use parent qw/Exporter/;
use Data::Util;
use Test::Builder;

our @EXPORT = qw/match_ok strict_match_ok/;

my $PREFIX = '###sample';
my $STRICT_MATCH = 0;
my $TEST = Test::Builder->new;

sub import {
    my $self = shift;
    my $pack = caller;


    $TEST->exported_to( $pack );
    $TEST->plan( @_ );

    $self->export_to_level( 1, $self, @EXPORT );
}

sub set_prefix{
    my ($prefix) = @_;

    return unless Data::Util::is_string($prefix);
    $PREFIX = $prefix;
}

sub _set_strict_mode{
    $STRICT_MATCH = 1;
}

sub strict_match_ok{
    my $crontab = shift;

    _set_strict_mode();
    match_ok( $crontab );
}

sub match_ok{
    my $crontab = shift;

    return unless Data::Util::is_instance($crontab , 'Parse::Crontab');

    for my $job ( $crontab->jobs ){
        my $sample = _search_sample( $crontab , $job );
        if( Data::Util::is_hash_ref($sample) ){
            my $ret = $job->schedule->match( %{$sample} );
            $TEST->ok( $ret , sprintf('[%s] matches ok', $job->command));
        }
        else{
            if( $STRICT_MATCH ){
                $TEST->ok( 0 , sprintf('[%s] does not have sample',$job->command));
            }
            else{
                next;
            }
        }
    }
}

sub _search_sample{
    my ( $crontab , $job ) = @_;

    my $sample_comment;
    my $find_flg = 0;
    for my $entry ( $crontab->entries ){
        if( $find_flg ){
            if( _is_sample( $entry ) ){
                return _parse_sample_comment( $entry );
            }
            else{
                next;
            }
        }
        elsif( $entry->line_number eq $job->line_number ){
            $find_flg = 1;
        }
    }
    return;
}

sub _is_sample{
    my $entry = shift;
    return 1 if $entry->line =~ m/\A$PREFIX/;
}

sub _parse_sample_comment{
    my $sample_entry = shift;
 
    if( $sample_entry->line =~ m/\A$PREFIX (\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/){
        return {
            year   => $1,
            month  => $2,
            day    => $3,
            hour   => $4,
            minute => $5,
        };
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::Parse::Crontab::Simple - Simple Test Tool of Crontab by Parse::Crontab

=head1 SYNOPSIS

    use strict;
    use warnings;
    
    use Test::More;
    use Parse::Crontab;
    use Test::Parse::Crontab::Simple;
    
    my $crontab = Parse::Crontab->new(file => './crontab.txt');
    
    ok $crontab->is_valid;
    
    match_ok $crontab;
    
    done_testing;

    <-------- crontab.txt ------------>
    */30 * * * * perl /path/to/cron_lib/some_worker1
    ###sample 2014-12-31 00:00:00

    0 23 * * * perl /path/to/cron_lib/some_worker2
    ###sample 2014-12-31 23:00:00

    0 15 * * * perl /path/to/cron_lib/some_worker3
    <--------------------------------->

=head1 DESCRIPTION

Test::Parse::Crontab::Simple is Simple Test Tool of Crontab. It is using Parse::Crontab

If you write execution timing of crontab following below that declaration, test method validate it.
If sample is valid , test will pass.

Basically, you have to write sample as below format.
###sample YYYY-MM-DD HH:ii:ss

=head1 METHODS

=head2 match_ok

If you do not write sample, that declaration is not validated automatically.

=head2 strict_match_ok

If you do not write sample, test will fail.

=head1 DEPENDENCIES

L<Parse::Crontab>

=head1 LICENSE

Copyright (C) masartz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

masartz E<lt>masartz@gmail.comE<gt>

=head1 SEE ALSO

L<Parse::Crontab>

=cut

