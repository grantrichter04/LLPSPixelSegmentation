// -------------------- Initial Setup --------------------
// Set measurements and clear results
run("Set Measurements...", "area mean min stack add redirect=None decimal=3");
run("Clear Results");
print("\\Clear");

// -------------------- User Input Dialog --------------------
// Create a dialog box for user input and collect the inputs
Dialog.create("Enter Bleaching Parameters");
Dialog.addNumber("Prebleach Time Interval: ", 0.420);
Dialog.addNumber("Prebleach Frames: ", 2);
Dialog.addNumber("Total Time Bleaching: ", 2.949);
Dialog.addNumber("First Postbleach Time Interval: ", 1);
Dialog.addNumber("First Postbleach Frames: ", 20);
Dialog.addCheckbox("Include Second Postbleach Time Series?", true);
Dialog.addNumber("Second Postbleach Time Interval: ", 2);
Dialog.addNumber("Second Postbleach Frames: ", 70);
Dialog.addCheckbox("Include Third Postbleach Time Series?", true);
Dialog.addNumber("Third Postbleach Time Interval: ", 5);
Dialog.addNumber("Third Postbleach Frames: ", 16);
Dialog.addCheckbox("Taken on Sp5?", false);
Dialog.show();


//sp5  settings for nat are 1.295 sec pre x2
//bleach 6.47sec
//5 sec for 84 frames

//sp8 low bleach settings
//prebleach 0.420 x2
//bleach 2.949
//pb1 20x1

//sp8 high bleach settings
//prebleach 
//bleach 
//pb1 

// -------------------- Variable Definitions --------------------
// Collect the user-defined parameters
Timepre = Dialog.getNumber();
Framespre = Dialog.getNumber();
bleachtime = (-1 * Dialog.getNumber());
Timepb1 = Dialog.getNumber();
Framespb1 = Dialog.getNumber();
includeSecond = Dialog.getCheckbox();
Timepb2 = Dialog.getNumber();
Framespb2 = Dialog.getNumber();
includeThird = Dialog.getCheckbox();
Timepb3 = Dialog.getNumber();
Framespb3 = Dialog.getNumber();
sp5 = Dialog.getCheckbox();

// Definitions for the image and ROI names
report = "report";
prebleach = "PreBleach background intensity";
postbleach1 = "PostBleach1 background intensity";
prebleachref = "Prebleach reference cell intensity";
postbleach1ref ="Postbleach1 reference cell intensity";
postbleach2 =  "PostBleach2 background intensity";
postbleach2ref = "Postbleach2 reference cell intensity";
openimages = getList("image.titles");
run("Select None");

// -------------------- ROI and Image Handling --------------------
// Clean ROI Manager and set image arrangement
run("Cascade");
if (roiManager("count") > 0) {
	roiManager("Deselect");
	roiManager("Delete");
}
run("Select None");
roiManager("Show None");

// Duplicate and rename images based on opened originals
openimages = getList("image.titles");
for (i = 0; i < openimages.length; i++) {
	if (indexOf(openimages[i], "Pre") > 0) {
		selectWindow(openimages[i]);
		run("Duplicate...", "duplicate");
		rename("Prebleach");
	}
	if (indexOf(openimages[i], "Pb1") > 0) {
		selectWindow(openimages[i]);
		run("Duplicate...", "duplicate");
		rename("Postbleach1");
	}
	if (indexOf(openimages[i], "Pb2") > 0) {
		selectWindow(openimages[i]);
		run("Duplicate...", "duplicate");
		rename("Postbleach2");
	}
	if (indexOf(openimages[i], "Pb3") > 0) {
		selectWindow(openimages[i]);
		run("Duplicate...", "duplicate");
		rename("Postbleach3");
	}
}


