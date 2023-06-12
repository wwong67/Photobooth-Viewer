#!/usr/bin/perl -w

#	Creator:	Wai wong (wwong@mmnet.com
#	Date:		Hov 10, 2022
#	Version:	0.1 (This is the first draft)

# Stict syntax checking
use strict;
use warnings;

# Perl modules needed for the Web Browser part
use CGI ':standard';
use CGI qw(:cgi-lib);
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
use Time::Local;

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
my $videos = "Videos";
my $samples = "Samples";
my $qrcodes = "QRcodes";
my $qrlevel = "M";
my $qrsize = "10";
my $tempspace = "TempSpace";
my $parser = "parseemail.pl";
my $processor = "processTempSpace.pl";
my $samplesize = 600;
my $videowidth = 720;
my $videoheight = 480;
my $videoreduction = 6;
my $imagelogoleft = "";
my $imagelogoright = "";
my $bannertextwidth="80%";
my $imagelogoleftwidth="10%";
my $imagelogorightwidth="10%";
my $watermarkimage="";
my $configfile = "./photobooth-event.config";
my $uploadenable = 'false';
my $uploadkey = 'media';
my $uploadfilename = 'SomeFile';
my $uploadusername = 'SomeUser';
my $uploadpassword = 'SomePassword';
my $uploadresponse = 'JSON';
my $uploadmaxsize = 2048;
my $displayorder = "Photos Videos";
my $videodownloads = 0;
my $photodownloads = 1;
my $additionallinks = '';
my $background = '';
my $videocontrols = 'controls muted';
my $fillwidth = "98%";
my $imagewidth = "70%";
my $qrwidth = "30%";
my $deleteoption = '';
my $deletecode = '';
my $expires;

# This is a combined script to run email parsing and web pages
if ( grep ( /$parser/, $0 ) )
   {
	parseEmail (); # Parse the email and exit
	exit ();
   }

if ( grep ( /$processor/, $0 ) )
   {
	processTempSpace (); # Process the files and exit
	exit ();
   }

# Default is to do the Web Display
my %in; &ReadParse (\%in);
my $self = "none";
my $usediv = 0; # This is for the future using DIV to create blocks

if ( $ENV{SCRIPT_NAME} )
   {
	$self = $ENV{SCRIPT_NAME};
	$self =~ s/index.pl//;
	$self =~ s/stage.pl//;
   }
WebProcess ();

#####
# Shared functions starts here
#####

