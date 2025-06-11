
//run("Arrange Channels...", "new=23");

//--------------------------------------------------
// This section of code checks if certain plugins are installed in ImageJ.

// A list of plugins to check is created. These are the names of the plugins.
plugins = newArray("bv3dbox", "FeatureJ", "MorphoLibJ_", "mcib3d_plugins", "Read_and_Write_Excel", "clij_", "clij2_", "clijx-assistant-morpholibj_", "clijx-assistant_");

// This variable will keep track of any plugins that are missing.
missingPlugins = "";

// Looping through the list of plugins to check each one.
for (i = 0; i < lengthOf(plugins); i++) {
    // Calls the 'pluginExists' function for each plugin. If the plugin is not found, it gets added to 'missingPlugins'.
    if (!pluginExists(plugins[i])) {
        missingPlugins += plugins[i] + "\n";
    }
}

// Checking if any plugins were missing.
if (missingPlugins != "") {
    // If there are missing plugins, it prints a message listing them.
    print("The following plugins are missing:\n" + missingPlugins);
    // Shows a dialog box to the user, asking them to update the missing plugins before proceeding.
    waitForUser("Missing Plugins?", "Please update missing plugins and run again");
    // Exits the script because of the missing plugins.
    exit
} else {
    // If all plugins are present, it prints a confirmation message.
    print("All plugins are present.");
}



//--------------------------------------------------


print("\\Clear");
setBatchMode(false);
originalname = getTitle();
getVoxelSize(width, height, depth, unit);
run("Select None");
run("Duplicate...", "title=MotorNeuron duplicate");

//INSERT SECTION HERE TO FIND CLASSIFIER FILE//


run("Segment Image With Labkit", "input=Nuc segmenter_file=[C:\\Users\\mq10002204\\OneDrive - Macquarie University\\ImageJ Macros and Machine Learning Classifiers\\labkit classifier\\Doublegoodv2.classifier] use_gpu=false");
run("glasbey");
resetMinAndMax;


selectImage("segmentation of MotorNeuron");
setBatchMode(true);
setThreshold(2, 2);
run("Make Binary", "background=Dark black");
rename("nuctmp");

selectImage("segmentation of MotorNeuron");
setThreshold(3, 3);
run("Make Binary", "background=Dark black");
rename("cytotmp");

selectImage("segmentation of MotorNeuron");
setThreshold(4, 4);
run("Make Binary", "background=Dark black");
rename("condensate");

imageCalculator("Add create stack", "nuctmp","condensate");
rename("MASK_Nuc");
run("3D Binary Close Labels", "radiusxy=6 radiusz=2 operation=Close");
close("MASK_Nuc");
selectImage("CloseLabels");
rename("MASK_Nuc");
run("3D Fill Holes");
//run("3D Binary Close Labels", "radiusxy=5 radiusz=3 operation=Close");
run("Distance Transform Watershed 3D", "distances=[Chessboard (1,1,1)] output=[16 bits] normalize dynamic=2 connectivity=6");
close("MASK_Nuc");
run("Keep Largest Region");
rename("MASK_Nuc");

imageCalculator("Add create stack", "MASK_Nuc","cytotmp");
rename("MASK_Cellbody2");
imageCalculator("Add create stack", "MASK_Cellbody2","condensate");
rename("MASK_Cellbody");

run("3D Binary Close Labels", "radiusxy=6 radiusz=2 operation=Close");
close("MASK_Cellbody");
selectImage("CloseLabels");
rename("MASK_Cellbody");

run("Distance Transform Watershed 3D", "distances=[Chessboard (1,1,1)] output=[16 bits] normalize dynamic=3 connectivity=6");
close("MASK_Cellbody");
selectImage("MASK_Cellbodydist-watershed");
run("Keep Largest Region");
close("MASK_Cellbodydist-watershed");
selectImage("MASK_Cellbodydist-watershed-largest");
rename("MASK_Cellbody");
run("3D Fill Holes");





run("Cascade");

imageCalculator("Subtract create stack", "MASK_Cellbody","MASK_Nuc");
rename("MASK_Cytoplasm");

selectWindow("condensate");
run("3D Binary Close Labels", "radiusxy=3 radiusz=2 operation=Close");
run("3D Watershed Split", "binary=CloseLabels seeds=Automatic radius=1");
close("EDT");
selectWindow("Split");
rename("Seg_Speckles");
run("Label Size Filtering", "operation=Greater_Than size=100");
run("Remap Labels");
setOption("ScaleConversions", true);
run("8-bit");
run("glasbey");
close("Seg_Speckles");
selectImage("Seg_Speckles-sizeFilt");
rename("Seg_Speckles");


