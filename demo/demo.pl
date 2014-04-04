#!/usr/bin/perl
####################################################################################################################################
# demo.pl - Demonstration for "Database Validation and Versioning" talk
####################################################################################################################################
use strict;
use warnings;
use english;
use Carp;

use IPC::System::Simple qw(capture);
use File::Path qw(remove_tree);
use Term::ReadKey;

####################################################################################################################################
# GLOBAL VARIABLES
####################################################################################################################################
my $iPort = 5500;

use constant
{
    true  => 1,
    false => 0
};

my $strPGDump = "pg_dump --port=$iPort -s -N sqitch";
my $strAPGDiff = "java -jar apgdiff-2.4/apgdiff-2.4.jar --ignore-start-with";

####################################################################################################################################
# EXECUTE
####################################################################################################################################
sub execute
{
    my $strWhat = shift;
    my $strCommand = shift;
    my $bWait = shift;
    
    if (defined($strWhat))
    {
        print "\n$strWhat: $strCommand";
    }

    print "\n";

    system($strCommand) == 0 or die confess "unable to execute: $strCommand";
    
    if (defined($bWait) and $bWait)
    {
        print "\n[press enter]";
        
        ReadMode(2);
        ReadKey(0);
        ReadMode(0);
        
        print "\n";
    }
}

####################################################################################################################################
# CLUSTER MANAGEMENT
####################################################################################################################################
sub cluster_drop
{
    my $strPath = shift;
    
    # If the db directory already exists, stop the cluster and remove the directory
    if (-e $strPath)
    {
        # Attempt to stop the cluster
        eval
        {
            execute("STOP CLUSTER", "pg_ctl stop -D $strPath -w -s -m fast");
        };
    
        if ($@)
        {
            print "OUTPUT: $@";
        }
    
        # Remove the db directory
        remove_tree($strPath) > 0 or confess "ERROR: unable to remove db directory";
    }
}

sub cluster_create
{
    my $strPath = shift;

    execute("CREATE DB DIR", "mkdir $strPath");
    execute("CREATE CLUSTER", "initdb -D $strPath -A trust");
    execute("START CLUSTER", "pg_ctl start -o \"-c port=$iPort\" -D $strPath -l $strPath/postgresql.log -w -s", true);
}

####################################################################################################################################
# PSQL
####################################################################################################################################
sub psql
{
    my $strWhat = shift;
    my $strDatabase = shift;
    my $strSql = shift;
    my $bWait = shift;
    
    my $strCommand = "echo \"$strSql\" | psql --port=$iPort $strDatabase";
    
    execute($strWhat, $strCommand, $bWait);
}

####################################################################################################################################
# MAIN
####################################################################################################################################
print "PGConf NYC 2014 Database Validation and Versioning Demo\n";

# Drop the cluster if it is already running
cluster_drop("db");

# Create the cluster
cluster_create("db");

# Drop the git repo if exists
if (-e "repo")
{
    remove_tree("repo") > 0 or confess "ERROR: unable to remove git directory";
}

# Drop the diff dir if exists
if (-e "diff")
{
    remove_tree("diff") > 0 or confess "ERROR: unable to remove diff directory";
}

# Create the git repo
execute(undef, "mkdir repo");
execute("CREATE GIT REPO", "cd repo && git init .");
execute(undef, "mkdir repo/full");
execute("CREATE FULL PROJECT", "cd repo/full && sqitch --engine pg init app");
execute("CREATE FULL TARGET", "cd repo/full && sqitch target add app db:pg://localhost:5500/app_full");
execute(undef, "mkdir repo/update");
execute("CREATE UPDATE PROJECT", "cd repo/update && sqitch --engine pg init app");
execute("CREATE UPDATE TARGET", "cd repo/update && sqitch target add app db:pg://localhost:5500/app");
execute("STAGE APP PROJECT", "cd repo && git add .");
execute("COMMIT APP PROJECT", "cd repo && git commit -am 'Init db'", true);

# Create v1 full and update builds
psql("CREATE V1 FULL DB", "postgres", "create database app_full");
execute("ADD PUBLIC SCHEMA", "cd repo/full && sqitch add app_table --without=verify --without=revert -n 'Add app schema'");
execute("MV DEPLOY SCRIPT", "cp -f sql/full_v1.sql repo/full/deploy/app_table.sql");
execute(undef, "more repo/full/deploy/app_table.sql");
execute("DEPLOY FULL V1", "cd repo/full && sqitch deploy app", true);

psql("CREATE V1 UPDATE DB", "postgres", "create database app");
execute("ADD PUBLIC SCHEMA", "cd repo/update && sqitch add update_v1 --without=verify -n 'Add v1 update'");
execute(undef, "mkdir diff");
execute("EXPORT UPDATE DB", "$strPGDump app > diff/old.dump");
execute("EXPORT FULL DB", "$strPGDump app_full > diff/new.dump");
execute("CREATE V1 DEPLOY SCRIPT", "$strAPGDiff diff/old.dump diff/new.dump > repo/update/deploy/update_v1.sql");
execute(undef, "more repo/update/deploy/update_v1.sql");
execute("CREATE V1 REVERT SCRIPT", "$strAPGDiff diff/new.dump diff/old.dump > repo/update/revert/update_v1.sql");
execute(undef, "more repo/update/revert/update_v1.sql");
execute("COMMIT V1", "cd repo && git add . && git commit -am 'Completed v1'");
execute("DEPLOY UPDATE V1", "cd repo/update && sqitch deploy app", true);