sub readConfig
{
	my $config = shift @_;
	my $line;
	my $name;
	my $value;

	for $line ( readFile ( $config ) )
	   {
		chomp ( $line );

		if ( $line )
		   {
			( $name, $value ) = split ( '=', $line, 2 );
			if ( $value )
			   { chomp ( $value ); }

			if ( $name and $name eq "basedir" ) { $basedir = "$value" };
			if ( $name and $name eq "photos" ) { $photos = "$value" };
			if ( $name and $name eq "samples" ) { $samples = "$value" };
			if ( $name and $name eq "qrcodes" ) { $qrcodes = "$value" };
			if ( $name and $name eq "qrlevel" ) { $qrlevel = "$value" };
			if ( $name and $name eq "qrsize" ) { $qrsize = "$value" };
			if ( $name and $name eq "eventname" ) { $eventname = "$value" };
			if ( $name and $name eq "eventinfo" ) { $eventinfo = "$value" };
			if ( $name and $name eq "additionallinks" ) { $additionallinks = "$value" };
			if ( $name and $name eq "eventpasscode" ) { $eventpasscode = "$value" };
			if ( $name and $name eq "URL" ) { $URL = "$value" };
			if ( $name and $name eq "samplesize" ) { $samplesize = "$value" };
			if ( $name and $name eq "videowidth" ) { $videowidth = "$value" };
			if ( $name and $name eq "videoheight" ) { $videoheight = "$value" };
			if ( $name and $name eq "videoreduction" ) { $videoreduction = "$value" };
			if ( $name and $name eq "displayorder" ) { $displayorder = "$value" };
			if ( $name and $name eq "videodownloads" ) { $videodownloads = "$value" };
			if ( $name and $name eq "photodownloads" ) { $photodownloads = "$value" };
			if ( $name and $name eq "bannertextwidth" ) { $bannertextwidth = "$value" };
			if ( $name and $name eq "imagelogoleft" )
			   {
				$imagelogoleft = "$value";
				if ( $imagelogoleft eq "QRcode" )
				   {
					$imagelogoleft = "$qrcodes/QRcode.gif";
					if ( ! -f "$imagelogoleft" )
					   {
						generateQRcode ( "QRcode.gif" );
					   }
				   }
			   };
			if ( $name and $name eq "imagelogoright" )
			   {
				$imagelogoright = "$value";
				if ( $imagelogoright eq "QRcode" )
				   {
					$imagelogoright = "$qrcodes/QRcode.gif";
					if ( ! -f "$imagelogoright" )
					   {
						generateQRcode ( "QRcode.gif" );
					   }
				   }
			   };
			if ( $name and $name eq "imagelogoleftwidth" ) { $imagelogoleftwidth = "$value" };
			if ( $name and $name eq "imagelogorightwidth" ) { $imagelogorightwidth = "$value" };
			if ( $name and $name eq "watermarkimage" ) { $watermarkimage = "$value" };
			if ( $name and $name eq "background" ) { $background = "$value" };
			if ( $name and $name eq "imagewidth" ) { $imagewidth = "$value" };
			if ( $name and $name eq "qrwidth" ) { $qrwidth = "$value" };
			if ( $name and $name eq "fillwidth" ) { $fillwidth = "$value" };
			if ( $name and $name eq "videocontrols" ) { $videocontrols = "$value" };
			if ( $name and $name eq "uploadenable" ) { $uploadenable = lc ("$value" ) };
			if ( $name and $name eq "uploadkey" ) { $uploadkey = "$value" };
			if ( $name and $name eq "uploadfilename" ) { $uploadfilename = "$value" };
			if ( $name and $name eq "uploadusername" ) { $uploadusername = "$value" };
			if ( $name and $name eq "uploadpassword" ) { $uploadpassword = "$value" };
			if ( $name and $name eq "uploadresponse" ) { $uploadresponse = "$value" };
			if ( $name and $name eq "uploadmaxsize" ) { $uploadmaxsize = "$value" };
			if ( $name and $name eq "deletecode" ) { $deletecode = "$value" };
			if ( $name and $name eq "expires" ) { $expires = "$value" };
		   }
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

#####
# Web Functions starts here
#####

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
	if ( $uploadenable eq "true" )
	   {
		if ( $in{refresh} and $in{refresh} > 60 ) { $refresh = $in{refresh} }
		$refresh = $refresh * 1000;

		print "<script type='text/javascript'>\n";
		print "function load()\n";
		print "{\n";
		print "setTimeout(\"window.open('$self?function=refresh', '_self');\", $refresh);\n";
		print "}\n";
		print "</script>\n";
	   }

	print "<body onload='load()'> \n";
}

sub getFileDateTime
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

		if ( $year and $month and $day and $hour and $minute and $second )
		   { return ( $year, $month, $day, $hour, $minute, $second ); }
	   }

	# The filename does not contain the info
	my $filetime = (stat("$filename"))[9];
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

