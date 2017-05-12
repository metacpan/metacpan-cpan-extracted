#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Test::More;

my $class = 'Text::Guess::Language';

use_ok($class);

my $text =<<TEXT;

Maddələr[redaktə | əsas redaktə]
Maddə 1[redaktə | əsas redaktə]
Bütün insanlar öz ləyaqətləri və hüquqları etibarilə azad və bərabər doğulurlar. Onlara ağıl və vicdan bəxş edilib və onlar bir-birinə münasibətdə qardaşlıq ruhunda davranmalıdırlar.

Maddə 2[redaktə | əsas redaktə]
Hər bir insan, irqi, dərisinin rəngi, cinsi, dili, dini, siyasi və digər əqidələri, milli və sosial mənsubiyyəti, əmlak vəziyyəti, silk mənsubiyyəti və digər vəziyyətlərinə görə heç bir fərq qoyulmadan hazırkı Bəyannamədə bəyan edilən bütün hüquqlara və bütün azadlıqlara malik olmalıdır.

Bundan əlavə, insanın mənsub olduğu ölkənin və ya ərazinin siyasi, hüquqi və beynəlxalq statusuna, bu ərazinin müstəqil, asılı, özünü idarə etməyən və ya suverenliyi hər hansı digər şəkildə məhdudlasdıran ərazi olub-olmamasından asılı olmayaraq, heç bir fərq qoyulmamalıdır.

Maddə 3[redaktə | əsas redaktə]
Hər bir insan yasamaq, azadlıq və şəxsi toxunulmazlıq hüququna malikdir.

Maddə 4[redaktə | əsas redaktə]
Heç kim kölə vəziyyətində və ya asılı vəziyyətdə saxlanılmamalıdır: köləliyin və kölə ticarətinin bütün formaları qadağan edilir.

Maddə 5[redaktə | əsas redaktə]
Heç kim işgəncələrə və yaxud ağır, qeyri-insani və ya onun ləyaqətini alçaldan rəftara və cəzaya məruz qalmamalıdır.

Maddə 6[redaktə | əsas redaktə]
Hər bir insan, harada olmasından asılı olmayaraq, özünün hüquq subyekti kimi qəbul edilməsi hüququna malikdir.

Maddə 7[redaktə | əsas redaktə]
Bütün insanlar qanun qarşısında bərabərdirlər və heç bir fərq qoyulmadan qanun tərəfindən bərabər müdafiə olunmaq hüququna malikdirlər. Bütün insanlar, hazırkı Bəyannaməni pozan istənilən ayrı-seçkilik aktından və belə bir ayrı-seçkiliyə hər cür təhrikdən müdafiə olunmaqda bərabər hüquqlara malikdirlər.

Maddə 8[redaktə | əsas redaktə]
Hər bir insan, Konstitusiya və ya qanunla ona verilən əsas hüquqlarının pozulması hallarında səlahiyyətli məhkəmələr tərəfindən bu hüquqlarının səmərəli şəkildə bərpa edilməsi hüququna malikdir.

Maddə 9[redaktə | əsas redaktə]
Heç kəs özbaşınalıqla həbsə, tutulub saxlanılmaya və ya sürgün edilməyə məruz qala bilməz.

Maddə 10[redaktə | əsas redaktə]
Hər bir insan öz hüquq və vəzifələrini müəyyənləşdirmək üçün və ona qarşı qaldırılan cinayət ittihamının əsaslandırılmıs olub-olmamasını aydınlaşdırmaq üçün ona qarşı qaldırılan isə müstəqil və qərəzsiz məhkəmə tərəfindən tam bərabərlik əsasında, açıq və ədalətin bütün tələblərinə riayət olunmaqla baxılmasını tələb etmək hüququna malikdir.

Maddə 11[redaktə | əsas redaktə]
1.Cinayət törətməkdə ittiham edilən hər bir insan, ona bütün müdafiə imkanları təmin edilməklə, açıq məhkəmə arasdırması yolu ilə onun günahkar olduğu qanuni qaydada müəyyən edilməyənə qədər günahsız hesab edilmək hüququna malikdir.
2. Heç kim, törədildiyi zaman milli qanunlara və ya beynəlxalq hüquqa görə cinayət tərkibi dasımayan hər hansı bir əməl və ya fəaliyyətsizlik əsasında cinayət törətməkdə ittiham oluna bilməz. Habelə, cinayətin törədildiyi zaman tətbiq edilə bilən cəzadan ağır cəza verilə bilməz.
Maddə 12[redaktə | əsas redaktə]
Heç kimin şəxsi və ailə həyatına özbaşınalıqla müdaxilə, evinin toxunulmazlığına, gizli məktublaşmalarına, sərəf və nüfuzuna özbaşınalıqla qəsd edilə bilməz. Hər bir insan bu cür müdaxilələrdən və ya belə qəsdlərdən qanunla müdafiə olunmaq hüququna malikdir.

