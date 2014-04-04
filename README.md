Title: Database Validation and Versioning

Abstract:

There are many advantages to maintaining full build scripts for your database.  They allow you to create your database from scratch, run unit tests, and serve as a useful reference to the current state of the database.  However, in production full build scripts are only run once per database.  After that it is an endless sequence of update scripts.  How do you to keep the full build and update scripts in sync?  How can you be sure that your production database looks exactly like your full build once all the updates have been applied?  In this talk we’ll examine how validation and versioning can be used to ensure that production databases always match full builds even after thousands of updates have been applied.  There will be practical demonstrations using tools such as check_postgres and sqitch.  

Bio:

David Steele is the Data Architect at Resonate, an online media company using PostgreSQL to drive its transactional and data warehousing databases.  He has been actively developing with PostgresSQL since 1999.
