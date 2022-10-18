#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;

use Getopt::Std qw/ getopts /;
use File::Copy qw(move);

sub usage ($);

my %opts;
getopts 'hf', \%opts
    or usage 1;

if ($opts{h}) {
    usage 0;
}

my $as_first_sec = $opts{f};

my $infile = shift or
    die "usage: $0 <infile>\n";

my $name;
if ($infile =~ m{([^/]+)\.wiki$}) {
    $name = $1;
    if ($name !~ /^[A-Z]/) {
        undef $name;

    } else {
        warn "Using name $name...\n";
    }
}

open my $in, $infile or
    die "cannot open $infile for reading: $!\n";

my $s = do { local $/; <$in> };

close $in;

my $preamble = '';
my @sections;
my $section;
my $verbatim;
my $toc = '';
while (1) {
    if ($s =~ /\G^\`\`\`.*/gmc) {
        $verbatim = !$verbatim;
        if (!$section) {
            $preamble .= $&;
            #die "Bad line: $&";
            next;
        }

        $section->[1] .= $&;
        next;
    }

    if ($verbatim && $s =~ /\G.*\n/gmc) {
        if (!$section) {
            $preamble .= $&;
            #die "Bad line: $&";
            next;
        }

        $section->[1] .= $&;
        next;
    }

    if ($s =~ /\G^(\S[^\n]*)\n([-=]){2,}\n/gsmc) {
        my ($title, $bar) = ($1, $2);

        warn "$title\n";

        my $anchor = gen_anchor($title);
        my $indent;
        if ($bar eq '=') {
            $indent = "";

        } else {
            $indent = "    ";
        }

        $bar = $bar x length($title);

        if ($title ne 'Table of Contents') {
            $toc .= "$indent* [$title](#$anchor)\n";
        }

        $section = [$title, "$title\n$bar\n"];
        push @sections, $section;

    } elsif ($s =~ /\G^(\#{1,})\s*(\S[^\n]*)\n/gsmc) {
        my ($bar, $title) = ($1, $2);

        warn "$title\n";

        my $anchor = gen_anchor($title);
        my $indent = "    " x (length($bar) - 1);

        if ($title ne 'Table of Contents') {
            $toc .= "$indent* [$title](#$anchor)\n";
        }

        $section = [$title, $&];
        push @sections, $section;

    } elsif ($s =~ /\G[^\n]*\n/gsmc) {
        if (!$section) {
            $preamble .= $&;
            #die "Bad line: $&";
            next;
        }

        $section->[1] .= $&;
        #warn $&;

    } else {
        last;
    }
}

my $outfile = "$infile.new";
open my $out, ">$outfile"
    or die "Cannot open $outfile for writing: $!\n";

my $i = 0;
print $out $preamble;
my $wrote_toc;
for my $sec (@sections) {
    my ($title, $src) = @$sec;
    if ($title =~ /^(?:\# )?Table of Contents$/) {
        # skip this section
        next;
    }

    if ($as_first_sec) {
        if (!$wrote_toc) {
            print $out "# Table of Contents\n\n$toc\n";
            $wrote_toc = 1;
        }

        print $out $src;
        next;
    }

    print $out $src;
    if (++$i > 3 && $src !~ /Back to TOC/sm) {
        if ($src =~ /\w\n.*?\n.*?\w/s) {
            if ($src !~ /\n\n$/s) {
                print $out "\n";
            }
            print $out "[Back to TOC](#table-of-contents)\n\n";
        }
    }

    if (!$wrote_toc) {
        print $out "# Table of Contents\n\n$toc\n";
        $wrote_toc = 1;
    }
}

close $out;

move($outfile, $infile);

sub gen_anchor {
    my $link = shift;
    $link =~ s/[^-\w_ ]//g;
    $link =~ s/ /-/g;
    lc($link);
}

sub gen_toc ($) {
    my $s = shift;
    return $toc;
}

sub usage ($) {
    my $rc = shift;
    my $msg = <<_EOC_;
Usage: $0 [-h] [-f] MD_FILE

Options:
    -f      Insert TOC before the first section title
            (by default, inserting before the 2nd)
    -h      Print this help.
_EOC_

    if ($rc == 0) {
        print $msg;
        exit 0;
    }

    warn $msg;
    exit $rc;
}
