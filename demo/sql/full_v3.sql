-- V3 FULL
create schema app;

create table app.master
(
    id serial not null,
    name text not null,
    constraint master_pk primary key (id)
);

create table app.detail
(
    id serial not null,
    master_id int not null
        constraint detail_masterid_fk references app.master (id),
    name text not null,
    constraint detail_pk primary key (id)
);
