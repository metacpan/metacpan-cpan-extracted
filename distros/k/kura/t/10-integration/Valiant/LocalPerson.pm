package LocalPerson;
use Moo;
use Valiant::Validations;
use Valiant::Filters;

has name => (is=>'ro');

validates name => (
  length => {
    maximum => 10,
    minimum => 3,
  }
);

1;
