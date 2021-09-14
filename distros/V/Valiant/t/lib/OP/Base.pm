use v5.26;
use Object::Pad;
class OP::Base :repr(HASH) {
  
  use Valiant::Validations;

  has $alive :reader :param;

  validates alive => (
    boolean => {
      state => 0,
    }
  );
}

