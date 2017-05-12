# Test::VirtualModule

Perl virtual modules mechanism for unit testing. For example, you have some perl module with complex dependencies,
which can't be satisfied without a lot of manipulation.
But for your unit tests you need to use this module.
So, you can do that:

See example:

    # load virtual module
    use Test::VirtualModule qw/BlahBlahBlah::FooBar/;
    # import mocked module, it's ok
    use BlahBlahBlah::FooBar;
    # Mock constructor
    Test::VirtualModule->mock_sub('BlahBlahBlah::FooBar',
        new => sub {
            my $self = {};
            bless $self, 'BlahBlahBlah::FooBar';
            return $self;
        }
    );
    # create object
    my $object = BlahBlahBlah::FooBar->new();
    
