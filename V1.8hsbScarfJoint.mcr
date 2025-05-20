/// <History>///region
/// <summary Lang="en">
/// This TSL creates Simple Scarf, Double Scarf, or Lap joints to connect two collinear beam parts. It splits the selected beam(s) at a user-defined point and applies the chosen joinery. Key features include parametric geometry, an 'Offset from Axis' for the main joint, and options for through-drills with independent top/bottom sinkholes. Drills and sinkholes remain aligned with the original beam axis, irrespective of the joint's offset.
/// </summary>
/// <summary Lang="de">
/// Dieses TSL erzeugt ein Hakenblatt, Gerberstoß oder eine Überblattung und teilt die gewählten Bauteile
/// </summary>

/// <insert Lang="en">
/// Select one or more co-linear beams and specify the division point. The script will split the beams and apply the selected joint type with the configured parameters.
/// </insert>
/// <insert Lang="de">
/// Wählen Sie einen oder mehrere Stäbe aus und geben den Teilungspunkt an.
/// </insert>

/// <remark Lang="en">
/// This TSL creates Simple Scarf, Double Scarf (non-stepped), or Lap joints. The 'Offset from Axis' parameter adjusts the vertical position of the primary joint cut. Drill and sinkhole features are always positioned relative to the original beam axis and maintain their specified depths from the beam surfaces, regardless of the main joint's offset.
/// </remark>
/// <remark Lang="de">
/// Ein Update sollte bei bereits eingefügten Instanzen der Versionen vor 1.4 vermieden werden oder es
/// müssen die Eigenschaften aller Instanzen überprüft werden
/// </summary> // Retained original German remark, added 'Lang="en"' for consistency if it makes sense, or replace.

/// History
///<version  value="1.8" date="16may25" author="zhengqiao.sun@hsbcad.com">Unified drill/sinkhole positioning to be independent of joint offset for all types (Simple Scarf, Double Scarf, Lap). Refined 'Offset from Axis' behavior for Lap and Double Scarf joint cuts. Removed all step-related functionality (formerly Japanese Scarf/Stepped type). Cleaned UI property names and completed various syntax/logic correctio
///<version  value="1.7" date="05mar20" author="david.delombaerde@hsbcad.com"> setting boundaries when moving the grippoint. And resetting the value when grip is out of bounds. </version>
///<version  value="1.6" date="05dec17" author="th@hsbCAD.de"> bugfix, offset from axis</version>
///<version  value="1.5" date="19jan15" author="th@hsbCAD.de"> drill offset now supports relative value to tool length, 0 = one centered drill </version>
///<version  value="1.4" date="19jan15" author="th@hsbCAD.de"> properties revised and extended, relative properties supported, catalog based insertion supported </version>
///<version  value="1.3" date="08aug13" author="th@hsbCAD.de"> new type lap added </version>
///<version  value="1.2" date="07mai13" author="th@hsbCAD.de"> Simple Scarf optimized using Simple Scarf instead of a Double Cut, new property offset for simple scarf</version>

//endregion

//region Constants
	
	U(1,"mm");
	double dEps = U(0.1);
	int nDoubleIndex, nStringIndex,nIntIndex;
	String sDoubleClick= "TslDoubleClick";
	String sCategoryGeo = T("|Geometry|");
	String sCategoryTool = T("|Tooling|");
	String sCategoryDrill = T("|Drill|");
	String sDescRelative = T("|Absolute values or relative values to beam dimension supported, i.e. *0.25 for the value of 25% of the beam dimension|");
	String sLastEntry = T("|_LastInserted|");

//End Constants//endregion 
	
//region Properties
		
	String sTypes[]={T("|Simple Scarf Joint|"), T("|Double Scarf Joint|"),T("|Lap|")};
	PropString sType(nStringIndex++, sTypes, T("|Type|"));
	sType.setDescription(T("|Select the type of scarf joinery.|"));
	sType.setCategory(sCategoryTool);
	
	/// Geometry properties (absolute values only)
	String sLengthName = "   " + T("|Length|"); 
	PropDouble dLength(nDoubleIndex++, U(500), sLengthName);
	dLength.setDescription(T("|The length of the tool (absolute value in mm)|"));
	dLength.setCategory(sCategoryGeo);
	
	double dDefaultDepth = U(40);
	String sDepthName = "   " + T("|Depth|" );
	PropDouble dDepth(nDoubleIndex++, dDefaultDepth, sDepthName );
	dDepth.setDescription(T("|The depth of the tool (main scarf cut, absolute value in mm)|"));
	dDepth.setCategory(sCategoryGeo);

	String sDiameterName="   "+T("|Drill Diameter|"); 
	PropDouble dDiameter(nDoubleIndex++, U(18), sDiameterName);
	dDiameter.setDescription(T("|The diameter of the connecting drill|"));
	dDiameter.setCategory(sCategoryDrill);
	
	String sDrillOffsetName="   "+T("|Drill X-Offset|"); 
	PropString sDrillOffset(nStringIndex++, "0", sDrillOffsetName);
	sDrillOffset.setDescription(T("|The offset of the drill in length|") + " " + T("|Absolute value or relative value to length of tool supported, i.e. *0.5 for 50% of tool length, 0 for centered (single drill pair)||"));
	sDrillOffset.setCategory(sCategoryDrill);

	String sSinkholeDiameterName = "   " + T("|Top Sinkhole Diameter|");
	PropDouble dSinkholeDiameter(nDoubleIndex++, U(0), sSinkholeDiameterName);
	dSinkholeDiameter.setDescription(T("|Diameter of the sinkhole on top side. Must be greater than Drill Diameter to take effect.|"));
	dSinkholeDiameter.setCategory(sCategoryDrill);

	String sSinkholeDepthName = "   " + T("|Top Sinkhole Depth|");
	PropDouble dSinkholeDepth(nDoubleIndex++, U(0), sSinkholeDepthName);
	dSinkholeDepth.setDescription(T("|Depth of the sinkhole on top side. Must be positive to take effect.|"));
	dSinkholeDepth.setCategory(sCategoryDrill);
	
	String sBottomSinkholeDiameterName = "   " + T("|Bottom Sinkhole Diameter|");
	PropDouble dBottomSinkholeDiameter(nDoubleIndex++, U(0), sBottomSinkholeDiameterName);
	dBottomSinkholeDiameter.setDescription(T("|Diameter of the sinkhole on bottom side. Must be greater than Drill Diameter to take effect.|"));
	dBottomSinkholeDiameter.setCategory(sCategoryDrill);

	String sBottomSinkholeDepthName = "   " + T("|Bottom Sinkhole Depth|");
	PropDouble dBottomSinkholeDepth(nDoubleIndex++, U(0), sBottomSinkholeDepthName);
	dBottomSinkholeDepth.setDescription(T("|Depth of the sinkhole on bottom side. Must be positive to take effect.|"));
	dBottomSinkholeDepth.setCategory(sCategoryDrill);
	
	PropDouble dOffset(nDoubleIndex++, 0, "   " +T("|Offset from Axis|"));
	dOffset.setDescription(T("|Defines the vertical offset from the beam axis for the joint center. Applies to Simple Scarf, Lap, and Double Scarf Joint.|")); 
	dOffset.setCategory(sCategoryGeo);
	