Maddə 13[redaktə | əsas redaktə]
1. Hər bir insan, hər bir dövlətin hüdudları daxilində sərbəst hərəkət etmək və özünə yaşayış yeri seçmək hüququna malikdir.
2. Hər bir insan, öz ölkəsi də daxil olmaqla istənilən ölkəni tərk etmək və öz ölkəsinə qayıtmaq hüququna malikdir.
Maddə 14[redaktə | əsas redaktə]
1. Hər bir insan təqiblərdən qurtulmaq üçün digər ölkələrdə sığınacaq axtarmaq və bu sığınacaqdan istifadə etmək hüququna malikdir.
2. Bu hüquqdan, əslində Birləşmiş Millətlər Təskilatının məqsəd və prinsiplərinə zidd olan qeyri-siyasi xarakterli cinayətlər və ya əməllər törətməyə görə təqiblərdən qurtulmağa çalışılması hallarında istifadə edilə bilməz.
Maddə 15[redaktə | əsas redaktə]
1. Hər bir insan vətəndaşlıq hüququna malikdir.
2. Heç kim öz vətəndaşlığından və öz vətəndaşlığını dəyişmək hüququndan məhrum edilə bilməz.
Maddə 16[redaktə | əsas redaktə]
1. Yetkinlik yaşına çatmıs kişilər və qadınlar, irqi, milli və ya dini əlamətlərinə görə heç bir məhdudiyyət qoyulmadan nikah bağlamaq və ailə qurmaq hüququna malikdirlər. Onlar nikah bağlayarkən, nikah vəziyyətində olarkən və onun pozulması zamanı eyni hüquqlardan istifadə edirlər.
2. Nikah yalnız hər iki tərəfin sərbəst və tam razılığı ilə bağlana bilər.
3. Ailə cəmiyyətin təbii və əsas özəyidir və o, cəmiyyət və dövlət tərəfindən müdafiə olunmaq hüququna malikdir.
Maddə 17[redaktə | əsas redaktə]
1. Hər bir insan təkbaşına və ya başqaları ilə birlikdə əmlaka sahib olmaq hüququna malikdir.
2. Heç kim öz əmlakından özbaşınalıqla məhrum edilməməlidir.
Maddə 18[redaktə | əsas redaktə]
Hər bir insan düşüncə, vicdan və din azadlığı hüququna malikdir: bu hüquqa öz dinini və ya əqidəsini dəyismək azadlığı, öz dininə və ya əqidəsinə həm təkbaşına, həm də basqaları ilə birlikdə, dini təlimdə, ibadətdə və dini mərasim qaydalarının yerinə yetirilməsində açıq və özəl qaydada etiqad etmək azadlığı daxildir.

Maddə 19[redaktə | əsas redaktə]
Hər bir insan əqidə azadlığı və onu sərbəst ifadə etmək azadlığı hüququna malikdir: bu hüquqa maneəsiz olaraq öz əqidəsində qalmaq azadlığı və istənilən vasitələrlə və dövlət sərhədlərindən asılı olmayaraq, informasiya və ideyalar axtarmaq, almaq və yaymaq azadlığı daxildir.

Maddə 20[redaktə | əsas redaktə]
1. Hər bir insan dinc yığıncaqlar keçirmək və assosiasiyalar qurmaq hüququna malikdir.
2. Heç kim hər hansı bir assosiasiyaya daxil olmağa məcbur edilə bilməz.
Maddə 21[redaktə | əsas redaktə]
1. Hər bir insan öz ölkəsinin idarə edilməsində bilavasitə və yaxud azad seçilən nümayəndələr vasitəsilə istirak etmək hüququna malikdir.
2. Hər bir insan öz ölkəsində dövlət qulluğuna hamıyla bərabər yol tapmaq hüququna malikdir.
3. Xalqın iradəsi hökumətin hakimiyyətinin əsası olmalıdır; bu iradə, vaxtasırı və saxtalasdırılmadan, ümumi və bərabər seçki hüququ əsasında, gizli səsverməyolu ilə və yaxud səsvermə azadlığını təmin edən digər eynimənalı formalar vasitəsilə keçirilən seçkilərdə öz əksini tapmalıdır.
Maddə 22[redaktə | əsas redaktə]
Cəmiyyətin bir üzvü kimi, hər bir insan sosial təminat hüququna və öz ləyaqətini qoruyub saxlaya bilmək və öz şəxsiyyətini azad inkisaf etdirmək üçün iqtisadi, sosial və mədəni sahələrdə zəruri olan hüquqlarını milli səylər və beynəlxalq əməkdaslıq vasitəsilə, hər bir dövlətin strukturu və resurslarına müvafiq olaraq həyata keçirmək hüququna malikdir.

