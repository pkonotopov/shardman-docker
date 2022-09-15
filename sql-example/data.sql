--
-- Generate data
--

begin;
insert into author values
(gen_random_uuid(),'Heather Evans'),
(gen_random_uuid(),'Aedan Turnbull'),
(gen_random_uuid(),'Shelby Bevan'),
(gen_random_uuid(),'Lewie Pollard'),
(gen_random_uuid(),'Maddox Small'),
(gen_random_uuid(),'Ella-Mai Finney'),
(gen_random_uuid(),'Emelie Rodrigues'),
(gen_random_uuid(),'Annabell Gates'),
(gen_random_uuid(),'Belinda Proctor'),
(gen_random_uuid(),'Zena Hancock'),
(gen_random_uuid(),'Gus Philip'),
(gen_random_uuid(),'Brandi Irving'),
(gen_random_uuid(),'Zayaan Rubio'),
(gen_random_uuid(),'Danyl Mclean'),
(gen_random_uuid(),'Jack Campos'),
(gen_random_uuid(),'Felicity Truong'),
(gen_random_uuid(),'Tanvir Cordova'),
(gen_random_uuid(),'Kellan Appleton'),
(gen_random_uuid(),'Cillian Charlton'),
(gen_random_uuid(),'Aroush Ramsay'),
(gen_random_uuid(),'Yasmin Randolph'),
(gen_random_uuid(),'Rachelle Swanson'),
(gen_random_uuid(),'Sam Underwood'),
(gen_random_uuid(),'Hugh Carty'),
(gen_random_uuid(),'Sommer Blackmore'),
(gen_random_uuid(),'Lilia Rocha'),
(gen_random_uuid(),'Lilly-Grace Quintana'),
(gen_random_uuid(),'Jaeden Wu'),
(gen_random_uuid(),'Alara Bentley'),
(gen_random_uuid(),'Milo Estrada'),
(gen_random_uuid(),'Kasper Lynch'),
(gen_random_uuid(),'Zara Mcmahon'),
(gen_random_uuid(),'Cloe Bouvet'),
(gen_random_uuid(),'Rosemarie Daugherty'),
(gen_random_uuid(),'Ayush Whyte'),
(gen_random_uuid(),'Aneesa Villanueva'),
(gen_random_uuid(),'Mikayla Mercado'),
(gen_random_uuid(),'Antoinette Compton'),
(gen_random_uuid(),'Findlay Kemp'),
(gen_random_uuid(),'Onur Mendez');

insert into rstatus values 
(gen_random_uuid(),'draft','Draft image'),
(gen_random_uuid(),'preview','In preview'),
(gen_random_uuid(),'done','Already done'),
(gen_random_uuid(),'stage','On stage'),
(gen_random_uuid(),'preprod','In preproduction'),
(gen_random_uuid(),'inprocess','Currently in work process'),
(gen_random_uuid(),'banned','Banned due content'),
(gen_random_uuid(),'removed','Removed from pipline'),
(gen_random_uuid(),'payed','Payed'),
(gen_random_uuid(),'rejected','Rejected from payment'),
(gen_random_uuid(),'accepted','Accepeted for payment'),
(gen_random_uuid(),'closed','Close image'),
(gen_random_uuid(),'appended','Append preview'),
(gen_random_uuid(),'fired','Fire image'),
(gen_random_uuid(),'broken','Broken'),
(gen_random_uuid(),'censored','Cesored'),
(gen_random_uuid(),'excluded','Exclude image from work process'),
(gen_random_uuid(),'executed','Execute due content'),
(gen_random_uuid(),'solved','Solved from pipline'),
(gen_random_uuid(),'unpayed','Unpayed'),
(gen_random_uuid(),'returned','Retun to author payment'),
(gen_random_uuid(),'deleted','Deleted from');

insert into rtype values 
(gen_random_uuid(),'low small','100ppi'),
(gen_random_uuid(),'small','150ppi'),
(gen_random_uuid(),'hi small','300ppi'),
(gen_random_uuid(),'low medium','100ppi'),
(gen_random_uuid(),'medium','150ppi'),
(gen_random_uuid(),'hi medium','300ppi'),
(gen_random_uuid(),'low big','100ppi'),
(gen_random_uuid(),'big','150ppi'),
(gen_random_uuid(),'hi big','300ppi'),
(gen_random_uuid(),'huge','10000ppi'),
(gen_random_uuid(),'low x-small','1000ppi'),
(gen_random_uuid(),'x-small','1500ppi'),
(gen_random_uuid(),'hi x-small','3000ppi'),
(gen_random_uuid(),'low x-medium','1000ppi'),
(gen_random_uuid(),'x-medium','1500ppi'),
(gen_random_uuid(),'hi x-medium','3000ppi'),
(gen_random_uuid(),'low x-big','1000ppi'),
(gen_random_uuid(),'x-big','1500ppi'),
(gen_random_uuid(),'hi x-big','3000ppi'),
(gen_random_uuid(),'x-huge','100000ppi');
commit;

begin;
do
$do$
begin
    for i in 1..10000 LOOP
        insert into doc values (
        gen_random_uuid(),
        (select now() - '1 year'::interval * random()),
        (select a.id from (select id from author) as a order by random() limit 1),
        md5(random()::text),
        '',
        (select a.id from (select id from rstatus) as a order by random() limit 1)
        );
    end loop;
end
$do$;

do
$do$
begin
    for i in 1..10000 LOOP
        insert into resolution values (
        gen_random_uuid(),
        (select a.id from (select id from doc) as a order by random() limit 1),
        (select a.id from (select id from author) as a order by random() limit 1),
        md5(random()::text),
        (select a.id from (select id from rtype) as a order by random() limit 1),
        (select now() - '1 year'::interval * random())
        );
    end loop;
end
$do$;
commit;
