package WebService::Speechmatics::Job;
$WebService::Speechmatics::Job::VERSION = '0.02';
use 5.010;
use Moo 1.006;

has created_at      => (is => 'ro');
has duration        => (is => 'ro');
has id              => (is => 'ro');
has job_status      => (is => 'ro');
has lang            => (is => 'ro');
has name            => (is => 'ro');
has next_check      => (is => 'ro');
has notification    => (is => 'ro');
has size            => (is => 'ro');
has transcription   => (is => 'ro');
has url             => (is => 'ro');
has user_id         => (is => 'ro');

1;


=head1 NAME

WebService::Speechmatics::Job - data object that holds details of a transcription job

=head1 SYNOPSIS

=head1 DESCRIPTION

