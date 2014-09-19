Title: Heavy Duty Backup with PgBackRest

Abstract:

PgBackRest is a backup system developed at Resonate and open sourced to address issues around the backup of multi-terabyte databases. It supports per file checksums, compression, partial/failed backup resume, high-performance parallel transfer, async archiving, tablespaces, expiration, full/differential/incremental, local/remote operation via SSH, hard-linking, and more. PgBackRest is written in Perl and uses common (and configurable) command line tools, but does not depend on rsync or tar and instead performs its own deltas which gives it maximum flexibility. It works with any file system that provides snapshots to allow easy access to data by starting a cluster directly on the backup. This talk will introduce the features, give sample configurations, and talk about design philosophy.

Bio:

David Steele is the Data Architect at Resonate, an online media company using PostgreSQL to drive its transactional and data warehousing databases.  He has been actively developing with PostgresSQL since 1999.
