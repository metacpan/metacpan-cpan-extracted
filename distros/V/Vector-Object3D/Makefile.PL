use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Vector::Object3D',
    VERSION_FROM     => 'lib/Vector/Object3D.pm',
    PREREQ_PM        => {
                            Carp             => 0,
                            IO::Scalar       => 0,
                            Math::VectorReal => 0,
                            Moose            => 0,
                            Readonly         => 0,
                            Scalar::Util     => 0,
                            Test::Deep       => 0,
                            Test::Exception  => 0,
                            Test::More       => 0,
                        },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Vector/Object3D.pm',
       AUTHOR        => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
);
