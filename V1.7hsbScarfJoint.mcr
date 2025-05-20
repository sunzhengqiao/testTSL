#Version 8
#BeginDescription
DE erzeugt Gerberstöße oder Hakenblätter an mehreren Bauteilen
EN creates a single or double scarf joint on multiple beams

version  value="1.7" date="05mar20" author="david.delombaerde@hsbcad.com"> 
Setting boundaries when moving the grippoint. 
And resetting the value when grip is out of bounds. 


NOTE: Avoid update with existing entities of versions before 1.4 or validate new properties of existing entities
HINWEIS: Ein Update sollte bei bereits eingefügten Instanzen der Versionen vor 1.4 vermieden werden oder es
müssen die Eigenschaften aller Instanzen überprüft werden

#End
#Type E
#NumBeamsReq 1
#NumPointsGrip 0
#DxaOut 0
#ImplInsert 1
#FileState 0
#MajorVersion 1
#MinorVersion 7
#KeyWords 
#BeginContents
/// <History>//region
/// <summary Lang=de>
/// Dieses TSL erzeugt ein Hakenblatt, Gerberstoß oder eine Überblattung und teilt die gewählten Bauteile
/// </summary>

/// <insert Lang=de>
/// Wählen Sie einen oder mehrere Stäbe aus und geben den Teilungspunkt an.
/// </insert>

/// <remark Lang=de>
/// Ein Update sollte bei bereits eingefügten Instanzen der Versionen vor 1.4 vermieden werden oder es
/// müssen die Eigenschaften aller Instanzen überprüft werden
/// <remark Lang=de>

/// History
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
	
	double dDefaultLength = U(500);
	String sLengthName = "   " + T("|Length|");
	PropString sLength (nStringIndex++, "*2", sLengthName);
	sLength.setDescription(T("|The length of the tool|") + " " + sDescRelative);
	sLength.setCategory(sCategoryGeo);
	
	double dDefaultDepth = U(40);
	String sDepthName = "   " + T("|Depth|");
	PropString sDepth(nStringIndex++, "*0.15", sDepthName );
	sLength.setDescription(T("|The depth of the tool|") + " " + sDescRelative);	
	sDepth.setCategory(sCategoryGeo);

	// drill props
	String sDiameterName="   "+T("|Diameter|");
	PropDouble dDiameter(nDoubleIndex++, U(18), sDiameterName);
	dDiameter.setDescription(T("|The diameter of the connecting drill|"));
	dDiameter.setCategory(sCategoryDrill);
	
	String sDrillOffsetName="   "+T("|X-Offset|");
	PropString sDrillOffset(nStringIndex++, 0, sDrillOffsetName);
	sDrillOffset.setDescription(T("|The offset of the drill in length|") + " " + T("|Absolute value or relative value to length of tool supported, i.e. *0.5 to place the drills with an offset of 50% of the tool length|"));
	sDrillOffset.setCategory(sCategoryDrill);
	
	PropDouble dOffset(nDoubleIndex++, 0, "   " +T("|Offset from Axis|"));
	dOffset.setDescription(T("|Defines the vertical offset of the tool.|") + " (" + T("|Simple Scarf only|") + ")");
	dOffset.setCategory(sCategoryGeo);
	

//End Properties//endregion 

