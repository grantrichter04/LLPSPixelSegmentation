// This ImageJ macro performs an analysis of microscopy images, specifically targeting the detection and measurement of biomolecular condensates in cells.
// The macro assists researchers in studying the distribution, intensity, and quantity of condensates within cells.

// Initialize environment
setBackgroundColor(0, 0, 0);  // Set the background color to black
run("Set Measurements...", "area mean standard integrated add redirect=None decimal=2");  // Configure the measurements settings
classifier = "C:/classifiers/";  // Specify the location of the classifiers
print("\\Clear");  // Clear the log
run("Clear Results");  // Clear the results

// Load and preprocess the image
originalname = getTitle();
selectWindow(originalname);
run("Duplicate...", "title=MotorNeuron duplicate");
run("Enhance Contrast", "saturated=0.35");
getDimensions(width, height, channels, slices, frames);  // Retrieve image dimensions
if (channels == 2) {
	n=nSlices;
	setSlice(n/2);
	Stack.setDisplayMode("color");
	Stack.setChannel(2);
	run("Enhance Contrast", "saturated=0.35");
	Stack.setChannel(1);
	run("Enhance Contrast", "saturated=0.35");
	Stack.setDisplayMode("composite");
	
	
}

if (channels == 3) {
	n=nSlices;
	setSlice(n/2);
	Stack.setDisplayMode("color");
	Stack.setChannel(3);
	run("Enhance Contrast", "saturated=0.35");
	Stack.setChannel(2);
	run("Enhance Contrast", "saturated=0.35");
	Stack.setChannel(1);
	run("Enhance Contrast", "saturated=0.35");
	Stack.setDisplayMode("composite");
	
	
}

// User interaction for cropping
title = "Cropping";
msg = "Crop to the cell of interest, then click \"OK\".\nTip: draw around cell then Edit > Clear Outside.";
setTool("freehand");
waitForUser(title, msg);
run("Select None");

// Process image based on the number of channels
if (channels == 1) {
    if (slices > 1) {
        run("Z Project...", "projection=[Max Intensity]");
        originalname = getTitle();
        getDimensions(width, height, channels, slices, frames);	
    }
    run("Enhance Contrast", "saturated=1");
    run("Duplicate...", "title=Cellbody duplicate");
    run("Duplicate...", "title=Nuc duplicate");
    run("Duplicate...", "title=TDP duplicate");
    fork = "singlechannelmip";
} else if (channels == 2) {
    enhanceContrastForAllChannels(2, slices);
    run("Duplicate...", "title=MotorNeuron2 duplicate");
    run("Split Channels");
    selectWindow("C1-MotorNeuron2");
    rename("TDP");
    run("Duplicate...", "title=Cellbody duplicate");
    selectWindow("C2-MotorNeuron2");
    rename("Nuc");
} else if (channels == 3) {
    enhanceContrastForAllChannels(3, slices);
    run("Duplicate...", "title=MotorNeuron2 duplicate");
    run("Split Channels");
    selectWindow("C1-MotorNeuron2");
    rename("TDP");
    selectWindow("C2-MotorNeuron2");
    rename("Nuc");
    selectWindow("C3-MotorNeuron2");
    rename("Cellbody");	
}


// Select nucleus window
run("Cascade");
selectWindow("MotorNeuron");



// Check for single channel - if so can only do traditional thresholding helped by user
if (channels == 1) {
    Img = "Nuc";
    nucThreshold(Img);
    Img = "Cellbody";
    cellbodyThreshold(Img);
    fork = "mip";

} else if (channels == 2) { // For multi-channel images
    if (slices > 1) { 
        fork = "stack";
        Img = "Nuc";
        nucclassifiers(Img);
        Img = "Cellbody";
    	cellbodyThreshold(Img);
    }else {
    Img = "Nuc";
    nucThreshold(Img);
    Img = "Cellbody";
    cellbodyThreshold(Img);
    fork = "mip";
    }
      
    } else if (channels ==3) { 
    	if (slices > 1) { 
        fork = "stack";
        Img = "Nuc";
        nucclassifiers(Img);
        Img ="Cellbody";
    	cellbodythresholdnesnls(Img);
               
    }
    else {
    	fork="mip";
    	Img = "Nuc";
    	nucThreshold(Img);
    	Img ="Cellbody";
    	cellbodythresholdnesnls(Img);
    	
    }
    
    }

   


Img="TDP";
Speckleseg(Img);
cleanup();

if (fork == "mip") { 
        inspectmip();
        measuremip();
    } else if (channels == 2){
    	inspectstack();
    	measurestack();
    } else if (channels == 3){
    	inspectstack3channel();
    	measurestack();
    }
    

