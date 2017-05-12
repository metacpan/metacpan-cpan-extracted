package Vayne::Task;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::late;

use Data::UUID;
use Vayne::Job;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( STATUS_RUN STATUS_COMPLETE STATUS_CANCEL STATUS_TIMEOUT );

use constant STATUS_PREPARE  => 'prepare';
use constant STATUS_RUN      => 'running';
use constant STATUS_COMPLETE => 'complete';
use constant STATUS_CANCEL   => 'cancel';
use constant STATUS_TIMEOUT  => 'timeout';

has taskid   => (is => 'rw', isa => 'Str');
has name     => (is => 'rw', isa => 'Str');
has start    => (is => 'rw', isa => 'Str');
has expire   => (is => 'rw', isa => Int);
has jobs     => (is => 'rw', isa => 'ArrayRef');
has opt      => (is => 'rw', isa => 'HashRef');
has status   => (is => 'rw', isa => 'Str', default => sub{STATUS_PREPARE});
has complete => (is => 'rw', isa => 'Int', default => sub{0});




sub make
{
    my($class, $opt) = splice @_, 0, 2;

    my @jobs = Vayne::Job::generate_jobs($opt, @_);

    __PACKAGE__->new
    ( 
        jobs=>\@jobs, opt=>$opt, taskid => Data::UUID->new->create_str,
        map{$_ => delete $opt->{$_}}qw(expire name)
    );
}

my @DUMP = qw(taskid name start expire opt status complete);

sub to_hash
{
    my ($this, %ret) = shift;
    %ret = map{$_ => $this->$_}@DUMP;
    map{ push @{ $ret{job} }, $_->uuid }@{$this->jobs};

    %ret;
}

1;
