#!/usr/bin/perl
####################################################################################################################################
# demo.pl - Demonstration for "Database Validation and Versioning" talk
####################################################################################################################################
use strict;
use warnings FATAL => qw(all);
use Carp qw(confess);

use File::Path qw(remove_tree);
use Term::ReadKey qw(ReadMode ReadKey);
use File::Basename qw(dirname);
use Cwd qw(cwd);
use Getopt::Long qw(GetOptions);

####################################################################################################################################
# INSTALLATION-SPECIFIC VARIABLES
#
# Modify these variables to match your installation in order to run the demo.
####################################################################################################################################
# Fully-qualified path to pg_backrest exe
my $strBackRestBin = "pg_backrest";

# Configure Postgres
my $strDbVersion = '9.4';
my $strDbPath = "/usr/lib/postgresql/${strDbVersion}/bin";

####################################################################################################################################
# GLOBAL VARIABLES
####################################################################################################################################
use constant
{
    true  => 1,
    false => 0
};

my $strStanza = 'main';
my $strConfFileName = '/etc/pg_backrest.conf';
my $strCommonParam = "--stanza=${strStanza}";

####################################################################################################################################
# Options
####################################################################################################################################
my $bNoWait = false;

GetOptions ('no-wait' => \$bNoWait)
    or exit 1;

####################################################################################################################################
# screenClear
####################################################################################################################################
sub screenClear
{
    if (!$bNoWait)
    {
        syswrite(*STDOUT, "\033[2J");   #clear the screen
        syswrite(*STDOUT, "\033[0;0H"); #jump to 0,0
    }
}

####################################################################################################################################
# EXECUTE
####################################################################################################################################
sub execute
{
    my $strWhat = shift;
    my $strCommand = shift;
    my $bWait = shift;
    my $bExpectError = shift;

    if (defined($strWhat))
    {
        syswrite(*STDOUT, "\n$strWhat: $strCommand");
    }

    syswrite(*STDOUT, "\n");

    die confess "unable to execute: $strCommand"
        if system($strCommand) != 0 && (!defined($bExpectError) || !$bExpectError);

    if (defined($bWait) && $bWait)
    {
        if ($bNoWait)
        {
            syswrite(*STDOUT, "\n");
            # syswrite(*STDOUT, "\n--------------------------------------------------------------------------------\n\n");
        }
        else
        {
            my $cChar;

            ReadMode(3);

            # Clear any previous characters
            do
            {
                $cChar = ReadKey(-1);
            }
            while (defined($cChar));

            syswrite(*STDOUT, "\n[press enter]");

            # Read the next char
            do
            {
                $cChar = ReadKey(1000);
            }
            while (!defined($cChar));

            ReadMode(0);

            syswrite(*STDOUT, "\n");
            screenClear();
        }
    }
}

####################################################################################################################################
# CLUSTER MANAGEMENT
####################################################################################################################################
sub cluster_stop
{
    my $strPath = shift;

    # If the db directory already exists, stop the cluster and remove the directory
    if (-e $strPath)
    {
        # Attempt to stop the cluster
        execute("STOP CLUSTER", "${strDbPath}/pg_ctl stop -D $strPath -w -s -m fast > /dev/null");
    }
}

sub cluster_drop
{
    my $strPath = shift;

    # If the db directory already exists, stop the cluster and remove the directory
    if (-e $strPath)
    {
        # Attempt to stop the cluster
        eval
        {
            cluster_stop($strPath);
        };

        if ($@)
        {
            syswrite(*STDOUT, "OUTPUT: $@");
        }

        # Remove the db directory
        remove_tree($strPath) > 0 or confess "ERROR: unable to remove db directory";
    }
}

