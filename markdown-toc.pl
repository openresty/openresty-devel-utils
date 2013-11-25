#!/usr/bin/env perl

use strict;
use warnings;
use File::Copy qw(move);

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

    if ($s =~ /\G^(\S[^\n]*)\n([-=])+\n/gsmc) {
        my ($title, $bar) = ($1, $2);

        warn "$title\n";

        my $anchor = gen_anchor($title);
        my $indent;
        if ($bar eq '=') {
            $indent = "";

        } else {
            $indent = "    ";
        }

        if ($title ne 'Table of Contents') {
            $toc .= "$indent* [$title](#$anchor)\n";
        }

        $section = [$title, $&];
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
    or die "Cannot open $infile for writing: $!\n";

my $i = 0;
print $out $preamble;
for my $sec (@sections) {
    my ($title, $src) = @$sec;
    if ($title eq 'Table of Contents') {
        # skip this section
        next;
    }

    print $out $src;
    if (++$i > 3 && $src !~ /Back to TOC/sm) {
        print $out "[Back to TOC](#table-of-contents)\n\n";
    }

    if ($title =~ /^Name$/i) {
        print $out "Table of Contents\n=================\n\n$toc\n";
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
