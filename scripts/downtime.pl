#!/usr/bin/perl
use strict;
use warnings;

my $oldIPFilePath = "/var/tmp/downtimeOldIP";

my $hostname = `hostname`;
chomp($hostname);
my $whoami = `whoami`;
chomp($whoami);

my $oldIP = ();
my $oldIPLastChangedDate = ();
my $bool_oldIPFileFound = 0;

my $currentIPLastChangedDate = `date`;
chomp($currentIPLastChangedDate);

open(logFile, ">>/var/tmp/downtimeLogFile");

if (-e $oldIPFilePath) {
  $bool_oldIPFileFound = 1;

  open(oldIPFile, "<$oldIPFilePath");
  
  $oldIP = <oldIPFile>;
  chomp($oldIP);

  $oldIPLastChangedDate = <oldIPFile>;
  chomp($oldIPLastChangedDate);
  
  # DEBUG SHIT
#  print("DEBUG OLD: $oldIP\nDEBUG OLD: $oldIPLastChangedDate\n");
  # DEBUG SHIT

  print(logFile "$currentIPLastChangedDate: Old IP: $oldIP; Last Changed: $oldIPLastChangedDate\n");
  close(oldIPFile);
} else {
  print(logFile "$currentIPLastChangedDate: No old IP file found!\n");
  $oldIP = "";
}

my $currentIP = `curl ifconfig.me`;
chomp($currentIP);

# DEBUG SHIT
print("DEBUG NEW: $currentIP\nDEBUG NEW: $currentIPLastChangedDate\n");
# DEBUG SHIT

print("$hostname: $oldIP->$currentIP");

if ($currentIP =~ m/\d+\.\d+\.\d+\.\d+/ && !($currentIP eq $oldIP)) {
  
  
  print(logFile `date`.": IP Aresses CHANGED!! Emailing...\n");
#  print("DEBUG: IP ADDRESS CHANGED\n");

  my $changeOccurredString = $bool_oldIPFileFound eq 1 ?
    "This change occurred somewhere between $oldIPLastChangedDate and $currentIPLastChangedDate." : 
      "This change occurred at $currentIPLastChangedDate.";

  my $mailCommand = <<EOF;
echo "The IP Address for $hostname has CHANGED from $oldIP to $currentIP
$changeOccurredString
Please update your DNS records, etc accordingly." | mail -s "IP ADDRESS CHANGED FOR $hostname" $whoami

EOF

  system($mailCommand);
} else {
#  print("DEBUG: No Change\n");
  # Do Nothing
}

open(currentIPFileUpdate, ">$oldIPFilePath");
print(currentIPFileUpdate "$currentIP\n$currentIPLastChangedDate");
close(currentIPFileUpdate);


close(logFile);