sub showVideos
{
	my $year;
	my $month;
	my $day;

	my $hour;
	my $minute;
	my $second;

	my $video;
	my $qrfile;
	my $div;
	my $align = "style='vertical-align:middle'";
	my $lazy = "'preload=none'";
	my $poster;

	if ( ! -d "$basedir/$videos" ) { return };

	print "<CENTER>\n"; 
	for $video ( `( cd $basedir/$videos ; ls -t )` )
	   {
		chomp ( $video );

		# Set QR image
		$qrfile = $video;
		$qrfile =~ s/mpeg/gif/;
		$qrfile =~ s/MPEG/GIF/;
		$qrfile =~ s/mp4/gif/;
		$qrfile =~ s/MP4/GIF/;
		$qrfile =~ s/mov/gif/;
		$qrfile =~ s/MOV/GIF/;

		# Set Poster image
		$poster = $qrfile;
		$poster =~ s/GIF/JPG/i;

		if ( $usediv )
		   {
			$div = $video;
			$div =~ s/.mp4//;
			$div =~ s/.MP4//;
			$div =~ s/.mpeg//;
			$div =~ s/.MPEG//;
			$div =~ s/.mov//;
			$div =~ s/.MOV//;
			print "<div id='$div'>\n";
		   };

		$lazy = "preload=none poster='Samples/$poster'";
		# Get Video info
		( $year, $month, $day, $hour, $minute, $second ) = getFileDateTime ( "$videos/$video" );

		print "<TABLE WIDTH=${fillwidth} BORDER=0>\n";
		print "<TR>\n";

		print "<TD ALIGN=middle WIDTH=${imagewidth}>\n";
		print "<video width='$videowidth' height='$videoheight' $videocontrols $lazy>\n";
		print "<source src='$samples/$video' type='video/mp4'>\n";
		print "</video>\n";
		print "</TD>\n";

		if ( $videodownloads )
		   {
			print "<TD WIDTH=${qrwidth} ALIGN=CENTER CLASS=QRBanner>\n";
			print "<FONT CLASS=PhotoTaken>";
			print "Video taken on $month/$day/$year @ $hour:$minute";
			print "</FONT>\n";
			print "<HR WIDTH=85%>\n";
			print "<IMG SRC='QRcodes/$qrfile' WIDTH='100%' $align $lazy>\n";

			print "<FONT CLASS=QRDownload>";
			print "<A HREF='$self?function=download&video=$video'>";
			print "Scan QR code download hi-res video";
			print "</A></FONT>\n";

			if ( $eventpasscode )
			   {
				print "<FONT CLASS=QRDownloadPassCode>(Passcode required)</FONT>\n";
			   }

			if ( $deleteoption and $deletecode )
			   {
				print "====(deletecode)\n";
				print "<FORM METHOD-POST ACTION='$self'>\n";
				print "<INPUT TYPE=HIDDEN NAME=function VALUE='delete'>\n";
				print "<INPUT TYPE=HIDDEN NAME=video VALUE='$video'>\n";
				print "<input type='submit' value='Delete video - $video'>\n";
				print "</FORM>\n";
			   }

			print "</TD>\n";
		   }

		print "</TR>\n";
		print "</TABLE>\n";

		if ( $usediv ) { print "</div>\n"; };
		print "<BR><HR WIDTH=85%><BR>\n";
	   }
	print "</CENTER>\n"; 
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
	my $lazy = "loading='lazy'";
	my $width = "WIDTH=100%";
	my $imageoptions = "$width $lazy $align";

	if ( ! -d "$basedir/$photo" ) { return };

	print "<CENTER>\n"; 
	for $photo ( `( cd $basedir/$photos ; ls -t *.jpg *.JPG *.jpeg *.JPEG ) | egrep -v "QRcode.gif"` )
	   {
		chomp ( $photo );

		$qrfile = $photo;
		$qrfile =~ s/jpg/gif/;
		$qrfile =~ s/JPG/GIF/;
		$qrfile =~ s/jpeg/gif/;
		$qrfile =~ s/JPEG/GIFGIF/;

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
		( $year, $month, $day, $hour, $minute, $second ) = getFileDateTime ( "$photos/$photo" );

		print "<TABLE WIDTH=${fillwidth} BORDER=0>\n";
		print "<TR>\n";

		print "<TD WIDTH=${imagewidth}>\n";
		print "\t<IMG SRC='$samples/$photo' $imageoptions>\n";
		print "</TD>\n";

		if ( $photodownloads )
		   {
			print "<TD WIDTH=${qrwidth} ALIGN=CENTER CLASS=QRBanner>\n";

			print "<FONT CLASS=PhotoTaken>";
			print "Photo taken on $month/$day/$year @ $hour:$minute";
			print "</FONT>\n";
			print "<HR WIDTH=85%>\n";

			print "<A HREF='$self?function=download&photo=$photo'>";
				print "<IMG SRC='QRcodes/$qrfile' $imageoptions>";
			print "</A>";

			print "<FONT CLASS=QRDownload>";
				print "Scan or click on QR code to download full resolution image";
			print "</FONT>\n";

			if ( $eventpasscode )
			   {
				print "<FONT CLASS=QRDownloadPassCode>(Passcode required)</FONT>\n";
			   }

			if ( $deleteoption and $deletecode )
			   {
				print "<FORM METHOD-POST ACTION='$self'>\n";
				print "<INPUT TYPE=HIDDEN NAME=function VALUE='delete'>\n";
				print "<INPUT TYPE=HIDDEN NAME=photo VALUE='$photo'>\n";
				print "<input type='submit' value='Delete photo - $photo'>\n";
				print "</FORM>\n";
			   }

			print "</TD>\n";
		   }

		print "</TR>\n";
		print "</TABLE>\n";

		if ( $usediv ) { print "</div>\n"; };
		print "<BR><HR WIDTH=85%><BR>\n";
	   }
	print "</CENTER>\n"; 
}