//End Properties//endregion 

//region On Insert
// V1.8 now opens without auto-loading a catalog so the user can
// choose any entry. Parameters are still saved to "_LastInserted".
				
	if (_bOnInsert)
	{
		String sLastEntry = T("|_LastInserted|");
		String sDefaultCatalogTypes[] = {"Simple", "Double", "Lap"}; // Short, non-translated keys
		String sEntries[] = TslInst().getListOfCatalogNames(scriptName());

                if (_kExecuteKey.length() == 0) // Interactive insertion: no _kExecuteKey
                {
                        // Show dialog for user input/confirmation. Catalog switching
                        // will load the selected entry's parameters as chosen by the user.
                        showDialog();
                }
		else // _kExecuteKey is provided
		{
			if (sEntries.find(_kExecuteKey) > -1) // Case 1: _kExecuteKey is a valid, existing Catalog name
			{
				// Load this catalog's parameters
				setPropValuesFromCatalog(_kExecuteKey);
				// Show dialog to allow review/modification
				showDialog(); 
			}
			else // Case 2: _kExecuteKey is not an existing catalog name, check if it's a type trigger
			{
				int nMatchingTypeIndex = -1;
				// First, check if _kExecuteKey is a full, translated type name (e.g., "|Simple Scarf Joint|")
				for (int i = 0; i < sTypes.length(); i++) {
				    if (_kExecuteKey == sTypes[i]) {
				        nMatchingTypeIndex = i;
				        break;
				    }
				}
				
				// If not a full name, check if _kExecuteKey is a short type trigger (e.g., "Simple")
				if (nMatchingTypeIndex == -1) {
				    int nShortNameIndex = sDefaultCatalogTypes.find(_kExecuteKey);
				    if (nShortNameIndex > -1 && sTypes.length() > nShortNameIndex) {
				        nMatchingTypeIndex = nShortNameIndex; // Map "Simple" to index of T("|Simple Scarf Joint|")
				    }
				}

                                if (nMatchingTypeIndex > -1) // _kExecuteKey is a recognized type trigger
                                {
                                        // Set the type based on the matched _kExecuteKey
                                        sType.set(sTypes[nMatchingTypeIndex]);
                                        // Store values in the '_LastInserted' catalog and show dialog with that catalog selected
                                        setCatalogFromPropValues(sLastEntry);
                                        showDialog(sLastEntry);
                                }
				else // _kExecuteKey is unrecognized (not a catalog, not a type trigger)
				{
					// Fallback: try loading _LastInserted if available, then show dialog
					if (sEntries.find(sLastEntry) > -1) {
						setPropValuesFromCatalog(sLastEntry);
					}
					showDialog();	
				}
			}
		}	
		
		// --- Post-dialog processing and validation, before entity selection & dbCreate ---

		// Parameter Validation: sDrillOffset check for "LENGTH"
		String sDrillOffsetValCurrent = sDrillOffset;
		String sDrillOffsetValUpper = sDrillOffsetValCurrent; // Avoid modifying original if not needed
		sDrillOffsetValUpper.makeUpper();
		if (sDrillOffsetValUpper == "LENGTH")
		{
			reportNotice(scriptName() + ": " + T("|Drill X-Offset was 'LENGTH', resetting to '0'.|"));
			sDrillOffset.set("0");
		}

		// Ensure dLength and dDepth are positive, without overriding valid catalog/user inputs too aggressively
		if (dLength <= 0) {
			dLength.set(U(1));	
		}
		if (dDepth <= 0) {
			dDepth.set(U(1));	
		}
		
		// Save the final, confirmed/adjusted parameters to _LastInserted catalog
		setCatalogFromPropValues(sLastEntry);			
			
		PrEntity ssE(T("|Select a set of beams|"), Beam());
  		if (ssE.go()) {
			_Beam = ssE.beamSet();
  		} else { // User cancelled beam selection
  		    eraseInstance(); 
  		    return;
  		}
			
		_Pt0 = getPoint(T("|Select insertion point|"));	
		// Add check for valid point selection if getPoint can return invalid state
		// For now, assuming valid point or script handles it later.
		
		TslInst tsl;
		Vector3d vUcsX = _XW;
		Vector3d vUcsY = _YW;
		Entity ents[0];
		Beam gbs[2];
		Point3d ptsIn[1];
		int nProps[0]; // This is for integer properties, seems unused in this TSL for dbCreate

        // Property values must be passed to dbCreate in the order of their nDoubleIndex/nStringIndex
        // String Props declaration order: sType (index 0), sDrillOffset (index 1)
		String sPropsToPass[]={ 
		    sType, 
		    sDrillOffset 
		};
		
        // Double Props declaration order: dLength (0), dDepth (1), dDiameter (2), 
        // dSinkholeDiameter (3), dSinkholeDepth (4), 
        // dBottomSinkholeDiameter (5), dBottomSinkholeDepth (6), dOffset (7)
		double dPropsToPass[]={
		    dLength, dDepth, dDiameter, 
		    dSinkholeDiameter, dSinkholeDepth, 
		    dBottomSinkholeDiameter, dBottomSinkholeDepth,
		    dOffset
		};
		
		for (int i = 0; i < _Beam.length(); i++)
		{	
            // Verify we have a valid beam index
            if (i >= _Beam.length()) {
                reportWarning(scriptName() + ": " + T("Invalid beam index."));
                continue;
            }
            
            // Get beam properties - center and axis vector
            Point3d ptOriginalBeamCenter = _Beam[i].ptCen();
            Vector3d vecToOrigin = Point3d(0,0,0) - ptOriginalBeamCenter;
            
            // Check if ptOriginalBeamCenter is too close to origin (suspicious)
            if (vecToOrigin.length() < U(0.1)) {
                reportWarning(scriptName() + ": " + T("Beam may have invalid center point."));
                continue;
            }
            
            Vector3d vecOriginalBeamX = _Beam[i].vecX();
            if (vecOriginalBeamX.length() < U(0.001)) {
                // A near-zero axis vector indicates a potentially invalid beam
                reportWarning(scriptName() + ": " + T("Beam has invalid axis vector."));
                continue;
            }
            
            // Calculate projection of insertion point onto the beam axis
            ptsIn[0] = Line(ptOriginalBeamCenter, vecOriginalBeamX).closestPointTo(_Pt0);
            
            // Check if the projected point is within the beam's length
            Vector3d vecToSplit = ptsIn[0] - ptOriginalBeamCenter;
            double dDistanceAlongBeam = vecToSplit.dotProduct(vecOriginalBeamX);
            double dBeamHalfLength = _Beam[i].dL() * 0.5;
            
            if (abs(dDistanceAlongBeam) > dBeamHalfLength) {
                reportWarning(scriptName() + ": " + T("Split point outside beam length limits."));
                continue;
            }
				
			// Perform the split operation
			Beam bm1;
			bm1 = _Beam[i].dbSplit(ptsIn[0], ptsIn[0]); // Split at the projected point on beam axis
			
            // Verify split succeeded by checking beam lengths
            double d1 = _Beam[i].dL();
            double d2 = 0;
            
            // Carefully check the second beam - check if its center is a meaningful distance from origin
            Point3d pt2 = bm1.ptCen();
            Vector3d vec2Check = Point3d(0,0,0) - pt2;
            if (vec2Check.length() > U(0.1)) {
                // If center point isn't too close to origin, probably valid
                d2 = bm1.dL();
            }
            
            // Both beams must have meaningful lengths
            int beamsValid = 0; // 0 = false, 1 = true
            if (d1 > U(1) && d2 > U(1)) {
                beamsValid = 1;
            }
                
			if (beamsValid) {
			    // Split succeeded, proceed with joint creation
			    gbs[0] = _Beam[i]; // The first part of the split beam
			    gbs[1] = bm1;      // The second part of the split beam
			    
			    // Create the joinery between the two beams
			    tsl.dbCreate(scriptName(), vUcsX, vUcsY, gbs, ents, ptsIn,
				    nProps, dPropsToPass, sPropsToPass);
			} else {
			    reportError(scriptName() + ": " + T("Failed to split beam or resulting beam parts are invalid. Skipping this beam."));
			}
		}	
		eraseInstance(); // Erase the temporary TSL instance used for insertion.
		return;	
	}	

