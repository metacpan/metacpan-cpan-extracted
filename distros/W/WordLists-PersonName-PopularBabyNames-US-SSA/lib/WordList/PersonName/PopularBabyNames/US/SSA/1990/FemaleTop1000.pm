package WordList::PersonName::PopularBabyNames::US::SSA::1990::FemaleTop1000;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-01'; # DATE
our $DIST = 'WordLists-PersonName-PopularBabyNames-US-SSA'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our $SORT = 'rank';

our %STATS = ("num_words_contain_nonword_chars",0,"longest_word_len",11,"avg_word_len",6.111,"num_words_contains_nonword_chars",0,"num_words_contains_whitespace",0,"num_words_contain_unicode",0,"shortest_word_len",3,"num_words_contains_unicode",0,"num_words_contain_whitespace",0,"num_words",1000); # STATS

1;
# ABSTRACT: Top 1000 most popular names for female babies born in the USA in 1990 (from Social Security Administration)

=pod

=encoding UTF-8

=head1 NAME

WordList::PersonName::PopularBabyNames::US::SSA::1990::FemaleTop1000 - Top 1000 most popular names for female babies born in the USA in 1990 (from Social Security Administration)

=head1 VERSION

This document describes version 0.001 of WordList::PersonName::PopularBabyNames::US::SSA::1990::FemaleTop1000 (from Perl distribution WordLists-PersonName-PopularBabyNames-US-SSA), released on 2020-05-01.

=head1 SYNOPSIS

 use WordList::PersonName::PopularBabyNames::US::SSA::1990::FemaleTop1000;

 my $wl = WordList::PersonName::PopularBabyNames::US::SSA::1990::FemaleTop1000->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

Taken from L<https://www.ssa.gov/oact/babynames/>

Sorted by rank (most popular first).

=head1 STATISTICS

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 6.111 |
 | longest_word_len                 | 11    |
 | num_words                        | 1000  |
 | num_words_contain_nonword_chars  | 0     |
 | num_words_contain_unicode        | 0     |
 | num_words_contain_whitespace     | 0     |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                | 3     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-PersonName-PopularBabyNames-US-SSA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-PersonName-PopularBabyNames-US-SSA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordLists-PersonName-PopularBabyNames-US-SSA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