close("*");







//list of functions:
//function enhanceContrastForAllChannels
//function cellbodyThreshold
//function nucThreshold
//function nucclassifiers
//function Speckleseg
//function cleanupfunction cleanup
//function inspectmip
//function inspectstack
//function measuremip
//function cellbodythresholdnesnls



// Helper function to enhance contrast for all channels
function enhanceContrastForAllChannels(channels, slices) {
    Stack.setSlice(slices/2);
    for (ch = 1; ch <= channels; ch++) {
        Stack.setChannel(ch);
        run("Enhance Contrast", "saturated=0.35");
    }
}


function cellbodyThreshold(Img) {
    selectWindow(Img);
    // Duplicate the image and threshold
    run("Duplicate...", "title="+Img+"_dup duplicate");
    // Select and preprocess the image
    run("Median...", "radius=2");
        
    title = "Thresholding Choice";
    msg = "Choose a Threshold method that captures most of the cell in the image. Crop out others if needed then click \"OK\". IMPORTANT! Make sure Stack histogram is checked.";
    selectWindow(Img+"_dup");
    setAutoThreshold("Triangle dark stack");  // Set auto threshold for the entire stack
    run("Threshold...");  // Run the threshold dialog for user input
    
    // Wait for the user to finish with the thresholding
    waitForUser(title, msg);
    
    // Get and apply the user-defined thresholds
    getThreshold(lower, upper);
    setThreshold(lower, upper); 
    run("Convert to Mask", "black");  // Convert the image to a binary mask
    
    // Post-process the mask
    run("Keep Largest Region");
    close(Img+"_dup");
    selectWindow(Img+"_dup-largest");
    rename("MASK_"+Img);
    
    // Refine mask with a sequence of morphological operations
    run("3D Binary Close Labels", "radiusxy=0 radiusz=2 operation=Erode");
    close("MASK_"+Img);
    selectWindow("CloseLabels");
    rename("MASK_"+Img);
    run("3D Binary Close Labels", "radiusxy=10 radiusz=10 operation=Close");
    close("MASK_"+Img);
    selectWindow("CloseLabels");
    rename("MASK_"+Img);
    
    // Further process the mask
    run("Fill Holes", "stack");
    run("Cascade");
    selectWindow("Threshold"); 
    run("Close");
}


function nucThreshold(Img) {
    selectWindow(Img);
    
    // Duplicate the image and threshold
    run("Duplicate...", "title="+Img+"_dup duplicate");
    // Select and preprocess the image
    run("Median...", "radius=2");
    title = "Thresholding Choice";
    msg = "Choose a Threshold method that captures most of the nucleus in the image. Crop out others if needed then click \"OK\". IMPORTANT! Make sure Stack histogram is checked.";
    selectWindow(Img+"_dup");
    setAutoThreshold("Moments dark stack");  // Set auto threshold for the entire stack
    run("Threshold...");  // Run the threshold dialog for user input
    
    // Wait for the user to finish with the thresholding
    waitForUser(title, msg);
    
    // Get and apply the user-defined thresholds
    getThreshold(lower, upper);
    setThreshold(lower, upper); 
    run("Convert to Mask", "black");  // Convert the image to a binary mask
    
    // Post-process the mask
    run("Keep Largest Region");
    close(Img+"_dup");
    selectWindow(Img+"_dup-largest");
    rename("MASK_"+Img);
    run("3D Binary Close Labels", "radiusxy=10 radiusz=3 operation=Close");
    close("MASK_"+Img);
    selectWindow("CloseLabels");
    rename("MASK_"+Img);
    run("Fill Holes", "stack");
    run("Cascade");
    selectWindow("Threshold"); 
    run("Close");
}

function nucclassifiers(Img) {
	classifier = "C:/classifiers/";
    selectWindow(Img);
    ilp="Nuc";
    run("Run Pixel Classification Prediction", "projectfilename="+classifier+ilp+".ilp inputimage="+Img+" pixelclassificationtype=Probabilities");
    rename("tmp");
    run("Split Channels");
	selectImage("C1-tmp");
	close();
	selectImage("C2-tmp");
	run("8-bit");
	selectImage("C2-tmp");
    setAutoThreshold("Triangle dark stack"); // Set auto threshold for the entire stack
    run("Convert to Mask", "black"); // Convert the image to a binary mask
    rename("MASK_Nuc");
    run("Keep Largest Region");
    selectImage("MASK_Nuc");
	close();
	selectImage("MASK_Nuc-largest");
	rename("MASK_Nuc");
	run("3D Fill Holes");
	run("3D Binary Close Labels", "radiusxy=5 radiusz=3 operation=Close");
	close("MASK_Nuc");
	selectWindow("CloseLabels");
	rename("MASK_Nuc");
	run("Erode", "stack");
}