//End On Insert//endregion 

//region Validate
		
	if(_Beam.length()<2)
	{
		reportNotice("\n*****************************************************************\n" + 
		scriptName() + ": " + T("Missing beam.") + "\n" + 
		T("Tool will be deleted") + "\n" +
		"*****************************************************************");
		eraseInstance();
		return;
	}

//End Validate//endregion 

//region Declare standards

	int nThisType = sTypes.find(sType);
	Beam bm0 = _Beam[0];
	Beam bm1 = _Beam[1];
	Vector3d vecX,vecY,vecZ;	

	vecX=bm0.vecX();
	vecY=_Y0; // Beam's local Y
	vecZ=_Z0; // Beam's local Z (usually vertical if beam is flat)
	
	vecX.vis(_Pt0, 1);
	vecY.vis(_Pt0, 3);
	vecZ.vis(_Pt0, 150);

	Point3d ptCen0 = bm0.ptCen();
	Point3d ptCen1 = bm1.ptCen();	
	Vector3d vecXT = bm0.vecX();
  	
//End Declare standards//endregion 
			
	if (vecXT.dotProduct(ptCen1 - ptCen0) < 0)
	{ 
		vecXT *= -1;
	}
	
	vecXT.vis(ptCen0);
	
	if (_kNameLastChangedProp == "_Pt0" && _Map.hasVector3d("vecPt0"))
	{ 
		Point3d ptMax0 = ptCen0 - vecXT * .5 * bm0.dL();
		double d0 = vecXT.dotProduct(_Pt0 - ptMax0);
		Point3d ptMax1 = ptCen1 + vecXT * .5 * bm1.dL();
		double d1 = vecXT.dotProduct(ptMax1 - _Pt0);	
		
		if (d0< 0 || d1 < 0)
		{ 
			_Pt0 = _PtW + _Map.getVector3d("vecPt0");
		}
	}

/// Process Length, Depth, DrillOffset properties (relative values)
	double dLengthVal = dLength;
	double dDepthVal = dDepth;
	double dDrillOffsetVal = sDrillOffset.atof(); 
	
/// Remove all Length and Depth processing from here
/// Process only DrillOffset property (relative values)
String sValueStr = sDrillOffset;
			sValueStr.makeUpper();
int nFindStar = sValueStr.find("*",0);
if(nFindStar > -1 && sValueStr.length() > 1) {
    sValueStr = sValueStr.right(sValueStr.length()-nFindStar-1).trimLeft().trimRight();
    double dFactor = sValueStr.atof();
    if (dFactor > 0) {
        dDrillOffsetVal = dFactor * dLengthVal;
    }
}

/// Simple minimum value check only
if (dLengthVal <= 0) dLengthVal = U(1);
if (dDepthVal <= 0) dDepthVal = U(1);

