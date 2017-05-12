package Vayne::Job;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::late;

use Data::UUID;
use YAML::XS;

use Vayne;
use Data::Printer;

use Log::Log4perl qw(:easy);

has uuid     => (is => 'rw', isa => 'Str');
has expire   => (is => 'rw', isa => Int);

our @META = qw(step run workload taskid region result status);

has workload => (is => 'rw', isa => 'Str');
has taskid   => (is => 'rw', isa => 'Str');
has region   => (is => 'rw', isa => 'Str');

our %FREEZE = map{ $_ => 1 }qw(step result status);

our @UPDATE = qw(run result status);
has run      => (is => 'rw', isa => 'Int', default => 0);
has step     => (is => 'rw', isa => 'ArrayRef');
has result   => (is => 'rw', isa => 'HashRef', default => sub{{}});
has status   => (is => 'rw', isa => 'HashRef', default => sub{{}});


for my $method (qw( result status ))
{

    around $method => sub 
    {
        my $orig = shift;
        my $self = shift;
        @_ == 2 ? $self->{$method}->{$_[0]} = $_[1] : $orig->($self, @_);
    };

}

around BUILDARGS => sub
{
    my( $orig, $class, %args ) = @_;
    $args{uuid} ||= Data::UUID->new->create_str;
    $class->$orig( %args );
};

sub step_to_run { my $this = shift; eval{ $this->step->[$this->run] }; }

sub chk_need
{
    my($this, $step) = @_;

    return 1 unless $step->{need};

    WARN "need is not Array" 
        and return unless ref $step->{need} eq 'ARRAY';

    ORI: for(@{$step->{need}})
    {
        WARN "need is not HASH" 
            and next ORI unless ref $_ eq 'HASH' and my %need = %$_;

        while(my($step, $status) = each %need)
        {
            next ORI unless $this->status->{$step} eq $status;
        }
        return 1;
    }
    0;
}

sub key{$Vayne::NAMESPACE. ":jobs:".$_[0]->uuid}

our @DUMP = qw(workload taskid region status);
sub to_hash
{
    my $this = shift;
    map{$_ => $this->$_}@DUMP;
}

sub generate_jobs
{
    my $opt = shift;
    my($step, $expire) = map{$opt->{$_}}qw(step expire);
    eval{$opt->{step} = YAML::XS::LoadFile $step} if not ref $step && -f $step;
    map{ __PACKAGE__->new(workload=>$_, step=>$opt->{step}, expire=>$expire) }@_;
}

1;
__END__