function Speckleseg(Img) {
    // Initialize the classifier path
    classifier = "C:/classifiers/";
    
    // Select the image and get its dimensions
    selectWindow(Img);
    getDimensions(width, height, channels, slices, frames);
    
    // Determine the type of image (MIP vs stack)
    if (slices == 1) {
        ilp = "tdpmip";  // For MIP image
    } else if (slices > 1) {
        ilp = "tdp";     // For image stack
    }
    
    // Run Pixel Classification Prediction using Ilastik
    run("Run Pixel Classification Prediction", "projectfilename=" + classifier + ilp + ".ilp inputimage=" + Img + " pixelclassificationtype=Segmentation");
    
    // Rename the output and visualize the segmentation
    rename("tmp");
    run("Duplicate...", "duplicate");
    rename("seg_" + Img);
    resetMinAndMax();
    run("glasbey");
    close("tmp");    
    run("Tile");
    run("Cascade");
    
    // Create a condensate mask using 3D Simple Segmentation
    print("Condensate mask:");
    selectWindow("seg_" + Img);
    run("3D Simple Segmentation", "low_threshold=3 min_size=50 max_size=-1");
    selectWindow("Seg");
    rename("tmp");
    selectWindow("Bin");
    close();
    selectWindow("tmp");
    run("3D Simple Segmentation", "low_threshold=1 min_size=0 max_size=-1");
    selectWindow("tmp");
    close();
    
    // Prepare a speckle mask
    selectWindow("Bin");
    selectWindow("Seg");
    close();
    selectWindow("Bin");
    run("3D Simple Segmentation", "low_threshold=1 min_size=0 max_size=-1");
    selectWindow("Bin");
    close();
    selectWindow("Bin");
    rename("MASK_Speckles");
    selectWindow("Seg");
    rename("seg_Speckles");
    run("glasbey");
    close("seg_" + Img);
    selectImage("MASK_Speckles");
    run("Cascade");
}


function cleanup() {
    // Subtract the nuclear mask from the cellbody mask to create the cytoplasm mask
    imageCalculator("Subtract create stack", "MASK_Cellbody", "MASK_Nuc");
    selectWindow("Result of MASK_Cellbody");
    rename("MASK_Cytoplasm");
    
    // Create the speckles mask by AND-ing the cellbody mask with the speckles mask
    imageCalculator("AND create stack", "MASK_Cellbody", "MASK_Speckles");
    close("MASK_Speckles");
    selectWindow("Result of MASK_Cellbody");
    rename("MASK_Speckles");
    run("Cascade");

    // Apply Distance Transform Watershed 3D and visualization to the speckles mask
    selectWindow("MASK_Speckles");
    run("Distance Transform Watershed 3D", "distances=[Borgefors (3,4,5)] output=[16 bits] normalize dynamic=1 connectivity=6");
    close("seg_Speckles");
    selectWindow("MASK_Specklesdist-watershed");
    rename("seg_Speckles");
    run("glasbey");
    run("16-bit");
    
    // Apply 3D Simple Segmentation to the speckle mask and cleanup
    run("3D Simple Segmentation", "low_threshold=1 min_size=0 max_size=-1");
    selectWindow("Seg");
    close();
    selectWindow("MASK_Speckles");
    close();
    selectWindow("Bin");
    rename("MASK_Speckles");
    run("Watershed", "stack");
    run("Cascade");

    // Subtract the speckle mask from the nuclear mask to remove speckles
    imageCalculator("Subtract create stack", "MASK_Nuc", "MASK_Speckles");
    selectWindow("Result of MASK_Nuc");
    rename("MASK_Nuc_nospeckle");
    run("Cascade");
  }