/// --- BEGIN Parameter Validation ---
	/// Sinkhole validation for all types (top and bottom)
	double dSinkholeDiaVal = dSinkholeDiameter;
	double dDrillDiaVal = dDiameter;
	double dBottomSinkholeDiaVal = dBottomSinkholeDiameter;
	
	/// Only validate interactively - don't override user catalog values during insertion
	if (!_bOnInsert) {
		/// Top Sinkhole validation
		if (dSinkholeDiaVal < 0) {
			reportNotice(scriptName() + ": " + T("|Top Sinkhole Diameter cannot be negative. Resetting to 0.|"));
			dSinkholeDiameter.set(0); dSinkholeDiaVal = 0;
		}
		else if (dSinkholeDiaVal > 0) {
			/// If sinkhole diameter is set but smaller than drill diameter, adjust it
			if (dSinkholeDiaVal <= dDrillDiaVal && dDrillDiaVal > 0) {
				/// Auto-correct to 1.5x the drill diameter
				double dNewSinkholeDia = dDrillDiaVal * 1.5;
				reportNotice(scriptName() + ": " + T("|Top Sinkhole Diameter must be greater than Drill Diameter.|") + dNewSinkholeDia + ".");
				dSinkholeDiameter.set(dNewSinkholeDia);
				dSinkholeDiaVal = dNewSinkholeDia;
			}
			
			/// If sinkhole depth is not set but diameter is, set a reasonable depth
			if (dSinkholeDepth <= 0) {
				/// Auto-correct to half the drill diameter or 5mm, whichever is larger
				double dNewSinkholeDepth = dDrillDiaVal * 0.5;
				if (dNewSinkholeDepth < U(5)) dNewSinkholeDepth = U(5);
				reportNotice(scriptName() + ": " + T("|Top Sinkhole Depth must be positive. Setting to |") + dNewSinkholeDepth + ".");
				dSinkholeDepth.set(dNewSinkholeDepth);
			}
		}
		
		/// If top sinkhole depth is set but diameter is 0, set a reasonable diameter
		if (dSinkholeDiaVal == 0 && dSinkholeDepth > 0) {
			/// Auto-correct to 1.5x the drill diameter
			double dNewSinkholeDia = dDrillDiaVal * 1.5;
			reportNotice(scriptName() + ": " + T("|Top Sinkhole Depth is set, but Diameter is 0. Setting diameter to |") + dNewSinkholeDia + ".");
			dSinkholeDiameter.set(dNewSinkholeDia);
		}
		
		/// Bottom Sinkhole validation
		if (dBottomSinkholeDiaVal < 0) {
			reportNotice(scriptName() + ": " + T("|Bottom Sinkhole Diameter cannot be negative. Resetting to 0.|"));
			dBottomSinkholeDiameter.set(0); dBottomSinkholeDiaVal = 0;
		}
		else if (dBottomSinkholeDiaVal > 0) {
			/// If bottom sinkhole diameter is set but smaller than drill diameter, adjust it
			if (dBottomSinkholeDiaVal <= dDrillDiaVal && dDrillDiaVal > 0) {
				/// Auto-correct to 1.5x the drill diameter
				double dNewBottomSinkholeDia = dDrillDiaVal * 1.5;
				reportNotice(scriptName() + ": " + T("|Bottom Sinkhole Diameter must be greater than Drill Diameter.|") + dNewBottomSinkholeDia + ".");
				dBottomSinkholeDiameter.set(dNewBottomSinkholeDia);
				dBottomSinkholeDiaVal = dNewBottomSinkholeDia;
			}
			
			/// If bottom sinkhole depth is not set but diameter is, set a reasonable depth
			if (dBottomSinkholeDepth <= 0) {
				/// Auto-correct to half the drill diameter or 5mm, whichever is larger
				double dNewBottomSinkholeDepth = dDrillDiaVal * 0.5;
				if (dNewBottomSinkholeDepth < U(5)) dNewBottomSinkholeDepth = U(5);
				reportNotice(scriptName() + ": " + T("|Bottom Sinkhole Depth must be positive. Setting to |") + dNewBottomSinkholeDepth + ".");
				dBottomSinkholeDepth.set(dNewBottomSinkholeDepth);
			}
		}
		
		/// If bottom sinkhole depth is set but diameter is 0, set a reasonable diameter
		if (dBottomSinkholeDiaVal == 0 && dBottomSinkholeDepth > 0) {
			/// Auto-correct to 1.5x the drill diameter
			double dNewBottomSinkholeDia = dDrillDiaVal * 1.5;
			reportNotice(scriptName() + ": " + T("|Bottom Sinkhole Depth is set, but Diameter is 0. Setting diameter to |") + dNewBottomSinkholeDia + ".");
			dBottomSinkholeDiameter.set(dNewBottomSinkholeDia);
		}

		if (nThisType == 1) { // Validations specific to "Double Scarf Joint"
			// Drill diameter validation
			if (dDiameter <= 0) {
				reportNotice(scriptName() + ": " + T("|Drill Diameter must be positive. Setting to default.|"));
				dDiameter.set(U(18));
			}
			
			// Sinkhole depth validation
			if (dSinkholeDiameter > 0 && dSinkholeDepth > 0) {
				/// Ensure sinkhole is not too deep
				double dMaxSinkholeDepth = _H0 * 0.35;
				if (dSinkholeDepth > dMaxSinkholeDepth) {
					reportNotice(scriptName() + ": " + T("|Sinkhole Depth must be less than 35% of beam height.|"));
					dSinkholeDepth.set(dMaxSinkholeDepth);
				}
			}
			
			// Offset validation for Double Scarf (formerly Japanese Scarf)
			double dMaxOffset = _H0 * 0.25;
			if (dOffset > dMaxOffset) {
				reportNotice(scriptName() + ": " + T("|Vertical offset exceeds recommended limit for Double Scarf. Limiting to safe value.|"));
				dOffset.set(dMaxOffset);
			} else if (dOffset < -dMaxOffset) {
				reportNotice(scriptName() + ": " + T("|Vertical offset exceeds recommended limit for Double Scarf. Limiting to safe value.|"));
				dOffset.set(-dMaxOffset);
			}
		}
	}
	/// --- END Parameter Validation ---
	
/// color
	if (_bOnDbCreated)
	{
		_ThisInst.setColor(171);
		setExecutionLoops(2);
	}

/// add triggers
	String sTriggerFlipX = T("|Flip X|");
	addRecalcTrigger(_kContext, sTriggerFlipX);
		
	if (!_Map.hasInt("nFlipX"))_Map.setInt("nFlipX",1);
	int nFlipX = _Map.getInt("nFlipX");			
	
	double dAppliedOffset = 0; // Declare dAppliedOffset at a higher scope

	if (_bOnRecalc && _kExecuteKey==sTriggerFlipX) 
	{
		nFlipX = (_Map.getInt("nFlipX") == 1) ? -1 : 1;
		_Map.setInt("nFlipX",nFlipX);
	}	

/// stretch connecting beams
	Cut ct0(_Pt0 + bm0.vecX() * 0.5 * dLengthVal, bm0.vecX());
	Cut ct1(_Pt0 - bm0.vecX() * 0.5 * dLengthVal, -bm0.vecX());
	_Beam[0].addTool(ct0,1);
	_Beam[1].addTool(ct1,1);
	
	Point3d ptPl[0];
	Vector3d vecZScarf = nFlipX * vecZ;
	Point3d ptRef;