imageCalculator("AND create stack", "Seg_Speckles","MASK_Cellbody");
close("Seg_Speckles");
selectImage("Result of Seg_Speckles");
rename("Seg_Speckles");
imageCalculator("AND stack", "Seg_Speckles","MASK_Cellbody");
setThreshold(1, 255);
setOption("BlackBackground", true);
run("Convert to Mask", "black create");
rename("MASK_Speckles");

imageCalculator("Subtract create stack","MASK_Nuc","MASK_Speckles");
rename("MASK_Nuc_nospeckle");


selectWindow("MASK_Cellbody");
setBatchMode("show");
selectWindow("MASK_Nuc");
setBatchMode("show");
selectWindow("Seg_Speckles");
setBatchMode("show");
selectWindow("MASK_Cytoplasm");
setBatchMode("show");
selectWindow("MASK_Nuc_nospeckle");
setBatchMode("show");
selectWindow("MASK_Speckles");
setBatchMode("show");
run("Cascade");


setBatchMode(false);

//overlap extractor
selectImage("Seg_Speckles");
run("Remap Labels");
run("Overlap Extractor (2D/3D)", "image_plus_1=MASK_Speckles image_plus_2=MASK_Nuc volume_range=10-150 exclude_edge_objects=false show_original_primary_statistics=false show_extracted_objects=true show_count_statistics=false show_volume_statistics=false show_percent_volume_map=false treat_binary_objects_as_one=false");
run("glasbey");
run("3D Simple Segmentation", "seeds=None low_threshold=1 min_size=0 max_size=-1");
selectImage("Seg");
close();
selectImage("Bin");
imageCalculator("XOR create stack", "MASK_Speckles","Bin");
selectImage("Result of MASK_Speckles");
rename("MASK_Cytoplasm_Speckles");
selectImage("Bin");
close();
selectWindow("MASK_Cytoplasm_Speckles");
setBatchMode("show");
selectImage("MASK_Cytoplasm_Speckles");
run("3D Simple Segmentation", "seeds=None low_threshold=255 min_size=0 max_size=-1");

selectImage("Bin");
close();
selectImage("Seg");
rename("seg_Cytoplasm_Speckles");
selectWindow("seg_Cytoplasm_Speckles");
setBatchMode("show");




selectImage("MotorNeuron");
run("Split Channels");
selectImage("C1-MotorNeuron");
rename("TDP");
selectImage("C2-MotorNeuron");
rename("Nuc");
run("Merge Channels...", "c1=TDP c2=Nuc c3=Seg_Speckles create keep");
Stack.setDisplayMode("color");
Stack.getDimensions(width, height, channels, slices, frames);
Stack.setSlice(slices/2);
run("Enhance Contrast", "saturated=0.05");
rename("MotorNeuron");
selectWindow("MotorNeuron");
setBatchMode("show");
selectWindow("TDP");
setBatchMode("show");
selectWindow("Nuc");
setBatchMode("show");

setBatchMode(false);
run("Cascade");



inspectstack();
measurestack();
close("*");















