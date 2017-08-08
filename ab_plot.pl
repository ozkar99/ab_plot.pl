#!/usr/bin/env perl
use warnings;
use strict;

my $OUTPUT="/var/www/html/webroot/img/graph.png";
my $CONCURRENT='5';
my $REQUESTS='50';
my $DOMAIN="http://127.0.0.1/";
my @URL_LIST = ("", "page/howitworks/", "auctions/future/", "auctions/closed/", "auctions/Ensayo-no-pujar-1681/", "users/login/");

############### DEM STUFF ##########################

my $GNUPLOT="/usr/bin/gnuplot";
my $FONT="/usr/share/fonts/liberation/LiberationSans-Regular.ttf";
my $AB="/usr/bin/ab";
my $FILE = "";
my @FILES;
my $MAX_VALUE;
my %VALUES;

################ BENCHMARK THIS SHIZZLEE ###############
foreach my $URL (@URL_LIST) {

        if ( $URL eq "") {
                $FILE="index";
        } else {
                $FILE = $URL;
                $FILE =~ s/\//_/g;
                $FILE =~ s/_$//;
        }

        $FILE = "/tmp/$FILE.csv"; #Put these files in the /tmp/ folder.
        system("$AB -n $REQUESTS -c $CONCURRENT -e $FILE '$DOMAIN$_'\n");
        push(@FILES, $FILE);

}

########### GET MAX VALUES #####################

foreach my $FILE_NAME (@FILES) {

        my $PROM;
        open FILE, "<", "$FILE_NAME" or die $!;

        while( <FILE> ) {
                $_ =~ m/^98,(.*)$/;
                $MAX_VALUE = $1;
        }

        close FILE;

        $VALUES{$FILE_NAME} = $MAX_VALUE;

}

############# CREATE PLOT FILE ####################

open FILE, ">", "/tmp/plot.plt";
my $I=0;
my $J=0;
my $TICKS = "";
my $PLOTS = "";

foreach my $FILE (@FILES) {

        $FILE =~ s/\/tmp\///;
        $FILE =~ s/.csv//;
        $FILE =~ s/_/\//g;
        $TICKS = "$TICKS '$FILE' $J,";
        $PLOTS = "$PLOTS '-' notitle with boxes fill, \\\n";
        $J++;

}

$TICKS =~ s/,\Q)/\Q)/;
$PLOTS =~ s/,\ \\$//; #Remove last comma and \ from plots.
my $H=$J+1;

print FILE "set term png enhanced font '/usr/share/fonts/liberation/LiberationSans-Regular.ttf' size 800,600
set output '$OUTPUT'
set title 'Benchmark: $DOMAIN, Concurrent: $CONCURRENT, Requests: $REQUESTS'
unset xtics
set ytics
set boxwidth 1
set style fill solid border -1
set xtics ($TICKS)
set xrange [ -0.$H:$J.$H ]
set xtics border in scale 1,0.5 nomirror rotate by -45  offset character 0, 0, 0
plot $PLOTS\n";

while ( my ($URL, $VALUE) = each(%VALUES) ) {

        print FILE "$I\t$VALUE\ne\n"; #get a csv value of the url and its value.
        $I++;
}

close FILE;
############ PLOT THIS SHIZZLEEE ################


system("$GNUPLOT /tmp/plot.plt");