// -------------------- Image Concatenation --------------------
// Prepare concatenation based on user input
concatString = "title=FRAPexp open image1=Prebleach image2=Postbleach1";
if (includeSecond) {
    concatString += " image3=Postbleach2";
}
if (includeThird) {
    concatString += " image4=Postbleach3";
}
run("Concatenate...", concatString);

// -------------------- Post-Processing --------------------
// Enhance image contrast and play animation
run("Fire");
run("Enhance Contrast", "saturated=0.35");
selectWindow("FRAPexp");
maxslices = nSlices;
run("Animation Options...", "speed=30 first=1 last=" + maxslices);
doCommand("Start Animation [\\]");

// -------------------- Stabilization Query --------------------
// Ask the user whether the cell needs stabilization
stable = getBoolean("Does Cell Need Stabilisation?");
selectWindow("FRAPexp");
doCommand("Start Animation [\\]");
setSlice(1);

// -------------------- Stack Alignment (If Required) --------------------
// If stabilization is needed, align the slices in the stack
if (stable) {
	selectWindow("FRAPexp");
	setSlice(nSlices);
	title = "Stack Alignment";
	msg = "Draw box around cell in last timepoint";
	setTool("rectangle");
	waitForUser(title, msg);
	run("Enhance Contrast", "saturated=0.35");
	roiManager("add");
	roiManager("Select", 0);
	Roi.getBounds(xx, yy, wwidth, hheight);
	roiManager("rename", "Stack Alignment Selection");
	run("From ROI Manager");
	run("Show Overlay");
	run("Align slices in stack...", "method=5 windowsizex=" + wwidth + " windowsizey=" + hheight + " x0=" + xx + " y0=" + yy + " swindow=0 subpixel=false itpmethod=0 ref.slice=" + nSlices + " show=true");
	run("Clear Results");
	roiManager("Select", 0);
	roiManager("delete");
}

// -------------------- Continue Analysis --------------------
// Continue with the FRAP analysis steps
selectWindow("FRAPexp");
maxslices = nSlices;
setSlice(1);
run("Set Measurements...", "area mean min stack add redirect=None decimal=3");

// -------------------- Confirm Background ROI --------------------

// Initialize at the first slice
setSlice(1);

if (sp5) {
makeRectangle(450, 15, 20, 20, 1); // For a different protocol with 20x20 ROI
}
else {
	makeRectangle(446, 15, 12, 12); // For SP8
	run("Specify...", "width=12 height=12 x=225 y=15 slice=" + i);
	run("Fit Circle");
}


// Enhance contrast for better visualization
run("Enhance Contrast", "saturated=0.35");

// Animation settings
selectWindow("FRAPexp");
maxslices = nSlices;
run("Animation Options...", "speed=30 first=1 last=maxslices");

// Start animation and display a dialog for user confirmation
doCommand("Start Animation [\\]");
title = "Background";
msg = "Confirm background position acceptable or reposition THEN hit OK  \n Do not position background ROI overlapping cell's ROI";
waitForUser(title, msg);
doCommand("Start Animation [\\]");

// Add the confirmed ROI to the ROI Manager
roiManager("add");

// Delete previous ROI if needed
roiManager("Select", 0);
Roi.getBounds(x, y, width, height);
roiManager("Select", 0);
roiManager("delete");
run("Select None");


// Image preprocessing for thresholding
// ... (section 3)
run("Set Measurements...", "area mean min add redirect=None decimal=3");
selectWindow("FRAPexp");
run("Fire");
setSlice(1);
run("Duplicate...", "duplicate");
rename("Dup");
run("Gaussian Blur...", "sigma=3 stack");
run("ROI Manager...");
// Threshold selection
// ... (section 4)
title = "Thresholding Choice";
msg = "Chose a Threshold method that captures most of the cell in the image\nThen click \"OK\".\n Triangle usually works best.";
run("Threshold...");
waitForUser(title, msg);
getThreshold(lower, upper);  
setThreshold(lower, upper);
run("Overlay Options...", "stroke=blue width=0 fill=none set show");