/// the joinery
	if (nThisType==1)/// double scarf
	{
		ptRef = _Pt0; /// Default reference point for the joint center
		dAppliedOffset = dOffset; /// Assign value from dOffset property

		/// Apply the offset to position the joint's reference point along vecZScarf
		    ptRef = _Pt0 + vecZScarf * dAppliedOffset; 
		
		/// Create ScarfJoints using the offset ptRef and original dDepthVal.
		/// The ScarfJoint tool applies a cut of dDepthVal from the surface 
		/// effectively defined by ptRef and the respective vecZScarf direction for each beam.

		double dMinDepth = U(1.0); // Minimum allowed depth for scarf cut

		double effective_H = _H0 + 2.0 * abs(dAppliedOffset);

		ScarfJoint sf0(ptRef, vecX, vecZScarf, dLengthVal, dDepthVal, effective_H);	
		ScarfJoint sf1(ptRef, -vecX, -vecZScarf, dLengthVal, dDepthVal, effective_H);	

		_Beam[0].addTool(sf0);
		_Beam[1].addTool(sf1);
	}
	else if (nThisType==0)/// single scarf
	{
        double dOffsetAppliedVal = dOffset;
		if (dOffsetAppliedVal > dDepthVal) dOffsetAppliedVal = dDepthVal;
        if (dOffsetAppliedVal < -dDepthVal) dOffsetAppliedVal = -dDepthVal;
		
		ptRef = _Pt0 + _Beam[0].vecD(vecZScarf)*dOffsetAppliedVal;
		double dSimpleScarfDepth = (_H0 - 2*dDepthVal);
		
		SimpleScarf ss1(ptRef ,vecX, vecZScarf,dLengthVal, dSimpleScarfDepth );
		SimpleScarf ss2(ptRef ,-vecX, -vecZScarf,dLengthVal, dSimpleScarfDepth );
		_Beam[0].addTool(ss1);
		_Beam[1].addTool(ss2);	
	}
	else if (nThisType==2)///lap
	{
        double dOffsetAppliedVal = dOffset;
		ptRef = _Pt0 + _Beam[0].vecD(vecZScarf)*dOffsetAppliedVal;
		
		/// For Lap type, adjust cut depths based on offset
		double dBaseLapCutDepth = _H0*0.5;
		double dLapCutDepth_Beam0 = dBaseLapCutDepth - dOffsetAppliedVal; // If offset is positive, Beam0 is cut less
		double dLapCutDepth_Beam1 = dBaseLapCutDepth + dOffsetAppliedVal; // If offset is positive, Beam1 is cut more

		// Safeguard depths
		dLapCutDepth_Beam0 = ((dEps) > (((dLapCutDepth_Beam0) < (_H0 - dEps) ? (dLapCutDepth_Beam0) : (_H0 - dEps))) ? (dEps) : (((dLapCutDepth_Beam0) < (_H0 - dEps) ? (dLapCutDepth_Beam0) : (_H0 - dEps))));
		dLapCutDepth_Beam1 = ((dEps) > (((dLapCutDepth_Beam1) < (_H0 - dEps) ? (dLapCutDepth_Beam1) : (_H0 - dEps))) ? (dEps) : (((dLapCutDepth_Beam1) < (_H0 - dEps) ? (dLapCutDepth_Beam1) : (_H0 - dEps))));

		BeamCut bc1(ptRef-vecX*.5*dLengthVal, vecX,vecY,vecZScarf, dLengthVal, _Beam[0].dD(vecY), dLapCutDepth_Beam0, 1,0,1);
		_Beam[0].addTool(bc1);			
		BeamCut bc2(ptRef+vecX*.5*dLengthVal, -vecX,vecY,-vecZScarf, dLengthVal, _Beam[1].dD(vecY), dLapCutDepth_Beam1, 1,0,1);
		_Beam[1].addTool(bc2);	
	}

