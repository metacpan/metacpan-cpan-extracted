#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test: Multiple packages with inheritance
# 
# Create a class hierarchy:
#   Animal (base class)
#     -> Dog (inherits from Animal)
#     -> Cat (inherits from Animal)
#   
#   Pet::Owner (separate package)
# ============================================

subtest 'Multiple packages with inheritance' => sub {
    my $b = XS::JIT::Builder->new;
    
    # ========================================
    # Animal base class methods
    # ========================================
    
    # Animal constructor
    $b->xs_function('animal_new')
      ->xs_preamble
      ->new_hv('hv')
      ->declare_sv('name_sv', 'items > 1 ? ST(1) : &PL_sv_undef')
      ->hv_store('hv', 'name', 4, 'newSVsv(name_sv)')
      ->hv_store('hv', 'sound', 5, 'newSVpv("unknown", 0)')
      ->raw('SV* self = newRV_noinc((SV*)hv);')
      ->raw('sv_bless(self, gv_stashpv(SvPV_nolen(ST(0)), GV_ADD));')
      ->return_sv('self')
      ->xs_end
      ->blank;
    
    # Animal::name accessor (rw)
    $b->xs_function('animal_name')
      ->xs_preamble
      ->get_self_hv
      ->if('items > 1')
        ->hv_store('hv', 'name', 4, 'newSVsv(ST(1))')
      ->endif
      ->hv_fetch('hv', 'name', 4, 'val')
      ->if('val != NULL')
        ->return_sv('*val')
      ->endif
      ->return_undef
      ->xs_end
      ->blank;
    
    # Animal::sound accessor (ro)
    $b->xs_function('animal_sound')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'sound', 5, 'val')
      ->if('val != NULL')
        ->return_sv('*val')
      ->endif
      ->return_undef
      ->xs_end
      ->blank;
    
    # Animal::speak - returns "name says sound"
    $b->xs_function('animal_speak')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'name', 4, 'name_val')
      ->hv_fetch('hv', 'sound', 5, 'sound_val')
      ->declare_pv('name_str', 'name_val && *name_val ? SvPV_nolen(*name_val) : "Unknown"')
      ->declare_pv('sound_str', 'sound_val && *sound_val ? SvPV_nolen(*sound_val) : "..."')
      ->raw('SV* result = newSVpvf("%s says %s", name_str, sound_str);')
      ->return_sv('sv_2mortal(result)')
      ->xs_end
      ->blank;
    
    # ========================================
    # Dog class methods (inherits from Animal)
    # ========================================
    
    # Dog constructor - calls parent-like behavior
    $b->xs_function('dog_new')
      ->xs_preamble
      ->new_hv('hv')
      ->declare_sv('name_sv', 'items > 1 ? ST(1) : &PL_sv_undef')
      ->hv_store('hv', 'name', 4, 'newSVsv(name_sv)')
      ->hv_store('hv', 'sound', 5, 'newSVpv("woof", 0)')
      ->hv_store('hv', 'breed', 5, 'items > 2 ? newSVsv(ST(2)) : newSVpv("mutt", 0)')
      ->raw('SV* self = newRV_noinc((SV*)hv);')
      ->raw('sv_bless(self, gv_stashpv("InheritTest::Dog", GV_ADD));')
      ->return_sv('self')
      ->xs_end
      ->blank;
    
    # Dog::breed accessor (ro)
    $b->xs_function('dog_breed')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'breed', 5, 'val')
      ->if('val != NULL')
        ->return_sv('*val')
      ->endif
      ->return_undef
      ->xs_end
      ->blank;
    
    # Dog::fetch - dog-specific method
    $b->xs_function('dog_fetch')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'name', 4, 'name_val')
      ->declare_pv('name_str', 'name_val && *name_val ? SvPV_nolen(*name_val) : "Dog"')
      ->raw('SV* result = newSVpvf("%s fetches the ball!", name_str);')
      ->return_sv('sv_2mortal(result)')
      ->xs_end
      ->blank;
    
    # ========================================
    # Cat class methods (inherits from Animal)
    # ========================================
    
    # Cat constructor
    $b->xs_function('cat_new')
      ->xs_preamble
      ->new_hv('hv')
      ->declare_sv('name_sv', 'items > 1 ? ST(1) : &PL_sv_undef')
      ->hv_store('hv', 'name', 4, 'newSVsv(name_sv)')
      ->hv_store('hv', 'sound', 5, 'newSVpv("meow", 0)')
      ->hv_store('hv', 'lives', 5, 'newSViv(9)')
      ->raw('SV* self = newRV_noinc((SV*)hv);')
      ->raw('sv_bless(self, gv_stashpv("InheritTest::Cat", GV_ADD));')
      ->return_sv('self')
      ->xs_end
      ->blank;
    
    # Cat::lives accessor (rw)
    $b->xs_function('cat_lives')
      ->xs_preamble
      ->get_self_hv
      ->if('items > 1')
        ->hv_store('hv', 'lives', 5, 'newSVsv(ST(1))')
      ->endif
      ->hv_fetch('hv', 'lives', 5, 'val')
      ->if('val != NULL')
        ->return_sv('*val')
      ->endif
      ->return_iv('0')
      ->xs_end
      ->blank;
    
    # Cat::pounce - cat-specific method
    $b->xs_function('cat_pounce')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'name', 4, 'name_val')
      ->declare_pv('name_str', 'name_val && *name_val ? SvPV_nolen(*name_val) : "Cat"')
      ->raw('SV* result = newSVpvf("%s pounces!", name_str);')
      ->return_sv('sv_2mortal(result)')
      ->xs_end
      ->blank;
    
    # ========================================
    # Pet::Owner - separate namespace
    # ========================================
    
    # Pet::Owner constructor
    $b->xs_function('owner_new')
      ->xs_preamble
      ->new_hv('hv')
      ->declare_sv('name_sv', 'items > 1 ? ST(1) : &PL_sv_undef')
      ->hv_store('hv', 'name', 4, 'newSVsv(name_sv)')
      ->raw('AV* pets = newAV();')
      ->raw('(void)hv_store(hv, "pets", 4, newRV_noinc((SV*)pets), 0);')
      ->raw('SV* self = newRV_noinc((SV*)hv);')
      ->raw('sv_bless(self, gv_stashpv("InheritTest::Pet::Owner", GV_ADD));')
      ->return_sv('self')
      ->xs_end
      ->blank;
    
    # Pet::Owner::name accessor
    $b->xs_function('owner_name')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'name', 4, 'val')
      ->if('val != NULL')
        ->return_sv('*val')
      ->endif
      ->return_undef
      ->xs_end
      ->blank;
    
    # Pet::Owner::add_pet - adds a pet to the owner's list
    $b->xs_function('owner_add_pet')
      ->xs_preamble
      ->get_self_hv
      ->if('items < 2')
        ->raw('croak("add_pet requires a pet object");')
      ->endif
      ->hv_fetch('hv', 'pets', 4, 'pets_ref')
      ->if('pets_ref && *pets_ref && SvROK(*pets_ref)')
        ->raw('AV* pets = (AV*)SvRV(*pets_ref);')
        ->raw('av_push(pets, newSVsv(ST(1)));')
      ->endif
      ->return_self
      ->xs_end
      ->blank;
    
    # Pet::Owner::pets - returns arrayref of pets
    $b->xs_function('owner_pets')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'pets', 4, 'val')
      ->if('val != NULL')
        ->return_sv('*val')
      ->endif
      ->return_undef
      ->xs_end
      ->blank;
    
    # Pet::Owner::pet_count
    $b->xs_function('owner_pet_count')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'pets', 4, 'pets_ref')
      ->if('pets_ref && *pets_ref && SvROK(*pets_ref)')
        ->raw('AV* pets_av = (AV*)SvRV(*pets_ref);')
        ->raw('ST(0) = sv_2mortal(newSViv(av_len(pets_av) + 1));')
        ->xs_return('1')
      ->else
        ->return_iv('0')
      ->endif
      ->xs_end;
    
    # Compile all functions at once
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'InheritTest',
        cache_dir => $cache_dir,
        functions => {
            # Animal base class
            'InheritTest::Animal::new'   => { source => 'animal_new', is_xs_native => 1 },
            'InheritTest::Animal::name'  => { source => 'animal_name', is_xs_native => 1 },
            'InheritTest::Animal::sound' => { source => 'animal_sound', is_xs_native => 1 },
            'InheritTest::Animal::speak' => { source => 'animal_speak', is_xs_native => 1 },
            
            # Dog class - inherits from Animal
            'InheritTest::Dog::new'   => { source => 'dog_new', is_xs_native => 1 },
            'InheritTest::Dog::breed' => { source => 'dog_breed', is_xs_native => 1 },
            'InheritTest::Dog::fetch' => { source => 'dog_fetch', is_xs_native => 1 },
            
            # Cat class - inherits from Animal
            'InheritTest::Cat::new'    => { source => 'cat_new', is_xs_native => 1 },
            'InheritTest::Cat::lives'  => { source => 'cat_lives', is_xs_native => 1 },
            'InheritTest::Cat::pounce' => { source => 'cat_pounce', is_xs_native => 1 },
            
            # Pet::Owner - separate namespace
            'InheritTest::Pet::Owner::new'       => { source => 'owner_new', is_xs_native => 1 },
            'InheritTest::Pet::Owner::name'      => { source => 'owner_name', is_xs_native => 1 },
            'InheritTest::Pet::Owner::add_pet'   => { source => 'owner_add_pet', is_xs_native => 1 },
            'InheritTest::Pet::Owner::pets'      => { source => 'owner_pets', is_xs_native => 1 },
            'InheritTest::Pet::Owner::pet_count' => { source => 'owner_pet_count', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    # Set up inheritance with parent/base
    {
        package InheritTest::Animal;
        # base class - no parent
    }
    {
        package InheritTest::Dog;
        use parent -norequire => 'InheritTest::Animal';
    }
    {
        package InheritTest::Cat;
        use parent -norequire => 'InheritTest::Animal';
    }
    {
        package InheritTest::Pet::Owner;
        # standalone class
    }
    
    # ========================================
    # Test Animal base class
    # ========================================
    subtest 'Animal base class' => sub {
        my $animal = InheritTest::Animal->new('Generic');
        isa_ok($animal, 'InheritTest::Animal');
        is($animal->name, 'Generic', 'Animal name works');
        is($animal->sound, 'unknown', 'Animal default sound');
        is($animal->speak, 'Generic says unknown', 'Animal speak works');
        
        # Test name setter
        $animal->name('NewName');
        is($animal->name, 'NewName', 'Animal name setter works');
    };
    
    # ========================================
    # Test Dog class (inherits from Animal)
    # ========================================
    subtest 'Dog class with inheritance' => sub {
        my $dog = InheritTest::Dog->new('Buddy', 'Golden Retriever');
        isa_ok($dog, 'InheritTest::Dog');
        isa_ok($dog, 'InheritTest::Animal', 'Dog isa Animal');
        
        # Inherited methods from Animal
        is($dog->name, 'Buddy', 'Dog inherits name accessor');
        is($dog->sound, 'woof', 'Dog has woof sound');
        is($dog->speak, 'Buddy says woof', 'Dog speak uses woof');
        
        # Dog-specific methods
        is($dog->breed, 'Golden Retriever', 'Dog breed works');
        is($dog->fetch, 'Buddy fetches the ball!', 'Dog fetch works');
        
        # Test default breed
        my $mutt = InheritTest::Dog->new('Max');
        is($mutt->breed, 'mutt', 'Dog default breed is mutt');
    };
    
    # ========================================
    # Test Cat class (inherits from Animal)
    # ========================================
    subtest 'Cat class with inheritance' => sub {
        my $cat = InheritTest::Cat->new('Whiskers');
        isa_ok($cat, 'InheritTest::Cat');
        isa_ok($cat, 'InheritTest::Animal', 'Cat isa Animal');
        
        # Inherited methods from Animal
        is($cat->name, 'Whiskers', 'Cat inherits name accessor');
        is($cat->sound, 'meow', 'Cat has meow sound');
        is($cat->speak, 'Whiskers says meow', 'Cat speak uses meow');
        
        # Cat-specific methods
        is($cat->lives, 9, 'Cat has 9 lives');
        is($cat->pounce, 'Whiskers pounces!', 'Cat pounce works');
        
        # Test lives setter
        $cat->lives(8);
        is($cat->lives, 8, 'Cat lives setter works');
    };
    
    # ========================================
    # Test Pet::Owner (separate namespace)
    # ========================================
    subtest 'Pet::Owner separate namespace' => sub {
        my $owner = InheritTest::Pet::Owner->new('Alice');
        isa_ok($owner, 'InheritTest::Pet::Owner');
        is($owner->name, 'Alice', 'Owner name works');
        is($owner->pet_count, 0, 'Owner starts with no pets');
        
        # Add some pets
        my $dog = InheritTest::Dog->new('Rex');
        my $cat = InheritTest::Cat->new('Fluffy');
        
        $owner->add_pet($dog)->add_pet($cat);
        is($owner->pet_count, 2, 'Owner has 2 pets after adding');
        
        # Check pets array
        my $pets = $owner->pets;
        is(ref($pets), 'ARRAY', 'pets returns arrayref');
        is(scalar(@$pets), 2, 'pets has 2 elements');
        isa_ok($pets->[0], 'InheritTest::Dog');
        isa_ok($pets->[1], 'InheritTest::Cat');
        
        # Verify pet properties
        is($pets->[0]->name, 'Rex', 'First pet is Rex');
        is($pets->[1]->name, 'Fluffy', 'Second pet is Fluffy');
    };
    
    # ========================================
    # Test polymorphism
    # ========================================
    subtest 'Polymorphic behavior' => sub {
        my @animals = (
            InheritTest::Animal->new('Thing'),
            InheritTest::Dog->new('Fido'),
            InheritTest::Cat->new('Mittens'),
        );
        
        my @expected = (
            'Thing says unknown',
            'Fido says woof',
            'Mittens says meow',
        );
        
        for my $i (0..$#animals) {
            is($animals[$i]->speak, $expected[$i], "Polymorphic speak for animal $i");
        }
        
        # All are Animals
        for my $animal (@animals) {
            ok($animal->isa('InheritTest::Animal'), ref($animal) . ' isa Animal');
        }
    };
    
    # ========================================
    # Test can() with inheritance
    # ========================================
    subtest 'Method resolution with can()' => sub {
        my $dog = InheritTest::Dog->new('Rover');
        
        # Dog-specific
        ok($dog->can('breed'), 'Dog can breed');
        ok($dog->can('fetch'), 'Dog can fetch');
        
        # Inherited from Animal
        ok($dog->can('name'), 'Dog can name (inherited)');
        ok($dog->can('sound'), 'Dog can sound (inherited)');
        ok($dog->can('speak'), 'Dog can speak (inherited)');
        
        # Cannot do cat things
        ok(!$dog->can('lives'), 'Dog cannot lives');
        ok(!$dog->can('pounce'), 'Dog cannot pounce');
        
        # Animal cannot do subclass things
        my $animal = InheritTest::Animal->new('Base');
        ok(!$animal->can('breed'), 'Animal cannot breed');
        ok(!$animal->can('fetch'), 'Animal cannot fetch');
        ok(!$animal->can('lives'), 'Animal cannot lives');
        ok(!$animal->can('pounce'), 'Animal cannot pounce');
    };
};

# ============================================
# Test: Multiple unrelated packages
# ============================================
subtest 'Multiple unrelated packages' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Math::Utils package
    $b->xs_function('math_add')
      ->xs_preamble
      ->declare_nv('a', 'items > 0 ? SvNV(ST(0)) : 0')
      ->declare_nv('b', 'items > 1 ? SvNV(ST(1)) : 0')
      ->return_nv('a + b')
      ->xs_end
      ->blank;
    
    $b->xs_function('math_multiply')
      ->xs_preamble
      ->declare_nv('a', 'items > 0 ? SvNV(ST(0)) : 0')
      ->declare_nv('b', 'items > 1 ? SvNV(ST(1)) : 0')
      ->return_nv('a * b')
      ->xs_end
      ->blank;
    
    # String::Utils package
    $b->xs_function('string_length')
      ->xs_preamble
      ->if('items < 1')
        ->return_iv('0')
      ->endif
      ->raw('STRLEN len;')
      ->raw('(void)SvPV(ST(0), len);')
      ->raw('ST(0) = sv_2mortal(newSViv(len));')
      ->xs_return('1')
      ->xs_end
      ->blank;
    
    $b->xs_function('string_reverse')
      ->xs_preamble
      ->if('items < 1')
        ->return_pv('""')
      ->endif
      ->raw('STRLEN len;')
      ->raw('const char* str = SvPV(ST(0), len);')
      ->raw('char* buffer = (char*)alloca(len + 1);')
      ->for('STRLEN i = 0', 'i < len', 'i++')
        ->raw('buffer[i] = str[len - 1 - i];')
      ->endfor
      ->raw('buffer[len] = \'\\0\';')
      ->raw('ST(0) = sv_2mortal(newSVpvn(buffer, len));')
      ->xs_return('1')
      ->xs_end
      ->blank;
    
    # Array::Utils package
    $b->xs_function('array_sum')
      ->xs_preamble
      ->declare_nv('sum', '0')
      ->for('int i = 0', 'i < items', 'i++')
        ->raw('sum += SvNV(ST(i));')
      ->endfor
      ->return_nv('sum')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'MultiPackage',
        cache_dir => $cache_dir,
        functions => {
            'MultiPkg::Math::add'      => { source => 'math_add', is_xs_native => 1 },
            'MultiPkg::Math::multiply' => { source => 'math_multiply', is_xs_native => 1 },
            'MultiPkg::String::length' => { source => 'string_length', is_xs_native => 1 },
            'MultiPkg::String::reverse' => { source => 'string_reverse', is_xs_native => 1 },
            'MultiPkg::Array::sum'     => { source => 'array_sum', is_xs_native => 1 },
        },
    ), 'Compile multiple packages');
    
    # Test Math::Utils
    is(MultiPkg::Math::add(2, 3), 5, 'Math add');
    is(MultiPkg::Math::multiply(4, 5), 20, 'Math multiply');
    
    # Test String::Utils
    is(MultiPkg::String::length('hello'), 5, 'String length');
    is(MultiPkg::String::reverse('hello'), 'olleh', 'String reverse');
    is(MultiPkg::String::reverse(''), '', 'String reverse empty');
    
    # Test Array::Utils
    is(MultiPkg::Array::sum(1, 2, 3, 4, 5), 15, 'Array sum');
    is(MultiPkg::Array::sum(), 0, 'Array sum empty');
};

done_testing();