//region On Insert
				
	if (_bOnInsert)
	{
	// dialog or catalog based properties
		String sDefaultCatalogTypes[] = {"Simple", "Double", "Lap"};
		if (_kExecuteKey.length()==0) // show default dialog
			showDialog();
		else
		{
			String sEntries[] = TslInst().getListOfCatalogNames(scriptName());
			if (sEntries.find(_kExecuteKey)>-1) // the entry exists, do not show dialog
				setPropValuesFromCatalog(_kExecuteKey);
			else // the entry does not exist
			{
				int nDefault = sDefaultCatalogTypes.find(_kExecuteKey);
				if (nDefault >-1 && sTypes.length()>nDefault) // the requested entry is a default entry to preset the type
				{
					sType.set(sTypes[nDefault]);
					setCatalogFromPropValues(sLastEntry);
					showDialog(sLastEntry);
				}
				else // not defined, show dialog
				{
					showDialog();	
				}
						
			}
		}	
		
	// set default string values if value was not entered by user
		int bSetLast;
		double dLength = sLength.atof();
		if (dLength<=0)
		{
			String s = sLength;
			s.makeUpper();
			int n=s.find("*",0);
		// no valid relative definition found
			if(n<0 || s.length()<2)
			{
				sLength.set(dDefaultLength);	
				bSetLast=true;	
			}	
		}
		double dDepth= sDepth.atof();
		if (dDepth<=0)
		{
			String s = sDepth;
			s.makeUpper();
			int n=s.find("*",0);
		// no valid relative definition found
			if(n<0 || s.length()<2)
			{
				sDepth.set(dDefaultDepth);	
				bSetLast=true;	
			}	
		}
		
	// set last entry if invalid initial values were found
		if (bSetLast)
			setCatalogFromPropValues(T("|_LastInserted|"));			
			
		PrEntity ssE(T("|Select a set of beams|"), Beam());
  		if (ssE.go())
			_Beam = ssE.beamSet();
			
		_Pt0 = getPoint(T("|Select insertion point|"));	
		
	// declare tsl props
		TslInst tsl;
		Vector3d vUcsX = _XW;
		Vector3d vUcsY = _YW;
		Entity ents[0];
		Beam gbs[2];
		Point3d ptsIn[1];
		int nProps[0];
		double dProps[]={dDiameter, dOffset};
		String sProps[]={sType, sLength, sDepth, sDrillOffset};
		
	// loop all selected beams	
		for (int i = 0; i < _Beam.length(); i++)
			{	
				ptsIn[0] = Line(_Beam[i].ptCen(), _Beam[i].vecX()).closestPointTo(_Pt0);	
				
				// split the beam
				Beam bm1;
				bm1 = _Beam[i].dbSplit(_Pt0,_Pt0);
				
				gbs[0] = _Beam[i];
				gbs[1] = bm1;
				tsl.dbCreate(scriptName(), vUcsX,vUcsY,gbs, ents,ptsIn,
					nProps, dProps,sProps );
			}	
	// erase the 'distribution' instance of this tsl			
		eraseInstance();
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

	int nType = sTypes.find(sType);// 0 = single, 1 = double, 2=Lap
	Beam bm0 = _Beam[0];
	Beam bm1 = _Beam[1];
	Vector3d vecX,vecY,vecZ;	

	vecX=bm0.vecX();
	vecY=_Y0;
	vecZ=_Z0;
	
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
			Point3d pttest = _PtW + _Map.getVector3d("vecPt0");
			_Pt0 = _PtW + _Map.getVector3d("vecPt0");
		}
	}

// set depth and length, allo wrelative values like *0.2
	double dLength = sLength.atof();
	double dDepth = sDepth.atof();
	double dDrillOffset = sDrillOffset.atof()*.5;
	String sValues[] = {sLength, sDepth,sDrillOffset};
	String sTxts[] = {sLengthName.trimLeft(), sDepthName.trimLeft(), sDrillOffsetName.trimLeft()};
	double dDefaultValues[] = {dDefaultLength, dDefaultDepth,0};
	for (int i=0;i<sValues.length();i++)
	{	
		double dValue = sValues[i].atof();
		if (dValue<=0)
		{
			String sValue = sValues[i];
			sValue.makeUpper();
			int n=sValue.find("*",0);
		// relative definition found	
			if(n>-1 || sValue.length()>1)
			{
				sValue=sValue.right(sValue.length()-n-1).trimLeft().trimRight();
				double d = sValue.atof();
				if (d>0 && i<2)
					dValue = d*bm0.dD(vecZ);
				else if (d>0 && i==2)
					dValue = d*dLength;
			}
		// no valid relative definition found
			else
			{
				String sTxt=sTxts[i];
				if (i==0)sLength.set(dDefaultValues[i]);	
				else if (i==1)sDepth.set(dDefaultValues[i]);	
				reportMessage("\n" + scriptName() +": " + sTxt + " " + T("|has had an invalid value, corrected to|") + " " + dDefaultValues[i]);	
			}	
		}
		if (i==0)dLength = dValue;	
		else if (i==1)	dDepth = dValue;		
		else if (i==2)	dDrillOffset = dValue*.5;			
	}
	if (dLength<=0) dLength=dDefaultLength;	
	if (dDepth <=0) dDepth =dDefaultDepth;
	if (dDrillOffset <=0) dDrillOffset =0;	
	