function inspectmip(){


selectWindow("MotorNeuron");
if (channels == 2) {
    resetMinAndMax();
    Stack.setDisplayMode("color");
    resetMinAndMax();
    Stack.setChannel(2);
    run("Enhance Contrast", "saturated=0.35");
    run("Magenta");
    Stack.setChannel(1);
    run("Brightness/Contrast...");
    resetMinAndMax();
	run("Fire");
	
	
}

if (channels == 3) {
    resetMinAndMax();
    Stack.setDisplayMode("color");
    resetMinAndMax();
    Stack.setChannel(2);
    run("Enhance Contrast", "saturated=0.35");
    run("Cyan");
    Stack.setChannel(3);
    run("Enhance Contrast", "saturated=0.35");
    run("Magenta");
    Stack.setChannel(1);
    run("Brightness/Contrast...");
    resetMinAndMax();
	run("Fire");
	
	
}

if (channels == 1) {
	run("Fire");
	setMinAndMax(0, 255);
}


run("Cascade");
selectWindow("MASK_Cytoplasm");
run("Create Selection");
selectWindow("MotorNeuron");
run("Restore Selection");
run("Add Selection...");
run("Overlay Options...", "stroke=Green width=0 fill=none set apply");
selectWindow("MotorNeuron");
selectWindow("MASK_Speckles");
run("Create Selection");
selectWindow("MotorNeuron");
run("Restore Selection");
run("Add Selection...");
run("Overlay Options...", "stroke=Green width=0 fill=none set apply");
selectWindow("MotorNeuron");
run("Select None");
Property.set("CompositeProjection", "null");
//Stack.setDisplayMode("color");
//Stack.setChannel(2);
run("Enhance Contrast", "saturated=0.35");
//Stack.setChannel(1);


run("Scale Bar...", "width=5 height=3 thickness=4 font=14 color=White background=None location=[Lower Left] horizontal bold overlay label");
run("In [+]");
title = "check";
msg = "inspect segmentation";
waitForUser(title, msg);

	performedCorrectly = getBoolean("Did the segmentation perform correctly?");
	while (!performedCorrectly) {
		selectWindow("MotorNeuron");
		run("Remove Overlay");
		run("Select None");
		selectWindow("MASK_Nuc_nospeckle");
		close();
		selectWindow("MASK_Cytoplasm");
		close();
		selectWindow("MASK_Cellbody");
		close();
		selectWindow("MASK_Nuc");
		close();
		selectWindow("seg_Speckles");
		close();
		selectWindow("MASK_Speckles");
		close();
		selectWindow("Nuc");
		Img = "Nuc";
    	nucThreshold(Img);
    	Img = "Cellbody";
    	cellbodyThreshold(Img);
    
		Img="TDP";
		Speckleseg(Img);
		cleanup();
	selectWindow("MotorNeuron");
	run("Fire");
setMinAndMax(0, 255);
run("Cascade");
selectWindow("MASK_Cytoplasm");
run("Create Selection");
selectWindow("MotorNeuron");
run("Restore Selection");
run("Add Selection...");
run("Overlay Options...", "stroke=Green width=0 fill=none set apply");
selectWindow("MotorNeuron");
selectWindow("MASK_Speckles");
run("Create Selection");
selectWindow("MotorNeuron");
run("Restore Selection");
run("Add Selection...");
run("Overlay Options...", "stroke=Green width=0 fill=none set apply");
selectWindow("MotorNeuron");
run("Select None");
Property.set("CompositeProjection", "null");
//Stack.setDisplayMode("color");
//Stack.setChannel(2);
run("Enhance Contrast", "saturated=0.35");
//Stack.setChannel(1);
	
	run("Scale Bar...", "width=5 height=3 thickness=4 font=14 color=White background=None location=[Lower Left] horizontal bold overlay label");
		run("In [+]");
		title = "check";
		msg = "inspect segmentation";
		waitForUser(title, msg);
		// Ask the user again if the operation was performed correctly
   		 	performedCorrectly = getBoolean("Did the operation perform correctly now?");
	}

}

function inspectstack(){



selectWindow("TDP");
run("Fire");
setMinAndMax(0, 255);
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=TDP seg=seg_Speckles");
selectWindow("DUP_TDP");
rename("OBJECT_Stack");

// Cell body detection
selectWindow("TDP");
run("Fire");
setMinAndMax(0, 255);
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=TDP seg=MASK_Cytoplasm");
selectWindow("DUP_TDP");
rename("CYTOPLASM_Stack");

// Nucleus stack
selectWindow("TDP");
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=TDP seg=MASK_Nuc");
selectWindow("DUP_TDP");
rename("NUC_Stack");

// Draw Rois for BFP Channel
selectWindow("Nuc");
run("Magenta");
setSlice(nSlices/2);
run("Enhance Contrast", "saturated=0.35");
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=Nuc seg=MASK_Cytoplasm");
selectWindow("DUP_Nuc");
rename("CYTOPLASM_Stack_BFP");

selectWindow("Nuc");
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=Nuc seg=MASK_Nuc");
selectWindow("DUP_Nuc");
rename("NUC_Stack_BFP");

// Combine stacks
run("Combine...", "stack1=CYTOPLASM_Stack_BFP stack2=NUC_Stack_BFP");
rename("BFP_Stack");
run("Combine...", "stack1=CYTOPLASM_Stack stack2=NUC_Stack");
rename("TDP_Stack");
run("Combine...", "stack1=BFP_Stack stack2=TDP_Stack combine");
rename("Summary Stack");

// Prepare segmented speckles for combination
selectWindow("seg_Speckles");
run("glasbey");
run("Duplicate...", "duplicate");
run("RGB Color");

// Combine speckles with OBJECT_Stack and Summary Stack
run("Combine...", "stack1=seg_Speckles-1 stack2=OBJECT_Stack combine");
run("Combine...", "stack1=[Summary Stack] stack2=[Combined Stacks]");
rename(originalname + "Analysed");

run("Cascade");
selectWindow(originalname + "Analysed");

run("Scale Bar...", "width=5 height=3 thickness=4 font=14 color=White background=None location=[Lower Left] horizontal bold overlay label");
run("Orthogonal Views");
title = "check";
msg = "inspect segmentation";
waitForUser(title, msg);
performedCorrectly = getBoolean("Did the segmentation perform correctly?");
	while (!performedCorrectly) {
		exit
	}


}

