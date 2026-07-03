// -------------------------------------------------------------------------------------------
// File version 1000
// -------------------------------------------------------------------------------------------
// Is second string in first string																		
FUNCTION FindInstr
	// Set up start value, function return value is not initialized
	FindInstr := 0;

	IF (brsstrlen(string1) >= brsstrlen(string2)) THEN
		FOR idx:=0 TO brsstrlen(string1) - brsstrlen(string2) DO
			IF (brsmemcmp(string1 + idx, string2, brsstrlen(string2)) = 0) THEN
				FindInstr := idx;
				EXIT;
			END_IF
		END_FOR;
	END_IF
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Generate crc																	
FUNCTION CalcCrc
	// Set up start value, function return value is not initialized
	CalcCrc := 0;

	FOR idx:=1 TO length - 1 DO
		brsmemcpy(ADR(_byte), data+idx, 1);
		CalcCrc := CalcCrc + _byte;
	END_FOR;
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Handle error state
FUNCTION CreateErrorState
	CreateLoggerEntry(exASSETINT_LOG_ERROR, ErrorMsg, Logger);

	DiagStatusID.ID := ErrorID;
	DiagStatusID.Code := UDINT_TO_UINT(State);
	DiagStatusID.Severity := Severity;

	State := exASSETINT_STATE_ERROR;
	
	CreateErrorState := ErrorID;
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Handle log buffer
FUNCTION CreateLoggerEntry
	IF LogBuffer = 0 THEN
		RETURN;		
	END_IF	
	// Make sure log message fits
	IF brsstrlen(LogMsg) > LOG_LEN - 20 THEN
		brsstrcpy(LogMsg, ADR('*** log meassage exceeds maximum length ***'));
		RETURN;
	END_IF
	// Check previous message
	IF brsstrlen(LogBuffer) > 19 THEN
		brsstrcpy(ADR(LastMsg), LogBuffer + 19);
	END_IF

	// Make sure we dont flood Logger
	IF brsstrcmp(LogMsg, ADR(LastMsg)) <> 0 AND LogLevel <= LOG_LEVEL AND LogBuffer <> 0 THEN
		// Move ring buffer around
		brsmemmove(LogBuffer+LOG_LEN+1, LogBuffer, LOG_LEN*(LOG_NUM-1));
		brsstrcpy(LogBuffer, ADR(''));
		// Create time information
		RTC_gettime(ADR(RtcGettime)); 
		IF(RtcGettime.day < 10) THEN
			brsstrcat(LogBuffer, ADR('0'));
		END_IF
		brsitoa(RtcGettime.day, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(TmpStr));
		brsitoa(RtcGettime.day, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR('.'));
		IF(RtcGettime.month < 10) THEN
			brsstrcat(LogBuffer, ADR('0'));
		END_IF
		brsitoa(RtcGettime.month, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(' '));
		IF(RtcGettime.hour < 10) THEN
			brsstrcat(LogBuffer, ADR('0'));
		END_IF
		brsitoa(RtcGettime.hour, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(':'));
		IF(RtcGettime.minute < 10) THEN
			brsstrcat(LogBuffer, ADR('0'));
		END_IF
		brsitoa(RtcGettime.minute, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(':'));
		IF(RtcGettime.second < 10) THEN
			brsstrcat(LogBuffer, ADR('0'));
		END_IF
		brsitoa(RtcGettime.second, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR('.'));
		IF(RtcGettime.millisec < 10) THEN
			brsstrcat(LogBuffer, ADR('00'));
		ELSIF(RtcGettime.millisec < 100) THEN
			brsstrcat(LogBuffer, ADR('0'));
		END_IF
		brsitoa(RtcGettime.millisec, ADR(TmpStr));
		brsstrcat(LogBuffer, ADR(TmpStr));
		// Add log message
		brsstrcat(LogBuffer, ADR(' '));
		brsstrcat(LogBuffer, LogMsg);
	END_IF

	CreateLoggerEntry := TRUE;
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Check prerequisites, exLink and buffers
FUNCTION exAssetIntCheckShiftData
	// -------------------------------------------------------------------------------------------
	// Check shift configuration for errors
	FOR y := 0 TO SIZEOF(Configuration.Shifts)/SIZEOF(Configuration.Shifts[0]) - 1 DO
		FOR x := 0 TO SIZEOF(Configuration.Shifts[y].ScheduledDowntime)/SIZEOF(Configuration.Shifts[y].ScheduledDowntime[0]) - 1 DO
			// Make sure downtime is within shift
			IF TOD_TO_UDINT(Configuration.Shifts[y].ScheduledDowntime[x].Start) <> 0 OR TOD_TO_UDINT(Configuration.Shifts[y].ScheduledDowntime[x].End) <> 0 THEN
				IF Configuration.Shifts[y].ScheduledDowntime[x].Start < Configuration.Shifts[y].TotalTime.Start OR 
					Configuration.Shifts[y].ScheduledDowntime[x].End > Configuration.Shifts[y].TotalTime.End THEN
					// Set status, remember state, go to error state
					TmpStr1 := 'ERR: downtime is outside of shift in no ';
					brsitoa(y, ADR(TmpStr2));
					brsstrcat(ADR(TmpStr1), ADR(TmpStr2));
					brsstrcat(ADR(TmpStr1), ADR(' in downtime no '));
					brsitoa(x, ADR(TmpStr2));
					brsstrcat(ADR(TmpStr1), ADR(TmpStr2));
					StatusID := CreateErrorState(ERR_ASSET_SHIFT_CALC, ADR(TmpStr1), Logger, exCOM_SEV_ERROR,  ADR(State), ADR(InfoDiagStatusID));
					exAssetIntCheckShiftData := FALSE;
					RETURN;							
				END_IF
			END_IF
		END_FOR;
	END_FOR;
	
	CreateLoggerEntry(exASSETINT_LOG_ALL, ADR('shift data is ok'), Logger);
	exAssetIntCheckShiftData := TRUE;
END_FUNCTION