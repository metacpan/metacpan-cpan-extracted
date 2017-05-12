package WebService::Speechmatics::User;
$WebService::Speechmatics::User::VERSION = '0.02';
use 5.010;
use Moo 1.006;

has balance => (is => 'ro', required => 1);
has email   => (is => 'ro', required => 1);
has id      => (is => 'ro', required => 1);

1;


=head1 NAME

WebService::Speechmatics::User - data object that holds details of a user account

=head1 SYNOPSIS

=head1 DESCRIPTION