// Function to inspect and segment stacks ("TDP" and "Nuc") and gather user feedback
function inspectstack() {
  	
    // Initial setup for the image processing
    selectImage("MotorNeuron");
     
    
    
    Stack.setDisplayMode("composite");
    //Stack.setActiveChannels("1");
    run("Grays");
    run("Enhance Contrast", "saturated=0.05");
    rename("Motorneuronsegment");
    

    // Process overlays for "MASK_Cellbody"
    selectWindow("MASK_Cellbody");
    slice = nSlices;
	setBatchMode(true);
    for (i = 1; i <= slice; i++) {
        selectImage("MASK_Cellbody");
        setSlice(i);
        run("Create Selection");

        if (selectionType() == -1) {
            continue; // Skip this iteration if no valid selection is found
        }

        // Add magenta overlay to selections in "Motorneuronsegment"
        selectImage("Motorneuronsegment");
        Stack.setSlice(i);
        run("Overlay Options...", "stroke=magenta width=0 fill=none set");
        run("Restore Selection");
        run("Add Selection...");
        selectImage("Motorneuronsegment");
        run("Select None");
    }
	setBatchMode(false);
    // Process overlays for "MASK_Nuc"
    selectWindow("MASK_Nuc");
    slice = nSlices;
setBatchMode(true);
    for (i = 1; i <= slice; i++) {
        selectImage("MASK_Nuc");
        setSlice(i);
        run("Create Selection");

        if (selectionType() == -1) {
            continue; // Skip this iteration if no valid selection is found
        }

        // Add green overlay to selections in "Motorneuronsegment"
        selectImage("Motorneuronsegment");
        Stack.setSlice(i);
        run("Overlay Options...", "stroke=green width=0 fill=none set");
        run("Restore Selection");
        run("Add Selection...");
        selectImage("Motorneuronsegment");
        run("Select None");
    }
setBatchMode(false);
    // Process overlays for "MASK_Speckles"
    selectWindow("MASK_Speckles");
    slice = nSlices;
setBatchMode(true);
    for (i = 1; i <= slice; i++) {
        selectImage("MASK_Speckles");
        setSlice(i);
        run("Create Selection");

        if (selectionType() == -1) {
            continue; // Skip this iteration if no valid selection is found
        }

        // Add red overlay to selections in "Motorneuronsegment"
        selectImage("Motorneuronsegment");
        Stack.setSlice(i);
        run("Overlay Options...", "stroke=red width=0 fill=none set");
        run("Restore Selection");
        run("Add Selection...");
        selectImage("Motorneuronsegment");
        run("Select None");
    } 
setBatchMode(false);
    // Finalize batch processing



 setBatchMode(true);
    for (i = 1; i <= slice; i++) {
        selectImage("MASK_Cytoplasm_Speckles");
        setSlice(i);
        run("Create Selection");

        if (selectionType() == -1) {
            continue; // Skip this iteration if no valid selection is found
        }

        // Add red overlay to selections in "Motorneuronsegment"
        selectImage("Motorneuronsegment");
        Stack.setSlice(i);
        run("Overlay Options...", "stroke=Yellow width=0 fill=none set");
        run("Restore Selection");
        run("Add Selection...");
        selectImage("Motorneuronsegment");
        run("Select None");
    } 
setBatchMode(false);
 
 
 
 
 
run("Cascade"); 
selectWindow("Motorneuronsegment");
Stack.getDimensions(width, height, channels, slices, frames);
run("Select None");
Stack.setDisplayMode("color");
Stack.setChannel(2);
Stack.setSlice(slices/2);
run("Enhance Contrast", "saturated=0.1");
Stack.setChannel(1);
Stack.getDimensions(width, height, channels, slices, frames);
Stack.setSlice(slices/2);
//resetMinAndMax();
run("Enhance Contrast", "saturated=0.1");



run("Scale Bar...", "width=5 height=3 thickness=4 font=14 color=White background=None location=[Lower Left] horizontal bold overlay label");
Stack.setChannel(2);
run("Grays");
Stack.setChannel(3);
run("glasbey_on_dark");
Stack.setChannel(1);



//_______________________________________________
    // Prompt the user for feedback on segmentation
    title = "Check";
    msg = "Inspect segmentation";
    waitForUser(title, msg);

    // Get user feedback and take appropriate actions
    stable = getBoolean("Agree with segmentation?");

    if (stable == 0) {
        waitForUser("Aborting", "Quitting");
        close("*");
        exit;
    }
}