// color
	if (_bOnDbCreated)
	{
		_ThisInst.setColor(171);
		setExecutionLoops(2);
	}


// add triggers
	String sTriggerFlipX = T("|Flip X|");
	addRecalcTrigger(_kContext, sTriggerFlipX);
		
// store flip x in map
	if (!_Map.hasInt("nFlipX"))_Map.setInt("nFlipX",1);
	int nFlipX = _Map.getInt("nFlipX");			
	
// trigger0: 
	if (_bOnRecalc && _kExecuteKey==sTriggerFlipX) 
	{
		if (nFlipX == 1)
			nFlipX = -1;		

		else
			nFlipX = 1;
		_Map.setInt("nFlipX",nFlipX);
	}	

// stretch connecting beams
	Cut ct0(_Pt0 + _Beam[0].vecX() * 0.5 * dLength, _Beam[0].vecX());
	Cut ct1(_Pt0 - _Beam[0].vecX() * 0.5 * dLength, -_Beam[0].vecX());
	_Beam[0].addTool(ct0,1);
	_Beam[1].addTool(ct1,1);
	
// declare scarf points
	Point3d ptX = _Pt0 + 0.5 * vecX * dLength - nFlipX * vecZ * (0.5 * _H0 - dDepth);
	Point3d ptX1 = _Pt0 - 0.5 * vecX * dLength + nFlipX * vecZ * (0.5 * _H0 - dDepth);

// declare scarf contour points
	Point3d ptPl[0];
	
// declare scarf vectors
	Vector3d vecZScarf = vecZ;

// the ref
	Point3d ptRef;

// the joinery
	if (nType==1)// double scarf
	{
		if (abs(dOffset)>0) dOffset.set(0);
		ptRef = _Pt0;
		
		ptX.vis(1);
		ptX1.vis(2);
	
		vecZScarf = nFlipX * vecZ;	
		ScarfJoint sf0(ptRef , vecX, vecZScarf, dLength, dDepth, _Beam[0].dD(vecZ));	
		ScarfJoint sf1(ptRef , -vecX, -vecZScarf, dLength, dDepth, _Beam[1].dD(vecZ));	
		
		_Beam[0].addTool(sf0);
		_Beam[1].addTool(sf1);
		
		// collect scarf contour
		ptPl.append(_Pt0 - vecX * 0.5 * dLength + 0.5 * nFlipX * vecZ * _Beam[0].dD(vecZ));
		ptPl.append(ptX1);
		Line ln(ptX1, Vector3d(ptX1 - (_Pt0 - nFlipX * vecZ * 0.5 * dDepth)));
		ptPl.append(ln.closestPointTo(_Pt0));
		ln = Line(ptX, Vector3d(ptX - (_Pt0 + nFlipX * vecZ * 0.5 * dDepth)));
		ptPl.append(ln.closestPointTo(_Pt0));
		ptPl.append(ptX);		
		ptPl.append(_Pt0 + vecX * 0.5 * dLength - 0.5 * nFlipX * vecZ * _Beam[0].dD(vecZ));			
	}
	else if (nType==0)// single scarf
	{
	// validate offset
		if (dOffset>dDepth)	
			dOffset.set(dDepth);
		
		ptRef = _Pt0 +_Beam[0].vecD(vecZScarf)*dOffset;
		ptX = _Pt0 + 0.5 * vecX * dLength - nFlipX * vecZ * (0.5 * _H0 );
		ptX1 = _Pt0 - 0.5 * vecX * dLength + nFlipX * vecZ * (0.5 * _H0);
		
		vecZScarf = nFlipX * vecZ;	
		
		double dThisDepth = (_H0-2*dDepth);
		
		ptRef.vis(20);
		SimpleScarf ss1(ptRef ,vecX, vecZScarf,dLength, dThisDepth );
		SimpleScarf ss2(ptRef ,-vecX, -vecZScarf,dLength, dThisDepth );
		_Beam[0].addTool(ss1);
		_Beam[1].addTool(ss2);	


		// collect scarf contour	
		ptPl.append(ptX1);			
		ptPl.append(ptRef - vecX * 0.5 * dLength + 0.5 * nFlipX * vecZ * dThisDepth );//_Beam[0].dD(vecZ));
		ptPl.append(ptRef + vecX * 0.5 * dLength - 0.5 * nFlipX * vecZ * dThisDepth );//_Beam[0].dD(vecZ));	
		ptPl.append(ptX);		
	
	}
	else if (nType==2)//lap
	{
		ptRef = _Pt0 +_Beam[0].vecD(vecZScarf)*dOffset;
		ptX = _Pt0 + 0.5 * vecX * dLength - nFlipX * vecZ * (0.5 * _H0 );
		ptX1 = _Pt0 - 0.5 * vecX * dLength + nFlipX * vecZ * (0.5 * _H0);
		
		dDepth=_H0*.5;
		//dDepth.setReadOnly(true);
		double dThisDepth = (_H0-2*dDepth);
		
		BeamCut bc1(ptRef-vecX*.5*dLength, vecX,vecY,vecZ, 2*dLength,U(2000), U(2000), 1,0,nFlipX);
		_Beam[0].addTool(bc1);			
		BeamCut bc2(ptRef+vecX*.5*dLength, vecX,vecY,vecZ, 2*dLength,U(2000), U(2000), -1,0,-nFlipX);
		_Beam[1].addTool(bc2);	

		// collect lap contour	
		ptPl.append(ptX1);			
		ptPl.append(ptRef - vecX * 0.5 * dLength + 0.5 * nFlipX * vecZ * dThisDepth );//_Beam[0].dD(vecZ));
		ptPl.append(ptRef + vecX * 0.5 * dLength - 0.5 * nFlipX * vecZ * dThisDepth );//_Beam[0].dD(vecZ));	
		ptPl.append(ptX);		
	
	}	
	
