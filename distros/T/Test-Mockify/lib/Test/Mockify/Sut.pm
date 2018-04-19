=pod

=head1 NAME

Test::Mockify::Sut - injection options for your System under test (Sut) based on Mockify

=head1 SYNOPSIS

  use Test::Mockify::Sut;
  use Test::Mockify::Verify qw ( WasCalled );
  use Test::Mockify::Matcher qw ( String );

  # build a new system under text
  my $MockifySut = Test::Mockify::Sut->new('Package::I::Like::To::Test', []);
  $MockifySut->mockImported('Package::Name', 'ImportedFunctionName')->when(String())->thenReturn('Hello');
  $MockifySut->mockStatic('Fully::Qualified::FunctionName')->when(String())->thenReturn('Hello');
  $MockifySut->mockConstructor('Package::Name', $Object);#  hint: build this object also with Mockify
  my $PackageILikeToTest = $MockifySut->getMockObject();

  $PackageILikeToTest->do_something();# all injections are used here

  # verify that the mocked method were called
  ok(WasCalled($PackageILikeToTest, 'ImportedFunctionName'), 'ImportedFunctionName was called');
  done_testing();

=head1 DESCRIPTION

Use L<Test::Mockify::Sut|Test::Mockify::Sut> to create and configure Sut objects. Use L<Test::Mockify::Verify|Test::Mockify::Verify> to
verify the interactions with your mocks.

You can find a Example Project in L<ExampleProject|https://github.com/ChristianBreitkreutz/Mockify/tree/master/t/ExampleProject>

=head1 METHODS

=cut

package Test::Mockify::Sut;
use strict;
use warnings;
use parent 'Test::Mockify';
use Test::Mockify::Matcher qw (String);
use Test::Mockify::Tools qw (Error);
use Test::Mockify::TypeTests qw ( IsString );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

=pod

=head2 mockImported

Sometimes it is not possible to inject the dependencies from the outside. This is especially the case when the package uses imports of static functions.
C<mockImported> provides the possibility to mock imported functions inside the mock.

Unlike C<mockStatic> is the injection with C<mockImported> only in the mock valid.

=head3 synopsis

  package Show::Magician;
  use Magic::Tools qw ( Rabbit );
  sub pullCylinder {
      shift;
      if(Rabbit('white')){
          return 1;
      }else{
          return 0;
      }
  }
  1;


In the Test it can be mocked

  package Test_Magician;
  use Magic::Tools qw ( Rabbit );
  my $Mockify = Test::Mockify::Sut->new( 'Show::Magician', [] );
  $Mockify->mockImported('Magic::Tools','Rabbit')->when(String('white'))->thenReturn(1);

  my $Magician = $Mockify->getMockObject();
  is($Magician ->pullCylinder(), 1);
  Rabbit('white');# return original result
  1;


It can be mixed with normal C<spy>

=cut
sub mockImported {
    my $self = shift;
    my @Parameters = @_;

    my $ParameterAmount = scalar @Parameters;
    if($ParameterAmount == 2 && IsString($Parameters[0]) && IsString($Parameters[1])){
            $self->{'IsImportedMockStore'}{$Parameters[1]} = {
                'Path' => $Parameters[0],
                'MethodName' => $Parameters[1],
            };
            return $self->_addMockWithMethod($Parameters[1]);
    }else{
        Error('"mockImported" Needs to be called with two Parameters which need to be a fully qualified path as String and the Function name. e.g. "Path::To::Your", "Function"');
    }

}
=pod

=head2 spyImported

C<spyImported> provides the possibility to spy imported functions inside the mock.

Unlike C<spyStatic> is the injection with C<spyImported> only in the mock valid.

=head3 synopsis

  package Show::Magician;
  use Magic::Tools qw ( Rabbit );
  sub pullCylinder {
      shift;
      if(Rabbit('white')){
          return 1;
      }else{
          return 0;
      }
  }
  1;


In the Test it can be mocked

  package Test_Magician;
  use Magic::Tools qw ( Rabbit );
  my $Mockify = Test::Mockify::Sut->new( 'Show::Magician', [] );
  $Mockify->spyImported('Magic::Tools','Rabbit')->when(String());

  my $Magician = $Mockify->getMockObject();
  is($Magician->pullCylinder(), 'SomeValue');
  is(GetCallCount($Magician, 'Rabbit'), 1);
  1;

It can be mixed with normal C<spy>

=cut
sub spyImported {
    my $self = shift;
    my @Parameters = @_;

    my $ParameterAmount = scalar @Parameters;
    if($ParameterAmount == 2 && IsString($Parameters[0]) && IsString($Parameters[1])){
            $self->{'IsImportedMockStore'}{$Parameters[1]} = {
                'Path' => $Parameters[0],
                'MethodName' => $Parameters[1],
            };
            my $PointerOriginalMethod = \&{sprintf ('%s::%s', $self->_mockedModulePath(), $Parameters[1])};
            return $self->_addMockWithMethodSpy($Parameters[1], $PointerOriginalMethod);
    }else{
        Error('"spyImported" Needs to be called with two Parameters which need to be a fully qualified path as String and the Function name. e.g. "Path::To::Your", "Function"');
    }

}
=pod

=head2 mockStatic

Sometimes it is not possible to inject the dependencies from the outside.
C<mockStatic> provides the possibility to mock static functions inside the mock.

Attention: The mocked function is valid as long as the $Mockify is defined. If You leave the scope or set the $Mockify to undef the injected method will be released.

=head3 synopsis

  package Show::Magician;
  use Magic::Tools;
  sub pullCylinder {
      shift;
      if(Magic::Tools::Rabbit('black')){
          return 1;
      }else{
          return 0;
      }
  }
  1;