function measuremip(){
	
// Set the measurements to be calculated for different mask regions
run("Set Measurements...", "area mean integrated add redirect="+originalname+" decimal=3");

// Create selection for the Nucleus mask and perform the measurement
selectWindow("MASK_Nuc");
run("Create Selection");
run("Measure");
setResult("Label", "0", "Nucleus");

// Create selection for the Nucleus without condensates mask and perform the measurement
selectWindow("MASK_Nuc_nospeckle");
run("Create Selection");
run("Measure");
setResult("Label", "1", "Nucleus without condensates");

// Create selection for the Cytoplasm mask and perform the measurement
selectWindow("MASK_Cytoplasm");
run("Create Selection");
run("Measure");
setResult("Label", "2", "Cytoplasm");

run("Cascade");

// Create a table for cell summary
Celltable = "Cell Summary";
Table.create(Celltable);
selectWindow(Celltable);

// Set up cell summary table with measurement results
// For nucleus:
Table.set("Label", 0, originalname);
Table.set("Nuc Area um^2", 0, getResult("Area", 0));
Table.set("Nuc Mean Intensity", 0, getResult("Mean", 0));
Table.set("Nuc RawIntDen", 0, getResult("RawIntDen", 0));

// For nucleus without condensates:
Table.set("Diffuse Area um^2", 0, getResult("Area", 1));
Table.set("Diffuse Mean Intensity", 0, getResult("Mean", 1));
Table.set("Diffuse RawIntDen", 0, getResult("RawIntDen", 1));

// For cytoplasm:
Table.set("Cytoplasm Area um^2", 0, getResult("Area", 2));
Table.set("Cytoplasm Mean Intensity", 0, getResult("Mean", 2));
Table.set("Cytoplasm RawIntDen", 0, getResult("RawIntDen", 2));

run("Clear Results");


// Process the 'Cellbody' image and perform particle analysis
selectWindow("Cellbody");
run("Divide...", "value=2");
imageCalculator("Add create", "MASK_Speckles","Cellbody");
selectWindow("Result of MASK_Speckles");
setThreshold(129, 255, "raw");
run("Create Selection");
run("Analyze Particles...", "summarize");

run("Cascade");

// Clear previous results and rename the summary table
run("Clear Results");
Table.rename("Summary", "Results");
selectWindow("Cell Summary");
updateResults();

// Add summarized data about the condensates to the cell summary table
Table.set("Condensates Count", 0, getResult("Count", 0));
Table.set("Condensates Area um^2", 0, getResult("Total Area", 0));
Table.set("Condensates Mean Intensity", 0, getResult("Mean", 0));



// Analyze particles in the result of mask speckles and calculate the total raw integrated density
selectWindow("Result of MASK_Speckles");
run("Analyze Particles...", "display clear");

q=0;
for (i = 0; i < nResults(); i++) {
    v = getResult("RawIntDen", i);
    q=v+q;
}
    selectWindow("Cell Summary");
Table.set("Condensates' RawIntDen", 0, q);

updateResults();

selectWindow("Results");
Table.set("Name", 0, originalname);
Table.rename("Results", "Condensates Summary");
// Create an output directory for storing the results
selectWindow(Celltable);
output = getDirectory("Output Directory for Segmentor");
File.makeDirectory(output+"/Results");
results = output+"/Results/";
File.makeDirectory(results + "/Detections");
detectionsfolder = results + "/Detections/";

// Clear previous results and save the cell summary and condensates summary in an Excel file
run("Clear Results");
Table.rename(Celltable, "Results");
run("Read and Write Excel", "stack_results dataset_label=[Segmentation Results] no_count_column sheet=Cell Segmentation file=["+results+"Ilastik_Segmentation_MIP.xlsx]");

run("Clear Results");
Table.rename("Condensates Summary", "Results");
run("Read and Write Excel", "stack_results dataset_label=["+originalname+"Condensate Details] sheet=Condensates file=["+results+"Ilastik_Segmentation_MIP.xlsx]");

// Add a scale bar to the "MotorNeuron2" image, rename it, and deselect all
selectWindow("MotorNeuron");
resetMinAndMax();
run("Scale Bar...", "width=5 height=3 thickness=4 font=14 color=White background=None location=[Lower Left] horizontal bold overlay label");
rename(originalname+"_ANALYSED");
run("Select None");
saveAs("Tiff", detectionsfolder + originalname+"_MIP_analysed.tif");
}


