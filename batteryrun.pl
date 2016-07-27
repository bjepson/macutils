#!/usr/bin/perl -w

use strict;
use DateTime;
use Time::Duration;

my %events;
open (PMSET, "pmset -g log |") or die "Couldn't launch pmset: $!";
while(<PMSET>) {
    next unless /Using/i;
    %events = () if /Using AC/i;
    my $datetime;
    if (/(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)/) {
        $datetime = DateTime->new(year=>$1,month=>$2,day=>$3,hour=>$4,minute=>$5,second=>$6, time_zone => 'local'); 
    }

    die "Couldn't parse date in $_" unless $datetime;
    if (/Using Batt/i) {
        my $action;
        $action = "Sleep" if /Entering Sleep/i;
        $action = "Wake" if /Wake from/i;
        $action = "Going On Battery" if scalar keys %events == 0;
        if ($action) {
            $events{$datetime->epoch()} = $action;
        }
    }
}

my $now = DateTime->now(time_zone => 'local');
$events{$now->epoch()} = "Now";
my ($last, $total);
foreach (sort keys %events) {
    my $delta = 0;
    my $time = $_;
    my $action = $events{$_};

    if ($last) {
        $delta = $time - $last;
    }

    print $time, "\t", $delta, "\t", $action, "\n";
    $last = $time;
    if ($action eq 'Sleep' || $action eq 'Now') {
        $total += $delta;
    }
}


print "Total battery time since last unplugged: ", duration($total), ".\n";