In the Test it can be mocked like:

  package Test_Magician;
  { # start scope
      my $Mockify = Test::Mockify::Sut->new( 'Show::Magician', [] );
      $Mockify->mockStatic('Magic::Tools::Rabbit')->when(String('black'))->thenReturn(1);
      $Mockify->spy('log')->when(String());
      my $Magician = $Mockify->getMockObject();

      is($Magician->pullCylinder('black'), 1);
      is(Magic::Tools::Rabbit('black'), 1); 
  } # end scope
  is(Magic::Tools::Rabbit('black'), 'someValue'); # The orignal method in in place again


It can be mixed with normal C<spy>

=head4 ACKNOWLEDGEMENTS
Thanks to @dbucky for this amazing idea

=cut
sub mockStatic {
    my $self = shift;
    my @Parameters = @_;

    my $ParameterAmount = scalar @Parameters;
    if($ParameterAmount == 1 && IsString($Parameters[0])){
        if( $Parameters[0] =~ /.*::.*/xsm ){
            $self->{'IsStaticMockStore'}{$Parameters[0]} = 1;
            return $self->_addMockWithMethod($Parameters[0]);
        }else{
            Error("The function you like to mock needs to be defined with a fully qualified path. e.g. 'Path::To::Your::$Parameters[0]' instead of only '$Parameters[0]'");
        }
    }else{
        Error('"mockStatic" Needs to be called with one Parameter which need to be a fully qualified path as String. e.g. "Path::To::Your::Function"');
    }

}
=pod

=head2 spyStatic

Provides the possibility to spy static functions around the mock.

=head3 synopsis

  package Show::Magician;
  sub pullCylinder {
      shift;
      if(Magic::Tools::Rabbit('black')){
          return 1;
      }else{
          return 0;
      }
  }
  1;

In the Test it can be mocked

  package Test_Magician;
  use Magic::Tools;
  my $Mockify = Test::Mockify::Sut->new( 'Show::Magician', [] );
  $Mockify->spyStatic('Magic::Tools::Rabbit')->whenAny();
  my $Magician = $Mockify->getMockObject();

  $Magician->pullCylinder();
  Magic::Tools::Rabbit('black');
  is(GetCallCount($Magician, 'Magic::Tools::Rabbit'), 2); # count as long as $Mockify is valid

  1;

It can be mixed with normal C<spy>. For more options see, C<mockStatic>

=cut
sub spyStatic {
    my $self = shift;
    my ($MethodName) = @_;
    if(! $MethodName){
        Error('"spyStatic" Needs to be called with one Parameter which need to be a fully qualified path as String. e.g. "Path::To::Your::Function"');
    }
    if( $MethodName =~ /.*::.*/xsm){
        $self->{'IsStaticMockStore'}{$MethodName} = 1;
        my $PointerOriginalMethod = \&{$MethodName};
        #In order to have the current object available in the parameter list, it has to be injected here.
        return $self->_addMockWithMethodSpy($MethodName, sub {
            return $PointerOriginalMethod->(@_);
        });
    }else{
        Error("The function you like to spy needs to be defined with a fully qualified path. e.g. 'Path::To::Your::$MethodName' instead of only '$MethodName'");
    }
}
=pod

=head2 mockConstructor

Sometimes it is not possible to inject the dependencies from the outside. This method gives you the posibility to override the constructor of a package where your Sut depends on.
The defaut constructor is C<new> if you need another constructor name, use the third parameter.

Attention: The mocked constructor is valid as long as the Mockify object is defined. If You leave the scope or set the Mockify object to undef the injected constructor will be released.

=head3 synopsis

  package Path::To::SUT;
  use Path::To::Package;
  sub callToAction {
      shift;
      return Path::To::Package->new()->doAction();
  }
  1;

In the Test it can be mocked like:

  package Test_SUT;
  { # start scope
      my $MockifySut = Test::Mockify::Sut->new( 'Path::To::SUT', [] );
      $MockifySut->mockConstructor('Path::To::Package', $self->_createPathToPackage()); 
      my $Test_SUT = $MockifySut->getMockObject();

      is($Test_SUT->callToAction(), 'hello');
  } # end scope

  sub _createPathToPackage{
      my $self = shift;
      my $Mockify = Test::Mockify::Sut->new( 'Path::To::Package', [] );
      $Mockify->mock('doAction')->when()->thenReturn('hello');
      return $Mockify->getMockObject();
  }

It can be mixed with normal C<spy>.

=cut
sub mockConstructor {
    my $self = shift;
    my ($PackageName,  $Object, $ConstructorName) = @_;
    $ConstructorName //= 'new';
    if($PackageName && IsString($PackageName)){
            #note for my self: It is not possible to use thenReturn one level up since 'mockStatic' will mock the constructor before this line has finished.
            # It is impossible to create an instance with the already mocked constructor.
            return $self->mockStatic( sprintf('%s::%s', $PackageName, $ConstructorName) )->whenAny()->thenReturn($Object);
    }else{
        Error('Wrong or missing parameter list. Please use it like: $Mockify->mockConstructor(\'Path::To::Package\', $Object, \'new\')'); ## no critic (RequireInterpolationOfMetachars)
    }
}
=pod

=head2 getVerificationObject

Provides the actual mock object, which you can use for verification.
This is code sugar for the method C<getMockObject>.

  my $Mockify = Test::Mockify::Sut->new( 'My::Module', [] );
  my $VerificationObject = $Mockify->getVerificationObject();
  ok(WasCalled($VerificationObject, 'FunctionName'));
=cut
sub getVerificationObject{
    my $self = shift;
    return $self->getMockObject();
}

1;