# Compare v1 full and update builds
execute("EXPORT UPDATE DB", "$strPGDump app > diff/update.dump");
execute("EXPORT FULL DB", "$strPGDump app_full > diff/full.dump");
execute("COMPARE V1 DB", "$strAPGDiff diff/full.dump diff/update.dump");
execute("TAG V1", "cd repo/update && sqitch tag v1 -n 'Tag v1'", true);

# Create v2 full and update builds
execute("MV DEPLOY SCRIPT", "cp -f sql/full_v2.sql repo/full/deploy/app_table.sql");
execute(undef, "more repo/full/deploy/app_table.sql");
psql("CREATE V2 FULL DB", "postgres", "drop database app_full; create database app_full");
execute("DEPLOY V2", "cd repo/full && sqitch deploy app", true);

execute("ADD UPDATE", "cd repo/update && sqitch add update_v2 --without=verify -n 'Add v2 update'");
execute("EXPORT UPDATE DB", "$strPGDump app > diff/old.dump");
execute("EXPORT FULL DB", "$strPGDump app_full > diff/new.dump");
execute("CREATE V2 DEPLOY SCRIPT", "$strAPGDiff diff/old.dump diff/new.dump > repo/update/deploy/update_v2.sql");
execute(undef, "more repo/update/deploy/update_v2.sql");
execute("CREATE V2 REVERT SCRIPT", "$strAPGDiff diff/new.dump diff/old.dump > repo/update/revert/update_v2.sql");
execute(undef, "more repo/update/revert/update_v2.sql");
execute("COMMIT V2", "cd repo && git add . && git commit -am 'Completed v2'");
execute("DEPLOY V2", "cd repo/update && sqitch deploy app", true);

# Compare v2 full and update builds
execute("EXPORT UPDATE DB", "$strPGDump app > diff/update.dump");
execute("EXPORT FULL DB", "$strPGDump app_full > diff/full.dump");
execute("COMPARE V2 DB", "$strAPGDiff diff/full.dump diff/update.dump");
execute("TAG V2", "cd repo/update && sqitch tag v2 -n 'Tag v2'", true);

# Create v3 full build
execute("MV DEPLOY SCRIPT", "cp -f sql/full_v3.sql repo/full/deploy/app_table.sql");
execute(undef, "more repo/full/deploy/app_table.sql");
psql("DROP V2 FULL DB", "postgres", "drop database app_full");
psql("CREATE V3 FULL DB", "postgres", "create database app_full");
execute("DEPLOY V3", "cd repo/full && sqitch deploy app", true);

# Create v3 update build with error
execute("ADD UPDATE", "cd repo/update && sqitch add update_v3 --without=verify -n 'Add v3 update'");
execute("MV DEPLOY SCRIPT", "cp -f sql/deploy_v3_error.sql repo/update/deploy/update_v3.sql");
execute(undef, "more repo/update/deploy/update_v3.sql");
execute("MV DEPLOY SCRIPT", "cp -f sql/revert_v3.sql repo/update/revert/update_v3.sql");
execute(undef, "more repo/update/revert/update_v3.sql");
execute("COMMIT V3", "cd repo && git add . && git commit -am 'Completed v3'");
execute("DEPLOY V3 ERROR", "cd repo/update && sqitch deploy app", true);

# Compare v3 error full and update builds
execute("EXPORT UPDATE DB", "$strPGDump app > diff/update.dump");
execute("EXPORT FULL DB", "$strPGDump app_full > diff/full.dump");
execute("COMPARE V3 ERROR DB", "$strAPGDiff diff/update.dump diff/full.dump", true);

# Now revert to v2
print "\n--------------------\n";
execute("REVERT V3 ERROR", "cd repo/update && sqitch revert -y app update_v2", true);

# Create v3 update build correctly
print "\n--------------------\n";
execute("EXPORT UPDATE DB", "$strPGDump app > diff/old.dump");
execute("EXPORT FULL DB", "$strPGDump app_full > diff/new.dump");
execute("CREATE V3 DEPLOY SCRIPT", "$strAPGDiff diff/old.dump diff/new.dump > repo/update/deploy/update_v3.sql");
execute(undef, "more repo/update/deploy/update_v3.sql");
execute("COMMIT V3", "cd repo && git add . && git commit -am 'Fixed v3'");
execute("DEPLOY V3", "cd repo/update && sqitch deploy app", true);

# Compare v3 corrected full and update builds
execute("EXPORT UPDATE DB", "$strPGDump app > diff/update.dump");
execute("EXPORT FULL DB", "$strPGDump app_full > diff/full.dump");
execute("COMPARE V3 CORRECTED DB", "$strAPGDiff diff/full.dump diff/update.dump", true);

# Demo complete!
cluster_drop("db");
print "\nDemo Complete!\n";