/// Drills section needs to be adjusted: Standard drills always apply.
/// Sinkholes now apply to all joint types
	double dThroughDrillDiaVal = dDiameter;
	
	if (dThroughDrillDiaVal > dEps) 
	{
	    double dZbeam = bm0.dD(vecZ); 
	    double dActualDrillOffset = dDrillOffsetVal;
	    
        /// SPECIAL HANDLING FOR SIMPLE SCARF JOINT
        /// The problem is that in Simple Scarf, the beams are cut differently
        /// and standard drill application doesn't work correctly when 
        /// both drills are inside the joint length
        if (nThisType == 0) { /// Simple Scarf Joint            
            /// Calculate the offset value that's actually applied
            double dOffsetAppliedVal = dOffset;
            if (dOffsetAppliedVal > dDepthVal) dOffsetAppliedVal = dDepthVal;
            if (dOffsetAppliedVal < -dDepthVal) dOffsetAppliedVal = -dDepthVal;
            
            /// For Simple Scarf, we need to manually apply the drill to each beam
            /// First drill
            Point3d ptDrillCenter1 = _Pt0 - vecX * dActualDrillOffset;
            
            /// Second drill (if offset is non-zero)
            Point3d ptDrillCenter2;
            if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                ptDrillCenter2 = _Pt0 + vecX * dActualDrillOffset;
            }
            
            /// Apply drills to Beam[0]
            double dDrillRadius = dThroughDrillDiaVal * 0.5;
            
            /// First drill for Beam[0]
            Point3d ptDrillStart1_Beam0 = ptDrillCenter1 + vecZ * (dZbeam * 0.6); // Extended drill
            Point3d ptDrillEnd1_Beam0 = ptDrillCenter1 - vecZ * (dZbeam * 0.6);  // Extended drill
            Drill drill1_Beam0(ptDrillStart1_Beam0, ptDrillEnd1_Beam0, dDrillRadius);
            _Beam[0].addTool(drill1_Beam0);
            
            /// Second drill for Beam[0] if needed
            if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                Point3d ptDrillStart2_Beam0 = ptDrillCenter2 + vecZ * (dZbeam * 0.6);
                Point3d ptDrillEnd2_Beam0 = ptDrillCenter2 - vecZ * (dZbeam * 0.6);
                Drill drill2_Beam0(ptDrillStart2_Beam0, ptDrillEnd2_Beam0, dDrillRadius);
                _Beam[0].addTool(drill2_Beam0);
            }
            
            /// Apply drills to Beam[1]
            /// First drill for Beam[1]
            Point3d ptDrillStart1_Beam1 = ptDrillCenter1 + vecZ * (dZbeam * 0.6);
            Point3d ptDrillEnd1_Beam1 = ptDrillCenter1 - vecZ * (dZbeam * 0.6);
            Drill drill1_Beam1(ptDrillStart1_Beam1, ptDrillEnd1_Beam1, dDrillRadius);
            _Beam[1].addTool(drill1_Beam1);
            
            /// Second drill for Beam[1] if needed
            if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                Point3d ptDrillStart2_Beam1 = ptDrillCenter2 + vecZ * (dZbeam * 0.6);
                Point3d ptDrillEnd2_Beam1 = ptDrillCenter2 - vecZ * (dZbeam * 0.6);
                Drill drill2_Beam1(ptDrillStart2_Beam1, ptDrillEnd2_Beam1, dDrillRadius);
                _Beam[1].addTool(drill2_Beam1);
            }
            
            /// Add top sinkholes if needed
            if (dSinkholeDiameter > dThroughDrillDiaVal && dSinkholeDepth > 0) {
                double dSinkRadius = dSinkholeDiameter * 0.5;
                
                /// First top sinkhole for Beam[0]
                Point3d ptSinkCenter1_Beam0 = ptDrillCenter1 + vecZ * (dZbeam * 0.5);
                Drill sinkhole1Top_Beam0(ptSinkCenter1_Beam0, ptSinkCenter1_Beam0 - vecZ * dSinkholeDepth, dSinkRadius);
                _Beam[0].addTool(sinkhole1Top_Beam0);
                
                /// First top sinkhole for Beam[1]
                Point3d ptSinkCenter1_Beam1 = ptDrillCenter1 + vecZ * (dZbeam * 0.5);
                Drill sinkhole1Top_Beam1(ptSinkCenter1_Beam1, ptSinkCenter1_Beam1 - vecZ * dSinkholeDepth, dSinkRadius);
                _Beam[1].addTool(sinkhole1Top_Beam1);
                
                /// Second top sinkholes if offset
                if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                    /// Second top sinkhole for Beam[0]
                    Point3d ptSinkCenter2_Beam0 = ptDrillCenter2 + vecZ * (dZbeam * 0.5);
                    Drill sinkhole2Top_Beam0(ptSinkCenter2_Beam0, ptSinkCenter2_Beam0 - vecZ * dSinkholeDepth, dSinkRadius);
                    _Beam[0].addTool(sinkhole2Top_Beam0);
                    
                    /// Second top sinkhole for Beam[1]
                    Point3d ptSinkCenter2_Beam1 = ptDrillCenter2 + vecZ * (dZbeam * 0.5);
                    Drill sinkhole2Top_Beam1(ptSinkCenter2_Beam1, ptSinkCenter2_Beam1 - vecZ * dSinkholeDepth, dSinkRadius);
                    _Beam[1].addTool(sinkhole2Top_Beam1);
                }
            }
            
            /// Add bottom sinkholes if needed
            if (dBottomSinkholeDiameter > dThroughDrillDiaVal && dBottomSinkholeDepth > 0) {
                double dBottomSinkRadius = dBottomSinkholeDiameter * 0.5;
                
                /// First bottom sinkhole for Beam[0]
                Point3d ptBottomSinkCenter1_Beam0 = ptDrillCenter1 - vecZ * (dZbeam * 0.5);
                Drill sinkhole1Bottom_Beam0(ptBottomSinkCenter1_Beam0, ptBottomSinkCenter1_Beam0 + vecZ * dBottomSinkholeDepth, dBottomSinkRadius);
                _Beam[0].addTool(sinkhole1Bottom_Beam0);
                
                /// First bottom sinkhole for Beam[1]
                Point3d ptBottomSinkCenter1_Beam1 = ptDrillCenter1 - vecZ * (dZbeam * 0.5);
                Drill sinkhole1Bottom_Beam1(ptBottomSinkCenter1_Beam1, ptBottomSinkCenter1_Beam1 + vecZ * dBottomSinkholeDepth, dBottomSinkRadius);
                _Beam[1].addTool(sinkhole1Bottom_Beam1);
                
                /// Second bottom sinkholes if offset
                if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                    /// Second bottom sinkhole for Beam[0]
                    Point3d ptBottomSinkCenter2_Beam0 = ptDrillCenter2 - vecZ * (dZbeam * 0.5);
                    Drill sinkhole2Bottom_Beam0(ptBottomSinkCenter2_Beam0, ptBottomSinkCenter2_Beam0 + vecZ * dBottomSinkholeDepth, dBottomSinkRadius);
                    _Beam[0].addTool(sinkhole2Bottom_Beam0);
                    
                    /// Second bottom sinkhole for Beam[1]
                    Point3d ptBottomSinkCenter2_Beam1 = ptDrillCenter2 - vecZ * (dZbeam * 0.5);
                    Drill sinkhole2Bottom_Beam1(ptBottomSinkCenter2_Beam1, ptBottomSinkCenter2_Beam1 + vecZ * dBottomSinkholeDepth, dBottomSinkRadius);
                    _Beam[1].addTool(sinkhole2Bottom_Beam1);
                }
            }
            
            /// Prepare for display - rest of code handles display only
            /// (addMeToGenBeamsIntersect approach is not used for Simple Scarf type now)
            ptRef = _Pt0 + _Beam[0].vecD(vecZScarf) * dOffsetAppliedVal;
	    }
	    else if (nThisType == 1 || nThisType == 2) /// Double Scarf (1) or Lap (2)
        { 
            /// For other joint types, use ptRef which correctly includes the offset
            Point3d ptDrillBaseCalc = _Pt0; // ALWAYS base drills on _Pt0 for all types now
        
            /// First through drill
            Point3d ptDrillCenter1 = ptDrillBaseCalc - vecX * dActualDrillOffset; 
            
            Point3d ptDrillStart1 = ptDrillCenter1 + vecZ * (dZbeam * 0.5); // True beam top
            Point3d ptDrillEnd1 = ptDrillCenter1 - vecZ * (dZbeam * 0.5);   // True beam bottom
        
            Drill drill1(ptDrillStart1, ptDrillEnd1, dThroughDrillDiaVal * 0.5);
            drill1.addMeToGenBeamsIntersect(_Beam);
            
            /// Second through drill (if offset is non-zero)
            Point3d ptDrillCenter2, ptDrillStart2, ptDrillEnd2;
            if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                ptDrillCenter2 = ptDrillBaseCalc + vecX * dActualDrillOffset;
                ptDrillStart2 = ptDrillCenter2 + vecZ * (dZbeam * 0.5);
                ptDrillEnd2 = ptDrillCenter2 - vecZ * (dZbeam * 0.5);
            
                Drill drill2(ptDrillStart2, ptDrillEnd2, dThroughDrillDiaVal * 0.5);
                drill2.addMeToGenBeamsIntersect(_Beam);
            }
        
            /// Top Sinkhole logic for other joint types
            if (dSinkholeDiameter > dThroughDrillDiaVal && dSinkholeDepth > 0) {
                double adjusted_TopSinkholeDepth_general = dSinkholeDepth; // Always direct depth

                /// First top sinkhole
                Point3d ptSinkCenter1 = ptDrillCenter1 + vecZ * (dZbeam * 0.5); 
                Drill sinkhole1Top(ptSinkCenter1, ptSinkCenter1 - vecZ * adjusted_TopSinkholeDepth_general, dSinkholeDiameter * 0.5);
                sinkhole1Top.addMeToGenBeamsIntersect(_Beam);
            
                /// Second top sinkhole if offset
                if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                    Point3d ptSinkCenter2 = ptDrillCenter2 + vecZ * (dZbeam * 0.5); 
                    Drill sinkhole2Top(ptSinkCenter2, ptSinkCenter2 - vecZ * adjusted_TopSinkholeDepth_general, dSinkholeDiameter * 0.5);
                    sinkhole2Top.addMeToGenBeamsIntersect(_Beam);
                }
            }
        
            /// Bottom Sinkhole logic for other joint types
            if (dBottomSinkholeDiameter > dThroughDrillDiaVal && dBottomSinkholeDepth > 0) {
                double adjusted_BottomSinkholeDepth_general = dBottomSinkholeDepth; // Always direct depth

                /// First bottom sinkhole
                Point3d ptBottomSinkCenter1 = ptDrillCenter1 - vecZ * (dZbeam * 0.5); 
                Drill sinkhole1Bottom(ptBottomSinkCenter1, ptBottomSinkCenter1 + vecZ * adjusted_BottomSinkholeDepth_general, dBottomSinkholeDiameter * 0.5);
                sinkhole1Bottom.addMeToGenBeamsIntersect(_Beam);
            
                /// Second bottom sinkhole if offset
                if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                    Point3d ptBottomSinkCenter2 = ptDrillCenter2 - vecZ * (dZbeam * 0.5); 
                    Drill sinkhole2Bottom(ptBottomSinkCenter2, ptBottomSinkCenter2 + vecZ * adjusted_BottomSinkholeDepth_general, dBottomSinkholeDiameter * 0.5);
                    sinkhole2Bottom.addMeToGenBeamsIntersect(_Beam);
                }
            }
        }
	}
	
