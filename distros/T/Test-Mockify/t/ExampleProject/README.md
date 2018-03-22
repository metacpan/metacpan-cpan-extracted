# Example project

This is the circus example. On the stage are two shows. A magician and some clowns.

## The !! MAGIC SHOW !!

Summary: You can see a magician who pulls a rabbit out of a cylinder. But sometimes it's a bit snappy.

### lib

The `rabbit.pm` and the `Magician.pm` are both classes. So they have a constructor and methods with a `$self` context.

### test

* `t/test_MagicShow_Rabbit.t` Proves that the `rabbit.pm` behaves as expected.
* `t/test_MagicShow_Magician.t`
  * The `rabbit.pm` is mocked in order to control the snappy behavior when testing the `Magician.pm`.
  * This mock is injected into the `Magician.pm`.
  * Tests the behavior of the code in `Magician.pm`.

# The !! KIDS SHOW !!

Summary: On the stage are two clowns, an old and a new one. Both are sitting on a seesaw and the heaviest will win.
The seesaw is a very modern one, but both of them remember the good old times when they used a timber beam for the kids show.

### lib

The `OldClown.pm` is a perl package with a function. The function has to be called with a fully qualified path. In this case: `t::ExampleProject::KidsShow::OldClown::BeHeavy`
The `NewClown.pm` is a perl package with a exported function. The function has to be called with the imported function name. Here `ShowOfWeight`
The `SeeSaw.pm` is a class with a constructor and methods with a `$self` context. It uses both, the OldClown and the NewClown.
The `TimberBeam.pm` is a perl package with functions. It uses both, the OldClown and the NewClown.

### test

* `t/test_KidsShow_OldClown.t` Prove that the `OldClown.pm` behaves as expected.
* `t/test_KidsShow_NewClown.t` Prove that the `NewClown.pm` behaves as expected.
* `t/test_KidsShow_SeeSaw.t`
  * The `OldClown.pm`is mocked and injected the static function into `SeeSaw.pm`.
  * The `NewClown.pm`is mocked and injected the imported function into `SeeSaw.pm`.
  * Unit test the behavior of the code in `SeeSaw.pm`.
* `t/test_KidsShow_TimberBeam.t`
  * The `OldClown.pm`is mocked and injected the static function into `TimberBeam.pm`.
  * The `NewClown.pm`is mocked and injected the imported function into `TimberBeam.pm`.
  * Unit test the behavior of the code in `TimberBeam.pm`.

# Summary

* You can control with Mockify packages and classes

  Package:
  ```
  Test::Mockify->new('t::ExampleProject::KidsShow::TimberBeam');
  ```

  Class:
  ``` 
  Test::Mockify->new('t::ExampleProject::KidsShow::SeeSaw',['ConstructorParams']);
  ```
* You can mock methods and functions.
  ```
  Mockify->mock('_getAge')->when()->thenReturn('hello'); # method
  Mockify->mock('_GetAge')->when()->thenReturn('hello'); # function
  ```
* You can inject static functions
Attention: The mocked function is valid as long as the $Mockify is defined. If You leave the scope or set the $Mockify to undef the injected method will be released. 
  ```
  $Mockify->mockStatic('Fully::Qualified::Path::FunctionName')->when()->thenReturn('hello');
  ```
* You can inject imported function
  ```
  $Mockify->mockImported('Full::Path', 'FunctionName')->when()->thenReturn('hello');
  ```

