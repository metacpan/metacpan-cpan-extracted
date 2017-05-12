package WebService::Speechmatics::Submission;
$WebService::Speechmatics::Submission::VERSION = '0.02';
use 5.010;
use Moo 1.006;

has balance => (is => 'ro', required => 1);
has cost    => (is => 'ro', required => 1);
has id      => (is => 'ro', required => 1);

1;


=head1 NAME

WebService::Speechmatics::Submission - data object that holds the response from submitting a job

=head1 SYNOPSIS

=head1 DESCRIPTION