sub downloadFile
{
	my $type = shift @_;
	my $dir = shift @_;
	my $file = shift @_;
	my @data = readFile ( "$basedir/$dir/$file" );
	my $line;

	print "Content-Type: $type\n";
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

	return;
}

sub HTMLExpired
{
        print "Content-Type: text/html\n\n";

        if ( $in{search} )
           { print "<TITLE>$eventname</TITLE>\n"; }
           else { print "<TITLE>$eventname</TITLE>\n"; }

        print "<HTML>\n";
        print "<HEAD>\n";
	print "<LINK REL='stylesheet' TYPE='text/css' href='photobooth.css'>\n";
        print "</HEAD>\n";

	if ( $background )
	   {
		print "<style>\n";
		print "body {\n";
		print "  background-image: url('$background');\n";
		print "  background-attachment: fixed;\n";
		print "}\n";
		print "</style>\n";
	   }

	print "<BODY>\n";

	showBanner ();

	print "<CENTER>\n";
	print "Viewing/Download for this event has expired, please contact the event coordinator\n";
	print "</CENTER>\n";

        print "</BODY\n";
        print "</HTML>\n";
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

	if ( $background )
	   {
		print "<style>\n";
		print "body {\n";
		print "  background-image: url('$background');\n";
		print "  background-attachment: fixed;\n";
		print "}\n";
		print "</style>\n";
	   }

	if ( $in{function} and $in{function} eq "refresh" )
	   {
		HTMLreload();
		return;
	   }

	print "<BODY>\n";
}

sub showBanner
{
	my $align = "style='vertical-align:middle'";

	print "<CENTER>\n";
	print "<DIV ID=banner>\n";
	print "<TABLE WIDTH=${fillwidth} BORDER=0>\n";
	print "<TR>\n";
	if ( $imagelogoleft )
	   {
		print "<TD WIDTH=$imagelogoleftwidth>";
		if ( $deletecode ) { print "<A HREF='$self?deleteoption=True'>" }
		print "<IMG SRC='$imagelogoleft' WIDTH=100% $align>";
		if ( $deletecode ) { print "</A>" }
		print "</TD>\n";
	   }

	print "<TH WIDTH=$bannertextwidth CLASS=Banner>";
	print "<FONT CLASS=Event>$eventname</FONT>";
	if ( $eventinfo )
	   {
		print "<BR>\n";
		print "<FONT CLASS=EventInfo>$eventinfo</FONT>";
	   }

	if ( $uploadenable eq "true" )
	   {
		print "<HR WIDTH=75%>\n";
		print "<FONT CLASS=refresh>";
		if ( $in{function} and $in{function} eq "refresh" )
		   {
			print "<A HREF=$self?function=refresh&refresh=180>Pause refresh for 3 minutes</A>";
			print " <A HREF=$self>(Stop refresh)</A>";
		   } else { print "\t<A HREF=$self?function=refresh>(Start auto refresh)</A>\n"; }
		print "</FONT>";
	   }
	print "</TH>\n";

	if ( $imagelogoright )
	   {
		print "<TD WIDTH=$imagelogorightwidth>";
		if ( $deletecode ) { print "<A HREF='$self?deleteoption=True'>" }
		print "<IMG SRC='$imagelogoright' WIDTH=100% $align>";
		if ( $deletecode ) { print "</A>" }
		print "</TD>\n";
	   }
	print "</TR>\n";
	print "</TABLE>\n";
	print "</DIV>\n";
	print "</CENTER>\n";
	print "<HR WIDTH=85%>\n";

	my $expired = checkExpires ();
}

