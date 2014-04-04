-- V2 FULL
create schema app;

create table app.master
(
    id serial not null,
    name text not null,
    constraint master_pk primary key (id)
);
