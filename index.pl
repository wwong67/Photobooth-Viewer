#!/usr/bin/perl

#	Creator:	Wai wong (wwong@mmnet.com
#	Date:		Hov 10, 2022
#	Version:	0.1 (This is the first draft)

# Stict syntax checking
use strict;
use warnings;

# Perl modules needed for the Web Browser part
use CGI ':standard';
use CGI qw(:cgi-lib);

# Perl modules needed for parsing emails
use MIME::Parser;
use Imager::QRCode;

# Some default variables, will be reset after reading the configuration file
my $basedir = "/PhotoBooth/Events/EventName";
my $URL = "https://www.example.com/PhotoBooth/Events/EventName";
my $eventname = "Event name";
my $eventinfo = "";
my $eventpasscode = "";
my $photos = "Photos";
my $samples = "Samples";
my $qrcodes = "QRcodes";
my $tempspace = "TempSpace";
my $parser = "parseemail.pl";
my $samplesize = 400;
my $imagelogoleft = "";
my $imagelogoright = "";
my $bannertextwidth="80%";
my $imagelogoleftwidth="10%";
my $imagelogorightwidth="10%";
my $watermarkimage="";
my $configfile = "./photobooth-event.config";

# This is a combine script to run email parsing and web pages
if ( grep ( /$parser/, $0 ) )
   {
	parseEmail (); # Parse the email and exit
	exit ();
   }

# Default is to do the Web Display
my %in; &ReadParse (\%in);
my $self = "none";
my $usediv = 0; # This is for the future using DIV to create blocks

if ( $ENV{SCRIPT_NAME} ) { $self = $ENV{SCRIPT_NAME}; }
WebDisplay ();

# Functions starts here
sub readConfig
{
	my $config = shift @_;
	my $line;
	my $name;
	my $value;
	my $junk;

	for $line ( readFile ( $config ) )
	   {
		chomp ( $line );
		( $name, $value, $junk ) = split ( '=', $line );

		if ( $name and $name eq "basedir" ) { $basedir = "$value" };
		if ( $name and $name eq "photos" ) { $photos = "$value" };
		if ( $name and $name eq "samples" ) { $samples = "$value" };
		if ( $name and $name eq "qrcodes" ) { $qrcodes = "$value" };
		if ( $name and $name eq "eventname" ) { $eventname = "$value" };
		if ( $name and $name eq "eventinfo" ) { $eventinfo = "$value" };
		if ( $name and $name eq "eventpasscode" ) { $eventpasscode = "$value" };
		if ( $name and $name eq "URL" ) { $URL = "$value" };
		if ( $name and $name eq "samplesize" ) { $samplesize = "$value" };
		if ( $name and $name eq "bannertextwidth" ) { $bannertextwidth = "$value" };
		if ( $name and $name eq "imagelogoleft" ) { $imagelogoleft = "$value" };
		if ( $name and $name eq "imagelogoright" ) { $imagelogoright = "$value" };
		if ( $name and $name eq "imagelogoleftwidth" ) { $imagelogoleftwidth = "$value" };
		if ( $name and $name eq "imagelogorightwidth" ) { $imagelogorightwidth = "$value" };
		if ( $name and $name eq "watermarkimage" ) { $watermarkimage = "$value" };
	   }
}

sub readFile
{
	my $filename = shift @_;
	my @temp = ();
	my $fd;

	chomp ( $filename );

	if ( -f "$filename" )
	   {
		open ( $fd, "$filename" );
		if ( $fd )
		   {
			@temp = <$fd>;
			close ($fd);
			chomp ( @temp );
		   }
	   }

	return ( @temp );
}

# Web Functions starts here
sub HTMLreload
{
	# In seconds
	my $refresh = 120;	# Refresh when there is no update

	my $last = (stat('$photos'))[9];
	my $time = time ();

	if ( $time - $last > $refresh )
	   {
		# Refresh in secs if the last update has been more than the default
		$refresh = 10;
	   }

	# Override refresh
	if ( $in{refresh} and $in{refresh} > 60 ) { $refresh = $in{refresh} }
	$refresh = $refresh * 1000;

	print "<script type='text/javascript'>\n";
	print "function load()\n";
	print "{\n";
	print "setTimeout(\"window.open('$self?function=refresh', '_self');\", $refresh);\n";
	print "}\n";
	print "</script>\n";
	print "<body onload='load()'> \n";
}

sub getPhotoDateTime
{
	my $filename	= shift @_;
	my @temp = split ( '_|\.', $filename );

	my $year = $temp[0];
	my $month = $temp[1];
	my $day = $temp[2];

	my $hour;
	my $minute;
	my $second;

	my $usefilename = 0;
	if ( $usefilename )
	   {
		@temp = split ( '', $temp[3] );

		$hour = "$temp[0]$temp[1]";
		$minute = "$temp[2]$temp[3]";
		$second = "$temp[4]$temp[5]";

		if ( $year, $month, $day, $hour, $minute, $second )
		   { return ( $year, $month, $day, $hour, $minute, $second ); }
	   }

	# The filename does not contain the info
	my $filetime = (stat("$photos/$filename"))[9];
	@temp = localtime ( $filetime );

	$year = $temp[5] + 1900;
	$month = $temp[4] + 1;
	$day = $temp[3];
	$hour = $temp[2];
	$minute = $temp[1];
	$second = $temp[0];

	# Pretty up some fields to two digits
	if ( $day < 10 ) { $day = "0$day"; }
	if ( $month < 10 ) { $month = "0$month"; }

	if ( $hour < 10 ) { $hour = "0$hour"; }
	if ( $minute < 10 ) { $minute = "0$minute"; }
	if ( $second < 10 ) { $second = "0$second"; }

	{ return ( $year, $month, $day, $hour, $minute, $second ); }
}

