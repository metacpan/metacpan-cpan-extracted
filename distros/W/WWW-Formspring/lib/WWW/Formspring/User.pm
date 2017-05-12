package WWW::Formspring::User;

use Moose;

use WWW::Formspring;

has 'username' => ( is => 'rw', isa => 'Str', predicate => 'has_username' );
has 'name' => ( is => 'rw', isa => 'Str', predicate => 'has_name' );
has 'website' => ( is => 'rw', isa => 'Str', predicate => 'has_website' );
has 'location' => ( is => 'rw', isa => 'Str', predicate => 'has_location' );
has 'bio' => ( is => 'rw', isa => 'Str', predicate => 'has_bio' );
has 'photo_url' => ( is => 'rw', isa => 'Str', predicate => 'has_photo_url' );
has 'answered_count' => ( is => 'rw', isa => 'Int', predicate => 'has_answered_count' );
has 'is_following' => ( is => 'rw', isa => 'Bool', predicate => 'has_is_following' );
has 'protected' => ( is => 'rw', isa => 'Bool' );
has 'taking_questions' => (is => 'rw', isa => 'Bool' );

__PACKAGE__->meta->make_immutable;

1;