run("Overlay Options...", "stroke=yellow width=0 fill=none set show");
selectWindow("FRAPexp");
run("Set Measurements...", "area mean min stack add redirect=None decimal=3");


selectWindow("FRAPexp");
// Set bleach point ROI	
run("Select None");
run("Enhance Contrast", "saturated=0.35");	
selectWindow("FRAPexp");
setSlice(1);

// Create ROI
if (sp5) {
	makeRectangle(150, 15, 20, 20, 1);//fornatprotocol with 20x20 roi
}
else {
	run("Specify...", "width=12 height=12 x=200 y=25 slice=1");
	run("Fit Circle");
}

//makeEllipse(150, 15, 12, 12, 1);




// Set ROI properties
run("Properties... ", "  stroke=green");
roiManager("Add");  // Add to ROI Manager
selectWindow("FRAPexp");
roiManager("Select", 0);
run("Hide Overlay");
run("In [+]");
run("In [+]");
// User Confirmation for ROI Position
title = "BleachROI selection";
msg = "Re-position ROI over bleach area, add to manager, repeat for each slice, THEN hit OK.\n(position with arrow keys, add to manager with 't' next slice with '.')";
run("Brightness/Contrast...");
waitForUser(title, msg);

// Verify number of ROIs
while (roiManager("count") != (nSlices + 1)) {
    roiManager("Deselect");
    roiManager("Delete");
    // Resetting to initial ROI setup
    selectWindow("FRAPexp");
    setSlice(1);
    
    if (sp5) {
	makeRectangle(150, 15, 20, 20, 1);//fornatprotocol with 20x20 roi
}
else {
	run("Specify...", "width=12 height=12 x=200 y=25 slice=1");
	run("Fit Circle");
}
    
   
    run("Properties... ", "  stroke=green");
    roiManager("Add");
    selectWindow("FRAPexp");
    title = "REPEAT BleachROI selection";
    msg = "ERROR: ROI count does not match the number of slices, try again.";
    waitForUser(title, msg);
}

// Delete temporary ROI
roiManager("Select", 0);
roiManager("Delete");

// Rename and measure ROIs
nROIs = roiManager("Count");
for (i = 1; i <= nROIs; i++) {
    selectWindow("FRAPexp");
    setSlice(i);
    name = "BLEACH-ROI" + i;
    roiManager("Select", i - 1);
    roiManager("rename", name);
}
roiManager("deselect");
roiManager("measure");
run("From ROI Manager");

// Clear existing ROIs
roiManager("Deselect");
roiManager("Delete");

// Create report table and save measurements
Table.create(report);
loopnumber = getValue("results.count");
for(n = 0; n < loopnumber; n++) {
    selectWindow(report);
    Table.set("Timepoint", n, ((n)));
    Table.set("BleachROI", n, getResult("Mean", n));
}

// Clear previous results and set overlay options
run("Clear Results");
run("Overlay Options...", "stroke=yellow width=0 fill=none set show");
selectWindow("FRAPexp");
run("Set Measurements...", "area mean min stack add redirect=None decimal=3");

selectWindow("Dup");
// Convert to Mask and Dilate
// ... (section 5)
run("Convert to Mask", "black");
run("Dilate", "stack");
run("Dilate", "stack");
run("Dilate", "stack");
run("Keep Largest Region"); // needs morpholibj plugin

// Analyze particles
// ... (section 6)
run("Analyze Particles...", "size=3000-Infinity pixel add slice");
run("Select None");  
close("Dup");
close("Dup-largest");
selectWindow("FRAPexp");



// Rename and Add ROIs (for the Reference)
// ...
roiManager("Select", 0);
Roi.setPosition(1);
name = "Reference";
roiManager("Show None");
roiManager("Show All");
roiManager("Select", 0);
roiManager("rename", name);
for (i = 1; i <= nSlices; i++) {
    setSlice(i);
    roiManager("Add");
    roiManager("Select", i - 1);
    roiManager("rename", name + i);
    Roi.setPosition(i);
}

