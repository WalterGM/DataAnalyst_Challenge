CREATE DATABASE challenge;

\c challenge;

-- Table: public.ce.data.0.AllCESSeries

-- DROP TABLE IF EXISTS public."ce.data.0.AllCESSeries";

CREATE TABLE IF NOT EXISTS public."ce.data.0.AllCESSeries"
(
    series_id text COLLATE pg_catalog."default",
    year bigint,
    period text COLLATE pg_catalog."default",
    value double precision,
    footnote_codes text COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ce.data.0.AllCESSeries"
    OWNER to postgres;
-- Index: series_id

-- DROP INDEX IF EXISTS public.series_id;

CREATE INDEX IF NOT EXISTS series_id
    ON public."ce.data.0.AllCESSeries" USING btree
    (series_id COLLATE pg_catalog."default" varchar_ops ASC NULLS LAST)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;

-- Table: public.ce.datatype

-- DROP TABLE IF EXISTS public."ce.datatype";

CREATE TABLE IF NOT EXISTS public."ce.datatype"
(
    data_type_code bigint,
    data_type_text text COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ce.datatype"
    OWNER to postgres;

-- Table: public.ce.period

-- DROP TABLE IF EXISTS public."ce.period";

CREATE TABLE IF NOT EXISTS public."ce.period"
(
    period text COLLATE pg_catalog."default",
    mm text COLLATE pg_catalog."default",
    month text COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ce.period"
    OWNER to postgres;

-- Table: public.ce.series

-- DROP TABLE IF EXISTS public."ce.series";

CREATE TABLE IF NOT EXISTS public."ce.series"
(
    series_id text COLLATE pg_catalog."default",
    supersector_code bigint,
    industry_code bigint,
    data_type_code bigint,
    seasonal text COLLATE pg_catalog."default",
    series_title text COLLATE pg_catalog."default",
    footnote_codes text COLLATE pg_catalog."default",
    begin_year bigint,
    begin_period text COLLATE pg_catalog."default",
    end_year bigint,
    end_period text COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ce.series"
    OWNER to postgres;
-- Index: series.series_id

-- DROP INDEX IF EXISTS public."series.series_id";

CREATE INDEX IF NOT EXISTS "series.series_id"
    ON public."ce.series" USING btree
    (series_id COLLATE pg_catalog."default" varchar_ops ASC NULLS LAST)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;

-- Table: public.ce.supersector

-- DROP TABLE IF EXISTS public."ce.supersector";

CREATE TABLE IF NOT EXISTS public."ce.supersector"
(
    supersector_code bigint,
    supersector_name text COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ce.supersector"
    OWNER to postgres;


CREATE OR REPLACE VIEW "women-in-government" as (WITH series_supersector as (select series_id, series_title, se.supersector_code, sp.supersector_name
from public."ce.series" se inner join public."ce.supersector" sp on se.supersector_code = sp.supersector_code
where lower(se.series_title) like '%women%'and trim(se.series_id) like 'CES9%'),

women_government as(
Select
	trim(pe.month) || ' ' || year date,
	value
From public."ce.data.0.AllCESSeries" alls INNER JOIN series_supersector sp on alls.series_id= sp.series_id
inner join public."ce.period" pe on trim(pe.period) = trim(alls.period))

select date, round(sum(value)) valueInThousands
from women_government
group by date);

CREATE OR REPLACE VIEW "employee-ratio" as( WITH series_supersector as (select series_id, series_title, se.supersector_code, sp.supersector_name,dt.data_type_code
from public."ce.series" se inner join public."ce.supersector" sp on se.supersector_code = sp.supersector_code
inner join 	public."ce.datatype" dt on dt.data_type_code = se.data_type_code
where dt.data_type_code in (01,06)),

all_employees as (
Select
	trim(month) || ' ' || year date,
	value as value_all
From public."ce.data.0.AllCESSeries" alls INNER JOIN series_supersector sp on alls.series_id= sp.series_id
inner join public."ce.period" pe on trim(pe.period) = trim(alls.period)
where sp.data_type_code =01),

production_employees as (
Select
	trim(month) || ' ' || year date,
	value as value_prod
From public."ce.data.0.AllCESSeries" alls INNER JOIN series_supersector sp on alls.series_id= sp.series_id
inner join public."ce.period" pe on trim(pe.period) = trim(alls.period)
where sp.data_type_code =06)



Select date,round(sum(value_prod/value_all)) ratio
From all_employees inner join production_employees using(date)
group by date);