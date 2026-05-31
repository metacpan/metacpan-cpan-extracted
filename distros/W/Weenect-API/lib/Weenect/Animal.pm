#! perl

use v5.36;
use Object::Pad;
use Class::JSON_Object;
use utf8;

=head1 NAME

Weenect::Animal - animal data

(Remember, the tracker is intended for cats and dogs.)

=cut

=head1 DESCRIPTION

Weenect::Animal describes an animal

=head1 METHODS

Supported methods include:

=head2 activity_level

=head2 birth_date

=head2 breed

=head2 breed_id

=head2 created_at

=head2 habitual_environment

=head2 id

=head2 identification

=head2 is_activated

=head2 is_sterilized

=head2 last_vaccination_date

=head2 last_vet_visit_date

=head2 morphology

=head2 name

=head2 santevet_optin

=head2 sex

=head2 species

=head2 tracker_id

=head2 updated_at

=head2 weight

=cut

class Weenect::Animal :does(Class::JSON_Object) {
    field $activity_level;              # 
    field $birth_date;                  # 
    field $breed;                       # 
    field $breed_id;                    # 
    field $created_at;                  # 
    field $habitual_environment;        # 
    field $id;                          # 
    field $identification;              # 
    field $is_activated;                # 
    field $is_sterilized;               # 
    field $last_vaccination_date;       # 
    field $last_vet_visit_date;         # 
    field $morphology;                  # 
    field $name;                        # 
    field $santevet_optin;              # 
    field $sex;                         # 
    field $species;                     # 
    field $tracker_id;                  # 
    field $updated_at;                  # 
    field $weight;                      # 
}

class Weenect::Animals :does(Class::JSON_Object) {
    field $total;
    field @items :Class(Weenect::Animal);
}

1;