roiManager("Select", nSlices);
roiManager("delete");

// Measure ROIs and save the measurements (for the Reference)
// ...
run("Clear Results");
roiManager("deselect");
//doCommand("Start Animation [\\]");
//title = "check step";
//msg = "verify cell stays within boundaries";
//run("ROI Manager...");
//waitForUser(title, msg);	
//roiManager("Deselect");
roiManager("measure");
run("From ROI Manager");
roiManager("Deselect");
roiManager("Delete");


// Create a table for the report and save the measurements of the ROIs


loopnumber = getValue("results.count");
for(n = 0; n < loopnumber; n++) {
    selectWindow(report);
    Table.set("Reference", n, getResult("Mean", n));
}



// Start Animation
doCommand("Start Animation [\\]");	


run("Clear Results");
run("Overlay Options...", "stroke=yellow width=0 fill=none set show");
selectWindow("FRAPexp");
run("Set Measurements...", "area mean min stack add redirect=None decimal=3");
doCommand("Start Animation [\\]");	


// Create and measure background ROIs
for (i = 1; i <= nSlices; i++) {
	setSlice(i);
	 
    if (sp5) {
	makeRectangle(x, y, 20, 20);//fornatprotocol with 20x20 roi
}
else {
	
	makeRectangle(x, y, 12, 12);
	run("Specify...", "width=12 height=12 x=" + x + " y=" + y + " slice=" + i);
	run("Fit Circle");
}
	roiManager("Add");
	name = "Background - " + i;
	roiManager("Select", i - 1);
	roiManager("rename", name);
	run("Measure");
}

// Clear existing ROIs
roiManager("Deselect");
roiManager("Delete");

// Save measurements in the report
loopnumber = getValue("results.count");
for (n = 0; n < loopnumber; n++) {
	selectWindow(report);
	Table.set("Background", n, getResult("Mean", n));
}
Table.update();

// Reset animation and clear results
selectWindow("FRAPexp");
run("Overlay Options...", "stroke=green width=0 fill=none set");
doCommand("Start Animation [\\]");

// Initialize row counter for table
row = 0;

// Calculate starting time for prebleach
startPrebleachTime = bleachtime + (-1)*(Timepre * (Framespre-1));

//print(startPrebleachTime);


// Setting times for prebleach
for(n = 0; n < Framespre; n++) {
    Table.set("Timepoint", row, startPrebleachTime + (Timepre * n));
    row++;
}

// Setting times for first set of postbleach frames
T = 0;  // Resetting T to 0 for postbleach times
for(n = 0; n < Framespb1; n++) {
    Table.set("Timepoint", row, T);
    row++;
    if (n != Framespb1 - 1) {
        // Only update T if it is not the last iteration of the loop
        T = T + Timepb1;
    }
}

// Conditionally setting times for second postbleach if included
if (includeSecond) {
    for(n = 0; n < Framespb2; n++) {
        Table.set("Timepoint", row, T + Timepb2);
        T = T + Timepb2;
        row++;
    }
}

// Conditionally setting times for third postbleach if included
if (includeThird) {
    for(n = 0; n < Framespb3; n++) {
        Table.set("Timepoint", row, T + Timepb3);
        T = T + Timepb3;
        row++;
    }
}


Table.update();

// Prompt user to specify the directory.
saveDir = getDirectory("Choose a Directory to Save Files...");

// Prompt user to specify the filename.
fileName = getString("Enter the filename", "defaultName");

// Create the full paths for both files.
csvPath = saveDir + fileName + ".csv";
tifPath = saveDir + fileName + ".tif";

// Save the "Results" table as CSV
saveAs("Results", csvPath);

// Your code to activate or create the TIFF window.
// Then save it.
saveAs("Tiff", tifPath);