Maddə 23[redaktə | əsas redaktə]
1. Hər bir insan işləmək, istədiyi işi sərbəst seçmək, ədalətli və əlverişli iş şəraitinə malik olmaq və işsizlikdən müdafiə olunmaq hüququna malikdir.
2. Hər bir insan, heç bir ayrı-seçkiliyə məruz qalmadan, bərabər əməyə görə bərabər haqq almaq hüququna malikdir.
3. Đsləyən hər bir insan, onun özünün və ailəsinin layiqli dolanışığını təmin edən, ədalətli və qənaətbəxş həcmdə zəruri hallarda isə digər sosial təminat vəsaitləri ona əlavə edilməklə haqq almaq hüququna malikdir.
4. Hər bir insan, öz mənafelərini müdafiə etmək üçün həmkarlar ittifaqları yaratmaq və həmkarlar ittifaqlarına daxil olmaq hüququna malikdir.
Maddə 24[redaktə | əsas redaktə]
Hər bir insan, is gününün səmərəli məhdudlaşdırılması və ödənilən vaxtaşırı məzuniyyət hüququ da daxil edilməklə istirahət və asudə vaxt hüququna malikdir.

Maddə 25[redaktə | əsas redaktə]
1. Hər bir insan, qida, geyim, mənzil, tibbi qulluq və zəruri sosial xidmətlər də daxil olmaqla onun özünün və ailəsinin sağlamlığının və rifahının qorunub saxlanılması üçün zəruri olan həyat səviyyəsinə malik olmaq hüququna və işsizlik, xəstəlik, əlillik, dulluq, qocalıq halında və ondan asılı olmayan digər səbəblərə görə dolanışıq vəsaitlərini itirdiyi halda təminat hüququna malikdir.
2. Analıq və körpəlik xüsusi himayə və yardım hüququ verir. Nikahlı və yaxud nikahsız doğulmuş bütün uşaqlar eyni sosial müdafiədən istifadə etməlidirlər.
Maddə 26[redaktə | əsas redaktə]
1. Hər bir insan təhsil almaq hüququna malikdir. Təhsil ən azı ibtidai və ümumi səviyyələrdə pulsuz olmalıdır. Đbtidai təhsil məcburi olmalıdır. Hamının texniki və peşə təhsili almaq imkanı olmalıdır və hər bir insanın qabiliyyəti əsasında hamının eyni dərəcədə ali təhsil almaq imkanı olmalıdır.
2. Təhsil insan şəxsiyyətinin tam inkisafına və insan hüquqlarına və əsas azadlıqlara hörmətin artırılmasına yönəldilməlidir. Təhsil bütün xalqlar, irqi və dini qruplar arasında qarşılıqlı anlasmaya, dözümlülüyə və dostluğa yardımçı olmalı və Birləşmiş Millətlər Təşkilatının sülhün qorunub saxlanması ilə bağlı fəaliyyətinə köməklik göstərməlidir.
3.Valideynlər öz kiçik yaşlı usaqları üçün təhsil növlərini seçməkdə prioritet hüquqa malikdirlər.
Maddə 27[redaktə | əsas redaktə]
1. Hər bir insan, cəmiyyətin mədəni həyatında iştirak etmək, incəsənətdən həzz almaq, elmi tərəqqidə iştirak etmək və onun nemətlərindən
istifadə etmək hüququna malikdir.

2. Hər bir insan, müəllifi olduğu elmi, ədəbi və bədii əsərlərin nəticəsi olan mənəvi və maddi mənafelərinin müdafiə olunması hüququna malikdir.
Maddə 28[redaktə | əsas redaktə]
Hər bir insan, hazırkı Bəyannamədə ifadə edilən hüquq və azadlıqların tam şəkildə həyata keçirilməsinə sərait yaradan sosial və beynəlxalq idarə üsulu hüququna malikdir.

Maddə 29[redaktə | əsas redaktə]
1. Hər bir insan elə bir cəmiyyət qarşısında məsuliyyət dasıyır ki, onun şəxsiyyətinin azad və tam inkişafı yalnız o cəmiyyətdə mümkündür.
2. Hər bir insan öz hüquq və azadlıqlarını həyata keçirərkən yalnız o məhdudiyyətlərə məruz qala bilər ki, onlar müstəsna olaraq, başqalarının
hüquq və azadlıqlarının lazımı qaydada tanınması və onlara hörmət edilməsinin təmin edilməsi və demokratik cəmiyyətdə əxlaq qaydalarının, ictimai asayişin və ümumi rifahın ədalətli rəhbərlərin ödənilməsi naminə qanunla müəyyən edilmisdir.

3. Bu hüquq və azadlıqların həyata keçirilməsi heç bir halda Birləşmiş Millətlər Təşkilatının məqsəd və prinsiplərinə zidd olmamalıdır.
Maddə 30[redaktə | əsas redaktə]
Hazırkı Bəyannamənin heç bir müddəası hansısa dövlətə, insan qrupuna və ya ayrı-ayrı şəxslərə, hazırkı Bəyannamədə ifadə olunan hüquq və azadlıqların ləğv edilməsinə yönəldilən hər hansı bir fəaliyyətlə məsğul olmaq və ya hər hansı bir əməl törətmək hüququnun verilməsi kimi şərh edilə bilməz.
TEXT

is(Text::Guess::Language->guess($text),'az','is az');

done_testing;