sub HTMLEnd
{
        print "</BODY\n";
        print "</HTML>\n";
}

sub askForCode
{
	my $type = shift @_;
	# Someday, this should be made nicer
	my $key;

	print "<CENTER>\n";
	print "<FORM METHOD=POST ACTION='$self'>\n";

	if ( $type eq "passcode" )
	   { print "Event Passcode for download: <INPUT TYPE=INPUT NAME='$type' VALUE=''>\n"; }

	if ( $type eq "deletecode" )
	   { print "Enter code for deletion: <INPUT TYPE=INPUT NAME='$type' VALUE=''>\n"; }

	for $key ( keys (%in) )
	   {
		chomp ( $key );
		if ( $key ne "$type" )
		   {
			print "<INPUT TYPE=HIDDEN NAME=$key VALUE='$in{$key}'>\n";
		   }
	   }

	print "<INPUT TYPE=SUBMIT VALUE=Submit>\n";
	print "</FORM>";
	print "</CENTER>\n";
}

sub getUpLoadFile
{
	my $username;
	my $password;
	my $success;
	my $errormessage = "Error upload failed.";

	my $query = new CGI;
	my $photo = $query->param("$uploadkey");
	my $uploadfilehandle;

	# Set the max filesize before starting
	$CGI::POST_MAX = 1024 * $uploadmaxsize;

	if ( $in{username} ) { $username = $in{username} }
	if ( $in{password} ) { $password = $in{password} }

	if ( $uploadenable eq "true" )
	   {
		if ( $uploadusername ne $username )
		   {
			$errormessage = "Username/Password failed";
			goto UploadDone;
		   }

		if ( $uploadpassword ne $password )
		   {
			$errormessage = "Username/Password failed";
			goto UploadDone;
		   }
	   }
	   else { goto UploadDone; }

	if ( $username and $password and $uploadusername and $uploadpassword and $uploadusername eq $username and $uploadpassword eq $password )
	   {
		# Get the upload file
		$uploadfilehandle = $query->upload("$uploadkey");
		open ( UPLOADFILE, ">$basedir/$tempspace/$photo" ) or die "$!";
		binmode UPLOADFILE;
		while ( <$uploadfilehandle> )
		   {
			print UPLOADFILE;
		   }
		close UPLOADFILE;
		processFiles ();
		$success=1;
	   }

	UploadDone:
	if ( $uploadresponse eq "JSON" )
	   {
		#
        	print "Content-Type: application/json\n\n";

		print "{\n";
		if ( $success )
		   {
   			print "\"status\": true,\n";
   			print "\"error\": \"Upload Successful\",\n";
   			print "\"url\": \"$URL/?function=download&photo=$photo\"\n";
		   } else
		   {
   			print "\"status\": false,\n";
   			print "\"error\": \"$errormessage\"\n";
		   }
		print "}\n";
		return ();
	   }

	if ( $uploadresponse eq "XML" )
	   {
		#
        	print "Content-Type: application/xhtml+xml\n\n";
		print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		if ( $success )
		   {
			print "<rsp status=\"ok\" url=\"$URL/?function=download&photo=$photo\" >\n";
			print "<err msg=\"Upload Successful\" />\n";
		   } else
		   {
			print "<rsp status=\"fail\" >\n";
			print "<err msg=\"$errormessage\" />\n";
		   }
		print "</rsp>\n";
		return ();
	   }

	# Last action of upload to send a redirect to the basepage, as there is no forms page for this.
	sendRedirect ();
	return ();
}

sub deleteFile
{
	my $type = shift @_;
	my $file = shift @_;

	# Delete photos
	if ( $type eq "photo" )
	   {
		`/bin/rm -f $samples/$file $photos/$file $qrcodes/$file`;
	   }

	# Delete videos
	if ( $type eq "video" )
	   {
		`/bin/rm -f $samples/$file $videos/$file $qrcodes/$file`;
	   }
}

