-- V1 FULL
create schema app;

create table app.master
(
    id serial,
    name text,
    constraint master_pk primary key (id)
);