function cellbodythresholdnesnls(Img){
classifier = "C:/classifiers/";
     selectWindow(Img);
     // Determine the type of image (MIP vs stack)
    if (slices == 1) {
        ilp = "nesnlsmip";  // For MIP image
    } else if (slices > 1) {
        ilp = "nesnls";     // For image stack
    }
    
    selectWindow(Img);
    
    run("Run Pixel Classification Prediction", "projectfilename="+classifier+ilp+".ilp inputimage="+Img+" pixelclassificationtype=Probabilities");
    rename("tmp");
    run("Split Channels");
	selectImage("C1-tmp");
	close();
	selectImage("C2-tmp");
	close();
	selectImage("C3-tmp");
	run("8-bit");
	selectImage("C3-tmp");
    setAutoThreshold("Moments dark stack"); // Set auto threshold for the entire stack
    run("Convert to Mask", "black"); // Convert the image to a binary mask
    rename("MASK_Cellbody");
    run("Keep Largest Region");
    selectImage("MASK_Cellbody");
	close();
	selectImage("MASK_Cellbody-largest");
	rename("MASK_Cellbody");
	run("3D Fill Holes");
	rename("MASK_Cellbody");
	run("3D Binary Close Labels", "radiusxy=5 radiusz=3 operation=Close");
	close("MASK_Cellbody");
	selectWindow("CloseLabels");
	rename("MASK_Cellbody");
	run("Erode", "stack");

	 	 
}