sub cluster_start
{
    my $strPath = shift;
    my $bWait = shift;

    execute("START CLUSTER", "${strDbPath}/pg_ctl start -o \"-c archive_mode=on -c wal_level=archive" .
                             " -c archive_command='$strBackRestBin $strCommonParam archive-push %p'" .
                            #  " -c unix_socket_directories=/tmp" .
                             "\" -D $strPath -l $strPath/postgresql.log -w -s", defined($bWait) && $bWait);
}

sub cluster_create
{
    my $strPath = shift;
    my $bWait = shift;

    execute("CREATE DB DIR", "mkdir $strPath");
    execute("CREATE CLUSTER", "${strDbPath}/initdb -D $strPath -A trust > /dev/null");
    cluster_start($strPath, $bWait);
}

####################################################################################################################################
# PSQL
####################################################################################################################################
sub psql
{
    my $strWhat = shift;
    my $strSql = shift;
    my $bWait = shift;

    my $strCommand = "echo \"$strSql\" | psql postgres";

    execute($strWhat, $strCommand, $bWait);
}

####################################################################################################################################
# BACKUP
####################################################################################################################################
sub backup
{
    my $strType = shift;
    my $bWait = shift;

    my $strWhat = 'BACKUP TYPE=' . uc($strType);
    my $strCommand = "$strBackRestBin $strCommonParam --type=${strType} backup";

    execute($strWhat, $strCommand, defined($bWait) && $bWait);
}

####################################################################################################################################
# INFO
####################################################################################################################################
sub info
{
    my $strOutput = shift;
    my $bWait = shift;

    $strOutput = defined($strOutput) ? $strOutput : 'text';

    my $strWhat = 'INFO OUTPUT=' . uc($strOutput);
    my $strCommand = "$strBackRestBin $strCommonParam" . ($strOutput eq 'text' ? '' : " --output=${strOutput}") . " info";

    execute($strWhat, $strCommand, defined($bWait) && $bWait);
}

####################################################################################################################################
# RESTORE
####################################################################################################################################
sub restore
{
    my $strType = shift;
    my $strTarget = shift;
    my $iTimeline = shift;
    my $bWait = shift;
    my $bExpectError = shift;

    my $strWhat = 'RESTORE TYPE=' .
        (defined($strType) ? uc($strType) : "DEFAULT") .
        (defined($strTarget) ? " TARGET=${strTarget}" : '') .
        (defined($iTimeline) ? " TIMELINE=${iTimeline}" : '');

    my $strCommand = "$strBackRestBin $strCommonParam" .
        (defined($strType) ? " --type=${strType}" : '') .
        (defined($strTarget) ? " --target=${strTarget}" : '') .
        (defined($iTimeline) ? " --target-timeline=${iTimeline}" : '') .
        " --delta restore";

    execute($strWhat, $strCommand, defined($bWait) && $bWait, $bExpectError);
}

####################################################################################################################################
# WRITE_CONF
####################################################################################################################################
sub write_conf
{
    my $hFile;

    open($hFile, '>', $strConfFileName)
        or confess "unable to open ${strConfFileName}";

    syswrite($hFile, "[global:general]\nrepo-path=" . cwd() . "/repo");
    syswrite($hFile, "\n\n[${strStanza}]\ndb-path=" . cwd() . "/db");
    syswrite($hFile, "\n");

    close($hFile);
}

####################################################################################################################################
# headingWrite
####################################################################################################################################
sub headingWrite
{
    my $strHeading = shift;

    if ($bNoWait)
    {
        syswrite(*STDOUT, ('-' x (length($strHeading) + 1)) . "\n");
    }

    syswrite(*STDOUT, "${strHeading}:\n");
    syswrite(*STDOUT, ('-' x (length($strHeading) + 1)) . "\n");
}

####################################################################################################################################
# MAIN
####################################################################################################################################
screenClear();
syswrite(*STDOUT, "pgBackRest Demo\n===============\n\n");

headingWrite('Setup the cluster and repo');

# Drop the cluster if it is already running
cluster_drop('db');

# Write pg_backrest.conf
write_conf();