/// the display
	Display dp(_ThisInst.color());
	PLine pl(_Y0); 
	ptPl.setLength(0);

    /// Draw joint geometry based on type
    if (nThisType == 1) /// double scarf
	{
        /// Normal double scarf joint display (no steps)
        Point3d p1 = ptRef - vecX * 0.5 * dLengthVal + 0.5 * vecZScarf * _H0;
        Point3d p2 = ptRef - 0.5 * vecX * dLengthVal + vecZScarf * (0.5 * _H0 - dDepthVal);
        Point3d p3 = ptRef + 0.5 * vecX * dLengthVal - vecZScarf * (0.5 * _H0 - dDepthVal);
        Point3d p4 = ptRef + vecX * 0.5 * dLengthVal - 0.5 * vecZScarf * _H0;
        ptPl.append(p1); ptPl.append(p2); ptPl.append(p3); ptPl.append(p4);
	}
	else if (nThisType == 0 || nThisType == 2)
	{
		/// For display purposes, calculate different values for each type
		double dDisplayDepth;
		if (nThisType == 0) {
			/// For Simple Scarf Joint, use the user-specified depth
			dDisplayDepth = dDepthVal;
		} else {
			/// For Lap type, always use 50% of beam height
			dDisplayDepth = _H0 * 0.5;
		}
		
        Point3d actual_ptX1 = ptRef - 0.5 * vecX * dLengthVal + vecZScarf * (0.5 * _H0 - dDisplayDepth);
        Point3d actual_ptX  = ptRef + 0.5 * vecX * dLengthVal - vecZScarf * (0.5 * _H0 - dDisplayDepth);
		ptPl.append(actual_ptX1); 	
		
		double dRemainingHeight;
		if (nThisType == 0) {
			dRemainingHeight = _H0 - 2 * dDepthVal;
		} else {
			dRemainingHeight = 0; /// For Lap type
		}
		
		ptPl.append(ptRef - vecX * 0.5 * dLengthVal + 0.5 * vecZScarf * dRemainingHeight);
		ptPl.append(ptRef + vecX * 0.5 * dLengthVal - 0.5 * vecZScarf * dRemainingHeight);	
		ptPl.append(actual_ptX);
	}

    /// Draw the main joint outline
	for (int i = 0; i < ptPl.length(); i++)
		pl.addVertex(ptPl[i]);
	dp.draw(pl);
	
    /// Draw drills and sinkholes (for all joint types)
        if (dDiameter > 0) 
        {
        double dZbeam = bm0.dD(vecZ);
            double dActualDrillOffset = dDrillOffsetVal;
        Point3d ptDrillBaseCalc;
        
        /// For Simple Scarf Joint, drills should be positioned at _Pt0, not at ptRef
        if (nThisType == 0) {
            ptDrillBaseCalc = _Pt0; /// Simple Scarf Joint - drills at center point
        }
        else {
            /// For other joint types, use ptRef which correctly includes the offset
            ptDrillBaseCalc = ptRef;
        }
        
        /// Calculate drill compensation for offset in Double Scarf Joint OR Lap Joint
        double dDisplayTopOffset = 0;
        double dDisplayBottomOffset = 0;
        
        // This compensation is for DISPLAY of through-drill only if it were to follow offset joint face
        // However, actual drills are now always centered on _Pt0. So, this display logic for dTop/BottomOffset might be misleading.
        // For now, keep it as it affects where the sinkhole display lines might appear to start from if they were on an offset face.
        // But the actual sinkhole tools now use direct depths from true beam surfaces.
        if ((nThisType == 1 || nThisType == 2) && dOffset != 0) {
            if (dOffset > 0) {
                dDisplayBottomOffset = dOffset;
            } else {
                dDisplayTopOffset = -dOffset;
            }
        }
        
        /// Draw main through drill holes (now always centered on _Pt0 for all types)
        // ptDrillBaseCalc for display should also be _Pt0 if actual drills are from _Pt0
        Point3d ptDrillBaseCalc_Display = _Pt0; // Align display with actual drill logic

        Point3d ptDrillCenter1_display = ptDrillBaseCalc_Display - vecX * dActualDrillOffset;
        
        /// Draw drill circle
            PLine plDrill1(_Y0);
            double dRadius = dDiameter * 0.5;
            int nSegments = 16;
            Point3d ptFirstDrill1;
            
            for (int i = 0; i < nSegments; i++)
            {
                double angle = (double)i / nSegments * 2 * 3.14159;
                Point3d ptOnCircle = ptDrillCenter1_display + vecY * (dRadius * cos(angle)) + vecZ * (dRadius * sin(angle));
                if (i == 0) ptFirstDrill1 = ptOnCircle;
                plDrill1.addVertex(ptOnCircle);
            }
            plDrill1.addVertex(ptFirstDrill1);
            dp.draw(plDrill1);
            
        /// Draw drill depth line (now always through beam center)
        Point3d ptDrillStart1_display = ptDrillCenter1_display + vecZ * (dZbeam * 0.5);
        Point3d ptDrillEnd1_display = ptDrillCenter1_display - vecZ * (dZbeam * 0.5);
        dp.draw(PLine(ptDrillStart1_display, ptDrillEnd1_display));
        
        Point3d ptDrillCenter2_display; 
            if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps)
            {
            ptDrillCenter2_display = ptDrillBaseCalc_Display + vecX * dActualDrillOffset;
            
            /// Draw second drill circle
                PLine plDrill2(_Y0);
                Point3d ptFirstDrill2;
                
                for (int i = 0; i < nSegments; i++)
                {
                    double angle = (double)i / nSegments * 2 * 3.14159;
                    Point3d ptOnCircle = ptDrillCenter2_display + vecY * (dRadius * cos(angle)) + vecZ * (dRadius * sin(angle));
                    if (i == 0) ptFirstDrill2 = ptOnCircle;
                    plDrill2.addVertex(ptOnCircle);
                }
                plDrill2.addVertex(ptFirstDrill2);
                dp.draw(plDrill2);
            
            /// Draw second drill depth line (now always through beam center)
            Point3d ptDrillStart2_display = ptDrillCenter2_display + vecZ * (dZbeam * 0.5);
            Point3d ptDrillEnd2_display = ptDrillCenter2_display - vecZ * (dZbeam * 0.5);
            dp.draw(PLine(ptDrillStart2_display, ptDrillEnd2_display));
            }
            
        /// Draw sinkholes for all joint types only if diameter > drill diameter and depth > 0
        /// Top Sinkholes (display uses direct depth)
            if (dSinkholeDiameter > dDiameter && dSinkholeDepth > 0)
            {
            Point3d ptSinkCenter1_display = ptDrillCenter1_display + vecZ * (dZbeam * 0.5); // From true beam top
                PLine plSink1(_Y0);
                double dSinkRadius = dSinkholeDiameter * 0.5;
                Point3d ptFirstSink1;
                
                for (int i = 0; i < nSegments; i++)
                {
                    double angle = (double)i / nSegments * 2 * 3.14159;
                Point3d ptOnCircle = ptSinkCenter1_display + vecY * (dSinkRadius * cos(angle)) + vecX * (dSinkRadius * sin(angle));
                    if (i == 0) ptFirstSink1 = ptOnCircle;
                    plSink1.addVertex(ptOnCircle);
                }
                plSink1.addVertex(ptFirstSink1);
                dp.draw(plSink1);
                
            /// Draw second top sinkhole if offset
                if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps)
                {
                Point3d ptSinkCenter2_display = ptDrillCenter2_display + vecZ * (dZbeam * 0.5); // From true beam top
                    PLine plSink2(_Y0);
                    Point3d ptFirstSink2;
                    
                    for (int i = 0; i < nSegments; i++)
                    {
                        double angle = (double)i / nSegments * 2 * 3.14159;
                    Point3d ptOnCircle = ptSinkCenter2_display + vecY * (dSinkRadius * cos(angle)) + vecX * (dSinkRadius * sin(angle));
                        if (i == 0) ptFirstSink2 = ptOnCircle;
                        plSink2.addVertex(ptOnCircle);
                    }
                    plSink2.addVertex(ptFirstSink2);
                    dp.draw(plSink2);
                }
            
            /// Draw sinkhole depth - line indicating depth
            Point3d ptDepthStart1 = ptSinkCenter1_display; 
            double display_top_sink_depth = dSinkholeDepth; // Always direct depth for display
            // if (nThisType == 1 || nThisType == 2) {
            //     display_top_sink_depth += dAppliedOffset; 
            //     display_top_sink_depth = ((display_top_sink_depth) > (dEps) ? (display_top_sink_depth) : (dEps));
            // }
            Point3d ptDepthEnd1 = ptSinkCenter1_display - vecZ * display_top_sink_depth;
            dp.draw(PLine(ptDepthStart1, ptDepthEnd1));
            
            if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                Point3d ptSinkCenter2_display = ptDrillCenter2_display + vecZ * (dZbeam * 0.5); // From true beam top
                Point3d ptDepthStart2 = ptSinkCenter2_display;
                display_top_sink_depth = dSinkholeDepth; // Always direct depth for display
                // if (nThisType == 1 || nThisType == 2) {
                //     display_top_sink_depth += dAppliedOffset; 
                //     display_top_sink_depth = ((display_top_sink_depth) > (dEps) ? (display_top_sink_depth) : (dEps));
                // }
                Point3d ptDepthEnd2 = ptSinkCenter2_display - vecZ * display_top_sink_depth;
                dp.draw(PLine(ptDepthStart2, ptDepthEnd2));
            }
        }

        /// Bottom Sinkholes (display uses direct depth)
        if (dBottomSinkholeDiameter > dDiameter && dBottomSinkholeDepth > 0)
        {
            Point3d ptBottomSinkCenter1_display = ptDrillCenter1_display - vecZ * (dZbeam * 0.5); // From true beam bottom
            PLine plBottomSink1(_Y0);
            double dBottomSinkRadius = dBottomSinkholeDiameter * 0.5;
            Point3d ptFirstBottomSink1;
            
            for (int i = 0; i < nSegments; i++)
            {
                double angle = (double)i / nSegments * 2 * 3.14159;
                Point3d ptOnCircle = ptBottomSinkCenter1_display + vecY * (dBottomSinkRadius * cos(angle)) + vecX * (dBottomSinkRadius * sin(angle));
                if (i == 0) ptFirstBottomSink1 = ptOnCircle;
                plBottomSink1.addVertex(ptOnCircle);
            }
            plBottomSink1.addVertex(ptFirstBottomSink1);
            dp.draw(plBottomSink1);
            
            /// Draw second bottom sinkhole if offset
            if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps)
            {
                Point3d ptBottomSinkCenter2_display = ptDrillCenter2_display - vecZ * (dZbeam * 0.5); // From true beam bottom
                PLine plBottomSink2(_Y0);
                Point3d ptFirstBottomSink2;
                
                for (int i = 0; i < nSegments; i++)
                {
                    double angle = (double)i / nSegments * 2 * 3.14159;
                    Point3d ptOnCircle = ptBottomSinkCenter2_display + vecY * (dBottomSinkRadius * cos(angle)) + vecX * (dBottomSinkRadius * sin(angle));
                    if (i == 0) ptFirstBottomSink2 = ptOnCircle;
                    plBottomSink2.addVertex(ptOnCircle);
                }
                plBottomSink2.addVertex(ptFirstBottomSink2);
                dp.draw(plBottomSink2);
            }
            
            /// Draw bottom sinkhole depth - line indicating depth
            Point3d ptBottomDepthStart1 = ptBottomSinkCenter1_display;
            double display_bottom_sink_depth = dBottomSinkholeDepth; // Always direct depth for display
            // if (nThisType == 1 || nThisType == 2) {
            //     display_bottom_sink_depth -= dAppliedOffset; 
            //     display_bottom_sink_depth = ((display_bottom_sink_depth) > (dEps) ? (display_bottom_sink_depth) : (dEps));
            // }
            Point3d ptBottomDepthEnd1 = ptBottomSinkCenter1_display + vecZ * display_bottom_sink_depth;
            dp.draw(PLine(ptBottomDepthStart1, ptBottomDepthEnd1));
            
            if (dActualDrillOffset > dEps || dActualDrillOffset < -dEps) {
                Point3d ptBottomSinkCenter2_display = ptDrillCenter2_display - vecZ * (dZbeam * 0.5); // From true beam bottom
                Point3d ptBottomDepthStart2 = ptBottomSinkCenter2_display;
                display_bottom_sink_depth = dBottomSinkholeDepth; // Always direct depth for display
                // if (nThisType == 1 || nThisType == 2) {
                //     display_bottom_sink_depth -= dAppliedOffset; 
                //     display_bottom_sink_depth = ((display_bottom_sink_depth) > (dEps) ? (display_bottom_sink_depth) : (dEps));
                // }
                Point3d ptBottomDepthEnd2 = ptBottomSinkCenter2_display + vecZ * display_bottom_sink_depth;
                dp.draw(PLine(ptBottomDepthStart2, ptBottomDepthEnd2));
            }
        }
    }
	
	_Map.setVector3d("vecPt0", _Pt0 - _PtW);

/// Debug visualization (set to 1 to enable, 0 to disable)
int bEnableDebug = 0;
if (bEnableDebug) 
{
    Point3d ptDebugText = _Pt0 + vecY * (_Beam[0].dD(vecY) * 0.7) + vecZScarf * (_H0 * 0.7);
}