function measurestack(){
output = getDirectory("Output Directory for Segmentor");

setBatchMode(true);	

//output = getDirectory("Output Directory for Segmentor");

File.makeDirectory(output+"/Results");
results = output+"/Results/";
File.makeDirectory(results + "/Detections");
detectionsfolder = results + "/Detections/";
selectWindow("Motorneuronsegment");
saveAs("Tiff", detectionsfolder +  originalname +  "_analysed.tif");
	//close();



// Set voxel size for the windows with TDP, seg_Speckles, and MASK_Speckles
selectWindow("TDP");
getVoxelSize(width, height, depth, unit);
selectWindow("Seg_Speckles");
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
run("Intensity Measurements 2D/3D", "input=TDP labels=MASK_Cellbody mean numberofvoxels volume");
selectWindow("TDP-intensity-measurements");
Table.rename("TDP-intensity-measurements", "Results");

Mean = getResult("Mean", 0);
Sum = getResult("NumberOfVoxels", 0);
Vol = getResult("Volume", 0);

// Store nucleus measurements in the results table
selectWindow(Resultstable);
Table.set("Cellbody Mean Intensity", 0, Mean);
Table.set("Cellbody Intensity Sum", 0, (Mean * Sum));
Table.set("Cellbody Volume (um^3)", 0, Vol);
run("Clear Results");





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
run("3D Numbering", "main=MASK_Cellbody counted=Seg_Speckles");
selectWindow("Numbering");
Table.rename("Numbering", "Results");
number = getResult("NbObjects", 0);

// Store the number of detected condensates in the results table
selectWindow(Resultstable);
Table.set("Detected Condensates", 0, number);
run("Clear Results");

// Count the number of speckles detected
run("3D Numbering", "main=MASK_Cellbody counted=seg_Cytoplasm_Speckles");
selectWindow("Numbering");
Table.rename("Numbering", "Results");
number = getResult("NbObjects", 0);

// Store the number of detected condensates in the results table
selectWindow(Resultstable);
Table.set("Cytoplasmic Condensates", 0, number);
run("Clear Results");


run("Intensity Measurements 2D/3D", "input=TDP labels=Seg_Speckles mean numberofvoxels volume");
Table.rename("TDP-intensity-measurements", "Results");

if(nResults == 0){
	nocondensates = 1;
table_name = "Condensate Summary";
table_cols = newArray("Label", "Mean", "NumberOfVoxels", "Volume", "Corrected Sphericity", "Image Name");

newTable(table_name, table_cols);

function newTable(table_name, table_cols) {
	Table.create(table_name);
	for (i=0; i<table_cols.length; i++) {
		selectWindow(table_name);
		Table.set(table_cols[i], 0, 0);
	}
	Table.deleteRows(0, 0, table_name);
}
Table.set("Image", 0, savename);
//Table.rename("Condensate Summary", "Results");
}
else if (nResults != 0){
	nocondensates = 0;
	Table.rename("Results", "Resultstmp");
	selectWindow("Seg_Speckles");
	run("3D Compactness");
// Get the number of rows in the "Results" table
nRows = nResults;
// Specify the name of the column you want to copy
columnName1 = "SpherCorr(pix)";
// Select the condensate summary window
selectWindow("Results");

// Loop over each row in the "Results" table
for (row = 0; row < nRows; row++) {
    // Get the value from the "Results" table
    value = getResult(columnName1, row);
    // Set the value in the condensate summary table
    // The sphericity value computed using volume in pixel unit and corrected surface (pixel unit)
    selectWindow("Resultstmp");
    Table.set("Corrected Sphericity", row, value);	
}
Table.rename("Resultstmp", "Condensate Summary");
Table.set("Image Name", 0, savename);
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
Table.set("Cellbody Volume (um^3)", 0, getResult("Cellbody Volume (um^3)", 0));
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
Table.set("Cellbody Mean Intensity", 0, getResult("Cellbody Mean Intensity", 0));
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
Table.set("Cellbody Intensity Sum", 0, getResult("Nucleus Intensity Sum", 0));
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
Table.set("Cytoplasmic Condensates", 0, getResult("Cytoplasmic Condensates", 0));
Table.rename("Better Results", "Results");



// Save results to an Excel file
run("Read and Write Excel", "stack_results no_count_column dataset_label=[Segmentation Results] sheet=Segmentation Results file=[" + results + "Segmentation.xlsx]");
run("Clear Results");
if (nocondensates ==0){
Table.rename("Condensate Summary", "Results");
run("Read and Write Excel", "stack_results no_count_column dataset_label=[Condensates] sheet=Condensates  file=[" + results + "Segmentation.xlsx]");
run("Clear Results");
}
}






//--------------------------------------------------
// This is a function named 'pluginExists' designed to check if a specific plugin exists in ImageJ's directories.
function pluginExists(pluginName) {
    // First, it looks in the main plugins directory of ImageJ.
    mainDir = getDirectory("imagej") + "plugins/";
    list = getFileList(mainDir);
    for (i = 0; i < lengthOf(list); i++) {
        // It checks each file in this directory to see if its name matches the plugin we're looking for.
        if (matches(list[i], pluginName + ".*\\.jar")) {
            // If a match is found, it means the plugin exists here, so the function returns 'true'.
            return true;
        }
    }
    
    // Next, it looks in a specific subdirectory named 'mcib3d-suite', which is also part of the plugins directory.
    Dir3dsuite = getDirectory("imagej") + "plugins/mcib3d-suite/";
    list = getFileList(Dir3dsuite);
    for (i = 0; i < lengthOf(list); i++) {
        // Again, it checks each file in this directory for a name match.
        if (matches(list[i], pluginName + ".*\\.jar")) {
            // If the plugin is found here, the function returns 'true'.
            return true;
        }
    }
    
    // Finally, it checks in another directory named 'update/plugins', which is where updated plugins might be stored.
    updateDir = getDirectory("imagej") + "update/plugins/";
    updateList = getFileList(updateDir);
    for (i = 0; i < lengthOf(updateList); i++) {
        // It goes through each file in this directory to find a match.
        if (matches(updateList[i], pluginName + ".*\\.jar")) {
            // If the plugin is found, the function returns 'true'.
            return true;
        }
    }

    // If the plugin is not found in any of the checked directories, the function returns 'false'.
    return false;
}



//--------------------------------------------------