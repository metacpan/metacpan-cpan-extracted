package Vayne::Zk;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::late;

use ZooKeeper;
use Data::Dumper;
use Sys::Hostname;
use Log::Log4perl qw(:easy);
use Data::Printer;

use Vayne;

use YAML::XS;
use constant CONF => 'zookeeper';
has zk => ( is => 'ro', isa => 'ZooKeeper');


=head1 NAME

Vayne::Zk - Vayne Zk control modual

=head1 SYNOPSIS

  use Vayne::Zk;
  my $zk = Vayne::Zk->new();
  my %region = $zk->meta;

=head1 DESCRIPTION

=head2 DATA STRUCTURE

    # we have three regions and 'vayne' is the namespace.
    [zk: localhost:2181(CONNECTED) 0] ls /vayne
    [region-foo, region-bar, region-first]

    # region-first's redis(message system) info.
    [zk: localhost:2181(CONNECTED) 1] get /vayne/region-first
    ---
    password: xxxxxxxxxx
    server: 127.0.0.1:6379

    # real servers belong to the region 'region-fist'.
    [zk: localhost:2181(CONNECTED) 2] ls /vayne/region-first
    [vayne1.foo.bar.net, vayne2.foo.bar.net]

    # workers in vayne1.foo.bar.net.
    [zk: localhost:2181(CONNECTED) 3] ls /vayne/region-first/vayne1.foo.bar.net
    [tcp, dump, track]

    # we have two tcp workers running on vayne1.foo.bar.net belongs to region-first and pids are 52749 52757.
    [zk: localhost:2181(CONNECTED) 4] ls /vayne/region-first/vayne1.foo.bar.net/tcp
    [52749, 52757]

    The node '/vayne/region-first/vayne1.foo.bar.net/tcp/52749' is registered when the worker tcp start.

=head2 METHODS FOR CONTROLLING VAYNE SYSTEM
=cut

around BUILDARGS => sub
{
  my ( $orig, $class, @args ) = @_;
  my $conf = Vayne->conf( CONF );
  my $zk = ZooKeeper->new( ( $conf ? %$conf : () ), @args );
  return $zk ? $class->$orig( zk => $zk ) : undef;
};


=head3 C<< $zk->meta >>

Get all meta info under zookeeper NAMESPACE.

=cut

sub meta
{
    my($this, %meta) = shift;
    for my $region ( $this->regions )
    {
        my $r = $meta{$region} = {} ;
        for my $slave ( $this->slaves( $region ) )
        {
            $r->{$slave} = $this->workers($region, $slave);
        }

    }

    wantarray ? %meta : \%meta;
}

=head3 C<< $zk->define($region, {server=>$redis_server, password=>$redis_pwd}) >>

Define a new region.

=cut

sub define
{
    my($this, $region, $value) = @_;
    my $path =  _path($region);


    return unless $value && $value->{server};

    $this->zk->exists($path) ?
        $this->zk->set($path => YAML::XS::Dump $value)
        : $this->mkpath($path, value => YAML::XS::Dump $value);

}

=head3 C<< $zk->switch($region, $host) >>

Switch a host to region

=cut

sub switch
{
    my($this, $region, $host) = @_;
    $host ||= hostname;

    $region and my ($dst, @del) = _path($region, $host);

    LOGWARN "region $region not exist!" and return unless $this->zk->exists(_path($region));
    LOGWARN "$dst exist" and return if $this->zk->exists($dst);

    @del = grep{ $this->zk->exists($_) }map{_path($_, $host)}$this->regions;

    $this->rmpath($_) for @del;
    $this->mkpath( $dst ) unless $this->zk->exists($dst);
}

=head3 C<< $zk->delete($host) >>

Delete a host.

=cut

sub delete
{
    my($this, $host, @del) = splice @_, 0, 2;
    $host ||= hostname;
    @del = grep{ $this->zk->exists($_) }map{ _path($_, $host) }$this->regions;
    $this->rmpath($_) for @del;
    @del;
}