function measurestack(){
	
// Measure
//-----------------------------------------------------------

output = getDirectory("Output Directory for Segmentor");
File.makeDirectory(output+"/Results");
results = output+"/Results/";
File.makeDirectory(results + "/Detections");
detectionsfolder = results + "/Detections/";

saveAs("Tiff", detectionsfolder + originalname + "_analysed.tif");
	close();

// Set voxel size for the windows with TDP, seg_Speckles, and MASK_Speckles
selectWindow("TDP");
getVoxelSize(width, height, depth, unit);
selectWindow("seg_Speckles");
setVoxelSize(width, height, depth, unit);
selectWindow("MASK_Speckles");
setVoxelSize(width, height, depth, unit);

// Save original image name
savename = originalname;

// Create a separate results table to store measurements
Resultstable = "Results Table";
Table.create(Resultstable);
Table.set("Image", 0, savename);

// Measure the mean intensity, number of voxels, and volume of the nucleus
run("Intensity Measurements 2D/3D", "input=TDP labels=MASK_Nuc mean numberofvoxels volume");
selectWindow("TDP-intensity-measurements");
Table.rename("TDP-intensity-measurements", "Results");

Mean = getResult("Mean", 0);
Sum = getResult("NumberOfVoxels", 0);
Vol = getResult("Volume", 0);

// Store nucleus measurements in the results table
selectWindow(Resultstable);
Table.set("Nucleus Mean Intensity", 0, Mean);
Table.set("Nucleus Intensity Sum", 0, (Mean * Sum));
Table.set("Nucleus Volume (um^3)", 0, Vol);
run("Clear Results");

// Measure the mean intensity, number of voxels, and volume of the nucleus without speckles
run("Intensity Measurements 2D/3D", "input=TDP labels=MASK_Nuc_nospeckle mean numberofvoxels volume");
selectWindow("TDP-intensity-measurements");
Table.rename("TDP-intensity-measurements", "Results");

Mean = getResult("Mean", 0);
Sum = getResult("NumberOfVoxels", 0);
Vol = getResult("Volume", 0);

// Store diffuse nucleus measurements in the results table
selectWindow(Resultstable);
Table.set("Diffuse Mean Intensity", 0, Mean);
Table.set("Diffuse Intensity Sum", 0, (Mean * Sum));
Table.set("Diffuse Volume (um^3)", 0, Vol);
run("Clear Results");

// Measure the mean intensity, number of voxels, and volume of the cytoplasm
run("Intensity Measurements 2D/3D", "input=TDP labels=MASK_Cytoplasm mean numberofvoxels volume");
selectWindow("TDP-intensity-measurements");
Table.rename("TDP-intensity-measurements", "Results");

Mean = getResult("Mean", 0);
Sum = getResult("NumberOfVoxels", 0);
Vol = getResult("Volume", 0);

// Store cytoplasm measurements in the results table
selectWindow(Resultstable);
Table.set("Cytoplasm Mean Intensity", 0, Mean);
Table.set("Cytoplasm Intensity Sum", 0, (Mean * Sum));
Table.set("Cytoplasm Volume (um^3)", 0, Vol);
run("Clear Results");

// Measure speckles' properties
//-----------------------------------------------------------


// Measure the mean intensity, number of voxels, and volume of speckles
run("Intensity Measurements 2D/3D", "input=TDP labels=MASK_Speckles mean numberofvoxels volume");
selectWindow("TDP-intensity-measurements");
Table.rename("TDP-intensity-measurements", "Results");

Mean = getResult("Mean", 0);
Sum = getResult("NumberOfVoxels", 0);
Vol = getResult("Volume", 0);

// Store speckle measurements in the results table
selectWindow(Resultstable);
Table.set("Condensate Mean Intensity", 0, Mean);
Table.set("Condensate Intensity Sum", 0, (Mean * Sum));
Table.set("Total Condensate Volume (um^3)", 0, Vol);
run("Clear Results");

// Count the number of speckles detected
run("3D Numbering", "main=MASK_Cellbody counted=seg_Speckles");
selectWindow("Numbering");
Table.rename("Numbering", "Results");
number = getResult("NbObjects", 0);

// Store the number of detected condensates in the results table
selectWindow(Resultstable);
Table.set("Detected Condensates", 0, number);
run("Clear Results");



// Create a condensate summary table
run("Intensity Measurements 2D/3D", "input=TDP labels=seg_Speckles mean numberofvoxels volume");
selectWindow("TDP-intensity-measurements");
Table.rename("TDP-intensity-measurements", "Condensate Summary");
Table.set("Image", 0, savename);

// Calculate the corrected sphericity for each speckle
selectWindow("seg_Speckles");
run("3D Compactness");

// Get the number of rows in the "Results" table
nRows = nResults;

// Specify the name of the column you want to copy
columnName = "SpherCorr(Pix)";

// Select the condensate summary window
selectWindow("Condensate Summary");

// Loop over each row in the "Results" table
for (row = 0; row < nRows; row++) {
    // Get the value from the "Results" table
    value = getResult(columnName, row);
    
    // Set the value in the condensate summary table
    // The sphericity value computed using volume in pixel unit and corrected surface (pixel unit)
    Table.set("Corrected Sphericity", row, value);
}

// Clear the results table
run("Clear Results");

// Create a new table called "Better Results"
Table.create("Better Results");
Table.rename(Resultstable, "Results");

// Store the image name in the "Better Results" table
selectWindow("Better Results");
Table.set("Image", 0, savename);

// Calculate volumes and ratios
//-----------------------------------------------------------
// Set volume values in the "Better Results" table
Table.set("Nucleus Volume (um^3)", 0, getResult("Nucleus Volume (um^3)", 0));
Table.set("Cytoplasm Volume (um^3)", 0, getResult("Cytoplasm Volume (um^3)", 0));
Table.set("Diffuse Volume (um^3)", 0, getResult("Diffuse Volume (um^3)", 0));
Table.set("Total Condensate Volume (um^3)", 0, getResult("Total Condensate Volume (um^3)", 0));

// Calculate the nucleus-to-cytoplasm volume ratio
Nuc = getResult("Nucleus Volume (um^3)", 0);
Cyto = getResult("Cytoplasm Volume (um^3)", 0);
Ratio = Nuc / Cyto;
selectWindow("Better Results");
Table.set("Nucleus:Cytoplasm Volume", 0, Ratio);

// Set mean intensity values in the "Better Results" table
Table.set("Nucleus Mean Intensity", 0, getResult("Nucleus Mean Intensity", 0));
Table.set("Cytoplasm Mean Intensity", 0, getResult("Cytoplasm Mean Intensity", 0));
Table.set("Diffuse Mean Intensity", 0, getResult("Diffuse Mean Intensity", 0));
Table.set("Condensate Mean Intensity", 0, getResult("Condensate Mean Intensity", 0));

// Calculate the nucleus-to-cytoplasm mean intensity ratio
Nuc = getResult("Nucleus Mean Intensity", 0);
Cyto = getResult("Cytoplasm Mean Intensity", 0);
Ratio = Nuc / Cyto;
Table.set("Nucleus:Cytoplasm Mean Intensity", 0, Ratio);

// Set intensity sum values in the "Better Results" table
Table.set("Nucleus Intensity Sum", 0, getResult("Nucleus Intensity Sum", 0));
Table.set("Cytoplasm Intensity Sum", 0, getResult("Cytoplasm Intensity Sum", 0));
Table.set("Diffuse Intensity Sum", 0, getResult("Diffuse Intensity Sum", 0));
Table.set("Condensate Intensity Sum", 0, getResult("Condensate Intensity Sum", 0));

// Calculate the diffuse nucleus-to-cytoplasm sum intensity ratio
Nuc = getResult("Diffuse Intensity Sum", 0);
Cyto = getResult("Cytoplasm Intensity Sum", 0);
Ratio = Nuc / Cyto;
Table.set("Diffuse Nucleus:Cytoplasm Sum Intensity", 0, Ratio);

// Set the detected condensates value in the "Better Results" table
Table.set("Detected Condensates", 0, getResult("Detected Condensates", 0));
Table.rename("Better Results", "Results");



// Save results to an Excel file
run("Read and Write Excel", "stack_results no_count_column dataset_label=[Segmentation Results] sheet=Segmentation Results file=[" + results + "Ilastik_Segmentation.xlsx]");
run("Clear Results");
Table.rename("Condensate Summary", "Results");
run("Read and Write Excel", "stack_results no_count_column dataset_label=[Condensates] sheet=Condensates  file=[" + results + "Ilastik_Segmentation.xlsx]");
run("Clear Results");


   
      
       
         

// Notify user that analysis is complete and close all windows
//-----------------------------------------------------------
title = "Finished";
msg = "Analysis Finished, results saved at \n" + detectionsfolder;
waitForUser(title, msg);  // Display a dialog box with the message and wait for the user to click "OK"
close("Results");  // Select the "Results" window
		           // Close the "Results" window    

	
	
}