# Create the cluster
cluster_create('db');

# Drop the repo if exists
if (-e 'repo')
{
    remove_tree('repo') > 0 or confess 'ERROR: unable to remove repo';
}

# Create test table
psql('CREATE TABLE', 'create table test (message text)');

# Show conf
execute('SHOW CONF', "cat ${strConfFileName}");

# Create the repo
execute('CREATE REPO', 'mkdir repo', true);

# Perform a full backup
headingWrite('Perform a full backup');
    backup('full');
    execute('DB SIZE', 'du -sh db');
    execute('SHOW BACKUP', "ls -lah repo/backup/${strStanza}");
    execute('BACKUP SIZE', "du -sh repo/backup/${strStanza}", true);

headingWrite('Show archive after the full backup');
    # execute('BACKUP INFO', "more repo/backup/${strStanza}/backup.info", true);
    execute('SHOW ARCHIVE', "ls -lah repo/archive/${strStanza}/${strDbVersion}-1/0000000100000000");
    execute('ARCHIVE SIZE', "du -sh repo/archive/${strStanza}/${strDbVersion}-1", true);
    # execute('ARCHIVE INFO', "more repo/archive/${strStanza}/archive.info", true);

headingWrite('Perform a differential backup');
    backup('diff');
    execute('DB SIZE', 'du -sh db');
    execute('SHOW BACKUP', "ls -lah repo/backup/${strStanza}");
    execute('BACKUP SIZE', "du -sh repo/backup/${strStanza}", true);

headingWrite('Show archive after the differential backup');
    execute('SHOW ARCHIVE', "ls -lah repo/archive/${strStanza}/${strDbVersion}-1/0000000100000000");
    execute('ARCHIVE SIZE', "du -sh repo/archive/${strStanza}/${strDbVersion}-1", true);

headingWrite('Release time - take a backup');
    backup('incr');
    execute('SHOW BACKUP', "ls -lah repo/backup/${strStanza}", true);

headingWrite('Release time - set a restore point');
    psql('INSERT BEFORE MESSAGE', "insert into test values ('before release')");
    psql('CREATE RESTORE POINT', "select pg_create_restore_point('release')", true);

headingWrite('Perform the release');
    psql('INSERT AFTER MESSAGE', "update test set message = 'after release'", true);

headingWrite('QA says the release is no good - please rollback');
    restore('name', 'release', undef, true, true);

headingWrite('Forgot to stop the database - try again');
    cluster_stop('db');
    restore('name', 'release', undef);
    execute('SHOW RECOVERY.CONF', 'more db/recovery.conf', true);

headingWrite('Start the database and verify the recovery');
    cluster_start('db');
    psql('GET MESSAGE', 'select message from test');
    execute('SHOW NEW TIMELINE', "ls -lah repo/archive/${strStanza}/${strDbVersion}-1", true);
    # execute('SHOW NEW TIMELINE INFO', "more repo/archive/${strStanza}/${strDbVersion}-1/00000002.history");

headingWrite('App is started and important data is written to the database');
    psql('INSERT AFTER MESSAGE', "update test set message = 'very important update'", true);

headingWrite('QA made a mistake, the release is good!  Please undo the rollback');
    cluster_stop('db');
    restore(undef, undef, undef);
    execute('SHOW RECOVERY.CONF', 'more db/recovery.conf');
    cluster_start('db');
    psql('GET MESSAGE', 'select message from test', true);

headingWrite("Uh oh - what about the 'very important update' that happened?");
    cluster_stop('db');
    restore(undef, undef, 2);
    execute('SHOW RECOVERY.CONF', 'more db/recovery.conf');
    cluster_start('db');
    psql('GET MESSAGE', 'select message from test', true);

headingWrite('Show basic info');
    info(undef, true);

headingWrite('Show exhaustive JSON info');
    info('json');

syswrite(*STDOUT, "\n\nDemo Complete!\n");