sub checkExpires
{
	my $currenttime = time ();
	my $year;
	my $month;
	my $day;
	my @expirestruct;
	my $expiredtime;

	# Just do a double check of expires
	if ( $expires )
	   {
		# Set up the expires info
		( $year, $month, $day ) = split ( '-', $expires );

		$expirestruct[0] = 59;			# Seconds
		$expirestruct[1] = 59;			# Minute
		$expirestruct[2] = 23;			# Hour
		$expirestruct[3] = $day;		# Day
		$expirestruct[4] = $month - 1;		# Month
		$expirestruct[5] = $year - 1900;	# YEar
		$expirestruct[6] = '';	#
		$expirestruct[7] = '';	#
		$expirestruct[8] = '';	#
		$expiredtime = timegm ( @expirestruct );

		if ( $currenttime > $expiredtime )
		   {
			return ( $expiredtime );
		   }
	   }

	# Just in case, return a 0
	return;
}

sub WebProcess
{
	# Main start function for displaying the web pages
	use Cwd;
	my $dir = getcwd;
	readConfig ( "$configfile" );
	my %displayed;
	my $display;

	if ( $expires and checkExpires () )
	   {
		HTMLExpired ();
		exit ();
	   }

	# Set up to show delete button
	if ( $in{deleteoption} )
	   {
		$deleteoption = 'True';
	   }

	# If this script is not in the basedir, send a redirect
	if ( ( $dir ne $basedir ) or ( ! grep ( /$self/, $URL ) ) )
	   {
		sendRedirect;
		exit ();
	   };


	# Handle deletion of file
	if ( $in{function} and $in{function} eq "delete" and ( $in{photo} or $in{video} ) )
	   {
		if ( $deletecode and $in{deletecode} and $deletecode eq $in{deletecode} )
		   {
			if ( $in{photo} ) { deleteFile ( "photo", $in{photo} ) }
			if ( $in{video} ) { deleteFile ( "video", $in{video} ) }
		   }
		   else
		   {
			HTMLStart ();
			askForCode ( "deletecode" );
			HTMLEnd ();
			exit ();
		   }
	   }

	# If this is for the download, handle it here
	if ( $in{function} and $in{function} eq "download" and ( $in{photo} or $in{video} ) )
	   {
		if ( $eventpasscode and $in{passcode} and $in{passcode} eq $eventpasscode )
		   {
			if ( $in{photo} and $photodownloads )
			   { downloadFile ( "image/jpeg", $photos, $in{photo} ); }

			if ( $in{video} and $videodownloads )
			   { downloadFile ( "video/mp4", $videos, $in{video} ); }

			exit ();
		   }
		if ( $eventpasscode )
		   {
			HTMLStart ();
			askForCode ( "passcode" );
			HTMLEnd ();
			exit ();
		   }

		# Download file with no passcode
		if ( $in{photo} and $photodownloads )
		   { downloadFile ( "image/jpeg", $photos, $in{photo} ); }

		if ( $in{video} and $videodownloads )
		   { downloadFile ( "video/mp4", $videos, $in{video} ); }
	   }

	# If this is for upload
	if ( $in{$uploadkey} )
	   {
		getUpLoadFile ();
		exit ();
	   }

	# Default, show the pages
	HTMLStart ();
	showBanner ();

	if ( $additionallinks and -f "$additionallinks" )
	   {
		my $linkhtml = `cat $additionallinks`;
		print "$linkhtml\n";
	   }

	for $display ( split ( " |,", $displayorder ) )
	   {
		if ( !$displayed{Videos} and $display eq "Videos" )
		   {
			showVideos ();
			$displayed{$display} = 1;
		   }
		if ( !$displayed{Photos} and $display eq "Photos" )
		   {
			showPhotos ();
			$displayed{$display} = 1;
		   }
	   }
	HTMLEnd ();
}

