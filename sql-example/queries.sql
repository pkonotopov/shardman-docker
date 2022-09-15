--
-- example queries 
--

explain (analyze,network,verbose)
SELECT d.*, r.id 
FROM doc        d 
JOIN resolution r 
ON    d.id = r.doc_id 
WHERE d.author_id = 'c7b502a5-adaf-4565-bb1d-988623646cdb'
AND   d.id        = '000900c2-22fa-4d6b-9f3f-476eb1b8b75f'; 

explain (analyze,network,verbose)
SELECT d.*, a.name FROM doc d JOIN author a ON a.id = d.author_id;

explain (analyze,network,verbose)
SELECT d.*, r.id 
FROM doc d 
JOIN resolution r 
 ON d.author_id = r.author_id;

explain (analyze,network,verbose)
SELECT d.*, r.id 
FROM doc d 
JOIN resolution r 
 ON d.id = r.doc_id
JOIN author a 
 ON a.id = d.author_id;

explain (analyze,network,verbose)
SELECT count(d.id) as cnt 
FROM doc d 
JOIN resolution r 
 ON d.id = r.doc_id;

explain (analyze,verbose,network) 
with rownums as 
     (
       SELECT row_number() OVER (partition by d.id order by a.name) AS row, 
              r.id AS res, 
              d.id AS doc, 
              a.name as name 
       FROM doc d 
       JOIN resolution r ON d.id = r.doc_id 
       JOIN author     a ON a.id = d.author_id 
       GROUP BY r.id,d.id,a.name
     ) select row,doc,name from rownums where row > 3;