Jessica
Ashley
Brittany
Amanda
Samantha
Sarah
Stephanie
Jennifer
Elizabeth
Lauren
Megan
Emily
Nicole
Kayla
Amber
Rachel
Courtney
Danielle
Heather
Melissa
Rebecca
Michelle
Tiffany
Chelsea
Christina
Katherine
Alyssa
Jasmine
Laura
Hannah
Kimberly
Kelsey
Victoria
Sara
Mary
Erica
Alexandra
Amy
Crystal
Andrea
Kelly
Kristen
Erin
Brittney
Anna
Taylor
Maria
Allison
Cassandra
Caitlin
Lindsey
Angela
Katie
Alicia
Jamie
Vanessa
Kathryn
Morgan
Jordan
Whitney
Brianna
Christine
Natalie
Lisa
Kristin
Alexis
Jacqueline
Shannon
Lindsay
Brooke
Catherine
Olivia
April
Erika
Katelyn
Monica
Kristina
Kaitlyn
Paige
Molly
Jenna
Leah
Julia
Bianca
Tara
Melanie
Marissa
Cynthia
Holly
Abigail
Meghan
Kathleen
Julie
Ariel
Alexandria
Veronica
Patricia
Diana
Gabrielle
Shelby
Kaitlin
Margaret
Brandi
Krystal
Natasha
Casey
Bethany
Haley
Briana
Kara
Rachael
Miranda
Breanna
Dana
Leslie
Caroline
Kendra
Sabrina
Angelica
Karen
Felicia
Jillian
Brenda
Ana
Desiree
Meagan
Katrina
Chelsey
Valerie
Emma
Nancy
Alison
Monique
Sandra
Alisha
Britney
Brandy
Joanna
Gina
Grace
Sierra
Candace
Jaclyn
Adriana
Krista
Alexa
Candice
Lacey
Rebekah
Sydney
Nichole
Denise
Dominique
Ashlee
Anne
Yesenia
Kirsten
Claire
Deanna
Colleen
Audrey
Mallory
Carly
Tabitha
Cristina
Raven
Priscilla
Stacey
Carolyn
Carrie
Kiara
Susan
Stacy
Angel
Linda
Mercedes
Autumn
Ashleigh
Kylie
Teresa
Gabriela
Kelli
Caitlyn
Renee
Arielle
Cindy
Ebony
Justine
Karina
Meredith
Bridget
Hillary
Daisy
Amelia
Mayra
Theresa
Claudia
Madeline
Sasha
Heidi
Robin
Destiny
Madison
Lydia
Savannah
Wendy
Barbara
Melinda
Tamara
Ellen
Alejandra
Chloe
Marie
Jenny
Virginia
Kasey
Jocelyn
Carmen
Jade
Evelyn
Jacquelyn
Abby
Janet
Martha
Tracy
Cortney
Bailey
Ariana
Cassie
Brittani
Jasmin
Hilary
Kaylee
Adrienne
Cara
Allyson
Kristine
Pamela
Raquel
Tina
Gloria
Rosa
Camille
Michele
Tiara
Tasha
Mackenzie
Kristy
Ann
Shawna
Sophia
Tanya
Jessie
Latoya
Marisa
Kari
Carissa
Janelle
Mariah
Nina
Angelina
Deborah
Carla
Kellie
Elise
Hope
Hayley
Cierra
Kristi
Kate
Summer
Aimee
Chelsie
Sharon
Toni
Karla
Alissa
Devon
Misty
Regina
Jeanette
Nikki
Esther
Miriam
Tatiana
Christy
Charlotte
Maggie
Stefanie
Tessa
Ruby
Gabriella
Hailey
Ciara
Callie
Faith
Paula
Aubrey
Asia
Naomi
Jazmine
Jazmin
Carolina
Tia
Ruth
Trisha
Rose
Kelley
Robyn
Jaime
Michaela
Kassandra
Karissa
Sonia
Melody
Christian
Helen
Devin
Donna
Brianne
Kelsie
Clarissa
Lori
Marina
Adrianna
Cecilia
Shaniqua
Guadalupe
Jill
Rachelle
Ashton
Cheyenne
Annie
Sylvia
Taryn
Roxanne
Shayla
Randi
Isabel
Leticia
Mia
Eva
Katlyn
Hanna
Alice
Jane
Simone
Elisabeth
Carol
Shana
Frances
Elena
Tierra
Antoinette
Lacy
Ericka
Brittni
Latasha
Alyson
Dawn
Yvette
Chantel
Diane
Shauna
Tonya
Liliana
Lillian
Meaghan
Alana
Suzanne
Yvonne
Christa
Chasity
Johanna
Joy
Kristie
Rochelle
Katelynn
Bonnie
Sandy
Daniela
Lorena
Anastasia
Lyndsey
Irene
Alma
Tanisha
Keri
Leanna
Marlene
Yolanda
Beth
Blanca
Maribel
Charlene
Nadia
Keisha
Celeste
Marisol
Maya
Katharine
Larissa
Kourtney
Anita
Casandra
Corinne
Kendall
Shaina
Elaine
Alysha
Arianna
Shayna
Sheila
Kayleigh
Cheryl
Tabatha
Iris
Brenna
Chanel
Stacie
Elisa
Kylee
Mindy
Tiana
Esmeralda
Dorothy
Juliana
Kyla
Diamond
Shanna
Nora
Marilyn
Infant
Kierra
Josephine
Kaila
Kerri
Christie
Staci
Bridgette
Alaina
Stephany
Ciera
Kali
Julianne
Kerry
Jalisa
Vivian
Lucy
Tammy
Sally
Precious
Judith
Debra
Sadie
Tiffani
Kirstie
Charity
Alisa
Krystle
Eileen
Margarita
Noelle
Francesca
Mollie
Mandy
Tori
Leigh
Sheena
Beatriz
Cassidy
Patrice
Alanna
Jodi
Traci
Ashlie
Janice
Joyce
Natalia
Desirae
Jordyn
Abbey
Connie
Darlene
Blair
Genevieve
Maritza
India
Tania
Mckenzie
Britany
Tracey
Latisha
Norma
Tricia
Kelsi
Maureen
Breanne
Shantel
Angelia
Daniella
Janae
Zoe
Kathy
Serena
Constance
Jaimie
Mariana
Rosemary
Shirley
Annette
Nicolette
Sonya
Katy
Clara
Lea
Loren
Kacie
Kristyn
Cristal
Jami
Alycia
Jackie
Beverly
Lena
Ryan
Elyse
Kira
Gladys
Kaleigh
Juanita
Laurel
Isamar
Leanne
Tyler
Ashly
Justina
Lara
Mara
Jacklyn
Lesley
Paris
Kala
Carina
Rita
Jana
Rocio
Breana
Whitley
Cayla
Brandie
Brittanie
Chantal
Terri
Eliza
Susana
Araceli
Edith
Alexia
Ashlyn
Joanne
Skylar
Jena
Kirstin
Shelly
Kiera
Aisha
Katelin
Paulina
Kyra
Sade
Betty
Cecily
Tamika
Tess
Judy
Madeleine
Maegan
Allie
Lucia
Sherry
Lynn
Maricela
Lily
Angie
Jennie
Emilee
Celia
Genesis
Lakeisha
Noemi
Brittny
Keshia
Dianna
Jayme
Dakota
Maranda
Savanna
Eleanor
Jessika
Kaley
Adrian
Kailey
Luz
Rhonda
Sophie
Talia
Britni
Jerrica
Silvia
Hollie
Logan
Shante
Kenya
Marisela
Christin
Emilie
Octavia
Josie
Fatima
Kaci
Kiersten
Lizbeth
Belinda
Gretchen
Jenifer
Lizette
Katlin
Kristian
Perla
Bryanna
Janette
Terra
Yadira
Angelique
Ashely
Racheal
Bobbie
Danica
Dayna
Macy
Lacie
Maura
Alysia
Corina
Elisha
Sofia
Jesse
Laurie
Christen
Kacey
Stevie
Alexandrea
Lorraine
Kaitlynn
Clare
Jaleesa
Julianna
Antonia
Janine
Nikita
Nathalie
Yessenia
Alina
Paola
Janie
Kimberley
Viviana
Devan
Kasandra
Audra
Rhiannon
Corey
Janessa
Cameron
Yasmin
Kortney
Kaylyn
Abbie
Arlene
Gwendolyn
Alecia
Irma
Joann
Valeria
Roxana
Brittaney
Ali
Skye
Kristal
Shanae
Tiffanie
Alesha
Leann
Nadine
Amie
Eden
Chrystal
Domonique
Lauryn
Myra
Latifah
Celina
Cori
Giselle
Shelley
Allyssa
Krysta
Tayler
Kimberlee
Mikayla
Tianna
Brittnee
Lyndsay
Aurora
Kanisha
Janay
Kaylin
Georgia
Beatrice
Ashli
Britny
Chantelle
Rebeca
Shanice
Reyna
Shanika
Cassondra
Griselda
Jerica
Athena
Iesha
Porsha
Rubi
Madelyn
Iliana
Skyler
Stefani
Bernadette
Betsy
Ingrid
Chandra
Debbie
Elissa
Trista
Deja
Michael
Anabel
Kandice
Kassie
Latrice
Dina
Kiley
Kandace
Krystina
Pauline
Martika
Kiana
Marcella
Princess
Carley
Chelsi
Joan
Selina
Daphne
Keely
Lora
Tiera
Ivy
Jeannette
Bobbi
Jean
Breann
Felisha
Hallie
Julissa
Melisa
Mikaela
Kelsea
Selena
Kathrine
Darcy
Olga
Adrianne
Kim
Monika
Phylicia
Laci
Jaqueline
Joelle
Marquita
Noel
Kori
Mai
Jolene
Eboni
Lana
Moriah
Latonya
Liana
Makayla
Alex
Avery
Leandra
Maira
Marla
Kaylie
Kaela
Delia
Tanesha
Micaela
Juana
Leeann
Elsa
Valencia
Alyse
Ayla
Elaina
Charmaine
Gillian
Mariela
Symone
Laquita
Lynette
Melina
Rikki
Riley
Kyle
Sonja
Alessandra
Jamila
Janna
Martina
Tyesha
Billie
Ella
Krysten
Nikole
Teri
Bridgett
Portia
Tameka
Brittnie
Christiana
Deidra
Susanna
Destinee
Kaycee
Cecelia
Fabiola
Geneva
Ivana
Ivette
Kalyn
Aileen
Cora
Doris
Heaven
Becky
Cody
Kia
Nia
Shea
Baby
Gianna
Janell
Cherie
Lucero
Andria
Brook
Phoebe
Jodie
Alexander
Jaimee
Magen
Mandi
Corrine
Kati
Kenisha
Samatha
Sarai
Shelbi
Danika
Dara
Deana
Demetria
Marjorie
Shakira
Liza
Karly
Tera
Lashonda
Maryann
Holli
Isabella
Chaya
Lakeshia
Lissette
Richelle
Alysa
Jessenia
Joana
Marcia
Catrina
Gabriel
Katheryn
Lourdes
Micah
Roxanna
Dominque
Dulce
Brooklyn
Cathy
Nataly
Chastity
Jessi
Magdalena
Trina
Fallon
Loretta
Shanell
Sherri
Sidney
Anjelica
Carlie
Chanelle
Edna
Eunice
Karli
Tracie
Jesica
Kalie
Krystin
Mari
Imani
Marian
Aja
Alannah
Blake
Bree
Fiona
Roberta
Kallie
Shari
Catalina
Lisette
Candy
Danyelle
Helena
Vicky
Geraldine
Kanesha
Lia
Ava
Kristan
Laken
Lee
Dena
Kacy
Mariel
Marsha
Cari
Haleigh
Jeanne
Jesenia
Janel
Marlena
Deidre
Georgina
Luisa
Cory
Dora
Eryn
Lizeth
Annmarie
Danae
Graciela
Shamika
Tosha
Wanda
Christopher
Elyssa
Emilia
Jody
Kimber
Marianne
Malinda
Renae
Shameka
Deirdre
Linsey
Lynsey
Shantell
Asha
Cherish
Tarah
Hali
Jada
Leila
Louise