#####
# Web functions for Email parsing starts here
#####

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
	$qrfile =~ s/JPG/GIF/;
	$qrfile =~ s/jpeg/gif/;
	$qrfile =~ s/JPEG/GIF/;
	$qrfile =~ s/mpeg/gif/;
	$qrfile =~ s/MPEG/GIF/;
	$qrfile =~ s/mp4/gif/;
	$qrfile =~ s/MP4/GIF/;


	my $qrcode = Imager::QRCode->new(
		size		=> '$qrsize',
		margin		=> 2,
		version		=> 1,
		level		=> '$qrlevel',
		casesensitive	=> 1,
		lightcolor	=> Imager::Color->new(255, 255, 255),
		darkcolor	=> Imager::Color->new(0, 0, 0),
		);
	my $img = $qrcode->plot("$URL/?function=download&photo=$file");
	if ( $file eq "QRcode.gif" ) { $img = $qrcode->plot("$URL"); }

	$img->write(file => "$qrfile"); # or die "Failed to write: " . $img->errstr;
}

sub checkFileName
{
	my $type = shift @_;
	my $filename = shift @_;
	my $newfile = $filename;

	my $count = 1;
	my $max = 100;
	my $base;
	my $extension;

	( $extension, $base ) = split ( '\.', reverse ( $filename ), 2 );
	$extension = reverse ( $extension );
	$base = reverse ( $base );

	while ( $count < $max and -f "$basedir/$type/$newfile" )
	   {
		# Found a file with the same name
		$newfile = "${base}-${count}.$extension";
		$count++;
	   }

	return ( $newfile );
}

sub processFiles
{
	my $reprocess;
	if ( @_ ) { $reprocess = shift @_; }

	my $file;
	my $convert = "/usr/bin/convert";
	my $composite = "/usr/bin/composite";
	my $checkedname;
	my $ffmpeg = "ffmpeg";
	my $ffmpegoptions = "-y -vcodec libx264 -vf 'scale=trunc(iw/${videoreduction})*2:trunc(ih/${videoreduction})*2' -crf 28";
	my $sourcedir = "$basedir/$tempspace/";
	my $poster;

	if ( $reprocess )
	   {
		if ( $reprocess eq "photos" ) { $sourcedir = "$basedir/$photos/"; }
		if ( $reprocess eq "videos" ) { $sourcedir = "$basedir/$videos/"; }
	   }

	# Process and move files
	for $file ( `( cd $sourcedir/ ; ls )` )
	  {
		chomp ( $file );

		# Process photos
		if ( grep ( /.JPG|.JPEG/i, $file ) )
		   {
			# Do this for the first time
			$checkedname = $file;			
			if ( !$reprocess )
			   {
				$checkedname = checkFileName ( "$photos", $file );
				generateQRcode ( $checkedname );
				`/bin/mv $sourcedir/$file $basedir/$photos/$checkedname`;
			   }

			# Process file
			`$convert -quality 99 -resize '$samplesize>x$samplesize>' $basedir/$photos/$checkedname $basedir/$samples/$checkedname`;
			if ( $watermarkimage )
			   {
				`$composite -gravity Center $basedir/$watermarkimage $basedir/$samples/$checkedname $basedir/$samples/$checkedname`;
			   }
		   }

		# Process videos
		if ( grep ( /.MPEG|.MP4|.MOV/i, $file ) )
		   {
			# Do this for the first time
			$checkedname = $file;			
			$poster = $checkedname;
			$poster =~ s/MPEG/JPG/i;
			$poster =~ s/MP4/JPG/i;
			$poster =~ s/MOV/JPG/i;

			if ( !$reprocess )
			   {
				$checkedname = checkFileName ( $videos, $file );
				generateQRcode ( $checkedname );
				`/bin/mv $sourcedir/$file $basedir/$videos/$checkedname`;
			   }

			# Process file
			`$ffmpeg -i $videos/$checkedname $ffmpegoptions $samples/$checkedname`;

			# Create Poster file
			`$ffmpeg -i $samples/$checkedname -y -frames:v 1 -q:v 2 $samples/$poster`;
		   }

		# Do this for the first time
		if ( !$reprocess )
		   {
			# Remove file
			`/bin/rm -f $sourcedir/$file`;
		   }
	  }
}

sub readSTDIN
{
	my @lines;
	my $line;

	while ( <> )
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
		processFiles ();
	   }
}

sub processTempSpace
{
	readConfig ( "$configfile" );
	if ( $ARGV[0] )
	   { processFiles ( "$ARGV[0]" ); }
	   else { processFiles (); }
}
