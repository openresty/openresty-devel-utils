#!/usr/bin/env perl

use strict;
use warnings;

my $expr = shift;

my $res = eval $expr;
if ($@) {
    die "$@\n";
}

print "$res\n";
printf "%#x\n", $res;
