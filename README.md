Title: Heavy Duty Backup with PgBackRest

Abstract:

PgBackRest is open source software developed to perform efficient backup on PostgreSQL databases that measure in tens of terabytes and greater. It supports per file checksums, compression, partial/failed backup resume, high-performance parallel transfer, asynchronous archiving, tablespaces, expiration, full/differential/incremental, local/remote operation via SSH, hard-linking, restore, and more. PgBackRest is written in Perl and does not depend on rsync or tar but instead performs its own deltas which gives it maximum flexibility.  This talk by the author will introduce the features, give sample configurations, and talk about design philosophy.

Bio:

David Steele is Senior Data Architect at Crunchy Data Solutions, the PostgreSQL company for secure enterprises.  He has been actively developing with PostgreSQL since 1999.