function inspectstack3channel(){
	  
//-----------------------------------------------------------	
// Summary images

// Condensate detection
selectWindow("TDP");
run("Fire");
setMinAndMax(0, 255);
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=TDP seg=seg_Speckles");
selectWindow("DUP_TDP");
rename("OBJECT_Stack");

// Cell body detection
selectWindow("TDP");
run("Fire");
setMinAndMax(0, 255);
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=TDP seg=MASK_Cytoplasm");
selectWindow("DUP_TDP");
rename("CYTOPLASM_Stack");

// Nucleus stack
selectWindow("TDP");
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=TDP seg=MASK_Nuc");
selectWindow("DUP_TDP");
rename("NUC_Stack");

// Draw Rois for BFP Channel
selectWindow("Nuc");
setSlice(nSlices/2);
run("Enhance Contrast", "saturated=0.35");
setForegroundColor(255, 255, 0);
selectWindow("Cellbody");
run("Green");
setSlice(nSlices/2);
run("Enhance Contrast", "saturated=0.35");
setForegroundColor(255, 255, 0);
run("Merge Channels...", "c2=Cellbody c6=Nuc create keep ignore");
run("3D Draw Rois", "raw=Composite seg=MASK_Cytoplasm");
rename("CYTOPLASM_Stack_BFP");


selectWindow("Nuc");
setForegroundColor(0, 255, 0);
run("3D Draw Rois", "raw=Nuc seg=MASK_Nuc");
selectWindow("DUP_Nuc");
rename("NUC_Stack_BFP");

// Combine stacks
run("Combine...", "stack1=CYTOPLASM_Stack_BFP stack2=NUC_Stack_BFP");
rename("BFP_Stack");
run("Combine...", "stack1=CYTOPLASM_Stack stack2=NUC_Stack");
rename("TDP_Stack");
run("Combine...", "stack1=BFP_Stack stack2=TDP_Stack combine");
rename("Summary Stack");

// Prepare segmented speckles for combination
selectWindow("seg_Speckles");
run("glasbey");
run("Duplicate...", "duplicate");
run("RGB Color");

// Combine speckles with OBJECT_Stack and Summary Stack
run("Combine...", "stack1=seg_Speckles-1 stack2=OBJECT_Stack combine");
run("Combine...", "stack1=[Summary Stack] stack2=[Combined Stacks]");
rename(originalname + "Analysed");

run("Cascade");
selectWindow(originalname + "Analysed");

run("Scale Bar...", "width=5 height=3 thickness=4 font=14 color=White background=None location=[Lower Left] horizontal bold overlay label");
title = "check";
msg = "inspect segmentation";
run("Orthogonal Views");
waitForUser(title, msg);

stable = getBoolean("Agree with segmentation?");
setSlice(1);

if (stable == 0) {
    waitForUser("Aborting", "Quitting");
    close("*");
    exit
}
}