// the drills
	if (dDiameter>=0)
	{
		double dZ =bm0.dD(vecZ);
		double dRefOffset;
		if (nType==1 && dDrillOffset<=0) 
			dRefOffset= .25*dLength;
		else if(dDrillOffset>0)
			dRefOffset= dDrillOffset;
		if (dDrillOffset>dLength)
			dRefOffset=dLength;
		Point3d ptDrill = _Pt0-vecX*dRefOffset+vecZ*dZ;
		Drill drill1(ptDrill , ptDrill -vecZ*2*dZ, dDiameter*.5);
		//drill1.cuttingBody().vis(2);
		drill1.addMeToGenBeamsIntersect(_Beam);			
		
		if (dRefOffset>0)
		{
			Point3d ptDrill = _Pt0+vecX*dRefOffset+vecZ*dZ;
			Drill drill2(ptDrill , ptDrill -vecZ*2*dZ, dDiameter*.5);
			//drill1.cuttingBody().vis(2);
			drill2.addMeToGenBeamsIntersect(_Beam);		
		}		
	}	
		
// the display
	Display dp(_ThisInst.color());
	PLine pl(_Y0);
	for (int i = 0; i < ptPl.length(); i++)
		pl.addVertex(ptPl[i]);

	dp.draw(pl);
	
	_Map.setVector3d("vecPt0", _Pt0 - _PtW);


#End
#BeginThumbnail
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
FU);.?)`]14M_I]LGAZVO50B>2[=&;/4;5/\`,FG2C=L*KLD?_]F'
`





#End
#BeginMapX
<?xml version="1.0" encoding="utf-16"?>
<Hsb_Map>
  <lst nm="TslIDESettings">
    <lst nm="HOSTSETTINGS">
      <dbl nm="PREVIEWTEXTHEIGHT" ut="L" vl="1" />
    </lst>
    <lst nm="{E1BE2767-6E4B-4299-BBF2-FB3E14445A54}">
      <lst nm="BREAKPOINTS" />
    </lst>
  </lst>
  <lst nm="VersionHistory[]">
    <lst nm="VERSION">
      <str nm="COMMENT" vl="Unified drill/sinkhole positioning to be independent of joint offset for all types (Simple Scarf, Double Scarf, Lap). Refined 'Offset from Axis' behavior for Lap and Double Scarf joint cuts. Removed all step-related functionality (formerly Japanese Scarf/Stepped type). Cleaned UI property names and completed various syntax/logic correctio" />
      <int nm="MAJORVERSION" vl="1" />
      <int nm="MINORVERSION" vl="8" />
      <str nm="DATE" vl="5/16/2025 9:20:55 AM" />
    </lst>
  </lst>
  <unit ut="L" uv="millimeter" />
  <unit ut="A" uv="radian" />
</Hsb_Map>
#End