sub showPhotos
{
	my $year;
	my $month;
	my $day;

	my $hour;
	my $minute;
	my $second;

	my $photo;
	my $qrfile;
	my $align = "style='vertical-align:middle'";
	my $div;

	print "<CENTER>\n"; 
	for $photo ( `( cd $basedir/$photos ; ls -t *.jpg *.JPG *.jpeg *.JPEG)` )
	   {
		chomp ( $photo );
		$qrfile = $photo;
		$qrfile =~ s/jpg/gif/;
		$qrfile =~ s/JPG/GIF/;
		$qrfile =~ s/jpeg/gif/;
		$qrfile =~ s/JPEG/GIF/;

		if ( $usediv )
		   {
			$div = $photo;
			$div =~ s/.jpg//;
			$div =~ s/.JPG//;
			$div =~ s/.jpeg//;
			$div =~ s/.JPEG//;
			print "<div id='$div'>\n";
		   };

		# Get Photo info
		( $year, $month, $day, $hour, $minute, $second ) = getPhotoDateTime ( $photo );

		print "<TABLE WIDTH=95% BORDER=0>\n";
		print "<TR>\n";
		print "<TD WIDTH=65%>\n";
		print "\t<IMG SRC='$samples/$photo' WIDTH=100% $align>\n";
		print "</TD>\n";
		print "<TD WIDTH=35% ALIGN=CENTER CLASS=QRBanner>\n";
		print "<FONT CLASS=PhotoTaken>";
		print "Photo taken on $month/$day/$year @ $hour:$minute";
		print "</FONT>\n";
		print "<HR WIDTH=85%>\n";
		print "<IMG SRC='QRcodes/$qrfile' WIDTH='100%' $align>\n";

		print "<FONT CLASS=QRDownload>";
		print "<A HREF='index.pl?function=download&photo=$photo'>Scan QR code or click to download</A></FONT>\n";
		if ( $eventpasscode ) { print "<FONT CLASS=QRDownloadPassCode>(Passcode required)</FONT>\n" };

		print "</TD>\n";
		print "</TR>\n";
		print "</TABLE>\n";

		if ( $usediv ) { print "</div>\n"; };
		print "<BR><HR WIDTH=85%><BR>\n";
	   }
	print "</CENTER>\n"; 
}

sub downloadFile
{
	my $file = shift @_;
	my @data = readFile ( "$basedir/$photos/$file" );
	my $line;

	print "Content-Type: image/jpeg\n";
	print "Content-Disposition: attachment; filename=$file\n\n";

	# Send file down one line at a time
	for $line ( @data )
	   {
		print "$line\n";
	   }
}

sub sendRedirect
{
	print "Location: $URL\n\n";
	print "Content-type: text/html\n\n";
}

sub HTMLStart
{
        print "Content-Type: text/html\n\n";

        if ( $in{search} )
           { print "<TITLE>$eventname</TITLE>\n"; }
           else { print "<TITLE>$eventname</TITLE>\n"; }

        print "<HTML>\n";
        print "<HEAD>\n";
	print "<LINK REL='stylesheet' TYPE='text/css' href='photobooth.css'>\n";
        print "</HEAD>\n";

	if ( $in{function} and $in{function} eq "refresh" )
	   { HTMLreload() }
	   else
	   { print "<BODY>\n"; }
}

sub showBanner
{
	my $align = "style='vertical-align:middle'";

	print "<CENTER>\n";
	print "<DIV ID=banner>\n";
	print "<TABLE WIDTH=95% BORDER=0>\n";
	print "<TR>\n";
	if ( $imagelogoleft ) { print "<TD WIDTH=$imagelogoleftwidth><IMG SRC='$imagelogoleft' WIDTH=100% $align></TD>\n"; }

	print "<TH WIDTH=$bannertextwidth CLASS=Banner>";
	print "<FONT CLASS=Event>$eventname</FONT>";
	if ( $eventinfo )
	   {
		print "<BR>\n";
		print "<FONT CLASS=EventInfo>$eventinfo</FONT>";
	   }

	print "<HR WIDTH=75%>\n";
	print "<FONT CLASS=refresh>";
	if ( $in{function} and $in{function} eq "refresh" )
	   {
		print "<A HREF=$self?function=refresh&refresh=180>Pause refresh for 3 minutes</A>";
		print " <A HREF=$self>(Stop refresh)</A>";
	   } else { print "\t<A HREF=$self?function=refresh>(Start auto refresh)</A>\n"; }
	print "</FONT>";
	print "</TH>\n";

	if ( $imagelogoright ) { print "<TD WIDTH=$imagelogorightwidth><IMG SRC='$imagelogoright' WIDTH=100% $align></TD>\n"; }
	print "</TR>\n";
	print "</TABLE>\n";
	print "</DIV>\n";
	print "</CENTER>\n";
	print "<HR WIDTH=85%>\n";
}

