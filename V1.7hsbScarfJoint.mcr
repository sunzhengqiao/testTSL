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


