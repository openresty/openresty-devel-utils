#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy qw( move );
use File::Temp qw( tempfile );
use Getopt::Std qw( getopts );

sub usage ($);

my %opts;
getopts("ih", \%opts)
    or usage 1;

my $help = $opts{h};

if ($help) {
    usage 0;
}

my $inplace = $opts{i};

if ($inplace) {
    die "TODO";
}

my $operation = shift or die "No operation specified";

if (!@ARGV) {
    warn "ERROR: no input file specified.\n\n";
    usage 1;
}

my $total_hits = 0;

for my $file (@ARGV) {
    my ($out, $tmpfile);
    if ($inplace) {
        ($out, $tmpfile) =
            tempfile("sed-pl-XXXXXXX.txt", UNLINK => 1, TMPDIR => 1);
    }

    my $hits = 0;

    open my $in, $file
        or die "Cannot open $file for reading: $!\n";
    while (<$in>) {
        chomp;
        if (eval $operation) {
            $hits++;
            print "$file:$.: $_\n";
        }
        if ($inplace) {
            print $out "$_\n";
        }
    }
    close $in;

    $total_hits += $hits;

    if ($inplace) {
        close $out;
        if ($hits) {
            move $tmpfile, $file
                or die "Cannot move $tmpfile to $file: $!\n";
        }
    }
}

warn "\nFound $total_hits hits.\n";

sub usage ($) {
    my $rc = shift;
    my $msg = <<_EOC_;
Usage:
    sed.pl [OPTION...] OPERATION INFILE...

Optons:
    -h          Print this help.
    -i          Do in-place substitution

Example:

    sed.pl 's/(foo.*?)bar/${1}baz/gsm' `find lib -name '*.pm'`

Copyright (C) by Yichun Zhang. All rights reserved.
_EOC_
}