sub HTMLEnd
{
        print "</CENTER>\n";
        print "</BODY\n";
        print "</HTML>\n";
}

sub askForPassCode
{
	# Someday, this should be made nicer
	my $key;

	print "<CENTER>\n";
	print "<FORM METHOD=POST ACTION=$self>";
	print "Event Passcode for download: <INPUT TYPE=INPUT NAME=passcode VALUE=''>\n";

	for $key ( keys (%in) )
	   {
		chomp ( $key );
		if ( $key ne "passcode" )
		   {
			print "<INPUT TYPE=HIDDEN NAME=$key VALUE='$in{$key}'>\n";
		   }
	   }

	print "<INPUT TYPE=SUBMIT VALUE=Submit>\n";
	print "</FORM>";
	print "</CENTER>\n";
}

sub WebDisplay
{
	# Main start function for displaying the web pages
	use Cwd;
	my $dir = getcwd;
	readConfig ( "$configfile" );

	# If this script is not in the basedir, send a redirect
	if ( $dir ne $basedir )
	   {
		sendRedirect;
		exit ();
	   };

	if ( $in{function} and $in{function} eq "download" and $in{photo} )
	   {
		if ( $eventpasscode and $in{passcode} and $in{passcode} eq $eventpasscode )
		   {
			downloadFile ( $in{photo} );
			exit ();
		   }
		if ( $eventpasscode )
		   {
			HTMLStart ();
			askForPassCode ();
			HTMLEnd ();
			exit ();
		   }
		downloadFile ( $in{photo} );
	   }


	# Default, show the pages
	HTMLStart ();
	showBanner ();
	showPhotos ( );
	HTMLEnd ();
}


# Web functions for Email parsing starts here
sub processEmail
{
	my $MESSAGE = shift @_;
	my $part;
	my $content_type;
	my $body;
	my $count;

	my $parser = MIME::Parser->new( );
	#$parser->output_to_core(1);			# don't write attachments to disk
	$parser->output_dir("$basedir/$tempspace");	# Output to new directory

	my $message = $parser->parse_data($MESSAGE);	# die( )s if can't parse

	my $head = $message->head( );			# object--see docs
	my $preamble = $message->preamble;		# ref to array of lines
	my $epilogue = $message->epilogue;		# ref to array of lines

	my $num_parts = $message->parts;
	for ( $count=0; $count < $num_parts; $count++ )
	   {
		$part		= $message->parts($count);
		$content_type	= $part->mime_type;
		$body		= $part->as_string;
	   }
	return ( $count );
}

sub generateQRcode
{
	my $file = shift @_;
	my $qrfile = "$basedir/$qrcodes/$file";
	$qrfile =~ s/jpg/gif/;
	$qrfile =~ s/JPG/gif/;
	$qrfile =~ s/jpeg/gif/;
	$qrfile =~ s/JPEG/gif/;

	my $qrcode = Imager::QRCode->new(
		size		=> 10,
		margin		=> 2,
		version		=> 1,
		level		=> 'M',
		casesensitive	=> 1,
		lightcolor	=> Imager::Color->new(255, 255, 255),
		darkcolor	=> Imager::Color->new(0, 0, 0),
		);
	my $img = $qrcode->plot("$URL/?function=download&photo=$file");
	$img->write(file => "$qrfile"); # or die "Failed to write: " . $img->errstr;
}

sub processFiles
{
	my $file;
	my $convert = "/usr/bin/convert";
	my $composite = "/usr/bin/composite";

	# Process and move file
	for $file ( `( cd $basedir/$tempspace/ ; ls )` )
	  {
		chomp ( $file );

		if ( grep ( /.JPG|JPEG/i, $file ) )
		   {
			generateQRcode ( $file );
			`/bin/mv $basedir/$tempspace/$file $basedir/$photos/`;
			`$convert -quality 99 -resize '$samplesize>x$samplesize>' $basedir/$photos/$file $basedir/$samples/$file`;

			if ( $watermarkimage )
			   {
				`$composite -gravity Center $basedir/$watermarkimage $basedir/$samples/$file $basedir/$samples/$file`;
			   }
		   }
		`/bin/rm -f $basedir/$tempspace/$file`;
	  }
}

sub readSTDIN
{
	my @lines;
	my $line;

	while( <> )
	   {
		push(@lines, $_);
	   }
	return ( join ( '', @lines ) );
}

sub parseEmail
{

	if ( $ARGV[0] ) { $configfile = "$ARGV[0]"; }

	readConfig ( "$configfile" );

	my $data = readSTDIN;
	if ( $data )
	   {
		processEmail ( $data ); 
		processFiles;
	   }
}