=head3 C<< $zk->delete_region($region) >>

Delete a region.

=cut

sub delete_region
{
    my($this, $region) = splice @_, 0, 2;
    $this->rmpath(_path($region));
}

=head2 METHODS USED BY WORKER

=head3 C<< $zk->register(@names) >>

Register worker. How to write a worker, please see L<Vayne::Worker>.

=cut

my($REGION, @LOCK);
sub register
{
    my ($this, $host) = shift;
    $host = hostname;

    ($REGION, my @other) = grep{ $this->zk->exists( _path($_, $host)  ) }$this->regions;
    LOGDIE "$host not belong to any region" unless $REGION;
    LOGDIE "$host redefind $REGION @other" if @other;

    for(@_)
    {
        my $lock;
        if($ENV{VAYNE_NOPID}) #for running in container
        {
            $lock = $this->mkpath
            (
                _path($REGION, $host, $_, ''),
                ephemeral=>1,
                sequential=>1
            );
        }else{
            $lock = _path($REGION, $host, $_, $$);
            $this->mkpath($lock, ephemeral=>1);
        }
        INFO "register lock: ", $lock;
        push @LOCK, $lock;
    }
}

=head3 C<< $zk->queue >>

Get region's queue(redis) info.

=cut

sub queue
{
    my($this, $value, $que) = shift;
    $value = $this->zk->get(_path( $REGION || shift ));
    $que   = eval{ YAML::XS::Load $value };
    ref $que ? %$que : ();
}

=head3 C<< $zk->check >>

Worker will verify the register info periodically.
Worker will go die when registered path changed.
More details see L<Vayne::Worker>.

=cut

sub check
{
    my $this = shift;
    $this->zk->exists($_) or LOGDIE "lock $_ not exists! now die!" for @LOCK;
}



#PRIVATE HELPER FUNCTION

sub workers
{
    my ($this, $p, %worker) = shift;

    $p = _path( @_ );

    for( $this->ls($p) )
    {
        my($p, @w) = _path(@_, $_);
        @w = $this->ls($p);
        $worker{$_}->{proc} = \@w;
        $worker{$_}->{real} = scalar @w;
    }
    wantarray ? %worker : \%worker;
}

sub slaves
{

    my($this, $region) = @_;
    my $p = _path($region);
    map{ s/^$p\///; $_}$this->_ls($p);
}

sub regions
{
    my $this = shift;
    my $p = _path();
    map{ s/^$p\///; $_}$this->_ls($p);
}

sub mkpath
{
    my($this, $path) = splice @_, 0, 2;
    my @a = split '/', $path, -1;
    for( 1 ... (scalar @a - 2) )
    {
        my $p = join '/', @a[0..$_];
        $this->zk->create($p) unless $this->zk->exists($p);
    }
    $this->zk->create($path, @_);
}
sub rmpath
{
    my($this, $path) = splice @_, 0, 2;
    while(my @leaf = $this->leaf($path))
    {
        $this->zk->delete($_) for @leaf;
    }
    $this->zk->delete($path);
}

sub leaf
{
    my($this, $path, @ret) = splice @_, 0, 2;
    my @path = $this->_ls($path);
    for(@path)
    {
        my @p = $this->_ls($_);
        push @ret, $_ and next unless @p;
        push @ret, $this->leaf($_);
    }
    return @ret;
}

sub ls { my($this, $p) = @_; map{ s/^$p\///; $_}$this->_ls($p) }

sub _path
{
    File::Spec->join('/', $Vayne::NAMESPACE, @_ );
}

sub _ls
{
    my($this, $path) = @_;
    my @child;eval{ @child = $this->zk->get_children($path) };
    LOGWARN $@ if $@;
    map{ File::Spec->join($path, $_) }@child;
}

1;
