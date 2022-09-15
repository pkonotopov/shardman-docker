-- 
-- create schema
--

begin;
create table if not exists author (
    id uuid primary key,
    name text
) with (global);

create table  if not exists rstatus (
    id uuid primary key,
    name text,
    description text
 ) with (global);

 create table  if not exists rtype (
     id uuid primary key,
     name  text not null,
     description text
 ) with (global);

create table if not exists doc (
    id uuid primary key,
    added_at timestamp not null,
    author_id uuid,
    content text not null,
    img bytea,
    rstatus_id uuid
) with (distributed_by = 'id', num_parts = 4);


create table if not exists resolution (
    id uuid,
    doc_id uuid,
    author_id uuid,
    content text not null,
    rtype_id uuid not null,
    added_at timestamp not null,
    primary key (doc_id,id)
) with (distributed_by = 'doc_id', num_parts = 4, colocate_with = 'doc');

create index doc_auth_id_idx ON doc(author_id);
create index res_type_id_idx ON resolution(author_id);
create index res_auth_id_idx ON resolution(rtype_id);
commit;

